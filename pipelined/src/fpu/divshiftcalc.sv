`include "wally-config.vh"

module divshiftcalc(
    input logic  [`DIVb-(`RADIX/4):0] DivQm,
    input logic  [`FMTBITS-1:0] Fmt,
    input logic Sqrt,
    input logic [`DURLEN-1:0] DivEarlyTermShift,
    input logic [`NE+1:0] DivQe,
    output logic [$clog2(`NORMSHIFTSZ)-1:0] DivShiftAmt,
    output logic [`NORMSHIFTSZ-1:0] DivShiftIn,
    output logic DivResDenorm,
    output logic [`NE+1:0] DivDenormShift
);
    logic [`NE+1:0] NormShift;

    // is the result denromalized
    // if the exponent is 1 then the result needs to be normalized then the result is denormalizes
    assign DivResDenorm = DivQe[`NE+1]|(~|DivQe[`NE+1:0]);

    // if the result is denormalized
    //  00000000x.xxxxxx...                     Exp = DivQe
    //  .00000000xxxxxxx... >> NF+1             Exp = DivQe+NF+1
    //  .00xxxxxxxxxxxxx... << DivQe+NF+1  Exp = +1
    //  .0000xxxxxxxxxxx... >> 1                Exp = 1
    // Left shift amount  = DivQe+NF+1-1
    assign DivDenormShift = (`NE+2)'(`NF)+DivQe;
    // if the result is normalized
    //  00000000x.xxxxxx...                     Exp = DivQe
    //  .00000000xxxxxxx... >> NF+1             Exp = DivQe+NF+1
    //  00000000.xxxxxxx... << NF               Exp = DivQe+1
    //  00000000x.xxxxxx... << NF               Exp = DivQe (extra shift done afterwards)
    //  00000000xx.xxxxx... << 1?               Exp = DivQe-1 (determined after)
    // inital Left shift amount  = NF
    // shift one more if the it's a minimally redundent radix 4 - one entire cycle needed for integer bit
    assign NormShift = (`NE+2)'(`NF);
    // if the shift amount is negitive then dont shift (keep sticky bit)
    // need to multiply the early termination shift by LOGR*DIVCOPIES =  left shift of log2(LOGR*DIVCOPIES)
    assign DivShiftAmt = (DivResDenorm ?  DivDenormShift[$clog2(`NORMSHIFTSZ)-1:0]&{$clog2(`NORMSHIFTSZ){~DivDenormShift[`NE+1]}} : NormShift[$clog2(`NORMSHIFTSZ)-1:0])+{{$clog2(`NORMSHIFTSZ)-`DURLEN-$clog2(`LOGR*`DIVCOPIES){1'b0}}, DivEarlyTermShift&{`DURLEN{~(DivDenormShift[`NE+1]|Sqrt)}}, {$clog2(`LOGR*`DIVCOPIES){1'b0}}};

    assign DivShiftIn = {{`NF{1'b0}}, DivQm, {`NORMSHIFTSZ-`DIVb+1+(`RADIX/4)-`NF{1'b0}}};

endmodule
