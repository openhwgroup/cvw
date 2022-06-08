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

  logic [`XLEN/8-1:0] 		  ByteMaskM;
  logic [31:0]        HWADDR, A;
  logic				  prevHREADYRam, risingHREADYRam;
  logic				  initTrans;
  logic				  memwrite;
  logic [3:0] 		  busycount;
  
  swbytemask swbytemask(.Size(HSIZED[1:0]), .Adr(HWADDR[2:0]), .ByteMask(ByteMaskM));

  assign initTrans = HREADY & HSELRam & (HTRANS != 2'b00);

  // *** this seems like a weird way to use reset
  flopenr #(1) memwritereg(HCLK, 1'b0, initTrans | ~HRESETn, HSELRam &  HWRITE, memwrite);
  flopenr #(32)   haddrreg(HCLK, 1'b0, initTrans | ~HRESETn, HADDR, A);

  // busy FSM to extend READY signal
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
    end
  assign HRESPRam = 0; // OK

  localparam ADDR_WDITH = $clog2(RANGE/8);
  localparam OFFSET = $clog2(`XLEN/8);
  
  // Rising HREADY edge detector
  //   Indicates when ram is finishing up
  //   Needed because HREADY may go high for other reasons,
  //   and we only want to write data when finishing up.
  flopenr #(1) prevhreadyRamreg(HCLK,~HRESETn, 1'b1, HREADYRam,prevHREADYRam);
  assign risingHREADYRam = HREADYRam & ~prevHREADYRam;

  always @(posedge HCLK)
    HWADDR <= #1 A;

  bram2p1r1w #(`XLEN/8, 8, ADDR_WDITH, `FPGA)
  memory(.clk(HCLK), .reA(1'b1),
		 .addrA(A[ADDR_WDITH+OFFSET-1:OFFSET]), .doutA(HREADRam),
		 .weB(memwrite & risingHREADYRam), .bweB(ByteMaskM),
		 .addrB(HWADDR[ADDR_WDITH+OFFSET-1:OFFSET]), .dinB(HWDATA));
/*
  bram1p1r1w #(`XLEN/8, 8, ADDR_WDITH)
    memory(.clk(HCLK), .we(memwrite), .bwe(ByteMaskM), . addr(A***), .dout(HREADRam), .din(HWDATA));
		 
       #(
	//--------------------------------------------------------------------------
	parameter NUM_COL = 8,
	parameter COL_WIDTH = 8,
	parameter ADDR_WIDTH = 10,
	// Addr Width in bits : 2 *ADDR_WIDTH = RAM Depth
	parameter DATA_WIDTH = NUM_COL*COL_WIDTH // Data Width in bits
	//----------------------------------------------------------------------
	) (
	   input logic 					 clk,
	   input logic 					 ena,
	   input logic [NUM_COL-1:0] 	 we,
	   input logic [ADDR_WIDTH-1:0]  addr,
	   output logic [DATA_WIDTH-1:0] dout,
	   input logic [DATA_WIDTH-1:0]  din
	   );*/

  
endmodule
  
