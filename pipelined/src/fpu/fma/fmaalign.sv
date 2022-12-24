
///////////////////////////////////////////
// fmaalign.sv
//
// Written:  6/23/2021 me@KatherineParry.com, David_Harris@hmc.edu
// Modified: 
//
// Purpose: FMA alginment shift
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

module fmaalign(
    input logic  [`NE-1:0]      Xe, Ye, Ze,      // biased exponents in B(NE.0) format
    input logic  [`NF:0]        Zm,      // significand in U(0.NF) format]
    input logic                 XZero, YZero, ZZero, // is the input zero
    output logic [3*`NF+5:0]    Am, // addend aligned for addition in U(NF+5.2NF+1)
    output logic                ZmSticky,  // Sticky bit calculated from the aliged addend
    output logic                KillProd       // should the product be set to zero
);

    logic [`NE+1:0]     ACnt;           // how far to shift the addend to align with the product in Q(NE+2.0) format
    logic [4*`NF+5:0]   ZmShifted;        // output of the alignment shifter including sticky bits U(NF+5.3NF+1)
    logic [4*`NF+5:0]   ZmPreshifted;     // input to the alignment shifter U(NF+5.3NF+1)
    logic KillZ;

    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    // determine the shift count for alignment
    //      - negitive means Z is larger, so shift Z left
    //      - positive means the product is larger, so shift Z right
    // This could have been done using Pe, but ACnt is on the critical path so we replicate logic for speed
    assign ACnt = {2'b0, Xe} + {2'b0, Ye} - {2'b0, (`NE)'(`BIAS)} + (`NE+2)'(`NF+3) - {2'b0, Ze};

    // Defualt Addition with only inital left shift
    //          |   54'b0    |  106'b(product)  | 2'b0 |
    //          | addnend |

    assign ZmPreshifted = {Zm,(3*`NF+5)'(0)};
    
    assign KillProd = (ACnt[`NE+1]&~ZZero)|XZero|YZero;
    assign KillZ = $signed(ACnt)>$signed((`NE+2)'(3)*(`NE+2)'(`NF)+(`NE+2)'(5));

    always_comb
        begin
        
        // If the product is too small to effect the sum, kill the product

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //  | addnend |
        if (KillProd) begin
            ZmShifted = {(`NF+3)'(0), Zm, (2*`NF+2)'(0)};
            ZmSticky = ~(XZero|YZero);

        // If the addend is too small to effect the addition        
        //      - The addend has to shift two past the end of the product to be considered too small
        //      - The 2 extra bits are needed for rounding

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //                                                      | addnend |
        end else if (KillZ)  begin
            ZmShifted = 0;
            ZmSticky = ~ZZero;

        // If the Addend is shifted right
        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //                                  | addnend |
        end else begin
            ZmShifted = ZmPreshifted >> ACnt;
            ZmSticky = |(ZmShifted[`NF-1:0]);

        end
    end

    assign Am = ZmShifted[4*`NF+5:`NF];

endmodule

