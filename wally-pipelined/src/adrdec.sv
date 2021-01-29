///////////////////////////////////////////
// adrdec.sv
//
// Written: David_Harris@hmc.edu 29 January 2021
// Modified: 
//
// Purpose: Address decoder
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

module adrdec (
  input  logic [`XLEN-1:0] AdrM,
  input  logic [`XLEN-1:0] Base, Range,
  output logic             En
);

  logic [`XLEN-1:0] match;

  // determine if an address is in a range starting at the base
  // for example, if Base = 0x04002000 and range = 0x00000FFF,
  // then anything address between 0x04002000 and 0x04002FFF should match (En=1)

  assign match = (AdrM ~^ Base) | Range;
  assign En = &match;

endmodule

