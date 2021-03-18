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

  input  logic             ITLBMissF, DTLBMissM,
  input  logic [`XLEN-1:0] PCF, MemAdrM,

  output logic [`XLEN-1:0] PageTableEntryF, PageTableEntryM,
  output logic             ITLBWriteF, DTLBWriteM,
  // *** handshake to tlbs probably not needed, since stalls take effect
  // output logic             TranslationComplete

  // Signals from and to ahblite
  input  logic [`XLEN-1:0] MMUReadPTE,
  input  logic             MMUReady,

  output logic [`XLEN-1:0] MMUPAdr,
  output logic             MMUTranslate
);

  logic                 SvMode;
  logic [`PPN_BITS-1:0] BasePageTablePPN;
  logic [`XLEN-1:0]     DirectInstrPTE, DirectMemPTE;

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

  flopenr #(`XLEN) instrpte(clk, reset, ITLBMissF, DirectInstrPTE, PageTableEntryF);
  flopenr #(`XLEN)  datapte(clk, reset, DTLBMissM, DirectMemPTE, PageTableEntryM);

  flopr #(1) iwritesignal(clk, reset, ITLBMissF, ITLBWriteF);
  flopr #(1) dwritesignal(clk, reset, DTLBMissM, DTLBWriteM);

/*
  generate
    if (`XLEN == 32) begin
      assign SvMode = SATP_REGW[31];

      logic VPN1 [9:0] = TranslationVAdr[31:22];
      logic VPN0 [9:0] = TranslationVAdr[21:12]; // *** could optimize by not passing offset?

      logic TranslationPAdr [33:0];

      typedef enum {IDLE, DATA_LEVEL1, DATA_LEVEL0, DATA_LEAF, DATA FAULT} statetype;
      statetype WalkerState, NextWalkerState;

      always_ff @(posedge HCLK, negedge HRESETn)
        if (~HRESETn) WalkerState <= #1 IDLE;
        else          WalkerState <= #1 NextWalkerState;

      always_comb begin
        NextWalkerState = 'X;
        case (WalkerState)
          IDLE:   if      (TLBMissM)             NextWalkerState = LEVEL1;
                  else                           NextWalkerState = IDLE;
          LEVEL1: if      (HREADY && ValidEntry) NextWalkerState = LEVEL0;
                  else if (HREADY)               NextWalkerState = FAULT;
                  else                           NextWalkerState = LEVEL1;
          LEVEL2: if      (HREADY && ValidEntry) NextWalkerState = LEAF;
                  else if (HREADY)               NextWalkerState = FAULT;
                  else                           NextWalkerState = LEVEL2;
          LEAF:                                  NextWalkerState = IDLE;
        endcase
      end

      always_ff @(posedge HCLK, negedge HRESETn)
        if (~HRESETn) begin
          TranslationPAdr <= '0;
          PageTableEntryF <= '0;
          TranslationComplete <= '0;
        end else begin
          // default values
          case (NextWalkerState)
            LEVEL1: TranslationPAdr <= {BasePageTablePPN, VPN1, 2'b00};
            LEVEL2: TranslationPAdr <= {CurrentPPN, VPN0, 2'b00};
            LEAF: begin
              PageTableEntryF <= CurrentPageTableEntry;
              TranslationComplete <= '1;
              end
          endcase
        end

      assign #1 Translate = (NextWalkerState == LEVEL1);
    end else begin
      // sv39 not yet implemented
      assign SvMode = SATP_REGW[63];
    end
  endgenerate

  // rv32 case

  
*/

endmodule