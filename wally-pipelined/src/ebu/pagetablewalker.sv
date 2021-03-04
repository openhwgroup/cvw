///////////////////////////////////////////
// ahblite.sv
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

module pagetablewalker (
  input  logic             clk, reset,

  input  logic [`XLEN-1:0] satp,

  input  logic             TLBMissF,
  input  logic [`XLEN-1:0] TranslationVAdr,

  input  logic             HCLK, HRESETn,

  input  logic             HREADY,

  output logic [`XLEN-1:0] PageTableEntryF,
  output logic             TranslationComplete
);

  /*
  generate
    if (`XLEN == 32) begin
      logic Sv_Mode       = satp[31]
    end else begin
      logic Sv_Mode [3:0] = satp[63:60]
    end
  endgenerate
  */

  logic Sv_Mode = satp[31];
  logic BasePageTablePPN [21:0] = satp[21:0];

  logic VPN1 [9:0] = TranslationVAdr[31:22];
  logic VPN0 [9:0] = TranslationVAdr[21:12]; // *** could optimize by not passing offset?

  logic TranslationPAdr [33:0];

  typedef enum {IDLE, LEVEL1, LEVEL0, LEAF, FAULT} statetype;
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
        LEAF:   PageTableEntryF <= CurrentPageTableEntry;
                TranslationComplete <= '1;
    end

  assign #1 Translate = (NextWalkerState = LEVEL1);


endmodule