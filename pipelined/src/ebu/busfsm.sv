///////////////////////////////////////////
// busfsm.sv
//
// Written: Ross Thompson ross1728@gmail.com December 29, 2021
// Modified: 
//
// Purpose: Load/Store Unit's interface to BUS for cacheless system
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
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

// HCLK and clk must be the same clock!
module busfsm 
  (input logic        HCLK,
   input logic        HRESETn,

   // IEU interface
   input logic        Flush,
   input logic [1:0]  BusRW,
   input logic        Stall,
   output logic       BusCommitted,
   output logic       BusStall,
   output logic       CaptureEn,
   input logic        HREADY,
   output logic [1:0] HTRANS,
   output logic       HWRITE
);
  
  typedef enum logic [2:0] {ADR_PHASE,
				            DATA_PHASE,
				            MEM3} busstatetype;

  typedef enum logic [1:0] {AHB_IDLE = 2'b00, AHB_BUSY = 2'b01, AHB_NONSEQ = 2'b10, AHB_SEQ = 2'b11} ahbtranstype;

  (* mark_debug = "true" *) busstatetype CurrState, NextState;

  always_ff @(posedge HCLK)
    if (~HRESETn | Flush) CurrState <= #1 ADR_PHASE;
    else                  CurrState <= #1 NextState;  
  
  always_comb begin
	case(CurrState)
	  ADR_PHASE: if(HREADY & |BusRW) NextState = DATA_PHASE;
                 else             NextState = ADR_PHASE;
      DATA_PHASE: if(HREADY)      NextState = MEM3;
		          else            NextState = DATA_PHASE;
      MEM3: if(Stall)             NextState = MEM3;
		    else                  NextState = ADR_PHASE;
	  default:                    NextState = ADR_PHASE;
	endcase
  end

  assign BusStall = (CurrState == ADR_PHASE & |BusRW) |
//					(CurrState == DATA_PHASE & ~BusRW[0]); // possible optimization here.  fails uart test, but i'm not sure the failure is valid.
					(CurrState == DATA_PHASE); 
  
  assign BusCommitted = CurrState != ADR_PHASE;

  assign HTRANS = (CurrState == ADR_PHASE & HREADY & |BusRW & ~Flush) ? AHB_NONSEQ : AHB_IDLE;
  assign HWRITE = BusRW[0];
  assign CaptureEn = CurrState == DATA_PHASE;
  
endmodule
