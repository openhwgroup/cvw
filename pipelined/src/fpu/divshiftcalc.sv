`include "wally-config.vh"

module divshiftcalc(
    input logic  [`DIVLEN+2:0] Quot,
    input logic  [`NE+1:0] DivCalcExpM,
    input logic  [`FMTBITS-1:0] FmtM,
    input logic [$clog2(`DIVLEN/2+3)-1:0] EarlyTermShiftDiv2M,
    output logic [$clog2(`NORMSHIFTSZ)-1:0] DivShiftAmt,
    output logic [`NORMSHIFTSZ-1:0] DivShiftIn,
    output logic [`NE+1:0] CorrDivExp
);
    logic ResDenorm;
    logic [`NE+1:0] DenormShift;
    logic [`NE+1:0] NormShift;
    logic [`NE+1:0] Nf, NfPlus1;

    // is the result denromalized
    // if the exponent is 1 then the result needs to be normalized then the result is denormalizes
    assign ResDenorm = DivCalcExpM[`NE+1]|(~|DivCalcExpM[`NE+1:1]&~(DivCalcExpM[0]&Quot[`DIVLEN+2]));
    // select the proper fraction lengnth
    if (`FPSIZES == 1) begin
        assign Nf = (`NE+2)'(`NF);
        assign NfPlus1 = (`NE+2)'(`NF+1);

    end else if (`FPSIZES == 2) begin
        assign Nf = FmtM ? (`NE+2)'(`NF) : (`NE+2)'(`NF1);
        assign NfPlus1 = FmtM ? (`NE+2)'(`NF+1) : (`NE+2)'(`NF1+1);

    end else if (`FPSIZES == 3) begin
        always_comb
            case (FmtM)
                `FMT: begin
                    Nf = (`NE+2)'(`NF);
                    NfPlus1 = (`NE+2)'(`NF+1);
                end
                `FMT1: begin
                    Nf = (`NE+2)'(`NF1);
                    NfPlus1 = (`NE+2)'(`NF1+1);
                end
                `FMT2: begin
                    Nf = (`NE+2)'(`NF2);
                    NfPlus1 = (`NE+2)'(`NF2+1);
                end
                default: begin
                    Nf = 1'bx;
                    NfPlus1 = 1'bx;
                end
            endcase
    end else if (`FPSIZES == 4) begin
        always_comb
            case (FmtM)
                2'h3: begin
                    Nf = (`NE+2)'(`Q_NF);
                    NfPlus1 = (`NE+2)'(`Q_NF+1);
                end
                2'h1: begin
                    Nf = (`NE+2)'(`D_NF);
                    NfPlus1 = (`NE+2)'(`D_NF+1);
                end
                2'h0: begin
                    Nf = (`NE+2)'(`S_NF);
                    NfPlus1 = (`NE+2)'(`S_NF+1);
                end
                2'h2: begin
                    Nf = (`NE+2)'(`H_NF);
                    NfPlus1 = (`NE+2)'(`H_NF+1);
                end
            endcase
    end
    // if the result is denormalized
    //  00000000x.xxxxxx...                     Exp = DivCalcExp
    //  .00000000xxxxxxx... >> NF+1             Exp = DivCalcExp+NF+1
    //  .000xxxxxxxxxxxx... << DivCalcExp+NF+1  Exp = 0
    //  .0000xxxxxxxxxxx... >> 1                Exp = 1
    // Left shift amount  = DivCalcExp+NF+1-1
    assign DenormShift = Nf+DivCalcExpM;
    // if the result is normalized
    //  00000000x.xxxxxx...                     Exp = DivCalcExp
    //  .00000000xxxxxxx... >> NF+1             Exp = DivCalcExp+NF+1
    //  00000000x.xxxxxx... << NF+1             Exp = DivCalcExp
    //  00000000xx.xxxxx... << 1?               Exp = DivCalcExp-1
    // Left shift amount  = NF+1 plus 1 if normalization required
    assign NormShift = NfPlus1 + {(`NE+1)'(0), ~Quot[`DIVLEN+2]};
    // if the shift amount is negitive then dont shift (keep sticky bit)
    assign DivShiftAmt = (ResDenorm ?  DenormShift[$clog2(`NORMSHIFTSZ)-1:0]&{$clog2(`NORMSHIFTSZ){~DenormShift[`NE+1]}} : NormShift[$clog2(`NORMSHIFTSZ)-1:0])+{{$clog2(`NORMSHIFTSZ)-$clog2(`DIVLEN/2+3)-1{1'b0}}, EarlyTermShiftDiv2M, 1'b0};

    // *** may be able to reduce shifter size
    assign DivShiftIn = {{`NF{1'b0}}, Quot[`DIVLEN+2:0], {`NORMSHIFTSZ-`DIVLEN-3-`NF{1'b0}}};
    // the quotent is in the range [.5,2) if there is no early termination
    // if the quotent < 1 and not denormal then subtract 1 to account for the normalization shift
    assign CorrDivExp = (ResDenorm&~DenormShift[`NE+1]) ? (`NE+2)'(0) : DivCalcExpM - {(`NE+1)'(0), ~Quot[`DIVLEN+2]};

endmodule
