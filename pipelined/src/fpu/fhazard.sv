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
    input logic [4:0]   Adr1E, Adr2E, Adr3E,    // read data adresses
    input logic         FRegWriteM, FRegWriteW, // is the fp register being written to
	  input logic [4:0]   RdM, RdW,               // the adress being written to
    input logic [1:0]   FResultSelM,            // the result being selected
    output logic        FStallD,                // stall the decode stage
    output logic [1:0]  FForwardXE, FForwardYE, FForwardZE // select a forwarded value
);


  always_comb begin
    // set defaults
    FForwardXE = 2'b00; // choose FRD1E
    FForwardYE = 2'b00; // choose FRD2E
    FForwardZE = 2'b00; // choose FRD3E
    FStallD = 0;

    // if the needed value is in the memory stage - input 1
    if ((Adr1E == RdM) & FRegWriteM) 
      // if the result will be FResM (can be taken from the memory stage)
      if(FResultSelM == 2'b11) FForwardXE = 2'b10; // choose FResM
      else FStallD = 1;                             // otherwise stall
    // if the needed value is in the writeback stage
    else if ((Adr1E == RdW) & FRegWriteW) FForwardXE = 2'b01; // choose FPUResult64W
  

    // if the needed value is in the memory stage - input 2
    if ((Adr2E == RdM) & FRegWriteM)
      // if the result will be FResM (can be taken from the memory stage)
      if(FResultSelM == 2'b11) FForwardYE = 2'b10; // choose FResM
      else FStallD = 1;                             // otherwise stall
    // if the needed value is in the writeback stage
    else if ((Adr2E == RdW) & FRegWriteW) FForwardYE = 2'b01; // choose FPUResult64W


    // if the needed value is in the memory stage - input 3
    if ((Adr3E == RdM) & FRegWriteM)
      // if the result will be FResM (can be taken from the memory stage)
      if(FResultSelM == 2'b11) FForwardZE = 2'b10; // choose FResM
      else FStallD = 1;                             // otherwise stall
    // if the needed value is in the writeback stage
    else if ((Adr3E == RdW) & FRegWriteW) FForwardZE = 2'b01; // choose FPUResult64W

  end 

endmodule
