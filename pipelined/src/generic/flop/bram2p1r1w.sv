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

/* -----\/----- EXCLUDED -----\/-----
  initial begin
    if(PRELOAD_ENABLED)
	  $readmemh(PRELOAD_FILE, RAM);
  end
 -----/\----- EXCLUDED -----/\----- */

  initial begin
	if(PRELOAD_ENABLED) begin
      RAM[0] =  64'h9581819300002197; 
      RAM[1] =  64'h4281420141014081; 
      RAM[2] =  64'h4481440143814301; 
      RAM[3] =  64'h4681460145814501; 
      RAM[4] =  64'h4881480147814701; 
      RAM[5] =  64'h4a814a0149814901; 
      RAM[6] =  64'h4c814c014b814b01; 
      RAM[7] =  64'h4e814e014d814d01; 
      RAM[8] =  64'h0110011b4f814f01; 
      RAM[9] =  64'h059b45011161016e; 
      RAM[10] = 64'h0004063705fe0010; 
      RAM[11] = 64'h05a000ef8006061b; 
      RAM[12] = 64'h0ff003930000100f; 
      RAM[13] = 64'h4e952e3110060e37; 
      RAM[14] = 64'hc602829b0053f2b7; 
      RAM[15] = 64'h2023fe02dfe312fd; 
      RAM[16] = 64'h829b0053f2b7007e; 
      RAM[17] = 64'hfe02dfe312fdc602; 
      RAM[18] = 64'h4de31efd000e2023; 
      RAM[19] = 64'h059bf1402573fdd0; 
      RAM[20] = 64'h0000061705e20870; 
      RAM[21] = 64'h0010029b01260613; 
      RAM[22] = 64'h11010002806702fe; 
      RAM[23] = 64'h84b2842ae426e822; 
      RAM[24] = 64'h892ee04aec064511; 
      RAM[25] = 64'h06e000ef07e000ef; 
      RAM[26] = 64'h979334fd02905563; 
      RAM[27] = 64'h07930177d4930204; 
      RAM[28] = 64'h4089093394be2004; 
      RAM[29] = 64'h04138522008905b3; 
      RAM[30] = 64'h19e3014000ef2004; 
      RAM[31] = 64'h64a2644260e2fe94; 
      RAM[32] = 64'h6749808261056902; 
      RAM[33] = 64'hdfed8b8510472783; 
      RAM[34] = 64'h2423479110a73823; 
      RAM[35] = 64'h10472783674910f7; 
      RAM[36] = 64'h20058693ffed8b89; 
      RAM[37] = 64'h05a1118737836749; 
      RAM[38] = 64'hfed59be3fef5bc23; 
      RAM[39] = 64'h1047278367498082; 
      RAM[40] = 64'h47858082dfed8b85; 
      RAM[41] = 64'h40a7853b4015551b;   
	  RAM[42] = 64'h808210a7a02367c9;
	end				
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
