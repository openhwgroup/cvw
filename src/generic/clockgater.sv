///////////////////////////////////////////
// clockgater.sv
//
// Written: Ross Thompson 9 January 2021
// Modified: 
//
// Purpose: Clock gater model. Must use standard cell for synthesis.
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

module clockgater #(parameter FPGA) (
  input  logic E,
  input  logic SE,
  input  logic CLK,
  output logic ECLK
);

  if (FPGA) BUFGCE bufgce_i0 (.I(CLK), .CE(E | SE), .O(ECLK));
  else begin
    // *** BUG 
    // VERY IMPORTANT.
    // This part functionally models a clock gater, but does not necessarily meet the timing constrains a real standard cell would.
    // Do not use this in synthesis!
    logic   enable_q;
    always_latch begin
      if(~CLK) begin
        enable_q <= E | SE;
      end
    end
    assign ECLK = enable_q & CLK;
  end    

endmodule
