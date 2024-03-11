///////////////////////////////////////////
// aes64esm.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: aes64esm instruction: RV64 middle round encryption 
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
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

module aes64esm(
    input  logic [63:0] rs1,
    input  logic [63:0] rs2,
    output logic [63:0] DataOut
);
   
    logic [127:0] ShiftRowOut;
    logic [63:0]  SboxOut;
                
    // AES shiftrow unit
    aesshiftrow srow({rs2,rs1}, ShiftRowOut);
   
    // Apply substitution box to 2 lower words
    aessboxword sbox0(ShiftRowOut[31:0],  SboxOut[31:0]);
    aessboxword sbox1(ShiftRowOut[63:32], SboxOut[63:32]);
   
    // Apply mix columns operations
    aesmixcolumns mw0(SboxOut[31:0], DataOut[31:0]);
    aesmixcolumns mw1(SboxOut[63:32], DataOut[63:32]);    
endmodule
