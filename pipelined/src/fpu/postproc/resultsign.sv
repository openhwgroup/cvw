///////////////////////////////////////////
// resultsign.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: calculating the result's sign
// 
// A component of the CORE-V Wally configurable RISC-V project.
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

module resultsign(
    input logic [2:0]   Frm,
    input logic         FmaPs, FmaAs,
    input logic         ZInf,
    input logic         InfIn,
    input logic         FmaOp,
    input logic         FmaSZero,
    input logic         Mult,
    input logic         Round,
    input logic         Sticky,
    input logic         Guard,
    input logic         Ms,
    output logic        Rs
);

    logic Zeros;
    logic Infs;

    // The IEEE754-2019 standard specifies: 
    //      - the sign of an exact zero sum (with operands of diffrent signs) should be positive unless rounding toward negitive infinity
    //      - when the exact result of an FMA opperation is non-zero, but is zero due to rounding, use the sign of the exact result
    //      - if x = +0 or -0 then x+x=x and x-(-x)=x 
    //      - the sign of a product is the exclisive or or the opperand's signs
    // Zero sign will only be selected if:
    //      - P=Z and a cancelation occurs - exact zero
    //      - Z is zero and P is zero - exact zero
    //      - P is killed and Z is zero - Psgn
    //      - Z is killed and P is zero - impossible
    // Zero sign calculation:
    //      - if a multiply opperation is done, then use the products sign(Ps)
    //      - if the zero sum is not exactly zero i.e. Round|Sticky use the sign of the exact result (which is the product's sign)
    //      - if an effective addition occurs (P+A or -P+-A or P--A) then use the product's sign
    assign Zeros = (FmaPs^FmaAs)&~(Round|Guard|Sticky)&~Mult ? Frm[1:0] == 2'b10 : FmaPs;


    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign Infs = ZInf ? FmaAs : FmaPs;
    always_comb
        if(InfIn&FmaOp) Rs = Infs;
        else if(FmaSZero&FmaOp) Rs = Zeros;
        else Rs = Ms;

endmodule