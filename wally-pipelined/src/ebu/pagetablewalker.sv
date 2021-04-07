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

module pagetablewalker (
  input  logic             clk, reset,

  input  logic [`XLEN-1:0] SATP_REGW,

  input  logic             MemWriteM,
  input  logic             ITLBMissF, DTLBMissM,
  input  logic [`XLEN-1:0] PCF, MemAdrM,

  output logic [`XLEN-1:0] PageTableEntryF, PageTableEntryM,
  output logic             ITLBWriteF, DTLBWriteM,
  // *** handshake to tlbs probably not needed, since stalls take effect
  output logic             MMUTranslationComplete,

  // Signals from and to ahblite
  input  logic [`XLEN-1:0] MMUReadPTE,
  input  logic             MMUReady,

  output logic [`XLEN-1:0] MMUPAdr,
  output logic             MMUTranslate,

  // Faults
  output logic             InstrPageFaultM, LoadPageFaultM, StorePageFaultM
);

  logic                 SvMode;
  logic [`PPN_BITS-1:0] BasePageTablePPN;
  logic [`XLEN-1:0]     DirectInstrPTE, DirectMemPTE, TranslationVAdr;

  logic [9:0] DirectPTEFlags = {2'b0, 8'b00001111};

  // rv32 temp case
  logic [`VPN_BITS-1:0] PCPageNumber;
  logic [`VPN_BITS-1:0] MemAdrPageNumber;

  assign BasePageTablePPN = SATP_REGW[`PPN_BITS-1:0];

  assign PCPageNumber = PCF[`VPN_BITS+11:12];
  assign MemAdrPageNumber = MemAdrM[`VPN_BITS+11:12];

  generate
    if (`XLEN == 32) begin
      assign DirectInstrPTE = {PCPageNumber, DirectPTEFlags};
      assign DirectMemPTE   = {MemAdrPageNumber, DirectPTEFlags};
    end else begin
      assign DirectInstrPTE = {10'b0, PCPageNumber, DirectPTEFlags};
      assign DirectMemPTE   = {10'b0, MemAdrPageNumber, DirectPTEFlags};
    end
  endgenerate

  //flopenr #(`XLEN) instrpte(clk, reset, ITLBMissF, DirectInstrPTE, PageTableEntryF);
  //flopenr #(`XLEN)  datapte(clk, reset, DTLBMissM, DirectMemPTE, PageTableEntryM);

  //flopr #(1) iwritesignal(clk, reset, ITLBMissF, ITLBWriteF);
  //flopr #(1) dwritesignal(clk, reset, DTLBMissM, DTLBWriteM);

  // Prefer data address translations over instruction address translations
  assign TranslationVAdr = (DTLBMissM) ? MemAdrM : PCF;
  assign MMUTranslate = DTLBMissM || ITLBMissF;

  generate
    if (`XLEN == 32) begin
      assign SvMode = SATP_REGW[31];

      logic [9:0] VPN1 = TranslationVAdr[31:22];
      logic [9:0] VPN0 = TranslationVAdr[21:12]; // *** could optimize by not passing offset?

      logic [33:0] TranslationPAdr;
      logic [21:0] CurrentPPN;

      logic Dirty, Accessed, Global, User,
            Executable, Writable, Readable, Valid;
      logic ValidPTE, AccessAlert, MegapageMisaligned, BadMegapage, LeafPTE;

      typedef enum {IDLE, LEVEL1, LEVEL0, LEAF, FAULT} statetype;
      statetype WalkerState, NextWalkerState;

      // *** Do we need a synchronizer here for walker to talk to ahblite?
      flopenl #(.TYPE(statetype)) mmureg(clk, reset, 1'b1, NextWalkerState, IDLE, WalkerState);

      always_comb begin
        case (WalkerState)
          IDLE:   if      (MMUTranslate)           NextWalkerState = LEVEL1;
                  else                             NextWalkerState = IDLE;
          LEVEL1: if      (~MMUReady)              NextWalkerState = LEVEL1;
                //  else if (~ValidPTE || (LeafPTE && BadMegapage))
                //                                   NextWalkerState = FAULT;
                // *** Leave megapage implementation for later
                //  else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;
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

      // unswizzle PTE bits
      assign {Dirty, Accessed, Global, User,
              Executable, Writable, Readable, Valid} = MMUReadPTE[7:0];

      // A megapage is a Level 1 leaf page. This page must have zero PPN[0].
      assign MegapageMisaligned = |(CurrentPPN[9:0]);
      assign LeafPTE = Executable | Writable | Readable;
      assign ValidPTE = Valid && ~(Writable && ~Readable);
      assign AccessAlert = ~Accessed || (MemWriteM && ~Dirty);
      assign BadMegapage = MegapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme

      // *** Should translate this flop block into our flop module notation
      always_ff @(posedge clk, negedge reset)
        if (reset) begin
          TranslationPAdr <= '0;
          PageTableEntryF <= '0;
          MMUTranslationComplete <= '0;
          DTLBWriteM <= '0;
          ITLBWriteF <= '0;
          InstrPageFaultM <= '0;
          LoadPageFaultM <= '0;
          StorePageFaultM <= '0;
        end else begin
          // default values
          TranslationPAdr <= '0;
          PageTableEntryF <= '0;
          MMUTranslationComplete <= '0;
          DTLBWriteM <= '0;
          ITLBWriteF <= '0;
          InstrPageFaultM <= '0;
          LoadPageFaultM <= '0;
          StorePageFaultM <= '0;
          case (NextWalkerState)
            LEVEL1: begin
              TranslationPAdr <= {BasePageTablePPN, VPN1, 2'b00};
            end
            LEVEL0: begin
              TranslationPAdr <= {CurrentPPN, VPN0, 2'b00};
            end
            LEAF: begin
              PageTableEntryF <= MMUReadPTE;
              PageTableEntryM <= MMUReadPTE;
              MMUTranslationComplete <= '1;
              DTLBWriteM <= DTLBMissM;
              ITLBWriteF <= ~DTLBMissM;  // Prefer data over instructions
            end
            FAULT: begin
              InstrPageFaultM <= ~DTLBMissM;
              LoadPageFaultM <= DTLBMissM && ~MemWriteM;
              StorePageFaultM <= DTLBMissM && MemWriteM;
            end
          endcase
        end

      // Interpret inputs from ahblite
      assign CurrentPPN = MMUReadPTE[31:10];

      // Assign outputs to ahblite
      // *** Currently truncate address to 32 bits. This must be changed if
      // we support larger physical address spaces
      assign MMUPAdr = TranslationPAdr[31:0];

    end else begin
      assign SvMode = SATP_REGW[63];

      logic [8:0] VPN2 = TranslationVAdr[38:30];
      logic [8:0] VPN1 = TranslationVAdr[29:21];
      logic [8:0] VPN0 = TranslationVAdr[20:12]; // *** could optimize by not passing offset?

      logic [55:0] TranslationPAdr;
      logic [43:0] CurrentPPN;

      logic Dirty, Accessed, Global, User,
            Executable, Writable, Readable, Valid;
      logic ValidPTE, AccessAlert, GigapageMisaligned, MegapageMisaligned,
            BadGigapage, BadMegapage, LeafPTE;

      typedef enum {IDLE, LEVEL2, LEVEL1, LEVEL0, LEAF, FAULT} statetype;
      statetype WalkerState, NextWalkerState;

      // *** Do we need a synchronizer here for walker to talk to ahblite?
      flopenl #(.TYPE(statetype)) mmureg(clk, reset, 1'b1, NextWalkerState, IDLE, WalkerState);

      always_comb begin
        case (WalkerState)
          IDLE:   if      (MMUTranslate)           NextWalkerState = LEVEL1;
                  else                             NextWalkerState = IDLE;
          LEVEL2: if      (~MMUReady)              NextWalkerState = LEVEL2;
                  else if (ValidPTE && ~LeafPTE)   NextWalkerState = LEVEL1;
                  else                             NextWalkerState = FAULT;
          LEVEL1: if      (~MMUReady)              NextWalkerState = LEVEL1;
                //  else if (~ValidPTE || (LeafPTE && BadMegapage))
                //                                   NextWalkerState = FAULT;
                // *** Leave megapage implementation for later
                //  else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;
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

      // unswizzle PTE bits
      assign {Dirty, Accessed, Global, User,
              Executable, Writable, Readable, Valid} = MMUReadPTE[7:0];

      // A megapage is a Level 1 leaf page. This page must have zero PPN[0].
      assign GigapageMisaligned = |(CurrentPPN[17:0]);
      assign MegapageMisaligned = |(CurrentPPN[8:0]);
      assign LeafPTE = Executable | Writable | Readable;
      assign ValidPTE = Valid && ~(Writable && ~Readable);
      assign AccessAlert = ~Accessed || (MemWriteM && ~Dirty);
      assign BadGigapage = GigapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme
      assign BadMegapage = MegapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme

      // *** Should translate this flop block into our flop module notation
      always_ff @(posedge clk, negedge reset)
        if (reset) begin
          TranslationPAdr <= '0;
          PageTableEntryF <= '0;
          MMUTranslationComplete <= '0;
          DTLBWriteM <= '0;
          ITLBWriteF <= '0;
          InstrPageFaultM <= '0;
          LoadPageFaultM <= '0;
          StorePageFaultM <= '0;
        end else begin
          // default values
          TranslationPAdr <= '0;
          PageTableEntryF <= '0;
          MMUTranslationComplete <= '0;
          DTLBWriteM <= '0;
          ITLBWriteF <= '0;
          InstrPageFaultM <= '0;
          LoadPageFaultM <= '0;
          StorePageFaultM <= '0;
          case (NextWalkerState)
            LEVEL2: begin
              TranslationPAdr <= {BasePageTablePPN, VPN2, 3'b00};
            end
            LEVEL1: begin
              TranslationPAdr <= {CurrentPPN, VPN1, 3'b00};
            end
            LEVEL0: begin
              TranslationPAdr <= {CurrentPPN, VPN0, 3'b00};
            end
            LEAF: begin
              PageTableEntryF <= MMUReadPTE;
              PageTableEntryM <= MMUReadPTE;
              MMUTranslationComplete <= '1;
              DTLBWriteM <= DTLBMissM;
              ITLBWriteF <= ~DTLBMissM;  // Prefer data over instructions
            end
            FAULT: begin
              InstrPageFaultM <= ~DTLBMissM;
              LoadPageFaultM <= DTLBMissM && ~MemWriteM;
              StorePageFaultM <= DTLBMissM && MemWriteM;
            end
          endcase
        end

      // Interpret inputs from ahblite
      assign CurrentPPN = MMUReadPTE[53:10];

      // Assign outputs to ahblite
      // *** Currently truncate address to 32 bits. This must be changed if
      // we support larger physical address spaces
      assign MMUPAdr = TranslationPAdr[31:0];
    end
  endgenerate

endmodule