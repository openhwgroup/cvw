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

module wallypipelinedhart 
  (
   input logic 		    clk, reset,
   output logic [`XLEN-1:0] PCF,
   //  input  logic [31:0]      InstrF,
   // Privileged
   input logic 		    TimerIntM, ExtIntM, SwIntM,
   input logic 		    DataAccessFaultM,
   input logic [63:0] 	    MTIME_CLINT, MTIMECMP_CLINT,
   // Bus Interface
   input logic [15:0] 	    rd2, // bogus, delete when real multicycle fetch works
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
   output logic [5:0] 	    HSELRegions,
   // Delayed signals for subword write
   output logic [2:0] 	    HADDRD,
   output logic [3:0] 	    HSIZED,
   output logic 	    HWRITED
   );

  //  logic [1:0]  ForwardAE, ForwardBE;
  logic 		    StallF, StallD, StallE, StallM, StallW;
  logic 		    FlushF, FlushD, FlushE, FlushM, FlushW;
  logic 		    RetM, TrapM, NonBusTrapM;

  // new signals that must connect through DP
  logic 		    MulDivE, W64E;
  logic 		    CSRReadM, CSRWriteM, PrivilegedM;
  logic [1:0] 		    AtomicE;
  logic [1:0] 		    AtomicM;
  logic [`XLEN-1:0] 	    SrcAE, SrcBE;
  logic [`XLEN-1:0] 	    SrcAM;
  logic [2:0] 		    Funct3E;
  //  logic [31:0] InstrF;
  logic [31:0] 		    InstrD, InstrE, InstrM, InstrW;
  logic [`XLEN-1:0] 	    PCD, PCE, PCM, PCLinkE, PCLinkW;
  logic [`XLEN-1:0] 	    PCTargetE;
  logic [`XLEN-1:0] 	    CSRReadValW, MulDivResultW;
  logic [`XLEN-1:0] 	    PrivilegedNextPCM;
  logic [1:0] 		    MemRWE;  
  logic [1:0] 		    MemRWM;
  logic 		    InstrValidM;
  logic 		    InstrMisalignedFaultM;
  logic 		    DataMisalignedM;
  logic 		    IllegalBaseInstrFaultD, IllegalIEUInstrFaultD;
  logic 		    ITLBInstrPageFaultF, DTLBLoadPageFaultM, DTLBStorePageFaultM;
  logic 		    WalkerInstrPageFaultF, WalkerLoadPageFaultM, WalkerStorePageFaultM;
  logic 		    LoadMisalignedFaultM, LoadAccessFaultM;
  logic 		    StoreMisalignedFaultM, StoreAccessFaultM;
  logic [`XLEN-1:0] 	    InstrMisalignedAdrM;

  logic 		    PCSrcE;
  logic 		    CSRWritePendingDEM;
  logic 		    DivDoneE;
  logic 		    DivBusyE;
  logic 		    RegWriteD;
  logic 		    LoadStallD, StoreStallD, MulDivStallD, CSRRdStallD;
  logic 		    SquashSCM, SquashSCW;
  // floating point unit signals
  logic [2:0] 		    FRM_REGW;
  logic [1:0] 		    FMemRWM, FMemRWE;
  logic [4:0]        RdE, RdM, RdW;
  logic 		    FStallD;
  logic 		    FWriteIntE, FWriteIntM, FWriteIntW;
  logic [`XLEN-1:0] 	    FWriteDataE;
  logic [`XLEN-1:0] 	    FIntResM;  
  logic 		    FDivBusyE;
  logic 		    IllegalFPUInstrD, IllegalFPUInstrE;
  logic 		    FRegWriteM;
  logic 		    FPUStallD;
  logic [4:0] 		    SetFflagsM;
  logic [`XLEN-1:0] 	    FPUResultW;

  // memory management unit signals
  logic 		    ITLBWriteF, DTLBWriteM;
  logic 		    ITLBFlushF, DTLBFlushM;
  logic 		    ITLBMissF, ITLBHitF;
  logic 		    DTLBMissM, DTLBHitM;
  logic [`XLEN-1:0] 	    SATP_REGW;
  logic              STATUS_MXR, STATUS_SUM, STATUS_MPRV;
  logic  [1:0]       STATUS_MPP;
  logic [1:0] 		    PrivilegeModeW;
  logic [`XLEN-1:0] 	    PageTableEntryF, PageTableEntryM;
  logic [1:0] 		    PageType;

  // PMA checker signals
  logic 		    DSquashBusAccessM, ISquashBusAccessF;
  var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0];
  var logic [7:0]       PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0];

  // IMem stalls
  logic 		    ICacheStallF;
  logic 		    LSUStall;

  

  // cpu lsu interface
  logic [2:0] 		    Funct3M;
  logic [`XLEN-1:0] 	    MemAdrM, MemAdrE, WriteDataM;
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
  
  logic 		    CommitM;
  
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

  
  ifu ifu(.InstrInF(InstrRData),
	  .WalkerInstrPageFaultF(WalkerInstrPageFaultF),
	  .*); // instruction fetch unit: PC, branch prediction, instruction cache

  ieu ieu(.*); // integer execution unit: integer register file, datapath and controller

  lsu lsu(.clk(clk),
	  .reset(reset),
	  .StallM(StallM),
	  .FlushM(FlushM),
	  .StallW(StallW),
	  .FlushW(FlushW),
	  // CPU interface
	  .MemRWM(MemRWM),                  
	  .Funct3M(Funct3M),
	  .Funct7M(InstrM[31:25]),
	  .AtomicM(AtomicM),    
	  .ExceptionM(ExceptionM),
	  .PendingInterruptM(PendingInterruptM),		
	  .CommittedM(CommittedM),          
	  .SquashSCW(SquashSCW),            
	  .DataMisalignedM(DataMisalignedM),
	  .MemAdrE(MemAdrE),
	  .MemAdrM(MemAdrM),      
	  .WriteDataM(WriteDataM),
	  .ReadDataW(ReadDataW),

	  // connected to ahb (all stay the same)
	  .CommitM(CommitM),
	  .DCtoAHBPAdrM(DCtoAHBPAdrM),
	  .DCtoAHBReadM(DCtoAHBReadM),
	  .DCtoAHBWriteM(DCtoAHBWriteM),
	  .DCfromAHBAck(DCfromAHBAck),
	  .DCfromAHBReadData(DCfromAHBReadData),
	  .DCtoAHBWriteData(DCtoAHBWriteData),
	  .DCtoAHBSizeM(DCtoAHBSizeM),

	  // connect to csr or privilege and stay the same.
	  .PrivilegeModeW(PrivilegeModeW),           // connects to csr
	  .PMPCFG_ARRAY_REGW(PMPCFG_ARRAY_REGW),     // connects to csr
	  .PMPADDR_ARRAY_REGW(PMPADDR_ARRAY_REGW),    // connects to csr
	  // hptw keep i/o
	  .SATP_REGW(SATP_REGW), // from csr
	  .STATUS_MXR(STATUS_MXR), // from csr
	  .STATUS_SUM(STATUS_SUM),  // from csr
	  .STATUS_MPRV(STATUS_MPRV),  // from csr	  	  
	  .STATUS_MPP(STATUS_MPP),  // from csr	  

	  .DTLBFlushM(DTLBFlushM),                   // connects to privilege
	  .NonBusTrapM(NonBusTrapM),                 // connects to privilege
	  .DTLBLoadPageFaultM(DTLBLoadPageFaultM),   // connects to privilege
	  .DTLBStorePageFaultM(DTLBStorePageFaultM), // connects to privilege
	  .LoadMisalignedFaultM(LoadMisalignedFaultM), // connects to privilege
	  .LoadAccessFaultM(LoadAccessFaultM),         // connects to privilege
	  .StoreMisalignedFaultM(StoreMisalignedFaultM), // connects to privilege
	  .StoreAccessFaultM(StoreAccessFaultM),     // connects to privilege
    
	  .PCF(PCF),
	  .ITLBMissF(ITLBMissF),
	  .PTE(PageTableEntryF),
	  .PageType,
	  .ITLBWriteF(ITLBWriteF),
	  .WalkerInstrPageFaultF(WalkerInstrPageFaultF),
	  .WalkerLoadPageFaultM(WalkerLoadPageFaultM),
	  .WalkerStorePageFaultM(WalkerStorePageFaultM),

	  .DTLBHitM(DTLBHitM), // not connected remove

	  .LSUStall(LSUStall));                     // change to LSUStall


  

  ahblite ebu(// IFU connections
	      .InstrPAdrF(InstrPAdrF),
	      .InstrReadF(InstrReadF),
	      .InstrRData(InstrRData),
	      .InstrAckF(InstrAckF),
	      // LSU connections
	      .DCtoAHBPAdrM(DCtoAHBPAdrM), // rename to DCtoAHBPAdrM
	      .DCtoAHBReadM(DCtoAHBReadM), // rename to DCtoAHBReadM
	      .DCtoAHBWriteM(DCtoAHBWriteM), // rename to DCtoAHBWriteM
	      .DCtoAHBWriteData(DCtoAHBWriteData),
	      .DCfromAHBReadData(DCfromAHBReadData),
	      .DCfromAHBAck(DCfromAHBAck),
	      // remove these
	      .MemSizeM(DCtoAHBSizeM[1:0]),  // *** depends on XLEN  should be removed
	      .UnsignedLoadM(1'b0),
	      .Funct7M(7'b0),
//	      .HRDATAW(),
	      .StallW(1'b0),
	      .AtomicMaskedM(2'b00),
	       .*);

  
  muldiv mdu(.*); // multiply and divide unit
  
  hazard     hzu(.*);	// global stall and flush control

  // Priveleged block operates in M and W stages, handling CSRs and exceptions
  privileged priv(.*);
  

  fpu fpu(.*); // floating point unit
  // add FPU here, with SetFflagsM, FRM_REGW
  // presently stub out SetFlagsM and FRegWriteM
  //assign SetFflagsM = 0;
  //assign FRegWriteM = 0;
  
endmodule
