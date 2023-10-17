///////////////////////////////////////////
// sd_top_tb.sv
//
// Written: Ross Thompson September 20, 2021
// Modified: 
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

`include "wconfig.vh"


module sd_top_tb();


  localparam g_COUNT_WIDTH = 8;

  logic a_RST;
  logic i_SD_CMD;
  logic o_SD_CMD;
  logic o_SD_CMD_OE;
  wire [3:0] i_SD_DAT;
  logic o_SD_CLK;
  logic [32:9] i_BLOCK_ADDR;
  logic [g_COUNT_WIDTH-1:0] i_COUNT_IN_MAX;

  logic o_READY_FOR_READ;
  logic i_READ_REQUEST;
  logic [3:0] o_DATA_TO_CORE;
  logic o_DATA_VALID;
  logic o_LAST_NIBBLE;
  logic [4095:0] ReadData;
  logic o_SD_RESTARTING;
  logic [2:0] o_ERROR_CODE_Q;
  logic o_FATAL_ERROR;
  
  
  
  // Driver
  wire PAD;

  logic r_CLK;
  

  // clock
  
  sd_top #(g_COUNT_WIDTH) DUT
    (.CLK(r_CLK),
    .a_RST(a_RST),
    .i_SD_CMD(i_SD_CMD),
    .o_SD_CMD(o_SD_CMD),
    .o_SD_CMD_OE(o_SD_CMD_OE),
    .i_SD_DAT(i_SD_DAT),
    .o_SD_CLK(o_SD_CLK),
    .i_BLOCK_ADDR(i_BLOCK_ADDR),
    .o_READY_FOR_READ(o_READY_FOR_READ),
     .o_SD_RESTARTING(o_SD_RESTARTING),
     .o_ERROR_CODE_Q(o_ERROR_CODE_Q),
     .o_FATAL_ERROR(o_FATAL_ERROR),
    .i_READ_REQUEST(i_READ_REQUEST),
    .o_DATA_TO_CORE(o_DATA_TO_CORE),
    .ReadData(ReadData),     
    .o_DATA_VALID(o_DATA_VALID),
    .o_LAST_NIBBLE(o_LAST_NIBBLE),
    .i_COUNT_IN_MAX(i_COUNT_IN_MAX),
     .LIMIT_SD_TIMERS(1'b1));

  sdModel sdcard
    (.sdClk(o_SD_CLK),
    .cmd(PAD), 
    .dat(i_SD_DAT));
  
  // tri state pad
  // replace with I/O standard cell or FPGA gate.
  assign PAD = o_SD_CMD_OE ? o_SD_CMD : 1'bz;
  assign i_SD_CMD = PAD;
  

  always
    begin
      r_CLK = 1; # 5; r_CLK = 0; # 5;
    end
  

  initial $readmemh("ramdisk2.hex", sdcard.FLASHmem);
  
  initial begin

    a_RST          = 1'b0;
    i_BLOCK_ADDR   = 24'h100000;
    i_COUNT_IN_MAX = '0;
    i_READ_REQUEST = 1'b0;

    # 5;
    i_COUNT_IN_MAX = -62;

    # 10;
    a_RST = 1'b1;

    # 4800;
    
    a_RST = 1'b0;

    # 2000000;
    i_READ_REQUEST = 1'b0;
    # 10000;
    i_READ_REQUEST = 1'b1;
    # 10000;
    i_READ_REQUEST = 1'b0;
    
  end

endmodule
