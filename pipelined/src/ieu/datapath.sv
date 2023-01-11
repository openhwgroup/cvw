///////////////////////////////////////////
// datapath.sv
//
// Written: sarahleilani@gmail.com and David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wally Integer Datapath
// 
// A component of the CORE-V Wally configurable RISC-V project.
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

module datapath (
  input logic clk, reset,
  // Decode stage signals
  input  logic [2:0]       ImmSrcD,
  input  logic [31:0]      InstrD,
  input  logic [2:0]       Funct3E,
  // Execute stage signals
  input  logic             StallE, FlushE,
  input  logic [1:0]       ForwardAE, ForwardBE,
  input  logic [2:0]       ALUControlE,
  input  logic             ALUSrcAE, ALUSrcBE,
  input  logic             ALUResultSrcE, 
  input  logic             JumpE,
  input  logic             BranchSignedE,
  input  logic [`XLEN-1:0] PCE,
  input  logic [`XLEN-1:0] PCLinkE,
  output logic [1:0]       FlagsE,
  output logic [`XLEN-1:0] IEUAdrE,
  output logic [`XLEN-1:0] ForwardedSrcAE, ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
  // Memory stage signals
  input  logic             StallM, FlushM,
  input  logic             FWriteIntM, FCvtIntW,
  input  logic [`XLEN-1:0] FIntResM,
  output logic [`XLEN-1:0] SrcAM,
  output logic [`XLEN-1:0] WriteDataM, 
  // Writeback stage signals
  input  logic             StallW, FlushW,
(* mark_debug = "true" *)  input  logic             RegWriteW, IntDivW,
  input  logic             SquashSCW,
  input  logic [2:0]       ResultSrcW,
  input logic [`XLEN-1:0]  FCvtIntResW,
  input logic [`XLEN-1:0] ReadDataW,
  input  logic [`XLEN-1:0] CSRReadValW, MDUResultW, 
  input logic [`XLEN-1:0] FIntDivResultW,
   // Hazard Unit signals 
  output logic [4:0]       Rs1D, Rs2D, Rs1E, Rs2E,
  output logic [4:0]       RdE, RdM, RdW 
);

  // Fetch stage signals
  // Decode stage signals
  logic [`XLEN-1:0] R1D, R2D;
  logic [`XLEN-1:0] ExtImmD;
  logic [4:0]      RdD;
  // Execute stage signals
  logic [`XLEN-1:0] R1E, R2E;
  logic [`XLEN-1:0] ExtImmE;
  logic [`XLEN-1:0] SrcAE, SrcBE;
  logic [`XLEN-1:0] ALUResultE, AltResultE, IEUResultE;
  // Memory stage signals
  logic [`XLEN-1:0] IEUResultM;
  logic [`XLEN-1:0] IFResultM;
  // Writeback stage signals
  logic [`XLEN-1:0] SCResultW;
  logic [`XLEN-1:0] ResultW;
  logic [`XLEN-1:0] IFResultW, IFCvtResultW, MulDivResultW;

  // Decode stage
  assign Rs1D      = InstrD[19:15];
  assign Rs2D      = InstrD[24:20];
  assign RdD       = InstrD[11:7];
  regfile regf(clk, reset, RegWriteW, Rs1D, Rs2D, RdW, ResultW, R1D, R2D);
  extend ext(.InstrD(InstrD[31:7]), .ImmSrcD, .ExtImmD);
 
  // Execute stage pipeline register and logic
  flopenrc #(`XLEN) RD1EReg(clk, reset, FlushE, ~StallE, R1D, R1E);
  flopenrc #(`XLEN) RD2EReg(clk, reset, FlushE, ~StallE, R2D, R2E);
  flopenrc #(`XLEN) ExtImmEReg(clk, reset, FlushE, ~StallE, ExtImmD, ExtImmE);
  flopenrc #(5)     Rs1EReg(clk, reset, FlushE, ~StallE, Rs1D, Rs1E);
  flopenrc #(5)     Rs2EReg(clk, reset, FlushE, ~StallE, Rs2D, Rs2E);
  flopenrc #(5)     RdEReg(clk, reset, FlushE, ~StallE, RdD, RdE);
	
  mux3  #(`XLEN)  faemux(R1E, ResultW, IFResultM, ForwardAE, ForwardedSrcAE);
  mux3  #(`XLEN)  fbemux(R2E, ResultW, IFResultM, ForwardBE, ForwardedSrcBE);
  comparator_dc_flip #(`XLEN) comp(ForwardedSrcAE, ForwardedSrcBE, BranchSignedE, FlagsE);
  mux2  #(`XLEN)  srcamux(ForwardedSrcAE, PCE, ALUSrcAE, SrcAE);
  mux2  #(`XLEN)  srcbmux(ForwardedSrcBE, ExtImmE, ALUSrcBE, SrcBE);
  alu   #(`XLEN)  alu(SrcAE, SrcBE, ALUControlE, Funct3E, ALUResultE, IEUAdrE);
  mux2 #(`XLEN)   altresultmux(ExtImmE, PCLinkE, JumpE, AltResultE);
  mux2 #(`XLEN)   ieuresultmux(ALUResultE, AltResultE, ALUResultSrcE, IEUResultE);

  // Memory stage pipeline register
  flopenrc #(`XLEN) SrcAMReg(clk, reset, FlushM, ~StallM, SrcAE, SrcAM);
  flopenrc #(`XLEN) IEUResultMReg(clk, reset, FlushM, ~StallM, IEUResultE, IEUResultM);
  flopenrc #(5)     RdMReg(clk, reset, FlushM, ~StallM, RdE, RdM);	
  flopenrc #(`XLEN) WriteDataMReg(clk, reset, FlushM, ~StallM, ForwardedSrcBE, WriteDataM); 
  
  // Writeback stage pipeline register and logic
  flopenrc #(`XLEN) IFResultWReg(clk, reset, FlushW, ~StallW, IFResultM, IFResultW);
  flopenrc #(5)     RdWReg(clk, reset, FlushW, ~StallW, RdM, RdW);

  // floating point inputs: FIntResM comes from fclass, fcmp, fmv; FCvtIntResW comes from fcvt
  if (`F_SUPPORTED) begin:fpmux
    mux2  #(`XLEN)  resultmuxM(IEUResultM, FIntResM, FWriteIntM, IFResultM);
    mux2  #(`XLEN)  cvtresultmuxW(IFResultW, FCvtIntResW, FCvtIntW, IFCvtResultW);
    if (`IDIV_ON_FPU) begin
      mux2  #(`XLEN)  divresultmuxW(MDUResultW, FIntDivResultW, IntDivW, MulDivResultW);
    end else begin 
      assign MulDivResultW = MDUResultW;
    end
  end else begin:fpmux
    assign IFResultM = IEUResultM; assign IFCvtResultW = IFResultW;
    assign MulDivResultW = MDUResultW;
  end
  mux5  #(`XLEN)  resultmuxW(IFCvtResultW, ReadDataW, CSRReadValW, MulDivResultW, SCResultW, ResultSrcW, ResultW); 
 
  // handle Store Conditional result if atomic extension supported
  if (`A_SUPPORTED) assign SCResultW = {{(`XLEN-1){1'b0}}, SquashSCW};
  else              assign SCResultW = 0;
endmodule
