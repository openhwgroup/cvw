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
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module clint (
  input  logic             HCLK, HRESETn, TIMECLK,
  input  logic             HSELCLINT,
  input  logic [15:0]      HADDR,
  input  logic             HWRITE,
  input  logic [`XLEN-1:0] HWDATA,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  output logic [`XLEN-1:0] HREADCLINT,
  output logic             HRESPCLINT, HREADYCLINT,
  output logic [63:0]      MTIME, 
  output logic             TimerIntM, SwIntM);

  logic        MSIP;

  logic [15:0] entry, entryd;
  logic memwrite;
  logic initTrans;
  logic [63:0] MTIMECMP;

  assign initTrans = HREADY & HSELCLINT & (HTRANS != 2'b00);
  // entryd and memwrite are delayed by a cycle because AHB controller waits a cycle before outputting write data
  flopr #(1) memwriteflop(HCLK, ~HRESETn, initTrans & HWRITE, memwrite);
  flopr #(16) entrydflop(HCLK, ~HRESETn, entry, entryd);

  assign HRESPCLINT = 0; // OK
  assign HREADYCLINT = 1'b1; // *** needs to depend on DONE during accesses 
  
  // word aligned reads
  if (`XLEN==64) assign #2 entry = {HADDR[15:3], 3'b000};
  else           assign #2 entry = {HADDR[15:2], 2'b00}; 
  
  // DH 2/20/21: Eventually allow MTIME to run off a separate clock
  // This will require synchronizing MTIME to the system clock
  // before it is read or compared to MTIMECMP.
  // It will also require synchronizing the write to MTIMECMP.
  // Use req and ack signals synchronized across the clock domains.

  // register access
  if (`XLEN==64) begin:clint // 64-bit
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
      end

// eventually replace MTIME logic below with timereg
//    timereg tr(HCLK, HRESETn, TIMECLK, memwrite & (entryd==16'hBFF8), 1'b0, HWDATA, MTIME, done);

    always_ff @(posedge HCLK or negedge HRESETn) 
      if (~HRESETn) begin
        MTIME <= 0;
        // MTIMECMP is not reset
      end else if (memwrite & entryd == 16'hBFF8) begin
        // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
        MTIME <= HWDATA;
      end else MTIME <= MTIME + 1; 
  end else begin:clint // 32-bit
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
        // MTIMECMP is not reset ***?
      end else if (memwrite) begin
        if (entryd == 16'h0000) MSIP <= HWDATA[0];
        if (entryd == 16'h4000) MTIMECMP[31:0] <= HWDATA;
        if (entryd == 16'h4004) MTIMECMP[63:32] <= HWDATA;
        // MTIME Counter.  Eventually change this to run off separate clock.  Synchronization then needed
      end

// eventually replace MTIME logic below with timereg
//     timereg tr(HCLK, HRESETn, TIMECLK, memwrite & (entryd==16'hBFF8), memwrite & (entryd == 16'hBFFC), HWDATA, MTIME, done);
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

  // Software interrupt when MSIP is set
  assign SwIntM = MSIP;
  // Timer interrupt when MTIME >= MTIMECMP
  assign TimerIntM = ({1'b0, MTIME} >= {1'b0, MTIMECMP}); // unsigned comparison

endmodule

module timeregsync(
  input  logic clk, resetn, 
  input  logic             we0, we1,
  input  logic [`XLEN-1:0] wd,
  output logic [63:0]      q);

  if (`XLEN==64) 
    always_ff @(posedge clk or negedge resetn) 
      if (~resetn) q <= 0;
      else if (we0) q <= wd;
      else          q <= q + 1;
  else
    always_ff @(posedge clk or negedge resetn) 
      if (~resetn) q <= 0;
      else if (we0) q[31:0] <= wd;
      else if (we1) q[63:32] <= wd;
      else          q <= q + 1;
endmodule

module timereg(
  input  logic HCLK, HRESETn, TIMECLK,
  input  logic             we0, we1,
  input  logic [`XLEN-1:0] HWDATA,
  output logic [63:0]      MTIME,
  output logic             done);

//  if (`TIMEBASE_SYNC) begin:timereg // use HCLK for MTIME
  if (1) begin:timereg // use HCLK for MTIME
    timregsync timeregsync(.clk(HCLK), .resetn(HRESETn), .we0, .we1, .wd(HWDATA), .q(MTIME));
    assign done = 1; // immediately completes
  end else begin // use asynchronous TIMECLK 
    // TIME counter runs on TIMECLK but bus interface runs on HCLK
    // Need to synchronize reads and writes
    // This is subtle because synchronizing a binary counter on a per-bit basis could give a mix of old and new bits
    // Instead, we use a Gray coded counter that only changes one bit per cycle
    // Synchronizing this for a read is safe because we are guaranteed to get either the old or the new value.
    // Writing to the counter requires a request/acknowledge handshake to ensure the write value is held long enough.
    // The handshake signals are synchronized in each direction across the interface
    // There is no back pressure on instructions, so if multiple counter writes occur ***

    logic req, req_sync, ack, we0_stored, we1_stored, ack_stored, resetn_sync;
    logic [`XLEN-1:0] wd_stored;
    logic [63:0] time_int, time_int_gc, time_gc, MTIME_GC;

    // When a write enable is asserted for a cycle, sample the enables and data and raise a request until it is acknowledged
    // When the acknowledge falls, the transaction is done and the system is ready for another write.
    // ***look at redoing this assuming write enable and data are held rather than pulsed.
    always_ff @(posedge HCLK or negedge HRESETn) 
      if (~HRESETn) 
        req <= 0; // don't bother resetting wd
      else begin
        req        <= we0 | we1 | req & ~ack;
        we0_stored <= we0; 
        we1_stored <= we1;
        wd_stored  <= HWDATA;
        ack_stored <= ack;
        done       <= ack_stored & ~ack;
      end

    // synchronize the reset and reqest into the TIMECLK domain
    sync resetsync(TIMECLK, HRESETn, resetn_sync);
    sync rsync(TIMECLK, req, req_sync);
    // synchronize the acknowledge back to the HCLK domain to indicate the request was handled and can be lowered
    sync async(HCLK, req_sync, ack);

    timeregsync timeregsync(.clk(TIMECLK), .resetn(resetn_sync), .we0(we0_stored), .we1(we1_stored), .wd(wd_stored), .q(time_int));
    binarytogray b2g(time_int, time_int_gc);
    flop gcreg(TIMECLK, time_int_gc, time_gc);

    sync timesync[63:0](HCLK, time_gc, MTIME_GC); 
    graytobinary g2b(MTIME_GC, MTIME);
  end
endmodule

module binarytogray #(parameter N = `XLEN) (
  input  logic [N-1:0] b,
  output logic [N-1:0] g);

  // G[N-1] = B[N-1]; G[i] = B[i] ^ B[i+1] for 0 <= i < N-1
  // requires single layer of N-1 XOR gates
  assign g = b ^ {1'b0, b[N-1:1]};
endmodule

module graytobinary #(parameter N = `XLEN) (
  input  logic [N-1:0] g,
  output logic [N-1:0] b);

  // B[N-1] = G[N-1]; B[i] = G[i] ^ B[i+1] for 0 <= i < N-1
  // requires rippling through N-1 XOR gates
    genvar i;
    assign b[N-1] = g[N-1];
    for (i=N-2; i >= 0; i--) begin:g2b
      assign b[i] = g[i] ^ b[i+1];
    end
endmodule
