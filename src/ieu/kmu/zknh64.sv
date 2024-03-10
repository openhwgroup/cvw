///////////////////////////////////////////
// zknh64.sv
//
// Written: kelvin.tran@okstate.edu, james.stine@okstate.edu
// Created: 13 February 2024
//
// Purpose: RISC-V ZKNH 64-Bit top level unit
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

module zknh64 (input  logic [63:0] A, B, input  logic [3:0]  ZKNHSelect,
	       output logic [63:0] ZKNHResult);

   logic [63:0] 		   sha256sig0res;
   logic [63:0] 		   sha256sig1res;
   logic [63:0] 		   sha256sum0res;
   logic [63:0] 		   sha256sum1res;
   
   logic [63:0] 		   sha512sig0res;
   logic [63:0] 		   sha512sig1res;
   logic [63:0] 		   sha512sum0res;
   logic [63:0] 		   sha512sum1res;   
   
   sha256sig0 #(64) sha256sig0(A, sha256sig0res);
   sha256sig1 #(64) sha256sig1(A, sha256sig1res);
   sha256sum0 #(64) sha256sum0(A, sha256sum0res);
   sha256sum1 #(64) sha256sum1(A, sha256sum1res);
   sha512sig0 sha512sig0(A, sha512sig0res);
   sha512sig1 sha512sig1(A, sha512sig1res);
   sha512sum0 sha512sum0(A, sha512sum0res);
   sha512sum1 sha512sum1(A, sha512sum1res);
   
   // Result Select Mux
   always_comb begin
      casez(ZKNHSelect)
	4'b0000: ZKNHResult = sha256sig0res;
	4'b0001: ZKNHResult = sha256sig1res;
	4'b0010: ZKNHResult = sha256sum0res;
	4'b0011: ZKNHResult = sha256sum1res;
	4'b1010: ZKNHResult = sha512sig0res;
	4'b1011: ZKNHResult = sha512sig1res;
	4'b1100: ZKNHResult = sha512sum0res;
	4'b1101: ZKNHResult = sha512sum1res;
	default ZKNHResult = 0;
      endcase
   end
endmodule
