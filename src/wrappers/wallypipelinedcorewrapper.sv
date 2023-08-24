///////////////////////////////////////////
// wallypipelinedcorewrapper.sv
//
// Written: Kevin Kim kekim@hmc.edu 21 August 2023
// Modified: 
//
// Purpose: A wrapper to set parameters.  Vivado cannot set the top level parameters because it only supports verilog,
//          not system verilog.
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

//`include "BranchPredictorType.vh"
`include "config.vh"

import cvw::*;

`include "parameter-defs.vh"
module wallypipelinedcorewrapper (
   input  logic                  clk, reset,
   // Privileged
   input  logic                  MTimerInt, MExtInt, SExtInt, MSwInt,
   input  logic [63:0]           MTIME_CLINT, 
   // Bus Interface
   input  logic [32-1:0]     HRDATA,
   input  logic                  HREADY, HRESP,
   output logic                  HCLK, HRESETn,
   output logic [34-1:0]  HADDR,
   output logic [32-1:0]     HWDATA,
   output logic [32/8-1:0]   HWSTRB,
   output logic                  HWRITE,
   output logic [2:0]            HSIZE,
   output logic [2:0]            HBURST,
   output logic [3:0]            HPROT,
   output logic [1:0]            HTRANS,
   output logic                  HMASTLOCK
);

  wallypipelinedcore  #(P) core(.*); 

endmodule
