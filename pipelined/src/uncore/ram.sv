///////////////////////////////////////////
// ram.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: On-chip RAM, external to core
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

module ram #(parameter BASE=0, RANGE = 65535) (
  input  logic             HCLK, HRESETn, 
  input  logic             HSELRam,
  input  logic [31:0]      HADDR,
  input  logic             HWRITE,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  input  logic [`XLEN-1:0] HWDATA,
  input  logic [3:0]       HSIZED,
  output logic [`XLEN-1:0] HREADRam,
  output logic             HRESPRam, HREADYRam
);

  // Desired changes.
  // 1. find a way to merge read and write address into 1 port.
  // 2. remove all unnecessary latencies. (HREADY needs to be able to constant high.)
  // 3. implement burst.
  // 4. remove the configurable latency.

  logic [`XLEN/8-1:0] 		  ByteMask;
  logic [31:0]        HADDRD, RamAddr;
  //logic				  prevHREADYRam, risingHREADYRam;
  logic				  initTrans;
  logic				  memwrite, memwriteD, memread;
  logic         nextHREADYRam;
  //logic [3:0] 		  busycount;
  
  swbytemask swbytemask(.Size(HSIZED[1:0]), .Adr(HADDRD[2:0]), .ByteMask(ByteMask));

  assign initTrans = HREADY & HSELRam & (HTRANS[1]); 
  assign memwrite = initTrans & HWRITE;  // *** why is initTrans needed?  See CLINT interface
  assign memread = initTrans & ~HWRITE;
 
  flopenr #(1) memwritereg(HCLK, ~HRESETn, HREADY, memwrite, memwriteD); 
  flopenr #(32)   haddrreg(HCLK, ~HRESETn, HREADY, HADDR, HADDRD);

/*  // busy FSM to extend READY signal
  always @(posedge HCLK, negedge HRESETn) 
    if (~HRESETn) begin
      busycount <= 0;
      HREADYRam <= #1 0;
    end else begin
      if (initTrans) begin
        busycount <= 0;
        HREADYRam <= #1 0;
      end else if (~HREADYRam) begin
        if (busycount == 0) begin // Ram latency, for testing purposes.  *** test with different values such as 2
          HREADYRam <= #1 1;
        end else begin
          busycount <= busycount + 1;
        end
      end
    end */


  // Stall on a read after a write because the RAM can't take both adddresses on the same cycle
  assign nextHREADYRam = ~(memwriteD & memread);
// assign nextHREADYRam = ~(memwriteD & ~memwrite);
  flopr #(1) readyreg(HCLK, ~HRESETn, nextHREADYRam, HREADYRam);
//  assign HREADYRam = ~(memwriteD & ~memwrite);
  assign HRESPRam = 0; // OK

  localparam ADDR_WIDTH = $clog2(RANGE/8);
  localparam OFFSET = $clog2(`XLEN/8);
  
/*  // Rising HREADY edge detector
  //   Indicates when ram is finishing up
  //   Needed because HREADY may go high for other reasons,
  //   and we only want to write data when finishing up.
  flopenr #(1) prevhreadyRamreg(HCLK,~HRESETn, 1'b1, HREADYRam,prevHREADYRam);
  assign risingHREADYRam = HREADYRam & ~prevHREADYRam;*/

/*
 bram2p1r1w #(`XLEN/8, 8, ADDR_WDITH, `FPGA)
  memory(.clk(HCLK), .reA(1'b1),
		 .addrA(A[ADDR_WDITH+OFFSET-1:OFFSET]), .doutA(HREADRam),
		 .weB(memwrite & risingHREADYRam), .bweB(ByteMaskM),
		 .addrB(HWADDR[ADDR_WDITH+OFFSET-1:OFFSET]), .dinB(HWDATA)); */

    

  // On writes or during a wait state, use address delayed by one cycle to sync RamAddr with HWDATA or hold stalled address
  mux2 #(32) adrmux(HADDR, HADDRD, memwriteD | ~HREADY, RamAddr);

  // single-ported RAM
  bram1p1rw #(`XLEN/8, 8, ADDR_WIDTH)
    memory(.clk(HCLK), .we(memwriteD), .bwe(ByteMask), .addr(RamAddr[ADDR_WIDTH+OFFSET-1:OFFSET]), .dout(HREADRam), .din(HWDATA));  
endmodule
  
