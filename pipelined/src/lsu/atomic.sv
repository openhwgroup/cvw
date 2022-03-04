///////////////////////////////////////////
// atomic.sv
//
// Written: Ross Thompson ross1728@gmail.com January 31, 2022
// Modified:
//
// Purpose: atomic data path.
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

module atomic (
  input logic                clk,
  input logic                reset, FlushW, CPUBusy,
  input logic [`XLEN-1:0]    ReadDataM,
  input logic [`XLEN-1:0]    LSUWriteDataM, 
  input logic [`PA_BITS-1:0] LSUPAdrM,
  input logic [6:0]          LSUFunct7M,
  input logic [2:0]          LSUFunct3M,
  input logic [1:0]          LSUAtomicM,
  input logic [1:0]          PreLSURWM,
  input logic                IgnoreRequest,
  input logic                DTLBMissM,
  output logic [`XLEN-1:0]   FinalAMOWriteDataM,
  output logic               SquashSCW,
  output logic [1:0]         LSURWM);

  logic [`XLEN-1:0] AMOResult;
  logic               MemReadM;

  amoalu amoalu(.srca(ReadDataM), .srcb(LSUWriteDataM), .funct(LSUFunct7M), .width(LSUFunct3M[1:0]), 
                .result(AMOResult));
  mux2 #(`XLEN) wdmux(LSUWriteDataM, AMOResult, LSUAtomicM[1], FinalAMOWriteDataM);
  assign MemReadM = PreLSURWM[1] & ~(IgnoreRequest) & ~DTLBMissM; // *** is DTLBMiss needed; might be par tof ignorerequest
  lrsc lrsc(.clk, .reset, .FlushW, .CPUBusy, .MemReadM, .PreLSURWM, .LSUAtomicM, .LSUPAdrM,
    .SquashSCW, .LSURWM);

endmodule  
