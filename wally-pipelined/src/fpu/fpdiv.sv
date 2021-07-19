//
// File name : fpdiv
// Title     : Floating-Point Divider/Square-Root
// project   : FPU
// Library   : fpdiv
// Author(s) : James E. Stine, Jr.
// Purpose   : definition of main unit to floating-point div/sqrt
// notes :   
//
// Copyright Oklahoma State University
//
// Basic Operations
//
// Step 1: Load operands, set flags, and convert SP to DP
// Step 2: Check for special inputs ( +/- Infinity,  NaN)
// Step 3: Exponent Logic
// Step 4: Divide/Sqrt using Goldschmidt
// Step 5: Normalize the result.//
//   Shift left until normalized.  Normalized when the value to the 
//   left of the binrary point is 1.
// Step 6: Round the result.// 
// Step 7: Put quotient/remainder onto output.
//

// `timescale 1ps/1ps
module fpdiv (
   input logic [63:0] op1,		// 1st input operand (A)
   input logic [63:0] op2,		// 2nd input operand (B)
   input logic [1:0] 	rm,		// Rounding mode - specify values 
   input logic 	op_type,	// Function opcode
   input logic 	P,   		// Result Precision (0 for double, 1 for single)
   input logic 	OvEn,		// Overflow trap enabled
   input logic 	UnEn,   	// Underflow trap enabled
   input logic 	start,
   input logic 	reset,
   input logic 	clk,
   output logic done,
   output logic   FDivBusyE,
   output logic   HoldInputs,
   output logic [63:0] AS_Result,	// Result of operation
   output logic [4:0]  Flags);   	// IEEE exception flags 
   logic 	 Denorm;   	// Denorm on input or output
   // output 	 done;

   supply1 	  vdd;
   supply0 	  vss;   

   wire [63:0] 	 Float1; 
   wire [63:0] 	 Float2;
   wire [63:0] 	 IntValue;
   
   wire [12:0] 	 exp1, exp2, expF;
   wire [12:0] 	 exp_diff, bias;
   wire [13:0] 	 exp_sqrt;
   wire [12:0] 	 exp_s;
   wire [12:0] 	 exp_c;
   
   wire [10:0] 	 exponent, exp_pre;
   wire [63:0] 	 Result;   
   wire [52:0] 	 mantissaA;
   wire [52:0] 	 mantissaB; 
   wire [63:0] 	 sum, sum_tc, sum_corr, sum_norm;
   
   wire [5:0] 	 align_shift;
   wire [5:0] 	 norm_shift;
   wire [2:0] 	 sel_inv;
   wire		 op1_Norm, op2_Norm;
   wire		 opA_Norm, opB_Norm;
   wire		 Invalid;
   wire 	 DenormIn, DenormIO;
   wire [4:0] 	 FlagsIn;   	
   wire 	 exp_gt63;
   wire 	 Sticky_out;
   wire 	 signResult, sign_corr;
   wire          corr_sign;
   wire 	 zeroB;         
   wire 	 convert;
   wire          swap;
   wire          sub;
   
   wire [63:0] 	 q1, qm1, qp1, q0, qm0, qp0;
   wire [63:0] 	 rega_out, regb_out, regc_out, regd_out;
   wire [127:0]  regr_out;
   wire [2:0] 	 sel_muxa, sel_muxb;
   wire 	 sel_muxr;   
   wire 	 load_rega, load_regb, load_regc, load_regd, load_regr;

   wire 	 donev, sel_muxrv, sel_muxsv;
   wire [1:0] 	 sel_muxav, sel_muxbv;   
   wire 	 load_regav, load_regbv, load_regcv;
   wire 	 load_regrv, load_regs;
   logic exp_cout1, exp_cout2;
   logic exp_odd, open;
   // logic reset;
   
   // Convert the input operands to their appropriate forms based on 
   // the orignal operands, the op_type , and their precision P. 
   // Single precision inputs are converted to double precision 
   // and the sign of the first operand is set appropratiately based on
   // if the operation is absolute value or negation.   
   convert_inputs_div conv1 (Float1, Float2, op1, op2, op_type, P);

   // Test for exceptions and return the "Invalid Operation" and
   // "Denormalized" Input Flags. The "sel_inv" is used in
   // the third pipeline stage to select the result. Also, op1_Norm
   // and op2_Norm are one if op1 and op2 are not zero or denormalized.
   // sub is one if the effective operation is subtaction.   
   exception_div exc1 (sel_inv, Invalid, DenormIn, op1_Norm, op2_Norm, 
		       Float1, Float2, op_type);

   // Determine Sign/Mantissa
   assign signResult = (Float1[63]^Float2[63]);
   assign mantissaA = {vdd, Float1[51:0]};
   assign mantissaB = {vdd, Float2[51:0]};
   // Perform Exponent Subtraction - expA - expB + Bias   
   assign exp1 = {2'b0, Float1[62:52]};
   assign exp2 = {2'b0, Float2[62:52]};
   // bias : DP = 2^{11-1}-1 = 1023
   assign bias = {3'h0, 10'h3FF};
   // Divide exponent
   csa #(13) csa1 (exp1, ~exp2, bias, exp_s, exp_c);
   // adder #(14) explogic1 ({vss, exp_s}, {vss, exp_c}, 1'b1, {open, exp_diff}, exp_cout1);
   assign {exp_cout1, open, exp_diff} = {vss, exp_s} + {vss, exp_c} + 1'b1;
   
   // Sqrt exponent (check if exponent is odd)
   assign exp_odd = Float1[52] ? vss : vdd;
   // adder #(14) explogic2 ({vss, exp1}, {4'h0, 10'h3ff}, exp_odd, exp_sqrt, exp_cout2);
   assign {exp_cout2, exp_sqrt} = {vss, exp1} + {4'h0, 10'h3ff} + exp_odd;
   // Choose correct exponent
   assign expF = op_type ? exp_sqrt[13:1] : exp_diff;   

   // Main Goldschmidt/Division Routine   
   divconv goldy (q1, qm1, qp1, q0, qm0, qp0, rega_out, regb_out, regc_out, regd_out,
		  regr_out, mantissaB, mantissaA, sel_muxa, sel_muxb, sel_muxr, 
		  reset, clk,  load_rega, load_regb, load_regc, load_regd,
		  load_regr, load_regs, P, op_type, exp_odd);

   // FSM : control divider   
   fsm control (done, load_rega, load_regb, load_regc, load_regd, 
		    load_regr, load_regs, sel_muxa, sel_muxb, sel_muxr, 
		    clk, reset, start, op_type, FDivBusyE, HoldInputs);
   
   // Round the mantissa to a 52-bit value, with the leading one
   // removed. The rounding units also handles special cases and 
   // set the exception flags.   
   rounder_div round1 (Result, DenormIO, FlagsIn, 
		   rm, P, OvEn, UnEn, expF, 
   		   sel_inv, Invalid, DenormIn, signResult, 
		   q1, qm1, qp1, q0, qm0, qp0, regr_out);

   // Store the final result and the exception flags in registers.
   flopenr #(64) rega (clk, reset, done, Result, AS_Result);
   flopenr #(1) regb (clk, reset, done, DenormIO, Denorm);   
   flopenr #(5) regc (clk, reset, done, FlagsIn, Flags);   
   
endmodule // fpadd

