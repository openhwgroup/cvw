///////////////////////////////////////////
// round.sv
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
//    input logic                     DivDone,
    input logic  [1:0]              PostProcSel,
    input logic                     CvtResDenormUf,
    input logic                     CvtResUf,
    input logic  [`CORRSHIFTSZ-1:0] Mf,
    input logic                     FmaASticky,  // addend's sticky bit
    input logic  [`NE+1:0]          FmaMe,         // exponent of the normalized sum
    input logic                     Ms,      // the result's sign
    input logic  [`NE:0]            CvtCe,    // the calculated expoent
    input logic  [`NE+1:0]          Qe,    // the calculated expoent
    input logic                     DivS,             // sticky bit
    output logic                    UfPlus1,  // do you add or subtract on from the result
    output logic [`NE+1:0]          FullRe,      // Re with bits to determine sign and overflow
    output logic [`NF-1:0]          Rf,         // Result fraction
    output logic [`NE-1:0]          Re,          // Result exponent
    output logic                    S,             // sticky bit
    output logic [`NE+1:0]          Me,
    output logic                    Plus1,
    output logic                    R, G // bits needed to calculate rounding
);
    logic           UfCalcPlus1; 
    logic           NormS;  // normalized sum's sticky bit
    logic [`NF-1:0] RoundFrac;
    logic           FpRes, IntRes;
    logic           FpG, FpL, FpR;
    logic           L; // lsb of result
    logic           CalcPlus1, FpPlus1;
    logic [`FLEN:0] RoundAdd;           // how much to add to the result

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
        if (`XLENPOS == 1)assign NormS = (|Mf[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                 (|Mf[`CORRSHIFTSZ-`XLEN-2:0]);
    //     2: NF > XLEN
        if (`XLENPOS == 2)assign NormS = (|Mf[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&IntRes) |
                                                 (|Mf[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 2) begin
        // XLEN is either 64 or 32
        // so half and single are always smaller then XLEN

        // 1: XLEN > NF   > NF1
        if (`XLENPOS == 1) assign NormS = (|Mf[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&FpRes&~OutFmt) |
                                                  (|Mf[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                  (|Mf[`CORRSHIFTSZ-`XLEN-2:0]);
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormS = (|Mf[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~OutFmt) | 
                                                  (|Mf[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&(IntRes|~OutFmt)) |
                                                  (|Mf[`CORRSHIFTSZ-`NF-2:0]);
        // 3: NF   > NF1  > XLEN
        if (`XLENPOS == 3) assign NormS = (|Mf[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF1-1]&IntRes) |
                                                  (|Mf[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&(~OutFmt|IntRes)) |
                                                  (|Mf[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 3) begin
        // 1: XLEN > NF   > NF1
        if (`XLENPOS == 1) assign NormS = (|Mf[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`NF1-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|Mf[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&FpRes&~(OutFmt==`FMT)) |
                                                  (|Mf[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                  (|Mf[`CORRSHIFTSZ-`XLEN-2:0]);
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormS = (|Mf[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`NF1-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|Mf[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~(OutFmt==`FMT)) | 
                                                  (|Mf[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&(IntRes|~(OutFmt==`FMT))) |
                                                  (|Mf[`CORRSHIFTSZ-`NF-2:0]);
        // 3: NF   > NF1  > XLEN
        if (`XLENPOS == 3) assign NormS = (|Mf[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|Mf[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF1-1]&((OutFmt==`FMT1)|IntRes)) |
                                                  (|Mf[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&(~(OutFmt==`FMT)|IntRes)) |
                                                  (|Mf[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 4) begin
        // Quad precision will always be greater than XLEN
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormS = (|Mf[`CORRSHIFTSZ-`H_NF-2:`CORRSHIFTSZ-`S_NF-1]&FpRes&(OutFmt==`H_FMT)) |
                                                  (|Mf[`CORRSHIFTSZ-`S_NF-2:`CORRSHIFTSZ-`D_NF-1]&FpRes&((OutFmt==`S_FMT)|(OutFmt==`H_FMT))) | 
                                                  (|Mf[`CORRSHIFTSZ-`D_NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~(OutFmt==`Q_FMT)) | 
                                                  (|Mf[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`Q_NF-1]&(~(OutFmt==`Q_FMT)|IntRes)) |
                                                  (|Mf[`CORRSHIFTSZ-`Q_NF-2:0]);
        // 3: NF   > NF1  > XLEN
        // The extra XLEN bit will be ored later when caculating the final sticky bit - the ufplus1 not needed for integer
        if (`XLENPOS == 3) assign NormS = (|Mf[`CORRSHIFTSZ-`H_NF-2:`CORRSHIFTSZ-`S_NF-1]&FpRes&(OutFmt==`H_FMT)) |
                                                  (|Mf[`CORRSHIFTSZ-`S_NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&((OutFmt==`S_FMT)|(OutFmt==`H_FMT))) |
                                                  (|Mf[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`D_NF-1]&((OutFmt==`S_FMT)|(OutFmt==`H_FMT)|IntRes)) |
                                                  (|Mf[`CORRSHIFTSZ-`D_NF-2:`CORRSHIFTSZ-`Q_NF-1]&(~(OutFmt==`Q_FMT)|IntRes)) |
                                                  (|Mf[`CORRSHIFTSZ-`Q_NF-2:0]);

    end
    


    // only add the Addend sticky if doing an FMA opperation
    //      - the shifter shifts too far left when there's an underflow (shifting out all possible sticky bits)
    assign S = FmaASticky&FmaOp | NormS | CvtResUf&CvtOp | FmaMe[`NE+1]&FmaOp | DivS&DivOp;
    
    // determine round and LSB of the rounded value
    //      - underflow round bit is used to determint the underflow flag
    if (`FPSIZES == 1) begin
        assign FpG = Mf[`CORRSHIFTSZ-`NF-1];
        assign FpL = Mf[`CORRSHIFTSZ-`NF];
        assign FpR = Mf[`CORRSHIFTSZ-`NF-2];

    end else if (`FPSIZES == 2) begin
        assign FpG = OutFmt ? Mf[`CORRSHIFTSZ-`NF-1] : Mf[`CORRSHIFTSZ-`NF1-1];
        assign FpL = OutFmt ? Mf[`CORRSHIFTSZ-`NF] : Mf[`CORRSHIFTSZ-`NF1];
        assign FpR = OutFmt ? Mf[`CORRSHIFTSZ-`NF-2] : Mf[`CORRSHIFTSZ-`NF1-2];

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT: begin
                    FpG = Mf[`CORRSHIFTSZ-`NF-1];
                    FpL = Mf[`CORRSHIFTSZ-`NF];
                    FpR = Mf[`CORRSHIFTSZ-`NF-2];
                end
                `FMT1: begin
                    FpG = Mf[`CORRSHIFTSZ-`NF1-1];
                    FpL = Mf[`CORRSHIFTSZ-`NF1];
                    FpR = Mf[`CORRSHIFTSZ-`NF1-2];
                end
                `FMT2: begin
                    FpG = Mf[`CORRSHIFTSZ-`NF2-1];
                    FpL = Mf[`CORRSHIFTSZ-`NF2];
                    FpR = Mf[`CORRSHIFTSZ-`NF2-2];
                end
                default: begin
                    FpG = 1'bx;
                    FpL = 1'bx;
                    FpR = 1'bx;
                end
            endcase
    end else if (`FPSIZES == 4) begin
        always_comb
            case (OutFmt)
                2'h3: begin
                    FpG = Mf[`CORRSHIFTSZ-`Q_NF-1];
                    FpL = Mf[`CORRSHIFTSZ-`Q_NF];
                    FpR = Mf[`CORRSHIFTSZ-`Q_NF-2];
                end
                2'h1: begin
                    FpG = Mf[`CORRSHIFTSZ-`D_NF-1];
                    FpL = Mf[`CORRSHIFTSZ-`D_NF];
                    FpR = Mf[`CORRSHIFTSZ-`D_NF-2];
                end
                2'h0: begin
                    FpG = Mf[`CORRSHIFTSZ-`S_NF-1];
                    FpL = Mf[`CORRSHIFTSZ-`S_NF];
                    FpR = Mf[`CORRSHIFTSZ-`S_NF-2];
                end
                2'h2: begin
                    FpG = Mf[`CORRSHIFTSZ-`H_NF-1];
                    FpL = Mf[`CORRSHIFTSZ-`H_NF];
                    FpR = Mf[`CORRSHIFTSZ-`H_NF-2];
                end
            endcase
    end

    assign G = ToInt&CvtOp ? Mf[`CORRSHIFTSZ-`XLEN-1] : FpG;
    assign L = ToInt&CvtOp ? Mf[`CORRSHIFTSZ-`XLEN] : FpL;
    assign R = ToInt&CvtOp ? Mf[`CORRSHIFTSZ-`XLEN-2] : FpR;


    always_comb begin
        // Determine if you add 1
        case (Frm)
            3'b000: CalcPlus1 = G & (R|S|L);//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = Ms;//round down
            3'b011: CalcPlus1 = ~Ms;//round up
            3'b100: CalcPlus1 = G;//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
        // Determine if you add 1 (for underflow flag)
        case (Frm)
            3'b000: UfCalcPlus1 = R & (S|G);//round to nearest even
            3'b001: UfCalcPlus1 = 0;//round to zero
            3'b010: UfCalcPlus1 = Ms;//round down
            3'b011: UfCalcPlus1 = ~Ms;//round up
            3'b100: UfCalcPlus1 = R;//round to nearest max magnitude
            default: UfCalcPlus1 = 1'bx;
        endcase
   
    end

    // If an answer is exact don't round
    assign Plus1 = CalcPlus1 & (S|R|G);
    assign FpPlus1 = Plus1&~(ToInt&CvtOp);
    assign UfPlus1 = UfCalcPlus1 & (S|R);

    // Compute rounded result
    if (`FPSIZES == 1) begin
        assign RoundAdd = {{`FLEN{1'b0}}, FpPlus1};

    end else if (`FPSIZES == 2) begin
        // \/FLEN+1
        //  | NE+2 |        NF      |
        //  '-NE+2-^----NF1----^
        // `FLEN+1-`NE-2-`NF1 = FLEN-1-NE-NF1
        assign RoundAdd = {(`NE+1+`NF1)'(0), FpPlus1&~OutFmt, (`NF-`NF1-1)'(0), FpPlus1&OutFmt};

    end else if (`FPSIZES == 3) begin
        assign RoundAdd = {(`NE+1+`NF2)'(0), FpPlus1&(OutFmt==`FMT2), (`NF1-`NF2-1)'(0), FpPlus1&(OutFmt==`FMT1), (`NF-`NF1-1)'(0), FpPlus1&(OutFmt==`FMT)};

    end else if (`FPSIZES == 4)      
        assign RoundAdd = {(`Q_NE+1+`H_NF)'(0), FpPlus1&(OutFmt==`H_FMT), (`S_NF-`H_NF-1)'(0), FpPlus1&(OutFmt==`S_FMT), (`D_NF-`S_NF-1)'(0), FpPlus1&(OutFmt==`D_FMT), (`Q_NF-`D_NF-1)'(0), FpPlus1&(OutFmt==`Q_FMT)};

    // determine the result to be roundned
    assign RoundFrac = Mf[`CORRSHIFTSZ-1:`CORRSHIFTSZ-`NF];
    
    always_comb
        case(PostProcSel)
            2'b10: Me = FmaMe; // fma
            2'b00: Me = {CvtCe[`NE], CvtCe}&{`NE+2{~CvtResDenormUf|CvtResUf}}; // cvt
            // 2'b01: Me = DivDone ? Qe : '0; // divide
            2'b01: Me = Qe; // divide
            default: Me = '0; 
        endcase

    // round the result
    //      - if the fraction overflows one should be added to the exponent
    assign {FullRe, Rf} = {Me, RoundFrac} + RoundAdd;
    assign Re = FullRe[`NE-1:0];


endmodule