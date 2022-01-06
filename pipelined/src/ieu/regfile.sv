///////////////////////////////////////////
// regfile.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: 3-port register file
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

module regfile (
  input  logic             clk, reset,
  input  logic             we3, 
  input  logic [ 4:0]      a1, a2, a3, 
  input  logic [`XLEN-1:0] wd3, 
  output logic [`XLEN-1:0] rd1, rd2);

  logic [`XLEN-1:0] rf[31:1];
  integer i;

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // write occurs on falling edge of clock
  // register 0 hardwired to 0
  
  // reset is intended for simulation only, not synthesis
    
  always_ff @(negedge clk) // or posedge reset)
    if (reset) for(i=1; i<32; i++) rf[i] <= 0;
    else       if (we3)            rf[a3] <= wd3;	

  assign #2 rd1 = (a1 != 0) ? rf[a1] : 0;
  assign #2 rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule
