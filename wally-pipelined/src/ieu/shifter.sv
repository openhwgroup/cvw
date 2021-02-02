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

  // The best shifter architecture differs based on `XLEN.
  // for RV32, only 32-bit shifts are needed.  These are 
  // most efficiently implemented with a funnel shifter.  
  // For RV64, 32 and 64-bit shifts are needed, with sign
  // extension.

  generate
    if (`XLEN==32) begin
      // funnel shifter (see CMOS VLSI Design 4e Section 11.8.1, note Table 11.11 shift types wrong)
      logic [62:0]        z, zshift;
      logic [4:0]         offset;
  
      // funnel input
      always_comb  
        if (right)
          if (arith) z = {{31{a[31]}}, a};
          else       z = {31'b0, a};
        else         z = {a, 31'b0};
    
      // shift amount
      assign offset = right ? amt[4:0] : ~amt[4:0];
    
      // funnel operation
      assign zshift = z >> offset;
      assign y = zshift[31:0];      
    end else begin  // RV64
      // funnel shifter followed by masking
      // research idea: investigate shifter designs for mixed 32/64-bit shifts
      logic [126:0] z, zshift;
      logic [31:0]   ylower, yupper;
      logic [5:0]         offset, amt6;
  
      // funnel input
      always_comb  
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
    
      // shift amount
      assign amt6 = w64 ? {1'b0, amt[4:0]} : amt[5:0]; // 32 or 64-bit shift
      assign offset = right ? amt6 : ~amt6;
  
      // funnel operation
      assign zshift = z >> offset;
      assign ylower = zshift[31:0];    

      // mask upper 32 bits for W-type 32-bit shifts
      // harris: is there a clever way to get zshift[31] earlier for arithmetic right shifts to speed up critical path?
      assign yupper = w64 ? {32{zshift[31]}} : zshift[63:32];
      assign y = {yupper, ylower};
    end
  endgenerate
endmodule


