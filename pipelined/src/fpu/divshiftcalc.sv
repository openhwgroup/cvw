`include "wally-config.vh"

module divshiftcalc(
    input logic  [`DIVLEN+2:0] Quot,
    input logic  [`FMTBITS-1:0] Fmt,
    input logic [$clog2(`DIVLEN/2+3)-1:0] EarlyTermShiftDiv2M,
    input logic [`NE+1:0] DivCalcExpM,
    output logic [$clog2(`NORMSHIFTSZ)-1:0] DivShiftAmt,
    output logic [`NORMSHIFTSZ-1:0] DivShiftIn,
    output logic DivResDenorm,
    output logic [`NE+1:0] DivDenormShift
);
    logic [`NE+1:0] NormShift;
    logic [`NE+1:0] Nf;

    // is the result denromalized
    // if the exponent is 1 then the result needs to be normalized then the result is denormalizes
    assign DivResDenorm = DivCalcExpM[`NE+1]|(~|DivCalcExpM[`NE+1:0]);
    // select the proper fraction lengnth
    // if (`FPSIZES == 1) begin
    //     assign Nf = (`NE+2)'(`NF);

    // end else if (`FPSIZES == 2) begin
    //     assign Nf = Fmt ? (`NE+2)'(`NF) : (`NE+2)'(`NF1);

    // end else if (`FPSIZES == 3) begin
    //     always_comb
    //         case (Fmt)
    //             `FMT: Nf = (`NE+2)'(`NF);
    //             `FMT1: Nf = (`NE+2)'(`NF1);
    //             `FMT2: Nf = (`NE+2)'(`NF2);
    //             default: Nf = 1'bx;
    //         endcase
    // end else if (`FPSIZES == 4) begin
    //     always_comb
    //         case (Fmt)
    //             2'h3: Nf = (`NE+2)'(`Q_NF);
    //             2'h1: Nf = (`NE+2)'(`D_NF);
    //             2'h0: Nf = (`NE+2)'(`S_NF);
    //             2'h2: Nf = (`NE+2)'(`H_NF);
    //         endcase
    // end
    // if the result is denormalized
    //  00000000x.xxxxxx...                     Exp = DivCalcExpM
    //  .00000000xxxxxxx... >> NF+1             Exp = DivCalcExpM+NF+1
    //  .00xxxxxxxxxxxxx... << DivCalcExpM+NF+1  Exp = +1
    //  .0000xxxxxxxxxxx... >> 1                Exp = 1
    // Left shift amount  = DivCalcExpM+NF+1-1
    assign DivDenormShift = (`NE+2)'(`NF)+DivCalcExpM;
    // if the result is normalized
    //  00000000x.xxxxxx...                     Exp = DivCalcExpM
    //  .00000000xxxxxxx... >> NF+1             Exp = DivCalcExpM+NF+1
    //  00000000.xxxxxxx... << NF               Exp = DivCalcExpM+1
    //  00000000x.xxxxxx... << NF               Exp = DivCalcExpM (extra shift done afterwards)
    //  00000000xx.xxxxx... << 1?               Exp = DivCalcExpM-1 (determined after)
    // inital Left shift amount  = NF
    assign NormShift = (`NE+2)'(`NF);
    // if the shift amount is negitive then dont shift (keep sticky bit)
    assign DivShiftAmt = (DivResDenorm ?  DivDenormShift[$clog2(`NORMSHIFTSZ)-1:0]&{$clog2(`NORMSHIFTSZ){~DivDenormShift[`NE+1]}} : NormShift[$clog2(`NORMSHIFTSZ)-1:0])+{{$clog2(`NORMSHIFTSZ)-$clog2(`DIVLEN/2+3)-1{1'b0}}, EarlyTermShiftDiv2M&{$clog2(`DIVLEN/2+3){~DivDenormShift[`NE+1]}}, 1'b0};

    // *** may be able to reduce shifter size
    assign DivShiftIn = {{`NF{1'b0}}, Quot[`DIVLEN+2:0], {`NORMSHIFTSZ-`DIVLEN-3-`NF{1'b0}}};

endmodule
