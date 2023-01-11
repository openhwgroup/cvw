///////////////////////////////////////////
// adrdec.sv
//
// Written: David_Harris@hmc.edu 29 January 2021
// Modified: 
//
// Purpose: Address decoder
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

module adrdec (
  input  logic [`PA_BITS-1:0] PhysicalAddress,
  input  logic [`PA_BITS-1:0] Base, Range,
  input  logic                Supported,
  input  logic                AccessValid,
  input  logic [1:0]          Size,
  input  logic [3:0]          SizeMask,
  output logic                Sel
);

  logic Match;
  logic SizeValid;

  // determine if an address is in a range starting at the base
  // for example, if Base = 0x04002000 and range = 0x00000FFF,
  // then anything address between 0x04002000 and 0x04002FFF should match (HSEL=1)
  assign Match = &((PhysicalAddress ~^ Base) | Range);

  // determine if legal size of access is being made (byte, halfword, word, doubleword)
  assign SizeValid = SizeMask[Size]; 
  
  assign Sel = Match & Supported & AccessValid & SizeValid;

endmodule

