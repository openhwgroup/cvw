///////////////////////////////////////////
// mul.sv
//
// Written: David_Harris@hmc.edu 16 February 2021
// Modified: 
//
// Purpose: Integer multiplication
// 
// Documentation: RISC-V System on Chip Design Chapter 12 (Figure 12.18)
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

module mul(
  input  logic                clk, reset,
  input  logic                StallM, FlushM,
  input  logic [`XLEN-1:0]    ForwardedSrcAE, ForwardedSrcBE, // source A and B from after Forwarding mux
  input  logic [2:0]          Funct3E,                        // type of multiply
  output logic [`XLEN*2-1:0]  ProdM                           // double-widthproduct
);


  logic [`XLEN*2-1:0] PP1E, PP2E, PP3E, PP4E;               // partial products
  logic [`XLEN*2-1:0] PP1M, PP2M, PP3M, PP4M;               // registered partial proudcts
 
  //////////////////////////////
  // Execute Stage: Compute partial products
  //////////////////////////////

  // insert stuff here for lab 5

  //////////////////////////////
  // Memory Stage: Sum partial proudcts
  //////////////////////////////

  flopenrc #(`XLEN*2) PP1Reg(clk, reset, FlushM, ~StallM, PP1E, PP1M); 
  flopenrc #(`XLEN*2) PP2Reg(clk, reset, FlushM, ~StallM, PP2E, PP2M); 
  flopenrc #(`XLEN*2) PP3Reg(clk, reset, FlushM, ~StallM, PP3E, PP3M); 
  flopenrc #(`XLEN*2) PP4Reg(clk, reset, FlushM, ~StallM, PP4E, PP4M); 

  // add up partial products; this multi-input add implies CSAs and a final CPA
  assign ProdM = PP1M + PP2M + PP3M + PP4M; //ForwardedSrcAE * ForwardedSrcBE;
 endmodule

