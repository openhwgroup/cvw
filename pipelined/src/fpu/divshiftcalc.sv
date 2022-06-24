`include "wally-config.vh"

module divshiftcalc(
    input logic  [`DIVLEN+2:0] Quot,
    input logic  [`NE+1:0] DivCalcExpM,
    output logic [$clog2(`NORMSHIFTSZ)-1:0] DivShiftAmt,
    output logic [`NE+1:0] CorrDivExp
);
    
    assign DivShiftAmt = {{$clog2(`NORMSHIFTSZ)-1{1'b0}}, ~Quot[`DIVLEN+2]};
    // the quotent is in the range [.5,2)
    // if the quotent < 1 and not denormal then subtract 1 to account for the normalization shift
    assign CorrDivExp = DivCalcExpM - {(`NE)'(0), ~Quot[`DIVLEN+2]};

endmodule
