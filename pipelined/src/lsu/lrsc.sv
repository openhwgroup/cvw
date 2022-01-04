///////////////////////////////////////////
// lrsc.sv
//
// Written: David_Harris@hmc.edu 17 July 2021
// Modified: 
//
// Purpose: Load Reserved / Store Conditional unit
//          Track the reservation and squash the store if it fails
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

module lrsc
  (
    input  logic                clk, reset,
    input  logic                FlushW, CPUBusy,
    input  logic                MemReadM,
    input  logic [1:0]          PreLsuRWM,
    output logic [1:0]          LsuRWM,
    input  logic [1:0] 	        LsuAtomicM,
    input  logic [`PA_BITS-1:0] LsuPAdrM,  // from mmu to dcache
    output logic                SquashSCW
);
  // Handle atomic load reserved / store conditional
  logic [`PA_BITS-1:2] 			ReservationPAdrW;
  logic 						ReservationValidM, ReservationValidW; 
  logic 						lrM, scM, WriteAdrMatchM;
  logic 						SquashSCM;

  assign lrM = MemReadM & LsuAtomicM[0];
  assign scM = PreLsuRWM[0] & LsuAtomicM[0]; 
  assign WriteAdrMatchM = PreLsuRWM[0] & (LsuPAdrM[`PA_BITS-1:2] == ReservationPAdrW) & ReservationValidW;
  assign SquashSCM = scM & ~WriteAdrMatchM;
  assign LsuRWM = SquashSCM ? 2'b00 : PreLsuRWM;
  always_comb begin // ReservationValidM (next value of valid reservation)
    if (lrM) ReservationValidM = 1;  // set valid on load reserve
    else if (scM | WriteAdrMatchM) ReservationValidM = 0; // clear valid on store to same address or any sc
    else ReservationValidM = ReservationValidW; // otherwise don't change valid
  end
  flopenrc #(`PA_BITS-2) resadrreg(clk, reset, FlushW, lrM, LsuPAdrM[`PA_BITS-1:2], ReservationPAdrW); // could drop clear on this one but not valid
  flopenrc #(1) resvldreg(clk, reset, FlushW, lrM, ReservationValidM, ReservationValidW);
  flopenrc #(1) squashreg(clk, reset, FlushW, ~CPUBusy, SquashSCM, SquashSCW);
endmodule
