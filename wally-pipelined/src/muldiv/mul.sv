///////////////////////////////////////////
// mul.sv
//
// Written: David_Harris@hmc.edu 16 February 2021
// Modified: 
//
// Purpose: Multiply instructions
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module mul (
  // Execute Stage interface
  input  logic             clk, reset,
  input  logic             StallM, FlushM,
  input  logic [`XLEN-1:0] SrcAE, SrcBE,
  input  logic [2:0]       Funct3E,
  output logic [`XLEN*2-1:0] ProdM
);

    // Number systems
    // Let A' = sum(i=0, XLEN-2, A[i]*2^i)
    // Unsigned: A = A' + A[XLEN-1]*2^(XLEN-1)
    // Signed:   A = A' - A[XLEN-1]*2^(XLEN-1)

    // Multiplication: A*B
    // Let P' = A' * B'
    //     PA = (A' * B[XLEN-1]) 
    //     PB = (B' * A[XLEN-1])
    //     PP = A[XLEN-1] * B[XLEN-1]
    // Signed * Signed     = P' + (-PA - PB)*2^(XLEN-1) + PP*2^(2XLEN-2)
    // Signed * Unsigned   = P' + ( PA - PB)*2^(XLEN-1) - PP*2^(2XLEN-2)
    // Unsigned * Unsigned = P' + ( PA + PB)*2^(XLEN-1) + PP*2^(2XLEN-2)

    logic [`XLEN*2-1:0] PP0E, PP1E, PP2E, PP3E, PP4E;
    logic [`XLEN*2-1:0] PP0M, PP1M, PP2M, PP3M, PP4M;
    logic [`XLEN*2-1:0] Pprime;
    logic [`XLEN-2:0]   PA, PB;
    logic               PP;
    logic               MULH, MULHSU, MULHU;
    logic [`XLEN-1:0]   Aprime, Bprime;

  //////////////////////////////
  // Execute Stage: Compute partial products
  //////////////////////////////

    // portions of product
    //assign Pprime = {1'b0, SrcAE[`XLEN-2:0]} * {1'b0, SrcBE[`XLEN-2:0]};

    // *** assumes unsigned multiplication
    assign Aprime = {1'b0, SrcAE[`XLEN-2:0]};
    assign Bprime = {1'b0, SrcBE[`XLEN-2:0]};
    DW02_multp #(`XLEN, `XLEN, 2*`XLEN) bigmul(.a(Aprime), .b(Bprime), .tc(1'b0), .out0(PP0E), .out1(PP1E));
    // DW02_multp #((`XLEN-1), (`XLEN-1), 2*(`XLEN-1)) multp_dw( .a(SrcAE[`XLEN-2:0]),   .b(SrcBE[`XLEN-2:0]), .tc(1'b0), .out0(Pprime0), .out1(Pprime1) );
    assign PA = {(`XLEN-1){SrcAE[`XLEN-1]}} & SrcBE[`XLEN-2:0];  
    assign PB = {(`XLEN-1){SrcBE[`XLEN-1]}} & SrcAE[`XLEN-2:0];
    assign PP = SrcAE[`XLEN-1] & SrcBE[`XLEN-1];

    // flavor of multiplication
    assign MULH   = (Funct3E == 3'b001);
    assign MULHSU = (Funct3E == 3'b010);
    // assign MULHU = (Funct3E == 2'b11); // signal unused

    // Handle signs
//    assign PP0E = 0;
//    assign PP1E = Pprime; // same for all flavors
    assign PP2E = {2'b00, (MULH | MULHSU) ? ~PA : PA, {(`XLEN-1){1'b0}}};
    assign PP3E = {2'b00, (MULH) ? ~PB : PB, {(`XLEN-1){1'b0}}};
    always_comb 
    if (MULH)        PP4E = {1'b1, PP, {(`XLEN-3){1'b0}}, 1'b1, {(`XLEN){1'b0}}}; 
    else if (MULHSU) PP4E = {1'b1, ~PP, {(`XLEN-2){1'b0}}, 1'b1, {(`XLEN-1){1'b0}}};
    else             PP4E = {1'b0, PP, {(`XLEN*2-2){1'b0}}};

  //////////////////////////////
  // Memory Stage: Sum partial proudcts
  //////////////////////////////

	 flopenrc #(`XLEN*2) PP0Reg(clk, reset, FlushM, ~StallM, PP0E, PP0M); 
	 flopenrc #(`XLEN*2) PP1Reg(clk, reset, FlushM, ~StallM, PP1E, PP1M); 
	 flopenrc #(`XLEN*2) PP2Reg(clk, reset, FlushM, ~StallM, PP2E, PP2M); 
	 flopenrc #(`XLEN*2) PP3Reg(clk, reset, FlushM, ~StallM, PP3E, PP3M); 
	 flopenrc #(`XLEN*2) PP4Reg(clk, reset, FlushM, ~StallM, PP4E, PP4M); 

    assign ProdM = PP0M + PP1M + PP2M + PP3M + PP4M; //SrcAE * SrcBE;
 endmodule

