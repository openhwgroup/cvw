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

module fpuhazard(
    input logic [4:0] Adr1, Adr2, Adr3,
    input logic FWriteEnE, FWriteEnM, FWriteEnW, 
	  input logic [4:0] RdE, RdM, RdW,
	  input logic DivBusyM,
	  input logic	RegWriteD,
    input logic [2:0] FResultSelD, FResultSelE,
    input logic IllegalFPUInstrD,
    input logic FInput2UsedD, FInput3UsedD,
  // Stall outputs
	  output logic FStallD,
    output logic [1:0] FForwardInput1D, FForwardInput2D, 
    output logic FForwardInput3D
);


  always_comb begin
    // set ReadData as default
    FForwardInput1D = 2'b00; 
    FForwardInput2D = 2'b00;
    FForwardInput3D = 1'b0;
    FStallD = DivBusyM;
    if (~IllegalFPUInstrD) begin
//					if taking a value from int register
      if ((Adr1 == RdE) & (FWriteEnE | ((FResultSelE == 3'b110) & RegWriteD))) 
        if (FResultSelE == 3'b110) FForwardInput1D = 2'b11; // choose SrcAM
        else FStallD = 1'b1;                           // otherwise stall
      else if ((Adr1 == RdM) & FWriteEnM) FForwardInput1D = 2'b01; // choose FPUResultDirW
      else if ((Adr1 == RdW) & FWriteEnW) FForwardInput1D = 2'b11; // choose FPUResultDirE
    

      if(FInput2UsedD)
        if      ((Adr2 == RdE) & FWriteEnE) FStallD = 1'b1;
        else if ((Adr2 == RdM) & FWriteEnM) FForwardInput2D = 2'b01; // choose FPUResultDirW
        else if ((Adr2 == RdW) & FWriteEnW) FForwardInput2D = 2'b10; // choose FPUResultDirE


      if(FInput3UsedD)
        if      ((Adr3 == RdE) & FWriteEnE) FStallD = 1'b1;
        else if ((Adr3 == RdM) & FWriteEnM) FStallD = 1'b1;
        else if ((Adr3 == RdW) & FWriteEnW) FForwardInput3D = 1'b1; // choose FPUResultDirE
    end

  end 

endmodule
