//
// File name : fpcomp.v
// Title     : Floating-Point Comparator
// project   : FPU
// Library   : fpcomp
// Author(s) : James E. Stine
// Purpose   : definition of main unit to floating-point comparator
// notes :   
//
// Copyright Oklahoma State University
//
// Floating Point Comparator (Algorithm)
//
// 1.) Performs sign-extension if the inputs are 32-bit integers.
// 2.) Perform a magnitude comparison on the lower 63 bits of the inputs
// 3.) Check for special cases (+0=-0, unordered, and infinite values) 
//     and correct for sign bits
//
// This module takes 64-bits inputs op1 and op2, VSS, and VDD
// signals, and a 2-bit signal Sel that indicates the type of 
// operands being compared as indicated below.
//	Sel	Description
//	 00	double precision numbers
//	 01	single precision numbers
//	 10	half precision numbers
//	 11	(unused)
//
// The comparator produces a 2-bit signal FCC, which
// indicates the result of the comparison:
//
//     fcc 	decscription
//      00	A = B	
//      01	A < B	
//      10	A > B	
//      11	A and B	are unordered (i.e., A or B is NaN)
//
// It also produces an invalid operation flag, which is one
// if either of the input operands is a signaling NaN per 754

module fpucmp2 (Invalid, FCC, ANaN, BNaN, Azero, Bzero, w, x, Sel, op1, op2);
   
   input logic [63:0] op1; 
   input logic [63:0] op2;
   input logic [1:0]  Sel;
   input logic [7:0]  w, x;
   input logic        ANaN, BNaN;
   input logic        Azero, Bzero;
   
   output logic       Invalid; 		 // Invalid Operation
   output logic [1:0] FCC;  		 // Condition Codes 
   
   logic 	      LT;                // magnitude op1 < magnitude op2
   logic 	      EQ;                // magnitude op1 = magnitude op2
   
   // Perform magnitude comparison between the 63 least signficant bits
   // of the input operands. Only LT and EQ are returned, since GT can
   // be determined from these values. 
   magcompare64b_2 magcomp2 (LT, EQ, w, x);

   // Determine final values based on output of magnitude comparison, 
   // sign bits, and special case testing. 
   exception_cmp_2 exc2 (.invalid(Invalid), .fcc(FCC), .LT_mag(LT), .EQ_mag(EQ), .ANaN(ANaN), .BNaN(BNaN), .Azero(Azero), .Bzero(Bzero), .Sel(Sel), .A(op1), .B(op2));
   

endmodule // fpcomp

/*module magcompare2b (LT, GT, A, B);

   input logic [1:0] A;
   input logic [1:0] B;
   
   output logic     LT;
   output logic     GT;

   // Determine if A < B  using a minimized sum-of-products expression
   assign LT = ~A[1]&B[1] | ~A[1]&~A[0]&B[0] | ~A[0]&B[1]&B[0];
   // Determine if A > B  using a minimized sum-of-products expression
   assign GT = A[1]&~B[1] | A[1]&A[0]&~B[0] | A[0]&~B[1]&~B[0];

endmodule*/ // magcompare2b

// 2-bit magnitude comparator
// This module compares two 2-bit values A and B. LT is '1' if A < B 
// and GT is '1'if A > B. LT and GT are both '0' if A = B.  However,
// this version actually incorporates don't cares into the equation to
// simplify the optimization

module magcompare2c (LT, GT, A, B);

   input logic [1:0] A;
   input logic [1:0] B;
   
   output logic      LT;
   output logic      GT;

   assign LT = B[1] | (!A[1]&B[0]);
   assign GT = A[1] | (!B[1]&A[0]);

endmodule // magcompare2b

// This module compares two 64-bit values A and B. LT is '1' if A < B 
// and EQ is '1'if A = B. LT and GT are both '0' if A > B.
// This structure was modified so
// that it only does a strict magnitdude comparison, and only
// returns flags for less than (LT) and eqaual to (EQ). It uses a tree 
// of 63 2-bit magnitude comparators, followed by one OR gates.
//
// J. E. Stine and M. J. Schulte, "A combined two's complement and
// floating-point comparator," 2005 IEEE International Symposium on
// Circuits and Systems, Kobe, 2005, pp. 89-92 Vol. 1. 
// doi: 10.1109/ISCAS.2005.1464531

module magcompare64b_2 (LT, EQ, w, x);

   input logic [7:0]  w;
   input logic [7:0]  x;
   logic [3:0] 	      y;
   logic [3:0] 	      z;
   logic [1:0] 	      a;
   logic [1:0] 	      b;   
   logic 	      GT;
   
   output logic       LT;
   output logic       EQ;
   
   magcompare2c mag39(y[0], z[0], x[1:0], w[1:0]);
   magcompare2c mag3A(y[1], z[1], x[3:2], w[3:2]);
   magcompare2c mag3B(y[2], z[2], x[5:4], w[5:4]);
   magcompare2c mag3C(y[3], z[3], x[7:6], w[7:6]);
   
   magcompare2c mag3D(a[0], b[0], z[1:0], y[1:0]);
   magcompare2c mag3E(a[1], b[1], z[3:2], y[3:2]);
   
   magcompare2c mag3F(LT, GT, b[1:0], a[1:0]);

   assign EQ = ~(LT | GT);

endmodule // magcompare64b

// This module takes 64-bits inputs A and B, two magnitude comparison
// flags LT_mag and EQ_mag, and a 2-bit signal Sel that indicates the type of 
// operands being compared as indicated below.
//	Sel	Description
//	 00	double precision numbers
//	 01	single precision numbers
//	 10	half precision numbers
//	 11	bfloat precision numbers
//
// The comparator produces a 2-bit signal fcc, which
// indicates the result of the comparison as follows:
//     fcc 	decscription
//      00	A = B	
//      01	A < B	
//      10	A > B	
//      11	A and B	are unordered (i.e., A or B is NaN)
// It also produces a invalid operation flag, which is one
// if either of the input operands is a signaling NaN.

module exception_cmp_2 (invalid, fcc, LT_mag, EQ_mag, ANaN, BNaN, Azero, Bzero, Sel, A, B);

   input logic [63:0] A;
   input logic [63:0] B;
   input logic 	      LT_mag;
   input logic 	      EQ_mag;
   input logic [1:0]  Sel;
   
   output logic       invalid;
   output logic [1:0] fcc;   

   logic 	      dp;   
   logic 	      sp;
   logic 	      hp;   
   input logic 	      Azero;
   input logic 	      Bzero;   
   input logic 	      ANaN;
   input logic 	      BNaN;
   logic 	      ASNaN;
   logic 	      BSNaN;
   logic 	      UO;
   logic 	      GT;
   logic 	      LT;
   logic 	      EQ;
   logic [62:0]       sixtythreezeros = 63'h0;

   assign dp = !Sel[1]&!Sel[0];
   assign sp = !Sel[1]&Sel[0];
   assign hp = Sel[1]&!Sel[0];

   // Values are unordered if ((A is NaN) OR (B is NaN)) AND (a floating 
   // point comparison is being performed. 
   assign UO = (ANaN | BNaN);

   // Test if A or B is a signaling NaN.
   assign ASNaN = ANaN & (sp&~A[53] | dp&~A[50] | hp&~A[56]);
   assign BSNaN = BNaN & (sp&~B[53] | dp&~B[50] | hp&~B[56]);

   // If either A or B is a signaling NaN the "Invalid Operation"
   // exception flag is set to one; otherwise it is zero.    
   assign invalid = (ASNaN | BSNaN);

   // A and B are equal if (their magnitudes are equal) AND ((their signs are
   // equal) or (their magnitudes are zero AND they are floating point
   // numbers)). Also, A and B are not equal if they are unordered.
   assign EQ = (EQ_mag | (Azero&Bzero)) & (~UO);
   
   // A is less than B if (A is negative and B is posiive) OR
   // (A and B are positive and the magnitude of A is less than
   // the magnitude of B) or (A and B are negative integers and
   // the magnitude of A is less than the magnitude of B) or
   // (A and B are negative floating point numbers and
   // the magnitude of A is greater than the magnitude of B).
   // Also, A is not less than B if A and B are equal or unordered.
   assign LT = ((~LT_mag & A[63] & B[63]) |
		(LT_mag & ~(A[63] & B[63])))&~EQ&~UO;
   
   // A is greater than B when LT, EQ, and UO are are false.
   assign GT = ~(LT | EQ | UO);

   // Note: it may be possible to optimize the setting of fcc 
   // a little more, but it is probably not worth the effort. 

   // Set the bits of fcc based on LT, GT, EQ, and UO
   assign fcc[0] = LT | UO;
   assign fcc[1] = GT | UO;   

endmodule // exception_cmp
