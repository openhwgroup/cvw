///////////////////////////////////////////
// hptw.sv
//
// Written: tfleming@hmc.edu 2 March 2021
// Modified:  david_harris@hmc.edu 18 July 2021 cleanup and simplification
//            kmacsaigoren@hmc.edu 1 June 2021
//            implemented SV48 on top of SV39. This included, adding a level of the FSM for the extra page number segment
//            adding support for terapage encoding, and for setting the HPTWAdr using the new level,
//            adding the internal SvMode signal
//
// Purpose: Hardware Page Table Walker
//
// Documentation: RISC-V System on Chip Design Chapter 8
//
// A component of the CORE-V-WALLY configurable RISC-V project.
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

module hptw import cvw::*;  #(parameter cvw_t P) (
  input  logic              clk, reset,
  input  logic [P.XLEN-1:0] SATP_REGW,              // includes SATP.MODE to determine number of levels in page table
  input  logic [P.XLEN-1:0] PCSpillF,               // addresses to translate
  input  logic [P.XLEN+1:0] IEUAdrExtM,             // addresses to translate
  input  logic [1:0]        MemRWM, AtomicM,
  // system status
  input  logic              STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input  logic [1:0]        STATUS_MPP,
  input  logic [1:0]        PrivilegeModeW,
  input  logic [P.XLEN-1:0] ReadDataM,              // page table entry from LSU 
  input  logic [P.XLEN-1:0] WriteDataM,
  input  logic              DCacheStallM,           // stall from LSU
  input  logic [2:0]        Funct3M,
  input  logic [6:0]        Funct7M,
  input  logic              ITLBMissF,
  input  logic              DTLBMissM,
  input  logic              FlushW,
  input  logic              InstrUpdateDAF,
  input  logic              DataUpdateDAM,
  output logic [P.XLEN-1:0] PTE,                    // page table entry to TLBs
  output logic [1:0]        PageType,               // page type to TLBs
  output logic              ITLBWriteF, DTLBWriteM, // write TLB with new entry
  output logic [1:0]        PreLSURWM,
  output logic [P.XLEN+1:0] IHAdrM,
  output logic [P.XLEN-1:0] IHWriteDataM,
  output logic [1:0]        LSUAtomicM,
  output logic [2:0]        LSUFunct3M,
  output logic [6:0]        LSUFunct7M,
  output logic              IgnoreRequestTLB,
  output logic              SelHPTW,
  output logic              HPTWStall,
  input  logic              LSULoadAccessFaultM, LSUStoreAmoAccessFaultM, 
  output logic              LoadAccessFaultM, StoreAmoAccessFaultM, HPTWInstrAccessFaultF
);

  typedef enum logic [3:0] {L0_ADR, L0_RD, 
          L1_ADR, L1_RD, 
          L2_ADR, L2_RD, 
          L3_ADR, L3_RD, 
          LEAF, IDLE, UPDATE_PTE,
          FAULT} statetype;

  logic                     DTLBWalk; // register TLBs translation miss requests
  logic [P.PPN_BITS-1:0]    BasePageTablePPN;
  logic [P.PPN_BITS-1:0]    CurrentPPN;
  logic                     Executable, Writable, Readable, Valid, PTE_U;
  logic                     Misaligned, MegapageMisaligned;
  logic                     ValidPTE, LeafPTE, ValidLeafPTE, ValidNonLeafPTE;
  logic                     StartWalk;
  logic                     TLBMiss;
  logic                     PRegEn;
  logic [1:0]               NextPageType;
  logic [P.SVMODE_BITS-1:0] SvMode;
  logic [P.XLEN-1:0]        TranslationVAdr;
  logic [P.XLEN-1:0]        NextPTE;
  logic                     UpdatePTE;
  logic                     HPTWUpdateDA;
  logic [P.PA_BITS-1:0]     HPTWReadAdr;
  logic                     SelHPTWAdr;
  logic [P.XLEN+1:0]        HPTWAdrExt;
  logic                     ITLBMissOrUpdateDAF;
  logic                     DTLBMissOrUpdateDAM;
  logic                     LSUAccessFaultM;
  logic [P.PA_BITS-1:0]     HPTWAdr;
  logic [1:0]               HPTWRW;
  logic [2:0]               HPTWSize; // 32 or 64 bit access
  statetype                 WalkerState, NextWalkerState, InitialWalkerState;
  logic                     HPTWLoadAccessFault, HPTWStoreAmoAccessFault, HPTWInstrAccessFault;
  logic                     HPTWLoadAccessFaultDelay, HPTWStoreAmoAccessFaultDelay, HPTWInstrAccessFaultDelay;
  logic                     HPTWAccessFaultDelay;
  logic                     TakeHPTWFault, TakeHPTWFaultDelay;

  // map hptw access faults onto either the original LSU load/store fault or instruction access fault
  assign LSUAccessFaultM         = LSULoadAccessFaultM | LSUStoreAmoAccessFaultM;
  assign HPTWLoadAccessFault     = LSUAccessFaultM & DTLBWalk & MemRWM[1] & ~MemRWM[0];
  assign HPTWStoreAmoAccessFault = LSUAccessFaultM & DTLBWalk & MemRWM[0];
  assign HPTWInstrAccessFault    = LSUAccessFaultM & ~DTLBWalk;

  flopr #(4) HPTWAccesFaultReg(clk, reset, {TakeHPTWFault, HPTWLoadAccessFault, HPTWStoreAmoAccessFault, HPTWInstrAccessFault},
                               {TakeHPTWFaultDelay, HPTWLoadAccessFaultDelay, HPTWStoreAmoAccessFaultDelay, HPTWInstrAccessFaultDelay});

  assign TakeHPTWFault = WalkerState != IDLE;
  
  assign LoadAccessFaultM      = TakeHPTWFaultDelay ? HPTWLoadAccessFaultDelay : LSULoadAccessFaultM;
  assign StoreAmoAccessFaultM  = TakeHPTWFaultDelay ? HPTWStoreAmoAccessFaultDelay : LSUStoreAmoAccessFaultM;
  assign HPTWInstrAccessFaultF = TakeHPTWFaultDelay ? HPTWInstrAccessFaultDelay : 1'b0;

  // Extract bits from CSRs and inputs
  assign SvMode = SATP_REGW[P.XLEN-1:P.XLEN-P.SVMODE_BITS];
  assign BasePageTablePPN = SATP_REGW[P.PPN_BITS-1:0];
  assign TLBMiss = (DTLBMissOrUpdateDAM | ITLBMissOrUpdateDAF);

  // Determine which address to translate
  mux2 #(P.XLEN) vadrmux(PCSpillF, IEUAdrExtM[P.XLEN-1:0], DTLBWalk, TranslationVAdr);
  assign CurrentPPN = PTE[P.PPN_BITS+9:10];

  // State flops
  flopenr #(1) TLBMissMReg(clk, reset, StartWalk, DTLBMissOrUpdateDAM, DTLBWalk); // when walk begins, record whether it was for DTLB (or record 0 for ITLB)
  assign PRegEn = HPTWRW[1] & ~DCacheStallM | UpdatePTE;
  flopenr #(P.XLEN) PTEReg(clk, reset, PRegEn, NextPTE, PTE); // Capture page table entry from data cache

  // Assign PTE descriptors common across all XLEN values
  // For non-leaf PTEs, D, A, U bits are reserved and ignored.  They do not cause faults while walking the page table
  assign {PTE_U, Executable, Writable, Readable, Valid} = PTE[4:0];
  assign LeafPTE = Executable | Writable | Readable; 
  assign ValidPTE = Valid & ~(Writable & ~Readable);
  assign ValidLeafPTE = ValidPTE & LeafPTE;
  assign ValidNonLeafPTE = ValidPTE & ~LeafPTE;

  if(P.SVADU_SUPPORTED) begin : hptwwrites
    logic                 ReadAccess, WriteAccess;
    logic                 InvalidRead, InvalidWrite, InvalidOp;
    logic                 UpperBitsUnequal, UpperBitsUnequalD; 
    logic                 OtherPageFault;
    logic [1:0]           EffectivePrivilegeMode;
    logic                 ImproperPrivilege;
    logic                 SaveHPTWAdr, SelHPTWWriteAdr;
    logic [P.PA_BITS-1:0] HPTWWriteAdr;  
    logic                 SetDirty;
    logic                 Dirty, Accessed;
    logic [P.XLEN-1:0]    AccessedPTE;

    assign AccessedPTE = {PTE[P.XLEN-1:8], (SetDirty | PTE[7]), 1'b1, PTE[5:0]}; // set accessed bit, conditionally set dirty bit
    mux2 #(P.XLEN) NextPTEMux(ReadDataM, AccessedPTE, UpdatePTE, NextPTE);
    flopenr #(P.PA_BITS) HPTWAdrWriteReg(clk, reset, SaveHPTWAdr, HPTWReadAdr, HPTWWriteAdr);
  
    assign SaveHPTWAdr = WalkerState == L0_ADR;
    assign SelHPTWWriteAdr = UpdatePTE | HPTWRW[0];
    mux2 #(P.PA_BITS) HPTWWriteAdrMux(HPTWReadAdr, HPTWWriteAdr, SelHPTWWriteAdr, HPTWAdr); 

    assign {Dirty, Accessed} = PTE[7:6];
    assign WriteAccess = MemRWM[0]; // implies | (|AtomicM);
    assign SetDirty = ~Dirty & DTLBWalk & WriteAccess;
    assign ReadAccess = MemRWM[1];

    assign EffectivePrivilegeMode = DTLBWalk ? (STATUS_MPRV ? STATUS_MPP : PrivilegeModeW) : PrivilegeModeW; // DTLB uses MPP mode when MPRV is 1
    assign ImproperPrivilege = ((EffectivePrivilegeMode == P.U_MODE) & ~PTE_U) |
                               ((EffectivePrivilegeMode == P.S_MODE) & PTE_U & (~STATUS_SUM & DTLBWalk));

    // Check for page faults
    vm64check #(P) vm64check(.SATP_MODE(SATP_REGW[P.XLEN-1:P.XLEN-P.SVMODE_BITS]), .VAdr(TranslationVAdr), 
      .SV39Mode(), .UpperBitsUnequal);
    // This register is not functionally necessary, but improves the critical path.
    flopr #(1) upperbitsunequalreg(clk, reset, UpperBitsUnequal, UpperBitsUnequalD);
    assign InvalidRead = ReadAccess & ~Readable & (~STATUS_MXR | ~Executable);
    assign InvalidWrite = WriteAccess & ~Writable;
    assign InvalidOp = DTLBWalk ? (InvalidRead | InvalidWrite) : ~Executable;
    assign OtherPageFault = ImproperPrivilege | InvalidOp | UpperBitsUnequalD | Misaligned | ~Valid;

    // hptw needs to know if there is a Dirty or Access fault occuring on this
    // memory access.  If there is the PTE needs to be updated seting Access
    // and possibly also Dirty.  Dirty is set if the operation is a store/amo.
    // However any other fault should not cause the update.
    assign HPTWUpdateDA = ValidLeafPTE & (~Accessed | SetDirty) & ~OtherPageFault;

    assign HPTWRW[0] = (WalkerState == UPDATE_PTE);
    assign UpdatePTE = (WalkerState == LEAF) & HPTWUpdateDA;
  end else begin // block: hptwwrites
    assign NextPTE = ReadDataM;
    assign HPTWAdr = HPTWReadAdr;
    assign HPTWUpdateDA = '0;
    assign UpdatePTE = '0;
    assign HPTWRW[0] = '0;
  end

  // Enable and select signals based on states
  assign StartWalk  = (WalkerState == IDLE) & TLBMiss;
  assign HPTWRW[1]  = (WalkerState == L3_RD) | (WalkerState == L2_RD) | (WalkerState == L1_RD) | (WalkerState == L0_RD);
  assign DTLBWriteM = (WalkerState == LEAF & ~HPTWUpdateDA) & DTLBWalk;
  assign ITLBWriteF = (WalkerState == LEAF & ~HPTWUpdateDA) & ~DTLBWalk;
  
  // FSM to track PageType based on the levels of the page table traversed
  flopr #(2) PageTypeReg(clk, reset, NextPageType, PageType);
  always_comb 
    case (WalkerState)
      L3_RD:  NextPageType = 2'b11; // terapage
      L2_RD:  NextPageType = 2'b10; // gigapage
      L1_RD:  NextPageType = 2'b01; // megapage
      L0_RD:  NextPageType = 2'b00; // kilopage
      default: NextPageType = PageType;
    endcase

  // HPTWAdr muxing
  if (P.XLEN==32) begin // RV32
    logic [9:0] VPN;
    logic [P.PPN_BITS-1:0] PPN;
    assign VPN = ((WalkerState == L1_ADR) | (WalkerState == L1_RD)) ? TranslationVAdr[31:22] : TranslationVAdr[21:12]; // select VPN field based on HPTW state
    assign PPN = ((WalkerState == L1_ADR) | (WalkerState == L1_RD)) ? BasePageTablePPN : CurrentPPN; 
    assign HPTWReadAdr = {PPN, VPN, 2'b00};
    assign HPTWSize = 3'b010;
  end else begin // RV64
    logic [8:0] VPN;
    logic [P.PPN_BITS-1:0] PPN;
    always_comb
      case (WalkerState) // select VPN field based on HPTW state
        L3_ADR, L3_RD:  VPN = TranslationVAdr[47:39];
        L2_ADR, L2_RD:  VPN = TranslationVAdr[38:30];
        L1_ADR, L1_RD:   VPN = TranslationVAdr[29:21];
        default:    VPN = TranslationVAdr[20:12];
      endcase
    assign PPN = ((WalkerState == L3_ADR) | (WalkerState == L3_RD) | 
            (SvMode != P.SV48 & ((WalkerState == L2_ADR) | (WalkerState == L2_RD)))) ? BasePageTablePPN : CurrentPPN;
    assign HPTWReadAdr = {PPN, VPN, 3'b000};
    assign HPTWSize = 3'b011;
  end

  // Initial state and misalignment for RV32/64
  if (P.XLEN == 32) begin
    assign InitialWalkerState = L1_ADR;
    assign MegapageMisaligned = |(CurrentPPN[9:0]); // must have zero PPN0
    assign Misaligned = ((WalkerState == L0_ADR) & MegapageMisaligned);
  end else begin
    logic  GigapageMisaligned, TerapageMisaligned;
    assign InitialWalkerState = (SvMode == P.SV48) ? L3_ADR : L2_ADR;
    assign TerapageMisaligned = |(CurrentPPN[26:0]); // must have zero PPN2, PPN1, PPN0
    assign GigapageMisaligned = |(CurrentPPN[17:0]); // must have zero PPN1 and PPN0
    assign MegapageMisaligned = |(CurrentPPN[8:0]); // must have zero PPN0      
    assign Misaligned = ((WalkerState == L2_ADR) & TerapageMisaligned) | ((WalkerState == L1_ADR) & GigapageMisaligned) | ((WalkerState == L0_ADR) & MegapageMisaligned);
  end

  // Page Table Walker FSM
  // there is a bug here.  Each memory access needs to be potentially flushed if the PMA/P checkers
  // generate an access fault.  Specially the store on UDPATE_PTE needs to check for access violation.
  // I think the solution is to do 1 of the following
  // 1. Allow the HPTW to generate exceptions and stop walking immediately.
  // 2. If the store would generate an exception don't store to dcache but still write the TLB.  When we go back
  // to LEAF then the PMA/P.  Wait this does not work.  The PMA/P won't be looking a the address in the table, but
  // rather than physical address of the translated instruction/data.  So we must generate the exception.
  flopenl #(.TYPE(statetype)) WalkerStateReg(clk, reset | FlushW, 1'b1, NextWalkerState, IDLE, WalkerState); 
  always_comb 
    case (WalkerState)
      IDLE:       if (TLBMiss & ~DCacheStallM)                        NextWalkerState = InitialWalkerState;
                  else                                                NextWalkerState = IDLE;
      L3_ADR:                                                         NextWalkerState = L3_RD; // first access in SV48
      L3_RD:      if (DCacheStallM)                                   NextWalkerState = L3_RD;
                  else if(LSUAccessFaultM)                            NextWalkerState = FAULT;
                  else                                                NextWalkerState = L2_ADR;
      L2_ADR:     if (InitialWalkerState == L2_ADR | ValidNonLeafPTE) NextWalkerState = L2_RD; // first access in SV39
                  else                                                NextWalkerState = LEAF;
      L2_RD:      if (DCacheStallM)                                   NextWalkerState = L2_RD;
                  else if(LSUAccessFaultM)                            NextWalkerState = FAULT;
                  else                                                NextWalkerState = L1_ADR;
      L1_ADR:     if (InitialWalkerState == L1_ADR | ValidNonLeafPTE) NextWalkerState = L1_RD; // first access in SV32
                  else                                                NextWalkerState = LEAF;  
      L1_RD:      if (DCacheStallM)                                   NextWalkerState = L1_RD;
                  else if(LSUAccessFaultM)                            NextWalkerState = FAULT;
                  else                                                NextWalkerState = L0_ADR;
      L0_ADR:     if (ValidNonLeafPTE)                                NextWalkerState = L0_RD;
                  else                                                NextWalkerState = LEAF;
      L0_RD:      if (DCacheStallM)                                   NextWalkerState = L0_RD;
                  else if(LSUAccessFaultM)                            NextWalkerState = FAULT;
                  else                                                NextWalkerState = LEAF;
      LEAF:       if (P.SVADU_SUPPORTED & HPTWUpdateDA)               NextWalkerState = UPDATE_PTE;
                  else                                                NextWalkerState = IDLE;
      UPDATE_PTE: if(DCacheStallM)                                    NextWalkerState = UPDATE_PTE;
                  else                                                NextWalkerState = LEAF;
      FAULT:                                                          NextWalkerState = IDLE;
      default:                                                        NextWalkerState = IDLE; // should never be reached
    endcase // case (WalkerState)

  assign IgnoreRequestTLB = (WalkerState == IDLE & TLBMiss) | (LSUAccessFaultM); // RT : 05 April 2023 if hptw request has pmp/a fault suppress bus access.
  assign SelHPTW = WalkerState != IDLE;

  // RT 30 May 2023: When there is an access fault caused by the hptw itself, the fsm jumps to FAULT, removes
  // stall and asserts one of HPTWLoadAccessFault, HPTWStoreAmoAccessFault or HPTWInstrAccessFaultDelay.
  // The FSM directly transistions to IDLE to ready for the next operation when the delayed version will not be high.

  assign HPTWAccessFaultDelay = HPTWLoadAccessFaultDelay | HPTWStoreAmoAccessFaultDelay | HPTWInstrAccessFaultDelay;
  assign HPTWStall = (WalkerState != IDLE & WalkerState != FAULT) | (WalkerState == IDLE & TLBMiss);

  assign ITLBMissOrUpdateDAF = ITLBMissF | (P.SVADU_SUPPORTED & InstrUpdateDAF);
  assign DTLBMissOrUpdateDAM = DTLBMissM | (P.SVADU_SUPPORTED & DataUpdateDAM);  

  // HTPW address/data/control muxing

  // Once the walk is done and it is time to update the TLB we need to switch back 
  // to the orignal data virtual address.
  assign SelHPTWAdr = SelHPTW & ~(DTLBWriteM | ITLBWriteF);
  // always block interrupts when using the hardware page table walker.

  // multiplex the outputs to LSU
  if(P.XLEN == 64) assign HPTWAdrExt = {{(P.XLEN+2-P.PA_BITS){1'b0}}, HPTWAdr}; // extend to 66 bits
  else             assign HPTWAdrExt = HPTWAdr;
  mux2 #(2) rwmux(MemRWM, HPTWRW, SelHPTW, PreLSURWM);
  mux2 #(3) sizemux(Funct3M, HPTWSize, SelHPTW, LSUFunct3M);
  mux2 #(7) funct7mux(Funct7M, 7'b0, SelHPTW, LSUFunct7M);    
  mux2 #(2) atomicmux(AtomicM, 2'b00, SelHPTW, LSUAtomicM);
  mux2 #(P.XLEN+2) lsupadrmux(IEUAdrExtM, HPTWAdrExt, SelHPTWAdr, IHAdrM);
  if(P.SVADU_SUPPORTED)
    mux2 #(P.XLEN) lsuwritedatamux(WriteDataM, PTE, SelHPTW, IHWriteDataM);
  else assign IHWriteDataM = WriteDataM;

endmodule

// another idea.  We keep gating the control by ~FlushW, but this adds considerable length to the critical path.
// should we do this differently?  For example TLBMiss is gated by ~FlushW and then drives HPTWStall, which drives LSUStallM, which drives
// the hazard unit to issue stall and flush controlls. ~FlushW already suppresses these in the hazard unit.
