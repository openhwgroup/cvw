///////////////////////////////////////////
// vm64check.sv
//
// Written: David_Harris@hmc.edu 4 November 2022
// Modified: 
//
// Purpose: Check for good upper address bits in RV64 mode
// 
// Documentation: RISC-V System on Chip Design Chapter 8
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

module vm64check (
  input  logic [`SVMODE_BITS-1:0] SATP_MODE,
  input  logic [`XLEN-1:0]        VAdr,
  output logic                    SV39Mode, 
  output logic                    UpperBitsUnequalPageFault
);

  if (`XLEN == 64) begin
    assign SV39Mode = (SATP_MODE == `SV39);

    // page fault if upper bits aren't all the same
    logic                           eq_63_47, eq_46_38;
    assign eq_46_38 = &(VAdr[46:38]) | ~|(VAdr[46:38]);
    assign eq_63_47 = &(VAdr[63:47]) | ~|(VAdr[63:47]); 
    assign UpperBitsUnequalPageFault = SV39Mode ? ~(eq_63_47 & eq_46_38) : ~eq_63_47;
  end else begin
    assign SV39Mode = 0;
    assign UpperBitsUnequalPageFault = 0;
  end
endmodule
