///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Rounder
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
// what position is XLEN in?
//  options: 
//     1: XLEN > NF   > NF1
//     2: NF   > XLEN > NF1
//     3: NF   > NF1  > XLEN
//  single and double will always be smaller than XLEN
`define XLENPOS ((`XLEN>`NF) ? 1 : (`XLEN>`NF1) ? 2 : 3)

module round(
    input logic  [`FMTBITS-1:0]     OutFmt,       // precision 1 = double 0 = single
    input logic  [2:0]              Frm,       // rounding mode
    input logic                     FmaOp,
    input logic                     DivOp,
    input logic                     CvtOp,
    input logic                     ToInt,
    input logic                     DivDone,
    input logic  [1:0]              PostProcSel,
    input logic                     CvtResDenormUf,
    input logic                     CvtResUf,
    input logic  [`CORRSHIFTSZ-1:0] Nfrac,
    input logic                     FmaZmSticky,  // addend's sticky bit
    input logic                     ZZero,         // is Z zero
    input logic                     FmaInvA,          // invert Z
    input logic  [`NE+1:0]          FmaSe,         // exponent of the normalized sum
    input logic                     Nsgn,      // the result's sign
    input logic  [`NE:0]            CvtCe,    // the calculated expoent
    input logic  [`NE+1:0]          DivCorrExp,    // the calculated expoent
    input logic                     DivSticky,             // sticky bit
    output logic                    UfPlus1,  // do you add or subtract on from the result
    output logic [`NE+1:0]          FullRe,      // Re with bits to determine sign and overflow
    output logic [`NF-1:0]          Rf,         // Result fraction
    output logic [`NE-1:0]          Re,          // Result exponent
    output logic                    S,             // sticky bit
    output logic [`NE+1:0]          Nexp,
    output logic                    Plus1,
    output logic [`FLEN:0]          RoundAdd,           // how much to add to the result
    output logic                    R, UfLSBRes // bits needed to calculate rounding
);
    logic           LSBRes;         // bit used for rounding - least significant bit of the normalized sum
    logic           UfCalcPlus1, CalcMinus1, Minus1; // do you add or subtract on from the result
    logic           NormSumSticky;  // normalized sum's sticky bit
    logic           UfSticky;   // sticky bit for underlow calculation
    logic [`NF-1:0] RoundFrac;
    logic           FpRes, IntRes;
    logic           UfRound;
    logic           FpRound, FpLSBRes, FpUfRound;
    logic           CalcPlus1, FpPlus1;

    ///////////////////////////////////////////////////////////////////////////////
    // Rounding
    ///////////////////////////////////////////////////////////////////////////////

    // round to nearest even
    //      {R, S}
    //      0x - do nothing
    //      10 - tie - Plus1 if result is odd  (LSBNormSum = 1)
    //          - don't add 1 if a small number was supposed to be subtracted
    //      11 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
    //         - plus 1 otherwise

    //  round to zero - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

    //  round to -infinity
    //          - Plus1 if negative unless a small number was supposed to be subtracted from a result with guard and round bits of 0
    //          - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

    //  round to infinity
    //          - Plus1 if positive unless a small number was supposed to be subtracted from a result with guard and round bits of 0
    //          - subtract 1 if a small number was supposed to be subtracted from a negative result with guard and round bits of 0

    //  round to nearest max magnitude
    //      {Guard, R, S}
    //      0x - do nothing
    //      10 - tie - Plus1
    //          - don't add 1 if a small number was supposed to be subtracted
    //      11 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
    //         - Plus 1 otherwise

    assign IntRes = CvtOp & ToInt;
    assign FpRes = ~IntRes;

    // sticky bit calculation
    if (`FPSIZES == 1) begin

    //     1: XLEN > NF
    //      |         XLEN          |
    //      |    NF     |1|1|
    //                     ^    ^ if floating point result
    //                     ^ if not an FMA result
        if (`XLENPOS == 1)assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                 (|Nfrac[`CORRSHIFTSZ-`XLEN-2:0]);
    //     2: NF > XLEN
        if (`XLENPOS == 2)assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&IntRes) |
                                                 (|Nfrac[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 2) begin
        // XLEN is either 64 or 32
        // so half and single are always smaller then XLEN

        // 1: XLEN > NF   > NF1
        if (`XLENPOS == 1) assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&FpRes&~OutFmt) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                  (|Nfrac[`CORRSHIFTSZ-`XLEN-2:0]);
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~OutFmt) | 
                                                  (|Nfrac[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&(IntRes|~OutFmt)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF-2:0]);
        // 3: NF   > NF1  > XLEN
        if (`XLENPOS == 3) assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF1-1]&IntRes) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&(~OutFmt|IntRes)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 3) begin
        // 1: XLEN > NF   > NF1
        if (`XLENPOS == 1) assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`NF1-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&FpRes&~(OutFmt==`FMT)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                  (|Nfrac[`CORRSHIFTSZ-`XLEN-2:0]);
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`NF1-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~(OutFmt==`FMT)) | 
                                                  (|Nfrac[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&(IntRes|~(OutFmt==`FMT))) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF-2:0]);
        // 3: NF   > NF1  > XLEN
        if (`XLENPOS == 3) assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF1-1]&((OutFmt==`FMT1)|IntRes)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&(~(OutFmt==`FMT)|IntRes)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 4) begin
        // Quad precision will always be greater than XLEN
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`H_NF-2:`CORRSHIFTSZ-`S_NF-1]&FpRes&(OutFmt==`H_FMT)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`S_NF-2:`CORRSHIFTSZ-`D_NF-1]&FpRes&((OutFmt==`S_FMT)|(OutFmt==`H_FMT))) | 
                                                  (|Nfrac[`CORRSHIFTSZ-`D_NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~(OutFmt==`Q_FMT)) | 
                                                  (|Nfrac[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`Q_NF-1]&(~(OutFmt==`Q_FMT)|IntRes)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`Q_NF-2:0]);
        // 3: NF   > NF1  > XLEN
        // The extra XLEN bit will be ored later when caculating the final sticky bit - the ufplus1 not needed for integer
        if (`XLENPOS == 3) assign NormSumSticky = (|Nfrac[`CORRSHIFTSZ-`H_NF-2:`CORRSHIFTSZ-`S_NF-1]&FpRes&(OutFmt==`H_FMT)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`S_NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&((OutFmt==`S_FMT)|(OutFmt==`H_FMT))) |
                                                  (|Nfrac[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`D_NF-1]&((OutFmt==`S_FMT)|(OutFmt==`H_FMT)|IntRes)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`D_NF-2:`CORRSHIFTSZ-`Q_NF-1]&(~(OutFmt==`Q_FMT)|IntRes)) |
                                                  (|Nfrac[`CORRSHIFTSZ-`Q_NF-2:0]);

    end
    


    // only add the Addend sticky if doing an FMA opperation
    //      - the shifter shifts too far left when there's an underflow (shifting out all possible sticky bits)
    assign UfSticky = FmaZmSticky&FmaOp | NormSumSticky | CvtResUf&CvtOp | FmaSe[`NE+1]&FmaOp | DivSticky&DivOp;
    
    // determine round and LSB of the rounded value
    //      - underflow round bit is used to determint the underflow flag
    if (`FPSIZES == 1) begin
        assign FpRound = Nfrac[`CORRSHIFTSZ-`NF-1];
        assign FpLSBRes = Nfrac[`CORRSHIFTSZ-`NF];
        assign FpUfRound = Nfrac[`CORRSHIFTSZ-`NF-2];

    end else if (`FPSIZES == 2) begin
        assign FpRound = OutFmt ? Nfrac[`CORRSHIFTSZ-`NF-1] : Nfrac[`CORRSHIFTSZ-`NF1-1];
        assign FpLSBRes = OutFmt ? Nfrac[`CORRSHIFTSZ-`NF] : Nfrac[`CORRSHIFTSZ-`NF1];
        assign FpUfRound = OutFmt ? Nfrac[`CORRSHIFTSZ-`NF-2] : Nfrac[`CORRSHIFTSZ-`NF1-2];

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT: begin
                    FpRound = Nfrac[`CORRSHIFTSZ-`NF-1];
                    FpLSBRes = Nfrac[`CORRSHIFTSZ-`NF];
                    FpUfRound = Nfrac[`CORRSHIFTSZ-`NF-2];
                end
                `FMT1: begin
                    FpRound = Nfrac[`CORRSHIFTSZ-`NF1-1];
                    FpLSBRes = Nfrac[`CORRSHIFTSZ-`NF1];
                    FpUfRound = Nfrac[`CORRSHIFTSZ-`NF1-2];
                end
                `FMT2: begin
                    FpRound = Nfrac[`CORRSHIFTSZ-`NF2-1];
                    FpLSBRes = Nfrac[`CORRSHIFTSZ-`NF2];
                    FpUfRound = Nfrac[`CORRSHIFTSZ-`NF2-2];
                end
                default: begin
                    FpRound = 1'bx;
                    FpLSBRes = 1'bx;
                    FpUfRound = 1'bx;
                end
            endcase
    end else if (`FPSIZES == 4) begin
        always_comb
            case (OutFmt)
                2'h3: begin
                    FpRound = Nfrac[`CORRSHIFTSZ-`Q_NF-1];
                    FpLSBRes = Nfrac[`CORRSHIFTSZ-`Q_NF];
                    FpUfRound = Nfrac[`CORRSHIFTSZ-`Q_NF-2];
                end
                2'h1: begin
                    FpRound = Nfrac[`CORRSHIFTSZ-`D_NF-1];
                    FpLSBRes = Nfrac[`CORRSHIFTSZ-`D_NF];
                    FpUfRound = Nfrac[`CORRSHIFTSZ-`D_NF-2];
                end
                2'h0: begin
                    FpRound = Nfrac[`CORRSHIFTSZ-`S_NF-1];
                    FpLSBRes = Nfrac[`CORRSHIFTSZ-`S_NF];
                    FpUfRound = Nfrac[`CORRSHIFTSZ-`S_NF-2];
                end
                2'h2: begin
                    FpRound = Nfrac[`CORRSHIFTSZ-`H_NF-1];
                    FpLSBRes = Nfrac[`CORRSHIFTSZ-`H_NF];
                    FpUfRound = Nfrac[`CORRSHIFTSZ-`H_NF-2];
                end
            endcase
    end

    assign R = ToInt&CvtOp ? Nfrac[`CORRSHIFTSZ-`XLEN-1] : FpRound;
    assign LSBRes = ToInt&CvtOp ? Nfrac[`CORRSHIFTSZ-`XLEN] : FpLSBRes;
    assign UfRound = ToInt&CvtOp ? Nfrac[`CORRSHIFTSZ-`XLEN-2] : FpUfRound;

    // used to determine underflow flag
    assign UfLSBRes = FpRound;
    // determine sticky
    assign S = UfSticky | UfRound;


    always_comb begin
        // Determine if you add 1
        case (Frm)
            3'b000: CalcPlus1 = R & (S| LSBRes);//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = Nsgn;//round down
            3'b011: CalcPlus1 = ~Nsgn;//round up
            3'b100: CalcPlus1 = R;//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
        // Determine if you add 1 (for underflow flag)
        case (Frm)
            3'b000: UfCalcPlus1 = UfRound & (UfSticky| UfLSBRes);//round to nearest even
            3'b001: UfCalcPlus1 = 0;//round to zero
            3'b010: UfCalcPlus1 = Nsgn;//round down
            3'b011: UfCalcPlus1 = ~Nsgn;//round up
            3'b100: UfCalcPlus1 = UfRound;//round to nearest max magnitude
            default: UfCalcPlus1 = 1'bx;
        endcase
   
    end

    // If an answer is exact don't round
    assign Plus1 = CalcPlus1 & (S | R);
    assign FpPlus1 = Plus1&~(ToInt&CvtOp);
    assign UfPlus1 = UfCalcPlus1 & S; // UfRound is part of sticky

    // Compute rounded result
    if (`FPSIZES == 1) begin
        assign RoundAdd = {{`FLEN{1'b0}}, FpPlus1};

    end else if (`FPSIZES == 2) begin
        // \/FLEN+1
        //  | NE+2 |        NF      |
        //  '-NE+2-^----NF1----^
        // `FLEN+1-`NE-2-`NF1 = FLEN-1-NE-NF1
        assign RoundAdd = OutFmt ? {{{`FLEN{1'b0}}}, FpPlus1} :
                                   {(`NE+1+`NF1)'(0), FpPlus1, (`FLEN-1-`NE-`NF1)'(0)};

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (OutFmt)
                `FMT:  RoundAdd = {{{`FLEN{1'b0}}}, FpPlus1};
                `FMT1: RoundAdd = {(`NE+1+`NF1)'(0), FpPlus1, (`FLEN-1-`NE-`NF1)'(0)};
                `FMT2: RoundAdd = {(`NE+1+`NF2)'(0), FpPlus1, (`FLEN-1-`NE-`NF2)'(0)};
                default: RoundAdd = (`FLEN+1)'(0);
            endcase
        end

    end else if (`FPSIZES == 4) begin        
        always_comb begin
            case (OutFmt)
                2'h3: RoundAdd = {{`FLEN{1'b0}}, FpPlus1};
                2'h1: RoundAdd = {(`NE+1+`D_NF)'(0), FpPlus1, (`FLEN-1-`NE-`D_NF)'(0)};
                2'h0: RoundAdd = {(`NE+1+`S_NF)'(0), FpPlus1, (`FLEN-1-`NE-`S_NF)'(0)};
                2'h2: RoundAdd = {(`NE+1+`H_NF)'(0), FpPlus1, (`FLEN-1-`NE-`H_NF)'(0)};
            endcase
        end

    end

    // determine the result to be roundned
    assign RoundFrac = Nfrac[`CORRSHIFTSZ-1:`CORRSHIFTSZ-`NF];
    
    always_comb
        case(PostProcSel)
            2'b10: Nexp = FmaSe; // fma
            2'b00: Nexp = {CvtCe[`NE], CvtCe}&{`NE+2{~CvtResDenormUf|CvtResUf}}; // cvt
            2'b01: Nexp = DivDone ? DivCorrExp : '0; // divide
            default: Nexp = '0; 
        endcase

    // round the result
    //      - if the fraction overflows one should be added to the exponent
    assign {FullRe, Rf} = {Nexp, RoundFrac} + RoundAdd;
    assign Re = FullRe[`NE-1:0];


endmodule