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
   input logic 		    InstrAccessFaultF, 
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
  logic [1:0] 		    MemRWM;
  logic 		    InstrValidM, InstrValidW;
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
  logic 		    FPUStallD, LoadStallD, MulDivStallD, CSRRdStallD;
  logic 		    DivDoneE;
  logic 		    DivBusyE;
  logic 		    DivDoneW;
  logic [4:0] 		    SetFflagsM;
  logic [2:0] 		    FRM_REGW;
  logic 		    FloatRegWriteW;
  logic [1:0] 		    FMemRWM;
  logic 		    RegWriteD;
  logic [`XLEN-1:0] 	    FWriteDataM;
  logic 		    SquashSCW;
  logic 		    FStallD;
  logic 		    FWriteIntE, FWriteIntW, FWriteIntM;
  logic 		    FDivBusyE;
  logic 		    IllegalFPUInstrD, IllegalFPUInstrE;
  logic [`XLEN-1:0] 	    FPUResultW;

  // memory management unit signals
  logic 		    ITLBWriteF, DTLBWriteM;
  logic 		    ITLBFlushF, DTLBFlushM;
  logic 		    ITLBMissF, ITLBHitF;
  logic 		    DTLBMissM, DTLBHitM;
  logic [`XLEN-1:0] 	    SATP_REGW;
  logic 		    STATUS_MXR, STATUS_SUM;
  logic [1:0] 		    PrivilegeModeW;
  logic [`XLEN-1:0] 	    PageTableEntryF, PageTableEntryM;
  logic [1:0] 		    PageTypeF, PageTypeM;

  // PMA checker signals
  logic 		    AtomicAccessM, ExecuteAccessF, WriteAccessM, ReadAccessM;
  logic 		    PMPInstrAccessFaultF, PMPLoadAccessFaultM, PMPStoreAccessFaultM;
  logic 		    PMAInstrAccessFaultF, PMALoadAccessFaultM, PMAStoreAccessFaultM;
  logic 		    DSquashBusAccessM, ISquashBusAccessF;
  logic [5:0] 		    DHSELRegionsM, IHSELRegionsF;
  var logic [`XLEN-1:0]     PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0];
  logic [63:0] 		    PMPCFG01_REGW, PMPCFG23_REGW; // signals being sent from privileged unit to pmp/pma in dmem and ifu.
  assign            HSELRegions = ExecuteAccessF ? IHSELRegionsF : DHSELRegionsM; // *** this is a pure guess on how one of these should be selected. it passes tests, but is it the right way to do this?

  // IMem stalls
  logic 		    ICacheStallF;
  logic 		    DCacheStall;
  logic [`XLEN-1:0] 	    MMUPAdr, MMUReadPTE;
  logic 		    MMUStall;
  logic 		    MMUTranslate, MMUReady;

  // bus interface to dmem
  logic 		    MemReadM, MemWriteM;
  logic [1:0] 		    AtomicMaskedM;
  logic [2:0] 		    Funct3M;
  logic [`XLEN-1:0] 	    MemAdrM, WriteDataM;
  logic [`PA_BITS-1:0] 	    MemPAdrM;
  logic [`XLEN-1:0] 	    ReadDataW;
  logic [`PA_BITS-1:0] 	    InstrPAdrF;
  logic [`XLEN-1:0] 	    InstrRData;
  logic 		    InstrReadF;
  logic 		    DataStall;
  logic 		    InstrAckF, MemAckW;
  logic 		    CommitM, CommittedM;

  logic 		    BPPredWrongE;
  logic 		    BPPredDirWrongM;
  logic 		    BTBPredPCWrongM;
  logic 		    RASPredPCWrongM;
  logic 		    BPPredClassNonCFIWrongM;

  logic [`XLEN-1:0] 	    WriteDatatmpM;

  logic [4:0] 		    InstrClassM;

  logic [`XLEN-1:0] 	    HRDATAW;

  // IEU vs HPTW arbitration signals to send to LSU
  logic 		    DisableTranslation;   
  logic [1:0] 		    MemRWMtoLSU;
  logic [2:0] 		    Funct3MtoLSU;
  logic [1:0] 		    AtomicMtoLSU;
  logic [`XLEN-1:0] 	    MemAdrMtoLSU;
  logic [`XLEN-1:0] 	    WriteDataMtoLSU;
  logic [`XLEN-1:0] 	    ReadDataWFromLSU;
  logic 		    CommittedMfromLSU;
  logic 		    SquashSCWfromLSU;
  logic 		    DataMisalignedMfromLSU;
  
  
  
  
  ifu ifu(.InstrInF(InstrRData), .*); // instruction fetch unit: PC, branch prediction, instruction cache

  ieu ieu(.*); // integer execution unit: integer register file, datapath and controller

  
  mux2  #(`XLEN)  OutputInput2mux(WriteDataM, FWriteDataM, FMemRWM[0], WriteDatatmpM);

  pagetablewalker pagetablewalker(.*); // can send addresses to ahblite, send out pagetablestall
  // *** can connect to hazard unit
  // changing from this to the line above breaks the program.  auipc at 104 fails; seems to be flushed.
  // Would need to insertinstruction as InstrD, not InstrF
  /*ahblite ebu( 
   .InstrReadF(1'b0),
   .InstrRData(), // hook up InstrF later
   .MemSizeM(Funct3M[1:0]), .UnsignedLoadM(Funct3M[2]),
   .*); */


  // arbiter between IEU and pagetablewalker
  lsuArb arbiter(// HPTW connection
		 .HPTWTranslate(MMUTranslate),
		 .HPTWPAdr(MMUPAdr),
		 .HPTWReadPTE(MMUReadPTE),
		 .HPTWReady(MMUReady),
		 // CPU connection
		 .MemRWM(MemRWM|FMemRWM),
		 .Funct3M(Funct3M),
		 .AtomicM(AtomicM),
		 .MemAdrM(MemAdrM),
		 .WriteDataM(WriteDatatmpM),
		 .ReadDataW(ReadDataW),
		 .CommittedM(CommittedM),
		 .SquashSCW(SquashSCW),
		 .DataMisalignedM(DataMisalignedM),
		 .DCacheStall(DCacheStall),
		 // LSU
		 .DisableTranslation(DisableTranslation),
		 .MemRWMtoLSU(MemRWMtoLSU),
		 .Funct3MtoLSU(Funct3MtoLSU),
		 .AtomicMtoLSU(AtomicMtoLSU),
		 .MemAdrMtoLSU(MemAdrMtoLSU),          
		 .WriteDataMtoLSU(WriteDataMtoLSU),       
		 .CommittedMfromLSU(CommittedMfromLSU),     
		 .SquashSCWfromLSU(SquashSCWfromLSU),      
		 .DataMisalignedMfromLSU(DataMisalignedMfromLSU),
		 .ReadDataWFromLSU(ReadDataWFromLSU),
		 .DataStall(DataStall),
		 .*);


  lsu lsu(.MemRWM(MemRWMtoLSU),
	  .Funct3M(Funct3MtoLSU),
	  .AtomicM(AtomicMtoLSU),
	  .MemAdrM(MemAdrMtoLSU),
	  .WriteDataM(WriteDataMtoLSU),
	  .ReadDataW(ReadDataWFromLSU),

	  .CommittedM(CommittedMfromLSU),
	  .SquashSCW(SquashSCWfromLSU),
	  .DataMisalignedM(DataMisalignedMfromLSU),
	  .DisableTranslation(DisableTranslation),

	  .DataStall(DataStall), .* ); // data cache unit

  ahblite ebu( 
	       //.InstrReadF(1'b0),
	       //.InstrRData(InstrF), // hook up InstrF later
	       .WriteDataM(WriteDatatmpM),
	       .MemSizeM(Funct3M[1:0]), .UnsignedLoadM(Funct3M[2]),
	       .Funct7M(InstrM[31:25]),
	       .HRDATAW(HRDATAW),
	       .*);

  
  muldiv mdu(.*); // multiply and divide unit
  
  hazard     hzu(.*);	// global stall and flush control

  // Priveleged block operates in M and W stages, handling CSRs and exceptions
  privileged priv(.*);
  

  fpu fpu(.*); // floating point unit
  // add FPU here, with SetFflagsM, FRM_REGW
  // presently stub out SetFlagsM and FloatRegWriteW
  //assign SetFflagsM = 0;
  //assign FloatRegWriteW = 0;
  
endmodule
