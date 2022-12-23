///////////////////////////////////////////
// fhazard.sv
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

module fhazard(
    input  logic [4:0]  Adr1D, Adr2D, Adr3D,    // read data adresses
    input  logic [4:0]  Adr1E, Adr2E, Adr3E,    // read data adresses
    input  logic        FRegWriteE, FRegWriteM, FRegWriteW, // is the fp register being written to
    input  logic [4:0]  RdE, RdM, RdW,               // the adress being written to
    input  logic [1:0]  FResSelM,            // the result being selected
    input  logic        XEnD, YEnD, ZEnD,
    output logic        FPUStallD,                // stall the decode stage
    output logic [1:0]  ForwardXE, ForwardYE, ForwardZE // select a forwarded value
);

  logic                 MatchDE;

  // Decode-stage instruction source depends on result from execute stage instruction
  assign MatchDE = ((Adr1D == RdE) & XEnD) | ((Adr2D == RdE) & YEnD) | ((Adr3D == RdE) & ZEnD);
  assign FPUStallD = MatchDE & FRegWriteE;
  
  always_comb begin
    // set defaults
    ForwardXE = 2'b00; // choose FRD1E
    ForwardYE = 2'b00; // choose FRD2E
    ForwardZE = 2'b00; // choose FRD3E

    // if the needed value is in the memory stage - input 1
    if ((Adr1E == RdM) & FRegWriteM) begin
      // if the result will be FResM (can be taken from the memory stage)
      if(FResSelM == 2'b00) ForwardXE = 2'b10; // choose FResM
      // if the needed value is in the writeback stage
    end else if ((Adr1E == RdW) & FRegWriteW) ForwardXE = 2'b01; // choose FPUResult64W
  

    // if the needed value is in the memory stage - input 2
    if ((Adr2E == RdM) & FRegWriteM) begin
      // if the result will be FResM (can be taken from the memory stage)
      if(FResSelM == 2'b00) ForwardYE = 2'b10; // choose FResM
      // if the needed value is in the writeback stage
    end else if ((Adr2E == RdW) & FRegWriteW) ForwardYE = 2'b01; // choose FPUResult64W


    // if the needed value is in the memory stage - input 3
    if ((Adr3E == RdM) & FRegWriteM) begin
      // if the result will be FResM (can be taken from the memory stage)
      if(FResSelM == 2'b00) ForwardZE = 2'b10; // choose FResM
      // if the needed value is in the writeback stage
    end else if ((Adr3E == RdW) & FRegWriteW) ForwardZE = 2'b01; // choose FPUResult64W

  end 

endmodule
