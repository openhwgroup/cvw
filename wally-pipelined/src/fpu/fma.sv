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
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"
//    `include "../../../config/rv64icfd/wally-config.vh"

module fma(
    input logic                 clk,
    input logic                 reset,
    input logic                 FlushM,     // flush the memory stage
    input logic                 StallM,     // stall memory stage
    input logic                 FmtE, FmtM, // precision 1 = double 0 = single
    input logic  [2:0]          FOpCtrlE, // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic  [2:0]          FrmM,               // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic                 XSgnE, YSgnE, ZSgnE,    // input signs - execute stage
    input logic [`NE-1:0]       XExpE, YExpE, ZExpE,    // input exponents - execute stage
    input logic [`NF:0]         XManE, YManE, ZManE,    // input mantissa - execute stage
    input logic                 XSgnM, YSgnM,           // input signs - memory stage
    input logic [`NE-1:0]       XExpM, YExpM, ZExpM,    // input exponents - memory stage
    input logic [`NF:0]         XManM, YManM, ZManM,    // input mantissa - memory stage
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
    logic [8:0]			NormCntE, NormCntM;
    
    fma1 fma1 (.XSgnE, .YSgnE, .ZSgnE, .XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE, 
                .XDenormE, .YDenormE, .ZDenormE,  .XZeroE, .YZeroE, .ZZeroE,
                .FOpCtrlE, .FmtE, .SumE, .NegSumE, .InvZE, .NormCntE, .ZSgnEffE, .PSgnE,
                .ProdExpE, .AddendStickyE, .KillProdE); 
                
    // E/M pipeline registers
    flopenrc #(3*`NF+6) EMRegFma2(clk, reset, FlushM, ~StallM, SumE, SumM); 
    flopenrc #(13) EMRegFma3(clk, reset, FlushM, ~StallM, ProdExpE, ProdExpM);  
    flopenrc #(15) EMRegFma4(clk, reset, FlushM, ~StallM, 
                            {AddendStickyE, KillProdE, InvZE, NormCntE, NegSumE, ZSgnEffE, PSgnE},
                            {AddendStickyM, KillProdM, InvZM, NormCntM, NegSumM, ZSgnEffM, PSgnM});

    fma2 fma2(.XSgnM, .YSgnM, .XExpM, .YExpM, .ZExpM, .XManM, .YManM, .ZManM, 
            .FrmM, .FmtM,  .ProdExpM, .AddendStickyM, .KillProdM, .SumM, .NegSumM, .InvZM, .NormCntM, .ZSgnEffM, .PSgnM,
            .XZeroM, .YZeroM, .ZZeroM, .XInfM, .YInfM, .ZInfM, .XNaNM, .YNaNM, .ZNaNM, .XSNaNM, .YSNaNM, .ZSNaNM,
            .FMAResM, .FMAFlgM);

endmodule
      


module fma1(
    input logic                 XSgnE, YSgnE, ZSgnE,    // input's signs
    input logic  [`NE-1:0]      XExpE, YExpE, ZExpE,    // biased exponents in B(NE.0) format
    input logic  [`NF:0]        XManE, YManE, ZManE,    // fractions in U(0.NF) format
    input logic                 XDenormE, YDenormE, ZDenormE, // is the input denormal
    input logic                 XZeroE, YZeroE, ZZeroE, // is the input zero
    input logic  [2:0]          FOpCtrlE,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic                 FmtE,       // precision 1 = double 0 = single
    output logic [`NE+1:0]      ProdExpE,       // X exponent + Y exponent - bias in B(NE+2.0) format; adds 2 bits to allow for size of number and negative sign
    output logic                AddendStickyE,  // sticky bit that is calculated during alignment
    output logic                KillProdE,      // set the product to zero before addition if the product is too small to matter
    output logic [3*`NF+5:0]    SumE,           // the positive sum
    output logic                NegSumE,        // was the sum negitive
    output logic                InvZE,          // intert Z
    output logic                ZSgnEffE,       // the modified Z sign
    output logic                PSgnE,          // the product's sign
    output logic [8:0]          NormCntE        // normalization shift cnt
    );

    logic [`NE-1:0]     Denorm;             // value of a denormaized number based on precision
    logic [2*`NF+1:0]   ProdManE;           // 1.X frac * 1.Y frac in U(2.2Nf) format
    logic [3*`NF+5:0]   AlignedAddendE;     // Z aligned for addition in U(NF+5.2NF+1)
    logic [3*`NF+6:0]   AlignedAddendInv;   // aligned addend possibly inverted
    logic [2*`NF+1:0]   ProdManKilled;      // the product's mantissa possibly killed
    logic [3*`NF+6:0]   NegProdManKilled;   // a negated ProdManKilled
    logic [8:0]         PNormCnt, NNormCnt; // the positive and nagitive LOA results
    logic [3*`NF+6:0]   PreSum, NegPreSum;  // positive and negitve versions of the sum

    ///////////////////////////////////////////////////////////////////////////////
    // Calculate the product
    //      - When multipliying two fp numbers, add the exponents
    //      - Subtract the bias (XExp + YExp has two biases, one from each exponent)
    //      - If the product is zero then kill the exponent
    //      - Multiply the mantissas
    ///////////////////////////////////////////////////////////////////////////////
   

   // calculate the product's exponent 
    expadd expadd(.FmtE, .XExpE, .YExpE, .XZeroE, .YZeroE, .XDenormE, .YDenormE, 
                    .Denorm, .ProdExpE);

    // multiplication of the mantissa's
    mult mult(.XManE, .YManE, .ProdManE);
   
    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    align align(.ZExpE, .ZManE, .ZDenormE, .XZeroE, .YZeroE, .ZZeroE, .ProdExpE, .Denorm,
                        .AlignedAddendE, .AddendStickyE, .KillProdE);
                        
    // calculate the signs and take the opperation into account
    sign sign(.FOpCtrlE, .XSgnE, .YSgnE, .ZSgnE, .PSgnE, .ZSgnEffE);

    // ///////////////////////////////////////////////////////////////////////////////
    // // Addition/LZA
    // ///////////////////////////////////////////////////////////////////////////////
        
    add add(.AlignedAddendE, .ProdManE, .PSgnE, .ZSgnEffE, .KillProdE, .AlignedAddendInv, .ProdManKilled, .NegProdManKilled, .NegSumE, .PreSum, .NegPreSum, .InvZE, .XZeroE, .YZeroE);
    
    loa loa(.AlignedAddendE, .AlignedAddendInv, .ProdManKilled, .NegProdManKilled, .PNormCnt, .NNormCnt);

    // Choose the positive sum and accompanying LZA result.
    assign SumE = NegSumE ? NegPreSum[3*`NF+5:0] : PreSum[3*`NF+5:0];
    assign NormCntE = NegSumE ? NNormCnt : PNormCnt;


endmodule


module expadd(    
    input  logic            FmtE,          // precision
    input  logic [`NE-1:0]  XExpE, YExpE,  // input exponents
    input  logic            XDenormE, YDenormE,    // are the inputs denormalized
    input  logic            XZeroE, YZeroE,        // are the inputs zero
    output logic [`NE-1:0]  Denorm,        // value of denormalized exponent
    output logic [`NE+1:0]  ProdExpE       // product's exponent B^(1023)NE+2
);

    logic [`NE-1:0] XExpVal, YExpVal;       // Exponent value after taking into account denormals

    // denormalized numbers have diffrent values depending on which precison it is.
    //      double - 1
    //      single - 1023-127+1 = 897
    assign Denorm = FmtE ? 1 : 897;

    // pick denormalized value or exponent
    assign XExpVal = XDenormE ? Denorm : XExpE;
    assign YExpVal = YDenormE ? Denorm : YExpE;
    // kill the exponent if the product is zero - either X or Y is 0
    assign ProdExpE = ({2'b0, XExpVal} + {2'b0, YExpVal} - {2'b0, `NE'h3ff})&{`NE+2{~(XZeroE|YZeroE)}};

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
    assign AlignCnt = ProdExpE - {2'b0, ZExpVal} + (`NF+3);

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
        if ($signed(AlignCnt) < $signed(13'b0)) begin
            KillProdE = 1;
            ZManShifted = ZManPreShifted;
            AddendStickyE = ~(XZeroE|YZeroE);

        // If the Addend is shifted right
        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //                                  | addnend |
        end else if ($signed(AlignCnt)<=$signed(13'd3*13'd`NF+13'd4))  begin
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
    output logic [3*`NF+6:0] AlignedAddendInv,  // aligned addend possibly inverted
    output logic [2*`NF+1:0] ProdManKilled,     // the product's mantissa possibly killed
    output logic [3*`NF+6:0] NegProdManKilled,  // a negated ProdManKilled
    output logic                NegSumE,        // was the sum negitive
    output logic                InvZE,          // do you invert Z
    output logic [3*`NF+6:0]   PreSum, NegPreSum// possibly negitive sum
);

    ///////////////////////////////////////////////////////////////////////////////
    // Addition
    ///////////////////////////////////////////////////////////////////////////////
   
    // Negate Z  when doing one of the following opperations:
    //      -prod +  Z
    //       prod -  Z
    assign InvZE = ZSgnEffE ^ PSgnE;

    // Choose an inverted or non-inverted addend - the one has to be added now for the LZA
    assign AlignedAddendInv = InvZE ? -{1'b0, AlignedAddendE} : {1'b0, AlignedAddendE};
    // Kill the product if the product is too small to effect the addition (determined in fma1.sv)
    assign ProdManKilled = ProdManE&{2*`NF+2{~KillProdE}};
    // Negate ProdMan for LZA and the negitive sum calculation
    assign NegProdManKilled = {{`NF+3{~(XZeroE|YZeroE|KillProdE)}}, -ProdManKilled, 2'b0};



    // Do the addition
    //      - calculate a positive and negitive sum in parallel
    assign PreSum = AlignedAddendInv + {55'b0, ProdManKilled, 2'b0};
    assign NegPreSum = AlignedAddendE + NegProdManKilled;
     
    // Is the sum negitive
    assign NegSumE = PreSum[3*`NF+6];

endmodule


module loa(
    input logic [3*`NF+5:0] AlignedAddendE,     // Z aligned for addition in U(NF+5.2NF+1)
    input logic [3*`NF+6:0] AlignedAddendInv,   // aligned addend possibly inverted
    input logic [2*`NF+1:0] ProdManKilled,      // the product's mantissa possibly killed
    input logic [3*`NF+6:0] NegProdManKilled,   // a negated ProdManKilled
    output logic [8:0]      PNormCnt, NNormCnt  // positive and negitive LOA result    
);

    // LZAs one for the positive result and one for the negitive
    //      - the +1 from inverting causes problems for normalization
    posloa posloa(AlignedAddendInv, ProdManKilled, PNormCnt);
    negloa negloa({1'b0,AlignedAddendE}, NegProdManKilled, NNormCnt);

endmodule


module posloa(
    input logic  [3*`NF+6:0] A,     // addend
    input logic  [2*`NF+1:0] P,     // product
    output logic [8:0]       PCnt   // normalization shift count for the positive result
    ); 
    

    // calculate the propagate (T) and kill (Z) bits
    logic [3*`NF+6:0] T;
    logic [3*`NF+5:0] Z;
    assign T[3*`NF+6:2*`NF+4] = A[3*`NF+6:2*`NF+4];
    assign Z[3*`NF+5:2*`NF+4] = A[3*`NF+5:2*`NF+4];
    assign T[2*`NF+3:2] = A[2*`NF+3:2]^P;
    assign Z[2*`NF+3:2] = A[2*`NF+3:2]|P;
    assign T[1:0] = A[1:0];
    assign Z[1:0] = A[1:0];
    

    // Apply function to determine Leading pattern
    logic [3*`NF+6:0] f;
    assign f = T^{Z[3*`NF+5:0], 1'b0};

    lzc lzc(.f, .Cnt(PCnt));
  
endmodule

module negloa(
    input logic  [3*`NF+6:0]    A,      // addend
    input logic  [3*`NF+6:0]    P,      // product
    output logic [8:0]          NCnt    // normalization shift count for the negitive result
    ); 
    
    // calculate the propagate (T) and kill (Z) bits
    logic [3*`NF+6:0] T;
    logic [3*`NF+5:0] Z;
    assign T = A^P;
    assign Z = ~(A[3*`NF+5:0]|P[3*`NF+5:0]);
    

    // Apply function to determine Leading pattern
    logic [3*`NF+6:0] f;
    assign f = T^{~Z, 1'b0};
    
    lzc lzc(.f, .Cnt(NCnt));
  
endmodule


module lzc(
    input logic  [3*`NF+6:0]    f,
    output logic [8:0]          Cnt    // normalization shift count for the negitive result
);
    
    logic [8:0] i;
    always_comb begin
        i = 0;
        while (~f[3*`NF+6-i] && $unsigned(i) <= $unsigned(9'd3*9'd`NF+9'd6)) i = i+1;  // search for leading one
        Cnt = i;
    end
endmodule








module fma2(
    
    input logic                 XSgnM, YSgnM,        // input signs
    input logic     [`NE-1:0]   XExpM, YExpM, ZExpM, // input exponents
    input logic     [`NF:0]     XManM, YManM, ZManM, // input mantissas
    input logic     [2:0]       FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic                 FmtM,       // precision 1 = double 0 = single
    input logic     [`NE+1:0]   ProdExpM,       // X exponent + Y exponent - bias
    input logic                 AddendStickyM,  // sticky bit that is calculated during alignment
    input logic                 KillProdM,      // set the product to zero before addition if the product is too small to matter
    input logic                 XZeroM, YZeroM, ZZeroM, // inputs are zero
    input logic                 XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                 XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic                 XSNaNM, YSNaNM, ZSNaNM, // inputs are signaling NaNs
    input logic     [3*`NF+5:0] SumM,       // the positive sum
    input logic                 NegSumM,    // was the sum negitive
    input logic                 InvZM,      // do you invert Z
    input logic                 ZSgnEffM,   // the modified Z sign - depends on instruction
    input logic                 PSgnM,      // the product's sign
    input logic     [8:0]       NormCntM,   // the normalization shift count
    output logic    [`FLEN-1:0] FMAResM,    // FMA final result
    output logic    [4:0]       FMAFlgM);   // FMA flags {invalid, divide by zero, overflow, underflow, inexact}
   


    logic [`NF-1:0]     ResultFrac; // Result fraction
    logic [`NE-1:0]     ResultExp;  // Result exponent
    logic               ResultSgn;  // Result sign
    logic [`NE+1:0]     SumExp;     // exponent of the normalized sum
    logic [`NE+1:0]     FullResultExp;  // ResultExp with bits to determine sign and overflow
    logic [`NF+2:0]     NormSum;        // normalized sum
    logic               NormSumSticky;  // sticky bit calulated from the normalized sum
    logic               SumZero;        // is the sum zero
    logic               ResultDenorm;   // is the result denormalized
    logic               Sticky, UfSticky;           // Sticky bit
    logic               Plus1, Minus1, CalcPlus1;   // do you add or subtract one for rounding
    logic               UfPlus1;                    // do you add one (for determining underflow flag)
    logic               Invalid,Underflow,Overflow; // flags
    logic               Guard, Round;   // bits needed to determine rounding
    logic               UfLSBNormSum;   // bits needed to determine rounding for underflow flag
   
    



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

    fmaround fmaround(.FmtM, .FrmM, .Sticky, .UfSticky, .NormSum, .AddendStickyM, .NormSumSticky, .ZZeroM, .InvZM, .ResultSgn, .SumExp,
        .CalcPlus1, .Plus1, .UfPlus1, .Minus1, .FullResultExp, .ResultFrac, .ResultExp, .Round, .Guard, .UfLSBNormSum);





    ///////////////////////////////////////////////////////////////////////////////
    // Sign calculation
    ///////////////////////////////////////////////////////////////////////////////

 
    resultsign resultsign(.FrmM, .PSgnM, .ZSgnEffM, .Underflow, .InvZM, .NegSumM, .SumZero, .ResultSgn);




    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////

    fmaflags fmaflags(.XSNaNM, .YSNaNM, .ZSNaNM, .XInfM, .YInfM, .ZInfM, .XZeroM, .YZeroM,
        .XNaNM, .YNaNM, .ZNaNM, .FullResultExp, .SumExp, .ZSgnEffM, .PSgnM, .Round, .Guard, .UfLSBNormSum, .Sticky, .UfPlus1,
        .FmtM, .Invalid, .Overflow, .Underflow, .FMAFlgM);




    ///////////////////////////////////////////////////////////////////////////////
    // Select the result
    ///////////////////////////////////////////////////////////////////////////////

    resultselect resultselect(.XSgnM, .YSgnM, .XExpM, .YExpM, .ZExpM, .XManM, .YManM, .ZManM, 
        .FrmM, .FmtM, .AddendStickyM, .KillProdM, .XInfM, .YInfM, .ZInfM, .XNaNM, .YNaNM, .ZNaNM, 
        .ZSgnEffM, .PSgnM, .ResultSgn, .Minus1, .Plus1, .CalcPlus1, .Invalid, .Overflow, .Underflow, 
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
    output logic        ResultSgn
);

    logic ZeroSgn;
    logic ResultSgnTmp;

    // Determine the sign if the sum is zero
    //      if cancelation then 0 unless round to -infinity
    //      otherwise psign
    assign ZeroSgn = (PSgnM^ZSgnEffM)&~Underflow ? FrmM[1:0] == 2'b10 : PSgnM;

    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign ResultSgnTmp = InvZM&(ZSgnEffM)&NegSumM | InvZM&PSgnM&~NegSumM | ((ZSgnEffM)&PSgnM);
    assign ResultSgn = SumZero ? ZeroSgn : ResultSgnTmp;

endmodule

module resultselect(
    input logic                 XSgnM, YSgnM,        // input signs
    input logic     [`NE-1:0]   XExpM, YExpM, ZExpM, // input exponents
    input logic     [`NF:0]     XManM, YManM, ZManM, // input mantissas
    input logic     [2:0]       FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic                 FmtM,       // precision 1 = double 0 = single
    input logic                 AddendStickyM,  // sticky bit that is calculated during alignment
    input logic                 KillProdM,      // set the product to zero before addition if the product is too small to matter
    input logic                 XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                 XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic                 ZSgnEffM,   // the modified Z sign - depends on instruction
    input logic                 PSgnM,      // the product's sign
    input logic                 ResultSgn,  // the result's sign
    input logic                 Minus1, Plus1, CalcPlus1, // rounding bits
    input logic                 Invalid, Overflow, Underflow,  // flags
    input logic                 ResultDenorm,       // is the result denormalized
    input logic     [`NE-1:0]   ResultExp,          // Result exponent
    input logic     [`NF-1:0]   ResultFrac,         // Result fraction
    output logic    [`FLEN-1:0] FMAResM     // FMA final result
);
    logic [`FLEN-1:0]   XNaNResult, YNaNResult, ZNaNResult, InvalidResult, OverflowResult, KillProdResult, UnderflowResult; // possible results

    assign XNaNResult = FmtM ? {XSgnM, XExpM, 1'b1, XManM[`NF-2:0]} : {{32{1'b1}}, XSgnM, XExpM[7:0], 1'b1, XManM[50:29]};
    assign YNaNResult = FmtM ? {YSgnM, YExpM, 1'b1, YManM[`NF-2:0]} : {{32{1'b1}}, YSgnM, YExpM[7:0], 1'b1, YManM[50:29]};
    assign ZNaNResult = FmtM ? {ZSgnEffM, ZExpM, 1'b1, ZManM[`NF-2:0]} : {{32{1'b1}}, ZSgnEffM, ZExpM[7:0], 1'b1, ZManM[50:29]};
    assign OverflowResult =  FmtM ? ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} :
                                                                                                                          {ResultSgn, {`NE{1'b1}}, {`NF{1'b0}}} :
                                    ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{32{1'b1}}, ResultSgn, 8'hfe, {23{1'b1}}} :
                                                                                                                          {{32{1'b1}}, ResultSgn, 8'hff, 23'b0};
    assign InvalidResult = FmtM ? {ResultSgn, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{32{1'b1}}, ResultSgn, 8'hff, 1'b1, 22'b0};
    assign KillProdResult = FmtM ? {ResultSgn, {ZExpM, ZManM[`NF-1:0]} - {62'b0, (Minus1&AddendStickyM) + (Plus1&AddendStickyM)}} : {{32{1'b1}}, ResultSgn, {ZExpM[`NE-1],ZExpM[6:0], ZManM[51:29]} - {30'b0, (Minus1&AddendStickyM)} + {30'b0, (Plus1&AddendStickyM)}};
    assign UnderflowResult = FmtM ? {ResultSgn, {`FLEN-1{1'b0}}} + {63'b0,(CalcPlus1&(AddendStickyM|FrmM[1]))} : {{32{1'b1}}, {ResultSgn, 31'b0} + {31'b0, (CalcPlus1&(AddendStickyM|FrmM[1]))}};
    assign FMAResM = XNaNM ? XNaNResult :
                        YNaNM ? YNaNResult :
                        ZNaNM ? ZNaNResult :
                        Invalid ? InvalidResult :
                        XInfM ? FmtM ? {PSgnM, XExpM, XManM[`NF-1:0]} : {{32{1'b1}}, PSgnM,  XExpM[7:0], XManM[51:29]} : 
                        YInfM ? FmtM ? {PSgnM, YExpM, YManM[`NF-1:0]} : {{32{1'b1}}, PSgnM,  YExpM[7:0], YManM[51:29]} :
                        ZInfM ? FmtM ? {ZSgnEffM, ZExpM, ZManM[`NF-1:0]} : {{32{1'b1}}, ZSgnEffM, ZExpM[7:0], ZManM[51:29]} :
                        KillProdM ? KillProdResult :  
			            Overflow ? OverflowResult :
                        Underflow & ~ResultDenorm & (ResultExp!=1) ? UnderflowResult :  
                        FmtM ? {ResultSgn, ResultExp, ResultFrac} :
                               {{32{1'b1}}, ResultSgn, ResultExp[7:0], ResultFrac[51:29]};

endmodule


module normalize(
    input logic  [3*`NF+5:0]    SumM,       // the positive sum
    input logic  [`NE-1:0]      ZExpM,      // exponent of Z
    input logic  [`NE+1:0]      ProdExpM,   // X exponent + Y exponent - bias
    input logic  [8:0]          NormCntM,   // normalization shift count
    input logic                 FmtM,       // precision 1 = double 0 = single
    input logic                 KillProdM,  // is the product set to zero
    input logic                 AddendStickyM,  // the sticky bit caclulated from the aligned addend
    output logic [`NF+2:0]      NormSum,        // normalized sum
    output logic                SumZero,        // is the sum zero
    output logic                NormSumSticky, UfSticky,    // sticky bits
    output logic [`NE+1:0]      SumExp,         // exponent of the normalized sum
    output logic                ResultDenorm    // is the result denormalized
);
    logic [`NE+1:0]     FracLen;            // length of the fraction
    logic [`NE+1:0]     SumExpTmp;          // exponent of the normalized sum not taking into account denormal or zero results
    logic [8:0]         DenormShift;        // right shift if the result is denormalized //***change this later
    logic [3*`NF+5:0]   CorrSumShifted;     // the shifted sum after LZA correction
    logic [3*`NF+7:0]   SumShifted;         // the shifted sum before LZA correction
    logic [`NE+1:0]     SumExpTmpTmp;       // the exponent of the normalized sum with the `FLEN bias
    logic               PreResultDenorm;    // is the result denormalized - calculated before LZA corection
    logic               LZAPlus1;           // add one to the sum's exponent due to LZA correction

    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////

    // Determine if the sum is zero
    assign SumZero = ~(|SumM);

    // determine the length of the fraction based on precision
    assign FracLen = FmtM ? `NF+1 : 13'd24;

    // calculate the sum's exponent
    assign SumExpTmpTmp = KillProdM ? {2'b0, ZExpM} : ProdExpM + -({4'b0, NormCntM} + 1 - (`NF+4));
    assign SumExpTmp = FmtM ? SumExpTmpTmp : (SumExpTmpTmp-1023+127)&{`NE+2{|SumExpTmpTmp}};

    // Determine if the result is denormal
    assign PreResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp)>=$signed(-FracLen)) & ~SumZero;

    // Determine the shift needed for denormal results
    //  - if not denorm add 1 to shift out the leading 1
    assign DenormShift = PreResultDenorm ? SumExpTmp[8:0] : 1; //*** change this when changing the size of DenormShift also change to an and opperation
    // Normalize the sum
    assign SumShifted = {2'b0, SumM} << NormCntM+DenormShift; //*** fix mux's with constants in them //***NormCnt can be simplified
    // LZA correction
    assign LZAPlus1 = SumShifted[3*`NF+7];
    assign CorrSumShifted =  LZAPlus1 ? SumShifted[3*`NF+6:1] : SumShifted[3*`NF+5:0];
    assign NormSum = CorrSumShifted[3*`NF+5:2*`NF+3];
    // Calculate the sticky bit
    assign NormSumSticky = (|CorrSumShifted[2*`NF+2:0]) | (|CorrSumShifted[136:2*`NF+3]&~FmtM);
    assign UfSticky = AddendStickyM | NormSumSticky;

    // Determine sum's exponent
    assign SumExp = (SumExpTmp+{12'b0, LZAPlus1}+{12'b0, ~|SumExpTmp&SumShifted[3*`NF+6]}) & {`NE+2{~(SumZero|ResultDenorm)}};
    // recalculate if the result is denormalized
    assign ResultDenorm = PreResultDenorm&~SumShifted[3*`NF+6]&~SumShifted[3*`NF+7];

endmodule

module fmaround(
    input logic             FmtM,       // precision 1 = double 0 = single
    input logic  [2:0]      FrmM,       // rounding mode
    input logic             UfSticky,   // sticky bit for underlow calculation
    input logic  [`NF+2:0]  NormSum,    // normalized sum
    input logic             AddendStickyM,  // addend's sticky bit
    input logic             NormSumSticky,  // normalized sum's sticky bit
    input logic             ZZeroM,         // is Z zero
    input logic             InvZM,          // invert Z
    input logic  [`NE+1:0]  SumExp,         // exponent of the normalized sum
    input logic             ResultSgn,      // the result's sign
    output logic            CalcPlus1, Plus1, UfPlus1, Minus1,  // do you add or subtract on from the result
    output logic [`NE+1:0]  FullResultExp,      // ResultExp with bits to determine sign and overflow
    output logic [`NF-1:0]  ResultFrac,         // Result fraction
    output logic [`NE-1:0]  ResultExp,          // Result exponent
    output logic            Sticky,             // sticky bit
    output logic            Round, Guard, UfLSBNormSum // bits needed to calculate rounding
);
    logic           LSBNormSum;         // bit used for rounding - least significant bit of the normalized sum
    logic           SubBySmallNum, UfSubBySmallNum;  // was there supposed to be a subtraction by a small number
    logic           UfGuard;            // gaurd bit used to caluculate underflow
    logic           UfCalcPlus1, CalcMinus1;    // do you add or subtract on from the result
    logic [`FLEN:0] RoundAdd;           // how much to add to the result
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

    // determine guard, round, and least significant bit of the result
    assign Guard = FmtM ? NormSum[2] : NormSum[31];
    assign Round = FmtM ? NormSum[1] : NormSum[30];
    assign LSBNormSum = FmtM ? NormSum[3] : NormSum[32];

    // used to determine underflow flag
    assign UfGuard = FmtM ? NormSum[1] : NormSum[30];
    assign UfRound = FmtM ? NormSum[0] : NormSum[29];
    assign UfLSBNormSum = FmtM ? NormSum[2] : NormSum[31];

    // determine sticky
    assign Sticky = UfSticky | NormSum[0];
    // Deterimine if a small number was supposed to be subtrated
    assign SubBySmallNum = AddendStickyM & InvZM & ~(NormSumSticky|UfRound) & ~ZZeroM; //***here
    assign UfSubBySmallNum = AddendStickyM & InvZM & ~(NormSumSticky) & ~ZZeroM; //***here

    always_comb begin
        // Determine if you add 1
        case (FrmM)
            3'b000: CalcPlus1 = Guard & (Round | ((Sticky)&~(~Round&SubBySmallNum)) | (~Round&~(Sticky)&LSBNormSum&~SubBySmallNum));//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = ResultSgn & ~(SubBySmallNum & ~Guard & ~Round);//round down
            3'b011: CalcPlus1 = ~ResultSgn & ~(SubBySmallNum & ~Guard & ~Round);//round up
            3'b100: CalcPlus1 = (Guard & (Round | ((Sticky)&~(~Round&SubBySmallNum)) | (~Round&~(Sticky)&~SubBySmallNum)));//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
        // Determine if you add 1 (for underflow flag)
        case (FrmM)
            3'b000: UfCalcPlus1 = UfGuard & (UfRound | (UfSticky&UfRound|~UfSubBySmallNum) | (~Sticky&UfLSBNormSum&~UfSubBySmallNum));//round to nearest even
            3'b001: UfCalcPlus1 = 0;//round to zero
            3'b010: UfCalcPlus1 = ResultSgn & ~(UfSubBySmallNum & ~UfGuard & ~UfRound);//round down
            3'b011: UfCalcPlus1 = ~ResultSgn & ~(UfSubBySmallNum & ~UfGuard & ~UfRound);//round up
            3'b100: UfCalcPlus1 = (UfGuard & (UfRound | (UfSticky&~(~UfRound&UfSubBySmallNum)) | (~Sticky&~UfSubBySmallNum)));//round to nearest max magnitude
            default: UfCalcPlus1 = 1'bx;
        endcase
        // Determine if you subtract 1
        case (FrmM)
            3'b000: CalcMinus1 = 0;//round to nearest even
            3'b001: CalcMinus1 = SubBySmallNum & ~Guard & ~Round;//round to zero
            3'b010: CalcMinus1 = ~ResultSgn & ~Guard & ~Round & SubBySmallNum;//round down
            3'b011: CalcMinus1 = ResultSgn & ~Guard & ~Round & SubBySmallNum;//round up
            3'b100: CalcMinus1 = 0;//round to nearest max magnitude
            default: CalcMinus1 = 1'bx;
        endcase
   
    end

    // If an answer is exact don't round
    assign Plus1 = CalcPlus1 & (Sticky | Guard | Round);
    assign UfPlus1 = UfCalcPlus1 & (Sticky | UfGuard);//UfRound is part of sticky
    assign Minus1 = CalcMinus1 & (Sticky | Guard | Round);

    // Compute rounded result
    assign RoundAdd = FmtM ? Minus1 ? {`FLEN+1{1'b1}} : {{{`FLEN{1'b0}}}, Plus1} :
                             Minus1 ? {{36{1'b1}}, 29'b0} : {35'b0, Plus1, 29'b0};
    assign NormSumTruncated = {NormSum[`NF+2:32], NormSum[31:3]&{29{FmtM}}};

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
    input logic                 FmtM,                   // precision 1 = double 0 = single
    output logic                Invalid, Overflow, Underflow, // flags used to select the result
    output logic [4:0]          FMAFlgM // FMA flags
);
    logic               SigNaN;     // is an input a signaling NaN
    logic               UnderflowFlag, Inexact; // flags

    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////



    // Set Invalid flag for following cases:
    //   1) any input is a signaling NaN
    //   2) Inf - Inf (unless x or y is NaN)
    //   3) 0 * Inf

    assign SigNaN = XSNaNM | YSNaNM | ZSNaNM;
    assign Invalid = SigNaN | ((XInfM || YInfM) & ZInfM & (PSgnM ^ ZSgnEffM) & ~XNaNM & ~YNaNM) | (XZeroM & YInfM) | (YZeroM & XInfM);  
   
    // Set Overflow flag if the number is too big to be represented
    //      - Don't set the overflow flag if an overflowed result isn't outputed
    logic LtMaxExp;
    assign LtMaxExp = FmtM ? &FullResultExp[`NE-1:0] | FullResultExp[`NE] : &FullResultExp[7:0] | FullResultExp[8];
    assign Overflow = LtMaxExp & ~FullResultExp[`NE+1]&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

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