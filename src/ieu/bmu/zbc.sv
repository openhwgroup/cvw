///////////////////////////////////////////
// zbc.sv
//
// Written: Kevin Kim <kekim@hmc.edu> and Kip Macsai-Goren <kmacsaigoren@hmc.edu>
// Created: 2 February 2023
// Modified: 
//
// Purpose: RISC-V single bit manipulation unit (ZBC instructions)
//
// Documentation: RISC-V System on Chip Design Chapter ***
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

module zbc #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B,       // Operands
  input  logic [2:0]       Funct3,     // Indicates operation to perform
  output logic [WIDTH-1:0] ZBCResult); // ZBC result

  logic [WIDTH-1:0] ClmulResult, RevClmulResult;
  logic [WIDTH-1:0] RevA, RevB;
  logic [WIDTH-1:0] x,y;

  bitreverse #(WIDTH) brA(.a(A), .b(RevA));
  bitreverse #(WIDTH) brB(.a(B), .b(RevB));
   
  // zbc input select mux
  always_comb begin
    casez (Funct3[1:0])
      2'b01: begin //clmul
        x = A;
        y = B;
      end
      2'b11: begin //clmulh
        x = {RevA[WIDTH-2:0], {1'b0}};
        y = {{1'b0}, RevB[WIDTH-2:0]};
      end
      2'b10: begin //clmulr
        x = RevA;
        y = RevB;
      end
      default: begin
        x = 0;
        y = 0;
      end
    endcase
    
  end
  clmul #(WIDTH) clm(.A(x), .B(y), .ClmulResult(ClmulResult));
  bitreverse  #(WIDTH) brClmulResult(.a(ClmulResult), .b(RevClmulResult));

  mux2 #(WIDTH) zbcresultmux(ClmulResult, RevClmulResult, Funct3[1], ZBCResult);


endmodule