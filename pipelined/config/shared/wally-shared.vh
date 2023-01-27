//////////////////////////////////////////
// wally-shared.vh
//
// Written: david_harris@hmc.edu 7 June 2021
//
// Purpose: Shared and default configuration values common to all designs
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

// division constants
`define RADIX 32'h4
`define DIVCOPIES 32'h4

// eventually move to each config
`define ZBA_SUPPORTED 0
`define ZBB_SUPPORTED 0
`define ZBC_SUPPORTED 0
`define ZBS_SUPPORTED 0

// Memory synthesis configuration
`define USE_SRAM 0

// shared constants
`include "wally-constants.vh"

