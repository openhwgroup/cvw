///////////////////////////////////////////
// dtim.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Data tightly integrated memory
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

module dtim #(parameter BASE=0, RANGE = 65535) (
  input  logic             HCLK, HRESETn, 
  input  logic             HSELTim,
  input  logic [31:0]      HADDR,
  input  logic             HWRITE,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  input  logic [`XLEN-1:0] HWDATA,
  output logic [`XLEN-1:0] HREADTim,
  output logic             HRESPTim, HREADYTim
);

  localparam integer 	   MemStartAddr = BASE>>(1+`XLEN/32);
  localparam integer 	   MemEndAddr = (RANGE+BASE)>>1+(`XLEN/32);
  
  logic [`XLEN-1:0] RAM[BASE>>(1+`XLEN/32):(RANGE+BASE)>>1+(`XLEN/32)];
  logic [31:0] HWADDR, A;
  logic [`XLEN-1:0] HREADTim0;

//  logic [`XLEN-1:0] write;
  logic        prevHREADYTim, risingHREADYTim;
  logic        initTrans;
  logic [15:0] entry;
  logic        memread, memwrite;
  logic [3:0]  busycount;


  assign initTrans = HREADY & HSELTim & (HTRANS != 2'b00);

  // *** this seems like a weird way to use reset
  flopenr #(1)  memreadreg(HCLK, 1'b0, initTrans | ~HRESETn, HSELTim & ~HWRITE, memread);
  flopenr #(1) memwritereg(HCLK, 1'b0, initTrans | ~HRESETn, HSELTim &  HWRITE, memwrite);
  flopenr #(32)   haddrreg(HCLK, 1'b0, initTrans | ~HRESETn, HADDR, A);

  // busy FSM to extend READY signal
  always_ff @(posedge HCLK, negedge HRESETn) 
    if (~HRESETn) begin
      busycount <= 0;
      HREADYTim <= #1 0;
    end else begin
      if (initTrans) begin
        busycount <= 0;
        HREADYTim <= #1 0;
      end else if (~HREADYTim) begin
        if (busycount == 2) begin // TIM latency, for testing purposes.  *** test with different values
          HREADYTim <= #1 1;
        end else begin
          busycount <= busycount + 1;
        end
      end
    end
  assign HRESPTim = 0; // OK
  
  // Rising HREADY edge detector
  //   Indicates when dtim is finishing up
  //   Needed because HREADY may go high for other reasons,
  //   and we only want to write data when finishing up.
  flopr #(1) prevhreadytimreg(HCLK,~HRESETn,HREADYTim,prevHREADYTim);
  assign risingHREADYTim = HREADYTim & ~prevHREADYTim;

  // Model memory read and write
/* -----\/----- EXCLUDED -----\/-----
  integer       index;

  initial begin
    for(index = MemStartAddr; index < MemEndAddr; index = index + 1) begin
      RAM[index] <= {`XLEN{1'b0}};
    end
  end
 -----/\----- EXCLUDED -----/\----- */
  
  /* verilator lint_off WIDTH */
  generate
    if (`XLEN == 64)  begin
      always_ff @(posedge HCLK) begin
        HWADDR <= #1 A;
        HREADTim0 <= #1 RAM[A[31:3]];
	if (memwrite && risingHREADYTim) RAM[HWADDR[31:3]] <= #1 HWDATA;
      end
    end else begin 
      always_ff @(posedge HCLK) begin
        HWADDR <= #1 A;  
        HREADTim0 <= #1 RAM[A[31:2]];
        if (memwrite && risingHREADYTim) RAM[HWADDR[31:2]] <= #1 HWDATA;
      end
    end
  endgenerate
  /* verilator lint_on WIDTH */

  assign HREADTim = HREADYTim ? HREADTim0 : `XLEN'bz;
endmodule

