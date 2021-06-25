///////////////////////////////////////////
// forward.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Determine datapath forwarding
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

module forward(
  // Detect hazards
  input logic [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
  input logic        MemReadE, MulDivE, CSRReadE,
  input logic        RegWriteM, RegWriteW,
  input logic        DivDoneE, DivBusyE,
  input logic	       FWriteIntE, FWriteIntM, FWriteIntW,
  input logic        SCE,
  // Forwarding controls
  output logic [1:0] ForwardAE, ForwardBE,
  output logic       FPUStallD, LoadStallD, MulDivStallD, CSRRdStallD
);
  
  always_comb begin
    ForwardAE = 2'b00;
    ForwardBE = 2'b00;
    if (Rs1E != 5'b0)
      if      ((Rs1E == RdM) & (RegWriteM|FWriteIntM)) ForwardAE = 2'b10;
      else if ((Rs1E == RdW) & (RegWriteW|FWriteIntW)) ForwardAE = 2'b01;
 
    if (Rs2E != 5'b0)
      if      ((Rs2E == RdM) & (RegWriteM|FWriteIntM)) ForwardBE = 2'b10;
      else if ((Rs2E == RdW) & (RegWriteW|FWriteIntW)) ForwardBE = 2'b01;
  end

  // Stall on dependent operations that finish in Mem Stage and can't bypass in time
   assign FPUStallD = FWriteIntE & ((Rs1D == RdE) | (Rs2D == RdE)); 
   assign LoadStallD = (MemReadE|SCE) & ((Rs1D == RdE) | (Rs2D == RdE));  
   assign MulDivStallD = MulDivE & ((Rs1D == RdE) | (Rs2D == RdE)) | MulDivE | DivBusyE; // *** extend with stalls for divide
   assign CSRRdStallD = CSRReadE & ((Rs1D == RdE) | (Rs2D == RdE));

endmodule
