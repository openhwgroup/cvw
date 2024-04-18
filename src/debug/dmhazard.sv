///////////////////////////////////////////
// dmhazard.sv
//
// Written: james.stine@okstate.edu 18 March 2024
// Modified: 
//
// Purpose: Determine stalls for the Debug Module
// 
// Documentation: RISC-V System on Chip Design 
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

module dmhazard(
  input  logic        HaltReq,                            // Put into debug mode per Debug Spec
  input  logic        StepReq,                            // Step through CPU per Debug Spec
  output logic        DMStallD                            // stall the decode stage
);

  // Decode-stage instruction source depends on result from execute stage instruction
  assign DMStallD = HaltReq | StepReq;
endmodule
