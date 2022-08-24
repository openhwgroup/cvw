///////////////////////////////////////////
// block ram model should be equivalent to srsam.
//
// Written: Ross Thompson
// March 29, 2022
// Modified: Based on UG901 vivado documentation.
//
// Purpose: On-chip SIMPLERAM, external to core
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

module bram1p1rw_64x128
  #(
	//--------------------------------------------------------------------------
	parameter NUM_COL = 16,
	parameter COL_WIDTH = 8,
	parameter ADDR_WIDTH = 6,
	// Addr Width in bits : 2 *ADDR_WIDTH = RAM Depth
	parameter DATA_WIDTH = NUM_COL*COL_WIDTH // Data Width in bits
	//----------------------------------------------------------------------
	) (
	   input logic 					 clk,
	   input logic 					 we,
	   input logic [NUM_COL-1:0] 	 bwe,
	   input logic [ADDR_WIDTH-1:0]  addr,
	   output logic [DATA_WIDTH-1:0] dout,
	   input logic [DATA_WIDTH-1:0]  din
	   );
  // Core Memory
  logic [DATA_WIDTH-1:0] 			 RAM [(2**ADDR_WIDTH)-1:0];
  integer 							 i;

  always @ (posedge clk) begin
	dout <= RAM[addr];    
	if(we) begin
	  for(i=0;i<NUM_COL;i=i+1) begin
		if(bwe[i]) begin
		  RAM[addr][i*COL_WIDTH +: COL_WIDTH] <= din[i*COL_WIDTH +:COL_WIDTH];
		end
	  end
	end
  end
endmodule // bytewrite_tdp_ram_rf
