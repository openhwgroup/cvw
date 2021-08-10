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
 //  `include "../../../config/rv64icfd/wally-config.vh"

module fma(
    input logic                 clk,
    input logic                 reset,
    input logic                 FlushM,     // flush the memory stage
    input logic                 StallM,     // stall memory stage
    input logic                 FmtE, FmtM, // precision 1 = double 0 = single
    input logic  [2:0]          FOpCtrlM, FOpCtrlE, // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic  [2:0]          FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic                 XSgnE, YSgnE, ZSgnE,    // input signs - execute stage
    input logic [`NE-1:0]       XExpE, YExpE, ZExpE,    // input exponents - execute stage
    input logic [`NF:0]         XManE, YManE, ZManE,    // input mantissa - execute stage
    input logic                 XSgnM, YSgnM, ZSgnM,    // input signs - memory stage
    input logic [`NE-1:0]       XExpM, YExpM, ZExpM,    // input exponents - memory stage
    input logic [`NF:0]         XManM, YManM, ZManM,    // input mantissa - memory stage
    input logic                 XDenormE, YDenormE, ZDenormE, // is denorm
    input logic                 XZeroE, YZeroE, ZZeroE,     // is zero - execute stage
    input logic                 XNaNM, YNaNM, ZNaNM,        // is NaN
    input logic                 XSNaNM, YSNaNM, ZSNaNM,     // is signaling NaN
    input logic                 XZeroM, YZeroM, ZZeroM,     // is zero - memory stage
    input logic                 XInfM, YInfM, ZInfM,        // is infinity
    input logic [10:0]          BiasE,      // bias - depends on precison (max exponent/2)
	output logic [`FLEN-1:0]    FMAResM,    // FMA result
	output logic [4:0]		    FMAFlgM);   // FMA flags
	
  //fma/mult	
      //  fmadd  = ?000
      //  fmsub  = ?001
      //  fnmsub = ?010	-(a*b)+c
      //  fnmadd = ?011 -(a*b)-c
      //  fmul   = ?100
      //	{?, is mul, negate product, negate addend}

    // signals transfered between pipeline stages
    logic [2*`NF+1:0]	ProdManE, ProdManM; 
    logic [3*`NF+5:0]	AlignedAddendE, AlignedAddendM;                       
    logic [`NE+1:0]	    ProdExpE, ProdExpM;
    logic 			    AddendStickyE, AddendStickyM;
    logic 			    KillProdE, KillProdM;
    
    fma1 fma1 (.XExpE, .YExpE, .ZExpE, .XManE, .YManE, .ZManE, 
                .BiasE, .XDenormE, .YDenormE, .ZDenormE,  .XZeroE, .YZeroE, .ZZeroE,
                .FOpCtrlE, .FmtE, .ProdManE, .AlignedAddendE,
                .ProdExpE, .AddendStickyE, .KillProdE); 
                
    // E/M pipeline registers
    flopenrc #(106) EMRegFma1(clk, reset, FlushM, ~StallM, ProdManE, ProdManM); 
    flopenrc #(162) EMRegFma2(clk, reset, FlushM, ~StallM, AlignedAddendE, AlignedAddendM); 
    flopenrc #(13) EMRegFma3(clk, reset, FlushM, ~StallM, ProdExpE, ProdExpM);  
    flopenrc #(2) EMRegFma4(clk, reset, FlushM, ~StallM, 
                            {AddendStickyE, KillProdE},
                            {AddendStickyM, KillProdM});

    fma2 fma2(.XSgnM, .YSgnM, .ZSgnM, .XExpM, .YExpM, .ZExpM, .XManM, .YManM, .ZManM, 
            .FOpCtrlM, .FrmM, .FmtM, 
            .ProdManM, .AlignedAddendM, .ProdExpM, .AddendStickyM, .KillProdM, 
            .XZeroM, .YZeroM, .ZZeroM, .XInfM, .YInfM, .ZInfM, .XNaNM, .YNaNM, .ZNaNM, .XSNaNM, .YSNaNM, .ZSNaNM,
            .FMAResM, .FMAFlgM);

endmodule
      


module fma1(
    // input logic        XSgnE, YSgnE, ZSgnE,
    input logic [`NE-1:0] XExpE, YExpE, ZExpE,      // biased exponents in B(NE.0) format
    input logic [`NF:0] XManE, YManE, ZManE,   // fractions in U(0.NF) format]
    input logic        XDenormE, YDenormE, ZDenormE, // is the input denormal
    input logic XZeroE, YZeroE, ZZeroE, // is the input zero
    input logic [`NE-1:0] BiasE,
    input logic     [2:0]       FOpCtrlE,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic                 FmtE,       // precision 1 = double 0 = single
    output logic    [2*`NF+1:0]     ProdManE,   // 1.X frac * 1.Y frac in U(2.2Nf) format
    output logic    [3*`NF+5:0]     AlignedAddendE, // Z aligned for addition in U(NF+5.2NF+1)
    output logic    [`NE+1:0]      ProdExpE,       // X exponent + Y exponent - bias in B(NE+2.0) format; adds 2 bits to allow for size of number and negative sign
    output logic                AddendStickyE,  // sticky bit that is calculated during alignment
    output logic                KillProdE      // set the product to zero before addition if the product is too small to matter
    );
    logic [`NE-1:0] Denorm;
    logic [`NE-1:0] DenormXExp, DenormYExp;             // Denormalized input value

    ///////////////////////////////////////////////////////////////////////////////
    // Calculate the product
    //      - When multipliying two fp numbers, add the exponents
    //      - Subtract the bias (XExp + YExp has two biases, one from each exponent)
    //      - Denormal numbers have an an exponent value of 1, however they are
    //        represented with an exponent of 0. add one if there is a denormal number
    ///////////////////////////////////////////////////////////////////////////////
   
    // denormalized numbers have diffrent values depending on which precison it is.
    assign Denorm = FmtE ? 1 : 897;
    assign DenormXExp = XDenormE ? Denorm : XExpE;
    assign DenormYExp = YDenormE ? Denorm : YExpE;
    assign ProdExpE = (XZeroE|YZeroE) ? 0 :
                 DenormXExp + DenormYExp - BiasE;

    // Calculate the product's mantissa
    //      - Mantissa includes the assumed one. If the number is denormalized or zero, it does not have an assumed one.
            // assign ProdManE =  XManE * YManE;
    mult mult(.XManE, .YManE, .ProdManE);
   
            // ///////////////////////////////////////////////////////////////////////////////
            // // Alignment shifter
            // ///////////////////////////////////////////////////////////////////////////////

            // // determine the shift count for alignment
            // //      - negitive means Z is larger, so shift Z left
            // //      - positive means the product is larger, so shift Z right
            // //      - Denormal numbers have an an exponent value of 1, however they are
            // //        represented with an exponent of 0. add one to the exponent if it is a denormal number
            // assign AlignCnt = ProdExpE - (ZExpE + ({`NE-1{ZDenormE}}&Denorm));

            // // Defualt Addition without shifting
            // //          |   54'b0    |  106'b(product)  | 2'b0 |
            // //                       |1'b0| addnend |

            // // the 1'b0 before the added is because the product's mantissa has two bits before the binary point (xx.xxxxxxxxxx...)
            // assign ZManPreShifted = {(`NF+3)'(0), ZManE, /*106*/(2*`NF+2)'(0)};
            // always_comb
            //     begin
                
            //     // If the product is too small to effect the sum, kill the product

            //     //          |   54'b0    |  106'b(product)  | 2'b0 |
            //     //  | addnend |
            //     if ($signed(AlignCnt) <= $signed(-(`NF+4))) begin
            //         KillProdE = 1;
            //         ZManShifted = ZManPreShifted;//{107'b0, XManE, 54'b0};
            //         AddendStickyE = ~(XZeroE|YZeroE);

            //     // If the Addend is shifted left (negitive AlignCnt)

            //     //          |   54'b0    |  106'b(product)  | 2'b0 |
            //     //                  | addnend |
            //     end else if($signed(AlignCnt) <= $signed(0))  begin
            //         KillProdE = 0;
            //         ZManShifted = ZManPreShifted << -AlignCnt;
            //         AddendStickyE = |(ZManShifted[`NF-1:0]);

            //     // If the Addend is shifted right (positive AlignCnt)

            //     //          |   54'b0    |  106'b(product)  | 2'b0 |
            //     //                                  | addnend |
            //     end else if ($signed(AlignCnt)<=$signed(2*`NF+1))  begin
            //         KillProdE = 0;
            //         ZManShifted = ZManPreShifted >> AlignCnt;
            //         AddendStickyE = |(ZManShifted[`NF-1:0]);

            //     // If the addend is too small to effect the addition        
            //     //      - The addend has to shift two past the end of the addend to be considered too small
            //     //      - The 2 extra bits are needed for rounding

            //     //          |   54'b0    |  106'b(product)  | 2'b0 |
            //     //                                                      | addnend |
            //     end else begin
            //         KillProdE = 0;
            //         ZManShifted = 0;
            //         AddendStickyE = ~ZZeroE;

            //     end
            // end
            // assign AlignedAddendE = ZManShifted[4*`NF+5:`NF];

    alignshift alignshift(.ZExpE, .ZManE, .ZDenormE, .XZeroE, .YZeroE, .ZZeroE, .ProdExpE, .Denorm,
                        .AlignedAddendE, .AddendStickyE, .KillProdE);
endmodule



module fma2(
    
    input logic        XSgnM, YSgnM, ZSgnM,
    input logic [`NE-1:0] XExpM, YExpM, ZExpM,
    input logic [`NF:0] XManM, YManM, ZManM,
    input logic     [2:0]       FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic     [2:0]       FOpCtrlM,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic                 FmtM,       // precision 1 = double 0 = single
    input logic     [2*`NF+1:0]     ProdManM,   // 1.X frac * 1.Y frac
    input logic     [3*`NF+5:0]     AlignedAddendM, // Z aligned for addition
    input logic     [`NE+1:0]      ProdExpM,       // X exponent + Y exponent - bias
    input logic                 AddendStickyM,  // sticky bit that is calculated during alignment
    input logic                 KillProdM,      // set the product to zero before addition if the product is too small to matter
    input logic                 XZeroM, YZeroM, ZZeroM, // inputs are zero
    input logic                 XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                 XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic                 XSNaNM, YSNaNM, ZSNaNM,    // inputs are signaling NaNs
    output logic    [`FLEN-1:0]      FMAResM,     // FMA final result
    output logic    [4:0]       FMAFlgM);     // FMA flags {invalid, divide by zero, overflow, underflow, inexact}
   


    logic [`NF-1:0]     ResultFrac; // Result fraction
    logic [`NE-1:0]     ResultExp;  // Result exponent
    logic               ResultSgn;  // Result sign
    logic               PSgn;       // product sign
    // logic [2*`NF+1:0]   ProdMan2;   // product being added
    // logic [3*`NF+6:0]   AlignedAddend2; // possibly inverted aligned Z
    logic [3*`NF+5:0]   Sum;        // positive sum
    // logic [3*`NF+6:0]   PreSum;     // possibly negitive sum
    logic [`NE+1:0]     SumExp;     // exponent of the normalized sum
    // logic [`NE+1:0]     SumExpTmp;  // exponent of the normalized sum not taking into account denormal or zero results
    // logic [`NE+1:0]     SumExpTmpMinus1;    // SumExpTmp-1
    logic [`NE+1:0]     FullResultExp;      // ResultExp with bits to determine sign and overflow
    logic [`NF+2:0]     NormSum;    // normalized sum
    // logic [3*`NF+5:0]   SumShifted; // sum shifted for normalization
    logic [8:0]         NormCnt, NormCntCheck;    // output of the leading zero detector //***change this later
    logic               NormSumSticky; // sticky bit calulated from the normalized sum
    logic               SumZero;    // is the sum zero
    logic               NegSum;     // is the sum negitive
    logic               InvZ;       // invert Z if there is a subtraction (-product + Z or product - Z)
    logic               ResultDenorm;   // is the result denormalized
    logic               Sticky, UfSticky;     // Sticky bit
    logic               Plus1, Minus1, CalcPlus1, CalcMinus1;   // do you add or subtract one for rounding
    logic               UfPlus1, UfCalcPlus1;  // do you add one (for determining underflow flag)
    logic               Invalid,Underflow,Overflow,Inexact; // flags
    // logic [8:0]         DenormShift;    // right shift if the result is denormalized //***change this later
    // logic               SubBySmallNum;  // was there supposed to be a subtraction by a small number
    logic [`FLEN-1:0]    Addend;     // value to add (Z or zero)
    logic           ZeroSgn;        // the result's sign if the sum is zero
    logic           ResultSgnTmp;   // the result's sign assuming the result is not zero
    logic           Guard, Round, LSBNormSum;   // bits needed to determine rounding
    logic           UfGuard, UfRound, UfLSBNormSum;   // bits needed to determine rounding for underflow flag
    // logic [`NE+1:0]    MaxExp;     // maximum value of the exponent
    // logic [`NE+1:0]    FracLen;    // length of the fraction
    logic           SigNaN;     // is an input a signaling NaN
    logic           UnderflowFlag;  // Underflow singal used in FMAFlgM (used to avoid a circular depencency)
    logic [`FLEN-1:0] XNaNResult, YNaNResult, ZNaNResult, InvalidResult, OverflowResult, KillProdResult, UnderflowResult; // possible results
    logic           ZSgnEffM;
   
    
    // Calculate the product's sign
    //      Negate product's sign if FNMADD or FNMSUB
 
    assign PSgn = XSgnM ^ YSgnM ^ (FOpCtrlM[1]&~FOpCtrlM[2]);
    assign ZSgnEffM = ZSgnM^FOpCtrlM[0]; // Swap sign of Z for subtract



            // ///////////////////////////////////////////////////////////////////////////////
            // // Addition
            // ///////////////////////////////////////////////////////////////////////////////
        
            // // Negate Z  when doing one of the following opperations:
            // //      -prod +  Z
            // //       prod -  Z
            // assign ZSgnEffM = ZSgnM^FOpCtrlM[0]; // Swap sign of Z for subtract
            // assign InvZ = ZSgnEffM ^ PSgn;

            // // Choose an inverted or non-inverted addend - the one is added later
            // assign AlignedAddend2 = InvZ ? ~{1'b0, AlignedAddendM} : {1'b0, AlignedAddendM};
            // // Kill the product if the product is too small to effect the addition (determined in fma1.sv)
            // assign ProdMan2 = KillProdM ? 0 : ProdManM;

            // // Do the addition
            // //      - add one to negate if the added was inverted
            // //      - the 2 extra bits at the begining and end are needed for rounding
            // assign PreSum = AlignedAddend2 + {ProdMan2, 2'b0} + InvZ;
            
            // // Is the sum negitive
            // assign NegSum = PreSum[3*`NF+6];
            // // If the sum is negitive, negate the sum.
            // assign Sum = NegSum ? -PreSum[3*`NF+5:0] : PreSum[3*`NF+5:0];

    fmaadd fmaadd(.AlignedAddendM, .ProdManM, .PSgn, .ZSgnEffM, .KillProdM, .Sum, .NegSum, .InvZ, .NormCnt);




            // ///////////////////////////////////////////////////////////////////////////////
            // // Leading zero counter
            // ///////////////////////////////////////////////////////////////////////////////

            // //*** replace with non-behavoral code
            // logic [8:0] i;
            // always_comb begin
            //         i = 0;
            //         while (~Sum[3*`NF+5-i] && $unsigned(i) <= $unsigned(3*`NF+5)) i = i+1;  // search for leading one
            //         NormCnt = i+1;    // compute shift count
            // end

    fmalzc fmalzc(.Sum, .NormCntCheck);









            // ///////////////////////////////////////////////////////////////////////////////
            // // Normalization
            // ///////////////////////////////////////////////////////////////////////////////

            // // Determine if the sum is zero
            // assign SumZero = ~(|Sum);

            // // determine the length of the fraction based on precision
            // assign FracLen = FmtM ? `NF : 13'd23;
            // //assign FracLen = `NF;

            // // Determine if the result is denormal
            // logic [`NE+1:0] SumExpTmpTmp;
            // assign SumExpTmpTmp = KillProdM ? {2'b0, ZExpM} : ProdExpM + -({4'b0, NormCnt} - (`NF+4));
            // assign SumExpTmp = FmtM ? SumExpTmpTmp : (SumExpTmpTmp-1023+127)&{`NE+2{|SumExpTmpTmp}};

            // assign ResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp)>=$signed(-FracLen)) & ~SumZero;

            // // Determine the shift needed for denormal results
            // assign SumExpTmpMinus1 = SumExpTmp-1;
            // assign DenormShift = ResultDenorm ? SumExpTmpMinus1[8:0] : 0; //*** change this when changing the size of DenormShift also change to an and opperation

            // // Normalize the sum
            // assign SumShifted = SumZero ? 0 : Sum << NormCnt+DenormShift; //*** fix mux's with constants in them
            // assign NormSum = SumShifted[3*`NF+5:2*`NF+3];
            // // Calculate the sticky bit
            // assign NormSumSticky = FmtM ? (|SumShifted[2*`NF+3:0]) : (|SumShifted[136:0]);
            // assign Sticky = AddendStickyM | NormSumSticky;

            // // Determine sum's exponent
            // assign SumExp = SumZero ? 0 : //***again fix mux
            //                 ResultDenorm ? 0 :
            //                 SumExpTmp;
    normalize normalize(.Sum, .ZExpM, .ProdExpM, .NormCnt, .FmtM, .KillProdM, .AddendStickyM, .NormSum,
            .SumZero, .NormSumSticky, .UfSticky, .SumExp, .ResultDenorm);




                // ///////////////////////////////////////////////////////////////////////////////
                // // Rounding
                // ///////////////////////////////////////////////////////////////////////////////

                // // round to nearest even
                // //      {Guard, Round, Sticky}
                // //      0xx - do nothing
                // //      100 - tie - Plus1 if result is odd  (LSBNormSum = 1)
                // //          - don't add 1 if a small number was supposed to be subtracted
                // //      101 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
                // //      110/111 - Plus1

                // //  round to zero - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

                // //  round to -infinity
                // //          - Plus1 if negative unless a small number was supposed to be subtracted from a result with guard and round bits of 0
                // //          - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

                // //  round to infinity
                // //          - Plus1 if positive unless a small number was supposed to be subtracted from a result with guard and round bits of 0
                // //          - subtract 1 if a small number was supposed to be subtracted from a negative result with guard and round bits of 0

                // //  round to nearest max magnitude
                // //      {Guard, Round, Sticky}
                // //      0xx - do nothing
                // //      100 - tie - Plus1
                // //          - don't add 1 if a small number was supposed to be subtracted
                // //      101 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
                // //      110/111 - Plus1

                // // determine guard, round, and least significant bit of the result
                // assign Guard = FmtM ? NormSum[2] : NormSum[31];
                // assign Round = FmtM ? NormSum[1] : NormSum[30];
                // assign LSBNormSum = FmtM ? NormSum[3] : NormSum[32];

                // // used to determine underflow flag
                // assign UfGuard = FmtM ? NormSum[1] : NormSum[30];
                // assign UfRound = FmtM ? NormSum[0] : NormSum[29];
                // assign UfLSBNormSum = FmtM ? NormSum[2] : NormSum[31];

                // // Deterimine if a small number was supposed to be subtrated
                // assign SubBySmallNum = AddendStickyM & InvZ & ~(NormSumSticky) & ~ZZeroM;

                // always_comb begin
                //     // Determine if you add 1
                //     case (FrmM)
                //         3'b000: CalcPlus1 = Guard & (Round | ((Sticky|UfRound)&~(~Round&SubBySmallNum)) | (~Round&~(Sticky|UfRound)&LSBNormSum&~SubBySmallNum));//round to nearest even
                //         3'b001: CalcPlus1 = 0;//round to zero
                //         3'b010: CalcPlus1 = ResultSgn & ~(SubBySmallNum & ~Guard & ~Round);//round down
                //         3'b011: CalcPlus1 = ~ResultSgn & ~(SubBySmallNum & ~Guard & ~Round);//round up
                //         3'b100: CalcPlus1 = (Guard & (Round | ((Sticky|UfRound)&~(~Round&SubBySmallNum)) | (~Round&~(Sticky|UfRound)&~SubBySmallNum)));//round to nearest max magnitude
                //         default: CalcPlus1 = 1'bx;
                //     endcase
                //     // Determine if you add 1 (for underflow flag)
                //     case (FrmM)
                //         3'b000: UfCalcPlus1 = UfGuard & (UfRound | (Sticky&~(~UfRound&SubBySmallNum)) | (~UfRound&~Sticky&UfLSBNormSum&~SubBySmallNum));//round to nearest even
                //         3'b001: UfCalcPlus1 = 0;//round to zero
                //         3'b010: UfCalcPlus1 = ResultSgn & ~(SubBySmallNum & ~UfGuard & ~UfRound);//round down
                //         3'b011: UfCalcPlus1 = ~ResultSgn & ~(SubBySmallNum & ~UfGuard & ~UfRound);//round up
                //         3'b100: UfCalcPlus1 = (UfGuard & (UfRound | (Sticky&~(~UfRound&SubBySmallNum)) | (~UfRound&~Sticky&~SubBySmallNum)));//round to nearest max magnitude
                //         default: UfCalcPlus1 = 1'bx;
                //     endcase
                //     // Determine if you subtract 1
                //     case (FrmM)
                //         3'b000: CalcMinus1 = 0;//round to nearest even
                //         3'b001: CalcMinus1 = SubBySmallNum & ~Guard & ~Round;//round to zero
                //         3'b010: CalcMinus1 = ~ResultSgn & ~Guard & ~Round & SubBySmallNum;//round down
                //         3'b011: CalcMinus1 = ResultSgn & ~Guard & ~Round & SubBySmallNum;//round up
                //         3'b100: CalcMinus1 = 0;//round to nearest max magnitude
                //         default: CalcMinus1 = 1'bx;
                //     endcase
            
                // end

                // // If an answer is exact don't round
                // assign Plus1 = CalcPlus1 & (Sticky | UfGuard | Guard | Round);
                // assign UfPlus1 = UfCalcPlus1 & (Sticky | UfGuard | UfRound);
                // assign Minus1 = CalcMinus1 & (Sticky | UfGuard | Guard | Round);

                // // Compute rounded result
                // logic [`FLEN:0] RoundAdd; //*** move this up 
                // logic [`NF-1:0] NormSumTruncated;
                // assign RoundAdd = FmtM ? Minus1 ? {`FLEN+1{1'b1}} : {{{`FLEN{1'b0}}}, Plus1} :
                //                          Minus1 ? {{36{1'b1}}, 29'b0} : {35'b0, Plus1, 29'b0};
                // assign NormSumTruncated = FmtM ? NormSum[`NF+2:3] : {NormSum[54:32], 29'b0};

                // assign {FullResultExp, ResultFrac} = {SumExp, NormSumTruncated} + RoundAdd;
                // assign ResultExp = FullResultExp[`NE-1:0];

    fmaround fmaround(.FmtM, .FrmM, .Sticky, .UfSticky, .NormSum, .AddendStickyM, .NormSumSticky, .ZZeroM, .InvZ, .ResultSgn, .SumExp,
        .CalcPlus1, .Plus1, .UfPlus1, .Minus1, .FullResultExp, .ResultFrac, .ResultExp, .Round, .Guard, .UfRound, .UfLSBNormSum);





    ///////////////////////////////////////////////////////////////////////////////
    // Sign calculation
    ///////////////////////////////////////////////////////////////////////////////

    // Determine the sign if the sum is zero
    //      if cancelation then 0 unless round to -infinity
    //      otherwise psign
    assign ZeroSgn = (PSgn^ZSgnEffM)&~Underflow ? FrmM == 3'b010 : PSgn;

    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign ResultSgnTmp = InvZ&(ZSgnEffM)&NegSum | InvZ&PSgn&~NegSum | ((ZSgnEffM)&PSgn);
    assign ResultSgn = SumZero ? ZeroSgn : ResultSgnTmp;
 




        // ///////////////////////////////////////////////////////////////////////////////
        // // Flags
        // ///////////////////////////////////////////////////////////////////////////////



        // // Set Invalid flag for following cases:
        // //   1) any input is a signaling NaN
        // //   2) Inf - Inf (unless x or y is NaN)
        // //   3) 0 * Inf

        // assign MaxExp = FmtM ? {`NE{1'b1}} : {8{1'b1}};
        // assign SigNaN = XSNaNM | YSNaNM | ZSNaNM;
        // assign Invalid = SigNaN | ((XInfM || YInfM) & ZInfM & (PSgn ^ ZSgnEffM) & ~XNaNM & ~YNaNM) | (XZeroM & YInfM) | (YZeroM & XInfM);  

        // // Set Overflow flag if the number is too big to be represented
        // //      - Don't set the overflow flag if an overflowed result isn't outputed
        // assign Overflow = FullResultExp >= {MaxExp} & ~FullResultExp[`NE+1]&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

        // // Set Underflow flag if the number is too small to be represented in normal numbers
        // //      - Don't set the underflow flag if the result is exact

        // assign Underflow = (SumExp[`NE+1] | ((SumExp == 0) & (Round|Guard|Sticky|UfRound)))&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);
        // assign UnderflowFlag = (FullResultExp[`NE+1] | ((FullResultExp == 0) | ((FullResultExp == 1) & (SumExp == 0) & ~(UfPlus1&UfLSBNormSum)))&(Round|Guard|Sticky))&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);
        // // Set Inexact flag if the result is diffrent from what would be outputed given infinite precision
        // //      - Don't set the underflow flag if an underflowed result isn't outputed
        // assign Inexact = (Sticky|UfRound|Overflow|Guard|Round|Underflow)&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

        // // Combine flags
        // //      - FMA can't set the Divide by zero flag
        // //      - Don't set the underflow flag if the result was rounded up to a normal number
        // assign FMAFlgM = {Invalid, 1'b0, Overflow, UnderflowFlag, Inexact};

        fmaflags fmaflags(.XSNaNM, .YSNaNM, .ZSNaNM, .XInfM, .YInfM, .ZInfM, .XZeroM, .YZeroM,
    .XNaNM, .YNaNM, .ZNaNM, .FullResultExp, .SumExp, .ZSgnEffM, .PSgn, .Round, .Guard, .UfRound, .UfLSBNormSum, .Sticky, .UfPlus1,
    .FmtM, .Invalid, .Overflow, .Underflow, .FMAFlgM);




    ///////////////////////////////////////////////////////////////////////////////
    // Select the result
    ///////////////////////////////////////////////////////////////////////////////
    assign XNaNResult = FmtM ? {XSgnM, XExpM, 1'b1, XManM[`NF-2:0]} : {{32{1'b1}}, XSgnM, XExpM[7:0], 1'b1, XManM[50:29]};
    assign YNaNResult = FmtM ? {YSgnM, YExpM, 1'b1, YManM[`NF-2:0]} : {{32{1'b1}}, YSgnM, YExpM[7:0], 1'b1, YManM[50:29]};
    assign ZNaNResult = FmtM ? {ZSgnEffM, ZExpM, 1'b1, ZManM[`NF-2:0]} : {{32{1'b1}}, ZSgnEffM, ZExpM[7:0], 1'b1, ZManM[50:29]};
    assign OverflowResult =  FmtM ? ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} :
                                                                                                                          {ResultSgn, {`NE{1'b1}}, {`NF{1'b0}}} :
                                    ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{32{1'b1}}, ResultSgn, 8'hfe, {23{1'b1}}} :
                                                                                                                          {{32{1'b1}}, ResultSgn, 8'hff, 23'b0};
    assign InvalidResult = FmtM ? {ResultSgn, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{32{1'b1}}, ResultSgn, 8'hff, 1'b1, 22'b0};
    assign KillProdResult = FmtM ? {ResultSgn, {ZExpM, ZManM[`NF-1:0]} - (Minus1&AddendStickyM) + (Plus1&AddendStickyM)} : {{32{1'b1}}, ResultSgn, {ZExpM[`NE-1],ZExpM[6:0], ZManM[51:29]} - {30'b0, (Minus1&AddendStickyM)} + {30'b0, (Plus1&AddendStickyM)}};
    assign UnderflowResult = FmtM ? {ResultSgn, {`FLEN-1{1'b0}}} + (CalcPlus1&(AddendStickyM|FrmM[1])) : {{32{1'b1}}, {ResultSgn, 31'b0} + {31'b0, (CalcPlus1&(AddendStickyM|FrmM[1]))}};
    assign FMAResM = XNaNM ? XNaNResult :
                        YNaNM ? YNaNResult :
                        ZNaNM ? ZNaNResult :
                        Invalid ? InvalidResult : // has to be before inf
                        XInfM ? FmtM ? {PSgn, XExpM, XManM[`NF-1:0]} : {{32{1'b1}}, PSgn,  XExpM[7:0], XManM[51:29]} : 
                        YInfM ? FmtM ? {PSgn, YExpM, YManM[`NF-1:0]} : {{32{1'b1}}, PSgn,  YExpM[7:0], YManM[51:29]} :
                        ZInfM ? FmtM ? {ZSgnEffM, ZExpM, ZManM[`NF-1:0]} : {{32{1'b1}}, ZSgnEffM, ZExpM[7:0], ZManM[51:29]} :
                        KillProdM ? KillProdResult :  
			Overflow ? OverflowResult :
                        Underflow & ~ResultDenorm & (ResultExp!=1) ? UnderflowResult :  
                        FmtM ? {ResultSgn, ResultExp, ResultFrac} :
                               {{32{1'b1}}, ResultSgn, ResultExp[7:0], ResultFrac[51:29]};

// *** use NF where needed

endmodule

module mult(
    input logic [`NF:0] XManE, YManE,
    output logic [2*`NF+1:0] ProdManE
);
    assign ProdManE = XManE * YManE;
endmodule

module alignshift(
    input logic [`NE-1:0] ZExpE,      // biased exponents in B(NE.0) format
    input logic [`NF:0] ZManE,   // fractions in U(0.NF) format]
    input logic         ZDenormE, // is the input denormal
    input logic XZeroE, YZeroE, ZZeroE, // is the input zero
    input logic [`NE+1:0] ProdExpE,
    input logic [`NE-1:0] Denorm,
    output logic [3*`NF+5:0] AlignedAddendE,
    output logic AddendStickyE,
    output logic KillProdE
);

    logic [`NE+1:0]     AlignCnt;           // how far to shift the addend to align with the product in Q(NE+2.0) format
    logic [4*`NF+5:0]   ZManShifted;        // output of the alignment shifter including sticky bits U(NF+5.3NF+1)
    logic [4*`NF+5:0]   ZManPreShifted;     // input to the alignment shifter U(NF+5.3NF+1)
    logic [`NE-1:0]   DenormZExp;

    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    // determine the shift count for alignment
    //      - negitive means Z is larger, so shift Z left
    //      - positive means the product is larger, so shift Z right
    //      - Denormal numbers have an an exponent value of 1, however they are
    //        represented with an exponent of 0. add one to the exponent if it is a denormal number
    assign DenormZExp = ZDenormE ? Denorm : ZExpE;
    assign AlignCnt = ProdExpE - DenormZExp + (`NF+3);

    // Defualt Addition without shifting
    //          |   54'b0    |  106'b(product)  | 2'b0 |
    //                       |1'b0| addnend |

    // the 1'b0 before the added is because the product's mantissa has two bits before the binary point (xx.xxxxxxxxxx...)
    assign ZManPreShifted = {ZManE,(3*`NF+5)'(0)};
    always_comb
        begin
        
        // If the product is too small to effect the sum, kill the product

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //  | addnend |
        if ($signed(AlignCnt) < $signed(0)) begin
            KillProdE = 1;
            ZManShifted = ZManPreShifted;//{107'b0, XManE, 54'b0};
            AddendStickyE = ~(XZeroE|YZeroE);

        // // If the Addend is shifted left (negitive AlignCnt)

        // //          |   54'b0    |  106'b(product)  | 2'b0 |
        // //                  | addnend |
        // end else if($signed(AlignCnt) <= $signed(0))  begin
        //     KillProdE = 0;
        //     ZManShifted = ZManPreShifted << -AlignCnt;
        //     AddendStickyE = |(ZManShifted[`NF-1:0]);

        // If the Addend is shifted right (positive AlignCnt)

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //                                  | addnend |
        end else if ($signed(AlignCnt)<=$signed(3*`NF+4))  begin
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

module fmaadd(
    input logic     [3*`NF+5:0]     AlignedAddendM, // Z aligned for addition
    input logic [2*`NF+1:0] ProdManM,
    input logic PSgn, ZSgnEffM,
    input logic KillProdM,
    output logic [3*`NF+5:0]   Sum,
    output logic NegSum,
    output logic InvZ,
    output logic [8:0] NormCnt
);
    logic [3*`NF+6:0]   PreSum, NegPreSum;     // possibly negitive sum
    logic [2*`NF+1:0]   ProdMan2;   // product being added
    logic [3*`NF+6:0]   AlignedAddend2; // possibly inverted aligned Z
    logic [8:0] PNormCnt, NNormCnt;

    ///////////////////////////////////////////////////////////////////////////////
    // Addition
    ///////////////////////////////////////////////////////////////////////////////
   
    // Negate Z  when doing one of the following opperations:
    //      -prod +  Z
    //       prod -  Z
    assign InvZ = ZSgnEffM ^ PSgn;

    // Choose an inverted or non-inverted addend - the one is added later
    assign AlignedAddend2 = InvZ ? -{1'b0, AlignedAddendM} : {1'b0, AlignedAddendM};
    // Kill the product if the product is too small to effect the addition (determined in fma1.sv)
    assign ProdMan2 = KillProdM ? 0 : ProdManM;
    poslza poslza(AlignedAddend2, ProdMan2, PNormCnt);
    neglza neglza({1'b0,AlignedAddendM}, -{{`NF+3{1'b0}}, ProdMan2, 2'b0}, NNormCnt);
    // Do the addition
    //      - add one to negate if the added was inverted
    //      - the 2 extra bits at the begining and end are needed for rounding
    assign PreSum = AlignedAddend2 + {ProdMan2, 2'b0};
    assign NegPreSum = AlignedAddendM - {ProdMan2, 2'b0};
     
    // Is the sum negitive
    assign NegSum = PreSum[3*`NF+6];
    // If the sum is negitive, negate the sum.
    assign Sum = NegSum ? NegPreSum[3*`NF+5:0] : PreSum[3*`NF+5:0];
    assign NormCnt = NegSum ? NNormCnt : PNormCnt;
// set to PNormCnt if the product is zero (there may be an additional bit of error from the negation)

endmodule

module fmalzc(
    input logic [3*`NF+5:0]   Sum,
    output logic [8:0] NormCntCheck
);

    ///////////////////////////////////////////////////////////////////////////////
    // Leading one detector
    ///////////////////////////////////////////////////////////////////////////////

    //*** replace with non-behavoral code
    logic [8:0] i;
    always_comb begin
            i = 0;
            while (~Sum[3*`NF+5-i] && $unsigned(i) <= $unsigned(3*`NF+5)) i = i+1;  // search for leading one
            NormCntCheck = i;
    end

endmodule
////////////////////////////////////////////////////////////////////////////////////
//	Filename: 	lza.v
//	Author:		Katherine Parry
//  Date:		2021/02/07
//
// Description:  Leading Zero Anticipator
// This a the Kershaw Leading Zero Anticipator(LZA) using the algorithm described in
// "Leading Zero Anticipation and Dectection - A Comparison of Methods" (2001)
//    Schmookler and Nowka.
// After swapping, alignment and inversion of A & B, the following functions are 
// applied to all 'i' bits. 
//   -- T[i] =   A[i] XOR B[i];  // Propagation that will occur
//   -- G[i] =   A[i] AND B[i];  // The value Generated
//   -- Z[i] = ~(A[i] OR  B[i]): // Fill functions
// The leading Zero is determined by the first occurance of the pattern T*GGZ*,
// whereas Leading ones are found by the pattern T*ZG*
// To evaluate the pattern we map it to the function that evaluates the three bits 
//     (current, before, & after): 
//  f[i] = T[i-1](G[i]~Z[i+1] & ~G[i+1]Z[i]) | ~T[i-1](Z[i]~Z[i+1] & G[i]~G[i+1])
// 
////////////////////////////////////////////////////////////////////////////////////

module poslza(
    //   parameter SIGNIFICANT_SZ=52;
    //leading digit anticipator
    //   localparam sz=SIGNIFICANT_SZ+1;
    input logic [3*`NF+6:0] A, 
    input logic [2*`NF+1:0] P,
    output logic [8:0] PCnt
    ); 
    
    // Compute Generate, Propageate and Kill for each bit
    
    logic [3*`NF+6:0] T;
    logic [3*`NF+5:0] Z;
    // assign T = A^{{`NF+3{1'b0}}, P, 2'b0};
    // assign Z = ~(A|{{`NF+3{1'b0}}, P, 2'b0});
    assign T[3*`NF+6:2*`NF+4] = A[3*`NF+6:2*`NF+4];
    assign Z[3*`NF+5:2*`NF+4] = A[3*`NF+5:2*`NF+4];
    assign T[2*`NF+3:2] = A[2*`NF+3:2]^P;
    assign Z[2*`NF+3:2] = A[2*`NF+3:2]|P;
    assign T[1:0] = A[1:0];
    assign Z[1:0] = A[1:0];
    

    // Apply function to determine Leading pattern
    logic [3*`NF+6:0] pf;
    assign pf = T^{Z[3*`NF+5:0], 1'b0};
    // assign pf = T^{~Z[3*`NF+5:0], 1'b0};

    logic [8:0] i;
    always_comb begin
        i = 0;
        while (~pf[3*`NF+6-i] && $unsigned(i) <= $unsigned(3*`NF+6)) i = i+1;  // search for leading one
        PCnt = i;
    end
  
endmodule

module neglza(
    //   parameter SIGNIFICANT_SZ=52;
    //leading digit anticipator
    //   localparam sz=SIGNIFICANT_SZ+1;
    input logic [3*`NF+6:0] A, 
    input logic [3*`NF+6:0] P,
    output logic [8:0] NCnt
    ); 
    
    // Compute Generate, Propageate and Kill for each bit
    
    logic [3*`NF+6:0] T;
    logic [3*`NF+5:0] Z;
    assign T = A^P;
    assign Z = ~(A[3*`NF+5:0]|P[3*`NF+5:0]);
    

    // Apply function to determine Leading pattern
    logic [3*`NF+6:0] f;
    assign f = T^{~Z, 1'b0};
    
    logic [8:0] i;
    always_comb begin
        i = 0;
        while (~f[3*`NF+6-i] && $unsigned(i) <= $unsigned(3*`NF+6)) i = i+1;  // search for leading one
        NCnt = i;
    end
  
endmodule



module normalize(
    input logic [3*`NF+5:0]   Sum,
    input logic [`NE-1:0] ZExpM,
    input logic     [`NE+1:0]      ProdExpM,       // X exponent + Y exponent - bias
    input logic [8:0] NormCnt,
    input logic                 FmtM,       // precision 1 = double 0 = single
    input logic KillProdM,
    input logic AddendStickyM,
    output logic [`NF+2:0]     NormSum,    // normalized sum
    output logic SumZero,
    output logic NormSumSticky, UfSticky,
    output logic [`NE+1:0]     SumExp,     // exponent of the normalized sum
    output logic ResultDenorm
);
    logic [`NE+1:0]    FracLen;    // length of the fraction
    logic [`NE+1:0]     SumExpTmp;  // exponent of the normalized sum not taking into account denormal or zero results
    logic [`NE+1:0]     SumExpTmpMinus1;    // SumExpTmp-1
    logic [8:0]         DenormShift;    // right shift if the result is denormalized //***change this later
    logic [3*`NF+5:0]   SumShifted; // sum shifted for normalization
    logic [3*`NF+7:0]   SumShiftedTmp; // sum shifted for normalization
    logic [`NE+1:0] SumExpTmpTmp;
    logic PreResultDenorm;
    logic LZAPlus1;

    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////

    // Determine if the sum is zero
    assign SumZero = ~(|Sum);

    // determine the length of the fraction based on precision
    assign FracLen = FmtM ? `NF+1 : 13'd24;
    //assign FracLen = `NF;

    // Determine if the result is denormal
    assign SumExpTmpTmp = KillProdM ? {2'b0, ZExpM} : ProdExpM + -({4'b0, NormCnt} + 1 - (`NF+4));
    assign SumExpTmp = FmtM ? SumExpTmpTmp : (SumExpTmpTmp-1023+127)&{`NE+2{|SumExpTmpTmp}};

    assign PreResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp)>=$signed(-FracLen)) & ~SumZero;

    // Determine the shift needed for denormal results
    //  - if not denorm add 1 to shift out the leading 1
    assign DenormShift = PreResultDenorm ? SumExpTmp[8:0] : 1; //*** change this when changing the size of DenormShift also change to an and opperation
    // Normalize the sum
    assign SumShiftedTmp = SumZero ? 0 : {2'b0, Sum} << NormCnt+DenormShift; //*** fix mux's with constants in them //***NormCnt can be simplified
    // LZA correction
    assign LZAPlus1 = SumShiftedTmp[3*`NF+7];
    assign SumShifted =  LZAPlus1 ? SumShiftedTmp[3*`NF+6:1] : SumShiftedTmp[3*`NF+5:0];
    assign NormSum = SumShifted[3*`NF+5:2*`NF+3];
    // Calculate the sticky bit
    assign NormSumSticky = FmtM ? (|SumShifted[2*`NF+2:0]) : (|SumShifted[136:0]);
    assign UfSticky = AddendStickyM | NormSumSticky;

    // Determine sum's exponent
    assign SumExp = SumZero ? 0 : //***again fix mux
                 ResultDenorm ? 0 :
                 SumExpTmp+LZAPlus1+(~|SumExpTmp&SumShiftedTmp[3*`NF+6]);
// recalculate if the result is denormalized
assign ResultDenorm = PreResultDenorm&~SumShiftedTmp[3*`NF+6]&~SumShiftedTmp[3*`NF+7];
                 
    // // Determine if the sum is zero
    // assign SumZero = ~(|Sum);

    // // determine the length of the fraction based on precision
    // assign FracLen = FmtM ? `NF : 13'd23;
    // //assign FracLen = `NF;

    // // Determine if the result is denormal
    // assign SumExpTmpTmp = KillProdM ? {2'b0, ZExpM} : ProdExpM + -({4'b0, NormCnt} + 1 - (`NF+4));
    // assign SumExpTmp = FmtM ? SumExpTmpTmp : (SumExpTmpTmp-1023+127)&{`NE+2{|SumExpTmpTmp}};

    // assign ResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp)>=$signed(-FracLen)) & ~SumZero;

    // // Determine the shift needed for denormal results
    // //  - if not denorm add 1 to shift out the leading 1
    // assign DenormShift = ResultDenorm ? SumExpTmp[8:0] : 1; //*** change this when changing the size of DenormShift also change to an and opperation

    // // Normalize the sum
    // assign SumShifted = SumZero ? 0 : Sum << NormCnt+DenormShift; //*** fix mux's with constants in them
    // assign NormSum = SumShifted[3*`NF+5:2*`NF+3];
    // // Calculate the sticky bit
    // assign NormSumSticky = FmtM ? (|SumShifted[2*`NF+2:0]) : (|SumShifted[136:0]);
    // assign UfSticky = AddendStickyM | NormSumSticky;

    // // Determine sum's exponent
    // assign SumExp = SumZero ? 0 : //***again fix mux
    //              ResultDenorm ? 0 :
    //              SumExpTmp;

endmodule

module fmaround(
    input logic                 FmtM,       // precision 1 = double 0 = single
    input logic [2:0] FrmM,
    input logic UfSticky,
    output logic Sticky,
    input logic [`NF+2:0]     NormSum,    // normalized sum
    input logic AddendStickyM,
    input logic NormSumSticky,
    input logic ZZeroM,
    input logic InvZ,
    input logic [`NE+1:0]     SumExp,     // exponent of the normalized sum
    input logic ResultSgn,
    output logic CalcPlus1, Plus1, UfPlus1, Minus1,
    output logic [`NE+1:0]     FullResultExp,      // ResultExp with bits to determine sign and overflow
    output logic [`NF-1:0]     ResultFrac, // Result fraction
    output logic [`NE-1:0]     ResultExp,  // Result exponent
    output logic Round, Guard, UfRound, UfLSBNormSum
);
    logic LSBNormSum;
    logic SubBySmallNum, UfSubBySmallNum;  // was there supposed to be a subtraction by a small number
    logic UfGuard;
    logic UfCalcPlus1, CalcMinus1;
    logic [`FLEN:0] RoundAdd; //*** move this up 
    logic [`NF-1:0] NormSumTruncated;

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
    assign SubBySmallNum = AddendStickyM & InvZ & ~(NormSumSticky|UfRound) & ~ZZeroM; //***here
    assign UfSubBySmallNum = AddendStickyM & InvZ & ~(NormSumSticky) & ~ZZeroM; //***here

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
    assign NormSumTruncated = FmtM ? NormSum[`NF+2:3] : {NormSum[54:32], 29'b0};

    assign {FullResultExp, ResultFrac} = {SumExp, NormSumTruncated} + RoundAdd;
    assign ResultExp = FullResultExp[`NE-1:0];


endmodule

module fmaflags(
    input logic                 XSNaNM, YSNaNM, ZSNaNM,    // inputs are signaling NaNs
    input logic                 XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                 XZeroM, YZeroM, // inputs are zero
    input logic                 XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic [`NE+1:0]     FullResultExp,      // ResultExp with bits to determine sign and overflow
    input logic [`NE+1:0]     SumExp,     // exponent of the normalized sum
    input logic ZSgnEffM, PSgn,
    input logic Round, Guard, UfRound, UfLSBNormSum, Sticky, UfPlus1,
    input logic                 FmtM,       // precision 1 = double 0 = single
    output logic Invalid, Overflow, Underflow,
    output logic [4:0] FMAFlgM
);
    logic [`NE+1:0]    MaxExp;     // maximum value of the exponent
    logic SigNaN;
    logic UnderflowFlag, Inexact;

    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////



    // Set Invalid flag for following cases:
    //   1) any input is a signaling NaN
    //   2) Inf - Inf (unless x or y is NaN)
    //   3) 0 * Inf

    // assign MaxExp = FmtM ? {`NE{1'b1}} : {8{1'b1}};
    assign SigNaN = XSNaNM | YSNaNM | ZSNaNM;
    assign Invalid = SigNaN | ((XInfM || YInfM) & ZInfM & (PSgn ^ ZSgnEffM) & ~XNaNM & ~YNaNM) | (XZeroM & YInfM) | (YZeroM & XInfM);  
   
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