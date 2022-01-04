
// MJS - This module implements a 57-bit 2-to-1 multiplexor, which is
// used in the barrel shifter for significand alignment.

module mux21x57 (Z, A, B, Sel);

   input [56:0] A;
   input [56:0] B;
   input 	Sel;

   output [56:0] Z;

   assign Z = Sel ? B : A;

endmodule // mux21x57

// MJS - This module implements a 64-bit 2-to-1 multiplexor, which is
// used in the barrel shifter for significand normalization. 

module mux21x64 (Z, A, B, Sel);

   input [63:0] A;
   input [63:0] B;
   input 	Sel;

   output [63:0] Z;
   
   assign Z = Sel ? B : A;
   
endmodule // mux21x64
 
// The implementation of the barrel shifter was modified to use 
// fewer gates. It is now implemented using six 64-bit 2-to-1 muxes. The 
// barrel shifter takes a 64-bit input A and shifts it left by up to 
// 63-bits, as specified by Shift, to produce a 63-bit output Z. 
// Bits to the right are filled with zeros. 
// The 64 bit shift is implemented using 6 stages of shifts of 32
// 16, 8, 4, 2, and 1 bit shifts. 

module barrel_shifter_l64 (Z, A, Shift);

   input [63:0] A;
   input [5:0] 	Shift;
   
   wire [63:0] 	stage1;
   wire [63:0] 	stage2;
   wire [63:0] 	stage3;
   wire [63:0] 	stage4;
   wire [63:0] 	stage5;
   wire [31:0] 	thirtytwozeros = 32'h0;
   wire [15:0] 	sixteenzeros = 16'h0;
   wire [ 7:0] 	eightzeros = 8'h0;
   wire [ 3:0] 	fourzeros = 4'h0;
   wire [ 1:0] 	twozeros = 2'b00;
   wire 	onezero = 1'b0;   

   output [63:0] Z;      

   mux21x64  mx01(stage1, A,      {A[31:0], thirtytwozeros}, Shift[5]);
   mux21x64  mx02(stage2, stage1, {stage1[47:0], sixteenzeros}, Shift[4]);
   mux21x64  mx03(stage3, stage2, {stage2[55:0], eightzeros}, Shift[3]);
   mux21x64  mx04(stage4, stage3, {stage3[59:0], fourzeros}, Shift[2]);
   mux21x64  mx05(stage5, stage4, {stage4[61:0], twozeros}, Shift[1]);
   mux21x64  mx06(Z     , stage5, {stage5[62:0], onezero}, Shift[0]);

endmodule // barrel_shifter_l63

// The implementation of the barrel shifter was modified to use 
// fewer gates. It is now implemented using six 57-bit 2-to-1 muxes. The 
// barrel shifter takes a 57-bit input A and right shifts it by up to 
// 63-bits, as specified by Shift, to produce a 57-bit output Z. 
// It also computes a Sticky bit, which is set to 
// one if any of the bits that were shifted out was one.
// Bits shifted into the left are filled with zeros. 
// The 63 bit shift is implemented using 6 stages of shifts of 32
// 16, 8, 4, 2, and 1 bits.

module barrel_shifter_r57 (Z, Sticky, A, Shift);
   
   input [56:0] A;
   input [5:0] 	Shift;

   output 	Sticky;
   output [56:0] Z;      
   
   wire [56:0] 	stage1;
   wire [56:0] 	stage2;
   wire [56:0] 	stage3;
   wire [56:0] 	stage4;
   wire [56:0] 	stage5;
   wire [62:0] 	sixtythreezeros = 63'h0;
   wire [31:0] 	thirtytwozeros = 32'h0;
   wire [15:0] 	sixteenzeros = 16'h0;
   wire [ 7:0] 	eightzeros = 8'h0;
   wire [ 3:0] 	fourzeros = 4'h0;
   wire [ 1:0] 	twozeros = 2'b00;
   wire 	onezero = 1'b0;   
   wire [62:0] 	S;

   // Shift operations
   mux21x57  mx01(stage1,      A, {thirtytwozeros,    A[56:32]}, Shift[5]);
   mux21x57  mx02(stage2, stage1, {sixteenzeros, stage1[56:16]}, Shift[4]);
   mux21x57  mx03(stage3, stage2, {eightzeros, stage2[56:8]}, Shift[3]);
   mux21x57  mx04(stage4, stage3, {fourzeros, stage3[56:4]}, Shift[2]);
   mux21x57  mx05(stage5, stage4, {twozeros, stage4[56:2]}, Shift[1]);
   mux21x57  mx06(Z     , stage5, {onezero, stage5[56:1]}, Shift[0]);

   // Sticky bit calculation. The Sticky bit is set to one if any of the
   // bits that were shifter out were one

   assign S[31:0]  = {32{Shift[5]}} &      A[31:0];  
   assign S[47:32] = {16{Shift[4]}} & stage1[15:0];  
   assign S[55:48] = { 8{Shift[3]}} & stage2[7:0];  
   assign S[59:56] = { 4{Shift[2]}} & stage3[3:0];  
   assign S[61:60] = { 2{Shift[1]}} & stage4[1:0];  
   assign S[62] =        Shift[0]   & stage5[0];  
   assign Sticky = (S != sixtythreezeros);

endmodule // barrel_shifter_r57

/*
module barrel_shifter_r64 (Z, Sticky, A, Shift);
   
   input [63:0] A;
   input [5:0] 	Shift;

   output 	Sticky;
   output [63:0] Z;      
   
   wire [63:0] 	stage1;
   wire [63:0] 	stage2;
   wire [63:0] 	stage3;
   wire [63:0] 	stage4;
   wire [63:0] 	stage5;
   wire [62:0] 	sixtythreezeros = 63'h0;
   wire [31:0] 	thirtytwozeros = 32'h0;
   wire [15:0] 	sixteenzeros = 16'h0;
   wire [ 7:0] 	eightzeros = 8'h0;
   wire [ 3:0] 	fourzeros = 4'h0;
   wire [ 1:0] 	twozeros = 2'b00;
   wire 	onezero = 1'b0;   
   wire [62:0] 	S;

   // Shift operations
   mux21x64  mx01(stage1,      A, {thirtytwozeros,    A[63:32]}, Shift[5]);
   mux21x64  mx02(stage2, stage1, {sixteenzeros, stage1[63:16]}, Shift[4]);
   mux21x64  mx03(stage3, stage2, {eightzeros, stage2[63:8]}, Shift[3]);
   mux21x64  mx04(stage4, stage3, {fourzeros, stage3[63:4]}, Shift[2]);
   mux21x64  mx05(stage5, stage4, {twozeros, stage4[63:2]}, Shift[1]);
   mux21x64  mx06(Z     , stage5, {onezero, stage5[63:1]}, Shift[0]);

   // Sticky bit calculation. The Sticky bit is set to one if any of the
   // bits that were shifter out were one

   assign S[31:0]  = {32{Shift[5]}} &      A[31:0];  
   assign S[47:32] = {16{Shift[4]}} & stage1[15:0];  
   assign S[55:48] = { 8{Shift[3]}} & stage2[7:0];  
   assign S[59:56] = { 4{Shift[2]}} & stage3[3:0];  
   assign S[61:60] = { 2{Shift[1]}} & stage4[1:0];  
   assign S[62] =        Shift[0]   & stage5[0];  
   assign Sticky = (S != sixtythreezeros);

endmodule // barrel_shifter_r64
*/