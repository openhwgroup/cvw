`include "wally-config.vh"

module divshiftcalc(
    input logic  [`QLEN-1:0] Quot,
    input logic  [`FMTBITS-1:0] Fmt,
    input logic [`DURLEN-1:0] DivEarlyTermShift,
    input logic [`NE+1:0] DivCalcExp,
    output logic [$clog2(`NORMSHIFTSZ)-1:0] DivShiftAmt,
    output logic [`NORMSHIFTSZ-1:0] DivShiftIn,
    output logic DivResDenorm,
    output logic [`NE+1:0] DivDenormShift
);
    logic [`NE+1:0] NormShift;

    // is the result denromalized
    // if the exponent is 1 then the result needs to be normalized then the result is denormalizes
    assign DivResDenorm = DivCalcExp[`NE+1]|(~|DivCalcExp[`NE+1:0]);

    // if the result is denormalized
    //  00000000x.xxxxxx...                     Exp = DivCalcExp
    //  .00000000xxxxxxx... >> NF+1             Exp = DivCalcExp+NF+1
    //  .00xxxxxxxxxxxxx... << DivCalcExp+NF+1  Exp = +1
    //  .0000xxxxxxxxxxx... >> 1                Exp = 1
    // Left shift amount  = DivCalcExp+NF+1-1
    assign DivDenormShift = (`NE+2)'(`NF)+DivCalcExp;
    // if the result is normalized
    //  00000000x.xxxxxx...                     Exp = DivCalcExp
    //  .00000000xxxxxxx... >> NF+1             Exp = DivCalcExp+NF+1
    //  00000000.xxxxxxx... << NF               Exp = DivCalcExp+1
    //  00000000x.xxxxxx... << NF               Exp = DivCalcExp (extra shift done afterwards)
    //  00000000xx.xxxxx... << 1?               Exp = DivCalcExp-1 (determined after)
    // inital Left shift amount  = NF
    assign NormShift = (`NE+2)'(`NF);
    // if the shift amount is negitive then dont shift (keep sticky bit)
    // need to multiply the early termination shift by LOGR*DIVCOPIES =  left shift of log2(LOGR*DIVCOPIES)
    assign DivShiftAmt = (DivResDenorm ?  DivDenormShift[$clog2(`NORMSHIFTSZ)-1:0]&{$clog2(`NORMSHIFTSZ){~DivDenormShift[`NE+1]}} : NormShift[$clog2(`NORMSHIFTSZ)-1:0])+{{$clog2(`NORMSHIFTSZ)-`DURLEN-$clog2(`LOGR*`DIVCOPIES){1'b0}}, DivEarlyTermShift&{`DURLEN{~DivDenormShift[`NE+1]}}, ($clog2(`LOGR*`DIVCOPIES))'(0)};

    // *** may be able to reduce shifter size
    assign DivShiftIn = {{`NF-1{1'b0}}, Quot, {`NORMSHIFTSZ-`QLEN+1-`NF{1'b0}}};

endmodule
