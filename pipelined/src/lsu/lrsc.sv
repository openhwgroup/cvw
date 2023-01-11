///////////////////////////////////////////
// lrsc.sv
//
// Written: David_Harris@hmc.edu 17 July 2021
// Modified: 
//
// Purpose: Load Reserved / Store Conditional unit
//          Track the reservation and squash the store if it fails
// 
// A component of the CORE-V Wally configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module lrsc
  (
    input  logic                clk, reset,
    input  logic                StallW,
    input  logic                MemReadM,
    input  logic [1:0]          PreLSURWM,
    output logic [1:0]          LSURWM,
    input  logic [1:0] 	        LSUAtomicM,
    input  logic [`PA_BITS-1:0] PAdrM,  // from mmu to dcache
    output logic                SquashSCW
);
  // Handle atomic load reserved / store conditional
  logic [`PA_BITS-1:2] 			ReservationPAdrW;
  logic 						ReservationValidM, ReservationValidW; 
  logic 						lrM, scM, WriteAdrMatchM;
  logic 						SquashSCM;

  assign lrM = MemReadM & LSUAtomicM[0];
  assign scM = PreLSURWM[0] & LSUAtomicM[0]; 
  assign WriteAdrMatchM = PreLSURWM[0] & (PAdrM[`PA_BITS-1:2] == ReservationPAdrW) & ReservationValidW;
  assign SquashSCM = scM & ~WriteAdrMatchM;
  assign LSURWM = SquashSCM ? 2'b00 : PreLSURWM;
  always_comb begin // ReservationValidM (next value of valid reservation)
    if (lrM) ReservationValidM = 1;  // set valid on load reserve
	// if we implement multiple harts invalidate reservation if another hart stores to this reservation.
    else if (scM) ReservationValidM = 0; // clear valid on store to same address or any sc
    else ReservationValidM = ReservationValidW; // otherwise don't change valid
  end
  flopenr #(`PA_BITS-2) resadrreg(clk, reset, lrM & ~StallW, PAdrM[`PA_BITS-1:2], ReservationPAdrW); // could drop clear on this one but not valid
  flopenr #(1) resvldreg(clk, reset, ~StallW, ReservationValidM, ReservationValidW);
  flopenr #(1) squashreg(clk, reset, ~StallW, SquashSCM, SquashSCW);
endmodule
