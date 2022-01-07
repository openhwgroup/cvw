///////////////////////////////////////////
// 1 port sram.
//
// Written: ross1728@gmail.com May 3, 2021
//          Basic sram with 1 read write port.
//          When clk rises Addr and WriteData are sampled.
//          Following the clk edge read data is output from the sampled Addr.
//          Write 
//
// Purpose: Storage and read/write access to data cache data, tag valid, dirty, and replacement.
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

// WIDTH is number of bits in one "word" of the memory, DEPTH is number of such words

module sram1rw #(parameter DEPTH=128, WIDTH=256) (
    input logic 		    clk,
    // port 1 is read only
    input logic [$clog2(DEPTH)-1:0] Addr,
    output logic [WIDTH-1:0] 	    ReadData,
  
    // port 2 is write only
    input logic [WIDTH-1:0] 	    WriteData,
    input logic 		    WriteEnable
);

    logic [DEPTH-1:0][WIDTH-1:0] StoredData; // *** inconsistency in packed vs. unpacked
    logic [$clog2(DEPTH)-1:0] 	 AddrD;
    logic [WIDTH-1:0] 		 WriteDataD;
    logic 			 WriteEnableD;
  

    always_ff @(posedge clk) begin
      AddrD <= Addr;
      WriteDataD <= WriteData;    /// ****** this is not right. there should not need to be a delay.
      WriteEnableD <= WriteEnable;
        if (WriteEnableD) begin
            StoredData[AddrD] <= #1 WriteDataD;
        end
    end

  assign ReadData = StoredData[AddrD];
  
endmodule


