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

module dtim (
  input  logic             HCLK, HRESETn, 
  input  logic [1:0]       MemRWtim,
  input  logic [18:0]      HADDR, 
  input  logic [`XLEN-1:0] HWDATA,
  input  logic             HSELTim,
  output logic [`XLEN-1:0] HREADTim,
  output logic             HRESPTim, HREADYTim
);

  logic [`XLEN-1:0] RAM[0:65535];
//  logic [`XLEN-1:0] write;
  logic [15:0] entry;
  logic            memread, memwrite;

  assign memread = MemRWtim[1];
  assign memwrite = MemRWtim[0];
  assign HRESPTim = 0; // OK
  assign HREADYTim = 1; // Respond immediately; *** extend this 
  
  // word aligned reads
  generate
    if (`XLEN==64)
      assign #2 entry = HADDR[18:3];
    else
      assign #2 entry = HADDR[17:2]; 
  endgenerate
  assign HREADTim = RAM[entry];

  // write each byte based on the byte mask
  // UInstantiate a byte-writable memory here if possible
  // and drop tihs masking logic.  Otherwise, use the masking
  // from dmem
  /*generate

    if (`XLEN==64) begin
      always_comb begin
        write=HREADTim;
        if (ByteMaskM[0]) write[7:0]   = HWDATA[7:0];
        if (ByteMaskM[1]) write[15:8]  = HWDATA[15:8];
        if (ByteMaskM[2]) write[23:16] = HWDATA[23:16];
        if (ByteMaskM[3]) write[31:24] = HWDATA[31:24];
	      if (ByteMaskM[4]) write[39:32] = HWDATA[39:32];
	      if (ByteMaskM[5]) write[47:40] = HWDATA[47:40];
      	if (ByteMaskM[6]) write[55:48] = HWDATA[55:48];
	      if (ByteMaskM[7]) write[63:56] = HWDATA[63:56];
      end 
      always_ff @(posedge clk)
        if (memwrite) RAM[HADDR[18:3]] <= write;
    end else begin // 32-bit
      always_comb begin
        write=HREADTim;
        if (ByteMaskM[0]) write[7:0]   = HWDATA[7:0];
        if (ByteMaskM[1]) write[15:8]  = HWDATA[15:8];
        if (ByteMaskM[2]) write[23:16] = HWDATA[23:16];
        if (ByteMaskM[3]) write[31:24] = HWDATA[31:24];
      end 
    always_ff @(posedge clk)
      if (memwrite) RAM[HADDR[17:2]] <= write;  
    end
  endgenerate */
  generate
    if (`XLEN == 64) 
      always_ff @(posedge HCLK) begin
        if (memwrite) RAM[HADDR[17:3]] <= HWDATA;  
//        HREADTim <= RAM[HADDR[17:3]];
      end
    else 
      always_ff @(posedge HCLK) begin
        if (memwrite) RAM[HADDR[17:2]] <= HWDATA;  
//        HREADTim <= RAM[HADDR[17:2]];
      end
  endgenerate
endmodule

