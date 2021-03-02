///////////////////////////////////////////
// datapath.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wally Integer Datapath
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

module datapath (
  input logic clk, reset,
  // Decode stage signals
  input  logic [2:0]       ImmSrcD,
  input  logic [31:0]      InstrD,
  // Execute stage signals
  input  logic             StallE, FlushE,
  input  logic [1:0]       ForwardAE, ForwardBE,
  input  logic [4:0]       ALUControlE,
  input  logic             ALUSrcAE, ALUSrcBE,
  input  logic             TargetSrcE, 
  input  logic [`XLEN-1:0] PCE,
  output logic [2:0]       FlagsE,
  output logic [`XLEN-1:0] PCTargetE,
  output logic [`XLEN-1:0] SrcAE, SrcBE,
  // Memory stage signals
  input  logic             StallM, FlushM,
  output logic [`XLEN-1:0] SrcAM,
  output logic [`XLEN-1:0] WriteDataM, MemAdrM,
  // Writeback stage signals
  input  logic             StallW, FlushW,
  input  logic             RegWriteW, 
  input  logic             SquashSCW,
  input  logic [2:0]       ResultSrcW,
  input  logic [`XLEN-1:0] PCLinkW,
  input  logic [`XLEN-1:0] CSRReadValW, ReadDataW, MulDivResultW, 
  // Hazard Unit signals 
  output logic [4:0]       Rs1D, Rs2D, Rs1E, Rs2E,
  output logic [4:0]       RdE, RdM, RdW 
);

  // Fetch stage signals
  // Decode stage signals
  logic [`XLEN-1:0] RD1D, RD2D;
  logic [`XLEN-1:0] ExtImmD;
  logic [4:0]      RdD;
  // Execute stage signals
  logic [`XLEN-1:0] RD1E, RD2E;
  logic [`XLEN-1:0] ExtImmE;
  logic [`XLEN-1:0] PreSrcAE;
  logic [`XLEN-1:0] ALUResultE;
  logic [`XLEN-1:0] WriteDataE;
  logic [`XLEN-1:0] TargetBaseE;
  // Memory stage signals
  logic [`XLEN-1:0] ALUResultM;
  // Writeback stage signals
  logic [`XLEN-1:0] SCResultW;
  logic [`XLEN-1:0] ALUResultW;
  logic [`XLEN-1:0] ResultW;

  // Decode stage
  assign Rs1D      = InstrD[19:15];
  assign Rs2D      = InstrD[24:20];
  assign RdD       = InstrD[11:7];
  regfile regf(clk, reset, RegWriteW, Rs1D, Rs2D, RdW, ResultW, RD1D, RD2D);
  extend ext(.InstrD(InstrD[31:7]), .*);
 
  // Execute stage pipeline register and logic
  flopenrc #(`XLEN) RD1EReg(clk, reset, FlushE, ~StallE, RD1D, RD1E);
  flopenrc #(`XLEN) RD2EReg(clk, reset, FlushE, ~StallE, RD2D, RD2E);
  flopenrc #(`XLEN) ExtImmEReg(clk, reset, FlushE, ~StallE, ExtImmD, ExtImmE);
  flopenrc #(5)    Rs1EReg(clk, reset, FlushE, ~StallE, Rs1D, Rs1E);
  flopenrc #(5)    Rs2EReg(clk, reset, FlushE, ~StallE, Rs2D, Rs2E);
  flopenrc #(5)    RdEReg(clk, reset, FlushE, ~StallE, RdD, RdE);
	
  mux3  #(`XLEN)  faemux(RD1E, ResultW, ALUResultM, ForwardAE, PreSrcAE);
  mux3  #(`XLEN)  fbemux(RD2E, ResultW, ALUResultM, ForwardBE, WriteDataE);
  mux2  #(`XLEN)  srcamux(PreSrcAE, PCE, ALUSrcAE, SrcAE);
  mux2  #(`XLEN)  srcbmux(WriteDataE, ExtImmE, ALUSrcBE, SrcBE);
  alu   #(`XLEN)  alu(SrcAE, SrcBE, ALUControlE, ALUResultE, FlagsE);
  mux2  #(`XLEN)  targetsrcmux(PCE, SrcAE, TargetSrcE, TargetBaseE);
  assign  PCTargetE = ExtImmE + TargetBaseE;

  // Memory stage pipeline register
  flopenrc #(`XLEN) SrcAMReg(clk, reset, FlushM, ~StallM, SrcAE, SrcAM);
  flopenrc #(`XLEN) ALUResultMReg(clk, reset, FlushM, ~StallM, ALUResultE, ALUResultM);
  assign MemAdrM = ALUResultM;
  flopenrc #(`XLEN) WriteDataMReg(clk, reset, FlushM, ~StallM, WriteDataE, WriteDataM);
  flopenrc #(5)    RdMEg(clk, reset, FlushM, ~StallM, RdE, RdM);
  
  // Writeback stage pipeline register and logic
  flopenrc #(`XLEN) ALUResultWReg(clk, reset, FlushW, ~StallW, ALUResultM, ALUResultW);
  flopenrc #(5)    RdWEg(clk, reset, FlushW, ~StallW, RdM, RdW);

  // handle Store Conditional result if atomic extension supported
  generate 
    if (`A_SUPPORTED)
      assign SCResultW = SquashSCW ? {{(`XLEN-1){1'b0}}, 1'b1} : {{(`XLEN-1){1'b0}}, 1'b0};
    else 
      assign SCResultW = 0;
  endgenerate

  mux6  #(`XLEN) resultmux(ALUResultW, ReadDataW, PCLinkW, CSRReadValW, MulDivResultW, SCResultW, ResultSrcW, ResultW);	
endmodule
