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
   input logic 	      clk,
   input logic 	      reset,
   input logic 	      start,
   input logic [63:0]   op1,		// 1st input operand (A)
   input logic [63:0]   op2,		// 2nd input operand (B)
   input logic [1:0]    rm,		// Rounding mode - specify values 
   input logic 	      op_type,	// Function opcode
   input logic 	      P,   		// Result Precision (0 for double, 1 for single)
   input logic 	      OvEn,		// Overflow trap enabled
   input logic 	      UnEn,   	// Underflow trap enabled
   output logic         done,
   output logic         FDivBusyE,
   output logic [63:0]  AS_Result,	// Result of operation
   output logic [4:0]   Flags);   	// IEEE exception flags 


   logic [63:0]   Float1; 
   logic [63:0] 	Float2;
   
   logic [12:0] 	exp1, exp2, expF;
   logic [12:0] 	exp_diff, bias;
   logic [13:0] 	exp_sqrt;
   logic [12:0] 	exp_s;
   logic [12:0] 	exp_c;
   
   logic [10:0] 	exponent;
   logic [63:0] 	Result;   
   logic [52:0] 	mantissaA;
   logic [52:0] 	mantissaB; 
   
   logic [2:0] 	sel_inv;
   logic		      Invalid;
   logic [4:0] 	FlagsIn;   	
   logic 	      signResult;      
   logic 	      convert;
   logic          sub;
   
   logic [63:0] 	q1, qm1, qp1, q0, qm0, qp0;
   logic [63:0] 	rega_out, regb_out, regc_out, regd_out;
   logic [127:0]  regr_out;
   logic [2:0] 	sel_muxa, sel_muxb;
   logic 	      sel_muxr;   
   logic 	      load_rega, load_regb, load_regc, load_regd, load_regr;

   logic 	      load_regs;
   logic          exp_cout1, exp_cout2;
   logic          exp_odd, open;
   
   // div/sqrt
         //  fdiv  = 0
         //  fsqrt = 1

   // Convert the input operands to their appropriate forms based on 
   // the orignal operands, the op_type , and their precision P. 
   // Single precision inputs are converted to double precision 
   // and the sign of the first operand is set appropratiately based on
   // if the operation is absolute value or negation.   
   convert_inputs_div conv1 (.op1, .op2, .op_type, .P, 
                           // outputs:
                           .Float1, .Float2b(Float2));

   // Test for exceptions and return the "Invalid Operation" and
   // "Denormalized" Input Flags. The "sel_inv" is used in
   // the third pipeline stage to select the result. Also, op1_Norm
   // and op2_Norm are one if op1 and op2 are not zero or denormalized.
   // sub is one if the effective operation is subtaction.   
   exception_div exc1 (.A(Float1), .B(Float2), .op_type,
                     // output:
                     .Ztype(sel_inv), .Invalid);

   // Determine Sign/Mantissa
   assign signResult = (Float1[63]^Float2[63]);
   assign mantissaA = {1'b1, Float1[51:0]};
   assign mantissaB = {1'b1, Float2[51:0]};
   // Perform Exponent Subtraction - expA - expB + Bias   
   assign exp1 = {2'b0, Float1[62:52]};
   assign exp2 = {2'b0, Float2[62:52]};
   assign bias = {3'h0, 10'h3FF};
   // Divide exponent
   assign {exp_cout1, open, exp_diff} = exp1 - exp2 + bias;
   
   // Sqrt exponent (check if exponent is odd)
   assign exp_odd = Float1[52] ? 1'b0 : 1'b1;
   assign {exp_cout2, exp_sqrt} = {1'b0, exp1} + {4'h0, 10'h3ff} + exp_odd;
   // Choose correct exponent
   assign expF = op_type ? exp_sqrt[13:1] : exp_diff;   

   // Main Goldschmidt/Division Routine   
   divconv goldy (.q1, .qm1, .qp1, .q0, .qm0, .qp0, .rega_out, .regb_out, .regc_out, .regd_out,
		  .regr_out, .d(mantissaB), .n(mantissaA), .sel_muxa, .sel_muxb, .sel_muxr, 
		  .reset, .clk,  .load_rega, .load_regb, .load_regc, .load_regd,
		  .load_regr, .load_regs, .P, .op_type, .exp_odd);

   // FSM : control divider   
   fsm control (.clk, .reset, .start, .op_type,
               // outputs:
               .done, .load_rega, .load_regb, .load_regc, .load_regd, 
		         .load_regr, .load_regs, .sel_muxa, .sel_muxb, .sel_muxr, 
		         .divBusy(FDivBusyE));
   
   // Round the mantissa to a 52-bit value, with the leading one
   // removed. The rounding units also handles special cases and 
   // set the exception flags.   
   rounder_div round1 (.rm, .P, .OvEn, .UnEn, .exp_diff(expF), 
   		            .sel_inv, .Invalid, .SignR(signResult), 
		               .q1, .qm1, .qp1, .q0, .qm0, .qp0, .regr_out, 
                     // outputs:
                     .Result, .Flags(FlagsIn));

   // Store the final result and the exception flags in registers.
   flopenr #(64) rega (clk, reset, done, Result, AS_Result);  
   flopenr #(5) regc (clk, reset, done, FlagsIn, Flags);   
   
endmodule // fpadd

