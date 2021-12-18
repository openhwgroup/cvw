///////////////////////////////////////////
// shifter.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: RISC-V 32/64 bit shifter
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

module shifter (
  input  logic [`XLEN-1:0] a,
  input  logic [5:0]       amt,
  input  logic             right, arith, w64,
  output logic [`XLEN-1:0] y);

  localparam BITS = $clog2(`XLEN);

  logic [2*`XLEN-2:0]      z, zshift;
  logic [BITS-1:0]         amttrunc, offset;

  // The best shifter architecture differs based on `XLEN.
  // for RV32, only 32-bit shifts are needed.  These are 
  // most efficiently implemented with a funnel shifter.  
  // For RV64, 32 and 64-bit shifts are needed, with sign
  // extension.

  // funnel shifter input (see CMOS VLSI Design 4e Section 11.8.1, note Table 11.11 shift types wrong)
  generate
    if (`XLEN==32) begin:shifter // RV32
      always_comb  // funnel mux
        if (right) 
          if (arith) z = {{31{a[31]}}, a};
          else       z = {31'b0, a};
        else         z = {a, 31'b0};
      assign amttrunc = amt[4:0]; // shift amount
    end else begin:shifter  // RV64
      always_comb  // funnel mux
        if (w64) begin // 32-bit shifts
          if (right)
            if (arith) z = {64'b0, {31{a[31]}}, a[31:0]};
            else       z = {95'b0, a[31:0]};
          else         z = {32'b0, a[31:0], 63'b0};
        end else begin
          if (right)
            if (arith) z = {{63{a[63]}}, a};
            else       z = {63'b0, a};
          else         z = {a, 63'b0};         
        end
      assign amttrunc = w64 ? {1'b0, amt[4:0]} : amt[5:0]; // 32 or 64-bit shift
    end
  endgenerate

  // opposite offset for right shfits
  assign offset = right ? amttrunc : ~amttrunc;
  
  // funnel operation
  assign zshift = z >> offset;
  assign y = zshift[`XLEN-1:0];    
endmodule


