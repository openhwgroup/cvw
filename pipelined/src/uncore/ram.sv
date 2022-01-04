///////////////////////////////////////////
// ram.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: On-chip RAM, external to hart
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

module ram #(parameter BASE=0, RANGE = 65535) (
  input  logic             HCLK, HRESETn, 
  input  logic             HSELRam,
  input  logic [31:0]      HADDR,
  input  logic             HWRITE,
  input  logic             HREADY,
  input  logic [1:0]       HTRANS,
  input  logic [`XLEN-1:0] HWDATA,
  output logic [`XLEN-1:0] HREADRam,
  output logic             HRESPRam, HREADYRam
);

  localparam MemStartAddr = BASE>>(1+`XLEN/32);
  localparam MemEndAddr = (RANGE+BASE)>>1+(`XLEN/32);
  
  logic [`XLEN-1:0] RAM[BASE>>(1+`XLEN/32):(RANGE+BASE)>>1+(`XLEN/32)];
  logic [31:0] HWADDR, A;
  logic [`XLEN-1:0] HREADRam0;

  logic        prevHREADYRam, risingHREADYRam;
  logic        initTrans;
  logic        memwrite;
  logic [3:0]  busycount;

  generate
    if(`FPGA) begin:ram
      initial begin
	//$readmemh(PRELOAD, RAM);
	// FPGA only
	RAM[0] =  64'h94e1819300002197;
	RAM[1] =  64'h4281420141014081;
	RAM[2] =  64'h4481440143814301;
	RAM[3] =  64'h4681460145814501;
	RAM[4] =  64'h4881480147814701;
	RAM[5] =  64'h4a814a0149814901;
	RAM[6] =  64'h4c814c014b814b01;
	RAM[7] =  64'h4e814e014d814d01;
	RAM[8] =  64'h0110011b4f814f01;
	RAM[9] =  64'h059b45011161016e;
	RAM[10] = 64'h0004063705fe0010;
	RAM[11] = 64'h05a000ef8006061b;
	RAM[12] = 64'h0ff003930000100f;
	RAM[13] = 64'h4e952e3110012e37;
	RAM[14] = 64'hc602829b0053f2b7;
	RAM[15] = 64'h2023fe02dfe312fd;
	RAM[16] = 64'h829b0053f2b7007e;
	RAM[17] = 64'hfe02dfe312fdc602;
	RAM[18] = 64'h4de31efd000e2023;
	RAM[19] = 64'h059bf1402573fdd0;
	RAM[20] = 64'h0000061705e20870;
	RAM[21] = 64'h0010029b01260613;
	RAM[22] = 64'h11010002806702fe;
	RAM[23] = 64'h84b2842ae426e822;
	RAM[24] = 64'h892ee04aec064505;
	RAM[25] = 64'h06e000ef07e000ef;
	RAM[26] = 64'h979334fd02905563;
	RAM[27] = 64'h07930177d4930204;
	RAM[28] = 64'h4089093394be2004;
	RAM[29] = 64'h04138522008905b3;
	RAM[30] = 64'h19e3014000ef2004;
	RAM[31] = 64'h64a2644260e2fe94;
	RAM[32] = 64'h6749808261056902;
	RAM[33] = 64'hdfed8b8510472783;
	RAM[34] = 64'h2423479110a73823;
	RAM[35] = 64'h10472783674910f7;
	RAM[36] = 64'h20058693ffed8b89;
	RAM[37] = 64'h05a1118737836749;
	RAM[38] = 64'hfed59be3fef5bc23;
	RAM[39] = 64'h1047278367498082;
	RAM[40] = 64'h67c98082dfed8b85;
	RAM[41] = 64'h0000808210a7a023;
      end // initial begin
    end // if (FPGA)
  endgenerate

  assign initTrans = HREADY & HSELRam & (HTRANS != 2'b00);

  // *** this seems like a weird way to use reset
  flopenr #(1) memwritereg(HCLK, 1'b0, initTrans | ~HRESETn, HSELRam &  HWRITE, memwrite);
  flopenr #(32)   haddrreg(HCLK, 1'b0, initTrans | ~HRESETn, HADDR, A);

  // busy FSM to extend READY signal
  always_ff @(posedge HCLK, negedge HRESETn) 
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
  
  // Rising HREADY edge detector
  //   Indicates when ram is finishing up
  //   Needed because HREADY may go high for other reasons,
  //   and we only want to write data when finishing up.
  flopr #(1) prevhreadyRamreg(HCLK,~HRESETn,HREADYRam,prevHREADYRam);
  assign risingHREADYRam = HREADYRam & ~prevHREADYRam;

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
    if (`XLEN == 64)  begin:ramrd
      always_ff @(posedge HCLK) begin
        HWADDR <= #1 A;
        HREADRam0 <= #1 RAM[A[31:3]];
	if (memwrite & risingHREADYRam) RAM[HWADDR[31:3]] <= #1 HWDATA;
      end
    end else begin 
      always_ff @(posedge HCLK) begin:ramrd
        HWADDR <= #1 A;  
        HREADRam0 <= #1 RAM[A[31:2]];
        if (memwrite & risingHREADYRam) RAM[HWADDR[31:2]] <= #1 HWDATA;
      end
    end
  endgenerate
  /* verilator lint_on WIDTH */

  //assign HREADRam = HREADYRam ? HREADRam0 : `XLEN'bz;
  // *** Ross Thompson: removed tristate as fpga synthesis removes.
  assign HREADRam = HREADRam0;
  
endmodule

