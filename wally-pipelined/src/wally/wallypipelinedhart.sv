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
//  input  logic [31:0]      InstrF,
  // Privileged
  input  logic             TimerIntM, ExtIntM, SwIntM,
  input  logic             InstrAccessFaultF, 
  input  logic             DataAccessFaultM,
  // Bus Interface
  input  logic [15:0]      rd2, // bogus, delete when real multicycle fetch works
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
  output logic             HMASTLOCK,
  // Delayed signals for subword write
  output logic [2:0]       HADDRD,
  output logic [3:0]       HSIZED,
  output logic             HWRITED
);

//  logic [1:0]  ForwardAE, ForwardBE;
  logic        StallF, StallD, StallE, StallM, StallW;
  logic        FlushF, FlushD, FlushE, FlushM, FlushW;
  logic        RetM, TrapM;

  // new signals that must connect through DP
  logic        MulDivE, W64E;
  logic        CSRReadM, CSRWriteM, PrivilegedM;
  logic [1:0]  AtomicM;
  logic [`XLEN-1:0] SrcAE, SrcBE;
  logic [`XLEN-1:0] SrcAM;
  logic [2:0] Funct3E;
//  logic [31:0] InstrF;
  logic [31:0] InstrD, InstrM;
  logic [`XLEN-1:0] PCE, PCM, PCLinkE, PCLinkW;
  logic [`XLEN-1:0] PCTargetE;
  logic [`XLEN-1:0] CSRReadValW, MulDivResultW;
  logic [`XLEN-1:0] PrivilegedNextPCM;
  logic [1:0] MemRWM;
  logic InstrValidW;
  logic InstrMisalignedFaultM;
  logic DataMisalignedM;
  logic IllegalBaseInstrFaultD, IllegalIEUInstrFaultD;
  logic InstrPageFaultM, LoadPageFaultM, StorePageFaultM;
  logic LoadMisalignedFaultM, LoadAccessFaultM;
  logic StoreMisalignedFaultM, StoreAccessFaultM;
  logic [`XLEN-1:0] InstrMisalignedAdrM;

  logic        PCSrcE;
  logic        CSRWritePendingDEM;
  logic        LoadStallD, MulDivStallD, CSRRdStallD;
  logic [4:0] SetFflagsM;
  logic [2:0] FRM_REGW;
  logic       FloatRegWriteW;
  logic       SquashSCW;

  // memory management unit signals
  logic             ITLBWriteF, DTLBWriteM;
  logic             ITLBMissF, ITLBHitF;
  logic             DTLBMissM, DTLBHitM;
  logic [`XLEN-1:0] SATP_REGW;
  logic [1:0]       PrivilegeModeW;

  logic [`XLEN-1:0] PageTableEntryF, PageTableEntryM;

  // IMem stalls
  logic             ICacheStallF;
  logic [`XLEN-1:0] MMUPAdr, MMUReadPTE;
  logic             MMUTranslate, MMUTranslationComplete, MMUReady;

  // bus interface to dmem
  logic             MemReadM, MemWriteM;
  logic [2:0]       Funct3M;
  logic [`XLEN-1:0] MemAdrM, MemPAdrM, WriteDataM;
  logic [`XLEN-1:0] ReadDataW;
  logic [`XLEN-1:0] InstrPAdrF;
  logic [`XLEN-1:0] InstrRData;
  logic             InstrReadF;
  logic             DataStall, InstrStall;
  logic             InstrAckF, MemAckW;

  logic             BPPredWrongE, BPPredWrongM;
  logic [3:0]       InstrClassM;
  
           
  ifu ifu(.InstrInF(InstrRData), .*); // instruction fetch unit: PC, branch prediction, instruction cache

  ieu ieu(.*); // integer execution unit: integer register file, datapath and controller
  dmem dmem(.*); // data cache unit

  ahblite ebu( 
    //.InstrReadF(1'b0),
    //.InstrRData(InstrF), // hook up InstrF later
    .MemSizeM(Funct3M[1:0]), .UnsignedLoadM(Funct3M[2]),
    .Funct7M(InstrM[31:25]),
    .*);

  pagetablewalker pagetablewalker(.*); // can send addresses to ahblite, send out pagetablestall
  // *** can connect to hazard unit
// changing from this to the line above breaks the program.  auipc at 104 fails; seems to be flushed.
// Would need to insertinstruction as InstrD, not InstrF
    /*ahblite ebu( 
  .InstrReadF(1'b0),
    .InstrRData(), // hook up InstrF later
    .MemSizeM(Funct3M[1:0]), .UnsignedLoadM(Funct3M[2]),
    .*); */

 
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
