///////////////////////////////////////////
// bmu.sv
//
// Written: kekim@g.hmc.edu, David_Harris@hmc.edu 20 January 2023
// Modified: 
//
// Purpose: Bit manipulation extensions Zba, Zbb, Zbc, Zbs
//          Single-cycle operation in Execute stage
// 
// Documentation: n/a
// See RISC-V Bit-Manipulation ISA-extensions
//     Version 1.0.0-38-g865e7a7, 2021-06-28: Release candidate
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

module bmu(
	input  logic [`XLEN-1:0] 	ForwardedSrcAE, ForwardedSrcBE, 	// inputs A and B from IEU forwarding mux output
  input  logic [31:0] 			InstrD,                           // instruction        
  output logic              BMUE,                             // bit manipulation instruction  								
	output logic [`XLEN-1:0] 	BMUResultE												// bit manipulation result
);



endmodule // mdu


