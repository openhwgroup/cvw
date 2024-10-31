///////////////////////////////////////////
// watchdog.sv
//
// Written: Rose Thompson rose@rosethompson.net
// Modified: 14 June 2023
//
// Purpose: Detects if the processor is stuck and halts the simulation
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
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

module watchdog #(parameter XLEN, WatchDogTimerThreshold) 
  (input clk,
   input reset,
   string TEST
   );
  
  // check for hang up.
  logic [XLEN-1:0]      PCM, PCW, OldPCW;
  integer               WatchDogTimerCount;
  logic                 WatchDogTimeOut;

  flopenr #(XLEN) PCMReg(clk, reset, ~dut.core.ifu.StallM, dut.core.ifu.PCE, PCM); // duplicate PCM register because it is not in ifu for all configurations
  flopenr #(XLEN) PCWReg(clk, reset, ~dut.core.ieu.dp.StallW, PCM, PCW);

  always_ff @(posedge clk) begin
    OldPCW <= PCW;
    if(OldPCW == PCW) WatchDogTimerCount = WatchDogTimerCount + 1'b1;
    else WatchDogTimerCount = 0;
  end

  always_comb begin
    WatchDogTimeOut = WatchDogTimerCount >= WatchDogTimerThreshold;
    if(WatchDogTimeOut) begin
      if (TEST == "buildroot") $display("Watch Dog Time Out triggered.  This is a normal termination for a full buildroot boot.  Check sim/<simulator>/logs/buildroot_uart.log to check if the boot printed the login prompt.");
      else $display("FAILURE: Watch Dog Time Out triggered. PCW stuck at %x for more than %d cycles", PCW, WatchDogTimerCount);
      `ifdef QUESTA
        $stop;  // if this is changed to $finish for Questa, wally-batch.do does not go to the next step to run coverage, and wally.do terminates without allowing GUI debug
      `else
        $finish;
      `endif
    end
  end

endmodule
