// The rounder takes as inputs a 64-bit value to be rounded, A, the 
// exponent of the value to be rounded, the sign of the final result, Sign, 
// the precision of the results, P, and the two-bit rounding mode, rm. 
// It produces a rounded 52-bit result, Z, the exponent of the rounded 
// result, Z_exp, and a flag that indicates if the result was rounded,
// Inexact. The rounding mode has the following values.
//	rm		Modee
//      00 		round-to-nearest-even
//	01 		round-toward-zero
//      10 		round-toward-plus infinity
//      11  		round-toward-minus infinity
// The rounding algorithm determines if '1' should be added to the 
// truncated signficant result, based on three significant bits 
// (least (L), round (R) and sticky (S)), the rounding mode (rm)
// and the sign of the final result (Sign). Visually, L and R appear as
//    xxxxxL,Rxxxxxxx
// where , denotes the rounding boundary. S is the logical OR of all the
// bits to the right of R. 

module rounder (Result, DenormIO, Flags, rm, P, OvEn, 
		UnEn, exp_valid, sel_inv, Invalid, DenormIn, convert, Asign, Aexp, 
		norm_shift, A, exponent_postsum, A_Norm, B_Norm, exp_A_unmodified, exp_B_unmodified,
		normal_overflow, normal_underflow, swap, op_type, sum);

   input  [2:0]  rm;
   input         P;
   input         OvEn;
   input         UnEn;
   input         exp_valid;
   input [3:0] 	 sel_inv;
   input	 Invalid;
   input	 DenormIn;
   input         convert;
   input         Asign;
   input [10:0]  Aexp;
   input [5:0] 	 norm_shift;
   input [63:0]  A;
   input [10:0]  exponent_postsum;
   input 	 A_Norm;
   input 	 B_Norm;
   input [11:0]  exp_A_unmodified;
   input [11:0]  exp_B_unmodified;
   input 	 normal_overflow;
   input 	 normal_underflow;
   input 	 swap;
   input [3:0]	 op_type;
   input [63:0]  sum;
   
   output [63:0] Result;
   output 	 DenormIO;
   output [4:0]  Flags;
   
   wire          Rsign;
   wire 	 Sticky_out;
   wire [51:0]	 ShiftMant;
   wire [63:0]   ShiftMant_64;
   wire [10:0] 	 Rexp;
   wire [10:0]   Rexp_denorm;
   wire [11:0] 	 Texp;			//Parallelized for denorm exponent
   wire [11:0]   Texp_addone;		//results
   wire [11:0]   Texp_subone;
   wire [51:0] 	 Rmant;
   wire [51:0] 	 Tmant;
   wire          Rzero;
   wire          VSS = 1'b0;
   wire          VDD = 1'b1;
   wire [51:0] 	 B;			// Value used to add the "ones"
   wire [11:0]   B_12_overflow;		// Value used to add one to exponent
   wire [11:0]   B_12_underflow;	// Value used to subtract one from exponent
   wire		 S_SP;			// Single precision sticky bit
   wire		 S_DP;			// Double precision sticky bit
   wire		 S;			// Actual sticky bit
   wire		 R;			// Round bit
   wire		 L;			// Least significant bit
   wire		 add_one;		// '1' if one should be added
   wire		 UnFlow_SP, UnFlow_DP, UnderFlow; 
   wire		 OvFlow_SP, OvFlow_DP, OverFlow;		
   wire		 Inexact;
   wire		 Round_zero;
   wire		 Infinite;
   wire		 VeryLarge;
   wire		 Largest;
   wire		 Adj_exp;
   wire		 Valid;
   wire		 NaN;
   wire		 Cout;
   wire 	 Cout_overflow;
   wire		 Texp_l7z;
   wire		 Texp_l7o;
   wire		 OvCon;

   // Determine the sticky bits for double and single precision
   assign S_DP= A[9]|A[8]|A[7]|A[6]|A[5]|A[4]|A[3]|A[2]|A[1]|A[0];
   assign S_SP = S_DP |A[38]|A[37]|A[36]|A[35]|A[34]|A[33]|A[32]|A[31]|A[30]|
                 A[29]|A[28]|A[27]|A[26]|A[25]|A[24]|A[23]|A[22]|A[21]|A[20]|
                 A[19]|A[18]|A[17]|A[16]|A[15]|A[14]|A[13]|A[12]|A[11]|A[10];

   // Set the least (L), round (R), and sticky (S) bits based on
   // the precision. 
   assign {L, R, S} = P ? {A[40],A[39],S_SP} : {A[11],A[10],S_DP};

   // Add one if ((the rounding mode is round-to-nearest) and (R is one) and
   // (S or L is one)) or ((the rounding mode is towards plus or minus 
   // infinity (rm[1] = 1)) and (the sign and rm[0] are the same) and 
   // (R or S is one)). 

   assign add_one = ~rm[2] & ((~rm[1]&~rm[0]&R&(L|S)) | (rm[1]&(Asign^~rm[0])&(R|S))) | (rm[2] & R);

   // Add one using a 52-bit adder. The one is added to the LSB B[0] for
   // double precision or to B[29] for single precision. 
   // This could be simplified by using a specialized adder.
   // The current adder is actually 64-bits. The leading one 
   // for normalized results in not included in the addition.
   assign B = {{22{VSS}}, add_one&P, {28{VSS}}, add_one&~P};
   assign B_12_overflow = {8'h0, 3'b0, normal_overflow};
   assign B_12_underflow = {8'h0, 3'b0, normal_underflow};

   cla52 add1(Tmant, Cout, A[62:11], B);

   cla12 add1_exp(Texp_addone, Cout_overflow, Texp, B_12_overflow);

   cla_sub12 sub1_exp(Texp_subone, Texp, B_12_underflow);

   // Now that rounding is done, we compute the final exponent
   // and test for special cases. 

   // Compute the value of the exponent by subtracting the shift 
   // value from the previous exponent and then adding 2 + cout. 
   // If needed this could be optimized to used a specialized 
   // adder. 

   assign Texp = DenormIn ? ({1'b0, exponent_postsum}) : ({VSS, Aexp} - {{6{VSS}}, norm_shift} +{{10{VSS}}, VDD, Cout});   
   
   // Overflow only occurs for double precision, if Texp[10] to Texp[0] are 
   // all ones. To encourage sharing with single precision overflow detection,
   // the lower 7 bits are tested separately. 
   assign Texp_l7o  = Texp[6]&Texp[5]&Texp[4]&Texp[3]&Texp[2]&Texp[1]&Texp[0];
   assign OvFlow_DP = Texp[10]&Texp[9]&Texp[8]&Texp[7]&Texp_l7o;

   // Overflow occurs for single precision if (Texp[10] is one)  and 
   // ((Texp[9] or Texp[8] or Texp[7]) is one) or (Texp[6] to Texp[0] 
   // are all ones. 
   assign OvFlow_SP = Texp[10]&(Texp[9]|Texp[8]|Texp[7]|Texp_l7o);

   // Underflow occurs for double precision if (Texp[11] is one)  or Texp[10] to 
   // Texp[0] are all zeros. 
   assign Texp_l7z  = ~Texp[6]&~Texp[5]&~Texp[4]&~Texp[3]&~Texp[2]&~Texp[1]&~Texp[0];
   assign UnFlow_DP = Texp[11] | ~Texp[10]&~Texp[9]&~Texp[8]&~Texp[7]&Texp_l7z;

   // Underflow occurs for single precision if (Texp[10] is zero)  and 
   // (Texp[9] or Texp[8] or Texp[7]) is zero. 
   assign UnFlow_SP = (~Texp[10]&(~Texp[9]|~Texp[8]|~Texp[7]|Texp_l7z));
   
   // Set the overflow and underflow flags. They should not be set if
   // the input was infinite or NaN or the output of the adder is zero.
   // 00 = Valid
   // 10 = NaN
   assign Valid = (~sel_inv[2]&~sel_inv[1]&~sel_inv[0]);
   assign NaN   = ~sel_inv[2]&~sel_inv[1]& sel_inv[0];
   assign UnderFlow = ((P & UnFlow_SP | UnFlow_DP)&Valid&exp_valid) |
		      (~Aexp[10]&Aexp[9]&Aexp[8]&Aexp[7]&~Aexp[6]
		       &~Aexp[5]&~Aexp[4]&~Aexp[3]&~Aexp[2]
		       &~Aexp[1]&~Aexp[0]&sel_inv[3]);
   assign OverFlow  = (P & OvFlow_SP | OvFlow_DP)&Valid&~UnderFlow&exp_valid;

   // The DenormIO is set if underflow has occurred or if their was a
   // denormalized input. 
   assign DenormIO = DenormIn | UnderFlow;

   // The final result is Inexact if any rounding occurred ((i.e., R or S 
   // is one), or (if the result overflows ) or (if the result underflows and the 
   // underflow trap is not enabled)) and (value of the result was not previous set 
   // by an exception case). 
   assign Inexact = (R|S|OverFlow|(UnderFlow&~UnEn))&Valid;

   // Set the IEEE Exception Flags: Inexact, Underflow, Overflow, Div_By_0, 
   // Invlalid. 
   assign Flags = {UnderFlow, VSS, OverFlow, Invalid, Inexact};

   // Determine the final result. 

   // The sign of the final result is one if the result is not zero and
   // the sign of A is one, or if the result is zero and the the rounding 
   // mode is round-to-minus infinity. The final result is zero, if exp_valid
   // is zero. If underflow occurs, then the result is set to zero.
   //   
   // For Zero (goes equally for subtraction although 
   // signs may alter operands sign):
   // -0 + -0 = -0 (always)
   // +0 + +0 = +0 (always)
   // -0 + +0 = +0 (for RN, RZ, RU) 
   // -0 + +0 = -0 (for RD) 
   assign Rzero = ~exp_valid | UnderFlow;
   assign Rsign = DenormIn ?
		  ( ~(op_type[2] | op_type[1] | op_type[0]) ? 
		  ( (sum[63] & (A_Norm | B_Norm) & (exp_A_unmodified[11] ^ exp_B_unmodified[11])) ?
		  ~Asign : Asign) 
   		  : ( ((A_Norm ^ B_Norm) & (exp_A_unmodified[11] ~^ exp_B_unmodified[11])) ?
		  (normal_underflow ? ~Asign : Asign) : Asign)
		  ) 
		  : ( ((Asign&exp_valid | 
     	          (sel_inv[2]&~sel_inv[1]&sel_inv[0]&rm[1]&rm[0] |
	          sel_inv[2]&sel_inv[1]&~sel_inv[0] |		  
	          ~exp_valid&rm[1]&rm[0]&~sel_inv[2] | 
	          UnderFlow&rm[1]&rm[0]) & ~convert) & ~sel_inv[3]) |
		  (Asign & sel_inv[3]) );
   
   // The exponent of the final result is zero if the final result is 
   // zero or a denorm, all ones if the final result is NaN or Infinite
   // or overflow occurred and the magnitude of the number is 
   // not rounded toward from zero, and all ones with an LSB of zero
   // if overflow occurred and the magnitude of the number is 
   // rounded toward zero. If the result is single precision, 
   // Texp[7] shoud be inverted. When the Overflow trap is enabled (OvEn = 1)
   // and overflow occurs and the operation is not conversion, bits 10 and 9 are 
   // inverted for double precision, and bits 7 and 6 are inverted for single precision. 
   assign Round_zero = ~rm[1]&rm[0] | ~Asign&rm[0] | Asign&rm[1]&~rm[0];
   assign VeryLarge = OverFlow & ~OvEn;
   assign Infinite   = (VeryLarge & ~Round_zero) | (~sel_inv[2] & sel_inv[1]);
   assign Largest = VeryLarge & Round_zero;
   assign Adj_exp = OverFlow & OvEn & ~convert;
   assign Rexp[10:1] = ({10{~Valid}} | 
			{Texp[10]&~Adj_exp, Texp[9]&~Adj_exp, Texp[8], 
			 (Texp[7]^P)&~(Adj_exp&P), Texp[6]&~(Adj_exp&P), Texp[5:1]} | 
		        {10{VeryLarge}})&{10{~Rzero | NaN}};
   assign Rexp[0]    = ({~Valid} | Texp[0] | Infinite)&(~Rzero | NaN)&~Largest;
   
   // The denormalized rounded exponent uses the overflow/underflow values
   // computed in the fpadd component to round the exponent up or down 
   // Depending on the operation and the signs of the orignal operands,
   // underflow may or may not be needed to round.
   assign Rexp_denorm = DenormIn ? 
			((~op_type[2] & ~op_type[1] & op_type[0]) ? 
				( ((A_Norm != B_Norm) & (exp_A_unmodified[11] == exp_B_unmodified[11])) ? 
					( (normal_overflow == normal_underflow) ? Texp[10:0] : (normal_overflow ? Texp_addone[10:0] : Texp_subone[10:0]) ) 
					: ( normal_overflow ? Texp_addone[10:0] : Texp[10:0] ) ) 
				: ( ((A_Norm != B_Norm) & (exp_A_unmodified[11] != exp_B_unmodified[11])) ?	
					( (normal_overflow == normal_underflow) ? Texp[10:0] : (normal_overflow ? Texp_addone[10:0] : Texp_subone[10:0]) ) 
					: ( normal_overflow ? Texp_addone[10:0] : Texp[10:0] ) ) 
				) : 
			(op_type[3]) ? exp_A_unmodified : Rexp;

   // If the result is zero or infinity, the mantissa is all zeros. 
   // If the result is NaN, the mantissa is 10...0
   // If the result the largest floating point number, the mantissa
   // is all ones. Otherwise, the mantissa is not changed. 
   // If operation is denormalized, take the mantissa directly from
   // its normalized value. 
   assign Rmant[51] = Largest | NaN | (Tmant[51]&~Infinite&~Rzero);
   assign Rmant[50:0] = {51{Largest}} | (Tmant[50:0]&{51{~Infinite&Valid&~Rzero}});

   assign ShiftMant = A[51:0];

   // For single precision, the 8 least significant bits of the exponent
   // and 23 most significant bits of the mantissa contain bits used 
   // for the final result. A double precision result is returned if 
   // overflow has occurred, the overflow trap is enabled, and a conversion
   // is being performed. 
   assign OvCon = OverFlow & OvEn & convert;

   assign Result = (op_type[3]) ? {A[63:0]} : (DenormIn ? {Rsign, Rexp_denorm, ShiftMant} : ((P&~OvCon) ? {Rsign, Rexp[7:0], Rmant[51:29], {32{VSS}}}
	           : {Rsign, Rexp, Rmant}));

endmodule // rounder

