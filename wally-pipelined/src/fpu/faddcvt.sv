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

module faddcvt(
   input logic          clk,
   input logic          reset,
   input logic          FlushM,     // flush the memory stage
   input logic          StallM,     // stall the memory stage
   input logic  [63:0]  FSrcXE,		// 1st input operand (A)
   input logic  [63:0]  FSrcYE,		// 2nd input operand (B)
   input logic  [2:0]   FOpCtrlE, FOpCtrlM,	// Function opcode
   input logic          FmtE, FmtM,   	// Result Precision (0 for double, 1 for single)
   input logic  [2:0] 	FrmM,		      // Rounding mode - specify values 
   input logic XSgnE, YSgnE,
   input logic [52:0] XManE, YManE,
   input logic [10:0] XExpE, YExpE,
   input logic XSgnM, YSgnM,
   input logic [52:0] XManM, YManM,
   input logic [10:0] XExpM, YExpM,
   input logic XDenormE, YDenormE,
   input logic XNormE, YNormE,
   input logic XNormM, YNormM,
   input logic XZeroE, YZeroE,
   input logic XInfE, YInfE,
   input logic XNaNE, YNaNE,
   input logic XSNaNE, YSNaNE,
   output logic [63:0]  FAddResM,	   // Result of operation
   output logic [4:0]   FAddFlgM);   	// IEEE exception flags 
   
   logic [63:0] 	AddSumE, AddSumM;
   logic [63:0]   AddSumTcE, AddSumTcM;
   logic [3:0] 	AddSelInvE, AddSelInvM;
   logic [10:0] 	AddExpPostSumE,AddExpPostSumM;
   logic 		   AddCorrSignE, AddCorrSignM;
   logic          AddOpANormE,  AddOpANormM;
   logic          AddOpBNormE, AddOpBNormM;
   logic          AddInvalidE, AddInvalidM;
   logic 		   AddDenormInE, AddDenormInM;
   logic          AddSwapE, AddSwapM;
   logic          AddSignAE, AddSignAM;
   logic [11:0] 	AddExp1DenormE, AddExp2DenormE, AddExp1DenormM, AddExp2DenormM;
   logic [10:0] 	AddExponentE, AddExponentM;


   fpuaddcvt1 fpadd1 (.FOpCtrlE, .FmtE, .AddExponentE, 
                     .AddExpPostSumE, .AddExp1DenormE, .AddExp2DenormE, .AddSumE, .AddSumTcE, .AddSelInvE, 
   .XSgnE, .YSgnE,.XManE, .YManE, .XExpE, .YExpE,  .XDenormE, .YDenormE, .XNormE, .YNormE, .XZeroE, .YZeroE, .XInfE, .YInfE, .XNaNE, .YNaNE, .XSNaNE, .YSNaNE,
                     .AddCorrSignE, .AddSignAE, .AddOpANormE, .AddOpBNormE, .AddInvalidE, 
                     .AddDenormInE, .AddSwapE);

   // E/M pipeline registers
   flopenrc #(64) EMRegAdd1(clk, reset, FlushM, ~StallM, AddSumE, AddSumM); 
   flopenrc #(64) EMRegAdd2(clk, reset, FlushM, ~StallM, AddSumTcE, AddSumTcM); 
   flopenrc #(11) EMRegAdd3(clk, reset, FlushM, ~StallM, AddExpPostSumE, AddExpPostSumM); 
   flopenrc #(12) EMRegAdd6(clk, reset, FlushM, ~StallM, AddExp1DenormE, AddExp1DenormM); 
   flopenrc #(12) EMRegAdd7(clk, reset, FlushM, ~StallM, AddExp2DenormE, AddExp2DenormM); 
   flopenrc #(11) EMRegAdd8(clk, reset, FlushM, ~StallM, AddExponentE, AddExponentM);
   flopenrc #(11) EMRegAdd9(clk, reset, FlushM, ~StallM, 
                           {AddSelInvE, AddCorrSignE, AddOpANormE, AddOpBNormE, AddInvalidE, AddDenormInE, AddSwapE, AddSignAE},
                           {AddSelInvM, AddCorrSignM, AddOpANormM, AddOpBNormM, AddInvalidM, AddDenormInM, AddSwapM, AddSignAM}); 

                     
   fpuaddcvt2 fpadd2 (.FrmM, .FOpCtrlM, .FmtM, .AddSumM, .AddSumTcM,  .XNormM, .YNormM, 
                     .AddExp1DenormM, .AddExp2DenormM, .AddExponentM, .AddExpPostSumM, .AddSelInvM, .XSgnM, .YSgnM, .XManM, .YManM, .XExpM, .YExpM,
                     .AddOpANormM, .AddOpBNormM, .AddInvalidM, .AddDenormInM, 
                     .AddSignAM, .AddCorrSignM, .AddSwapM, .FAddResM, .FAddFlgM);
endmodule

module fpuaddcvt1 (
   input logic [2:0]	   FOpCtrlE,	// Function opcode
   input logic 	      FmtE,   		// Result Precision (1 for double, 0 for single)
   input logic XSgnE, YSgnE,
   input logic [10:0] XExpE, YExpE,
   input logic [52:0] XManE, YManE,
   input logic XDenormE, YDenormE,
   input logic XNormE, YNormE,
   input logic XZeroE, YZeroE,
   input logic XInfE, YInfE,
   input logic XNaNE, YNaNE,
   input logic XSNaNE, YSNaNE,

   output logic [10:0] 	AddExponentE,
   output logic [10:0]	AddExpPostSumE,
   output logic [11:0]  AddExp1DenormE, AddExp2DenormE,//KEP used to be [10:0]
   output logic [63:0]  AddSumE, AddSumTcE,
   output logic [3:0]   AddSelInvE,
   output logic         AddCorrSignE,
   output logic 	      AddSignAE,
   output logic	      AddOpANormE, AddOpBNormE,
   output logic	      AddInvalidE,
   output logic 	      AddDenormInE,
   output logic         AddSwapE
   );

   wire [5:0]	 ZP_mantissaA;
   wire [5:0]	 ZP_mantissaB;
   wire		    ZV_mantissaA;
   wire		    ZV_mantissaB;

   wire          P;
   assign P = ~(FmtE^FOpCtrlE[1]);

   wire [63:0] IntValue;
   wire [11:0] exp1, exp2;
   wire [11:0] exp_diff1, exp_diff2;
   wire [11:0] exp_shift;
   wire [51:0] mantissaA;
   wire [56:0] mantissaA1;
   wire [63:0] mantissaA3;
   wire [51:0] mantissaB; 
   wire [56:0] mantissaB1, mantissaB2;
   wire [63:0] mantissaB3;
   wire 	      exp_gt63;
   wire 	      Sticky_out;
   wire        sub;
   wire 	      zeroB;
   wire [5:0]	align_shift;

   // Test for exceptions and return the "Invalid Operation" and
   // "Denormalized" Input Flags. The "AddSelInvE" is used in
   // the third pipeline stage to select the result. Also, AddOp1NormE
   // and AddOp2NormE are one if FSrcXE and FSrcYE are not zero or denormalized.
   // sub is one if the effective operation is subtaction. 

   exception exc1 (.Ztype(AddSelInvE), .Invalid(AddInvalidE), .Denorm(AddDenormInE), .Sub(sub), 
   .XSgnE, .YSgnE, .XDenormE, .YDenormE, .XNormE, .YNormE, .XZeroE, .YZeroE, .XInfE, .YInfE, .XNaNE, .YNaNE, .XSNaNE, .YSNaNE,
	.op_type(FOpCtrlE));

   // Perform Exponent Subtraction (used for alignment). For performance
   // both exponent subtractions are performed in parallel. This was 
   // changed to a behavior level to allow the tools to  try to optimize
   // the two parallel additions. The input values are zero-extended to 12 
   // bits prior to performing the addition. 

   assign exp1 = {1'b0, XExpE};
   assign exp2 = {1'b0, YExpE};
   assign exp_diff1 = exp1 - exp2;
   assign exp_diff2 = AddDenormInE ? ({YSgnE, YExpE} - {XSgnE, XExpE}): exp2 - exp1;

   // The second operand (B) should be set to zero, if FOpCtrlE does not
   // specify addition or subtraction
   assign zeroB = FOpCtrlE[1];

   // Swapped operands if zeroB is not one and exp1 < exp2. 
   // Swapping causes exp2 to be used for the result exponent. 
   // Only the exponent of the larger operand is used to determine
   // the final result. 
   assign AddSwapE = exp_diff1[11] & ~zeroB;
   assign AddExponentE = AddSwapE ? YExpE : XExpE;
   assign AddExpPostSumE = AddSwapE ? YExpE : XExpE;
   assign mantissaA = AddSwapE ? YManE[51:0] : XManE[51:0];
   assign mantissaB = AddSwapE ? XManE[51:0] : YManE[51:0];
   assign AddSignAE     = AddSwapE ? YSgnE : XSgnE;   

   // Leading-Zero Detector. Determine the size of the shift needed for
   // normalization. If sum_corrected is all zeros, the exp_valid is 
   // zero; otherwise, it is one. 
   // modified to 52 bits to detect leading zeroes on denormalized mantissas
   lz52 lz_norm_1 (ZP_mantissaA, ZV_mantissaA, mantissaA);
   lz52 lz_norm_2 (ZP_mantissaB, ZV_mantissaB, mantissaB);

   // Denormalized exponents created by subtracting the leading zeroes from the original exponents
   assign AddExp1DenormE = AddSwapE ? (exp1 - {6'b0, ZP_mantissaB}) : (exp1 - {6'b0, ZP_mantissaA}); //KEP extended ZP_mantissa 
   assign AddExp2DenormE = AddSwapE ? (exp2 - {6'b0, ZP_mantissaA}) : (exp2 - {6'b0, ZP_mantissaB});

   // Determine the alignment shift and limit it to 63. If any bit from 
   // exp_shift[6] to exp_shift[11] is one, then shift is set to all ones. 
   assign exp_shift = AddSwapE ? exp_diff2 : exp_diff1;
   assign exp_gt63 = exp_shift[11] | exp_shift[10] | exp_shift[9] 
     | exp_shift[8] | exp_shift[7] | exp_shift[6];
   assign align_shift = exp_shift[5:0] | {6{exp_gt63}}; //KEP used to be all of exp_shift

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
   assign AddOpANormE = AddSwapE ? YNormE : XNormE;
   assign AddOpBNormE = AddSwapE ? XNormE : YNormE;
   assign mantissaA1 = {2'h0, AddOpANormE, mantissaA[51:0]&{52{AddOpANormE}}, 2'h0};
   assign mantissaB1 = {2'h0, AddOpBNormE, mantissaB[51:0]&{52{AddOpBNormE}}, 2'h0};

   // Perform mantissa alignment using a 57-bit barrel shifter 
   // If any of the bits shifted out are one, Sticky_out is set. 
   // The size of the barrel shifter could be reduced by two bits
   // by not adding the leading two zeros until after the shift. 
   barrel_shifter_r57 bs1 (mantissaB2, Sticky_out, mantissaB1, align_shift);

   // Place either the sign-extened 32-bit value or the original 64-bit value 
   // into IntValue (to be used for integer to floating point conversion)
   // assign IntValue [31:0] = FSrcXE[31:0];
   // assign IntValue [63:32] = FOpCtrlE[0] ? {32{FSrcXE[31]}} : FSrcXE[63:32];

   // If doing an integer to floating point conversion, mantissaA3 is set to 
   // IntVal and the prenomalized exponent is set to 1084. Otherwise, 
   // mantissaA3 is simply extended to 64-bits by setting the 7 LSBs to zero, 
   // and the exponent value is left unchanged. 
   // Under denormalized cases, the exponent before the rounder is set to 1
   // if the normal shift value is 11.
   assign mantissaA3    = AddDenormInE ? ({12'h0, mantissaA}) : {mantissaA1, 7'h0};

   // Put zero in for mantissaB3, if zeroB is one. Otherwise, B is extended to 
   // 64-bits by setting the 7 LSBs to the Sticky_out bit followed by six  
   // zeros. 
   assign mantissaB3[63:7] = AddDenormInE ? {12'h0, mantissaB[51:7]} : mantissaB2 & {57{~zeroB}};
   assign mantissaB3[6]    = AddDenormInE ? mantissaB[6] : Sticky_out & ~zeroB;
   assign mantissaB3[5:0]  = AddDenormInE ? mantissaB[5:0] : 6'h0;

   // The sign of the result needs to be corrected if the true
   // operation is subtraction and the input operands were swapped. 
   assign AddCorrSignE = ~FOpCtrlE[1]&FOpCtrlE[0]&AddSwapE;

   // 64-bit Mantissa Adder/Subtractor
   cla64 add1 (AddSumE, mantissaA3, mantissaB3, sub); //***adder

   // 64-bit Mantissa Subtractor - to get the two's complement of the 
   // result when the sign from the adder/subtractor is negative. 
   cla_sub64 sub1 (AddSumTcE, mantissaB3, mantissaA3); //***adder
 
   // Finds normal underflow result to determine whether to round final exponent down
   //***KEP used to be (AddSumE == 16'h0) I am unsure what it's supposed to be
   // assign AddNormOvflowE = (AddDenormInE & (AddSumE == 64'h0) & (AddOpANormE | AddOpBNormE) & ~FOpCtrlE[0]) ? 1'b1 : (AddSumE[63] ? AddSumTcE[52] : AddSumE[52]);

endmodule // fpadd


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


module fpuaddcvt2 (
   input logic [2:0] 	FrmM,		// Rounding mode - specify values 
   input logic [2:0]	FOpCtrlM,	// Function opcode
   input logic 	FmtM,   		// Result Precision (0 for double, 1 for single)
   input logic [63:0] AddSumM, AddSumTcM,
   input logic [11:0]	 AddExp1DenormM, AddExp2DenormM,
   input logic [10:0] 	 AddExponentM, AddExpPostSumM,
   input logic [3:0] 	 AddSelInvM,
   input logic XSgnM, YSgnM,
   input logic [52:0] XManM, YManM,
   input logic [10:0] XExpM, YExpM,
   input logic XNormM, YNormM,
   input logic		 AddOpANormM, AddOpBNormM,
   input logic		 AddInvalidM,
   input logic 	 AddDenormInM, 
   input logic 	 AddSignAM, 
   input logic         AddCorrSignM,
   input logic          AddSwapM,

   output logic [63:0] FAddResM,	// Result of operation
   output logic [4:0]  FAddFlgM   	// IEEE exception flags 
);
   wire 	 AddDenormM;   	// AddDenormM on input or output   

   wire          P;
   assign P = ~(FmtM^FOpCtrlM[1]);

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
 
 
   logic 	AddOvEnM;		// Overflow trap enabled
   logic 	AddUnEnM;   	// Underflow trap enabled

   assign AddOvEnM = 1'b1;
   assign AddUnEnM = 1'b1;
   //AddExponentM value pre-rounding with considerations for denormalized
   //cases/conversion cases
   assign exp_pre       = AddDenormInM ?
                          ((norm_shift == 6'b001011) ? 11'b00000000001 : (AddSwapM ? AddExp2DenormM[10:0] : AddExp1DenormM[10:0]))
                          : AddExponentM;


   // Finds normal underflow result to determine whether to round final AddExponentM down
   // Comparison between each float and the resulting AddSumM of the primary cla adder/subtractor and cla subtractor
   assign Float1_sum_comp = ~(XManM[51:0] > AddSumM[51:0]);
   assign Float2_sum_comp = ~(YManM[51:0] > AddSumM[51:0]);
   assign Float1_sum_tc_comp = ~(XManM[51:0] > AddSumTcM[51:0]);
   assign Float2_sum_tc_comp = ~(YManM[51:0] > AddSumTcM[51:0]);

   // Determines the correct Float value to compare based on AddSwapM result
   assign mantissa_comp_sum = AddSwapM ? Float2_sum_comp : Float1_sum_comp;
   assign mantissa_comp_sum_tc = AddSwapM ? Float2_sum_tc_comp : Float1_sum_tc_comp;

   // Determines the correct comparison result based on operation and sign of resulting AddSumM
   assign mantissa_comp = (FOpCtrlM[0] ^ AddSumM[63]) ? mantissa_comp_sum_tc : mantissa_comp_sum;

   // If the signs are different and both operands aren't denormalized
   // the normal underflow bit is needed and therefore updated.
   assign normal_underflow = ((XSgnM ^ YSgnM) & (AddOpANormM | AddOpBNormM)) ? mantissa_comp : 1'b0;

   // Determine the correct sign of the result
   assign sign_corr = (AddCorrSignM ^ AddSignAM) ^ AddSumM[63];   
   
   // If the AddSumM is negative, use its two complement instead. 
   // This value has to be 64-bits to correctly handle the 
   // case 10...00
   assign sum_corr = (AddDenormInM & (AddOpANormM | AddOpBNormM) & ( ( (XSgnM ~^ YSgnM) & FOpCtrlM[0] ) | ((XSgnM ^ YSgnM) & ~FOpCtrlM[0]) ))
			 ? (AddSumM[63] ? AddSumM : AddSumTcM) : (AddSumM[63] ? AddSumTcM : AddSumM);

   // Finds normal underflow result to determine whether to round final AddExponentM down
   //KEP used to be (AddSumM == 16'h0) not sure what it is supposed to be
   assign AddNormOvflowM = (AddDenormInM & (AddSumM == 64'h0) & (AddOpANormM | AddOpBNormM) & ~FOpCtrlM[0]) ? 1'b1 : (AddSumM[63] ? AddSumTcM[52] : AddSumM[52]);

   // Leading-Zero Detector. Determine the size of the shift needed for
   // normalization. If sum_corrected is all zeros, the exp_valid is 
   // zero; otherwise, it is one. 
   lz64 lzd1 (norm_shift, exp_valid, sum_corr);

   assign norm_shift_denorm = (AddDenormInM & ( (~AddOpANormM & ~AddOpBNormM) | normal_underflow)) ? (6'h00) : (norm_shift);

   // Barell shifter used for normalization. It takes as inputs the 
   // the corrected AddSumM and the amount by which the AddSumM should 
   // be right shifted. It outputs the normalized AddSumM. 
   barrel_shifter_l64 bs2 (sum_norm, sum_corr, norm_shift_denorm);
  
   assign sum_norm_w_bypass = sum_norm;

   // Round the mantissa to a 52-bit value, with the leading one
   // removed. If the result is a single precision number, the actual 
   // mantissa is in the upper 23 bits and the lower 29 bits are zero. 
   // At this point, normalization has already been performed, so we know 
   // exactly where the rounding point is. The rounding units also
   // handles special cases and set the exception flags.

   // Changed DenormIO -> AddDenormM and FlagsIn -> FAddFlgM in order to
   // help in processor reservation station detection of load/stores. In
   // other words, the processor would like to know ahead of time that
   // if the result is an exception then don't load or store.
   rounder round1 (.Result, .DenormIO, .Flags(FlagsIn), .rm(FrmM), .P, .OvEn(AddOvEnM), .UnEn(AddUnEnM), .exp_valid, 
		   .sel_inv(AddSelInvM), .Invalid(AddInvalidM), .DenormIn(AddDenormInM), .Asign(sign_corr), .Aexp(exp_pre), .norm_shift, .A(sum_norm_w_bypass),
		   .exponent_postsum(AddExpPostSumM), .A_Norm(XNormM), .B_Norm(YNormM), .exp_A_unmodified({XSgnM, XExpM}), .exp_B_unmodified({YSgnM, YExpM}),
		   .normal_overflow(AddNormOvflowM), .normal_underflow, .swap(AddSwapM), .op_type(FOpCtrlM), .sum(AddSumM));

   // Store the final result and the exception flags in registers.
   assign FAddResM = Result;
   assign {AddDenormM, FAddFlgM} = {DenormIO, FlagsIn};
   
endmodule // fpadd


