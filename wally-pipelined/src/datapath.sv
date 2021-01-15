///////////////////////////////////////////
// datapath.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wally Datapath
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

`include "wally-macros.sv"

module datapath #(parameter XLEN=32, MISA=0, ZCSR = 1, ZCOUNTERS = 1) (
  input logic clk, reset,
  // Fetch stage signals
  input  logic        StallF,
  output logic [XLEN-1:0] PCF,
  input  logic [31:0] InstrF,
  // Decode stage signals
  output logic [6:0]  opD,
  output logic [2:0]	funct3D, 
  output logic        funct7b5D,
  input  logic        StallD, FlushD,
  input  logic [2:0]  ImmSrcD,
  input  logic        LoadStallD, // for performance counter
  output logic        IllegalCompInstrD,
  // Execute stage signals
  input  logic        FlushE,
  input  logic [1:0]  ForwardAE, ForwardBE,
  input  logic        PCSrcE,
  input  logic [4:0]  ALUControlE,
  input  logic        ALUSrcAE, ALUSrcBE,
  input  logic        TargetSrcE, 
  output logic [2:0]  FlagsE,
  // Memory stage signals
  input  logic         FlushM,
  input  logic [1:0]  MemRWM,
  input  logic        CSRWriteM, PrivilegedM, 
  input  logic        InstrAccessFaultM, IllegalInstrFaultM,
  input  logic        TimerIntM, ExtIntM, SwIntM,
  output logic        InstrMisalignedFaultM,
  input  logic [2:0]  Funct3M,
  output logic [XLEN-1:0] WriteDataExtM, ALUResultM,
  input  logic [XLEN-1:0] ReadDataM,
  output logic [7:0]  ByteMaskM,
  output logic        RetM, TrapM,
  input  logic [4:0]  SetFflagsM,
  input  logic        DataAccessFaultM,
  // Writeback stage signals
  input  logic        FlushW,
  input  logic        RegWriteW, 
  input  logic [1:0]  ResultSrcW,
  input  logic        InstrValidW,
  input  logic        FloatRegWriteW,
  output logic [2:0]  FRM_REGW,
  // Hazard Unit signals 
  output logic [4:0]  Rs1D, Rs2D, Rs1E, Rs2E,
  output logic [4:0]  RdE, RdM, RdW);

  // Fetch stage signals
  logic [XLEN-1:0] PCPlus2or4F;
  // Decode stage signals
  logic [31:0]     InstrD;
  logic [XLEN-1:0] PCD, PCPlus2or4D;
  logic [XLEN-1:0] RD1D, RD2D;
  logic [XLEN-1:0] ExtImmD;
  logic [31:0]     InstrDecompD;
  logic [4:0]      RdD;
  // Execute stage signals
  logic [31:0]     InstrE;
  logic [XLEN-1:0] RD1E, RD2E;
  logic [XLEN-1:0] PCE, ExtImmE;
  logic [XLEN-1:0] PreSrcAE, SrcAE, SrcBE;
  logic [XLEN-1:0] ALUResultE;
  logic [XLEN-1:0] WriteDataE;
  logic [XLEN-1:0] TargetBaseE, PCTargetE;
  // Memory stage signals
  logic [31:0]     InstrM;
  logic [XLEN-1:0] PCM;
  logic [XLEN-1:0] SrcAM;
  logic [XLEN-1:0] ReadDataExtM;
  logic [XLEN-1:0] WriteDataM;
  logic [XLEN-1:0] CSRReadValM;
  logic [XLEN-1:0] PrivilegedNextPCM;
  logic            LoadMisalignedFaultM, LoadAccessFaultM;
  logic            StoreMisalignedFaultM, StoreAccessFaultM;
  logic [XLEN-1:0] InstrMisalignedAdrM;
  // Writeback stage signals
  logic [XLEN-1:0] ALUResultW;
  logic [XLEN-1:0] ReadDataW;
  logic [XLEN-1:0] PCW;
  logic [XLEN-1:0] CSRValW;
  logic [XLEN-1:0] ResultW;

  logic [31:0]     nop = 32'h00000013; // instruction for NOP

  // Fetch stage pipeline register and logic; also Ex stage for branches
  pclogic #(XLEN, MISA) pclogic(clk, reset, StallF, PCSrcE, 
                          InstrF, ExtImmE, TargetBaseE, RetM, TrapM, PrivilegedNextPCM, PCF, PCPlus2or4F, 
                          InstrMisalignedFaultM, InstrMisalignedAdrM);

  // Decode stage pipeline register and logic
  flopenl #(32)    InstrDReg(clk, reset, ~StallD, (FlushD ? nop : InstrF), nop, InstrD);
  flopenrc #(XLEN) PCDReg(clk, reset, FlushD, ~StallD, PCF, PCD);
  flopenrc #(XLEN) PCPlus2or4DReg(clk, reset, FlushD, ~StallD, PCPlus2or4F, PCPlus2or4D);
   
  instrDecompress #(XLEN, MISA) decomp(InstrD, InstrDecompD, IllegalCompInstrD);
  assign opD       = InstrDecompD[6:0];
  assign funct3D   = InstrDecompD[14:12];
  assign funct7b5D = InstrDecompD[30];
  assign Rs1D      = InstrDecompD[19:15];
  assign Rs2D      = InstrDecompD[24:20];
  assign RdD       = InstrDecompD[11:7];
	
  regfile #(XLEN) regf(clk, reset, RegWriteW, Rs1D, Rs2D, RdW, ResultW, RD1D, RD2D);
  extend  #(XLEN) ext(InstrDecompD[31:7], ImmSrcD, ExtImmD);
 
  // Execute stage pipeline register and logic
  floprc #(XLEN) RD1EReg(clk, reset, FlushE, RD1D, RD1E);
  floprc #(XLEN) RD2EReg(clk, reset, FlushE, RD2D, RD2E);
  floprc #(XLEN) PCEReg(clk, reset, FlushE, PCD, PCE);
  floprc #(XLEN) ExtImmEReg(clk, reset, FlushE, ExtImmD, ExtImmE);
  flopr  #(32)   InstrEReg(clk, reset, FlushE ? nop : InstrDecompD, InstrE);
  floprc #(5)    Rs1EReg(clk, reset, FlushE, Rs1D, Rs1E);
  floprc #(5)    Rs2EReg(clk, reset, FlushE, Rs2D, Rs2E);
  floprc #(5)    RdEReg(clk, reset, FlushE, RdD, RdE);
	
  mux3  #(XLEN)  faemux(RD1E, ResultW, ALUResultM, ForwardAE, PreSrcAE);
  mux3  #(XLEN)  fbemux(RD2E, ResultW, ALUResultM, ForwardBE, WriteDataE);
  mux2  #(XLEN)  srcamux(PreSrcAE, PCE, ALUSrcAE, SrcAE);
  mux2  #(XLEN)  srcbmux(WriteDataE, ExtImmE, ALUSrcBE, SrcBE);
  alu   #(XLEN)  alu(SrcAE, SrcBE, ALUControlE, ALUResultE, FlagsE);
  mux2  #(XLEN)  targetsrcmux(PCE, SrcAE, TargetSrcE, TargetBaseE);

  // Memory stage pipeline register
  floprc #(XLEN) SrcAMReg(clk, reset, FlushM, SrcAE, SrcAM);
  floprc #(XLEN) ALUResultMReg(clk, reset, FlushM, ALUResultE, ALUResultM);
  floprc #(XLEN) WriteDataMReg(clk, reset, FlushM, WriteDataE, WriteDataM);
  floprc #(XLEN) PCMReg(clk, reset, FlushM, PCE, PCM);
  flopr  #(32)   InstrMReg(clk, reset, FlushM ? nop : InstrE, InstrM);
  floprc #(5)    RdMEg(clk, reset, FlushM, RdE, RdM);
  
  memdp #(XLEN) memdp(
    MemRWM, ReadDataM, ALUResultM, Funct3M, ReadDataExtM, WriteDataM, WriteDataExtM, ByteMaskM, 
    DataAccessFaultM, LoadMisalignedFaultM, LoadAccessFaultM, StoreMisalignedFaultM, StoreAccessFaultM);
  
  // Priveleged block operates in M and W stages, handling CSRs and exceptions
  privileged #(XLEN, MISA, ZCSR, ZCOUNTERS) priv(
    clk, reset, CSRWriteM, SrcAM, InstrM, PCM, 
    CSRReadValM, PrivilegedNextPCM, RetM, TrapM,
    InstrValidW, FloatRegWriteW, LoadStallD, PrivilegedM, 
    InstrMisalignedFaultM, InstrAccessFaultM, IllegalInstrFaultM,
    LoadMisalignedFaultM, LoadAccessFaultM, StoreMisalignedFaultM, StoreAccessFaultM,
    TimerIntM, ExtIntM, SwIntM,
    InstrMisalignedAdrM, ALUResultM,
    SetFflagsM, FRM_REGW);

  // Writeback stage pipeline register and logic
  floprc #(XLEN) ALUResultWReg(clk, reset, FlushW, ALUResultM, ALUResultW);
  floprc #(XLEN) ReadDataWReg(clk, reset, FlushW, ReadDataExtM, ReadDataW);
  floprc #(XLEN) PCWReg(clk, reset, FlushW, PCM, PCW);
  floprc #(XLEN) CSRValWReg(clk, reset, FlushW, CSRReadValM, CSRValW);
  floprc #(5)    RdWEg(clk, reset, FlushW, RdM, RdW);

  mux4  #(XLEN) resultmux(ALUResultW, ReadDataW, PCW, CSRValW, ResultSrcW, ResultW);	
endmodule
