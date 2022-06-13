`include "wally-config.vh"


 // convert shift
    //      fp -> int: |  `XLEN  zeros |     Mantissa      | 0's if nessisary | << CalcExp
    //          process:
    //              - start - CalcExp = 1 + XExp - Largest Bias
    //                  |  `XLEN  zeros     |     Mantissa      | 0's if nessisary |
    //
    //              - shift left 1 (1)
    //                  | `XLEN-1 zeros |bit|     frac      | 0's if nessisary |
    //                                      . <- binary point
    //
    //              - shift left till unbiased exponent is 0 (XExp - Largest Bias)
    //                  |  0's |     Mantissa      |      0's if nessisary     |
    //                  |     keep          |
    //
    //      fp -> fp:
    //          - if result is denormalized or underflowed:
    //              |  `NF-1  zeros   |     Mantissa      | 0's if nessisary | << NF+CalcExp-1
    //          process:
    //             - start
    //                 |     mantissa      | 0's |
    //
    //             - shift right by NF-1 (NF-1)
    //                 |  `NF-1  zeros   |     mantissa      | 0's |
    //
    //             - shift left by CalcExp = XExp - Largest bias + new bias
    //                 |   0's  |     mantissa      |     0's      |
    //                 |       keep      |
    //
    //          - if the input is denormalized:
    //              |     lzcIn      | 0's if nessisary | << ZeroCnt+1
    //              - plus 1 to shift out the first 1
    //
    //      int -> fp: |     lzcIn      | 0's if nessisary | << ZeroCnt+1
    //              - plus 1 to shift out the first 1

module normshift(
    input logic  [$clog2(`NORMSHIFTSZ)-1:0]      ShiftAmt,   // normalization shift count
    input logic  [`NORMSHIFTSZ-1:0]              ShiftIn,        // is the sum zero
    output logic [`NORMSHIFTSZ-1:0]             Shifted        // is the sum zero
);
    assign Shifted = ShiftIn << ShiftAmt;

endmodule