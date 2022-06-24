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
    assign ResDenorm = DivCalcExpM[`NE+1];
    assign DenormShift = (`NE+2)'(`NF-1)+DivCalcExpM;
    assign NormShift = {(`NE+1)'(0), ~Quot[`DIVLEN+2]} + (`NE+2)'(`NF);
    assign DivShiftAmt = ResDenorm ?  DenormShift[$clog2(`NORMSHIFTSZ)-1:0] : NormShift[$clog2(`NORMSHIFTSZ)-1:0];

    assign DivShiftIn = {(`NF)'(0), Quot[`DIVLEN+1:0], {`NORMSHIFTSZ-`DIVLEN-2-`NF{1'b0}}};
    // the quotent is in the range [.5,2)
    // if the quotent < 1 and not denormal then subtract 1 to account for the normalization shift
    assign CorrDivExp = (ResDenorm&~DenormShift[`NE+1]) ? (`NE+2)'(0) : DivCalcExpM - {(`NE+1)'(0), ~Quot[`DIVLEN+2]};

endmodule
