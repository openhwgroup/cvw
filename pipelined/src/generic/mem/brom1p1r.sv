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
	parameter DATA_WIDTH = 32, // Data Width in bits
    parameter PRELOAD_ENABLED = 0
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

  if(PRELOAD_ENABLED) begin
    initial begin
      ROM[0] =  64'h9581819300002197; 
      ROM[1] =  64'h4281420141014081; 
      ROM[2] =  64'h4481440143814301; 
      ROM[3] =  64'h4681460145814501; 
      ROM[4] =  64'h4881480147814701; 
      ROM[5] =  64'h4a814a0149814901; 
      ROM[6] =  64'h4c814c014b814b01; 
      ROM[7] =  64'h4e814e014d814d01; 
      ROM[8] =  64'h0110011b4f814f01; 
      ROM[9] =  64'h059b45011161016e; 
      ROM[10] = 64'h0004063705fe0010; 
      ROM[11] = 64'h05a000ef8006061b; 
      ROM[12] = 64'h0ff003930000100f; 
      ROM[13] = 64'h4e952e3110060e37; 
      ROM[14] = 64'hc602829b0053f2b7; 
      ROM[15] = 64'h2023fe02dfe312fd; 
      ROM[16] = 64'h829b0053f2b7007e; 
      ROM[17] = 64'hfe02dfe312fdc602; 
      ROM[18] = 64'h4de31efd000e2023; 
      ROM[19] = 64'h059bf1402573fdd0; 
      ROM[20] = 64'h0000061705e20870; 
      ROM[21] = 64'h0010029b01260613; 
      ROM[22] = 64'h11010002806702fe; 
      ROM[23] = 64'h84b2842ae426e822; 
      ROM[24] = 64'h892ee04aec064511; 
      ROM[25] = 64'h06e000ef07e000ef; 
      ROM[26] = 64'h979334fd02905563; 
      ROM[27] = 64'h07930177d4930204; 
      ROM[28] = 64'h4089093394be2004; 
      ROM[29] = 64'h04138522008905b3; 
      ROM[30] = 64'h19e3014000ef2004; 
      ROM[31] = 64'h64a2644260e2fe94; 
      ROM[32] = 64'h6749808261056902; 
      ROM[33] = 64'hdfed8b8510472783; 
      ROM[34] = 64'h2423479110a73823; 
      ROM[35] = 64'h10472783674910f7; 
      ROM[36] = 64'h20058693ffed8b89; 
      ROM[37] = 64'h05a1118737836749; 
      ROM[38] = 64'hfed59be3fef5bc23; 
      ROM[39] = 64'h1047278367498082; 
      ROM[40] = 64'h47858082dfed8b85; 
      ROM[41] = 64'h40a7853b4015551b;   
	  ROM[42] = 64'h808210a7a02367c9;
	end				
end
  
endmodule // bytewrite_tdp_ram_rf
