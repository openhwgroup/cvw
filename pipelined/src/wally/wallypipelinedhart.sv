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
   input logic [63:0] 	    MTIME_CLINT, 
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
  logic 		    RetM;
  (* mark_debug = "true" *) logic TrapM;

  // new signals that must connect through DP
  logic 		    MulDivE, W64E;
  logic 		    CSRReadM, CSRWriteM, PrivilegedM;
  logic [1:0] 		    AtomicE;
  logic [1:0] 		    AtomicM;
  logic [`XLEN-1:0] 	ForwardedSrcAE, ForwardedSrcBE; //, SrcAE, SrcBE;
  logic [`XLEN-1:0] 	    SrcAM;
  logic [2:0] 		    Funct3E;
  //  logic [31:0] InstrF;
  logic [31:0] 		    InstrD, InstrW;
  (* mark_debug = "true" *) logic [31:0] 		    InstrM;
  logic [`XLEN-1:0] 	    PCF, PCD, PCE, PCLinkE;
  (* mark_debug = "true" *) logic [`XLEN-1:0] 	    PCM;
  logic [`XLEN-1:0] 	    CSRReadValW, MulDivResultW;
  logic [`XLEN-1:0] 	    PrivilegedNextPCM;
  (* mark_debug = "true" *) logic [1:0] 		    MemRWM;
  (* mark_debug = "true" *) logic 		    InstrValidM;
  logic 		    InstrMisalignedFaultM;
  logic 		    IllegalBaseInstrFaultD, IllegalIEUInstrFaultD;
  logic 		    ITLBInstrPageFaultF, DTLBLoadPageFaultM, DTLBStorePageFaultM;
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
  logic 		    FWriteIntE;
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
  logic 		    IfuStallF;
  logic 		    LSUStall;

  

  // cpu lsu interface
  logic [2:0] 		    Funct3M;
  logic [`XLEN-1:0] 	    IEUAdrE;
  (* mark_debug = "true" *) logic [`XLEN-1:0] WriteDataM;
  (* mark_debug = "true" *) logic [`XLEN-1:0] 	    IEUAdrM;  
  (* mark_debug = "true" *) logic [`XLEN-1:0] 	    ReadDataM;
  logic [`XLEN-1:0] 	    ReadDataW;  
  logic 		    CommittedM;

  // AHB ifu interface
  logic [`PA_BITS-1:0] 	    IfuBusAdr;
  logic [`XLEN-1:0] 	    IfuBusHRDATA;
  logic 		    IfuBusRead;
  logic 		    IfuBusAck;
  
  // AHB LSU interface
  logic [`PA_BITS-1:0] 	    LsuBusAdr;
  logic 		    LsuBusRead;
  logic 		    LsuBusWrite;
  logic 		    LsuBusAck;
  logic [`XLEN-1:0] 	    LsuBusHRDATA;
  logic [`XLEN-1:0] 	    LsuBusHWDATA;
  
  logic 		    BPPredWrongE;
  logic 		    BPPredDirWrongM;
  logic 		    BTBPredPCWrongM;
  logic 		    RASPredPCWrongM;
  logic 		    BPPredClassNonCFIWrongM;
  logic [4:0] 		    InstrClassM;
  logic 		    InstrAccessFaultF;
  logic [2:0] 		    LsuBusSize;
  
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
    .IfuBusHRDATA, .IfuBusAck, .PCF, .IfuBusAdr,
    .IfuBusRead, .IfuStallF,

    // Execute
    .PCLinkE, .PCSrcE, .IEUAdrE, .PCE,
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
    .ITLBMissF,

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
     .FWriteDataE, .IEUAdrE, .MulDivE, .W64E,
     .Funct3E, .ForwardedSrcAE, .ForwardedSrcBE, // *** these are the src outputs before the mux choosing between them and PCE to put in srcA/B

     // Memory stage interface
     .SquashSCW, // from LSU
     .MemRWM, // read/write control goes to LSU
     .AtomicE, // atomic control goes to LSU	    
     .AtomicM, // atomic control goes to LSU
     .WriteDataM, // Write data to LSU
     .Funct3M, // size and signedness to LSU
     .SrcAM, // to privilege and fpu
     .RdM, .FIntResM, .InvalidateICacheM, .FlushDCacheM,

     // Writeback stage
     .CSRReadValW, .ReadDataM, .MulDivResultW,
     .RdW, .ReadDataW,
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
	.IEUAdrE, .IEUAdrM, .WriteDataM,
	.ReadDataM, .FlushDCacheM,
	// connected to ahb (all stay the same)
	.LsuBusAdr, .LsuBusRead, .LsuBusWrite, .LsuBusAck,
	.LsuBusHRDATA, .LsuBusHWDATA, .LsuBusSize,

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
	.LSUStall);                     // change to LSUStall


   // *** Ross: please make EBU conditional when only supporting internal memories

  ahblite ebu(// IFU connections
     .clk, .reset,
     .UnsignedLoadM(1'b0), .AtomicMaskedM(2'b00),
     .IfuBusAdr,
     .IfuBusRead, .IfuBusHRDATA, .IfuBusAck,
     // Signals from Data Cache
     .LsuBusAdr, .LsuBusRead, .LsuBusWrite, .LsuBusHWDATA,
     .LsuBusHRDATA,
     .LsuBusSize,
     .LsuBusAck,
 
     .HRDATA, .HREADY, .HRESP, .HCLK, .HRESETn,
     .HADDR, .HWDATA, .HWRITE, .HSIZE, .HBURST,
     .HPROT, .HTRANS, .HMASTLOCK, .HADDRD, .HSIZED,
     .HWRITED);

  
   hazard     hzu(
     .BPPredWrongE, .CSRWritePendingDEM, .RetM, .TrapM,
     .LoadStallD, .StoreStallD, .MulDivStallD, .CSRRdStallD,
     .LSUStall, .IfuStallF,
     .FPUStallD, .FStallD,
	.DivBusyE, .FDivBusyE,
	.EcallFaultM, .BreakpointFaultM,
     .InvalidateICacheM,
     // Stall & flush outputs
	.StallF, .StallD, .StallE, .StallM, .StallW,
	.FlushF, .FlushD, .FlushE, .FlushM, .FlushW
     );	// global stall and flush control

   if (`ZICSR_SUPPORTED) begin:priv
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
         .InstrMisalignedFaultM, .IllegalIEUInstrFaultD, .IllegalFPUInstrD,
         .LoadMisalignedFaultM, .StoreMisalignedFaultM,
         .TimerIntM, .ExtIntM, .SwIntM,
         .MTIME_CLINT, 
         .InstrMisalignedAdrM, .IEUAdrM,
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
   end else begin
      assign CSRReadValW = 0;
      assign PrivilegedNextPCM = 0;
      assign RetM = 0;
      assign TrapM = 0;
      assign ITLBFlushF = 0;
      assign DTLBFlushM = 0;
   end
   if (`M_SUPPORTED) begin:mdu
      muldiv mdu(
         .clk, .reset,
         .ForwardedSrcAE, .ForwardedSrcBE, 
         .Funct3E, .Funct3M, .MulDivE, .W64E,
         .MulDivResultW, .DivBusyE, 
         .StallM, .StallW, .FlushM, .FlushW 
      ); 
   end else begin // no M instructions supported
      assign MulDivResultW = 0; 
      assign DivBusyE = 0;
   end

   if (`F_SUPPORTED) begin:fpu
      fpu fpu(
         .clk, .reset,
         .FRM_REGW, // Rounding mode from CSR
         .InstrD, // instruction from IFU
         .ReadDataW,// Read data from memory
         .ForwardedSrcAE, // Integer input being processed (from IEU)
         .StallE, .StallM, .StallW, // stall signals from HZU
         .FlushE, .FlushM, .FlushW, // flush signals from HZU
         .RdM, .RdW, // which FP register to write to (from IEU)
         .FRegWriteM, // FP register write enable
         .FStallD, // Stall the decode stage
         .FWriteIntE, // integer register write enable
         .FWriteDataE, // Data to be written to memory
         .FIntResM, // data to be written to integer register
         .FDivBusyE, // Is the divide/sqrt unit busy (stall execute stage)
         .IllegalFPUInstrD, // Is the instruction an illegal fpu instruction
         .SetFflagsM        // FPU flags (to privileged unit)
      ); // floating point unit
   end else begin // no F_SUPPORTED or D_SUPPORTED; tie outputs low
      assign FStallD = 0;
      assign FWriteIntE = 0; 
      assign FWriteDataE = 0;
      assign FIntResM = 0;
      assign FDivBusyE = 0;
      assign IllegalFPUInstrD = 1;
      assign SetFflagsM = 0;
   end
endmodule
