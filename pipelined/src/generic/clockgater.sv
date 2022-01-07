///////////////////////////////////////////
// clockgater.sv
//
// Written: Ross Thompson 9 January 2021
// Modified: 
//
// Purpose: Clock gater model. Must use standard cell for synthesis.
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

module clockgater
  (input logic 	E,
   input logic 	SE,
   input logic 	CLK,
   output logic ECLK);



  if (`FPGA) begin
    BUFGCE bufgce_i0 (   
   .I(CLK),
   .CE(E | SE),
   .O(ECLK)    
   );
  end else begin
    // *** BUG 
    // VERY IMPORTANT.
    // This part functionally models a clock gater, but does not necessarily meet the timing constrains a real standard cell would.
    // Do not use this in synthesis!
    logic 	enable_q;
    always_latch begin
      if(~CLK) begin
	enable_q <= E | SE;
      end
    end
    assign ECLK = enable_q & CLK;
  end    

endmodule
