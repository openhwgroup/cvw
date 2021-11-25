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
   input logic 		    clk, reset,
   // Privileged
   input logic 		    TimerIntM, ExtIntM, SwIntM,
   input logic [63:0] 	    MTIME_CLINT, MTIMECMP_CLINT,
   // Bus Interface
   input logic [`AHBW-1:0]  HRDATA,
   input logic 		    HREADY, HRESP,
   output logic 	    HCLK, HRESETn,
   output logic [31:0] 	    HADDR,
   output logic [`AHBW-1:0] HWDATA,
   output logic 	    HWRITE,
   output logic [2:0] 	    HSIZE,
   output logic [2:0] 	    HBURST,
   output logic [3:0] 	    HPROT,
   output logic [1:0] 	    HTRANS,
   output logic 	    HMASTLOCK,
   // Delayed signals for subword write
   output logic [2:0] 	    HADDRD,
   output logic [3:0] 	    HSIZED,
   output logic 	    HWRITED
   );

  //  logic [1:0]  ForwardAE, ForwardBE;
  logic 		    StallF, StallD, StallE, StallM, StallW;
  logic 		    FlushF, FlushD, FlushE, FlushM, FlushW;
  logic 		    RetM, TrapM;

  // new signals that must connect through DP
  logic 		    MulDivE, W64E;
  logic 		    CSRReadM, CSRWriteM, PrivilegedM;
  logic [1:0] 		    AtomicE;
  logic [1:0] 		    AtomicM;
  logic [`XLEN-1:0] 	ForwardedSrcAE, ForwardedSrcBE, SrcAE, SrcBE;
  logic [`XLEN-1:0] 	    SrcAM;
  logic [2:0] 		    Funct3E;
  //  logic [31:0] InstrF;
  logic [31:0] 		    InstrD, InstrM;
  logic [`XLEN-1:0] 	    PCF, PCE, PCM, PCLinkE;
  logic [`XLEN-1:0] 	    PCTargetE;
  logic [`XLEN-1:0] 	    CSRReadValW, MulDivResultW;
  logic [`XLEN-1:0] 	    PrivilegedNextPCM;
  logic [1:0] 		    MemRWM;
  logic 		    InstrValidM;
  logic 		    InstrMisalignedFaultM;
  logic 		    IllegalBaseInstrFaultD, IllegalIEUInstrFaultD;
  logic 		    ITLBInstrPageFaultF, DTLBLoadPageFaultM, DTLBStorePageFaultM;
  logic 		    WalkerInstrPageFaultF, WalkerLoadPageFaultM, WalkerStorePageFaultM;
  logic 		    LoadMisalignedFaultM, LoadAccessFaultM;
  logic 		    StoreMisalignedFaultM, StoreAccessFaultM;
  logic [`XLEN-1:0] 	    InstrMisalignedAdrM;
  logic       InvalidateICacheM, FlushDCacheM;
  logic 		    PCSrcE;
  logic 		    CSRWritePendingDEM;
  logic 		    DivBusyE;
  logic 		    LoadStallD, StoreStallD, MulDivStallD, CSRRdStallD;
  logic 		    SquashSCW;
  // floating point unit signals
  logic [2:0] 		    FRM_REGW;
   logic [4:0]        RdM, RdW;
  logic 		    FStallD;
  logic 		    FWriteIntE, FWriteIntM, FWriteIntW;
  logic [`XLEN-1:0] 	    FWriteDataE;
  logic [`XLEN-1:0] 	    FIntResM;  
  logic 		    FDivBusyE;
  logic 		    IllegalFPUInstrD, IllegalFPUInstrE;
  logic 		    FRegWriteM;
  logic 		    FPUStallD;
  logic [4:0] 		    SetFflagsM;

  // memory management unit signals
  logic 		    ITLBWriteF;
  logic 		    ITLBFlushF, DTLBFlushM;
  logic 		    ITLBMissF;
  logic [`XLEN-1:0] 	    SATP_REGW;
  logic              STATUS_MXR, STATUS_SUM, STATUS_MPRV;
  logic  [1:0]       STATUS_MPP;
  logic [1:0] 		    PrivilegeModeW;
  logic [`XLEN-1:0] 	PTE;
  logic [1:0] 		    PageType;

  // PMA checker signals
  var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0];
  var logic [7:0]       PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0];

  // IMem stalls
  logic 		    ICacheStallF;
  logic 		    LSUStall;

  

  // cpu lsu interface
  logic [2:0] 		    Funct3M;
  logic [`XLEN-1:0] 	    MemAdrM, MemAdrE, WriteDataM;
  logic [`XLEN-1:0] 	    ReadDataM;
  logic [`XLEN-1:0] 	    ReadDataW;  
  logic 		    CommittedM;

  // AHB ifu interface
  logic [`PA_BITS-1:0] 	    InstrPAdrF;
  logic [`XLEN-1:0] 	    InstrRData;
  logic 		    InstrReadF;
  logic 		    InstrAckF;
  
  // AHB LSU interface
  logic [`PA_BITS-1:0] 	    DCtoAHBPAdrM;
  logic 		    DCtoAHBReadM;
  logic 		    DCtoAHBWriteM;
  logic 		    DCfromAHBAck;
  logic [`XLEN-1:0] 	    DCfromAHBReadData;
  logic [`XLEN-1:0] 	    DCtoAHBWriteData;
  
  logic 		    BPPredWrongE;
  logic 		    BPPredDirWrongM;
  logic 		    BTBPredPCWrongM;
  logic 		    RASPredPCWrongM;
  logic 		    BPPredClassNonCFIWrongM;
  logic [4:0] 		    InstrClassM;
  logic 		    InstrAccessFaultF;
  logic [2:0] 		    DCtoAHBSizeM;
  
  logic 		    ExceptionM;
  logic 		    PendingInterruptM;
  logic 		    DCacheMiss;
  logic 		    DCacheAccess;
  logic 		    BreakpointFaultM, EcallFaultM;

  
  ifu ifu(
    .clk, .reset,
    .StallF, .StallD, .StallE, .StallM, .StallW,
    .FlushF, .FlushD, .FlushE, .FlushM, .FlushW,

    .ExceptionM, .PendingInterruptM,
    // Fetch
    .InstrInF(InstrRData), .InstrAckF, .PCF, .InstrPAdrF,
    .InstrReadF, .ICacheStallF,

    // Execute
    .PCLinkE, .PCSrcE, .PCTargetE, .PCE,
    .BPPredWrongE, 
  
    // Mem
    .RetM, .TrapM, .PrivilegedNextPCM, .InvalidateICacheM,
    .InstrD, .InstrM, . PCM, .InstrClassM, .BPPredDirWrongM,
    .BTBPredPCWrongM, .RASPredPCWrongM, .BPPredClassNonCFIWrongM,
  
    // Writeback

    // output logic
    // Faults
    .IllegalBaseInstrFaultD, .ITLBInstrPageFaultF,
    .IllegalIEUInstrFaultD, .InstrMisalignedFaultM,
    .InstrMisalignedAdrM,

    // mmu management
    .PrivilegeModeW, .PTE, .PageType, .SATP_REGW,
    .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV,
    .STATUS_MPP, .ITLBWriteF, .ITLBFlushF,
    .WalkerInstrPageFaultF, .ITLBMissF,

    // pmp/pma (inside mmu) signals.  *** temporarily from AHB bus but eventually replace with internal versions pre H
    .PMPCFG_ARRAY_REGW,  .PMPADDR_ARRAY_REGW,
    .InstrAccessFaultF

	  
	  ); // instruction fetch unit: PC, branch prediction, instruction cache
    

  ieu ieu(
      .clk, .reset,

      // Decode Stage interface
      .InstrD, .IllegalIEUInstrFaultD, 
      .IllegalBaseInstrFaultD,

      // Execute Stage interface
      .PCE, .PCLinkE, .FWriteIntE, .IllegalFPUInstrE,
      .FWriteDataE, .PCTargetE, .MulDivE, .W64E,
      .Funct3E, .ForwardedSrcAE, .ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
      .SrcAE, .SrcBE, .FWriteIntM,

      // Memory stage interface
      .SquashSCW, // from LSU
      .MemRWM, // read/write control goes to LSU
      .AtomicE, // atomic control goes to LSU	    
      .AtomicM, // atomic control goes to LSU
      .MemAdrM, .MemAdrE, .WriteDataM, // Address and write data to LSU
      .Funct3M, // size and signedness to LSU
      .SrcAM, // to privilege and fpu
      .RdM, .FIntResM, .InvalidateICacheM, .FlushDCacheM,

      // Writeback stage
      .CSRReadValW, .ReadDataM, .MulDivResultW,
      .FWriteIntW, .RdW, .ReadDataW,
      .InstrValidM, 

      // hazards
      .StallD, .StallE, .StallM, .StallW,
      .FlushD, .FlushE, .FlushM, .FlushW,
      .FPUStallD, .LoadStallD, .MulDivStallD, .CSRRdStallD,
      .PCSrcE,
      .CSRReadM, .CSRWriteM, .PrivilegedM,
      .CSRWritePendingDEM, .StoreStallD

  ); // integer execution unit: integer register file, datapath and controller

  lsu lsu(
       .clk, .reset, .StallM, .FlushM, .StallW,
	  .FlushW,
	  // CPU interface
	  .MemRWM, .Funct3M, .Funct7M(InstrM[31:25]),
	  .AtomicM, .ExceptionM, .PendingInterruptM,		
	  .CommittedM, .DCacheMiss, .DCacheAccess,
	  .SquashSCW,            
	  //.DataMisalignedM(DataMisalignedM),
	  .MemAdrE, .MemAdrM, .WriteDataM,
	  .ReadDataM, .FlushDCacheM,
	  // connected to ahb (all stay the same)
	  .DCtoAHBPAdrM, .DCtoAHBReadM, .DCtoAHBWriteM, .DCfromAHBAck,
	  .DCfromAHBReadData, .DCtoAHBWriteData, .DCtoAHBSizeM,

	  // connect to csr or privilege and stay the same.
	  .PrivilegeModeW,           // connects to csr
	  .PMPCFG_ARRAY_REGW,     // connects to csr
	  .PMPADDR_ARRAY_REGW,    // connects to csr
	  // hptw keep i/o
	  .SATP_REGW, // from csr
	  .STATUS_MXR, // from csr
	  .STATUS_SUM,  // from csr
	  .STATUS_MPRV,  // from csr	  	  
	  .STATUS_MPP,  // from csr	  

	  .DTLBFlushM,                   // connects to privilege
	  .DTLBLoadPageFaultM,   // connects to privilege
	  .DTLBStorePageFaultM, // connects to privilege
	  .LoadMisalignedFaultM, // connects to privilege
	  .LoadAccessFaultM,         // connects to privilege
	  .StoreMisalignedFaultM, // connects to privilege
	  .StoreAccessFaultM,     // connects to privilege
    
	  .PCF, .ITLBMissF, .PTE, .PageType, .ITLBWriteF,
       .WalkerInstrPageFaultF, .WalkerLoadPageFaultM,
	  .WalkerStorePageFaultM,
	  .LSUStall);                     // change to LSUStall


  

  ahblite ebu(// IFU connections
     .clk, .reset,
     .UnsignedLoadM(1'b0), .AtomicMaskedM(2'b00),
     .InstrPAdrF, // *** rename these to match block diagram
     .InstrReadF, .InstrRData, .InstrAckF,
     // Signals from Data Cache
     .DCtoAHBPAdrM, .DCtoAHBReadM, .DCtoAHBWriteM, .DCtoAHBWriteData,
     .DCfromAHBReadData,
     .MemSizeM(DCtoAHBSizeM[1:0]),     // *** remove
     .DCfromAHBAck,
 
     .HRDATA, .HREADY, .HRESP, .HCLK, .HRESETn,
     .HADDR, .HWDATA, .HWRITE, .HSIZE, .HBURST,
     .HPROT, .HTRANS, .HMASTLOCK, .HADDRD, .HSIZED,
     .HWRITED);

  
  muldiv mdu(
     .clk, .reset,
	// Execute Stage interface
	//   .SrcAE, .SrcBE,
	.ForwardedSrcAE, .ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B
	.Funct3E, .Funct3M,
     .MulDivE, .W64E,
	// Writeback stage
     .MulDivResultW,
     // Divide Done
	.DivBusyE, 
	// hazards
	.StallM, .StallW, .FlushM, .FlushW 
  ); // multiply and divide unit
  
  hazard     hzu(
     .BPPredWrongE, .CSRWritePendingDEM, .RetM, .TrapM,
     .LoadStallD, .StoreStallD, .MulDivStallD, .CSRRdStallD,
     .LSUStall, .ICacheStallF,
     .FPUStallD, .FStallD,
	.DivBusyE, .FDivBusyE,
	.EcallFaultM, .BreakpointFaultM,
     .InvalidateICacheM,
     // Stall & flush outputs
	.StallF, .StallD, .StallE, .StallM, .StallW,
	.FlushF, .FlushD, .FlushE, .FlushM, .FlushW
     );	// global stall and flush control

  // Priveleged block operates in M and W stages, handling CSRs and exceptions
  privileged priv(
     .clk, .reset,
     .FlushD, .FlushE, .FlushM, .FlushW, 
     .StallD, .StallE, .StallM, .StallW,
     .CSRReadM, .CSRWriteM, .SrcAM, .PCM,
     .InstrM, .CSRReadValW, .PrivilegedNextPCM,
     .RetM, .TrapM, 
     .ITLBFlushF, .DTLBFlushM,
     .InstrValidM, .CommittedM,
     .FRegWriteM, .LoadStallD,
     .BPPredDirWrongM, .BTBPredPCWrongM,
     .RASPredPCWrongM, .BPPredClassNonCFIWrongM,
     .InstrClassM, .DCacheMiss, .DCacheAccess, .PrivilegedM,
     .ITLBInstrPageFaultF, .DTLBLoadPageFaultM, .DTLBStorePageFaultM,
     .WalkerInstrPageFaultF, .WalkerLoadPageFaultM, .WalkerStorePageFaultM,
     .InstrMisalignedFaultM, .IllegalIEUInstrFaultD, .IllegalFPUInstrD,
     .LoadMisalignedFaultM, .StoreMisalignedFaultM,
     .TimerIntM, .ExtIntM, .SwIntM,
     .MTIME_CLINT, .MTIMECMP_CLINT,
     .InstrMisalignedAdrM, .MemAdrM,
     .SetFflagsM,
     // Trap signals from pmp/pma in mmu
     // *** do these need to be split up into one for dmem and one for ifu?
     // instead, could we only care about the instr and F pins that come from ifu and only care about the load/store and m pins that come from dmem?
     .InstrAccessFaultF, .LoadAccessFaultM, .StoreAccessFaultM,
     .ExceptionM, .PendingInterruptM, .IllegalFPUInstrE,
     .PrivilegeModeW, .SATP_REGW,
     .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP,
     .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW, 
     .FRM_REGW,.BreakpointFaultM, .EcallFaultM
  );
  

  fpu fpu(.*); // floating point unit
  
endmodule
