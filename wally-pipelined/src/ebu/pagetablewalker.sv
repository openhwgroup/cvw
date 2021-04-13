///////////////////////////////////////////
// pagetablewalker.sv
//
// Written: tfleming@hmc.edu 2 March 2021
// Modified: 
//
// Purpose: Page Table Walker
//          Part of the Memory Management Unit (MMU)
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
`include "wally-constants.vh"

/* ***
   TO-DO:
    - Faults have a timing issue and currently do not work.
    - Leaf state brings HADDR down to zeros (maybe fixed?)
    - Complete rv64ic case
    - Implement better accessed/dirty behavior
    - Implement read/write/execute checking (either here or in TLB)
*/

module pagetablewalker (
  // Control signals
  input  logic             HCLK, HRESETn,
  input  logic [`XLEN-1:0] SATP_REGW,

  // Signals from TLBs (addresses to translate)
  input  logic [`XLEN-1:0] PCF, MemAdrM,
  input  logic             ITLBMissF, DTLBMissM,
  input  logic [1:0]       MemRWM,

  // Outputs to the TLBs (PTEs to write)
  output logic [`XLEN-1:0] PageTableEntryF, PageTableEntryM,
  output logic [1:0]       PageTypeF, PageTypeM,
  output logic             ITLBWriteF, DTLBWriteM,

  // Signals from ahblite (PTEs from memory)
  input  logic [`XLEN-1:0] MMUReadPTE,
  input  logic             MMUReady,

  // Signals to ahblite (memory addresses to access)
  output logic [`XLEN-1:0] MMUPAdr,
  output logic             MMUTranslate,
  output logic             MMUTranslationComplete,

  // Faults
  output logic             InstrPageFaultF, LoadPageFaultM, StorePageFaultM
);

  // Internal signals
  logic                 SvMode, TLBMiss;
  logic [`PPN_BITS-1:0] BasePageTablePPN;
  logic [`XLEN-1:0]     TranslationVAdr;
  logic [`XLEN-1:0]     SavedPTE, CurrentPTE;
  logic [`PA_BITS-1:0]  TranslationPAdr;
  logic [`PPN_BITS-1:0] CurrentPPN;
  logic                 MemStore;

  // PTE Control Bits
  logic Dirty, Accessed, Global, User,
        Executable, Writable, Readable, Valid;
  // PTE descriptions
  logic ValidPTE, AccessAlert, MegapageMisaligned, BadMegapage, LeafPTE;

  // Outputs of walker
  logic [`XLEN-1:0] PageTableEntry;
  logic [1:0] PageType;

  // Signals for direct, fake translations. Not part of the final Wally version.
  logic [`XLEN-1:0]     DirectInstrPTE, DirectMemPTE;
  logic [9:0]           DirectPTEFlags = {2'b0, 8'b00001111};

  logic [`VPN_BITS-1:0] PCPageNumber, MemAdrPageNumber;

  assign BasePageTablePPN = SATP_REGW[`PPN_BITS-1:0];

  assign MemStore = MemRWM[0];

  assign PCPageNumber = PCF[`VPN_BITS+11:12];
  assign MemAdrPageNumber = MemAdrM[`VPN_BITS+11:12];

  // Create fake page table entries for direct virtual to physical translation
  generate
    if (`XLEN == 32) begin
      assign DirectInstrPTE = {PCPageNumber, DirectPTEFlags};
      assign DirectMemPTE   = {MemAdrPageNumber, DirectPTEFlags};
    end else begin
      assign DirectInstrPTE = {10'b0, PCPageNumber, DirectPTEFlags};
      assign DirectMemPTE   = {10'b0, MemAdrPageNumber, DirectPTEFlags};
    end
  endgenerate

  // Direct translation flops
  //flopenr #(`XLEN) instrpte(HCLK, ~HRESETn, ITLBMissF, DirectInstrPTE, PageTableEntryF);
  //flopenr #(`XLEN)  datapte(HCLK, ~HRESETn, DTLBMissM, DirectMemPTE, PageTableEntryM);

  //flopr #(1) iwritesignal(HCLK, ~HRESETn, ITLBMissF, ITLBWriteF);
  //flopr #(1) dwritesignal(HCLK, ~HRESETn, DTLBMissM, DTLBWriteM);

  // Prefer data address translations over instruction address translations
  assign TranslationVAdr = (DTLBMissM) ? MemAdrM : PCF;
  assign MMUTranslate = DTLBMissM || ITLBMissF;

  // unswizzle PTE bits
  assign {Dirty, Accessed, Global, User,
          Executable, Writable, Readable, Valid} = CurrentPTE[7:0];

  // Assign PTE descriptors common across all XLEN values
  assign LeafPTE = Executable | Writable | Readable;
  assign ValidPTE = Valid && ~(Writable && ~Readable);
  assign AccessAlert = ~Accessed || (MemStore && ~Dirty);

  // Assign specific outputs to general outputs
  assign PageTableEntryF = PageTableEntry;
  assign PageTableEntryM = PageTableEntry;
  assign PageTypeF = PageType;
  assign PageTypeM = PageType;

  generate
    if (`XLEN == 32) begin
      logic [9:0] VPN1, VPN0;

      assign SvMode = SATP_REGW[31];

      typedef enum {IDLE, LEVEL1, LEVEL0, LEAF, FAULT} walker_statetype;
      walker_statetype WalkerState, NextWalkerState;

      // *** Do we need a synchronizer here for walker to talk to ahblite?
      flopenl #(.TYPE(walker_statetype)) mmureg(HCLK, ~HRESETn, 1'b1, NextWalkerState, IDLE, WalkerState);

      // State transition logic
      always_comb begin
        case (WalkerState)
          IDLE:   if      (MMUTranslate)           NextWalkerState = LEVEL1;
                  else                             NextWalkerState = IDLE;
          LEVEL1: if      (~MMUReady)              NextWalkerState = LEVEL1;
                //  else if (~ValidPTE || (LeafPTE && BadMegapage))
                //                                   NextWalkerState = FAULT;
                // *** Leave megapage implementation for later
                // *** need to check if megapage valid/aligned
                  else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;
                  else if (ValidPTE && ~LeafPTE)   NextWalkerState = LEVEL0;
                  else                             NextWalkerState = FAULT;
          LEVEL0: if      (~MMUReady)              NextWalkerState = LEVEL0;
                  else if (ValidPTE && LeafPTE && ~AccessAlert)
                                                   NextWalkerState = LEAF;
                  else                             NextWalkerState = FAULT;
          LEAF:   if      (MMUTranslate)           NextWalkerState = LEVEL1;
                  else                             NextWalkerState = IDLE;
          FAULT:  if      (MMUTranslate)           NextWalkerState = LEVEL1;
                  else                             NextWalkerState = IDLE;
        endcase
      end


      // A megapage is a Level 1 leaf page. This page must have zero PPN[0].
      assign MegapageMisaligned = |(CurrentPPN[9:0]);
      assign BadMegapage = MegapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme

      assign VPN1 = TranslationVAdr[31:22];
      assign VPN0 = TranslationVAdr[21:12]; // *** could optimize by not passing offset?

      // Assign combinational outputs
      always_comb begin
        // default values
        assign TranslationPAdr = '0;
        assign PageTableEntry = '0;
        assign PageType ='0;
        assign MMUTranslationComplete = '0;
        assign DTLBWriteM = '0;
        assign ITLBWriteF = '0;
        assign InstrPageFaultF = '0;
        assign LoadPageFaultM = '0;
        assign StorePageFaultM = '0;

        case (NextWalkerState)
          LEVEL1: begin
            assign TranslationPAdr = {BasePageTablePPN, VPN1, 2'b00};
          end
          LEVEL0: begin
            assign TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
          end
          LEAF: begin
            // Keep physical address alive to prevent HADDR dropping to 0
            assign TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
            assign PageTableEntry = CurrentPTE;
            assign PageType = (WalkerState == LEVEL1) ? 2'b01 : 2'b00;
            assign MMUTranslationComplete = '1;
            assign DTLBWriteM = DTLBMissM;
            assign ITLBWriteF = ~DTLBMissM;  // Prefer data over instructions
          end
          FAULT: begin
            assign TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
            assign MMUTranslationComplete = '1;
            assign InstrPageFaultF = ~DTLBMissM;
            assign LoadPageFaultM = DTLBMissM && ~MemStore;
            assign StorePageFaultM = DTLBMissM && MemStore;
          end
        endcase
      end

      // Capture page table entry from ahblite
      flopenr #(32) ptereg(HCLK, ~HRESETn, MMUReady, MMUReadPTE, SavedPTE);
      mux2 #(32) ptemux(SavedPTE, MMUReadPTE, MMUReady, CurrentPTE);
      assign CurrentPPN = CurrentPTE[`PPN_BITS+9:10];

      // Assign outputs to ahblite
      // *** Currently truncate address to 32 bits. This must be changed if
      // we support larger physical address spaces
      assign MMUPAdr = TranslationPAdr[31:0];

    end else begin
      assign SvMode = SATP_REGW[63];

      logic [8:0] VPN2, VPN1, VPN0;

      logic GigapageMisaligned, BadGigapage;

      typedef enum {IDLE, LEVEL2, LEVEL1, LEVEL0, LEAF, FAULT} walker_statetype;
      walker_statetype WalkerState, NextWalkerState;

      // *** Do we need a synchronizer here for walker to talk to ahblite?
      flopenl #(.TYPE(walker_statetype)) mmureg(HCLK, ~HRESETn, 1'b1, NextWalkerState, IDLE, WalkerState);

      always_comb begin
        case (WalkerState)
          IDLE:   if      (MMUTranslate)           NextWalkerState = LEVEL2;
                  else                             NextWalkerState = IDLE;
          LEVEL2: if      (~MMUReady)              NextWalkerState = LEVEL2;
                  else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;
                  else if (ValidPTE && ~LeafPTE)   NextWalkerState = LEVEL1;
                  else                             NextWalkerState = FAULT;
          LEVEL1: if      (~MMUReady)              NextWalkerState = LEVEL1;
                //  else if (~ValidPTE || (LeafPTE && BadMegapage))
                //                                   NextWalkerState = FAULT;
                // *** Leave megapage implementation for later
                  else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;
                  else if (ValidPTE && ~LeafPTE)   NextWalkerState = LEVEL0;
                  else                             NextWalkerState = FAULT;
          LEVEL0: if      (~MMUReady)              NextWalkerState = LEVEL0;
                  else if (ValidPTE && LeafPTE && ~AccessAlert)
                                                   NextWalkerState = LEAF;
                  else                             NextWalkerState = FAULT;
          LEAF:   if      (MMUTranslate)           NextWalkerState = LEVEL2;
                  else                             NextWalkerState = IDLE;
          FAULT:  if      (MMUTranslate)           NextWalkerState = LEVEL2;
                  else                             NextWalkerState = IDLE;
        endcase
      end

      // A gigapage is a Level 2 leaf page. This page must have zero PPN[1] and
      // zero PPN[0]
      assign GigapageMisaligned = |(CurrentPPN[17:0]);
      // A megapage is a Level 1 leaf page. This page must have zero PPN[0].
      assign MegapageMisaligned = |(CurrentPPN[8:0]);

      assign BadGigapage = GigapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme
      assign BadMegapage = MegapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme

      assign VPN2 = TranslationVAdr[38:30];
      assign VPN1 = TranslationVAdr[29:21];
      assign VPN0 = TranslationVAdr[20:12]; // *** could optimize by not passing offset?

      // *** Should translate this flop block into our flop module notation
      always_comb begin
        // default values
        assign TranslationPAdr = '0;
        assign PageTableEntry = '0;
        assign PageType = '0;
        assign MMUTranslationComplete = '0;
        assign DTLBWriteM = '0;
        assign ITLBWriteF = '0;
        assign InstrPageFaultF = '0;
        assign LoadPageFaultM = '0;
        assign StorePageFaultM = '0;

        case (NextWalkerState)
          LEVEL2: begin
            assign TranslationPAdr = {BasePageTablePPN, VPN2, 3'b000};
          end
          LEVEL1: begin
            assign TranslationPAdr = {CurrentPPN, VPN1, 3'b000};
          end
          LEVEL0: begin
            assign TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
          end
          LEAF: begin
            // Keep physical address alive to prevent HADDR dropping to 0
            assign TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
            assign PageTableEntry = CurrentPTE;
            assign PageType = (WalkerState == LEVEL2) ? 2'b11 : 
                                ((WalkerState == LEVEL1) ? 2'b01 : 2'b00);
            assign MMUTranslationComplete = '1;
            assign DTLBWriteM = DTLBMissM;
            assign ITLBWriteF = ~DTLBMissM;  // Prefer data over instructions
          end
          FAULT: begin
            assign TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
            assign MMUTranslationComplete = '1;
            assign InstrPageFaultF = ~DTLBMissM;
            assign LoadPageFaultM = DTLBMissM && ~MemStore;
            assign StorePageFaultM = DTLBMissM && MemStore;
          end
        endcase
      end

      // Capture page table entry from ahblite
      flopenr #(`XLEN) ptereg(HCLK, ~HRESETn, MMUReady, MMUReadPTE, SavedPTE);
      mux2 #(`XLEN) ptemux(SavedPTE, MMUReadPTE, MMUReady, CurrentPTE);
      assign CurrentPPN = CurrentPTE[`PPN_BITS+9:10];

      // Assign outputs to ahblite
      // *** Currently truncate address to 32 bits. This must be changed if
      // we support larger physical address spaces
      assign MMUPAdr = TranslationPAdr[31:0];
    end
  endgenerate

endmodule