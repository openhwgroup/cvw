// Exception logic for the floating point adder. Note: We may 
// actually want to move to where the result is computed.
module exception_div (

   input logic [63:0] A,		// 1st input operand (op1)
   input logic [63:0] B,		// 2nd input operand (op2)
   input logic 	    op_type,   // Determine operation   
   output logic [2:0] Ztype,		// Indicates type of result (Z)
   output logic       Invalid	// Invalid operation exception
);
   
   logic 	      AzeroM;	 	// '1' if the mantissa of A is zero
   logic 	      BzeroM;		// '1' if the mantissa of B is zero
   logic 	      AzeroE;	 	// '1' if the exponent of A is zero
   logic 	      BzeroE;		// '1' if the exponent of B is zero
   logic 	      AonesE;	 	// '1' if the exponent of A is all ones
   logic 	      BonesE;		// '1' if the exponent of B is all ones
   logic 	      AInf;	 	// '1' if A is infinite
   logic 	      BInf;	 	// '1' if B is infinite
   logic 	      AZero;	 	// '1' if A is 0
   logic 	      BZero;	 	// '1' if B is 0
   logic 	      ANaN;	 	// '1' if A is a not-a-number
   logic 	      BNaN; 		// '1' if B is a not-a-number
   logic 	      ASNaN;	 	// '1' if A is a signalling not-a-number
   logic 	      BSNaN;	 	// '1' if B is a signalling not-a-number
   logic 	      ZSNaN;	 	// '1' if result Z is a quiet NaN
   logic 	      ZInf;	 	// '1' if result Z is an infnity
   logic 	      Zero;             // '1' if result is zero
   logic              NegSqrt;          // '1' if sqrt and operand is negative   
   
   //***take this module out and add more registers or just recalculate it all
   // Determine if mantissas are all zeros
   assign AzeroM = (A[51:0] == 52'h0);
   assign BzeroM = (B[51:0] == 52'h0);

   // Determine if exponents are all ones or all zeros 
   assign AonesE = A[62]&A[61]&A[60]&A[59]&A[58]&A[57]&A[56]&A[55]&A[54]&A[53]&A[52];
   assign BonesE = B[62]&B[61]&B[60]&B[59]&B[58]&B[57]&B[56]&B[55]&B[54]&B[53]&B[52];
   assign AzeroE = ~(A[62]|A[61]|A[60]|A[59]|A[58]|A[57]|A[56]|A[55]|A[54]|A[53]|A[52]);
   assign BzeroE = ~(B[62]|B[61]|B[60]|B[59]|B[58]|B[57]|B[56]|B[55]|B[54]|B[53]|B[52]);

   // Determine special cases. Note: Zero is not really a special case. 
   assign AInf = AonesE & AzeroM;
   assign BInf = BonesE & BzeroM;
   assign ANaN = AonesE & ~AzeroM;
   assign BNaN = BonesE & ~BzeroM;
   assign ASNaN = ANaN & A[50];
   assign BSNaN = ANaN & A[50];
   assign AZero = AzeroE & AzeroM;
   assign BZero = BzeroE & BzeroE;

   // Is NaN if operand is negative and its a sqrt
   assign NegSqrt = (A[63] & op_type & ~AZero);

   // An "Invalid Operation" exception occurs if (A or B is a signalling NaN)
   // or (A and B are both Infinite)
   assign Invalid = ASNaN | BSNaN | (((AInf & BInf) | (AZero & BZero))&~op_type) | 
		    NegSqrt;

   // The result is a quiet NaN if (an "Invalid Operation" exception occurs) 
   // or (A is a NaN) or (B is a NaN).
   assign ZSNaN = Invalid | ANaN | BNaN;

   //  The result is zero
   assign Zero = (AZero | BInf)&~op_type | AZero&op_type;   

   // The result is +Inf if ((A is Inf) or (B is 0)) and (the
   // result is not a quiet NaN).  
   assign ZInf = (AInf | BZero)&~ZSNaN&~op_type | AInf&op_type&~ZSNaN;   

   // Set the type of the result as follows:
   // Ztype	Result 
   //  000     Normal
   //  010     Infinity
   //  011     Zero
   //  110     Div by 0
   //  111     SNaN
   assign Ztype[2] = (ZSNaN);
   assign Ztype[1] = (ZSNaN) | (Zero) | (ZInf);
   assign Ztype[0] = (ZSNaN) | (Zero);
   
endmodule // exception
