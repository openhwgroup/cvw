///////////////////////////////////////////
//
// Written: me@KatherineParry.com, David Harris
// Modified: 6/23/2021
//
// Purpose: Floating point multiply-accumulate of configurable size
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

module fma(
    input logic                 Xs, Ys, Zs,    // input's signs
    input logic  [`NE-1:0]      Xe, Ye, Ze,    // input's biased exponents in B(NE.0) format
    input logic  [`NF:0]        Xm, Ym, Zm,    // input's significands in U(0.NF) format
    input logic                 XZero, YZero, ZZero, // is the input zero
    input logic  [2:0]          FOpCtrl,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic  [`FMTBITS-1:0] Fmt,       // format of the result single double half or quad
    output logic [`NE+1:0]      Pe,       // the product's exponent B(NE+2.0) format; adds 2 bits to allow for size of number and negative sign
    output logic                ZmSticky,  // sticky bit that is calculated during alignment
    output logic                KillProd,  // set the product to zero before addition if the product is too small to matter
    output logic [3*`NF+5:0]    Sm,           // the positive sum's significand
    output logic                NegSum,        // was the sum negitive
    output logic                InvA,          // Was A inverted for effective subtraction (P-A or -P+A)
    output logic                As,       // the aligned addend's sign (modified Z sign for other opperations)
    output logic                Ps,          // the product's sign
    output logic [$clog2(3*`NF+7)-1:0]          NCnt        // normalization shift count
    );

    logic [2*`NF+1:0]   Pm;           // the product's significand in U(2.2Nf) format
    logic [3*`NF+5:0]   Am;     // addend aligned's mantissa for addition in U(NF+5.2NF+1)
    logic [3*`NF+6:0]   AmInv;   // aligned addend's mantissa possibly inverted
    logic [2*`NF+1:0]   PmKilled;      // the product's mantissa possibly killed
    logic [3*`NF+6:0]   PreSum, NegPreSum;  // positive and negitve versions of the sum
    ///////////////////////////////////////////////////////////////////////////////
    // Calculate the product
    //      - When multipliying two fp numbers, add the exponents
    //      - Subtract the bias (XExp + YExp has two biases, one from each exponent)
    //      - If the product is zero then kill the exponent
    //      - Multiply the mantissas
    ///////////////////////////////////////////////////////////////////////////////
   

   // calculate the product's exponent 
    expadd expadd(.Fmt, .Xe, .Ye, .XZero, .YZero, .Pe);

    // multiplication of the mantissa's
    mult mult(.Xm, .Ym, .Pm);
   
    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    align align(.Ze, .Zm, .XZero, .YZero, .ZZero, .Xe, .Ye,
                        .Am, .ZmSticky, .KillProd);
                        
    // calculate the signs and take the opperation into account
    sign sign(.FOpCtrl, .Xs, .Ys, .Zs, .Ps, .As);

    // ///////////////////////////////////////////////////////////////////////////////
    // // Addition/LZA
    // ///////////////////////////////////////////////////////////////////////////////
        
    add add(.Am, .Pm, .Ps, .As, .KillProd, .AmInv, .PmKilled, .NegSum, .PreSum, .NegPreSum, .InvA, .XZero, .YZero, .Sm);
    
    loa loa(.A(AmInv+{(3*`NF+6)'(0),InvA}), .P(PmKilled), .NCnt);
endmodule


module expadd(    
    input  logic [`FMTBITS-1:0] Fmt,          // format of the output: single double half quad
    input  logic [`NE-1:0]      Xe, Ye,  // input's exponents
    input  logic                XZero, YZero,        // are the inputs zero
    output logic [`NE+1:0]      Pe       // product's exponent B^(1023)NE+2
);

    // kill the exponent if the product is zero - either X or Y is 0
    assign Pe = ({2'b0, Xe} + {2'b0, Ye} - {2'b0, (`NE)'(`BIAS)})&{`NE+2{~(XZero|YZero)}};

endmodule





module mult(
    input logic [`NF:0] Xm, Ym,
    output logic [2*`NF+1:0] Pm
);
    assign Pm = Xm * Ym;
endmodule








module sign(    
    input  logic [2:0]  FOpCtrl,               // opperation contol
    input  logic        Xs, Ys, Zs,    // sign of the inputs
    output logic        Ps,     // the product's sign - takes opperation into account
    output logic        As   // aligned addend sign used in fma - takes opperation into account
);

    // Calculate the product's sign
    //      Negate product's sign if FNMADD or FNMSUB
    
    // flip is negation opperation
    assign Ps = Xs ^ Ys ^ (FOpCtrl[1]&~FOpCtrl[2]);
    // flip if subtraction
    assign As = Zs^FOpCtrl[0];

endmodule








module align(
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

    // Defualt Addition without shifting
    //          |   54'b0    |  106'b(product)  | 2'b0 |
    //          | addnend |

    // the 1'b0 before the added is because the product's mantissa has two bits before the binary point (xx.xxxxxxxxxx...)
    assign ZmPreshifted = {Zm,(3*`NF+5)'(0)};
    
    assign KillProd = ACnt[`NE+1]|XZero|YZero;
    assign KillZ = $signed(ACnt)>$signed((`NE+2)'(3)*(`NE+2)'(`NF)+(`NE+2)'(5));

    always_comb
        begin
        
        // If the product is too small to effect the sum, kill the product

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //  | addnend |
        if (KillProd) begin
            ZmShifted = ZmPreshifted;
            ZmSticky = ~(XZero|YZero);

        // If the addend is too small to effect the addition        
        //      - The addend has to shift two past the end of the addend to be considered too small
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







module add(
    input logic  [3*`NF+5:0]    Am, // aligned addend's mantissa for addition in U(NF+5.2NF+1)
    input logic  [2*`NF+1:0]    Pm,       // the product's mantissa
    input logic                 Ps, As,// the product sign and the alligend addeded's sign (Modified Z sign for other opperations)
    input logic                 KillProd,      // should the product be set to 0
    input logic                 XZero, YZero, // is the input zero
    output logic [3*`NF+6:0]    AmInv,  // aligned addend possibly inverted
    output logic [2*`NF+1:0]    PmKilled,     // the product's mantissa possibly killed
    output logic                NegSum,        // was the sum negitive
    output logic                InvA,          // do you invert the aligned addend
    output logic [3*`NF+5:0]    Sm,           // the positive sum
    output logic [3*`NF+6:0]    PreSum, NegPreSum// possibly negitive sum
);

    ///////////////////////////////////////////////////////////////////////////////
    // Addition
    ///////////////////////////////////////////////////////////////////////////////
   
    // Negate Z  when doing one of the following opperations:
    //      -prod +  Z
    //       prod -  Z
    assign InvA = As ^ Ps;

    // Choose an inverted or non-inverted addend - the one has to be added now for the LZA
    assign AmInv = InvA ? {1'b1, ~Am} : {1'b0, Am};
    // Kill the product if the product is too small to effect the addition (determined in fma1.sv)
    assign PmKilled = Pm&{2*`NF+2{~KillProd}};



    // Do the addition
    //      - calculate a positive and negitive sum in parallel
    assign PreSum = {{`NF+3{1'b0}}, PmKilled, 2'b0} + AmInv + {{3*`NF+6{1'b0}}, InvA};
    assign NegPreSum = {1'b0, Am} + {{`NF+3{1'b1}}, ~PmKilled, 2'b0} + {(3*`NF+7)'(4)};
     
    // Is the sum negitive
    assign NegSum = PreSum[3*`NF+6];

    // Choose the positive sum and accompanying LZA result.
    assign Sm = NegSum ? NegPreSum[3*`NF+5:0] : PreSum[3*`NF+5:0];
endmodule


module loa( // [Schmookler & Nowka, Leading zero anticipation and detection, IEEE Sym. Computer Arithmetic, 2001]
    input logic  [3*`NF+6:0] A,     // addend
    input logic  [2*`NF+1:0] P,     // product
    output logic [$clog2(3*`NF+7)-1:0]       NCnt   // normalization shift count for the positive result
    ); 
    
    logic [3*`NF+6:0] T;
    logic [3*`NF+6:0] G;
    logic [3*`NF+6:0] Z;
    logic [3*`NF+6:0] f;

    assign T[3*`NF+6:2*`NF+4] = A[3*`NF+6:2*`NF+4];
    assign G[3*`NF+6:2*`NF+4] = 0;
    assign Z[3*`NF+6:2*`NF+4] = ~A[3*`NF+6:2*`NF+4];
    assign T[2*`NF+3:2] = A[2*`NF+3:2]^P;
    assign G[2*`NF+3:2] = A[2*`NF+3:2]&P;
    assign Z[2*`NF+3:2] = ~A[2*`NF+3:2]&~P;
    assign T[1:0] = A[1:0];
    assign G[1:0] = 0;
    assign Z[1:0] = ~A[1:0];


    // Apply function to determine Leading pattern
    //      - note: the paper linked above uses the numbering system where 0 is the most significant bit
    //f[n] = ~T[n]&T[n-1]           note: n is the MSB
    //f[i] = (T[i+1]&(G[i]&~Z[i-1] | Z[i]&~G[i-1])) | (~T[i+1]&(Z[i]&~Z[i-1] | G[i]&~G[i-1]))
    assign f[3*`NF+6] = ~T[3*`NF+6]&T[3*`NF+5];
    assign f[3*`NF+5:0] = (T[3*`NF+6:1]&(G[3*`NF+5:0]&{~Z[3*`NF+4:0], 1'b0} | Z[3*`NF+5:0]&{~G[3*`NF+4:0], 1'b1})) | (~T[3*`NF+6:1]&(Z[3*`NF+5:0]&{~Z[3*`NF+4:0], 1'b0} | G[3*`NF+5:0]&{~G[3*`NF+4:0], 1'b1}));



    lzc #(3*`NF+7) lzc (.num(f), .ZeroCnt(NCnt));
  
endmodule
