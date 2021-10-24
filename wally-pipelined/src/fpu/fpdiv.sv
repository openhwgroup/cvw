///////////////////////////////////////////
//
// Written: James Stine
// Modified: 8/1/2018
//
// Purpose: Floating point divider/square root top unit (Goldschmidt)
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

// `timescale 1ps/1ps
module fpdiv (
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
   
   logic [63:0]       Float1; 
   logic [63:0]       Float2;
   
   logic [12:0]       exp1, exp2, expF;
   logic [12:0]       exp_diff, bias;
   logic [13:0]       exp_sqrt;
   logic [63:0]       Result;   
   logic [52:0]       mantissaA;
   logic [52:0]       mantissaB; 
   
   logic [2:0] 	      sel_inv;
   logic 	      Invalid;
   logic [4:0] 	      FlagsIn;   	
   logic 	      signResult;      
   
   logic [59:0]       q1, qm1, qp1, q0, qm0, qp0;
   logic [59:0]       rega_out, regb_out, regc_out, regd_out;
   logic [119:0]      regr_out;
   logic [2:0] 	      sel_muxa, sel_muxb;
   logic 	      sel_muxr;   
   logic 	      load_rega, load_regb, load_regc, load_regd, load_regr;
   
   logic 	      load_regs;
   logic 	      exp_cout1, exp_cout2;
   logic 	      exp_odd, open;
   
   //  op_type : fdiv=0, fsqrt=1
   assign Float1 = op1;
   assign Float2 = op_type ? op1 : op2;   
   
   // Exception detection
   exception_div exc1 (.A(Float1), .B(Float2), .op_type, .Ztype(sel_inv), .Invalid);
   
   // Determine Sign/Mantissa
   assign signResult = (Float1[63]^Float2[63]);
   assign mantissaA = {1'b1, Float1[51:0]};
   assign mantissaB = {1'b1, Float2[51:0]};
   // Perform Exponent Subtraction - expA - expB + Bias   
   assign exp1 = {2'b0, Float1[62:52]};
   assign exp2 = {2'b0, Float2[62:52]};
   assign bias = {3'h0, 10'h3FF};
   // Divide exponent
   assign {exp_cout1, open, exp_diff} = {2'b0, exp1} - {2'b0, exp2} + {2'b0, bias};
   
   // Sqrt exponent (check if exponent is odd)
   assign exp_odd = Float1[52] ? 1'b0 : 1'b1;
   assign {exp_cout2, exp_sqrt} = {1'b0, exp1} + {4'h0, 10'h3ff} + {13'b0, exp_odd};
   // Choose correct exponent
   assign expF = op_type ? exp_sqrt[13:1] : exp_diff;   
   
   // Main Goldschmidt/Division Routine   
   divconv goldy (.q1, .qm1, .qp1, .q0, .qm0, .qp0, .rega_out, .regb_out, .regc_out, .regd_out,
		  .regr_out, .d(mantissaB), .n(mantissaA), .sel_muxa, .sel_muxb, .sel_muxr, 
		  .reset, .clk,  .load_rega, .load_regb, .load_regc, .load_regd,
		  .load_regr, .load_regs, .P, .op_type, .exp_odd);
   
   // FSM : control divider   
   fsm_fpdiv control (.clk, .reset, .start, .op_type,
		      .done, .load_rega, .load_regb, .load_regc, .load_regd, 
		      .load_regr, .load_regs, .sel_muxa, .sel_muxb, .sel_muxr, 
		      .divBusy(FDivBusyE));
   
   // Round the mantissa to a 52-bit value, with the leading one
   // removed. The rounding units also handles special cases and 
   // set the exception flags.   
   rounder_div round1 (.rm, .P, .OvEn, .UnEn, .exp_diff(expF), 
   		       .sel_inv, .Invalid, .SignR(signResult),
		       .Float1(op1), .Float2(op2),
		       .XNaNQ, .YNaNQ, .XZeroQ, .YZeroQ, 
		       .XInfQ, .YInfQ, .op_type,		       
		       .q1, .qm1, .qp1, .q0, .qm0, .qp0, .regr_out, 
                       .Result, .Flags(FlagsIn));
   
   // Store the final result and the exception flags in registers.
   flopenr #(64) rega (clk, reset, done, Result, AS_Result);  
   flopenr #(5) regc (clk, reset, done, FlagsIn, Flags);   
   
endmodule // fpadd

