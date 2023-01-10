///////////////////////////////////////////
// comparator.sv
//
// Written: David_Harris@hmc.edu 8 December 2021
// Modified: 
//
// Purpose: Branch comparison
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

// This comparator is best
module comparator_dc_flip #(parameter WIDTH=64) (
  input  logic [WIDTH-1:0] a, b,
  input  logic             sgnd,
  output logic [1:0]       flags);

  logic eq, lt, ltu;
  logic [WIDTH-1:0] af, bf;

  // For signed numbers, flip most significant bit
  assign af = {a[WIDTH-1] ^ sgnd, a[WIDTH-2:0]};
  assign bf = {b[WIDTH-1] ^ sgnd, b[WIDTH-2:0]};

  // behavioral description gives best results
  assign eq = (a == b);
  assign lt = (af < bf);
  assign flags = {eq, lt};
endmodule

/*

Other comparators evaluated

module donedet #(parameter WIDTH=64) (
  input  logic [WIDTH-1:0] a, b,
  output logic        eq);

  //assign eq = (a+b == 0); // gives good speed but 3x necessary area
  // See CMOS VLSI Design 4th Ed. p. 463 K = A+B for K = 0
  assign eq = ((a ^ b) == {a[WIDTH-2:0], 1'b0} | {b[WIDTH-2:0], 1'b0});
 endmodule

module comparator_sub #(parameter WIDTH=64) (
  input  logic [WIDTH-1:0] a, b,
  output logic [2:0]       flags);

  logic eq, lt, ltu;


  // Subtractor implementation
  logic [WIDTH-1:0] bbar, diff;
  logic             carry, neg, overflow;

  // subtraction
  assign bbar = ~b;
  assign {carry, diff} = a + bbar + 1;

  // condition code flags based on add/subtract output
  assign eq = (diff == 0);
  assign neg  = diff[WIDTH-1];
  // overflow occurs when the numbers being subtracted have the opposite sign 
  // and the result has the opposite sign fron the first
  assign overflow = (a[WIDTH-1] ^ b[WIDTH-1]) & (a[WIDTH-1] ^ diff[WIDTH-1]);
  assign lt = neg ^ overflow;
  assign ltu = ~carry;
  assign flags = {eq, lt, ltu};
endmodule

// *** eventually substitute comparator_flip, which gives slightly better synthesis
module comparator #(parameter WIDTH=64) (
  input  logic [WIDTH-1:0] a, b,
  output logic [2:0]       flags);

  logic eq, lt, ltu;

  // Behavioral description gives best results
  assign eq = (a == b);
  assign ltu = (a < b);
  assign lt = ($signed(a) < $signed(b));

  assign flags = {eq, lt, ltu};
endmodule


module comparator2 #(parameter WIDTH=64) (
  input  logic [WIDTH-1:0] a, b,
  output logic [2:0]       flags);

  logic eq, lt, ltu;

  /* verilator lint_off UNOPTFLAT /
  // prefix implementation
  localparam levels=$clog2(WIDTH);
  genvar i;
  genvar level;
  logic [WIDTH-1:0] e[levels:0];
  logic [WIDTH-1:0] l[levels:0];
  logic eq2, lt2, ltu2;

  // Bitwise logic
  assign e[0] = a ~^ b; // bitwise equality
  assign l[0] = ~a & b; // bitwise less than unsigned: A=0 and B=1

  // Recursion
  for (level = 1; level<=levels; level++) begin
    for (i=0; i<WIDTH/(2**level); i++) begin
      assign e[level][i] = e[level-1][i*2+1] & e[level-1][i*2];  // group equal if both parts equal
      assign l[level][i] = l[level-1][i*2+1] | e[level-1][i*2+1] & l[level-1][i*2]; // group less if upper is les or upper equal and lower less
    end
  end

  // Output logic
  assign eq2 = e[levels][0];  // A = B if all bits are equal
  assign ltu2 = l[levels][0]; // A < B if group is less (unsigned)
  // A < B signed if less than unsigned and msb is not < unsigned, or if A negative and B positive
  assign lt2 = ltu2 & ~l[0][WIDTH-1] | a[WIDTH-1] & ~b[WIDTH-1]; 
  assign flags = {eq2, lt2, ltu2};
  /* verilator lint_on UNOPTFLAT /
endmodule


module comparator_prefix #(parameter WIDTH=64) (
  input  logic [WIDTH-1:0] a, b,
  output logic [2:0]       flags);

  logic eq, lt, ltu;

  /* verilator lint_off UNOPTFLAT 
  // prefix implementation
  localparam levels=$clog2(WIDTH);
  genvar i;
  genvar level;
  logic [WIDTH-1:0] e[levels:0];
  logic [WIDTH-1:0] l[levels:0];
  logic eq2, lt2, ltu2;

  // Bitwise logic
  assign e[0] = a ~^ b; // bitwise equality
  assign l[0] = ~a & b; // bitwise less than unsigned: A=0 and B=1

  // Recursion
  for (level = 1; level<=levels; level++) begin
    for (i=0; i<WIDTH/(2**level); i++) begin
      assign e[level][i] = e[level-1][i*2+1] & e[level-1][i*2];  // group equal if both parts equal
      assign l[level][i] = l[level-1][i*2+1] | e[level-1][i*2+1] & l[level-1][i*2]; // group less if upper is les or upper equal and lower less
    end
  end

  // Output logic
  assign eq2 = e[levels][0];  // A = B if all bits are equal
  assign ltu2 = l[levels][0]; // A < B if group is less (unsigned)
  // A < B signed if less than unsigned and msb is not < unsigned, or if A negative and B positive
  assign lt2 = ltu2 & ~l[0][WIDTH-1] | a[WIDTH-1] & ~b[WIDTH-1]; 
  assign flags = {eq2, lt2, ltu2};
  /* verilator lint_on UNOPTFLAT /
endmodule



module magcompare2b (LT, GT, A, B);

   input logic [1:0] A;
   input logic [1:0] B;
   
   output logic     LT;
   output logic     GT;

   // Determine if A < B  using a minimized sum-of-products expression
   assign LT = ~A[1]&B[1] | ~A[1]&~A[0]&B[0] | ~A[0]&B[1]&B[0];
   // Determine if A > B  using a minimized sum-of-products expression
   assign GT = A[1]&~B[1] | A[1]&A[0]&~B[0] | A[0]&~B[1]&~B[0];

endmodule // magcompare2b

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

module stinecomp64 (FCC, A, B, Sel);

   input logic [63:0] A;
   input logic [63:0] B;
   input logic 	      Sel;   

   output logic [1:0] FCC;   
   
   logic [31:0]       s;
   logic [31:0]       t;
   logic [15:0]       u;
   logic [15:0]       v;
   logic [7:0] 	      w;
   logic [7:0] 	      x;
   logic [3:0] 	      y;
   logic [3:0] 	      z;
   logic [1:0] 	      a;
   logic [1:0] 	      b;   
   logic 	      GT;
   logic 	      LT;
   logic 	      EQ;
   logic [1:0] 	      A2;
   logic [1:0] 	      B2;

   assign A2 = Sel ? {~A[63], A[62]} : A[63:62];
   assign B2 = Sel ? {~B[63], B[62]} : B[63:62];      
   
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
   magcompare2b mag20(s[31], t[31], A2, B2);

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

   magcompare2c mag39(y[0], z[0], x[1:0], w[1:0]);
   magcompare2c mag3A(y[1], z[1], x[3:2], w[3:2]);
   magcompare2c mag3B(y[2], z[2], x[5:4], w[5:4]);
   magcompare2c mag3C(y[3], z[3], x[7:6], w[7:6]);
   
   magcompare2c mag3D(a[0], b[0], z[1:0], y[1:0]);
   magcompare2c mag3E(a[1], b[1], z[3:2], y[3:2]);
   
   magcompare2c mag3F(LT, GT, b[1:0], a[1:0]);

   assign EQ = ~(LT | GT);
   assign FCC = {LT, EQ};   

endmodule // comp64
*/