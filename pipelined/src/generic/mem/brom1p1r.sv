///////////////////////////////////////////
// brom1p1r
//
// Written: David_Harris@hmc.edu 8/24/22
//
// Purpose: Single-ported ROM
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

// This model actually works correctly with vivado.

`include "wally-config.vh"

module brom1p1r
  #(
	//--------------------------------------------------------------------------
	parameter ADDR_WIDTH = 8,
	// Addr Width in bits : 2 **ADDR_WIDTH = RAM Depth
	parameter DATA_WIDTH = 32 // Data Width in bits
	//----------------------------------------------------------------------
	) (
	   input logic 					 clk,
	   input logic [ADDR_WIDTH-1:0]  addr,
	   output logic [DATA_WIDTH-1:0] dout
	   );
  // Core Memory
  logic [DATA_WIDTH-1:0] 			 ROM [(2**ADDR_WIDTH)-1:0];

  always @ (posedge clk) begin
	dout <= ROM[addr];    
  end
endmodule // bytewrite_tdp_ram_rf
