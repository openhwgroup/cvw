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
// Step 1: Load operands, set flags, and AddConvertM SP to DP
// Step 2: Check for special inputs ( +/- Infinity,  NaN)
// Step 3: Compare exponents.  Swap the operands of exp1 < exp2
//         or of (exp1 = exp2 AND mnt1 < mnt2)
// Step 4: Shift the mantissa corresponding to the smaller AddExponentM, 
//          and extend precision by three bits to the right.
// Step 5: Add or subtract the mantissas.
// Step 6: Normalize the result.//
//   Shift left until normalized.  Normalized when the value to the 
//   left of the binrary point is 1.
// Step 7: Round the result.// 
// Step 8: Put AddSumM onto output.
//


module fpuaddcvt2 (AddResultM, AddFlagsM, AddDenormM, AddSumM, AddSumTcM, AddSelInvM, AddExpPostSumM, AddCorrSignM, AddOp1NormM, AddOp2NormM, AddOpANormM, AddOpBNormM, AddInvalidM, AddDenormInM, AddConvertM, AddSwapM, AddSignAM, AddFloat1M, AddFloat2M, AddExp1DenormM, AddExp2DenormM, AddExponentM, AddOp1M, AddOp2M, AddRmM, AddOpTypeM, AddPM, AddOvEnM, AddUnEnM);

   input [63:0] AddOp1M;		// 1st input operand (A)
   input [63:0] AddOp2M;		// 2nd input operand (B)
   input [2:0] 	AddRmM;		// Rounding mode - specify values 
   input [3:0]	AddOpTypeM;	// Function opcode
   input 	AddPM;   		// Result Precision (0 for double, 1 for single)
   input 	AddOvEnM;		// Overflow trap enabled
   input 	AddUnEnM;   	// Underflow trap enabled
   input [63:0] AddSumM, AddSumTcM;
   input [63:0] 	 AddFloat1M; 
   input [63:0] 	 AddFloat2M;
   input [10:0]	 AddExp1DenormM, AddExp2DenormM;
   input [10:0] 	 AddExponentM, AddExpPostSumM; //exp_pre;
   //input		 exp_valid;
   input [3:0] 	 AddSelInvM;
   input		 AddOp1NormM, AddOp2NormM;
   input		 AddOpANormM, AddOpBNormM;
   input		 AddInvalidM;
   input 	 AddDenormInM; 
   input 	 AddSignAM; 
   input         AddCorrSignM;
   input 	 AddConvertM;
   input          AddSwapM;
   // input 	 AddNormOvflowM;

   output [63:0] AddResultM;	// Result of operation
   output [4:0]  AddFlagsM;   	// IEEE exception flags 
   output 	 AddDenormM;   	// AddDenormM on input or output   

   wire          P;
   assign P = AddPM | AddOpTypeM[2];

   wire [10:0]   exp_pre;
   wire [63:0] 	 Result;   
   wire [63:0] 	 sum_norm, sum_norm_w_bypass;
   wire [5:0] 	 norm_shift, norm_shift_denorm;
   wire          exp_valid;
   wire		 DenormIO;
   wire [4:0] 	 FlagsIn;	
   wire 	 Sticky_out;
   wire 	 sign_corr;
   wire 	 zeroB;         
   wire [10:0]	 AddExpPostSumM;
   wire 	 mantissa_comp;
   wire 	 mantissa_comp_sum;
   wire 	 mantissa_comp_sum_tc;
   wire 	 Float1_sum_comp;
   wire 	 Float2_sum_comp;
   wire 	 Float1_sum_tc_comp;
   wire 	 Float2_sum_tc_comp;
   wire 	 normal_underflow;
   wire [63:0]   sum_corr;
   logic AddNormOvflowM;
 
   //AddExponentM value pre-rounding with considerations for denormalized
   //cases/conversion cases
   assign exp_pre       = AddDenormInM ?
                          ((norm_shift == 6'b001011) ? 11'b00000000001 : (AddSwapM ? AddExp2DenormM : AddExp1DenormM))
                          : (AddConvertM ? 11'b10000111100 : AddExponentM);


   // Finds normal underflow result to determine whether to round final AddExponentM down
   // Comparison between each float and the resulting AddSumM of the primary cla adder/subtractor and cla subtractor
   assign Float1_sum_comp = (AddFloat1M[51:0] > AddSumM[51:0]) ? 1'b0 : 1'b1;
   assign Float2_sum_comp = (AddFloat2M[51:0] > AddSumM[51:0]) ? 1'b0 : 1'b1;
   assign Float1_sum_tc_comp = (AddFloat1M[51:0] > AddSumTcM[51:0]) ? 1'b0 : 1'b1;
   assign Float2_sum_tc_comp = (AddFloat2M[51:0] > AddSumTcM[51:0]) ? 1'b0 : 1'b1;

   // Determines the correct Float value to compare based on AddSwapM result
   assign mantissa_comp_sum = AddSwapM ? Float2_sum_comp : Float1_sum_comp;
   assign mantissa_comp_sum_tc = AddSwapM ? Float2_sum_tc_comp : Float1_sum_tc_comp;

   // Determines the correct comparison result based on operation and sign of resulting AddSumM
   assign mantissa_comp = (AddOpTypeM[0] ^ AddSumM[63]) ? mantissa_comp_sum_tc : mantissa_comp_sum;

   // If the signs are different and both operands aren't denormalized
   // the normal underflow bit is needed and therefore updated.
   assign normal_underflow = ((AddFloat1M[63] ~^ AddFloat2M[63]) & (AddOpANormM | AddOpBNormM)) ? mantissa_comp : 1'b0;

   // Determine the correct sign of the result
   assign sign_corr = ((AddCorrSignM ^ AddSignAM) & ~AddConvertM) ^ AddSumM[63];   
   
   // If the AddSumM is negative, use its two complement instead. 
   // This value has to be 64-bits to correctly handle the 
   // case 10...00
   assign sum_corr = (AddDenormInM & (AddOpANormM | AddOpBNormM) & ( ( (AddFloat1M[63] ~^ AddFloat2M[63]) & AddOpTypeM[0] ) | ((AddFloat1M[63] ^ AddFloat2M[63]) & ~AddOpTypeM[0]) ))
			 ? (AddSumM[63] ? AddSumM : AddSumTcM) : ( (AddOpTypeM[3]) ? AddSumM : (AddSumM[63] ? AddSumTcM : AddSumM));

   // Finds normal underflow result to determine whether to round final AddExponentM down
   //KEP used to be (AddSumM == 16'h0) not sure what it is supposed to be
   assign AddNormOvflowM = (AddDenormInM & (AddSumM == 64'h0) & (AddOpANormM | AddOpBNormM) & ~AddOpTypeM[0]) ? 1'b1 : (AddSumM[63] ? AddSumTcM[52] : AddSumM[52]);

   // Leading-Zero Detector. Determine the size of the shift needed for
   // normalization. If sum_corrected is all zeros, the exp_valid is 
   // zero; otherwise, it is one. 
   lz64 lzd1 (norm_shift, exp_valid, sum_corr);

   assign norm_shift_denorm = (AddDenormInM & ( (~AddOpANormM & ~AddOpBNormM) | normal_underflow)) ? (6'h00) : (norm_shift);

   // Barell shifter used for normalization. It takes as inputs the 
   // the corrected AddSumM and the amount by which the AddSumM should 
   // be right shifted. It outputs the normalized AddSumM. 
   barrel_shifter_l64 bs2 (sum_norm, sum_corr, norm_shift_denorm);
  
   assign sum_norm_w_bypass = (AddOpTypeM[3]) ? (AddOpTypeM[0] ? ~sum_corr : sum_corr) : (sum_norm);

   // Round the mantissa to a 52-bit value, with the leading one
   // removed. If the result is a single precision number, the actual 
   // mantissa is in the upper 23 bits and the lower 29 bits are zero. 
   // At this point, normalization has already been performed, so we know 
   // exactly where the rounding point is. The rounding units also
   // handles special cases and set the exception flags.

   // Changed DenormIO -> AddDenormM and FlagsIn -> AddFlagsM in order to
   // help in processor reservation station detection of load/stores. In
   // other words, the processor would like to know ahead of time that
   // if the result is an exception then don't load or store.
   rounder round1 (Result, DenormIO, FlagsIn, AddRmM, P, AddOvEnM, AddUnEnM, exp_valid, 
		   AddSelInvM, AddInvalidM, AddDenormInM, AddConvertM, sign_corr, exp_pre, norm_shift, sum_norm_w_bypass,
		   AddExpPostSumM, AddOp1NormM, AddOp2NormM, AddFloat1M[63:52], AddFloat2M[63:52],
		   AddNormOvflowM, normal_underflow, AddSwapM, AddOpTypeM, AddSumM);

   // Store the final result and the exception flags in registers.
   assign AddResultM = Result;
   assign {AddDenormM, AddFlagsM} = {DenormIO, FlagsIn};
   
endmodule // fpadd


