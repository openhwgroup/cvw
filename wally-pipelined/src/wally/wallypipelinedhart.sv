///////////////////////////////////////////
// wallypipelinedhart.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Pipelined RISC-V Processor
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
/* verilator lint_on UNUSED */

module wallypipelinedhart (
  input  logic             clk, reset,
  output logic [`XLEN-1:0] PCF,
  input  logic [31:0]      InstrF,
  // Privileged
  input  logic             TimerIntM, ExtIntM, SwIntM,
  input  logic             InstrAccessFaultF, 
  input  logic             DataAccessFaultM,
  // Bus Interface
  input  logic [`AHBW-1:0] HRDATA,
  input  logic             HREADY, HRESP,
  output logic             HCLK, HRESETn,
  output logic [31:0]      HADDR,
  output logic [`AHBW-1:0] HWDATA,
  output logic             HWRITE,
  output logic [2:0]       HSIZE,
  output logic [2:0]       HBURST,
  output logic [3:0]       HPROT,
  output logic [1:0]       HTRANS,
  output logic             HMASTLOCK
);

  logic [1:0]  ForwardAE, ForwardBE;
  logic        StallF, StallD, FlushD, FlushE, FlushM, FlushW;
  logic        RetM, TrapM;

  // new signals that must connect through DP
  logic        MulDivE, W64E;
  logic        CSRWriteM, PrivilegedM;
  logic [`XLEN-1:0] SrcAE, SrcBE;
  logic [`XLEN-1:0] SrcAM;
  logic [2:0] Funct3E;
//  logic [31:0] InstrF;
  logic [31:0] InstrD, InstrM;
  logic [`XLEN-1:0] PCE, PCM, PCLinkW;
  logic [`XLEN-1:0] PCTargetE;
  logic [`XLEN-1:0] CSRReadValW, MulDivResultW;
  logic [`XLEN-1:0] PrivilegedNextPCM;
  logic [1:0] MemRWM;
  logic InstrValidW;
  logic InstrMisalignedFaultM;
  logic DataMisalignedM;
  logic IllegalBaseInstrFaultD, IllegalIEUInstrFaultD;
  logic LoadMisalignedFaultM, LoadAccessFaultM;
  logic StoreMisalignedFaultM, StoreAccessFaultM;
  logic [`XLEN-1:0] InstrMisalignedAdrM;
  logic [`XLEN-1:0] zero = 0;

  logic        PCSrcE;
  logic        CSRWritePendingDEM;
  logic        LoadStallD, MulDivStallD;
  logic [4:0] SetFflagsM;
  logic [2:0] FRM_REGW;
  logic       FloatRegWriteW;

  // bus interface to dmem
  logic [1:0]      MemRWAlignedM;
  logic [2:0]      Funct3M;
  logic [`XLEN-1:0] MemAdrM, MemPAdrM, WriteDataM;
  logic [`XLEN-1:0] ReadDataM, ReadDataW;
  logic [`XLEN-1:0] InstrPAdrF;
  logic             DataStall, InstrStall;
  logic             InstrAckD, MemAckW;
           
  ifu ifu(.*); // instruction fetch unit: PC, branch prediction, instruction cache

  ieu ieu(.*); // inteber execution unit: integer register file, datapath and controller
  dmem dmem(/*.Funct3M(InstrM[14:12]),*/ .*); // data cache unit

  ahblite ebu( // *** make IRData InstrF
    .IReadF(1'b1), .IRData(), //.IReady(), 
    .DReadM(MemRWAlignedM[1]), .DWriteM(MemRWAlignedM[0]), 
    .DSizeM(Funct3M[1:0]), .DRData(ReadDataM), //.DReady(), 
    .UnsignedLoadM(Funct3M[2]),
    .*);
  //assign InstrF = ReadDataM[31:0];

 
  muldiv mdu(.*); // multiply and divide unit
 /*  fpu fpu(.*); // floating point unit
  */
  hazard     hzu(.*);	// global stall and flush control

  // Priveleged block operates in M and W stages, handling CSRs and exceptions
  privileged priv(.*);

  // add FPU here, with SetFflagsM, FRM_REGW
  // presently stub out SetFlagsM and FloatRegWriteW
  assign SetFflagsM = 0;
  assign FloatRegWriteW = 0;
             
endmodule
