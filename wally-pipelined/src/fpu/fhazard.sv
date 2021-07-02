///////////////////////////////////////////
// fpuhazard.sv
//
// Written: me@KatherineParry.com 19 May 2021
// Modified: 
//
// Purpose: Determine forwarding, stalls and flushes for the FPU
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

module fhazard(
    input logic [4:0] Adr1E, Adr2E, Adr3E,
    input logic FWriteEnM, FWriteEnW, 
	  input logic [4:0] RdM, RdW,
    input logic [2:0] FResultSelM,
    output logic FStallD,
    output logic [1:0] ForwardXE, ForwardYE, ForwardZE
);


  always_comb begin
    // set ReadData as default
    ForwardXE = 2'b00; // choose FRD1E
    ForwardYE = 2'b00; // choose FRD2E
    ForwardZE = 2'b00; // choose FRD3E
    FStallD = 0;

      if ((Adr1E == RdM) & FWriteEnM)
      // if the result will be FResM
        if(FResultSelM == 3'b100) ForwardXE = 2'b10; // choose FResM
        else FStallD = 1;   // if the result won't be ready stall
      else if ((Adr1E == RdW) & FWriteEnW) ForwardXE = 2'b01; // choose FPUResult64W
    

      if ((Adr2E == RdM) & FWriteEnM)
      // if the result will be FResM
        if(FResultSelM == 3'b100) ForwardYE = 2'b10; // choose FResM
        else FStallD = 1;   // if the result won't be ready stall
      else if ((Adr2E == RdW) & FWriteEnW) ForwardYE = 2'b01; // choose FPUResult64W

 
      if ((Adr3E == RdM) & FWriteEnM)
      // if the result will be FResM
        if(FResultSelM == 3'b100) ForwardZE = 2'b10; // choose FResM
        else FStallD = 1;   // if the result won't be ready stall
      else if ((Adr3E == RdW) & FWriteEnW) ForwardZE = 2'b01; // choose FPUResult64W

  end 

endmodule
