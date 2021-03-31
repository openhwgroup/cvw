// Exception logic for the floating point adder. Note: We may 
// actually want to move to where the result is computed.

module exception_div (Ztype, Invalid, Denorm, ANorm, BNorm, A, B, op_type);

   input [63:0] A;		// 1st input operand (op1)
   input [63:0] B;		// 2nd input operand (op2)
   input 	op_type;        // Determine operation   
   
   output [2:0] Ztype;		// Indicates type of result (Z)
   output 	Invalid;	// Invalid operation exception
   output 	Denorm;		// Denormalized input
   output       ANorm;          // A is not zero or Denorm
   output       BNorm;          // B is not zero or Denorm
   
   wire		AzeroM;	 	// '1' if the mantissa of A is zero
   wire		BzeroM;		// '1' if the mantissa of B is zero
   wire		AzeroE;	 	// '1' if the exponent of A is zero
   wire		BzeroE;		// '1' if the exponent of B is zero
   wire		AonesE;	 	// '1' if the exponent of A is all ones
   wire		BonesE;		// '1' if the exponent of B is all ones
   wire		ADenorm; 	// '1' if A is a denomalized number
   wire		BDenorm; 	// '1' if B is a denomalized number
   wire		AInf;	 	// '1' if A is infinite
   wire		BInf;	 	// '1' if B is infinite
   wire		AZero;	 	// '1' if A is 0
   wire		BZero;	 	// '1' if B is 0
   wire		ANaN;	 	// '1' if A is a not-a-number
   wire		BNaN; 		// '1' if B is a not-a-number
   wire		ASNaN;	 	// '1' if A is a signalling not-a-number
   wire		BSNaN;	 	// '1' if B is a signalling not-a-number
   wire		ZQNaN;	 	// '1' if result Z is a quiet NaN
   wire		ZInf;	 	// '1' if result Z is an infnity
   wire 	square_root;    // '1' if square root operation
   wire 	Zero;           // '1' if result is zero   
   
   parameter [51:0]  fifty_two_zeros = 52'h0; // Use parameter?

   // Determine if mantissas are all zeros
   assign AzeroM = (A[51:0] == fifty_two_zeros);
   assign BzeroM = (B[51:0] == fifty_two_zeros);

   // Determine if exponents are all ones or all zeros 
   assign AonesE = A[62]&A[61]&A[60]&A[59]&A[58]&A[57]&A[56]&A[55]&A[54]&A[53]&A[52];
   assign BonesE = B[62]&B[61]&B[60]&B[59]&B[58]&B[57]&B[56]&B[55]&B[54]&B[53]&B[52];
   assign AzeroE = ~(A[62]|A[61]|A[60]|A[59]|A[58]|A[57]|A[56]|A[55]|A[54]|A[53]|A[52]);
   assign BzeroE = ~(B[62]|B[61]|B[60]|B[59]|B[58]|B[57]|B[56]|B[55]|B[54]|B[53]|B[52]);

   // Determine special cases. Note: Zero is not really a special case. 
   assign ADenorm = AzeroE & ~AzeroM;
   assign BDenorm = BzeroE & ~BzeroM;
   assign AInf = AonesE & AzeroM;
   assign BInf = BonesE & BzeroM;
   assign ANaN = AonesE & ~AzeroM;
   assign BNaN = BonesE & ~BzeroM;
   assign ASNaN = ANaN & A[50];
   assign BSNaN = ANaN & A[50];
   assign AZero = AzeroE & AzeroM;
   assign BZero = BzeroE & BzeroE;

   // A and B are normalized if their exponents are not zero. 
   assign ANorm = ~AzeroE;
   assign BNorm = ~BzeroE;

   // An "Invalid Operation" exception occurs if (A or B is a signalling NaN)
   // or (A and B are both Infinite)
   assign Invalid = ASNaN | BSNaN | (((AInf & BInf) | (AZero & BZero))&~op_type) | 
		    (A[63] & op_type);

   // The Denorm flag is set if A is denormlized or if B is normalized 
   assign Denorm = ADenorm | BDenorm;

   // The result is a quiet NaN if (an "Invalid Operation" exception occurs) 
   // or (A is a NaN) or (B is a NaN).
   assign ZQNaN = Invalid | ANaN | BNaN;

   //  The result is zero
   assign Zero = (AZero | BInf)&~op_type | AZero&op_type;   

   // The result is +Inf if ((A is Inf) or (B is 0)) and (the
   // result is not a quiet NaN).  
   assign ZInf = (AInf | BZero)&~ZQNaN&~op_type | AInf&op_type&~ZQNaN;   

   // Set the type of the result as follows:
   // Ztype	Result 
   //  000     Normal
   //  001     Quiet NaN
   //  010     Infinity
   //  011     Zero
   //  110     DivZero
   assign Ztype[0] = ZQNaN | Zero;
   assign Ztype[1] = ZInf | Zero;
   assign Ztype[2] = BZero&~op_type;   

endmodule // exception

