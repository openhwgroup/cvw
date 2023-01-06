///////////////////////////////////////////
// resultsign.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: calculating the result's sign
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
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