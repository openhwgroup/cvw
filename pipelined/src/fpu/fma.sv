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
    input logic                 clk,
    input logic                 reset,
    input logic                 FlushM,     // flush the memory stage
    input logic                 StallM,     // stall memory stage
    input logic  [`FPSIZES/3:0] FmtE, FmtM, // precision 1 = double 0 = single
    input logic  [2:0]          FOpCtrlE,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic  [2:0]          FrmM,               // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic                 XSgnE, YSgnE, ZSgnE,    // input signs - execute stage
    input logic [`NE-1:0]       XExpE, YExpE, ZExpE,    // input exponents - execute stage
    input logic [`NF:0]         XManE, YManE, ZManE,    // input mantissa - execute stage
    input logic                 XSgnM, YSgnM,           // input signs - memory stage
    input logic [`NE-1:0]       ZExpM,    // input exponents - memory stage
    input logic [`NF:0]         XManM, YManM, ZManM,    // input mantissa - memory stage
    input logic                 ZOrigDenormE, // is the original precision denormalized
    input logic                 XDenormE, YDenormE, ZDenormE, // is denorm
    input logic                 XZeroE, YZeroE, ZZeroE,     // is zero - execute stage
    input logic                 XNaNM, YNaNM, ZNaNM,        // is NaN
    input logic                 XSNaNM, YSNaNM, ZSNaNM,     // is signaling NaN
    input logic                 XZeroM, YZeroM, ZZeroM,     // is zero - memory stage
    input logic                 XInfM, YInfM, ZInfM,        // is infinity
	output logic [`FLEN-1:0]    FMAResM,    // FMA result
	output logic [4:0]		    FMAFlgM);   // FMA flags
	
  //fma/mult/add	
      //  fmadd  = 000
      //  fmsub  = 001
      //  fnmsub = 010	-(a*b)+c
      //  fnmadd = 011  -(a*b)-c
      //  fmul   = 100
      //  fadd   = 110
      //  fsub   = 111

    // signals transfered between pipeline stages
    logic [3*`NF+5:0]	SumE, SumM;                       
    logic [`NE+1:0]	    ProdExpE, ProdExpM;
    logic 			    AddendStickyE, AddendStickyM;
    logic 			    KillProdE, KillProdM;
    logic 			    InvZE, InvZM;
    logic 			    NegSumE, NegSumM;
    logic 			    ZSgnEffE, ZSgnEffM;
    logic 			    PSgnE, PSgnM;
    logic [$clog2(3*`NF+7)-1:0]			NormCntE, NormCntM;
    logic               Mult;
    logic               ZOrigDenormM;
    
    fma1 fma1 (.XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE, 
                .XDenormE, .YDenormE, .ZDenormE,  .XZeroE, .YZeroE, .ZZeroE,
                .FOpCtrlE, .FmtE, .SumE, .NegSumE, .InvZE, .NormCntE, .ZSgnEffE, .PSgnE,
                .ProdExpE, .AddendStickyE, .KillProdE); 
                
    // E/M pipeline registers
    flopenrc #(3*`NF+6) EMRegFma2(clk, reset, FlushM, ~StallM, SumE, SumM); 
    flopenrc #(13) EMRegFma3(clk, reset, FlushM, ~StallM, ProdExpE, ProdExpM);  
    flopenrc #($clog2(3*`NF+7)+8) EMRegFma4(clk, reset, FlushM, ~StallM, 
                            {AddendStickyE, KillProdE, InvZE, NormCntE, NegSumE, ZSgnEffE, PSgnE, FOpCtrlE[2]&~FOpCtrlE[1]&~FOpCtrlE[0], ZOrigDenormE},
                            {AddendStickyM, KillProdM, InvZM, NormCntM, NegSumM, ZSgnEffM, PSgnM, Mult, ZOrigDenormM});

    fma2 fma2(.XSgnM, .YSgnM, .ZExpM, .XManM, .YManM, .ZManM, .ZOrigDenormM,
            .FrmM, .FmtM,  .ProdExpM, .AddendStickyM, .KillProdM, .SumM, .NegSumM, .InvZM, .NormCntM, .ZSgnEffM, .PSgnM,
            .XZeroM, .YZeroM, .ZZeroM, .XInfM, .YInfM, .ZInfM, .XNaNM, .YNaNM, .ZNaNM, .XSNaNM, .YSNaNM, .ZSNaNM, .Mult,
            .FMAResM, .FMAFlgM);

endmodule
      

        //*** in al units before putting into : ? put in a seperate signal

module fma1(
    input logic                 XSgnE, YSgnE, ZSgnE,    // input's signs
    input logic  [`NE-1:0]      XExpE, YExpE, ZExpE,    // biased exponents in B(NE.0) format
    input logic  [`NF:0]        XManE, YManE, ZManE,    // fractions in U(0.NF) format
    input logic                 XDenormE, YDenormE, ZDenormE, // is the input denormal
    input logic                 XZeroE, YZeroE, ZZeroE, // is the input zero
    input logic  [2:0]          FOpCtrlE,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic  [`FPSIZES/3:0] FmtE,       // precision 1 = double 0 = single
    output logic [`NE+1:0]      ProdExpE,       // X exponent + Y exponent - bias in B(NE+2.0) format; adds 2 bits to allow for size of number and negative sign
    output logic                AddendStickyE,  // sticky bit that is calculated during alignment
    output logic                KillProdE,      // set the product to zero before addition if the product is too small to matter
    output logic [3*`NF+5:0]    SumE,           // the positive sum
    output logic                NegSumE,        // was the sum negitive
    output logic                InvZE,          // intert Z
    output logic                ZSgnEffE,       // the modified Z sign
    output logic                PSgnE,          // the product's sign
    output logic [$clog2(3*`NF+7)-1:0]          NormCntE        // normalization shift cnt
    );

    logic [`NE-1:0]     Denorm;             // value of a denormaized number based on precision
    logic [2*`NF+1:0]   ProdManE;           // 1.X frac * 1.Y frac in U(2.2Nf) format
    logic [3*`NF+5:0]   AlignedAddendE;     // Z aligned for addition in U(NF+5.2NF+1)
    logic [3*`NF+6:0]   AlignedAddendInv;   // aligned addend possibly inverted
    logic [2*`NF+1:0]   ProdManKilled;      // the product's mantissa possibly killed
    logic [3*`NF+6:0]   PreSum, NegPreSum;  // positive and negitve versions of the sum
    logic [`NE-1:0]     XExpVal, YExpVal;   // exponent value after taking into accound denormals
    ///////////////////////////////////////////////////////////////////////////////
    // Calculate the product
    //      - When multipliying two fp numbers, add the exponents
    //      - Subtract the bias (XExp + YExp has two biases, one from each exponent)
    //      - If the product is zero then kill the exponent
    //      - Multiply the mantissas
    ///////////////////////////////////////////////////////////////////////////////
   

   // calculate the product's exponent 
    expadd expadd(.FmtE, .XExpE, .YExpE, .XZeroE, .YZeroE, .XDenormE, .YDenormE, .XExpVal, .YExpVal, 
                    .Denorm, .ProdExpE);

    // multiplication of the mantissa's
    mult mult(.XManE, .YManE, .ProdManE);
   
    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    align align(.ZExpE, .ZManE, .ZDenormE, .XZeroE, .YZeroE, .ZZeroE, .ProdExpE, .Denorm, .XExpVal, .YExpVal,
                        .AlignedAddendE, .AddendStickyE, .KillProdE);
                        
    // calculate the signs and take the opperation into account
    sign sign(.FOpCtrlE, .XSgnE, .YSgnE, .ZSgnE, .PSgnE, .ZSgnEffE);

    // ///////////////////////////////////////////////////////////////////////////////
    // // Addition/LZA
    // ///////////////////////////////////////////////////////////////////////////////
        
    add add(.AlignedAddendE, .ProdManE, .PSgnE, .ZSgnEffE, .KillProdE, .AlignedAddendInv, .ProdManKilled, .NegSumE, .PreSum, .NegPreSum, .InvZE, .XZeroE, .YZeroE);
    
    loa loa(.A(AlignedAddendInv+{(3*`NF+6)'(0),InvZE}), .P(ProdManKilled), .NormCntE);

    // Choose the positive sum and accompanying LZA result.
    assign SumE = NegSumE ? NegPreSum[3*`NF+5:0] : PreSum[3*`NF+5:0];


endmodule


module expadd(    
    input  logic [`FPSIZES/3:0] FmtE,          // precision
    input  logic [`NE-1:0]      XExpE, YExpE,  // input exponents
    input  logic                XDenormE, YDenormE,    // are the inputs denormalized
    input  logic                XZeroE, YZeroE,        // are the inputs zero
    output logic [`NE-1:0]      XExpVal, YExpVal,      // Exponent value after taking into account denormals
    output logic [`NE-1:0]      Denorm,        // value of denormalized exponent
    output logic [`NE+1:0]      ProdExpE       // product's exponent B^(1023)NE+2
);


    // denormalized numbers have diffrent values depending on which precison it is.
    //      FLEN - 1
    //      Other - BIAS - other bias + 1
    
    if (`FPSIZES == 1) begin
        assign Denorm = 1;

    end else if (`FPSIZES == 2) begin
        assign Denorm = FmtE ? (`NE)'(1) : (`NE)'(`BIAS)-(`NE)'(`BIAS1)+(`NE)'(1);

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (FmtE)
                `FMT: Denorm = 1;
                `FMT1: Denorm = `BIAS-`BIAS1+1;
                `FMT2: Denorm = `BIAS-`BIAS2+1;
                default: Denorm = 1'bx;
            endcase
        end

    end else if (`FPSIZES == 4) begin
        always_comb begin
            case (FmtE)
                2'h3: Denorm = 1;
                2'h1: Denorm = `BIAS-`D_BIAS+1;
                2'h0: Denorm = `BIAS-`S_BIAS+1;
                2'h2: Denorm = `BIAS-`H_BIAS+1;
            endcase
        end

    end

    // pick denormalized value or exponent
    assign XExpVal = XDenormE ? Denorm : XExpE;
    assign YExpVal = YDenormE ? Denorm : YExpE;
    // kill the exponent if the product is zero - either X or Y is 0
    assign ProdExpE = ({2'b0, XExpVal} + {2'b0, YExpVal} - {2'b0, (`NE)'(`BIAS)})&{`NE+2{~(XZeroE|YZeroE)}};

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
    input logic  [`NE-1:0]      ZExpE,      // biased exponents in B(NE.0) format
    input logic  [`NF:0]        ZManE,      // fractions in U(0.NF) format]
    input logic                 ZDenormE,   // is the input denormal
    input logic                 XZeroE, YZeroE, ZZeroE, // is the input zero
    input logic  [`NE-1:0]      XExpVal, YExpVal,       // Exponent value after taking into account denormals
    input logic  [`NE+1:0]      ProdExpE,       // the product's exponent
    input logic  [`NE-1:0]      Denorm,         // the biased value of a denormalized number
    output logic [3*`NF+5:0]    AlignedAddendE, // Z aligned for addition in U(NF+5.2NF+1)
    output logic                AddendStickyE,  // Sticky bit calculated from the aliged addend
    output logic                KillProdE       // should the product be set to zero
);

    logic [`NE+1:0]     AlignCnt;           // how far to shift the addend to align with the product in Q(NE+2.0) format
    logic [4*`NF+5:0]   ZManShifted;        // output of the alignment shifter including sticky bits U(NF+5.3NF+1)
    logic [4*`NF+5:0]   ZManPreShifted;     // input to the alignment shifter U(NF+5.3NF+1)
    logic [`NE-1:0]     ZExpVal;            // Exponent value after taking into account denormals

    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    // determine the shift count for alignment
    //      - negitive means Z is larger, so shift Z left
    //      - positive means the product is larger, so shift Z right
    //      - Denormal numbers have a diffrent exponent value depending on the precision
    assign ZExpVal = ZDenormE ? Denorm : ZExpE;
    // assign AlignCnt = ProdExpE - {2'b0, ZExpVal} + (`NF+3);
    // *** can we use ProdExpE instead of XExp/YExp to save an adder? DH 5/12/22
    assign AlignCnt = XZeroE|YZeroE ? -1 : {2'b0, XExpVal} + {2'b0, YExpVal} - {2'b0, (`NE)'(`BIAS)} + `NF+3 - {2'b0, ZExpVal};

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
    assign PreSum = AlignedAddendInv + {55'b0, ProdManKilled, 2'b0} + {{3*`NF+6{1'b0}}, InvZE};
    assign NegPreSum = XZeroE|YZeroE|KillProdE ? {1'b0, AlignedAddendE} : {1'b0, AlignedAddendE} + {{`NF+3{1'b1}}, ~ProdManKilled, 2'b0} + {(3*`NF+7)'(4)};
     
    // Is the sum negitive
    assign NegSumE = PreSum[3*`NF+6];

endmodule


module loa( //https://ieeexplore.ieee.org/abstract/document/930098
    input logic  [3*`NF+6:0] A,     // addend
    input logic  [2*`NF+1:0] P,     // product
    output logic [$clog2(3*`NF+7)-1:0]       NormCntE   // normalization shift count for the positive result
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



    lzc lzc(.f, .NormCntE);
  
endmodule

module lzc(
    input logic  [3*`NF+6:0]            f,
    output logic [$clog2(3*`NF+7)-1:0]    NormCntE    // normalization shift
);
    
    logic [$clog2(3*`NF+7)-1:0] i;
    always_comb begin
        i = 0;
        while (~f[3*`NF+6-i] & $unsigned(i) <= $unsigned($clog2(3*`NF+7)'(3)*($clog2(3*`NF+7))'(`NF)+($clog2(3*`NF+7))'(6))) i = i+1;  // search for leading one
        NormCntE = i;
    end
endmodule








module fma2(
    
    input logic                             XSgnM, YSgnM,        // input signs
    input logic     [`NE-1:0]               ZExpM, // input exponents
    input logic     [`NF:0]                 XManM, YManM, ZManM, // input mantissas
    input logic     [2:0]                   FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic     [`FPSIZES/3:0]          FmtM,       // precision 1 = double 0 = single
    input logic     [`NE+1:0]               ProdExpM,       // X exponent + Y exponent - bias
    input logic                             AddendStickyM,  // sticky bit that is calculated during alignment
    input logic                             KillProdM,      // set the product to zero before addition if the product is too small to matter
    input logic                             XZeroM, YZeroM, ZZeroM, // inputs are zero
    input logic                             XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                             XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic                             XSNaNM, YSNaNM, ZSNaNM, // inputs are signaling NaNs
    input logic     [3*`NF+5:0]             SumM,       // the positive sum
    input logic                             NegSumM,    // was the sum negitive
    input logic                             InvZM,      // do you invert Z
    input logic                             ZOrigDenormM, // is the original precision denormalized
    input logic                             ZSgnEffM,   // the modified Z sign - depends on instruction
    input logic                             PSgnM,      // the product's sign
    input logic                             Mult,       // multiply opperation
    input logic     [$clog2(3*`NF+7)-1:0]   NormCntM,   // the normalization shift count
    output logic    [`FLEN-1:0]             FMAResM,    // FMA final result
    output logic    [4:0]                   FMAFlgM);   // FMA flags {invalid, divide by zero, overflow, underflow, inexact}
   


    logic [`NF-1:0]     ResultFrac; // Result fraction
    logic [`NE-1:0]     ResultExp;  // Result exponent
    logic               ResultSgn, ResultSgnTmp;  // Result sign
    logic [`NE+1:0]     SumExp;     // exponent of the normalized sum
    logic [`NE+1:0]     FullResultExp;  // ResultExp with bits to determine sign and overflow
    logic [`NF+2:0]     NormSum;        // normalized sum
    logic               NormSumSticky;  // sticky bit calulated from the normalized sum
    logic               SumZero;        // is the sum zero
    logic               ResultDenorm;   // is the result denormalized
    logic               Sticky, UfSticky;           // Sticky bit
    logic               CalcPlus1;                  // do you add or subtract one for rounding
    logic               UfPlus1;                    // do you add one (for determining underflow flag)
    logic               Invalid,Underflow,Overflow; // flags
    logic               Guard, Round;   // bits needed to determine rounding
    logic               UfLSBNormSum;   // bits needed to determine rounding for underflow flag
    logic [`FLEN:0]     RoundAdd;       // how much to add to the result
   
    



    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////

    normalize normalize(.SumM, .ZExpM, .ProdExpM, .NormCntM, .FmtM, .KillProdM, .AddendStickyM, .NormSum, 
            .SumZero, .NormSumSticky, .UfSticky, .SumExp, .ResultDenorm);




    ///////////////////////////////////////////////////////////////////////////////
    // Rounding
    ///////////////////////////////////////////////////////////////////////////////

    // round to nearest even
    // round to zero
    // round to -infinity
    // round to infinity
    // round to nearest max magnitude

    fmaround fmaround(.FmtM, .FrmM, .Sticky, .UfSticky, .NormSum, .AddendStickyM, .NormSumSticky, .ZZeroM, .InvZM, .ResultSgnTmp, .SumExp,
        .CalcPlus1, .UfPlus1, .FullResultExp, .ResultFrac, .ResultExp, .Round, .Guard, .RoundAdd, .UfLSBNormSum);





    ///////////////////////////////////////////////////////////////////////////////
    // Sign calculation
    ///////////////////////////////////////////////////////////////////////////////

 
    resultsign resultsign(.FrmM, .PSgnM, .ZSgnEffM, .Underflow, .InvZM, .NegSumM, .SumZero, .Mult, .ResultSgnTmp, .ResultSgn);




    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////

    fmaflags fmaflags(.XSNaNM, .YSNaNM, .ZSNaNM, .XInfM, .YInfM, .ZInfM, .XZeroM, .YZeroM,
        .XNaNM, .YNaNM, .ZNaNM, .FullResultExp, .SumExp, .ZSgnEffM, .PSgnM, .Round, .Guard, .UfLSBNormSum, .Sticky, .UfPlus1,
        .FmtM, .Invalid, .Overflow, .Underflow, .FMAFlgM);




    ///////////////////////////////////////////////////////////////////////////////
    // Select the result
    ///////////////////////////////////////////////////////////////////////////////

    resultselect resultselect(.XSgnM, .YSgnM, .ZExpM, .XManM, .YManM, .ZManM, .ZOrigDenormM,
        .FrmM, .FmtM, .AddendStickyM, .KillProdM, .XInfM, .YInfM, .ZInfM, .XNaNM, .YNaNM, .ZNaNM, .RoundAdd,
        .ZSgnEffM, .PSgnM, .ResultSgn, .CalcPlus1, .Invalid, .Overflow, .Underflow, 
        .ResultDenorm, .ResultExp, .ResultFrac, .FMAResM);

// *** use NF where needed

endmodule

module resultsign(
    input logic [2:0]   FrmM,
    input logic         PSgnM, ZSgnEffM,
    input logic         Underflow,
    input logic         InvZM,
    input logic         NegSumM,
    input logic         SumZero,
    input logic         Mult,
    output logic        ResultSgnTmp,
    output logic        ResultSgn
);

    logic ZeroSgn;
    // logic ResultSgnTmp;

    // Determine the sign if the sum is zero
    //      if cancelation then 0 unless round to -infinity
    //      if multiply then Psgn
    //      otherwise psign
    assign ZeroSgn = (PSgnM^ZSgnEffM)&~Underflow&~Mult ? FrmM[1:0] == 2'b10 : PSgnM;

    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign ResultSgnTmp = InvZM&(ZSgnEffM)&NegSumM | InvZM&PSgnM&~NegSumM | ((ZSgnEffM)&PSgnM);
    assign ResultSgn = SumZero ? ZeroSgn : ResultSgnTmp;

endmodule


module normalize(
    input logic  [3*`NF+5:0]            SumM,       // the positive sum
    input logic  [`NE-1:0]              ZExpM,      // exponent of Z
    input logic  [`NE+1:0]              ProdExpM,   // X exponent + Y exponent - bias
    input logic  [$clog2(3*`NF+7)-1:0]  NormCntM,   // normalization shift count
    input logic  [`FPSIZES/3:0]         FmtM,       // precision 1 = double 0 = single
    input logic                         KillProdM,  // is the product set to zero
    input logic                         AddendStickyM,  // the sticky bit caclulated from the aligned addend
    output logic [`NF+2:0]              NormSum,        // normalized sum
    output logic                        SumZero,        // is the sum zero
    output logic                        NormSumSticky, UfSticky,    // sticky bits
    output logic [`NE+1:0]              SumExp,         // exponent of the normalized sum
    output logic                        ResultDenorm    // is the result denormalized
);
    logic [`NE+1:0]             SumExpTmp;          // exponent of the normalized sum not taking into account denormal or zero results
    logic [$clog2(3*`NF+7)-1:0] DenormShift;        // right shift if the result is denormalized //***change this later
    logic [3*`NF+5:0]           CorrSumShifted;     // the shifted sum after LZA correction
    logic [3*`NF+8:0]           SumShifted;         // the shifted sum before LZA correction
    logic [`NE+1:0]             SumExpTmpTmp;       // the exponent of the normalized sum with the `FLEN bias
    logic                       PreResultDenorm;    // is the result denormalized - calculated before LZA corection
    logic                       LZAPlus1, LZAPlus2; // add one or two to the sum's exponent due to LZA correction

    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////

    // Determine if the sum is zero
    assign SumZero = ~(|SumM);

    // calculate the sum's exponent
    assign SumExpTmpTmp = KillProdM ? {2'b0, ZExpM} : ProdExpM + -({4'b0, NormCntM} + 1 - (`NF+4));

    //convert the sum's exponent into the propper percision
    if (`FPSIZES == 1) begin
        assign SumExpTmp = SumExpTmpTmp;

    end else if (`FPSIZES == 2) begin
        assign SumExpTmp = FmtM ? SumExpTmpTmp : (SumExpTmpTmp-(`NE+2)'(`BIAS)+(`NE+2)'(`BIAS1))&{`NE+2{|SumExpTmpTmp}};

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (FmtM)
                `FMT: SumExpTmp = SumExpTmpTmp;
                `FMT1: SumExpTmp = (SumExpTmpTmp-`BIAS+`BIAS1)&{`NE+2{|SumExpTmpTmp}};
                `FMT2: SumExpTmp = (SumExpTmpTmp-`BIAS+`BIAS2)&{`NE+2{|SumExpTmpTmp}};
                default: SumExpTmp = `NE+2'bx;
            endcase
        end

    end else if (`FPSIZES == 4) begin
        always_comb begin
            case (FmtM)
                2'h3: SumExpTmp = SumExpTmpTmp;
                2'h1: SumExpTmp = (SumExpTmpTmp-`BIAS+`D_BIAS)&{`NE+2{|SumExpTmpTmp}};
                2'h0: SumExpTmp = (SumExpTmpTmp-`BIAS+`S_BIAS)&{`NE+2{|SumExpTmpTmp}};
                2'h2: SumExpTmp = (SumExpTmpTmp-`BIAS+`H_BIAS)&{`NE+2{|SumExpTmpTmp}};
            endcase
        end

    end
    
    // determine if the result is denormalized
    
    if (`FPSIZES == 1) begin
        logic Sum0LEZ, Sum0GEFL;
        assign Sum0LEZ  = SumExpTmpTmp[`NE+1] | ~|SumExpTmpTmp;
        assign Sum0GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`NF)-(`NE+2)'(2));
        assign PreResultDenorm = Sum0LEZ & Sum0GEFL & ~SumZero;

    end else if (`FPSIZES == 2) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL;
        assign Sum0LEZ  = SumExpTmpTmp[`NE+1] | ~|SumExpTmpTmp;
        assign Sum0GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`NF)-(`NE+2)'(2));
        assign Sum1LEZ  = $signed(SumExpTmpTmp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`BIAS1));
        assign Sum1GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`NF1+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`BIAS1)) | ~|SumExpTmpTmp;
        assign PreResultDenorm = (FmtM ? Sum0LEZ : Sum1LEZ) & (FmtM ? Sum0GEFL : Sum1GEFL) & ~SumZero;

    end else if (`FPSIZES == 3) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL, Sum2LEZ, Sum2GEFL;
        assign Sum0LEZ  = SumExpTmpTmp[`NE+1] | ~|SumExpTmpTmp;
        assign Sum0GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`NF)-(`NE+2)'(2));
        assign Sum1LEZ  = $signed(SumExpTmpTmp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`BIAS1));
        assign Sum1GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`NF1+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`BIAS1)) | ~|SumExpTmpTmp;
        assign Sum2LEZ  = $signed(SumExpTmpTmp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`BIAS2));
        assign Sum2GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`NF2+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`BIAS2)) | ~|SumExpTmpTmp;
        always_comb begin
            case (FmtM)
                `FMT: PreResultDenorm = Sum0LEZ & Sum0GEFL & ~SumZero;
                `FMT1: PreResultDenorm = Sum1LEZ & Sum1GEFL & ~SumZero;
                `FMT2: PreResultDenorm = Sum2LEZ & Sum2GEFL & ~SumZero;
                default: PreResultDenorm = 1'bx;
            endcase
        end

    end else if (`FPSIZES == 4) begin
        logic Sum0LEZ, Sum0GEFL, Sum1LEZ, Sum1GEFL, Sum2LEZ, Sum2GEFL, Sum3LEZ, Sum3GEFL;
        assign Sum0LEZ  = SumExpTmpTmp[`NE+1] | ~|SumExpTmpTmp;
        assign Sum0GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`NF  )-(`NE+2)'(2));
        assign Sum1LEZ  = $signed(SumExpTmpTmp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`D_BIAS));
        assign Sum1GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`D_NF+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`D_BIAS)) | ~|SumExpTmpTmp;
        assign Sum2LEZ  = $signed(SumExpTmpTmp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`S_BIAS));
        assign Sum2GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`S_NF+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`S_BIAS)) | ~|SumExpTmpTmp;
        assign Sum3LEZ  = $signed(SumExpTmpTmp) <= $signed( (`NE+2)'(`BIAS)-(`NE+2)'(`H_BIAS));
        assign Sum3GEFL = $signed(SumExpTmpTmp) >= $signed(-(`NE+2)'(`H_NF+2)+(`NE+2)'(`BIAS)-(`NE+2)'(`H_BIAS)) | ~|SumExpTmpTmp;
        always_comb begin
            case (FmtM)
                2'h3: PreResultDenorm = Sum0LEZ & Sum0GEFL & ~SumZero;
                2'h1: PreResultDenorm = Sum1LEZ & Sum1GEFL & ~SumZero;
                2'h0: PreResultDenorm = Sum2LEZ & Sum2GEFL & ~SumZero;
                2'h2: PreResultDenorm = Sum3LEZ & Sum3GEFL & ~SumZero;
            endcase
        end

    end

    // 010. when should be 001.
    //      - shift left one
    //      - add one from exp
    //      - if kill prod dont add to exp

    // Determine if the result is denormal
    // assign PreResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp)>=$signed(-FracLen)) & ~SumZero;

    // Determine the shift needed for denormal results
    //  - if not denorm add 1 to shift out the leading 1
    assign DenormShift = PreResultDenorm ? SumExpTmp[$clog2(3*`NF+7)-1:0] : 1;
    // Normalize the sum
    assign SumShifted = {3'b0, SumM} << NormCntM+DenormShift;
    // LZA correction
    assign LZAPlus1 = SumShifted[3*`NF+7];
    assign LZAPlus2 = SumShifted[3*`NF+8];
	// the only possible mantissa for a plus two is all zeroes - a one has to propigate all the way through a sum. so we can leave the bottom statement alone
    assign CorrSumShifted =  LZAPlus1 ? SumShifted[3*`NF+6:1] : SumShifted[3*`NF+5:0];
    assign NormSum = CorrSumShifted[3*`NF+5:2*`NF+3];

    // Calculate the sticky bit
    if (`FPSIZES == 1) begin
        assign NormSumSticky = |CorrSumShifted[2*`NF+2:0];

    end else if (`FPSIZES == 2) begin
        // 3*NF+5 - NF1 - 3
        assign NormSumSticky = (|CorrSumShifted[2*`NF+2:0]) | 
        (|CorrSumShifted[3*`NF+2-`NF1:2*`NF+3]&~FmtM);

    end else if (`FPSIZES == 3) begin
        assign NormSumSticky = (|CorrSumShifted[2*`NF+2:0]) | 
        (|CorrSumShifted[3*`NF+2-`NF1:2*`NF+3]&((FmtM==`FMT1)|(FmtM==`FMT2))) | 
        (|CorrSumShifted[3*`NF+2-`NF2:3*`NF+3-`NF1]&(FmtM==`FMT2));

    end else if (`FPSIZES == 4) begin        
        assign NormSumSticky = (|CorrSumShifted[2*`NF+2:0]) | 
        (|CorrSumShifted[3*`NF+2-`D_NF:2*`NF+3]&((FmtM==1)|(FmtM==0)|(FmtM==2))) | 
        (|CorrSumShifted[3*`NF+2-`S_NF:3*`NF+3-`D_NF]&((FmtM==0)|(FmtM==2))) |
        (|CorrSumShifted[3*`NF+2-`H_NF:3*`NF+3-`S_NF]&(FmtM==2));

    end

    assign UfSticky = AddendStickyM | NormSumSticky;

    // Determine sum's exponent
    //                          if plus1                     If plus2                                      if said denorm but norm plus 1           if said denorm but norm plus 2
    assign SumExp = (SumExpTmp+{12'b0, LZAPlus1&~KillProdM}+{11'b0, LZAPlus2&~KillProdM, 1'b0}+{12'b0, ~ResultDenorm&PreResultDenorm&~KillProdM}+{12'b0, &SumExpTmp&SumShifted[3*`NF+6]&~KillProdM}) & {`NE+2{~(SumZero|ResultDenorm)}};
    // recalculate if the result is denormalized
    assign ResultDenorm = PreResultDenorm&~SumShifted[3*`NF+6]&~SumShifted[3*`NF+7];

endmodule

module fmaround(
    input logic  [`FPSIZES/3:0] FmtM,       // precision 1 = double 0 = single
    input logic  [2:0]          FrmM,       // rounding mode
    input logic                 UfSticky,   // sticky bit for underlow calculation
    input logic  [`NF+2:0]      NormSum,    // normalized sum
    input logic                 AddendStickyM,  // addend's sticky bit
    input logic                 NormSumSticky,  // normalized sum's sticky bit
    input logic                 ZZeroM,         // is Z zero
    input logic                 InvZM,          // invert Z
    input logic  [`NE+1:0]      SumExp,         // exponent of the normalized sum
    input logic                 ResultSgnTmp,      // the result's sign
    output logic                CalcPlus1, UfPlus1,  // do you add or subtract on from the result
    output logic [`NE+1:0]      FullResultExp,      // ResultExp with bits to determine sign and overflow
    output logic [`NF-1:0]      ResultFrac,         // Result fraction
    output logic [`NE-1:0]      ResultExp,          // Result exponent
    output logic                Sticky,             // sticky bit
    output logic [`FLEN:0]      RoundAdd,           // how much to add to the result
    output logic                Round, Guard, UfLSBNormSum // bits needed to calculate rounding
);
    logic           LSBNormSum;         // bit used for rounding - least significant bit of the normalized sum
    logic           SubBySmallNum, UfSubBySmallNum;  // was there supposed to be a subtraction by a small number
    logic           UfGuard;            // guard bit used to caluculate underflow
    logic           UfCalcPlus1, CalcMinus1, Plus1, Minus1; // do you add or subtract on from the result
    logic [`NF-1:0] NormSumTruncated;   // the normalized sum trimed to fit the mantissa
    logic           UfRound;

    ///////////////////////////////////////////////////////////////////////////////
    // Rounding
    ///////////////////////////////////////////////////////////////////////////////

    // round to nearest even
    //      {Guard, Round, Sticky}
    //      0xx - do nothing
    //      100 - tie - Plus1 if result is odd  (LSBNormSum = 1)
    //          - don't add 1 if a small number was supposed to be subtracted
    //      101 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
    //      110/111 - Plus1

    //  round to zero - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

    //  round to -infinity
    //          - Plus1 if negative unless a small number was supposed to be subtracted from a result with guard and round bits of 0
    //          - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

    //  round to infinity
    //          - Plus1 if positive unless a small number was supposed to be subtracted from a result with guard and round bits of 0
    //          - subtract 1 if a small number was supposed to be subtracted from a negative result with guard and round bits of 0

    //  round to nearest max magnitude
    //      {Guard, Round, Sticky}
    //      0xx - do nothing
    //      100 - tie - Plus1
    //          - don't add 1 if a small number was supposed to be subtracted
    //      101 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
    //      110/111 - Plus1

    if (`FPSIZES == 1) begin
        // determine guard, round, and least significant bit of the result
        assign Guard = NormSum[2];
        assign Round = NormSum[1];
        assign LSBNormSum = NormSum[3];

        // used to determine underflow flag
        assign UfGuard = NormSum[1];
        assign UfRound = NormSum[0];
        assign UfLSBNormSum = NormSum[2];

        // determine sticky
        assign Sticky = UfSticky | NormSum[0];

    end else if (`FPSIZES == 2) begin
        //         \/-------------NF---------------,
        //      |      NF1       | 3 |             |
        //          '-------NF1------^

        // determine guard, round, and least significant bit of the result
        assign Guard = FmtM ? NormSum[2] : NormSum[`NF-`NF1+2];
        assign Round = FmtM ? NormSum[1] : NormSum[`NF-`NF1+1];
        assign LSBNormSum = FmtM ? NormSum[3] : NormSum[`NF-`NF1+3];

        // used to determine underflow flag
        assign UfGuard = FmtM ? NormSum[1] : NormSum[`NF-`NF1+1];
        assign UfRound = FmtM ? NormSum[0] : NormSum[`NF-`NF1];
        assign UfLSBNormSum = FmtM ? NormSum[2] : NormSum[`NF-`NF1+2];

        // determine sticky
        assign Sticky = UfSticky | (FmtM ? NormSum[0] : NormSum[`NF-`NF1]);

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (FmtM)
                `FMT: begin
                    // determine guard, round, and least significant bit of the result
                    Guard = NormSum[2];
                    Round = NormSum[1];
                    LSBNormSum = NormSum[3];
                    // used to determine underflow flag
                    UfGuard = NormSum[1];
                    UfRound = NormSum[0];
                    UfLSBNormSum = NormSum[2];
                    // determine sticky
                    Sticky = UfSticky | NormSum[0];
                end
                `FMT1: begin
                    // determine guard, round, and least significant bit of the result
                    Guard = NormSum[`NF-`NF1+2];
                    Round = NormSum[`NF-`NF1+1];
                    LSBNormSum = NormSum[`NF-`NF1+3];
                    // used to determine underflow flag
                    UfGuard = NormSum[`NF-`NF1+1];
                    UfRound = NormSum[`NF-`NF1];
                    UfLSBNormSum = NormSum[`NF-`NF1+2];
                    // determine sticky
                    Sticky = UfSticky | NormSum[`NF-`NF1];
                end
                `FMT2: begin
                    // determine guard, round, and least significant bit of the result
                    Guard = NormSum[`NF-`NF2+2];
                    Round = NormSum[`NF-`NF2+1];
                    LSBNormSum = NormSum[`NF-`NF2+3];
                    // used to determine underflow flag
                    UfGuard = NormSum[`NF-`NF2+1];
                    UfRound = NormSum[`NF-`NF2];
                    UfLSBNormSum = NormSum[`NF-`NF2+2];
                    // determine sticky
                    Sticky = UfSticky | NormSum[`NF-`NF2];
                end
                default: begin
                    Guard = 1'bx;
                    Round = 1'bx;
                    LSBNormSum = 1'bx;
                    UfGuard = 1'bx;
                    UfRound = 1'bx;
                    UfLSBNormSum = 1'bx;
                    Sticky = 1'bx;
                end
            endcase
        end

    end else if (`FPSIZES == 4) begin
        always_comb begin
            case (FmtM)
                2'h3: begin
                    // determine guard, round, and least significant bit of the result
                    Guard = NormSum[2];
                    Round = NormSum[1];
                    LSBNormSum = NormSum[3];
                    // used to determine underflow flag
                    UfGuard = NormSum[1];
                    UfRound = NormSum[0];
                    UfLSBNormSum = NormSum[2];
                    // determine sticky
                    Sticky = UfSticky | NormSum[0];
                end
                2'h1: begin
                    // determine guard, round, and least significant bit of the result
                    Guard = NormSum[`NF-`D_NF+2];
                    Round = NormSum[`NF-`D_NF+1];
                    LSBNormSum = NormSum[`NF-`D_NF+3];
                    // used to determine underflow flag
                    UfGuard = NormSum[`NF-`D_NF+1];
                    UfRound = NormSum[`NF-`D_NF];
                    UfLSBNormSum = NormSum[`NF-`D_NF+2];
                    // determine sticky
                    Sticky = UfSticky | NormSum[`NF-`D_NF];
                end
                2'h0: begin
                    // determine guard, round, and least significant bit of the result
                    Guard = NormSum[`NF-`S_NF+2];
                    Round = NormSum[`NF-`S_NF+1];
                    LSBNormSum = NormSum[`NF-`S_NF+3];
                    // used to determine underflow flag
                    UfGuard = NormSum[`NF-`S_NF+1];
                    UfRound = NormSum[`NF-`S_NF];
                    UfLSBNormSum = NormSum[`NF-`S_NF+2];
                    // determine sticky
                    Sticky = UfSticky | NormSum[`NF-`S_NF];
                end
                2'h2: begin
                    // determine guard, round, and least significant bit of the result
                    Guard = NormSum[`NF-`H_NF+2];
                    Round = NormSum[`NF-`H_NF+1];
                    LSBNormSum = NormSum[`NF-`H_NF+3];
                    // used to determine underflow flag
                    UfGuard = NormSum[`NF-`H_NF+1];
                    UfRound = NormSum[`NF-`H_NF];
                    UfLSBNormSum = NormSum[`NF-`H_NF+2];
                    // determine sticky
                    Sticky = UfSticky | NormSum[`NF-`H_NF];
                end
            endcase
        end

    end


    // Deterimine if a small number was supposed to be subtrated
    assign SubBySmallNum = AddendStickyM & InvZM & ~(NormSumSticky|UfRound) & ~ZZeroM; //***here
    assign UfSubBySmallNum = AddendStickyM & InvZM & ~(NormSumSticky) & ~ZZeroM; //***here

    always_comb begin
        // Determine if you add 1
        case (FrmM)
            3'b000: CalcPlus1 = Guard & (Round | ((Sticky)&~(~Round&SubBySmallNum)) | (~Round&~(Sticky)&LSBNormSum&~SubBySmallNum));//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = ResultSgnTmp & ~(SubBySmallNum & ~Guard & ~Round);//round down
            3'b011: CalcPlus1 = ~ResultSgnTmp & ~(SubBySmallNum & ~Guard & ~Round);//round up
            3'b100: CalcPlus1 = (Guard & (Round | ((Sticky)&~(~Round&SubBySmallNum)) | (~Round&~(Sticky)&~SubBySmallNum)));//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
        // Determine if you add 1 (for underflow flag)
        case (FrmM)
            3'b000: UfCalcPlus1 = UfGuard & (UfRound | (UfSticky&UfRound|~UfSubBySmallNum) | (~Sticky&UfLSBNormSum&~UfSubBySmallNum));//round to nearest even
            3'b001: UfCalcPlus1 = 0;//round to zero
            3'b010: UfCalcPlus1 = ResultSgnTmp & ~(UfSubBySmallNum & ~UfGuard & ~UfRound);//round down
            3'b011: UfCalcPlus1 = ~ResultSgnTmp & ~(UfSubBySmallNum & ~UfGuard & ~UfRound);//round up
            3'b100: UfCalcPlus1 = (UfGuard & (UfRound | (UfSticky&~(~UfRound&UfSubBySmallNum)) | (~Sticky&~UfSubBySmallNum)));//round to nearest max magnitude
            default: UfCalcPlus1 = 1'bx;
        endcase
        // Determine if you subtract 1
        case (FrmM)
            3'b000: CalcMinus1 = 0;//round to nearest even
            3'b001: CalcMinus1 = SubBySmallNum & ~Guard & ~Round;//round to zero
            3'b010: CalcMinus1 = ~ResultSgnTmp & ~Guard & ~Round & SubBySmallNum;//round down
            3'b011: CalcMinus1 = ResultSgnTmp & ~Guard & ~Round & SubBySmallNum;//round up
            3'b100: CalcMinus1 = 0;//round to nearest max magnitude
            default: CalcMinus1 = 1'bx;
        endcase
   
    end

    // If an answer is exact don't round
    assign Plus1 = CalcPlus1 & (Sticky | Guard | Round);
    assign UfPlus1 = UfCalcPlus1 & (Sticky | UfGuard);//UfRound is part of sticky
    assign Minus1 = CalcMinus1 & (Sticky | Guard | Round);

    // Compute rounded result
    if (`FPSIZES == 1) begin
        assign RoundAdd = Minus1 ? {`FLEN+1{1'b1}} : {{`FLEN{1'b0}}, Plus1};

    end else if (`FPSIZES == 2) begin
        // \/FLEN+1
        //  | NE+2 |        NF      |
        //  '-NE+2-^----NF1----^
        // `FLEN+1-`NE-2-`NF1 = FLEN-1-NE-NF1
        assign RoundAdd = FmtM ? Minus1 ? {`FLEN+1{1'b1}} : {{{`FLEN{1'b0}}}, Plus1} :
                                Minus1 ? {{`NE+2+`NF1{1'b1}}, (`FLEN-1-`NE-`NF1)'(0)} : {(`NE+1+`NF1)'(0), Plus1, (`FLEN-1-`NE-`NF1)'(0)};

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (FmtM)
                `FMT: RoundAdd = Minus1 ? {`FLEN+1{1'b1}} : {{{`FLEN{1'b0}}}, Plus1};
                `FMT1: RoundAdd = Minus1 ? {{`NE+2+`NF1{1'b1}}, (`FLEN-1-`NE-`NF1)'(0)} : {(`NE+1+`NF1)'(0), Plus1, (`FLEN-1-`NE-`NF1)'(0)};
                `FMT2: RoundAdd = Minus1 ? {{`NE+2+`NF2{1'b1}}, (`FLEN-1-`NE-`NF2)'(0)} : {(`NE+1+`NF2)'(0), Plus1, (`FLEN-1-`NE-`NF2)'(0)};
                default: RoundAdd = (`FLEN+1)'(0);
            endcase
        end

    end else if (`FPSIZES == 4) begin        
        always_comb begin
            case (FmtM)
                2'h3: RoundAdd = Minus1 ? {`FLEN+1{1'b1}} : {{{`FLEN{1'b0}}}, Plus1};
                2'h1: RoundAdd = Minus1 ? {{`NE+2+`D_NF{1'b1}}, (`FLEN-1-`NE-`D_NF)'(0)} : {(`NE+1+`D_NF)'(0), Plus1, (`FLEN-1-`NE-`D_NF)'(0)};
                2'h0: RoundAdd = Minus1 ? {{`NE+2+`S_NF{1'b1}}, (`FLEN-1-`NE-`S_NF)'(0)} : {(`NE+1+`S_NF)'(0), Plus1, (`FLEN-1-`NE-`S_NF)'(0)};
                2'h2: RoundAdd = Minus1 ? {{`NE+2+`H_NF{1'b1}}, (`FLEN-1-`NE-`H_NF)'(0)} : {(`NE+1+`H_NF)'(0), Plus1, (`FLEN-1-`NE-`H_NF)'(0)};
            endcase
        end

    end

    assign NormSumTruncated = NormSum[`NF+2:3];
    assign {FullResultExp, ResultFrac} = {SumExp, NormSumTruncated} + RoundAdd;
    assign ResultExp = FullResultExp[`NE-1:0];


endmodule

module fmaflags(
    input logic                 XSNaNM, YSNaNM, ZSNaNM, // inputs are signaling NaNs
    input logic                 XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                 XZeroM, YZeroM,         // inputs are zero
    input logic                 XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic  [`NE+1:0]      FullResultExp,          // ResultExp with bits to determine sign and overflow
    input logic  [`NE+1:0]      SumExp,                 // exponent of the normalized sum
    input logic                 ZSgnEffM, PSgnM,        // the product and modified Z signs
    input logic                 Round, Guard, UfLSBNormSum, Sticky, UfPlus1, // bits used to determine rounding
    input logic  [`FPSIZES/3:0] FmtM,                   // precision 1 = double 0 = single
    output logic                Invalid, Overflow, Underflow, // flags used to select the result
    output logic [4:0]          FMAFlgM // FMA flags
);
    logic               SigNaN;     // is an input a signaling NaN
    logic               GtMaxExp;   // is exponent greater than the maximum
    logic               UnderflowFlag, Inexact; // flags

    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////



    // Set Invalid flag for following cases:
    //   1) any input is a signaling NaN
    //   2) Inf - Inf (unless x or y is NaN)
    //   3) 0 * Inf

    assign SigNaN = XSNaNM | YSNaNM | ZSNaNM;
    assign Invalid = SigNaN | ((XInfM | YInfM) & ZInfM & (PSgnM ^ ZSgnEffM) & ~XNaNM & ~YNaNM) | (XZeroM & YInfM) | (YZeroM & XInfM);  
   
    // Set Overflow flag if the number is too big to be represented
    //      - Don't set the overflow flag if an overflowed result isn't outputed    
    if (`FPSIZES == 1) begin
        assign GtMaxExp = &FullResultExp[`NE-1:0] | FullResultExp[`NE];

    end else if (`FPSIZES == 2) begin
        assign GtMaxExp = FmtM ? &FullResultExp[`NE-1:0] | FullResultExp[`NE] : &FullResultExp[`NE1-1:0] | FullResultExp[`NE1];

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (FmtM)
                `FMT: GtMaxExp =  &FullResultExp[`NE-1:0] | FullResultExp[`NE];
                `FMT1: GtMaxExp = &FullResultExp[`NE1-1:0] | FullResultExp[`NE1];
                `FMT2: GtMaxExp = &FullResultExp[`NE2-1:0] | FullResultExp[`NE2];
                default: GtMaxExp = 1'bx;
            endcase
        end

    end else if (`FPSIZES == 4) begin        
        always_comb begin
            case (FmtM)
                2'h3: GtMaxExp =  &FullResultExp[`NE-1:0] | FullResultExp[`NE];
                2'h1: GtMaxExp = &FullResultExp[`D_NE-1:0] | FullResultExp[`D_NE];
                2'h0: GtMaxExp = &FullResultExp[`S_NE-1:0] | FullResultExp[`S_NE];
                2'h2: GtMaxExp = &FullResultExp[`H_NE-1:0] | FullResultExp[`H_NE];
            endcase
        end

    end
    assign Overflow = GtMaxExp & ~FullResultExp[`NE+1]&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

    // Set Underflow flag if the number is too small to be represented in normal numbers
    //      - Don't set the underflow flag if the result is exact

    assign Underflow = (SumExp[`NE+1] | ((SumExp == 0) & (Round|Guard|Sticky)))&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);
    assign UnderflowFlag = (FullResultExp[`NE+1] | ((FullResultExp == 0) | ((FullResultExp == 1) & (SumExp == 0) & ~(UfPlus1&UfLSBNormSum)))&(Round|Guard|Sticky))&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);
    // Set Inexact flag if the result is diffrent from what would be outputed given infinite precision
    //      - Don't set the underflow flag if an underflowed result isn't outputed
    assign Inexact = (Sticky|Overflow|Guard|Round|Underflow)&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

    // Combine flags
    //      - FMA can't set the Divide by zero flag
    //      - Don't set the underflow flag if the result was rounded up to a normal number
    assign FMAFlgM = {Invalid, 1'b0, Overflow, UnderflowFlag, Inexact};

endmodule


module resultselect(
    input logic                     XSgnM, YSgnM,        // input signs
    input logic     [`NE-1:0]       ZExpM, // input exponents
    input logic     [`NF:0]         XManM, YManM, ZManM, // input mantissas
    input logic     [2:0]           FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic     [`FPSIZES/3:0]  FmtM,       // precision 1 = double 0 = single
    input logic                     AddendStickyM,  // sticky bit that is calculated during alignment
    input logic                     KillProdM,      // set the product to zero before addition if the product is too small to matter
    input logic                     XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                     XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic                     ZOrigDenormM, // is the original precision denormalized
    input logic                     ZSgnEffM,   // the modified Z sign - depends on instruction
    input logic                     PSgnM,      // the product's sign
    input logic                     ResultSgn,  // the result's sign
    input logic                     CalcPlus1,  // rounding bits
    input logic     [`FLEN:0]       RoundAdd,   // how much to add to the result
    input logic                     Invalid, Overflow, Underflow,  // flags
    input logic                     ResultDenorm,       // is the result denormalized
    input logic     [`NE-1:0]       ResultExp,          // Result exponent
    input logic     [`NF-1:0]       ResultFrac,         // Result fraction
    output logic    [`FLEN-1:0]     FMAResM     // FMA final result
);
    logic               InfSgn;
    logic [`FLEN-1:0]   XNaNResult, YNaNResult, ZNaNResult, InfResult, InvalidResult, OverflowResult, KillProdResult, UnderflowResult, NormResult; // possible results
    assign InfSgn = ZInfM ? ZSgnEffM : PSgnM;
    if (`FPSIZES == 1) begin
        if(`IEEE754) begin
            assign XNaNResult = {XSgnM, {`NE{1'b1}}, 1'b1, XManM[`NF-2:0]};
            assign YNaNResult = {YSgnM, {`NE{1'b1}}, 1'b1, YManM[`NF-2:0]};
            assign ZNaNResult = {ZSgnEffM, {`NE{1'b1}}, 1'b1, ZManM[`NF-2:0]};
            assign InvalidResult = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
        end else begin
            assign XNaNResult = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
        end
        assign OverflowResult =  ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} :
                                                                                                                    {ResultSgn, {`NE{1'b1}}, {`NF{1'b0}}};
        assign KillProdResult = {ResultSgn, {ZExpM, ZManM[`NF-1:0]} + (RoundAdd[`FLEN-2:0]&{`FLEN-1{AddendStickyM}})};
        assign UnderflowResult = {ResultSgn, {`FLEN-1{1'b0}}} + {(`FLEN-1)'(0),(CalcPlus1&(AddendStickyM|FrmM[1]))};
        assign InfResult = {InfSgn, {`NE{1'b1}}, (`NF)'(0)};
        assign NormResult = {ResultSgn, ResultExp, ResultFrac};

    end else if (`FPSIZES == 2) begin //will the format conversion in killprod work in other conversions?
        if(`IEEE754) begin
            assign XNaNResult = FmtM ? {XSgnM, {`NE{1'b1}}, 1'b1, XManM[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, XSgnM, {`NE1{1'b1}}, 1'b1, XManM[`NF-2:`NF-`NF1]};
            assign YNaNResult = FmtM ? {YSgnM, {`NE{1'b1}}, 1'b1, YManM[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, YSgnM, {`NE1{1'b1}}, 1'b1, YManM[`NF-2:`NF-`NF1]};
            assign ZNaNResult = FmtM ? {ZSgnEffM, {`NE{1'b1}}, 1'b1, ZManM[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, ZSgnEffM, {`NE1{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`NF1]};
            assign InvalidResult = FmtM ? {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
        end else begin 
            assign XNaNResult = FmtM ? {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
        end
        
        assign OverflowResult =  FmtM ? ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} :
                                                                                                                            {ResultSgn, {`NE{1'b1}}, {`NF{1'b0}}} :
                                        ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{`FLEN-`LEN1{1'b1}}, ResultSgn, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}} :
                                                                                                                            {{`FLEN-`LEN1{1'b1}}, ResultSgn, {`NE1{1'b1}}, (`NF1)'(0)};
        assign KillProdResult = FmtM ? {ResultSgn, {ZExpM, ZManM[`NF-1:0]} + (RoundAdd[`FLEN-2:0]&{`FLEN-1{AddendStickyM}})} : {{`FLEN-`LEN1{1'b1}}, ResultSgn, {ZExpM[`NE-1], ZExpM[`NE1-2:1], ZExpM[0]&~ZOrigDenormM, ZManM[`NF-1:`NF-`NF1]} + (RoundAdd[`NF-`NF1+`LEN1-2:`NF-`NF1]&{`LEN1-1{AddendStickyM}})};
        assign UnderflowResult = FmtM ? {ResultSgn, {`FLEN-1{1'b0}}} + {(`FLEN-1)'(0),(CalcPlus1&(AddendStickyM|FrmM[1]))} : {{`FLEN-`LEN1{1'b1}}, {ResultSgn, (`LEN1-1)'(0)} + {(`LEN1-1)'(0), (CalcPlus1&(AddendStickyM|FrmM[1]))}};
        assign InfResult = FmtM ? {InfSgn, {`NE{1'b1}}, (`NF)'(0)} : {{`FLEN-`LEN1{1'b1}}, InfSgn, {`NE1{1'b1}}, (`NF1)'(0)};
        assign NormResult = FmtM ? {ResultSgn, ResultExp, ResultFrac} : {{`FLEN-`LEN1{1'b1}}, ResultSgn, ResultExp[`NE1-1:0], ResultFrac[`NF-1:`NF-`NF1]};

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (FmtM)
                `FMT: begin  
                    if(`IEEE754) begin
                        XNaNResult = {XSgnM, {`NE{1'b1}}, 1'b1, XManM[`NF-2:0]};
                        YNaNResult = {YSgnM, {`NE{1'b1}}, 1'b1, YManM[`NF-2:0]};
                        ZNaNResult = {ZSgnEffM, {`NE{1'b1}}, 1'b1, ZManM[`NF-2:0]};
                        InvalidResult = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                    end else begin 
                        XNaNResult = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                    end
                    
                    OverflowResult = ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} :
                                                                                                                                        {ResultSgn, {`NE{1'b1}}, {`NF{1'b0}}};
                    KillProdResult = {ResultSgn, {ZExpM, ZManM[`NF-1:0]} + (RoundAdd[`FLEN-2:0]&{`FLEN-1{AddendStickyM}})};
                    UnderflowResult = {ResultSgn, {`FLEN-1{1'b0}}} + {(`FLEN-1)'(0),(CalcPlus1&(AddendStickyM|FrmM[1]))};
                    InfResult = {InfSgn, {`NE{1'b1}}, (`NF)'(0)};
                    NormResult = {ResultSgn, ResultExp, ResultFrac};
                end
                `FMT1: begin  
                    if(`IEEE754) begin
                        XNaNResult = {{`FLEN-`LEN1{1'b1}}, XSgnM, {`NE1{1'b1}}, 1'b1, XManM[`NF-2:`NF-`NF1]};
                        YNaNResult = {{`FLEN-`LEN1{1'b1}}, YSgnM, {`NE1{1'b1}}, 1'b1, YManM[`NF-2:`NF-`NF1]};
                        ZNaNResult = {{`FLEN-`LEN1{1'b1}}, ZSgnEffM, {`NE1{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`NF1]};
                        InvalidResult = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
                    end else begin 
                        XNaNResult = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
                    end
                    OverflowResult = ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{`FLEN-`LEN1{1'b1}}, ResultSgn, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}} :
                                                                                                                                  {{`FLEN-`LEN1{1'b1}}, ResultSgn, {`NE1{1'b1}}, (`NF1)'(0)};
                    KillProdResult = {{`FLEN-`LEN1{1'b1}}, ResultSgn, {ZExpM[`NE-1], ZExpM[`NE1-2:1], ZExpM[0]&~ZOrigDenormM, ZManM[`NF-1:`NF-`NF1]} + (RoundAdd[`NF-`NF1+`LEN1-2:`NF-`NF1]&{`LEN1-1{AddendStickyM}})};
                    UnderflowResult = {{`FLEN-`LEN1{1'b1}}, {ResultSgn, (`LEN1-1)'(0)} + {(`LEN1-1)'(0), (CalcPlus1&(AddendStickyM|FrmM[1]))}};
                    InfResult = {{`FLEN-`LEN1{1'b1}}, InfSgn, {`NE1{1'b1}}, (`NF1)'(0)};
                    NormResult = {{`FLEN-`LEN1{1'b1}}, ResultSgn, ResultExp[`NE1-1:0], ResultFrac[`NF-1:`NF-`NF1]};
                end
                `FMT2: begin  
                    if(`IEEE754) begin
                        XNaNResult = {{`FLEN-`LEN2{1'b1}}, XSgnM, {`NE2{1'b1}}, 1'b1, XManM[`NF-2:`NF-`NF2]};
                        YNaNResult = {{`FLEN-`LEN2{1'b1}}, YSgnM, {`NE2{1'b1}}, 1'b1, YManM[`NF-2:`NF-`NF2]};
                        ZNaNResult = {{`FLEN-`LEN2{1'b1}}, ZSgnEffM, {`NE2{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`NF2]};
                        InvalidResult = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, (`NF2-1)'(0)};
                    end else begin 
                        XNaNResult = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, (`NF2-1)'(0)};
                    end
                    
                    OverflowResult = ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{`FLEN-`LEN2{1'b1}}, ResultSgn, {`NE2-1{1'b1}}, 1'b0, {`NF2{1'b1}}} :
                                                                                                                                  {{`FLEN-`LEN2{1'b1}}, ResultSgn, {`NE2{1'b1}}, (`NF2)'(0)};
                    KillProdResult = {{`FLEN-`LEN2{1'b1}}, ResultSgn, {ZExpM[`NE-1], ZExpM[`NE2-2:1], ZExpM[0]&~ZOrigDenormM, ZManM[`NF-1:`NF-`NF2]} + (RoundAdd[`NF-`NF2+`LEN2-2:`NF-`NF2]&{`LEN2-1{AddendStickyM}})};
                    UnderflowResult = {{`FLEN-`LEN2{1'b1}}, {ResultSgn, (`LEN2-1)'(0)} + {(`LEN2-1)'(0), (CalcPlus1&(AddendStickyM|FrmM[1]))}};
                    InfResult = {{`FLEN-`LEN2{1'b1}}, InfSgn, {`NE2{1'b1}}, (`NF2)'(0)};
                    NormResult = {{`FLEN-`LEN2{1'b1}}, ResultSgn, ResultExp[`NE2-1:0], ResultFrac[`NF-1:`NF-`NF2]};
                end
                default: begin
                    if(`IEEE754) begin
                        XNaNResult = (`FLEN)'(0);
                        YNaNResult = (`FLEN)'(0);
                        ZNaNResult = (`FLEN)'(0);
                        InvalidResult = (`FLEN)'(0);
                    end else begin 
                        XNaNResult = (`FLEN)'(0);
                    end
                    OverflowResult = (`FLEN)'(0);
                    KillProdResult = (`FLEN)'(0);
                    UnderflowResult = (`FLEN)'(0);
                    InfResult = (`FLEN)'(0);
                    NormResult = (`FLEN)'(0);
                end
            endcase
        end

    end else if (`FPSIZES == 4) begin 
        always_comb begin
            case (FmtM)
                2'h3: begin  
                    if(`IEEE754) begin
                        XNaNResult = {XSgnM, {`NE{1'b1}}, 1'b1, XManM[`NF-2:0]};
                        YNaNResult = {YSgnM, {`NE{1'b1}}, 1'b1, YManM[`NF-2:0]};
                        ZNaNResult = {ZSgnEffM, {`NE{1'b1}}, 1'b1, ZManM[`NF-2:0]};
                        InvalidResult = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                    end else begin 
                        XNaNResult = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                    end
                    
                    OverflowResult = ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} :
                                                                                                                                        {ResultSgn, {`NE{1'b1}}, {`NF{1'b0}}};
                    KillProdResult = {ResultSgn, {ZExpM, ZManM[`NF-1:0]} + (RoundAdd[`FLEN-2:0]&{`FLEN-1{AddendStickyM}})};
                    UnderflowResult = {ResultSgn, {`FLEN-1{1'b0}}} + {(`FLEN-1)'(0),(CalcPlus1&(AddendStickyM|FrmM[1]))};
                    InfResult = {InfSgn, {`NE{1'b1}}, (`NF)'(0)};
                    NormResult = {ResultSgn, ResultExp, ResultFrac};
                end
                2'h1: begin  
                    if(`IEEE754) begin
                        XNaNResult = {{`FLEN-`D_LEN{1'b1}}, XSgnM, {`D_NE{1'b1}}, 1'b1, XManM[`NF-2:`NF-`D_NF]};
                        YNaNResult = {{`FLEN-`D_LEN{1'b1}}, YSgnM, {`D_NE{1'b1}}, 1'b1, YManM[`NF-2:`NF-`D_NF]};
                        ZNaNResult = {{`FLEN-`D_LEN{1'b1}}, ZSgnEffM, {`D_NE{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`D_NF]};
                        InvalidResult = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, (`D_NF-1)'(0)};
                    end else begin 
                        XNaNResult = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, (`D_NF-1)'(0)};
                    end
                    OverflowResult = ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{`FLEN-`D_LEN{1'b1}}, ResultSgn, {`D_NE-1{1'b1}}, 1'b0, {`D_NF{1'b1}}} :
                                                                                                                                  {{`FLEN-`D_LEN{1'b1}}, ResultSgn, {`D_NE{1'b1}}, (`D_NF)'(0)};
                    KillProdResult = {{`FLEN-`D_LEN{1'b1}}, ResultSgn, {ZExpM[`NE-1], ZExpM[`D_NE-2:1], ZExpM[0]&~ZOrigDenormM, ZManM[`NF-1:`NF-`D_NF]} + (RoundAdd[`NF-`D_NF+`D_LEN-2:`NF-`D_NF]&{`D_LEN-1{AddendStickyM}})};
                    UnderflowResult = {{`FLEN-`D_LEN{1'b1}}, {ResultSgn, (`D_LEN-1)'(0)} + {(`D_LEN-1)'(0), (CalcPlus1&(AddendStickyM|FrmM[1]))}};
                    InfResult = {{`FLEN-`D_LEN{1'b1}}, InfSgn, {`D_NE{1'b1}}, (`D_NF)'(0)};
                    NormResult = {{`FLEN-`D_LEN{1'b1}}, ResultSgn, ResultExp[`D_NE-1:0], ResultFrac[`NF-1:`NF-`D_NF]};
                end
                2'h0: begin  
                    if(`IEEE754) begin
                        XNaNResult = {{`FLEN-`S_LEN{1'b1}}, XSgnM, {`S_NE{1'b1}}, 1'b1, XManM[`NF-2:`NF-`S_NF]};
                        YNaNResult = {{`FLEN-`S_LEN{1'b1}}, YSgnM, {`S_NE{1'b1}}, 1'b1, YManM[`NF-2:`NF-`S_NF]};
                        ZNaNResult = {{`FLEN-`S_LEN{1'b1}}, ZSgnEffM, {`S_NE{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`S_NF]};
                        InvalidResult = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, (`S_NF-1)'(0)};
                    end else begin 
                        XNaNResult = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, (`S_NF-1)'(0)};
                    end
                    
                    OverflowResult = ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{`FLEN-`S_LEN{1'b1}}, ResultSgn, {`S_NE-1{1'b1}}, 1'b0, {`S_NF{1'b1}}} :
                                                                                                                                  {{`FLEN-`S_LEN{1'b1}}, ResultSgn, {`S_NE{1'b1}}, (`S_NF)'(0)};
                    KillProdResult = {{`FLEN-`S_LEN{1'b1}}, ResultSgn, {ZExpM[`NE-1], ZExpM[`S_NE-2:1], ZExpM[0]&~ZOrigDenormM, ZManM[`NF-1:`NF-`S_NF]} + (RoundAdd[`NF-`S_NF+`S_LEN-2:`NF-`S_NF]&{`S_LEN-1{AddendStickyM}})};
                    UnderflowResult = {{`FLEN-`S_LEN{1'b1}}, {ResultSgn, (`S_LEN-1)'(0)} + {(`S_LEN-1)'(0), (CalcPlus1&(AddendStickyM|FrmM[1]))}};
                    InfResult = {{`FLEN-`S_LEN{1'b1}}, InfSgn, {`S_NE{1'b1}}, (`S_NF)'(0)};
                    NormResult = {{`FLEN-`S_LEN{1'b1}}, ResultSgn, ResultExp[`S_NE-1:0], ResultFrac[`NF-1:`NF-`S_NF]};
                end
                2'h2: begin  
                    if(`IEEE754) begin
                        XNaNResult = {{`FLEN-`H_LEN{1'b1}}, XSgnM, {`H_NE{1'b1}}, 1'b1, XManM[`NF-2:`NF-`H_NF]};
                        YNaNResult = {{`FLEN-`H_LEN{1'b1}}, YSgnM, {`H_NE{1'b1}}, 1'b1, YManM[`NF-2:`NF-`H_NF]};
                        ZNaNResult = {{`FLEN-`H_LEN{1'b1}}, ZSgnEffM, {`H_NE{1'b1}}, 1'b1, ZManM[`NF-2:`NF-`H_NF]};
                        InvalidResult = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, (`H_NF-1)'(0)};
                    end else begin 
                        XNaNResult = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, (`H_NF-1)'(0)};
                    end
                    
                    OverflowResult = ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{`FLEN-`H_LEN{1'b1}}, ResultSgn, {`H_NE-1{1'b1}}, 1'b0, {`H_NF{1'b1}}} :
                                                                                                              {{`FLEN-`H_LEN{1'b1}}, ResultSgn, {`H_NE{1'b1}}, (`H_NF)'(0)};      

                    KillProdResult = {{`FLEN-`H_LEN{1'b1}}, ResultSgn, {ZExpM[`NE-1], ZExpM[`H_NE-2:1],ZExpM[0]&~ZOrigDenormM, ZManM[`NF-1:`NF-`H_NF]} + (RoundAdd[`NF-`H_NF+`H_LEN-2:`NF-`H_NF]&{`H_LEN-1{AddendStickyM}})};
                    UnderflowResult = {{`FLEN-`H_LEN{1'b1}}, {ResultSgn, (`H_LEN-1)'(0)} + {(`H_LEN-1)'(0), (CalcPlus1&(AddendStickyM|FrmM[1]))}};
                    InfResult = {{`FLEN-`H_LEN{1'b1}}, InfSgn, {`H_NE{1'b1}}, (`H_NF)'(0)};
                    NormResult = {{`FLEN-`H_LEN{1'b1}}, ResultSgn, ResultExp[`H_NE-1:0], ResultFrac[`NF-1:`NF-`H_NF]};
                end
            endcase
        end

    end
    if(`IEEE754) begin
        assign FMAResM = XNaNM ? XNaNResult :
                            YNaNM ? YNaNResult :
                            ZNaNM ? ZNaNResult :
                            Invalid ? InvalidResult :
                            XInfM|YInfM|ZInfM ? InfResult :
                            KillProdM ? KillProdResult :  
                            Overflow ? OverflowResult :
                            Underflow & ~ResultDenorm & (ResultExp!=1) ? UnderflowResult :  
                            NormResult;
    end else begin
        assign FMAResM = XNaNM|YNaNM|ZNaNM|Invalid ? XNaNResult :
                            XInfM|YInfM|ZInfM ? InfResult :
                            KillProdM ? KillProdResult :  
                            Overflow ? OverflowResult :
                            Underflow & ~ResultDenorm & (ResultExp!=1) ? UnderflowResult :  
                            NormResult;
    end

endmodule