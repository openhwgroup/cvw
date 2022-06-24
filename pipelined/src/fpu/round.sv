`include "wally-config.vh"
// what position is XLEN in?
//  options: 
//     1: XLEN > NF   > NF1
//     2: NF   > XLEN > NF1
//     3: NF   > NF1  > XLEN
//  single and double will always be smaller than XLEN
`define XLENPOS ((`XLEN>`NF) ? 1 : (`XLEN>`NF1) ? 2 : 3)

module round(
    input logic  [`FMTBITS-1:0] OutFmt,       // precision 1 = double 0 = single
    input logic  [2:0]          FrmM,       // rounding mode
    input logic                 FmaOp,
    input logic                 DivOp,
    input logic [1:0] PostProcSelM,
    input logic                 CvtResDenormUfM,
    input logic                 ToInt,
    input logic                 CvtOp,
    input logic                 CvtResUf,
    input logic [`CORRSHIFTSZ-1:0]  CorrShifted,
    input logic                 AddendStickyM,  // addend's sticky bit
    input logic                 ZZeroM,         // is Z zero
    input logic                 InvZM,          // invert Z
    input logic  [`NE+1:0]      SumExp,         // exponent of the normalized sum
    input logic                 RoundSgn,      // the result's sign
    input logic [`NE:0]           CvtCalcExpM,    // the calculated expoent
    input logic [`NE+1:0]           CorrDivExp,    // the calculated expoent
    input logic                DivStickyM,             // sticky bit
    input logic DivNegStickyM,
    output logic                UfPlus1,  // do you add or subtract on from the result
    output logic [`NE+1:0]      FullResExp,      // ResExp with bits to determine sign and overflow
    output logic [`NF-1:0]      ResFrac,         // Result fraction
    output logic [`NE-1:0]      ResExp,          // Result exponent
    output logic                Sticky,             // sticky bit
    output logic [`NE+1:0] RoundExp,
    output logic Plus1,
    output logic [`FLEN:0]      RoundAdd,           // how much to add to the result
    output logic                Round, UfLSBRes // bits needed to calculate rounding
);
    logic           LSBRes;         // bit used for rounding - least significant bit of the normalized sum
    logic           SubBySmallNum, UfSubBySmallNum;  // was there supposed to be a subtraction by a small number
    logic           UfCalcPlus1, CalcMinus1, Minus1; // do you add or subtract on from the result
    logic                 NormSumSticky;  // normalized sum's sticky bit
    logic                 UfSticky;   // sticky bit for underlow calculation
    logic [`NF-1:0] RoundFrac;
    logic FpRes, IntRes;
    logic           UfRound;
    logic           FpRound, FpLSBRes, FpUfRound;
    logic           CalcPlus1, FpPlus1;

    ///////////////////////////////////////////////////////////////////////////////
    // Rounding
    ///////////////////////////////////////////////////////////////////////////////

    // round to nearest even
    //      {Round, Sticky}
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
    //      {Guard, Round, Sticky}
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
        if (`XLENPOS == 1)assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                 (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:0]);
    //     2: NF > XLEN
        if (`XLENPOS == 2)assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&IntRes) |
                                                 (|CorrShifted[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 2) begin
        // XLEN is either 64 or 32
        // so half and single are always smaller then XLEN

        // 1: XLEN > NF   > NF1
        if (`XLENPOS == 1) assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&FpRes&~OutFmt) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:0]);
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~OutFmt) | 
                                                  (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&(IntRes|~OutFmt)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF-2:0]);
        // 3: NF   > NF1  > XLEN
        if (`XLENPOS == 3) assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF1-1]&IntRes) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&(~OutFmt|IntRes)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 3) begin
        // 1: XLEN > NF   > NF1
        if (`XLENPOS == 1) assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`NF1-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&FpRes&~(OutFmt==`FMT)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:0]);
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`NF1-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~(OutFmt==`FMT)) | 
                                                  (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF-1]&(IntRes|~(OutFmt==`FMT))) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF-2:0]);
        // 3: NF   > NF1  > XLEN
        if (`XLENPOS == 3) assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`NF2-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&(OutFmt==`FMT1)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`NF1-1]&((OutFmt==`FMT1)|IntRes)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF1-2:`CORRSHIFTSZ-`NF-1]&(~(OutFmt==`FMT)|IntRes)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`NF-2:0]);

    end else if (`FPSIZES == 4) begin
        // Quad precision will always be greater than XLEN
        // 2: NF   > XLEN > NF1
        if (`XLENPOS == 2) assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`H_NF-2:`CORRSHIFTSZ-`S_NF-1]&FpRes&(OutFmt==`H_FMT)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`S_NF-2:`CORRSHIFTSZ-`D_NF-1]&FpRes&((OutFmt==`S_FMT)|(OutFmt==`H_FMT))) | 
                                                  (|CorrShifted[`CORRSHIFTSZ-`D_NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&~(OutFmt==`Q_FMT)) | 
                                                  (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`Q_NF-1]&(~(OutFmt==`Q_FMT)|IntRes)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`Q_NF-2:0]);
        // 3: NF   > NF1  > XLEN
        // The extra XLEN bit will be ored later when caculating the final sticky bit - the ufplus1 not needed for integer
        if (`XLENPOS == 3) assign NormSumSticky = (|CorrShifted[`CORRSHIFTSZ-`H_NF-2:`CORRSHIFTSZ-`S_NF-1]&FpRes&(OutFmt==`H_FMT)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`S_NF-2:`CORRSHIFTSZ-`XLEN-1]&FpRes&((OutFmt==`S_FMT)|(OutFmt==`H_FMT))) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`XLEN-2:`CORRSHIFTSZ-`D_NF-1]&((OutFmt==`S_FMT)|(OutFmt==`H_FMT)|IntRes)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`D_NF-2:`CORRSHIFTSZ-`Q_NF-1]&(~(OutFmt==`Q_FMT)|IntRes)) |
                                                  (|CorrShifted[`CORRSHIFTSZ-`Q_NF-2:0]);

    end
    


    // only add the Addend sticky if doing an FMA opperation
    //      - the shifter shifts too far left when there's an underflow (shifting out all possible sticky bits)
    assign UfSticky = AddendStickyM&FmaOp | NormSumSticky | CvtResUf&CvtOp | SumExp[`NE+1]&FmaOp | DivStickyM&DivOp;
    
    // determine round and LSB of the rounded value
    //      - underflow round bit is used to determint the underflow flag
    if (`FPSIZES == 1) begin
        assign FpRound = CorrShifted[`CORRSHIFTSZ-`NF-1];
        assign FpLSBRes = CorrShifted[`CORRSHIFTSZ-`NF];
        assign FpUfRound = CorrShifted[`CORRSHIFTSZ-`NF-2];

    end else if (`FPSIZES == 2) begin
        assign FpRound = OutFmt ? CorrShifted[`CORRSHIFTSZ-`NF-1] : CorrShifted[`CORRSHIFTSZ-`NF1-1];
        assign FpLSBRes = OutFmt ? CorrShifted[`CORRSHIFTSZ-`NF] : CorrShifted[`CORRSHIFTSZ-`NF1];
        assign FpUfRound = OutFmt ? CorrShifted[`CORRSHIFTSZ-`NF-2] : CorrShifted[`CORRSHIFTSZ-`NF1-2];

    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT: begin
                    FpRound = CorrShifted[`CORRSHIFTSZ-`NF-1];
                    FpLSBRes = CorrShifted[`CORRSHIFTSZ-`NF];
                    FpUfRound = CorrShifted[`CORRSHIFTSZ-`NF-2];
                end
                `FMT1: begin
                    FpRound = CorrShifted[`CORRSHIFTSZ-`NF1-1];
                    FpLSBRes = CorrShifted[`CORRSHIFTSZ-`NF1];
                    FpUfRound = CorrShifted[`CORRSHIFTSZ-`NF1-2];
                end
                `FMT2: begin
                    FpRound = CorrShifted[`CORRSHIFTSZ-`NF2-1];
                    FpLSBRes = CorrShifted[`CORRSHIFTSZ-`NF2];
                    FpUfRound = CorrShifted[`CORRSHIFTSZ-`NF2-2];
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
                    FpRound = CorrShifted[`CORRSHIFTSZ-`Q_NF-1];
                    FpLSBRes = CorrShifted[`CORRSHIFTSZ-`Q_NF];
                    FpUfRound = CorrShifted[`CORRSHIFTSZ-`Q_NF-2];
                end
                2'h1: begin
                    FpRound = CorrShifted[`CORRSHIFTSZ-`D_NF-1];
                    FpLSBRes = CorrShifted[`CORRSHIFTSZ-`D_NF];
                    FpUfRound = CorrShifted[`CORRSHIFTSZ-`D_NF-2];
                end
                2'h0: begin
                    FpRound = CorrShifted[`CORRSHIFTSZ-`S_NF-1];
                    FpLSBRes = CorrShifted[`CORRSHIFTSZ-`S_NF];
                    FpUfRound = CorrShifted[`CORRSHIFTSZ-`S_NF-2];
                end
                2'h2: begin
                    FpRound = CorrShifted[`CORRSHIFTSZ-`H_NF-1];
                    FpLSBRes = CorrShifted[`CORRSHIFTSZ-`H_NF];
                    FpUfRound = CorrShifted[`CORRSHIFTSZ-`H_NF-2];
                end
            endcase
    end

    assign Round = ToInt&CvtOp ? CorrShifted[`CORRSHIFTSZ-`XLEN-1] : FpRound;
    assign LSBRes = ToInt&CvtOp ? CorrShifted[`CORRSHIFTSZ-`XLEN] : FpLSBRes;
    assign UfRound = ToInt&CvtOp ? CorrShifted[`CORRSHIFTSZ-`XLEN-2] : FpUfRound;

    // used to determine underflow flag
    assign UfLSBRes = FpRound;
    // determine sticky
    assign Sticky = UfSticky | UfRound;


    // Deterimine if a small number was supposed to be subtrated
    //  - for FMA or if division has a negitive sticky bit
    assign SubBySmallNum = ((AddendStickyM&FmaOp&~ZZeroM&InvZM) | (DivNegStickyM&DivOp)) & ~(NormSumSticky|UfRound);
    assign UfSubBySmallNum = ((AddendStickyM&FmaOp&~ZZeroM&InvZM) | (DivNegStickyM&DivOp)) & ~NormSumSticky;


    always_comb begin
        // Determine if you add 1
        case (FrmM)
            3'b000: CalcPlus1 = Round & ((Sticky| LSBRes)&~SubBySmallNum);//round to nearest even
            3'b001: CalcPlus1 = 0;//round to zero
            3'b010: CalcPlus1 = RoundSgn & ~(SubBySmallNum & ~Round);//round down
            3'b011: CalcPlus1 = ~RoundSgn & ~(SubBySmallNum & ~Round);//round up
            3'b100: CalcPlus1 = Round & ~SubBySmallNum;//round to nearest max magnitude
            default: CalcPlus1 = 1'bx;
        endcase
        // Determine if you add 1 (for underflow flag)
        case (FrmM)
            3'b000: UfCalcPlus1 = UfRound & ((UfSticky| UfLSBRes)&~UfSubBySmallNum);//round to nearest even
            3'b001: UfCalcPlus1 = 0;//round to zero
            3'b010: UfCalcPlus1 = RoundSgn & ~(UfSubBySmallNum & ~UfRound);//round down
            3'b011: UfCalcPlus1 = ~RoundSgn & ~(UfSubBySmallNum & ~UfRound);//round up
            3'b100: UfCalcPlus1 = UfRound & ~UfSubBySmallNum;//round to nearest max magnitude
            default: UfCalcPlus1 = 1'bx;
        endcase
        // Determine if you subtract 1
        case (FrmM)
            3'b000: CalcMinus1 = 0;//round to nearest even
            3'b001: CalcMinus1 = SubBySmallNum & ~Round;//round to zero
            3'b010: CalcMinus1 = ~RoundSgn & ~Round & SubBySmallNum;//round down
            3'b011: CalcMinus1 = RoundSgn & ~Round & SubBySmallNum;//round up
            3'b100: CalcMinus1 = 0;//round to nearest max magnitude
            default: CalcMinus1 = 1'bx;
        endcase
   
    end

    // If an answer is exact don't round
    assign Plus1 = CalcPlus1 & (Sticky | Round);
    assign FpPlus1 = Plus1&~(ToInt&CvtOp);
    assign UfPlus1 = UfCalcPlus1 & Sticky; // UfRound is part of sticky
    assign Minus1 = CalcMinus1 & (Sticky | Round);

    // Compute rounded result
    if (`FPSIZES == 1) begin
        assign RoundAdd = Minus1 ? {`FLEN+1{1'b1}} : {{`FLEN{1'b0}}, FpPlus1};

    end else if (`FPSIZES == 2) begin
        // \/FLEN+1
        //  | NE+2 |        NF      |
        //  '-NE+2-^----NF1----^
        // `FLEN+1-`NE-2-`NF1 = FLEN-1-NE-NF1
        assign RoundAdd = OutFmt ? Minus1 ? {`FLEN+1{1'b1}} : {{{`FLEN{1'b0}}}, FpPlus1} :
                                   Minus1 ? {{`NE+2+`NF1{1'b1}}, (`FLEN-1-`NE-`NF1)'(0)} : {(`NE+1+`NF1)'(0), FpPlus1, (`FLEN-1-`NE-`NF1)'(0)};

    end else if (`FPSIZES == 3) begin
        always_comb begin
            case (OutFmt)
                `FMT:  RoundAdd = Minus1 ? {`FLEN+1{1'b1}} : {{{`FLEN{1'b0}}}, FpPlus1};
                `FMT1: RoundAdd = Minus1 ? {{`NE+2+`NF1{1'b1}}, (`FLEN-1-`NE-`NF1)'(0)} : {(`NE+1+`NF1)'(0), FpPlus1, (`FLEN-1-`NE-`NF1)'(0)};
                `FMT2: RoundAdd = Minus1 ? {{`NE+2+`NF2{1'b1}}, (`FLEN-1-`NE-`NF2)'(0)} : {(`NE+1+`NF2)'(0), FpPlus1, (`FLEN-1-`NE-`NF2)'(0)};
                default: RoundAdd = (`FLEN+1)'(0);
            endcase
        end

    end else if (`FPSIZES == 4) begin        
        always_comb begin
            case (OutFmt)
                2'h3: RoundAdd = Minus1 ? {`FLEN+1{1'b1}} : {{{`FLEN{1'b0}}}, FpPlus1};
                2'h1: RoundAdd = Minus1 ? {{`NE+2+`D_NF{1'b1}}, (`FLEN-1-`NE-`D_NF)'(0)} : {(`NE+1+`D_NF)'(0), FpPlus1, (`FLEN-1-`NE-`D_NF)'(0)};
                2'h0: RoundAdd = Minus1 ? {{`NE+2+`S_NF{1'b1}}, (`FLEN-1-`NE-`S_NF)'(0)} : {(`NE+1+`S_NF)'(0), FpPlus1, (`FLEN-1-`NE-`S_NF)'(0)};
                2'h2: RoundAdd = Minus1 ? {{`NE+2+`H_NF{1'b1}}, (`FLEN-1-`NE-`H_NF)'(0)} : {(`NE+1+`H_NF)'(0), FpPlus1, (`FLEN-1-`NE-`H_NF)'(0)};
            endcase
        end

    end

    // determine the result to be roundned
    assign RoundFrac = CorrShifted[`CORRSHIFTSZ-1:`CORRSHIFTSZ-`NF];
    
    always_comb
        case(PostProcSelM)
            2'b10: RoundExp = SumExp; // fma
            2'b00: RoundExp = {CvtCalcExpM[`NE], CvtCalcExpM}&{`NE+2{~CvtResDenormUfM|CvtResUf}}; // cvt
            2'b01: RoundExp = CorrDivExp; // divide
            default: RoundExp = 0; 
        endcase

    // round the result
    //      - if the fraction overflows one should be added to the exponent
    assign {FullResExp, ResFrac} = {RoundExp, RoundFrac} + RoundAdd;
    assign ResExp = FullResExp[`NE-1:0];


endmodule