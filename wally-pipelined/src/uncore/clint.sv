///////////////////////////////////////////
// clint.sv
//
// Written: David_Harris@hmc.edu 14 January 2021
// Modified: 
//
// Purpose: Core-Local Interruptor
//   See FE310-G002-Manual-v19p05 for specifications
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

module clint (
  input  logic             HCLK, HRESETn,
  input  logic             HSELCLINT,
  input  logic [15:0]      HADDR,
  input  logic             HWRITE,
  input  logic [`XLEN-1:0] HWDATA,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  output logic [`XLEN-1:0] HREADCLINT,
  output logic             HRESPCLINT, HREADYCLINT,
  output logic [63:0]      MTIME, MTIMECMP,
  output logic             TimerIntM, SwIntM);

  logic        MSIP;

  logic [15:0] entry, entryd;
  logic memread, memwrite;
  logic initTrans;

  assign initTrans = HREADY & HSELCLINT & (HTRANS != 2'b00);
  assign memread = initTrans & ~HWRITE;
  // entryd and memwrite are delayed by a cycle because AHB controller waits a cycle before outputting write data
  flopr #(1) memwriteflop(HCLK, ~HRESETn, initTrans & HWRITE, memwrite);
  flopr #(16) entrydflop(HCLK, ~HRESETn, entry, entryd);

  assign HRESPCLINT = 0; // OK
  assign HREADYCLINT = 1'b1; // will need to be modified if CLINT ever needs more than 1 cycle to do something
  
  // word aligned reads
  generate
    if (`XLEN==64)
      assign #2 entry = {HADDR[15:3], 3'b000};
    else
      assign #2 entry = {HADDR[15:2], 2'b00}; 
  endgenerate
  
  // DH 2/20/21: Eventually allow MTIME to run off a separate clock
  // This will require synchronizing MTIME to the system clock
  // before it is read or compared to MTIMECMP.
  // It will also require synchronizing the write to MTIMECMP.
  // Use req and ack signals synchronized across the clock domains.

  // register access
  generate
    if (`XLEN==64) begin
      always @(posedge HCLK) begin
        case(entry)
          16'h0000: HREADCLINT <= {63'b0, MSIP};
          16'h4000: HREADCLINT <= MTIMECMP;
          16'hBFF8: HREADCLINT <= MTIME;
          default:  HREADCLINT <= 0;
        endcase
      end 
      always_ff @(posedge HCLK or negedge HRESETn) 
        if (~HRESETn) begin
          MSIP <= 0;
          MTIMECMP <= 0;
          // MTIMECMP is not reset
        end else if (memwrite) begin
          if (entryd == 16'h0000) MSIP <= HWDATA[0];
          if (entryd == 16'h4000) MTIMECMP <= HWDATA;
          // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
        end

      always_ff @(posedge HCLK or negedge HRESETn) 
        if (~HRESETn) begin
          MTIME <= 0;
          // MTIMECMP is not reset
        end else if (memwrite & entryd == 16'hBFF8) begin
          // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
	  MTIME <= HWDATA;
        end else MTIME <= MTIME + 1;
    end else begin // 32-bit
      always @(posedge HCLK) begin
        case(entry)
          16'h0000: HREADCLINT <= {31'b0, MSIP};
          16'h4000: HREADCLINT <= MTIMECMP[31:0];
          16'h4004: HREADCLINT <= MTIMECMP[63:32];
          16'hBFF8: HREADCLINT <= MTIME[31:0];
          16'hBFFC: HREADCLINT <= MTIME[63:32];
          default:  HREADCLINT <= 0;
        endcase
      end 
      always_ff @(posedge HCLK or negedge HRESETn) 
        if (~HRESETn) begin
          MSIP <= 0;
          MTIMECMP <= 0;
          // MTIMECMP is not reset
        end else if (memwrite) begin
          if (entryd == 16'h0000) MSIP <= HWDATA[0];
          if (entryd == 16'h4000) MTIMECMP[31:0] <= HWDATA;
          if (entryd == 16'h4004) MTIMECMP[63:32] <= HWDATA;
          // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
	end

      always_ff @(posedge HCLK or negedge HRESETn) 
        if (~HRESETn) begin
          MTIME <= 0;
          // MTIMECMP is not reset
	end else if (memwrite & (entryd == 16'hBFF8)) begin
	  MTIME[31:0] <= HWDATA;
	end else if (memwrite & (entryd == 16'hBFFC)) begin
          // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
	  MTIME[63:32]<= HWDATA;
	end else MTIME <= MTIME + 1;
    end
  endgenerate

  // Software interrupt when MSIP is set
  assign SwIntM = MSIP;
  // Timer interrupt when MTIME >= MTIMECMP
  assign TimerIntM = ({1'b0, MTIME} >= {1'b0, MTIMECMP}); // unsigned comparison

endmodule

