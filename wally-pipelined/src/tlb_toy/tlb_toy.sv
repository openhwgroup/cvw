///////////////////////////////////////////
// tlb_toy.sv
//
// Written: jtorrey@hmc.edu 16 February 2021
// Modified:
//
// Purpose: Example translation lookaside buffer
//           Cache of virtural-to-physical address translations
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

// `include "wally-config.vh"

/**
 * sv32 specs
 * ----------
 * Virtual address [31:0] (32 bits)
 *    [________________________________]
 *     |--VPN1--||--VPN0--||----OFF---|
 *         10        10         12
 * 
 * Physical address [33:0] (34 bits)
 *  [__________________________________]
 *   |---PPN1---||--PPN0--||----OFF---|
 *        12         10         12
 * 
 * Page Table Entry [31:0] (32 bits)
 *    [________________________________]
 *     |---PPN1---||--PPN0--|||DAGUXWRV
 *          12         10    ^^
 *                         RSW(2) -- for OS
 */

/* *** TODO:
 * - add LRU algorithm (select the write index based on which entry was used
 *   least recently)
 * - rename signals to use .* notation in CAM and RAM
 */

module tlb_toy (
  input         clk, reset,

  // Virtual address input
  input  [31:0] PCF,

  // Controls for writing a new entry to the TLB
  input  [31:0] PageTableEntryF,
  input         ITLBWriteF,

  // Invalidate all TLB entries
  input         ITLBFlushF,

  // Physical address outputs
  output [31:0] PCPF,
  output        ITLBMissF,
  output        ITLBHitF
);
  // Index (currently random) to write the next TLB entry
  logic [2:0] WriteIndexF;

  // Sections of the virtual and physical addresses
  logic [19:0] VirtualPageNumberF;
  logic [21:0] PhysicalPageNumberF;
  logic [11:0] PageOffsetF;
  logic [33:0] PhysicalAddressF;

  // Pattern and pattern location in the CAM
  logic [2:0] VPNIndexF;

  // RAM access location
  logic [2:0] ITLBEntryIndex;

  // Page table entry matching the virtual address
  logic [31:0] PTEMatchF;

  assign VirtualPageNumberF = PCF[31:12];
  assign PageOffsetF        = PCF[11:0];

  // Choose a read or write location to the entry list
  mux2 #(3) indexmux(VPNIndexF, WriteIndexF, ITLBWriteF, ITLBEntryIndex);

  // Currently use random replacement algorithm
  rand3 rdm(clk, reset, WriteIndexF);

  ram8x32 ram(clk, reset, ITLBEntryIndex, PageTableEntryF, ITLBWriteF, PTEMatchF);
  cam8x21 cam(clk, reset, ITLBWriteF, VirtualPageNumberF, WriteIndexF,
    ITLBFlushF, VPNIndexF, ITLBHitF);

  always_comb begin
    assign PhysicalPageNumberF = PTEMatchF[31:10];

    if (ITLBHitF) begin
      assign PhysicalAddressF = {PhysicalPageNumberF, PageOffsetF};
    end else begin
      assign PhysicalAddressF = 34'b0;
    end
  end

  assign PCPF = PhysicalAddressF[31:0];
  assign ITLBMissF = ~ITLBHitF & ~(ITLBWriteF | ITLBFlushF);

endmodule

// *** Add parameter for number of tlb lines (currently 8)
module ram8x32 (
  input         clk, reset,
  input   [2:0] address,
  input  [31:0] data,
  input         we,

  output [31:0] out_data
);

  logic [31:0] ram [0:7];
  always @(posedge clk) begin
    if (we) ram[address] <= data;
  end

  assign out_data = ram[address];
    
  initial begin
    for (int i = 0; i < 8; i++)
      ram[i] = 32'h0;
  end

endmodule

module cam8x21 (
  input         clk, reset, we,
  input  [19:0] pattern,
  input  [2:0]  write_address,
  input         ITLBFlushF,
  output [2:0]  matched_address,
  output        match_found
);

  logic [20:0] ram [0:7];
  logic [7:0] match_line;

  logic [2:0] matched_address_comb;
  logic       match_found_comb;

  always @(posedge clk) begin
    if (we) ram[write_address] <= {1'b1,pattern};
    if (ITLBFlushF) begin
      for (int i = 0; i < 8; i++)
        ram[i][20] = 1'b0;
    end
  end

  // *** Check whether this for loop synthesizes correctly
  always_comb begin
    match_found_comb = 1'b0;
    matched_address_comb = 3'b0;
    for (int i = 0; i < 8; i++) begin
      if (ram[i] == {1'b1,pattern} && !match_found_comb) begin
        matched_address_comb = i;
        match_found_comb = 1;
      end else begin
        matched_address_comb = matched_address_comb;
        match_found_comb = match_found_comb;
      end
    end
  end

  assign matched_address = matched_address_comb;
  assign match_found = match_found_comb & ~(we | ITLBFlushF);

  initial begin
    for (int i = 0; i < 8; i++)
      ram[i] <= 0;
  end

endmodule

module mux2 #(parameter WIDTH = 8) (
  input  logic [WIDTH-1:0] d0, d1, 
  input  logic             s, 
  output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

module rand3 (
  input        clk, reset,
  output [2:0] WriteIndexF
);

  logic [31:0] data;
  assign data = $urandom;
  assign WriteIndexF = data[2:0];
  
endmodule
