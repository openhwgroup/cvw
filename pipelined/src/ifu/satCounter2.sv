///////////////////////////////////////////
// satCounter2.sv
//
// Written: Ross Thomposn
// Email: ross1728@gmail.com
// Created: February 13, 2021
// Modified: 
//
// Purpose: 2 bit starting counter
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

`include "wally-config.vh"

module satCounter2
  (input logic        BrDir,
   input logic [1:0]  OldState,
   output logic [1:0] NewState
   );

  always_comb begin
    case(OldState)
      2'b00: begin
 if(BrDir) NewState = 2'b01;
 else NewState = 2'b00;
      end
      2'b01: begin
 if(BrDir) NewState = 2'b10;
 else NewState = 2'b00;
      end
      2'b10: begin
 if(BrDir) NewState = 2'b11;
 else NewState = 2'b01;
      end
      2'b11: begin
 if(BrDir) NewState = 2'b11;
 else NewState = 2'b10;
      end
    endcase
  end

endmodule
