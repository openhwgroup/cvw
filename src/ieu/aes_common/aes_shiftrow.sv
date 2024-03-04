///////////////////////////////////////////
// aes_shiftrow.sv
//
// Written: ryan.swann@okstate.edu, james.stine@okstate.edu
// Created: 20 February 2024
//
// Purpose: aes_shiftrow for taking in first Data line
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

module aes_Shiftrow (
   input  logic [127:0] DataIn,
	output logic [127:0] DataOut);
		    
   assign DataOut = {DataIn[95:88], DataIn[55:48], DataIn[15:8], DataIn[103:96],
                     DataIn[63:56], DataIn[23:16], DataIn[111:104], DataIn[71:64],
                     DataIn[31:24], DataIn[119:112], DataIn[79:72], DataIn[39:32],
                     DataIn[127:120], DataIn[87:80], DataIn[47:40], DataIn[7:0]};
   
endmodule
