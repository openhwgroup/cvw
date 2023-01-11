///////////////////////////////////////////
// negateintres.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Negate integer result
// 
// A component of the Wally configurable RISC-V project.
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

module negateintres(
    input logic         Xs,
    input logic [`NORMSHIFTSZ-1:0]  Shifted,
    input logic         Signed,
    input logic         Int64,
    input logic         Plus1,
    output logic [1:0]          CvtNegResMsbs,
    output logic [`XLEN+1:0]    CvtNegRes
);

    logic [2:0] CvtNegResMsbs3;
    
    // round and negate the positive res if needed
    assign CvtNegRes = Xs ? -({2'b0, Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`XLEN]}+{{`XLEN+1{1'b0}}, Plus1}) : {2'b0, Shifted[`NORMSHIFTSZ-1:`NORMSHIFTSZ-`XLEN]}+{{`XLEN+1{1'b0}}, Plus1};
    
    // select 2 most significant bits
    mux2 #(3) msb3mux(CvtNegRes[33:31], CvtNegRes[`XLEN+1:`XLEN-1], Int64, CvtNegResMsbs3);
    mux2 #(2) msb2mux(CvtNegResMsbs3[2:1], CvtNegResMsbs3[1:0], Signed, CvtNegResMsbs);
endmodule