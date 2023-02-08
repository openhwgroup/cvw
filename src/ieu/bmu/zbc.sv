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
  logic [WIDTH-1:0] X,Y;


  genvar i;
  

  bitreverse brA(.a(A), .b(RevA));
  bitreverse brB(.a(B), .b(RevB));
   
  //NOTE: Is it better to mux in input to a SINGLE clmul or to instantiate 3 clmul and MUX the result?
  //current implementation CP goes MUX -> CLMUL -> MUX -> RESULT
  //alternate could have CLMUL * 3 -> MUX -> MUX
  always_comb begin
    casez (Funct3)
      3'b001: begin //clmul
        X = A;
        Y = B;
      end
      3'b011: begin //clmulh
        X = {RevA[WIDTH-2:0], {1'b0}};
        Y = {{1'b0}, RevB[WIDTH-2:0]};
      end
      3'b010: begin //clmulr
        X = {A[WIDTH-2:0], {1'b0}};
        Y = B;
      end
      default: begin
        X = 0;
        Y = 0;
      end
    endcase
    
  end
  clmul clm(.A(X), .B(Y), .ClmulResult(ClmulResult));
  bitreverse brClmulResult(.a(ClmulResult), .b(RevClmulResult));

  assign ZBCResult = (Funct3 == 3'b011) ? RevClmulResult : ClmulResult;


endmodule