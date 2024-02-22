///////////////////////////////////////////
// sha512sig1l.sv
//
// Written: ryan.swann@okstate.edu, kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: sha512sig1l instruction
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

module sha512sig1l(input logic [31:0] rs1,
                   input logic [31:0]  rs2,
                   output logic [31:0] data_out);
                  
   // rs1 shift logic
   logic [31:0] 		       shift3;
   logic [31:0] 		       shift6;
   logic [31:0] 		       shift19;
   
   // rs2 shift logics         
   logic [31:0] 		       shift29;
   logic [31:0] 		       shift26;
   logic [31:0] 		       shift13;    
   
   // Shift rs1
   assign shift3 = rs1 << 3;
   assign shift6 = rs1 >> 6;
   assign shift19 = rs1 >> 19;
   
   // Shift rs2
   assign shift29 = rs2 >> 29;
   assign shift26 = rs2 << 26;
   assign shift13 = rs2 << 13;
   
   assign data_out = shift3 ^ shift6 ^ shift19 ^ shift29 ^ shift26 ^ shift13;
                            
endmodule