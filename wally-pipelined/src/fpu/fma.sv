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

module fma(
    input logic             clk,
    input logic             reset,
    input logic             FlushM,
    input logic             StallM,
    input logic             FmtE, FmtM,       // precision 1 = double 0 = single
    input logic  [2:0]      FOpCtrlM, FOpCtrlE,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic  [2:0]      FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic        XSgnE, YSgnE, ZSgnE,
    input logic [10:0] XExpE, YExpE, ZExpE,
    input logic [51:0] XFracE, YFracE, ZFracE,
    input logic        XSgnM, YSgnM, ZSgnM,
    input logic [10:0] XExpM, YExpM, ZExpM,
    input logic [51:0] XFracM, YFracM, ZFracM,
    input logic        XAssumed1E, YAssumed1E, ZAssumed1E,
    input logic XDenormE, YDenormE, ZDenormE,
    input logic XZeroE, YZeroE, ZZeroE,
    input logic XNaNM, YNaNM, ZNaNM,
    input logic XSNaNM, YSNaNM, ZSNaNM,
    input logic XZeroM, YZeroM, ZZeroM,
    input logic XInfM, YInfM, ZInfM,
    input logic [10:0] BiasE,
	output logic [63:0]		FMAResM,
	output logic [4:0]		FMAFlgM);
	

    logic [105:0]	ProdManE, ProdManM; 
    logic [161:0]	AlignedAddendE, AlignedAddendM;                       
    logic [12:0]	ProdExpE, ProdExpM;
    logic 			AddendStickyE, AddendStickyM;
    logic 			KillProdE, KillProdM;
    
    fma1 fma1 (.XExpE, .YExpE, .ZExpE, .XFracE, .YFracE, .ZFracE, 
                .BiasE, .XAssumed1E, .YAssumed1E, .ZAssumed1E, .XDenormE, .YDenormE, .ZDenormE,  .XZeroE, .YZeroE, .ZZeroE,
                .FOpCtrlE, .FmtE, .ProdManE, .AlignedAddendE,
                .ProdExpE, .AddendStickyE, .KillProdE); 
                
    flopenrc #(106) EMRegFma1(clk, reset, FlushM, ~StallM, ProdManE, ProdManM); 
    flopenrc #(162) EMRegFma2(clk, reset, FlushM, ~StallM, AlignedAddendE, AlignedAddendM); 
    flopenrc #(13) EMRegFma3(clk, reset, FlushM, ~StallM, ProdExpE, ProdExpM);  
    flopenrc #(2) EMRegFma4(clk, reset, FlushM, ~StallM, 
                            {AddendStickyE, KillProdE},
                            {AddendStickyM, KillProdM});

    fma2 fma2(.XSgnM, .YSgnM, .ZSgnM, .XExpM, .YExpM, .ZExpM, .XFracM, .YFracM, .ZFracM, 
            .FOpCtrlM, .FrmM, .FmtM, 
            .ProdManM, .AlignedAddendM, .ProdExpM, .AddendStickyM, .KillProdM, 
            .XZeroM, .YZeroM, .ZZeroM, .XInfM, .YInfM, .ZInfM, .XNaNM, .YNaNM, .ZNaNM, .XSNaNM, .YSNaNM, .ZSNaNM,
            .FMAResM, .FMAFlgM);

endmodule
      


module fma1(
    // input logic        XSgnE, YSgnE, ZSgnE,
    input logic [`NE-1:0] XExpE, YExpE, ZExpE,      // biased exponents in B(NE.0) format
    input logic [`NF-1:0] XFracE, YFracE, ZFracE,   // fractions in U(0.NF) format]
    input logic        XAssumed1E, YAssumed1E, ZAssumed1E,
    input logic        XDenormE, YDenormE, ZDenormE,
    input logic XZeroE, YZeroE, ZZeroE,
    input logic [`NE-1:0] BiasE,
    input logic     [2:0]       FOpCtrlE,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic                 FmtE,       // precision 1 = double 0 = single
    output logic    [2*`NF+1:0]     ProdManE,   // 1.X frac * 1.Y frac in U(2.2Nf) format
    output logic    [3*`NF+5:0]     AlignedAddendE, // Z aligned for addition in *** format
    output logic    [`NE+1:0]      ProdExpE,       // X exponent + Y exponent - bias in B(NE+2.0) format; adds 2 bits to allow for size of number and negative sign
    output logic                AddendStickyE,  // sticky bit that is calculated during alignment
    output logic                KillProdE      // set the product to zero before addition if the product is too small to matter
    );

    logic [`NE+1:0]    AlignCnt;           // how far to shift the addend to align with the product in Q(NE+2.0) format *** is this enough bits?
    logic [4*`NF+5:0]   ZManShifted;                // output of the alignment shifter including sticky bit
    logic [4*`NF+5:0]   ZManPreShifted;     // input to the alignment shifter
    
    ///////////////////////////////////////////////////////////////////////////////
    // Calculate the product
    //      - When multipliying two fp numbers, add the exponents
    //      - Subtract the bias (XExp + YExp has two biases, one from each exponent)
    //      - Denormal numbers have an an exponent value of 1, however they are
    //        represented with an exponent of 0. add one if there is a denormal number
    ///////////////////////////////////////////////////////////////////////////////
   
    // verilator lint_off WIDTH
    assign ProdExpE = (XZeroE|YZeroE) ? 0 :
                 XExpE + YExpE - BiasE + XDenormE + YDenormE;
    // verilator lint_on WIDTH

    // Calculate the product's mantissa
    //      - Add the assumed one. If the number is denormalized or zero, it does not have an assumed one.
    assign ProdManE =  {XAssumed1E, XFracE} * {YAssumed1E, YFracE};
   
    ///////////////////////////////////////////////////////////////////////////////
    // Alignment shifter
    ///////////////////////////////////////////////////////////////////////////////

    // determine the shift count for alignment
    //      - negitive means Z is larger, so shift Z left
    //      - positive means the product is larger, so shift Z right
    //      - Denormal numbers have an an exponent value of 1, however they are
    //        represented with an exponent of 0. add one to the exponent if it is a denormal number
    assign AlignCnt = ProdExpE - ZExpE - ZDenormE;

    // Defualt Addition without shifting
    //          |   55'b0    |  106'b(product)  | 2'b0 |
    //                       |1'b0| addnend |

    // the 1'b0 before the added is because the product's mantissa has two bits before the binary point (xx.xxxxxxxxxx...)
    assign ZManPreShifted = {55'b0, {ZAssumed1E, ZFracE}, 106'b0};
    always_comb
        begin
           
        // If the product is too small to effect the sum, kill the product

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //  | addnend |
        if ($signed(AlignCnt) <= $signed(-13'd56)) begin
            KillProdE = 1;
            ZManShifted = ZManPreShifted;//{107'b0, {~ZAssumed1E, ZFrac}, 54'b0};
            AddendStickyE = ~(XZeroE|YZeroE);

        // If the Addend is shifted left (negitive AlignCnt)

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //                  | addnend |
        end else if($signed(AlignCnt) <= $signed(13'd0))  begin
            KillProdE = 0;
            ZManShifted = ZManPreShifted << -AlignCnt;
            AddendStickyE = |(ZManShifted[51:0]);

        // If the Addend is shifted right (positive AlignCnt)

        //          |   54'b0    |  106'b(product)  | 2'b0 |
        //                                  | addnend |
        end else if ($signed(AlignCnt)<=$signed(13'd106))  begin
            KillProdE = 0;
            ZManShifted = ZManPreShifted >> AlignCnt;
            AddendStickyE = |(ZManShifted[51:0]);

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
    assign AlignedAddendE = ZManShifted[213:52];
endmodule


module fma2(
    
    input logic        XSgnM, YSgnM, ZSgnM,
    input logic [10:0] XExpM, YExpM, ZExpM,
    input logic [51:0] XFracM, YFracM, ZFracM,
    input logic     [2:0]       FrmM,       // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic     [2:0]       FOpCtrlM,   // 000 = fmadd (X*Y)+Z,  001 = fmsub (X*Y)-Z,  010 = fnmsub -(X*Y)+Z,  011 = fnmadd -(X*Y)-Z,  100 = fmul (X*Y)
    input logic                 FmtM,       // precision 1 = double 0 = single
    input logic     [105:0]     ProdManM,   // 1.X frac * 1.Y frac
    input logic     [161:0]     AlignedAddendM, // Z aligned for addition
    input logic     [12:0]      ProdExpM,       // X exponent + Y exponent - bias
    input logic                 AddendStickyM,  // sticky bit that is calculated during alignment
    input logic                 KillProdM,      // set the product to zero before addition if the product is too small to matter
    input logic                 XZeroM, YZeroM, ZZeroM, // inputs are zero
    input logic                 XInfM, YInfM, ZInfM,    // inputs are infinity
    input logic                 XNaNM, YNaNM, ZNaNM,    // inputs are NaN
    input logic                 XSNaNM, YSNaNM, ZSNaNM,    // inputs are signaling NaNs
    output logic    [63:0]      FMAResM,     // FMA final result
    output logic    [4:0]       FMAFlgM);     // FMA flags {invalid, divide by zero, overflow, underflow, inexact}
   


    logic [51:0]    ResultFrac; // Result fraction
    logic [10:0]    ResultExp;  // Result exponent
    logic           ResultSgn;  // Result sign
    logic           PSgn;       // product sign
    logic [105:0]   ProdMan2;   // product being added
    logic [162:0]   AlignedAddend2; // possibly inverted aligned Z
    logic [161:0]   Sum;        // positive sum
    logic [162:0]   PreSum;     // possibly negitive sum
    logic [12:0]    SumExp;     // exponent of the normalized sum
    logic [12:0]    SumExpTmp;  // exponent of the normalized sum not taking into account denormal or zero results
    logic [12:0]    SumExpTmpMinus1;    // SumExpTmp-1
    logic [12:0]    FullResultExp;      // ResultExp with bits to determine sign and overflow
    logic [54:0]    NormSum;    // normalized sum
    logic [161:0]   SumShifted; // sum shifted for normalization
    logic [8:0]     NormCnt;    // output of the leading zero detector
    logic           NormSumSticky; // sticky bit calulated from the normalized sum
    logic           SumZero;    // is the sum zero
    logic           NegSum;     // is the sum negitive
    logic           InvZ;       // invert Z if there is a subtraction (-product + Z or product - Z)
    logic           ResultDenorm;   // is the result denormalized
    logic           Sticky;     // Sticky bit
    logic           Plus1, Minus1, CalcPlus1, CalcMinus1;   // do you add or subtract one for rounding
    logic           UfPlus1, UfCalcPlus1;  // do you add one (for determining underflow flag)
    logic           Invalid,Underflow,Overflow,Inexact; // flags
    logic [8:0]     DenormShift;    // right shift if the result is denormalized
    logic           SubBySmallNum;  // was there supposed to be a subtraction by a small number
    logic [63:0]    Addend;     // value to add (Z or zero)
    logic           ZeroSgn;        // the result's sign if the sum is zero
    logic           ResultSgnTmp;   // the result's sign assuming the result is not zero
    logic           Guard, Round, LSBNormSum;   // bits needed to determine rounding
    logic           UfGuard, UfRound, UfLSBNormSum;   // bits needed to determine rounding for underflow flag
    logic [12:0]    MaxExp;     // maximum value of the exponent
    logic [12:0]    FracLen;    // length of the fraction
    logic           SigNaN;     // is an input a signaling NaN
    logic           UnderflowFlag;  // Underflow singal used in FMAFlgM (used to avoid a circular depencency)
    logic [63:0] XNaNResult, YNaNResult, ZNaNResult, InvalidResult, OverflowResult, KillProdResult, UnderflowResult; // possible results

   
    
    // Calculate the product's sign
    //      Negate product's sign if FNMADD or FNMSUB
    assign PSgn = XSgnM ^ YSgnM ^ FOpCtrlM[1];



    ///////////////////////////////////////////////////////////////////////////////
    // Addition
    ///////////////////////////////////////////////////////////////////////////////
   
    // Negate Z  when doing one of the following opperations:
    //      -prod +  Z
    //       prod -  Z
    assign InvZ = ZSgnM ^ PSgn;

    // Choose an inverted or non-inverted addend - the one is added later
    assign AlignedAddend2 = InvZ ? ~{1'b0, AlignedAddendM} : {1'b0, AlignedAddendM};
    // Kill the product if the product is too small to effect the addition (determined in fma1.sv)
    assign ProdMan2 = KillProdM ? 106'b0 : ProdManM;

    // Do the addition
    //      - add one to negate if the added was inverted
    //      - the 2 extra bits at the begining and end are needed for rounding
    assign PreSum = AlignedAddend2 + {55'b0, ProdMan2, 2'b0} + {162'b0, InvZ};
     
    // Is the sum negitive
    assign NegSum = PreSum[162];
    // If the sum is negitive, negate the sum.
    assign Sum = NegSum ? -PreSum[161:0] : PreSum[161:0];






    ///////////////////////////////////////////////////////////////////////////////
    // Leading one detector
    ///////////////////////////////////////////////////////////////////////////////

    //*** replace with non-behavoral code
    logic [8:0] i;
    always_comb begin
            i = 0;
            while (~Sum[161-i] && $unsigned(i) <= $unsigned(9'd161)) i = i+1;  // search for leading one
            NormCnt = i+1;    // compute shift count
    end











    ///////////////////////////////////////////////////////////////////////////////
    // Normalization
    ///////////////////////////////////////////////////////////////////////////////

    // Determine if the sum is zero
    assign SumZero = ~(|Sum);

    // determine the length of the fraction based on precision
    assign FracLen = FmtM ? 13'd52 : 13'd23;

    // Determine if the result is denormal
    assign SumExpTmp = KillProdM ? {2'b0, ZExpM} : ProdExpM + -({4'b0, NormCnt} - 13'd56);
    assign ResultDenorm = $signed(SumExpTmp)<=0 & ($signed(SumExpTmp)>=$signed(-FracLen)) & ~SumZero;

    // Determine the shift needed for denormal results
    assign SumExpTmpMinus1 = SumExpTmp-1;
    assign DenormShift = ResultDenorm ? SumExpTmpMinus1[8:0] : 9'b0;

    // Normalize the sum
    assign SumShifted = SumZero ? 162'b0 : Sum << NormCnt+DenormShift;
    assign NormSum = SumShifted[161:107];
    // Calculate the sticky bit
    assign NormSumSticky = FmtM ? (|SumShifted[107:0]) : (|SumShifted[136:0]);
    assign Sticky = AddendStickyM | NormSumSticky;

    // Determine sum's exponent
    assign SumExp = SumZero ? 13'b0 :
                 ResultDenorm ? 13'b0 :
                 SumExpTmp;





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

    // Deterimine if a small number was supposed to be subtrated
    assign SubBySmallNum = AddendStickyM&InvZ&~(NormSumSticky)&~ZZeroM;

    always_comb begin
        // Determine if you add 1
        case (FrmM)
            3'b000: CalcPlus1 = Guard & (Round | ((Sticky|UfGuard)&~(~Round&SubBySmallNum)) | (~Round&~(Sticky|UfGuard)&LSBNormSum&~SubBySmallNum));//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = ResultSgn & ~(SubBySmallNum & ~Guard & ~Round);//round down
            3'b011: CalcPlus1 = ~ResultSgn & ~(SubBySmallNum & ~Guard & ~Round);//round up
            3'b100: CalcPlus1 = (Guard & (Round | ((Sticky|UfGuard)&~(~Round&SubBySmallNum)) | (~Round&~(Sticky|UfGuard)&~SubBySmallNum)));//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
        // Determine if you add 1 (for underflow flag)
        case (FrmM)
            3'b000: UfCalcPlus1 = UfGuard & (UfRound | (Sticky&~(~UfRound&SubBySmallNum)) | (~UfRound&~Sticky&UfLSBNormSum&~SubBySmallNum));//round to nearest even
            3'b001: UfCalcPlus1 = 0;//round to zero
            3'b010: UfCalcPlus1 = ResultSgn & ~(SubBySmallNum & ~UfGuard & ~UfRound);//round down
            3'b011: UfCalcPlus1 = ~ResultSgn & ~(SubBySmallNum & ~UfGuard & ~UfRound);//round up
            3'b100: UfCalcPlus1 = (UfGuard & (UfRound | (Sticky&~(~UfRound&SubBySmallNum)) | (~UfRound&~Sticky&~SubBySmallNum)));//round to nearest max magnitude
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
    assign Plus1 = CalcPlus1 & (Sticky | UfGuard | Guard | Round);
    assign UfPlus1 = UfCalcPlus1 & (Sticky | UfGuard | UfRound);
    assign Minus1 = CalcMinus1 & (Sticky | UfGuard | Guard | Round);

    // Compute rounded result
    logic [64:0] RoundAdd;
    logic [51:0] NormSumTruncated;
    assign RoundAdd = FmtM ? Minus1 ? {65{1'b1}} : {64'b0, Plus1} :
                             Minus1 ? {{36{1'b1}}, 29'b0} : {35'b0, Plus1, 29'b0};
    assign NormSumTruncated = FmtM ? NormSum[54:3] : {NormSum[54:32], 29'b0};

    assign {FullResultExp, ResultFrac} = {SumExp, NormSumTruncated} + RoundAdd;
    assign ResultExp = FullResultExp[10:0];







    ///////////////////////////////////////////////////////////////////////////////
    // Sign calculation
    ///////////////////////////////////////////////////////////////////////////////

    // Determine the sign if the sum is zero
    //      if cancelation then 0 unless round to -infinity
    //      otherwise psign
    assign ZeroSgn = (PSgn^ZSgnM)&~Underflow ? FrmM == 3'b010 : PSgn;

    // is the result negitive
    //  if p - z is the Sum negitive
    //  if -p + z is the Sum positive
    //  if -p - z then the Sum is negitive
    assign ResultSgnTmp = InvZ&(ZSgnM)&NegSum | InvZ&PSgn&~NegSum | ((ZSgnM)&PSgn);
    assign ResultSgn = SumZero ? ZeroSgn : ResultSgnTmp;
 




    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////



    // Set Invalid flag for following cases:
    //   1) any input is a signaling NaN
    //   2) Inf - Inf (unless x or y is NaN)
    //   3) 0 * Inf
    assign MaxExp = FmtM ? 13'd2047 : 13'd255;
    assign SigNaN = XSNaNM | YSNaNM | ZSNaNM;
    assign Invalid = SigNaN | ((XInfM || YInfM) & ZInfM & (PSgn ^ ZSgnM) & ~XNaNM & ~YNaNM) | (XZeroM & YInfM) | (YZeroM & XInfM);  
   
    // Set Overflow flag if the number is too big to be represented
    //      - Don't set the overflow flag if an overflowed result isn't outputed
    assign Overflow = FullResultExp >= MaxExp & ~FullResultExp[12]&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

    // Set Underflow flag if the number is too small to be represented in normal numbers
    //      - Don't set the underflow flag if the result is exact
    assign Underflow = (SumExp[12] | ((SumExp == 0) & (Round|Guard|Sticky|UfGuard)))&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);
    assign UnderflowFlag = (FullResultExp[12] | ((FullResultExp == 0) | ((FullResultExp == 1) & (SumExp == 0) & ~(UfPlus1&UfLSBNormSum)))&(Round|Guard|Sticky))&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);
    // Set Inexact flag if the result is diffrent from what would be outputed given infinite precision
    //      - Don't set the underflow flag if an underflowed result isn't outputed
    assign Inexact = (Sticky|UfGuard|Overflow|Guard|Round|Underflow)&~(XNaNM|YNaNM|ZNaNM|XInfM|YInfM|ZInfM);

    // Combine flags
    //      - FMA can't set the Divide by zero flag
    //      - Don't set the underflow flag if the result was rounded up to a normal number
    assign FMAFlgM = {Invalid, 1'b0, Overflow, UnderflowFlag, Inexact};







    ///////////////////////////////////////////////////////////////////////////////
    // Select the result
    ///////////////////////////////////////////////////////////////////////////////
    assign XNaNResult = FmtM ? {XSgnM, XExpM, 1'b1, XFracM[50:0]} : {{32{1'b1}}, XSgnM, XExpM[7:0], 1'b1, XFracM[50:29]};
    assign YNaNResult = FmtM ? {YSgnM, YExpM, 1'b1, YFracM[50:0]} : {{32{1'b1}}, YSgnM, YExpM[7:0], 1'b1, YFracM[50:29]};
    assign ZNaNResult = FmtM ? {ZSgnM, ZExpM, 1'b1, ZFracM[50:0]} : {{32{1'b1}}, ZSgnM, ZExpM[7:0], 1'b1, ZFracM[50:29]};
    assign OverflowResult =  FmtM ? ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {ResultSgn, 11'h7fe, {52{1'b1}}} :
                                                                                                                          {ResultSgn, 11'h7ff, 52'b0} :
                                    ((FrmM[1:0]==2'b01) | (FrmM[1:0]==2'b10&~ResultSgn) | (FrmM[1:0]==2'b11&ResultSgn)) ? {{32{1'b1}}, ResultSgn, 8'hfe, {23{1'b1}}} :
                                                                                                                          {{32{1'b1}}, ResultSgn, 8'hff, 23'b0};
    assign InvalidResult = FmtM ? {ResultSgn, 11'h7ff, 1'b1, 51'b0} : {{32{1'b1}}, ResultSgn, 8'hff, 1'b1, 22'b0};
    assign KillProdResult = FmtM ? {ResultSgn, {ZExpM, ZFracM} - {62'b0, (Minus1&AddendStickyM)}} + {62'b0, (Plus1&AddendStickyM)} : {{32{1'b1}}, ResultSgn, {ZExpM[7:0], ZFracM[51:29]} - {30'b0, (Minus1&AddendStickyM)} + {30'b0, (Plus1&AddendStickyM)}};
    assign UnderflowResult = FmtM ? {ResultSgn, 63'b0} + {63'b0, (CalcPlus1&(AddendStickyM|FrmM[1]))} : {{32{1'b1}}, {ResultSgn, 31'b0} + {31'b0, (CalcPlus1&(AddendStickyM|FrmM[1]))}};
    assign FMAResM = XNaNM ? XNaNResult :
                        YNaNM ? YNaNResult :
                        ZNaNM ? ZNaNResult :
                        Invalid ? InvalidResult : // has to be before inf
                        XInfM ? FmtM ? {PSgn, XExpM, XFracM} : {{32{1'b1}}, PSgn, XExpM[7:0], XFracM[51:29]} :
                        XInfM ? FmtM ? {PSgn, YExpM, YFracM} : {{32{1'b1}}, PSgn, YExpM[7:0], YFracM[51:29]} :
                        XInfM ? FmtM ? {ZSgnM, ZExpM, ZFracM} : {{32{1'b1}}, ZSgnM, ZExpM[7:0], ZFracM[51:29]} :
                        Overflow ? OverflowResult :
                        KillProdM ? KillProdResult : // has to be after Underflow      
                        Underflow & ~ResultDenorm ? UnderflowResult :  
                        FmtM ? {ResultSgn, ResultExp, ResultFrac} :
                               {{32{1'b1}}, ResultSgn, ResultExp[7:0], ResultFrac[51:29]};



endmodule