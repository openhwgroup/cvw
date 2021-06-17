///////////////////////////////////////////
// regfile.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: 4-port register file
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

module FPregfile (
  input  logic             clk, reset,
  input  logic             we4, 
  input  logic [ 4:0]      a1, a2, a3, a4, 
  input  logic [63:0] wd4,    //KEP `XLEN-1 changed to 63 (lint warning) *** figure out if double can be suported when XLEN = 32
  output logic [63:0] rd1, rd2, rd3);

  logic [63:0] rf[31:0];
  integer i;

  // three ported register file
  // read three ports combinationally (A1/RD1, A2/RD2, A3/RD3)
  // write fourth port on rising edge of clock (A4/WD4/WE4)
  // write occurs on falling edge of clock
  
  // reset is intended for simulation only, not synthesis
    
   always_ff @(negedge clk or posedge reset)
     if (reset) for(i=0; i<32; i++) rf[i] <= 0;
     else if (we4) rf[a4] <= wd4;	
   
   assign #2 rd1 = rf[a1];
   assign #2 rd2 = rf[a2];
   assign #2 rd3 = rf[a3];
   
endmodule // regfile

