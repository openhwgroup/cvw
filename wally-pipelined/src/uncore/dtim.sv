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

module dtim #(parameter BASE=0, RANGE = 65535, string PRELOAD="") (
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

  localparam MemStartAddr = BASE>>(1+`XLEN/32);
  localparam MemEndAddr = (RANGE+BASE)>>1+(`XLEN/32);
  
  logic [`XLEN-1:0] RAM[BASE>>(1+`XLEN/32):(RANGE+BASE)>>1+(`XLEN/32)];
  logic [31:0] HWADDR, A;
  logic [`XLEN-1:0] HREADTim0;

//  logic [`XLEN-1:0] write;
  logic        prevHREADYTim, risingHREADYTim;
  logic        initTrans;
  logic [15:0] entry;
  logic        memread, memwrite;
  logic [3:0]  busycount;

  initial begin
    //$readmemh(PRELOAD, RAM);
    RAM[0] = 64'h8c61819300002197;
    RAM[1] = 64'h4281420141014081;
    RAM[2] = 64'h4481440143814301;
    RAM[3] = 64'h4681460145814501;
    RAM[4] = 64'h4881480147814701;
    RAM[5] = 64'h4a814a0149814901;
    RAM[6] = 64'h4c814c014b814b01;
    RAM[7] = 64'h4e814e014d814d01;
    RAM[8] = 64'h0ff001134f814f01;
    RAM[9] = 64'h00818213100121b7;
    RAM[10] = 64'h0022a02300c18293;
    RAM[11] = 64'h6bc14a8100222023;
    RAM[12] = 64'h4c010b7e00100b1b;
    RAM[13] = 64'h018ca023018b0cb3;
    RAM[14] = 64'h4c01ff7c4be30c11;
    RAM[15] = 64'h000caa83018b0cb3;
    RAM[16] = 64'h49e30c11038a9063;
    RAM[17] = 64'h0a1b014fba37ff7c;
    RAM[18] = 64'hfe0a5fe31a7d180a;
    RAM[19] = 64'hb7f50022a0230105;
    RAM[20] = 64'h8e0a0a1b0010da37;
    RAM[21] = 64'ha023fe0a5fe31a7d;
    RAM[22] = 64'h0a1b0010da370002;
    RAM[23] = 64'hfe0a5fe31a7d8e0a;
    RAM[24] = 64'h0000bff10022a023;

  end

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
        if (busycount == 0) begin // TIM latency, for testing purposes.  *** test with different values such as 2
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
	if (memwrite & risingHREADYTim) RAM[HWADDR[31:3]] <= #1 HWDATA;
      end
    end else begin 
      always_ff @(posedge HCLK) begin
        HWADDR <= #1 A;  
        HREADTim0 <= #1 RAM[A[31:2]];
        if (memwrite & risingHREADYTim) RAM[HWADDR[31:2]] <= #1 HWDATA;
      end
    end
  endgenerate
  /* verilator lint_on WIDTH */

  //assign HREADTim = HREADYTim ? HREADTim0 : `XLEN'bz;
  // *** Ross Thompson: removed tristate as fpga synthesis removes.
  assign HREADTim = HREADTim0;
  
endmodule

