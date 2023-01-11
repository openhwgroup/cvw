///////////////////////////////////////////
// fmalza.sv
//
// Written:  6/23/2021 me@KatherineParry.com, David_Harris@hmc.edu
// Modified: 
//
// Purpose: Leading Zero Anticipator
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

module fmalza #(WIDTH) ( // [Schmookler & Nowka, Leading zero anticipation and detection, IEEE Sym. Computer Arithmetic, 2001]
    input logic [WIDTH-1:0]             A,      // addend
    input logic [2*`NF+2:0]             Pm,     // product
    input logic 		                Cin,    // carry in
    input logic                         sub,
    output logic [$clog2(WIDTH+1)-1:0]  SCnt    // normalization shift count for the positive result
    ); 

   logic [WIDTH:0] 	       F;
   logic [WIDTH-1:0]  B, P, Guard, K;
    logic [WIDTH-1:0] Pp1, Gm1, Km1;

    assign B = {{(`NF+1){1'b0}}, Pm}; // Zero extend product

    assign P = A^B;
    assign Guard = A&B;
    assign K= ~A&~B;

   assign Pp1 = {sub, P[WIDTH-1:1]};
   assign Gm1 = {Guard[WIDTH-2:0], Cin};
   assign Km1 = {K[WIDTH-2:0], ~Cin};
   
    // Apply function to determine Leading pattern
    //      - note: the paper linked above uses the numbering system where 0 is the most significant bit
    assign F[WIDTH] = ~sub&P[WIDTH-1];
    assign F[WIDTH-1:0] = (Pp1&(Guard&~Km1 | K&~Gm1)) | (~Pp1&(K&~Km1 | Guard&~Gm1));

    lzc #(WIDTH+1) lzc (.num(F), .ZeroCnt(SCnt));
endmodule
