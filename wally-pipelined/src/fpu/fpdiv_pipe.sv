///////////////////////////////////////////
//
// Written: James Stine
// Modified: 8/1/2018
//
// Purpose: Floating point divider/square root top unit pipelined version (Goldschmidt)
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

module fpdiv_pipe (
  input logic 	      clk,
  input logic 	      reset,
  input logic 	      start,
  input logic [63:0]  op1, 
  input logic [63:0]  op2, 
  input logic [1:0]   rm, 
  input logic 	      op_type, 
  input logic 	      P, 
  input logic 	      OvEn, 
  input logic 	      UnEn,
  input logic 	      XNaNQ,
  input logic 	      YNaNQ,
  input logic 	      XZeroQ,
  input logic 	      YZeroQ,
  input logic 	      XInfQ,
  input logic 	      YInfQ, 

  output logic 	      done,
  output logic 	      FDivBusyE,
  output logic [63:0] AS_Result, 
  output logic [4:0]  Flags);

   supply1 	      vdd;
   supply0 	      vss;   
   
   logic [63:0]       Float1; 
   logic [63:0]       Float2;
   logic [63:0]       IntValue;
   
   logic [12:0]       exp1, exp2, expF;
   logic [12:0]       exp_diff, bias;
   logic [13:0]       exp_sqrt;
   
   logic [63:0]       Result;   
   logic [52:0]       mantissaA;
   logic [52:0]       mantissaB; 
   
   logic [2:0] 	      sel_inv;
   logic 	      Invalid;
   logic [4:0] 	      FlagsIn;   	
   logic 	      exp_gt63;
   logic 	      Sticky_out;
   logic 	      signResult, sign_corr;
   logic 	      corr_sign;
   logic 	      zeroB;         
   logic 	      convert;
   logic 	      swap;
   logic 	      sub;
   
   logic [59:0]       q1, qm1, qp1, q0, qm0, qp0;
   logic [59:0]       rega_out, regb_out, regc_out, regd_out;
   logic [119:0]      regr_out;
   logic [2:0] 	      sel_muxa, sel_muxb;
   logic 	      sel_muxr;   
   logic 	      load_rega, load_regb, load_regc, load_regd, load_regr;
   logic 	      load_regp, load_regs;

   logic 	      exp_odd, exp_odd1;
   logic 	      start1;   
   logic 	      P1;
   logic 	      op_type1;
   logic [12:0]       expF1;
   logic [52:0]       mantissaA1;
   logic [52:0]       mantissaB1;
   logic [2:0] 	      sel_inv1;
   logic 	      signResult1;
   logic 	      Invalid1;   

  //  op_type : fdiv=0, fsqrt=1
   assign Float1 = op1;
   assign Float2 = op_type ? op1 : op2;   
   
   // Exception detection
   exception_div exc1 (.A(Float1), .B(Float2), .op_type, .Ztype(sel_inv), .Invalid);

   // Determine Sign/Mantissa
   assign signResult = ((Float1[63]^Float2[63])&~op_type);
   assign mantissaA = {vdd, Float1[51:0]};
   assign mantissaB = {vdd, Float2[51:0]};
   
   // Perform Exponent Subtraction - expA - expB + Bias   
   assign exp1 = {2'b0, Float1[62:52]};
   assign exp2 = {2'b0, Float2[62:52]};
   // bias : DP = 2^{11-1}-1 = 1023
   assign bias = {3'h0, 10'h3FF};
   // Divide exponent
   assign exp_diff = {2'b0, exp1} - {2'b0, exp2} + {2'b0, bias};      
   
   // Sqrt exponent (check if exponent is odd)
   assign exp_odd = Float1[52] ? 1'b0 : 1'b1;
   assign exp_sqrt = {1'b0, exp1} + {4'h0, 10'h3ff} + {13'b0, exp_odd};   
   // Choose correct exponent
   assign expF = op_type ? exp_sqrt[13:1] : exp_diff;   

   flopenr #(1) rega (clk, reset, 1'b1, exp_odd, exp_odd1);
   flopenr #(1) regb (clk, reset, 1'b1, P, P1);
   flopenr #(1) regc (clk, reset, 1'b1, op_type, op_type1);
   flopenr #(13) regd (clk, reset, 1'b1, expF, expF1);
   flopenr #(53) rege (clk, reset, 1'b1, mantissaA, mantissaA1);
   flopenr #(53) regf (clk, reset, 1'b1, mantissaB, mantissaB1);
   flopenr #(1) regg (clk, reset, 1'b1, start, start1);
   flopenr #(3) regh (clk, reset, 1'b1, sel_inv, sel_inv1);
   flopenr #(1) regj (clk, reset, 1'b1, signResult, signResult1);
   flopenr #(1) regk (clk, reset, 1'b1, Invalid, Invalid1);      
   
   // Main Goldschmidt/Division Routine
   divconv_pipe goldy (.q1, .qm1, .qp1, .q0, .qm0, .qp0, 
		       .rega_out, .regb_out, .regc_out, .regd_out,
		       .regr_out, .d(mantissaB1), .n(mantissaA1), 
		       .sel_muxa, .sel_muxb, .sel_muxr, .reset, .clk,
		       .load_rega, .load_regb, .load_regc, .load_regd,
		       .load_regr, .load_regs, .load_regp,
		       .P(P1), .op_type(op_type1), .exp_odd(exp_odd1));

   // FSM : control divider
   fsm_fpdiv_pipe control (.clk, .reset, .start(start), .op_type(op_type1), .P(P1),
			   .done, .load_rega, .load_regb, .load_regc, .load_regd, 
			   .load_regr, .load_regs, .load_regp,
			   .sel_muxa, .sel_muxb, .sel_muxr, .divBusy(FDivBusyE));
   
   // Round the mantissa to a 52-bit value, with the leading one
   // removed. The rounding units also handles special cases and 
   // set the exception flags.
   rounder_div round1 (.rm, .P(P1), .OvEn(1'b0), .UnEn(1'b0), .exp_diff(expF1), 
   		       .sel_inv(sel_inv1), .Invalid(Invalid1), .SignR(signResult1),
		       .Float1(op1), .Float2(op2),
		       .XNaNQ, .YNaNQ, .XZeroQ, .YZeroQ, 
		       .XInfQ, .YInfQ, .op_type(op_type1),		       
		       .q1, .qm1, .qp1, .q0, .qm0, .qp0, .regr_out, 
                       .Result, .Flags(FlagsIn));

   // Store the final result and the exception flags in registers.
   flopenr #(64) regl (clk, reset, done, Result, AS_Result);
   flopenr #(5) regn (clk, reset, done, FlagsIn, Flags);   
   
endmodule // fpdiv_pipe

