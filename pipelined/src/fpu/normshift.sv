///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: normalization shifter
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