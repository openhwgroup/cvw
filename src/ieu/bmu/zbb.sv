
///////////////////////////////////////////
// zbb.sv
//
// Written: Kevin Kim <kekim@hmc.edu> and Kip Macsai-Goren <kmacsaigoren@hmc.edu>
// Created: 2 February 2023
// Modified: 
//
// Purpose: RISC-V miscellaneous bit manipulation unit (subset of ZBB instructions)
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

module zbb #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B,         // Operands
  input  logic [2:0]       Funct3,       // Indicates operation to perform
  input  logic [6:0]       Funct7,       // Indicates operation to perform
  input  logic             W64,          // Indicates word operation
  output logic [WIDTH-1:0] ZBBResult);   // ZBB result


  
  // count results
  logic [WIDTH-1:0] czResult;            // count zeros result (lzc or tzc)
  logic [WIDTH-1:0] cpopResult;          // population count result

  // byte results
  logic [WIDTH-1:0] OrcBResult;
  logic [WIDTH-1:0] Rev8Result;

  // sign/zero extend results
  logic [WIDTH-1:0] sexthResult;         // sign extend halfword result
  logic [WIDTH-1:0] sextbResult;         // sign extend byte result
  logic [WIDTH-1:0] zexthResult;         // zero extend halfword result 

  cnt #(WIDTH) cnt(.A(A), .B(B), .W64(W64), .czResult(czResult), .cpopResult(cpopResult));
  byteUnit #(WIDTH) bu(.A(A), .OrcBResult(OrcBResult), .Rev8Result(Rev8Result));
  ext #(WIDTH) ext(.A(A), .sexthResult(sexthResult), .sextbResult(sextbResult), .zexthResult(zexthResult));

  //can replace with structural mux by looking at bit 4 in rs2 field
  always_comb begin 
      case ({Funct7, Funct3, B[4:0]})
      15'b0010100_101_00111: ZBBResult = OrcBResult;
      15'b0110100_101_11000: ZBBResult = Rev8Result;
      15'b0110101_101_11000: ZBBResult = Rev8Result;
      15'b0110000_001_00000: ZBBResult = czResult;
      15'b0110000_001_00010: ZBBResult = cpopResult;
      15'b0110000_001_00001: ZBBResult = czResult;
      15'b0000100_100_00000: ZBBResult = zexthResult; 
      15'b0110000_001_00100: ZBBResult = sextbResult;
      15'b0110000_001_00101: ZBBResult = sexthResult;
      default: ZBBResult = {(WIDTH){1'b0}};
      endcase
  end


endmodule