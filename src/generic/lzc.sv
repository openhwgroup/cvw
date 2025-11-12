///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 11/12/2025 by marcus@infinitymdm.dev
//
// Purpose: Leading Zero Counter
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
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

module lzc #(parameter WIDTH = 1) (
  input  logic [WIDTH-1:0]           num,    // number to count the leading zeroes of
  output logic [$clog2(WIDTH+1)-1:0] ZeroCnt // the number of leading zeroes
);

  // Use a recursive binary tree structure to avoid unsynthesizable loops
  localparam LWIDTH = WIDTH - WIDTH/2; // May be 1 bit larger than WIDTH/2 due to floor division
  localparam RWIDTH = WIDTH/2;
  logic [LWIDTH-1:0] LNum;
  logic [RWIDTH-1:0] RNum;
  logic [$clog2(LWIDTH+1):0] LCnt;
  logic [$clog2(RWIDTH+1):0] RCnt;

  assign {LNum, RNum} = num;
  generate
    if (WIDTH == 1)
      assign ZeroCnt = ~num;
    else begin
      lzc #(LWIDTH) l_lcz (LNum, LCnt);
      lzc #(RWIDTH) r_lcz (RNum, RCnt);
      assign ZeroCnt = (LCnt == LWIDTH) ? LCnt + RCnt: LCnt;
    end
  endgenerate

endmodule

// Below is the prior version of this module. This works with Cadence Design Compiler and AMD
// Vivado 2024.1 but other tools (yosys 0.49, Intel Quartus Prime Lite 21.1.1, Cadence Jasper
// v2024.12, and possibly others) fail to synthesize the while loop.
//
// module lzc #(parameter WIDTH = 1) (
//   input  logic [WIDTH-1:0]            num,    // number to count the leading zeroes of
//   output logic [$clog2(WIDTH+1)-1:0]  ZeroCnt // the number of leading zeroes
// );
//
//   integer i;
//
//   always_comb begin
//     i = 0;
//     while ((i < WIDTH) & ~num[WIDTH-1-i]) i = i+1;  // search for leading one
//     ZeroCnt = i[$clog2(WIDTH+1)-1:0];
//   end
// endmodule
