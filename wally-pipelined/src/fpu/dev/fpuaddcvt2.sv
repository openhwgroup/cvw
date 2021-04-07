//
// File name : fpadd
// Title     : Floating-Point Adder/Subtractor
// project   : FPU
// Library   : fpadd
// Author(s) : James E. Stine, Jr., Brett Mathis
// Purpose   : definition of main unit to floating-point add/sub
// notes :   
//
// Copyright Oklahoma State University
// Copyright AFRL
//
// Basic and Denormalized Operations
//
// Step 1: Load operands, set flags, and convert SP to DP
// Step 2: Check for special inputs ( +/- Infinity,  NaN)
// Step 3: Compare exponents.  Swap the operands of exp1 < exp2
//         or of (exp1 = exp2 AND mnt1 < mnt2)
// Step 4: Shift the mantissa corresponding to the smaller exponent, 
//          and extend precision by three bits to the right.
// Step 5: Add or subtract the mantissas.
// Step 6: Normalize the result.//
//   Shift left until normalized.  Normalized when the value to the 
//   left of the binrary point is 1.
// Step 7: Round the result.// 
// Step 8: Put sum onto output.
//


module fpuaddcvt2sv (AS_Result, Flags, Denorm, sum, sum_tc, sel_inv, exponent_postsum, corr_sign, op1_Norm, op2_Norm, opA_Norm, opB_Norm, Invalid, DenormIn, exp_valid, convert, swap, normal_overflow, signA, Float1, Float2, exp1_denorm, exp2_denorm, exponent, op1, op2, rm, op_type, Pin, OvEn, UnEn);

   input [63:0] op1;		// 1st input operand (A)
   input [63:0] op2;		// 2nd input operand (B)
   input [2:0] 	rm;		// Rounding mode - specify values 
   input [3:0]	op_type;	// Function opcode
   input 	Pin;   		// Result Precision (0 for double, 1 for single)
   input 	OvEn;		// Overflow trap enabled
   input 	UnEn;   	// Underflow trap enabled
   input [63:0] sum, sum_tc;
   input [63:0] 	 Float1; 
   input [63:0] 	 Float2;
   input [10:0]	 exp1_denorm, exp2_denorm;
   input [10:0] 	 exponent, exponent_postsum; //exp_pre;
   input		 exp_valid;
   input [3:0] 	 sel_inv;
   input		 op1_Norm, op2_Norm;
   input		 opA_Norm, opB_Norm;
   input		 Invalid;
   input 	 DenormIn; 
   input 	 signA; 
   input         corr_sign;
   input 	 convert;
   input          swap;
   input 	 normal_overflow;

   output [63:0] AS_Result;	// Result of operation
   output [4:0]  Flags;   	// IEEE exception flags 
   output 	 Denorm;   	// Denorm on input or output   

   wire          P;
   assign P = Pin | op_type[2];

   wire [10:0]   exp_pre;
   wire [63:0] 	 Result;   
   wire [63:0] 	 sum_norm, sum_norm_w_bypass;
   wire [5:0] 	 norm_shift, norm_shift_denorm;
   wire		 DenormIO;
   wire [4:0] 	 FlagsIn;	
   wire 	 Sticky_out;
   wire 	 sign_corr;
   wire 	 zeroB;         
   wire [10:0]	 exponent_postsum;
   wire 	 mantissa_comp;
   wire 	 mantissa_comp_sum;
   wire 	 mantissa_comp_sum_tc;
   wire 	 Float1_sum_comp;
   wire 	 Float2_sum_comp;
   wire 	 Float1_sum_tc_comp;
   wire 	 Float2_sum_tc_comp;
   wire 	 normal_underflow;
   wire [63:0]   sum_corr;
 
   //exponent value pre-rounding with considerations for denormalized
   //cases/conversion cases
   assign exp_pre       = DenormIn ?
                          ((norm_shift == 6'b001011) ? 11'b00000000001 : (swap ? exp2_denorm : exp1_denorm))
                          : (convert ? 11'b10000111100 : exponent);


   // Finds normal underflow result to determine whether to round final exponent down
   // Comparison between each float and the resulting sum of the primary cla adder/subtractor and cla subtractor
   assign Float1_sum_comp = (Float1[51:0] > sum[51:0]) ? 1'b0 : 1'b1;
   assign Float2_sum_comp = (Float2[51:0] > sum[51:0]) ? 1'b0 : 1'b1;
   assign Float1_sum_tc_comp = (Float1[51:0] > sum_tc[51:0]) ? 1'b0 : 1'b1;
   assign Float2_sum_tc_comp = (Float2[51:0] > sum_tc[51:0]) ? 1'b0 : 1'b1;

   // Determines the correct Float value to compare based on swap result
   assign mantissa_comp_sum = swap ? Float2_sum_comp : Float1_sum_comp;
   assign mantissa_comp_sum_tc = swap ? Float2_sum_tc_comp : Float1_sum_tc_comp;

   // Determines the correct comparison result based on operation and sign of resulting sum
   assign mantissa_comp = (op_type[0] ^ sum[63]) ? mantissa_comp_sum_tc : mantissa_comp_sum;

   // If the signs are different and both operands aren't denormalized
   // the normal underflow bit is needed and therefore updated.
   assign normal_underflow = ((Float1[63] ~^ Float2[63]) & (opA_Norm | opB_Norm)) ? mantissa_comp : 1'b0;

   // Determine the correct sign of the result
   assign sign_corr = ((corr_sign ^ signA) & ~convert) ^ sum[63];   
   
   // If the sum is negative, use its two complement instead. 
   // This value has to be 64-bits to correctly handle the 
   // case 10...00
   assign sum_corr = (DenormIn & (opA_Norm | opB_Norm) & ( ( (Float1[63] ~^ Float2[63]) & op_type[0] ) | ((Float1[63] ^ Float2[63]) & ~op_type[0]) ))
			 ? (sum[63] ? sum : sum_tc) : ( (op_type[3]) ? sum : (sum[63] ? sum_tc : sum));

   // Finds normal underflow result to determine whether to round final exponent down
   assign normal_overflow = (DenormIn & (sum == 16'h0) & (opA_Norm | opB_Norm) & ~op_type[0]) ? 1'b1 : (sum[63] ? sum_tc[52] : sum[52]);

   // Leading-Zero Detector. Determine the size of the shift needed for
   // normalization. If sum_corrected is all zeros, the exp_valid is 
   // zero; otherwise, it is one. 
   lz64 lzd1 (norm_shift, exp_valid, sum_corr);

   assign norm_shift_denorm = (DenormIn & ( (~opA_Norm & ~opB_Norm) | normal_underflow)) ? (6'h00) : (norm_shift);

   // Barell shifter used for normalization. It takes as inputs the 
   // the corrected sum and the amount by which the sum should 
   // be right shifted. It outputs the normalized sum. 
   barrel_shifter_l64 bs2 (sum_norm, sum_corr, norm_shift_denorm);
  
   assign sum_norm_w_bypass = (op_type[3]) ? (op_type[0] ? ~sum_corr : sum_corr) : (sum_norm);

   // Round the mantissa to a 52-bit value, with the leading one
   // removed. If the result is a single precision number, the actual 
   // mantissa is in the upper 23 bits and the lower 29 bits are zero. 
   // At this point, normalization has already been performed, so we know 
   // exactly where the rounding point is. The rounding units also
   // handles special cases and set the exception flags.

   // Changed DenormIO -> Denorm and FlagsIn -> Flags in order to
   // help in processor reservation station detection of load/stores. In
   // other words, the processor would like to know ahead of time that
   // if the result is an exception then don't load or store.
   rounder round1 (Result, DenormIO, FlagsIn, rm, P, OvEn, UnEn, exp_valid, 
		   sel_inv, Invalid, DenormIn, convert, sign_corr, exp_pre, norm_shift, sum_norm_w_bypass,
		   exponent_postsum, op1_Norm, op2_Norm, Float1[63:52], Float2[63:52],
		   normal_overflow, normal_underflow, swap, op_type, sum);

   // Store the final result and the exception flags in registers.
   assign AS_Result = Result;
   assign {Denorm, Flags} = {DenormIO, FlagsIn};
   
endmodule // fpadd


