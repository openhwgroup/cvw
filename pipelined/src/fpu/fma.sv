///////////////////////////////////////////
//
// Written: Katherine Parry, David Harris
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
    input logic                 XSgnE, YSgnE, ZSgnE,    // input's signs
    input logic  [`NE-1:0]      XExpE, YExpE, ZExpE,    // biased exponents in B(NE.0) format
    input logic  [`NF:0]        XManE, YManE, ZManE,    // fractions in U(0.NF) format
    input logic                 XZeroE, YZeroE, ZZeroE, // is the input zero
    input logic  [2:0]          FOpCtrlE,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic  [`FMTBITS-1:0] FmtE,       // precision 1 = double 0 = single
    output logic [`NE+1:0]      ProdExpE,       // X exponent + Y exponent - bias in B(NE+2.0) format; adds 2 bits to allow for size of number and negative sign
    output logic                AddendStickyE,  // sticky bit that is calculated during alignment
    output logic                KillProdE,      // set the product to zero before addition if the product is too small to matter
    output logic [3*`NF+5:0]    SumE,           // the positive sum
    output logic                NegSumE,        // was the sum negitive
    output logic                InvZE,          // intert Z
    output logic                ZSgnEffE,       // the modified Z sign
    output logic                PSgnE,          // the product's sign
    output logic [$clog2(3*`NF+7)-1:0]          FmaNormCntE        // normalization shift cnt
    );

    logic [2*`NF+1:0]   ProdManE;           // 1.X frac * 1.Y frac in U(2.2Nf) format
    logic [3*`NF+5:0]   AlignedAddendE;     // Z aligned for addition in U(NF+5.2NF+1)
    logic [3*`NF+6:0]   AlignedAddendInv;   // aligned addend possibly inverted
    logic [2*`NF+1:0]   ProdManKilled;      // the product's mantissa possibly killed
    logic [3*`NF+6:0]   PreSum, NegPreSum;  // positive and negitve versions of the sum
    ///////////////////////////////////////////////////////////////////////////////
    // Calculate the product
    //      - When multipliying two fp numbers, add the exponents
    //      - Subtract the bias (XExp + YExp has two biases, one from each exponent)
    //      - If the product is zero then kill the exponent
    //      - Multiply the mantissas
    ///////////////////////////////////////////////////////////////////////////////
   

   // calculate the product's exponent 
    expadd expadd(.FmtE, .XExpE, .YExpE, .XZeroE, .YZeroE, .ProdExpE);

    // multiplication of the mantissa's
    mult mult(.XManE, .YManE, .ProdManE);
   
    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    align align(.ZExpE, .ZManE, .XZeroE, .YZeroE, .ZZeroE, .XExpE, .YExpE,
                        .AlignedAddendE, .AddendStickyE, .KillProdE);
                        
    // calculate the signs and take the opperation into account
    sign sign(.FOpCtrlE, .XSgnE, .YSgnE, .ZSgnE, .PSgnE, .ZSgnEffE);

    // ///////////////////////////////////////////////////////////////////////////////
    // // Addition/LZA
    // ///////////////////////////////////////////////////////////////////////////////
        
    add add(.AlignedAddendE, .ProdManE, .PSgnE, .ZSgnEffE, .KillProdE, .AlignedAddendInv, .ProdManKilled, .NegSumE, .PreSum, .NegPreSum, .InvZE, .XZeroE, .YZeroE);
    
    loa loa(.A(AlignedAddendInv+{(3*`NF+6)'(0),InvZE}), .P(ProdManKilled), .FmaNormCntE);

    // Choose the positive sum and accompanying LZA result.
    assign SumE = NegSumE ? NegPreSum[3*`NF+5:0] : PreSum[3*`NF+5:0];
endmodule


module expadd(    
    input  logic [`FMTBITS-1:0] FmtE,          // precision
    input  logic [`NE-1:0]      XExpE, YExpE,  // input exponents
    input  logic                XZeroE, YZeroE,        // are the inputs zero
    output logic [`NE+1:0]      ProdExpE       // product's exponent B^(1023)NE+2
);

    // kill the exponent if the product is zero - either X or Y is 0
    assign ProdExpE = ({2'b0, XExpE} + {2'b0, YExpE} - {2'b0, (`NE)'(`BIAS)})&{`NE+2{~(XZeroE|YZeroE)}};

endmodule





module mult(
    input logic [`NF:0] XManE, YManE,
    output logic [2*`NF+1:0] ProdManE
);
    assign ProdManE = XManE * YManE;
endmodule








module sign(    
    input  logic [2:0]  FOpCtrlE,               // precision
    input  logic        XSgnE, YSgnE, ZSgnE,    // are the inputs denormalized
    output logic        PSgnE,     // the product's sign - takes opperation into account
    output logic        ZSgnEffE   // Z sign used in fma - takes opperation into account
);

    // Calculate the product's sign
    //      Negate product's sign if FNMADD or FNMSUB
    
    // flip is negation opperation
    assign PSgnE = XSgnE ^ YSgnE ^ (FOpCtrlE[1]&~FOpCtrlE[2]);
    // flip if subtraction
    assign ZSgnEffE = ZSgnE^FOpCtrlE[0];

endmodule








module align(
    input logic  [`NE-1:0]      XExpE, YExpE, ZExpE,      // biased exponents in B(NE.0) format
    input logic  [`NF:0]        ZManE,      // fractions in U(0.NF) format]
    input logic                 XZeroE, YZeroE, ZZeroE, // is the input zero
    output logic [3*`NF+5:0]    AlignedAddendE, // Z aligned for addition in U(NF+5.2NF+1)
    output logic                AddendStickyE,  // Sticky bit calculated from the aliged addend
    output logic                KillProdE       // should the product be set to zero
);

    logic [`NE+1:0]     AlignCnt;           // how far to shift the addend to align with the product in Q(NE+2.0) format
    logic [4*`NF+5:0]   ZManShifted;        // output of the alignment shifter including sticky bits U(NF+5.3NF+1)
    logic [4*`NF+5:0]   ZManPreShifted;     // input to the alignment shifter U(NF+5.3NF+1)

    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    // determine the shift count for alignment
    //      - negitive means Z is larger, so shift Z left
    //      - positive means the product is larger, so shift Z right
    // This could have been done using ProdExpE, but AlignCnt is on the critical path so we replicate logic for speed
    assign AlignCnt = XZeroE|YZeroE ? -(`NE+2)'($unsigned(1)) : {2'b0, XExpE} + {2'b0, YExpE} - {2'b0, (`NE)'(`BIAS)} + (`NE+2)'(`NF)+3 - {2'b0, ZExpE};

    // Defualt Addition without shifting
    //          |   54'b0    |  106'b(product)  | 2'b0 |
    //          | addnend |

    // the 1'b0 before the added is because the product's mantissa has two bits before the binary point (xx.xxxxxxxxxx...)
    assign ZManPreShifted = {ZManE,(3*`NF+5)'(0)};
    always_comb
        begin
        
        // If the product is too small to effect the sum, kill the product

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //  | addnend |
        if ($signed(AlignCnt) < $signed((`NE+2)'(0))) begin
            KillProdE = 1;
            ZManShifted = ZManPreShifted;
            AddendStickyE = ~(XZeroE|YZeroE);

        // If the Addend is shifted right
        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //                                  | addnend |
        end else if ($signed(AlignCnt)<=$signed((`NE+2)'(3)*(`NE+2)'(`NF)+(`NE+2)'(5)))  begin
            KillProdE = 0;
            ZManShifted = ZManPreShifted >> AlignCnt;
            AddendStickyE = |(ZManShifted[`NF-1:0]);

        // If the addend is too small to effect the addition        
        //      - The addend has to shift two past the end of the addend to be considered too small
        //      - The 2 extra bits are needed for rounding

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //                                                      | addnend |
        end else begin
            KillProdE = 0;
            ZManShifted = 0;
            AddendStickyE = ~ZZeroE;

        end
    end

    assign AlignedAddendE = ZManShifted[4*`NF+5:`NF];

endmodule







module add(
    input logic  [3*`NF+5:0]    AlignedAddendE, // Z aligned for addition in U(NF+5.2NF+1)
    input logic  [2*`NF+1:0]    ProdManE,       // the product's mantissa
    input logic                 PSgnE, ZSgnEffE,// the product and modified Z signs
    input logic                 KillProdE,      // should the product be set to 0
    input logic                 XZeroE, YZeroE, // is the input zero
    output logic [3*`NF+6:0]    AlignedAddendInv,  // aligned addend possibly inverted
    output logic [2*`NF+1:0]    ProdManKilled,     // the product's mantissa possibly killed
    output logic                NegSumE,        // was the sum negitive
    output logic                InvZE,          // do you invert Z
    output logic [3*`NF+6:0]    PreSum, NegPreSum// possibly negitive sum
);

    ///////////////////////////////////////////////////////////////////////////////
    // Addition
    ///////////////////////////////////////////////////////////////////////////////
   
    // Negate Z  when doing one of the following opperations:
    //      -prod +  Z
    //       prod -  Z
    assign InvZE = ZSgnEffE ^ PSgnE;

    // Choose an inverted or non-inverted addend - the one has to be added now for the LZA
    assign AlignedAddendInv = InvZE ? {1'b1, ~AlignedAddendE} : {1'b0, AlignedAddendE};
    // Kill the product if the product is too small to effect the addition (determined in fma1.sv)
    assign ProdManKilled = ProdManE&{2*`NF+2{~KillProdE}};



    // Do the addition
    //      - calculate a positive and negitive sum in parallel
    assign PreSum = AlignedAddendInv + {{`NF+3{1'b0}}, ProdManKilled, 2'b0} + {{3*`NF+6{1'b0}}, InvZE};
    assign NegPreSum = XZeroE|YZeroE|KillProdE ? {1'b0, AlignedAddendE} : {1'b0, AlignedAddendE} + {{`NF+3{1'b1}}, ~ProdManKilled, 2'b0} + {(3*`NF+7)'(4)};
     
    // Is the sum negitive
    assign NegSumE = PreSum[3*`NF+6];

endmodule


module loa( //https://ieeexplore.ieee.org/abstract/document/930098
    input logic  [3*`NF+6:0] A,     // addend
    input logic  [2*`NF+1:0] P,     // product
    output logic [$clog2(3*`NF+7)-1:0]       FmaNormCntE   // normalization shift count for the positive result
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



    lzc #(3*`NF+7) lzc (.num(f), .ZeroCnt(FmaNormCntE));
  
endmodule
