
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
// signals, and a 2-bit signal FOpCtrlE that indicates the type of 
// operands being compared as indicated below.
//	FOpCtrlE	Description
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

`include "wally-config.vh"
module fcmp (   
   input logic [63:0] op1, 
   input logic [63:0] op2,
   input logic [2:0]  FOpCtrlE,
   input logic 	      FmtE,

   
   output logic       Invalid, 		 // Invalid Operation
   // output logic [1:0] FCC,  		 // Condition Codes 
   output logic [63:0] CmpResE);
   // Perform magnitude comparison between the 63 least signficant bits
   // of the input operands. Only LT and EQ are returned, since GT can
   // be determined from these values. 
   logic [1:0] FCC;  		 // Condition Codes 
   logic [7:0]	      w, x;
   logic	      ANaN, BNaN;
   logic	      Azero, Bzero;
   logic 	      LT;                // magnitude op1 < magnitude op2
   logic 	      EQ;                // magnitude op1 = magnitude op2
   logic [63:0]   PosOp1, PosOp2;
   
   assign PosOp1 = FmtE ? {~op1[63], op1[62:0]} : {~op1[31], op1[30:0], 32'b0};
   assign PosOp2 = FmtE ? {~op2[63], op2[62:0]} : {~op2[31], op2[30:0], 32'b0};
   magcompare64b_1 magcomp1 (w, x, PosOp1, PosOp2);

   // Determine final values based on output of magnitude comparison, 
   // sign bits, and special case testing. 
   exception_cmp_1 exc1 (ANaN, BNaN, Azero, Bzero, op1, op2, FOpCtrlE);
   
   // Perform magnitude comparison between the 63 least signficant bits
   // of the input operands. Only LT and EQ are returned, since GT can
   // be determined from these values. 
   magcompare64b_2 magcomp2 (LT, EQ, w, x);

   // Determine final values based on output of magnitude comparison, 
   // sign bits, and special case testing. 
   exception_cmp_2 exc2 (.invalid(Invalid), .fcc(FCC), .LT_mag(LT), .EQ_mag(EQ), .ANaN(ANaN), .BNaN(BNaN), .Azero(Azero), .Bzero(Bzero), .FOpCtrlE(FOpCtrlE), .A(op1), .B(op2), .*);

endmodule // fpcomp

// module magcompare2b (LT, GT, A, B);

//    input logic [1:0] A;
//    input logic [1:0] B;
   
//    output logic     LT;
//    output logic     GT;

//    // Determine if A < B  using a minimized sum-of-products expression
//    assign LT = ~A[1]&B[1] | ~A[1]&~A[0]&B[0] | ~A[0]&B[1]&B[0];
//    // Determine if A > B  using a minimized sum-of-products expression
//    assign GT = A[1]&~B[1] | A[1]&A[0]&~B[0] | A[0]&~B[1]&~B[0];

// endmodule // magcompare2b

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

module magcompare64b_1 (w, x,  A, B);

   input logic [63:0] A;
   input logic [63:0] B;
   
   logic [31:0]       s;
   logic [31:0]       t;
   logic [15:0]       u;
   logic [15:0]       v;
   output logic [7:0] 	      w;
   output logic [7:0] 	      x;
   
   magcompare2b mag1(s[0], t[0], A[1:0], B[1:0]);
   magcompare2b mag2(s[1], t[1], A[3:2], B[3:2]);
   magcompare2b mag3(s[2], t[2], A[5:4], B[5:4]);
   magcompare2b mag4(s[3], t[3], A[7:6], B[7:6]);
   magcompare2b mag5(s[4], t[4], A[9:8], B[9:8]);
   magcompare2b mag6(s[5], t[5], A[11:10], B[11:10]);
   magcompare2b mag7(s[6], t[6], A[13:12], B[13:12]);
   magcompare2b mag8(s[7], t[7], A[15:14], B[15:14]);
   magcompare2b mag9(s[8], t[8], A[17:16], B[17:16]);
   magcompare2b magA(s[9], t[9], A[19:18], B[19:18]);
   magcompare2b magB(s[10], t[10], A[21:20], B[21:20]);
   magcompare2b magC(s[11], t[11], A[23:22], B[23:22]);
   magcompare2b magD(s[12], t[12], A[25:24], B[25:24]);
   magcompare2b magE(s[13], t[13], A[27:26], B[27:26]);
   magcompare2b magF(s[14], t[14], A[29:28], B[29:28]);
   magcompare2b mag10(s[15], t[15], A[31:30], B[31:30]);
   magcompare2b mag11(s[16], t[16], A[33:32], B[33:32]);
   magcompare2b mag12(s[17], t[17], A[35:34], B[35:34]);
   magcompare2b mag13(s[18], t[18], A[37:36], B[37:36]);
   magcompare2b mag14(s[19], t[19], A[39:38], B[39:38]);
   magcompare2b mag15(s[20], t[20], A[41:40], B[41:40]);
   magcompare2b mag16(s[21], t[21], A[43:42], B[43:42]);
   magcompare2b mag17(s[22], t[22], A[45:44], B[45:44]);
   magcompare2b mag18(s[23], t[23], A[47:46], B[47:46]);
   magcompare2b mag19(s[24], t[24], A[49:48], B[49:48]);
   magcompare2b mag1A(s[25], t[25], A[51:50], B[51:50]);
   magcompare2b mag1B(s[26], t[26], A[53:52], B[53:52]);
   magcompare2b mag1C(s[27], t[27], A[55:54], B[55:54]);
   magcompare2b mag1D(s[28], t[28], A[57:56], B[57:56]);
   magcompare2b mag1E(s[29], t[29], A[59:58], B[59:58]);
   magcompare2b mag1F(s[30], t[30], A[61:60], B[61:60]);
   magcompare2b mag20(s[31], t[31], A[63:62], B[63:62]);

   magcompare2c mag21(u[0], v[0], t[1:0], s[1:0]);
   magcompare2c mag22(u[1], v[1], t[3:2], s[3:2]);
   magcompare2c mag23(u[2], v[2], t[5:4], s[5:4]);
   magcompare2c mag24(u[3], v[3], t[7:6], s[7:6]);
   magcompare2c mag25(u[4], v[4], t[9:8], s[9:8]);
   magcompare2c mag26(u[5], v[5], t[11:10], s[11:10]);
   magcompare2c mag27(u[6], v[6], t[13:12], s[13:12]);
   magcompare2c mag28(u[7], v[7], t[15:14], s[15:14]);
   magcompare2c mag29(u[8], v[8], t[17:16], s[17:16]);
   magcompare2c mag2A(u[9], v[9], t[19:18], s[19:18]);
   magcompare2c mag2B(u[10], v[10], t[21:20], s[21:20]);
   magcompare2c mag2C(u[11], v[11], t[23:22], s[23:22]);
   magcompare2c mag2D(u[12], v[12], t[25:24], s[25:24]);
   magcompare2c mag2E(u[13], v[13], t[27:26], s[27:26]);
   magcompare2c mag2F(u[14], v[14], t[29:28], s[29:28]);
   magcompare2c mag30(u[15], v[15], t[31:30], s[31:30]);

   magcompare2c mag31(w[0], x[0], v[1:0], u[1:0]);
   magcompare2c mag32(w[1], x[1], v[3:2], u[3:2]);
   magcompare2c mag33(w[2], x[2], v[5:4], u[5:4]);
   magcompare2c mag34(w[3], x[3], v[7:6], u[7:6]);
   magcompare2c mag35(w[4], x[4], v[9:8], u[9:8]);
   magcompare2c mag36(w[5], x[5], v[11:10], u[11:10]);
   magcompare2c mag37(w[6], x[6], v[13:12], u[13:12]);
   magcompare2c mag38(w[7], x[7], v[15:14], u[15:14]);

endmodule // magcompare64b

// This module takes 64-bits inputs A and B, two magnitude comparison
// flags LT_mag and EQ_mag, and a 2-bit signal FOpCtrlE that indicates the type of 
// operands being compared as indicated below.
//	FOpCtrlE	Description
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

module exception_cmp_1 (ANaN, BNaN, Azero, Bzero, A, B, FOpCtrlE);

   input logic [63:0] A;
   input logic [63:0] B;
   input logic [2:0]  FOpCtrlE;

   logic 		      dp, sp, hp;

   output logic 	      ANaN;
   output logic 	      BNaN;
   output logic               Azero;
   output logic               Bzero;

   assign dp = !FOpCtrlE[1]&!FOpCtrlE[0];
   assign sp = !FOpCtrlE[1]&FOpCtrlE[0];
   assign hp = FOpCtrlE[1]&!FOpCtrlE[0];

   // Test if A or B is NaN.
   assign ANaN = (A[62]&A[61]&A[60]&A[59]&A[58]) & 
		 ((sp&A[57]&A[56]&A[55]&(A[54]|A[53])) | 
		 (dp&A[57]&A[56]&A[55]&A[54]&A[53]&A[52]&(A[51]|A[50])) |
		 (hp&(A[57]|A[56])));

   assign BNaN = (B[62]&B[61]&B[60]&B[59]&B[58]) & 
		 ((sp&B[57]&B[56]&B[55]&(B[54]|B[53])) | 
		 (dp&B[57]&B[56]&B[55]&B[54]&B[53]&B[52]&(B[51]|B[50])) |
		 (hp&(B[57]|B[56])));

   // Test if A is +0 or -0 when viewed as a floating point number (i.e,
   // the 63 least siginficant bits of A are zero). 
   // Depending on how this synthesizes, it may work better to replace
   // this with assign Azero = ~(A[62] | A[61] | ... | A[0])
   assign Azero = (A[62:0] == 63'h0);
   assign Bzero = (B[62:0] == 63'h0);

endmodule // exception_cmp
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
// signals, and a 2-bit signal FOpCtrlE that indicates the type of 
// operands being compared as indicated below.
//	FOpCtrlE	Description
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

// module magcompare2c (LT, GT, A, B);

//    input logic [1:0] A;
//    input logic [1:0] B;
   
//    output logic      LT;
//    output logic      GT;

//    assign LT = B[1] | (!A[1]&B[0]);
//    assign GT = A[1] | (!B[1]&A[0]);

// endmodule // magcompare2b

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
// flags LT_mag and EQ_mag, and a 2-bit signal FOpCtrlE that indicates the type of 
// operands being compared as indicated below.
//	FOpCtrlE	Description
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

module exception_cmp_2 (
   input logic [63:0] A,
   input logic [63:0] B,
   input logic 	      FmtE,
   input logic 	      LT_mag,
   input logic 	      EQ_mag,
   input logic [2:0]  FOpCtrlE,
   
   output logic       invalid,
   output logic [1:0] fcc,
   output logic [63:0] CmpResE,

   input logic 	      Azero,
   input logic 	      Bzero,   
   input logic 	      ANaN,
   input logic 	      BNaN);
   
   logic 	      dp;   
   logic 	      sp;
   logic 	      hp;   
   logic 	      ASNaN;
   logic 	      BSNaN;
   logic 	      UO;
   logic 	      GT;
   logic 	      LT;
   logic 	      EQ;
   logic [62:0]       sixtythreezeros = 63'h0;

   assign dp = !FOpCtrlE[1]&!FOpCtrlE[0];
   assign sp = !FOpCtrlE[1]&FOpCtrlE[0];
   assign hp = FOpCtrlE[1]&!FOpCtrlE[0];

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

   always_comb begin
      case (FOpCtrlE[2:0])
         3'b111: CmpResE = LT ? A : B;//min 
         3'b101: CmpResE = GT ? A : B;//max
         3'b010: CmpResE = {63'b0, EQ};//equal
         3'b001: CmpResE = {63'b0, LT};//less than
         3'b011: CmpResE = {63'b0, LT|EQ};//less than or equal
         default: CmpResE = 64'b0;
      endcase
   end 

endmodule // exception_cmp
