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

module bram2p1r1w
  #(
	//--------------------------------------------------------------------------
	parameter NUM_COL = 8,
	parameter COL_WIDTH = 8,
	parameter ADDR_WIDTH = 10,
    parameter PRELOAD_ENABLED = 0,
    parameter PRELOAD_FILE = "bootrom.txt",
	// Addr Width in bits : 2 *ADDR_WIDTH = RAM Depth
	parameter DATA_WIDTH = NUM_COL*COL_WIDTH // Data Width in bits
	//----------------------------------------------------------------------
	) (
	   input logic 					 clk,
	   input logic 					 enaA,
	   input logic [ADDR_WIDTH-1:0]  addrA,
	   output logic [DATA_WIDTH-1:0] doutA,
	   input logic 					 enaB,
	   input logic [NUM_COL-1:0] 	 weB,
	   input logic [ADDR_WIDTH-1:0]  addrB,
	   input logic [DATA_WIDTH-1:0]  dinB
	   );



  // *** TODO.
/* -----\/----- EXCLUDED -----\/-----
  if(`SRAM) begin
    // instanciate SRAM model
    // need multiple SRAM instances to map into correct dimentions.
    // also map the byte write enables onto bit write enables.
  end else begin // FPGA or infered flip flop memory
    // Core Memory
  end
 -----/\----- EXCLUDED -----/\----- */

  logic [DATA_WIDTH-1:0] 			 RAM [(2**ADDR_WIDTH)-1:0];
  integer                            i;

  initial begin
    if(PRELOAD_ENABLED)
	  $readmemh(PRELOAD_FILE, RAM);
  end

  // Port-A Operation
  always @ (posedge clk) begin
	if(enaA) begin
	  doutA <= RAM[addrA];
	end
  end
  // Port-B Operation:
  always @ (posedge clk) begin
	if(enaB) begin
	  for(i=0;i<NUM_COL;i=i+1) begin
		if(weB[i]) begin
		  RAM[addrB][i*COL_WIDTH +: COL_WIDTH] <= dinB[i*COL_WIDTH +:COL_WIDTH];
		end
	  end
	end
  end
  
endmodule // bytewrite_tdp_ram_rf
