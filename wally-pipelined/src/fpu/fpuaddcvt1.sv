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


module fpuaddcvt1 (sum, sum_tc, sel_inv, exponent_postsum, corr_sign, op1_Norm, op2_Norm, opA_Norm, opB_Norm, Invalid, DenormIn, convert, swap, normal_overflow, signA, Float1, Float2, exp1_denorm, exp2_denorm, exponent, op1, op2, rm, op_type, Pin, OvEn, UnEn);

   input [63:0] op1;		// 1st input operand (A)
   input [63:0] op2;		// 2nd input operand (B)
   input [2:0] 	rm;		// Rounding mode - specify values 
   input [3:0]	op_type;	// Function opcode
   input 	Pin;   		// Result Precision (0 for double, 1 for single)
   input 	OvEn;		// Overflow trap enabled
   input 	UnEn;   	// Underflow trap enabled

   wire          P;
   assign P = Pin | op_type[2];

   wire [63:0] 	 IntValue;
   wire [11:0] 	 exp1, exp2;
   wire [11:0] 	 exp_diff1, exp_diff2;
   wire [11:0] 	 exp_shift;
   wire [51:0] 	 mantissaA;
   wire [56:0] 	 mantissaA1;
   wire [63:0] 	 mantissaA3;
   wire [51:0] 	 mantissaB; 
   wire [56:0] 	 mantissaB1, mantissaB2;
   wire [63:0] 	 mantissaB3;
   wire 	 exp_gt63;
   wire 	 Sticky_out;
   wire          sub;
   wire 	 zeroB;
   wire [5:0]	 align_shift; 

   output [63:0] 	 Float1; 
   output [63:0] 	 Float2;
   output [10:0] 	 exponent;
   output [10:0]	 exponent_postsum;
   output [10:0]	 exp1_denorm, exp2_denorm;
   output [63:0] sum, sum_tc;
   output [3:0]  sel_inv;
   output        corr_sign;
   output 	 signA;
   output	 op1_Norm, op2_Norm;
   output	 opA_Norm, opB_Norm;
   output	 Invalid;
   output 	 DenormIn;
//   output 	 exp_valid;
   output 	 convert;
   output        swap;
   output 	 normal_overflow;
   wire [5:0]	 ZP_mantissaA;
   wire [5:0]	 ZP_mantissaB;
   wire		 ZV_mantissaA;
   wire		 ZV_mantissaB;

   // Convert the input operands to their appropriate forms based on 
   // the orignal operands, the op_type , and their precision P. 
   // Single precision inputs are converted to double precision 
   // and the sign of the first operand is set appropratiately based on
   // if the operation is absolute value or negation. 

   convert_inputs conv1 (Float1, Float2, op1, op2, op_type, P);

   // Test for exceptions and return the "Invalid Operation" and
   // "Denormalized" Input Flags. The "sel_inv" is used in
   // the third pipeline stage to select the result. Also, op1_Norm
   // and op2_Norm are one if op1 and op2 are not zero or denormalized.
   // sub is one if the effective operation is subtaction. 

   exception exc1 (sel_inv, Invalid, DenormIn, op1_Norm, op2_Norm, sub, 
		   Float1, Float2, op_type);

   // Perform Exponent Subtraction (used for alignment). For performance
   // both exponent subtractions are performed in parallel. This was 
   // changed to a behavior level to allow the tools to  try to optimize
   // the two parallel additions. The input values are zero-extended to 12 
   // bits prior to performing the addition. 

   assign exp1 = {1'b0, Float1[62:52]};
   assign exp2 = {1'b0, Float2[62:52]};
   assign exp_diff1 = exp1 - exp2;
   assign exp_diff2 = DenormIn ? ({Float2[63], exp2[10:0]} - {Float1[63], exp1[10:0]}): exp2 - exp1;

   // The second operand (B) should be set to zero, if op_type does not
   // specify addition or subtraction
   assign zeroB = op_type[2] | op_type[1];

   // Swapped operands if zeroB is not one and exp1 < exp2. 
   // Swapping causes exp2 to be used for the result exponent. 
   // Only the exponent of the larger operand is used to determine
   // the final result. 
   assign swap = exp_diff1[11] & ~zeroB;
   assign exponent = swap ? exp2[10:0] : exp1[10:0];
   assign exponent_postsum = swap ? exp2[10:0] : exp1[10:0];
   assign mantissaA = swap ? Float2[51:0] : Float1[51:0];
   assign mantissaB = swap ? Float1[51:0] : Float2[51:0];
   assign signA     = swap ? Float2[63] : Float1[63];   

   // Leading-Zero Detector. Determine the size of the shift needed for
   // normalization. If sum_corrected is all zeros, the exp_valid is 
   // zero; otherwise, it is one. 
   // modified to 52 bits to detect leading zeroes on denormalized mantissas
   lz52 lz_norm_1 (ZP_mantissaA, ZV_mantissaA, mantissaA);
   lz52 lz_norm_2 (ZP_mantissaB, ZV_mantissaB, mantissaB);

   // Denormalized exponents created by subtracting the leading zeroes from the original exponents
   assign exp1_denorm = swap ? (exp1 - ZP_mantissaB) : (exp1 - ZP_mantissaA);
   assign exp2_denorm = swap ? (exp2 - ZP_mantissaA) : (exp2 - ZP_mantissaB);

   // Determine the alignment shift and limit it to 63. If any bit from 
   // exp_shift[6] to exp_shift[11] is one, then shift is set to all ones. 
   assign exp_shift = swap ? exp_diff2 : exp_diff1;
   assign exp_gt63 = exp_shift[11] | exp_shift[10] | exp_shift[9] 
     | exp_shift[8] | exp_shift[7] | exp_shift[6];
   assign align_shift = exp_shift | {6{exp_gt63}};

   // Unpack the 52-bit mantissas to 57-bit numbers of the form.
   //    001.M[51]M[50] ... M[1]M[0]00
   // Unless the number has an exponent of zero, in which case it
   // is unpacked as
   //    000.00 ... 00
   // This effectively flushes denormalized values to zero. 
   // The three bits of to the left of the binary point prevent overflow
   // and loss of sign information. The two bits to the right of the 
   // original mantissa form the "guard" and "round" bits that are used
   // to round the result. 
   assign opA_Norm = swap ? op2_Norm : op1_Norm;
   assign opB_Norm = swap ? op1_Norm : op2_Norm;
   assign mantissaA1 = {2'h0, opA_Norm, mantissaA[51:0]&{52{opA_Norm}}, 2'h0};
   assign mantissaB1 = {2'h0, opB_Norm, mantissaB[51:0]&{52{opB_Norm}}, 2'h0};

   // Perform mantissa alignment using a 57-bit barrel shifter 
   // If any of the bits shifted out are one, Sticky_out is set. 
   // The size of the barrel shifter could be reduced by two bits
   // by not adding the leading two zeros until after the shift. 
   barrel_shifter_r57 bs1 (mantissaB2, Sticky_out, mantissaB1, align_shift);

   // Place either the sign-extened 32-bit value or the original 64-bit value 
   // into IntValue (to be used for integer to floating point conversion)
   assign IntValue [31:0] = op1[31:0];
   assign IntValue [63:32] = op_type[0] ? {32{op1[31]}} : op1[63:32];

   // If doing an integer to floating point conversion, mantissaA3 is set to 
   // IntVal and the prenomalized exponent is set to 1084. Otherwise, 
   // mantissaA3 is simply extended to 64-bits by setting the 7 LSBs to zero, 
   // and the exponent value is left unchanged. 
   // Under denormalized cases, the exponent before the rounder is set to 1
   // if the normal shift value is 11.
   assign convert       = ~op_type[2] & op_type[1];
   assign mantissaA3    = (op_type[3]) ? (op_type[0] ? Float1 : ~Float1) : (DenormIn ? ({12'h0, mantissaA}) : (convert ? IntValue : {mantissaA1, 7'h0}));

   // Put zero in for mantissaB3, if zeroB is one. Otherwise, B is extended to 
   // 64-bits by setting the 7 LSBs to the Sticky_out bit followed by six  
   // zeros. 
   assign mantissaB3[63:7] = (op_type[3]) ? (57'h0) : (DenormIn ? {12'h0, mantissaB[51:7]} : mantissaB2 & {57{~zeroB}});
   assign mantissaB3[6]    = (op_type[3]) ? (1'b0) : (DenormIn ? mantissaB[6] : Sticky_out & ~zeroB);
   assign mantissaB3[5:0]  = (op_type[3]) ? (6'h01) : (DenormIn ? mantissaB[5:0] : 6'h0);

   // The sign of the result needs to be corrected if the true
   // operation is subtraction and the input operands were swapped. 
   assign corr_sign = ~op_type[2]&~op_type[1]&op_type[0]&swap;

   // 64-bit Mantissa Adder/Subtractor
   cla64 add1 (sum, mantissaA3, mantissaB3, sub);

   // 64-bit Mantissa Subtractor - to get the two's complement of the 
   // result when the sign from the adder/subtractor is negative. 
   cla_sub64 sub1 (sum_tc, mantissaB3, mantissaA3);
 
   // Finds normal underflow result to determine whether to round final exponent down
   assign normal_overflow = (DenormIn & (sum == 16'h0) & (opA_Norm | opB_Norm) & ~op_type[0]) ? 1'b1 : (sum[63] ? sum_tc[52] : sum[52]);

endmodule // fpadd


