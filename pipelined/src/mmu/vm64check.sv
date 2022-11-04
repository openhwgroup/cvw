///////////////////////////////////////////
// vm64check.sv
//
// Written: David_Harris@hmc.edu 4 November 2022
// Modified: 
//
// Purpose: Check for good upper address bits in RV64 mode
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

module vm64check (
   input  logic [`SVMODE_BITS-1:0] SATP_MODE,
   input  logic [`XLEN-1:0]        VAdr,
   output logic                    SV39Mode, UpperBitsUnequalPageFault
);

  if (`XLEN==64) begin:rv64
      assign SV39Mode = (SATP_MODE == `SV39);
      // page fault if upper bits aren't all the same
      logic UpperEqual39, UpperEqual48;
      assign UpperEqual39 = &(VAdr[63:38]) | ~|(VAdr[63:38]);
      assign UpperEqual48 = &(VAdr[63:47]) | ~|(VAdr[63:47]); 
      assign UpperBitsUnequalPageFault = SV39Mode ? ~UpperEqual39 : ~UpperEqual48;
  end else begin
      assign SV39Mode = 0;
      assign UpperBitsUnequalPageFault = 0;
  end           
endmodule
