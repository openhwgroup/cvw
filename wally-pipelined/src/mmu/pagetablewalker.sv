///////////////////////////////////////////
// pagetablewalker.sv
//
// Written: tfleming@hmc.edu 2 March 2021
// Modified: kmacsaigoren@hmc.edu 1 June 2021
//            implemented SV48 on top of SV39. This included, adding a level of the FSM for the extra page number segment
//            adding support for terapage encoding, and for setting the TranslationPAdr using the new level,
//            adding the internal SvMode signal
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

/* ***
   TO-DO:
    - Implement faults on accessed/dirty behavior
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

  // Stall signal
  output logic             MMUStall,

  // Faults
  output logic             WalkerInstrPageFaultF,
  output logic             WalkerLoadPageFaultM, 
  output logic             WalkerStorePageFaultM
);

  // Internal signals
  logic [`PPN_BITS-1:0] BasePageTablePPN;
  logic [`XLEN-1:0]     TranslationVAdr;
  logic [`XLEN-1:0]     SavedPTE, CurrentPTE;
  logic [`PA_BITS-1:0]  TranslationPAdr;
  logic [`PPN_BITS-1:0] CurrentPPN;
  logic [`SVMODE_BITS-1:0]  SvMode;
  logic                 MemStore;

  // PTE Control Bits
  logic Dirty, Accessed, Global, User,
        Executable, Writable, Readable, Valid;
  // PTE descriptions
  logic ValidPTE, AccessAlert, MegapageMisaligned, BadMegapage, LeafPTE;

  // Outputs of walker
  logic [`XLEN-1:0] PageTableEntry;
  logic [1:0] PageType;

  assign SvMode = SATP_REGW[`XLEN-1:`XLEN-`SVMODE_BITS];

  assign BasePageTablePPN = SATP_REGW[`PPN_BITS-1:0];

  assign MemStore = MemRWM[0];

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

  localparam LEVEL0 = 3'h0;
  localparam LEVEL1 = 3'h1;
  // space left for more levels
  localparam LEAF = 3'h5;
  localparam IDLE = 3'h6;
  localparam FAULT = 3'h7;

  logic [2:0] WalkerState, NextWalkerState;

  generate
    if (`XLEN == 32) begin
      logic [9:0] VPN1, VPN0;

      flopenl #(3) mmureg(HCLK, ~HRESETn, 1'b1, NextWalkerState, IDLE, WalkerState);

      // State transition logic
      always_comb begin
        case (WalkerState)
          IDLE:   if      (MMUTranslate)           NextWalkerState = LEVEL1;
                  else                             NextWalkerState = IDLE;
          LEVEL1: if      (~MMUReady)              NextWalkerState = LEVEL1;
                  // *** <FUTURE WORK> According to the architecture, we should
                  // fault upon finding a superpage that is misaligned or has 0
                  // access bit. The following commented line of code is
                  // supposed to perform that check. However, it is untested.
                  else if (ValidPTE && LeafPTE && ~BadMegapage) NextWalkerState = LEAF;
                  // else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;  // *** Once the above line is properly tested, delete this line.
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
          // Default case should never happen, but is included for linter.
          default:                                 NextWalkerState = IDLE;
        endcase
      end

      // A megapage is a Level 1 leaf page. This page must have zero PPN[0].
      assign MegapageMisaligned = |(CurrentPPN[9:0]);
      assign BadMegapage = MegapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme

      assign VPN1 = TranslationVAdr[31:22];
      assign VPN0 = TranslationVAdr[21:12];

      // Assign combinational outputs
      always_comb begin
        // default values
        TranslationPAdr = '0;
        PageTableEntry = '0;
        PageType ='0;
        DTLBWriteM = '0;
        ITLBWriteF = '0;
        WalkerInstrPageFaultF = '0;
        WalkerLoadPageFaultM = '0;
        WalkerStorePageFaultM = '0;
        MMUStall = '1;

        case (NextWalkerState)
          IDLE: begin
            MMUStall = '0;
          end
          LEVEL1: begin
            TranslationPAdr = {BasePageTablePPN, VPN1, 2'b00};
          end
          LEVEL0: begin
            TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
          end
          LEAF: begin
            // Keep physical address alive to prevent HADDR dropping to 0
            TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
            PageTableEntry = CurrentPTE;
            PageType = (WalkerState == LEVEL1) ? 2'b01 : 2'b00;
            DTLBWriteM = DTLBMissM;
            ITLBWriteF = ~DTLBMissM;  // Prefer data over instructions
          end
          FAULT: begin
            TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
            WalkerInstrPageFaultF = ~DTLBMissM;
            WalkerLoadPageFaultM = DTLBMissM && ~MemStore;
            WalkerStorePageFaultM = DTLBMissM && MemStore;
            MMUStall = '0;  // Drop the stall early to enter trap handling code
          end
          default: begin
            // nothing
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
      localparam LEVEL2 = 3'h2;
      localparam LEVEL3 = 3'h3;

      logic [8:0] VPN3, VPN2, VPN1, VPN0;

      logic TerapageMisaligned, GigapageMisaligned, BadTerapage, BadGigapage;

      flopenl #(3) mmureg(HCLK, ~HRESETn, 1'b1, NextWalkerState, IDLE, WalkerState);

      always_comb begin
        case (WalkerState)
          IDLE:   if      (MMUTranslate)           NextWalkerState = LEVEL3;
                  else                             NextWalkerState = IDLE;
          LEVEL3: if      (SvMode != `SV48)         NextWalkerState = LEVEL2;
                  // 3rd level used if SV48 is enabled.
                  else begin
                    if      (~MMUReady)              NextWalkerState = LEVEL3;
                    // *** <FUTURE WORK> According to the architecture, we should
                    // fault upon finding a superpage that is misaligned or has 0
                    // access bit. The following commented line of code is
                    // supposed to perform that check. However, it is untested.
                    else if (ValidPTE && LeafPTE && ~BadTerapage) NextWalkerState = LEAF;
                    // else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;  // *** Once the above line is properly tested, delete this line.
                    else if (ValidPTE && ~LeafPTE)   NextWalkerState = LEVEL2;
                    else                             NextWalkerState = FAULT;
                  end
          LEVEL2: if      (~MMUReady)              NextWalkerState = LEVEL2;
                  // *** <FUTURE WORK> According to the architecture, we should
                  // fault upon finding a superpage that is misaligned or has 0
                  // access bit. The following commented line of code is
                  // supposed to perform that check. However, it is untested.
                  else if (ValidPTE && LeafPTE && ~BadGigapage) NextWalkerState = LEAF;
                  // else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;  // *** Once the above line is properly tested, delete this line.
                  else if (ValidPTE && ~LeafPTE)   NextWalkerState = LEVEL1;
                  else                             NextWalkerState = FAULT;
          LEVEL1: if      (~MMUReady)              NextWalkerState = LEVEL1;
                  // *** <FUTURE WORK> According to the architecture, we should
                  // fault upon finding a superpage that is misaligned or has 0
                  // access bit. The following commented line of code is
                  // supposed to perform that check. However, it is untested.
                  else if (ValidPTE && LeafPTE && ~BadMegapage) NextWalkerState = LEAF;
                  // else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;  // *** Once the above line is properly tested, delete this line.
                  else if (ValidPTE && ~LeafPTE)   NextWalkerState = LEVEL0;
                  else                             NextWalkerState = FAULT;
          LEVEL0: if      (~MMUReady)              NextWalkerState = LEVEL0;
                  else if (ValidPTE && LeafPTE && ~AccessAlert)
                                                   NextWalkerState = LEAF;
                  else                             NextWalkerState = FAULT;
          LEAF:   if      (MMUTranslate)           NextWalkerState = LEVEL3;
                  else                             NextWalkerState = IDLE;
          FAULT:  if      (MMUTranslate)           NextWalkerState = LEVEL3;
                  else                             NextWalkerState = IDLE;
          // Default case should never happen, but is included for linter.
          default:                                 NextWalkerState = IDLE;
        endcase
      end

      // A terapage is a level 3 leaf page. This page must have zero PPN[2],
      // zero PPN[1], and zero PPN[0]
      assign TerapageMisaligned = |(CurrentPPN[26:0]);
      // A gigapage is a Level 2 leaf page. This page must have zero PPN[1] and
      // zero PPN[0]
      assign GigapageMisaligned = |(CurrentPPN[17:0]);
      // A megapage is a Level 1 leaf page. This page must have zero PPN[0].
      assign MegapageMisaligned = |(CurrentPPN[8:0]);

      assign BadTerapage = TerapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme
      assign BadGigapage = GigapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme
      assign BadMegapage = MegapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme

      assign VPN3 = TranslationVAdr[47:39];
      assign VPN2 = TranslationVAdr[38:30];
      assign VPN1 = TranslationVAdr[29:21];
      assign VPN0 = TranslationVAdr[20:12];

      always_comb begin
        // default values
        TranslationPAdr = '0;
        PageTableEntry = '0;
        PageType = '0;
        DTLBWriteM = '0;
        ITLBWriteF = '0;
        WalkerInstrPageFaultF = '0;
        WalkerLoadPageFaultM = '0;
        WalkerStorePageFaultM = '0;

        // The MMU defaults to stalling the processor 
        MMUStall = '1;

        case (NextWalkerState)
          IDLE: begin
            MMUStall = '0;
          end
          LEVEL3: begin
            TranslationPAdr = {BasePageTablePPN, VPN3, 3'b000};
            // *** this is a huge breaking point. if we're going through level3 every time, even when sv48 is off,
            // what should translationPAdr be when level3 is just off?
          end
          LEVEL2: begin
            TranslationPAdr = {(SvMode == `SV48) ? CurrentPPN : BasePageTablePPN, VPN2, 3'b000};
          end
          LEVEL1: begin
            TranslationPAdr = {CurrentPPN, VPN1, 3'b000};
          end
          LEVEL0: begin
            TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
          end
          LEAF: begin
            // Keep physical address alive to prevent HADDR dropping to 0
            TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
            PageTableEntry = CurrentPTE;
            PageType = (WalkerState == LEVEL3) ? 2'b11 :
                                ((WalkerState == LEVEL2) ? 2'b10 : 
                                ((WalkerState == LEVEL1) ? 2'b01 : 2'b00));
            DTLBWriteM = DTLBMissM;
            ITLBWriteF = ~DTLBMissM;  // Prefer data over instructions
          end
          FAULT: begin
            // Keep physical address alive to prevent HADDR dropping to 0
            TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
            WalkerInstrPageFaultF = ~DTLBMissM;
            WalkerLoadPageFaultM = DTLBMissM && ~MemStore;
            WalkerStorePageFaultM = DTLBMissM && MemStore;
            MMUStall = '0;  // Drop the stall early to enter trap handling code
          end
          default: begin
            // nothing
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
      assign MMUPAdr = {{(`XLEN-32){1'b0}}, TranslationPAdr[31:0]};
    end
  endgenerate

endmodule
