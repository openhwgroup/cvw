`include "wally-config.vh"

module divshiftcalc(
    input logic  [`DIVLEN+2:0] Quot,
    input logic  [`NE+1:0] DivCalcExpM,
    output logic [$clog2(`NORMSHIFTSZ)-1:0] DivShiftAmt,
    output logic [`NORMSHIFTSZ-1:0] DivShiftIn,
    output logic [`NE+1:0] CorrDivExp
);
    logic ResDenorm;
    logic [`NE+1:0] DenormShift;
    logic [`NE+1:0] NormShift;

    // is the result denromalized
    // if the exponent is 1 then the result needs to be normalized then the result is denormalizes
    assign ResDenorm = DivCalcExpM[`NE+1]|(~|DivCalcExpM[`NE+1:1]&~(DivCalcExpM[0]&Quot[`DIVLEN+2]));
    // if the result is denormalized
    //  00000000x.xxxxxx...                     Exp = DivCalcExp
    //  .00000000xxxxxxx... >> NF+1             Exp = DivCalcExp+NF+1
    //  .000xxxxxxxxxxxx... << DivCalcExp+NF+1  Exp = 0
    //  .0000xxxxxxxxxxx... >> 1                Exp = 1
    // Left shift amount  = DivCalcExp+NF+1-1
    assign DenormShift = (`NE+2)'(`NF)+DivCalcExpM;
    // if the result is denormalized
    //  00000000x.xxxxxx...                     Exp = DivCalcExp
    //  .00000000xxxxxxx... >> NF+1             Exp = DivCalcExp+NF+1
    //  00000000x.xxxxxx... << NF+1             Exp = DivCalcExp
    //  00000000xx.xxxxx... << 1?               Exp = DivCalcExp-1
    // Left shift amount  = NF+1 plus 1 if normalization required
    assign NormShift = (`NE+2)'(`NF+1) + {(`NE+1)'(0), ~Quot[`DIVLEN+2]};
    assign DivShiftAmt = ResDenorm ?  DenormShift[$clog2(`NORMSHIFTSZ)-1:0] : NormShift[$clog2(`NORMSHIFTSZ)-1:0];

    // assign DivShiftIn = {(`NF)'(0), Quot[`DIVLEN+2:0], {`NORMSHIFTSZ-`DIVLEN-3-`NF{1'b0}}};
    // the quotent is in the range [.5,2)
    // if the quotent < 1 and not denormal then subtract 1 to account for the normalization shift
    assign CorrDivExp = (ResDenorm&~DenormShift[`NE+1]) ? (`NE+2)'(0) : DivCalcExpM - {(`NE+1)'(0), ~Quot[`DIVLEN+2]};

endmodule
