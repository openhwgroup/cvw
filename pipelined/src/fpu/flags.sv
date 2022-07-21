///////////////////////////////////////////
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Post-Processing flag calculation
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

module flags(
    input logic                 Xs,
    input logic                 XSNaN, YSNaN, ZSNaN, // inputs are signaling NaNs
    input logic                 XInf, YInf, ZInf,    // inputs are infinity
    input logic                 Plus1,
    input logic                 InfIn,                  // is a Inf input being used
    input logic                 NaNIn,                  // is a NaN input being used
    input logic [`FMTBITS-1:0]  OutFmt,                 // output format
    input logic                 XZero, YZero,         // inputs are zero
    input logic                 Sqrt,                   // Sqrt?
    input logic                 ToInt,                  // convert to integer
    input logic                 IntToFp,                // convert integer to floating point
    input logic                 Int64,                  // convert to 64 bit integer
    input logic                 Signed,                 // convert to a signed integer
    input logic [`NE:0]         CvtCe,            // the calculated expoent - Cvt
    input logic                 CvtOp,                  // conversion opperation?
    input logic                 DivOp,                  // conversion opperation?
    input logic                 FmaOp,                  // Fma opperation?
    input logic  [`NE+1:0]      FullRe,             // Re with bits to determine sign and overflow
    input logic  [`NE+1:0]      Me,               // exponent of the normalized sum
    input logic  [1:0]          CvtNegResMsbs,             // the negitive integer result's most significant bits
    input logic                 FmaAs, FmaPs,        // the product and modified Z signs
    input logic                 R, UfL, S, UfPlus1, // bits used to determine rounding
    output logic                DivByZero,
    output logic                IntInvalid, Invalid, Overflow, // flags used to select the res
    output logic [4:0]          PostProcFlg // flags
);
    logic               SigNaN;     // is an input a signaling NaN
    logic               Inexact;    // inexact flag
    logic               FpInexact;  // floating point inexact flag
    logic               IntInexact; // integer inexact flag
    logic               FmaInvalid; // integer invalid flag
    logic               DivInvalid; // integer invalid flag
    logic               Underflow;   // Underflow flag
    logic               ResExpGteMax; // is the result greater than or equal to the maximum floating point expoent
    logic               ShiftGtIntSz; // is the shift greater than the the integer size (use Re to account for possible roundning "shift")

    ///////////////////////////////////////////////////////////////////////////////
    // Flags
    ///////////////////////////////////////////////////////////////////////////////



   if (`FPSIZES == 1) begin
        assign ResExpGteMax = &FullRe[`NE-1:0] | FullRe[`NE];
        assign ShiftGtIntSz = (|FullRe[`NE:7]|(FullRe[6]&~Int64)) | ((|FullRe[4:0]|(FullRe[5]&Int64))&((FullRe[5]&~Int64) | FullRe[6]&Int64));

    end else if (`FPSIZES == 2) begin    
        assign ResExpGteMax = OutFmt ? &FullRe[`NE-1:0] | FullRe[`NE] : &FullRe[`NE1-1:0] | (|FullRe[`NE:`NE1]);

        assign ShiftGtIntSz = (|FullRe[`NE:7]|(FullRe[6]&~Int64)) | ((|FullRe[4:0]|(FullRe[5]&Int64))&((FullRe[5]&~Int64) | FullRe[6]&Int64));
    end else if (`FPSIZES == 3) begin
        always_comb
            case (OutFmt)
                `FMT: ResExpGteMax = &FullRe[`NE-1:0] | FullRe[`NE];
                `FMT1: ResExpGteMax = &FullRe[`NE1-1:0] | (|FullRe[`NE:`NE1]);
                `FMT2: ResExpGteMax = &FullRe[`NE2-1:0] | (|FullRe[`NE:`NE2]);
                default: ResExpGteMax = 1'bx;
            endcase
            assign ShiftGtIntSz = (|FullRe[`NE:7]|(FullRe[6]&~Int64)) | ((|FullRe[4:0]|(FullRe[5]&Int64))&((FullRe[5]&~Int64) | FullRe[6]&Int64));

    end else if (`FPSIZES == 4) begin        
        always_comb
            case (OutFmt)
                `Q_FMT: ResExpGteMax = &FullRe[`Q_NE-1:0] | FullRe[`Q_NE];
                `D_FMT: ResExpGteMax = &FullRe[`D_NE-1:0] | (|FullRe[`Q_NE:`D_NE]);
                `S_FMT: ResExpGteMax = &FullRe[`S_NE-1:0] | (|FullRe[`Q_NE:`S_NE]);
                `H_FMT: ResExpGteMax = &FullRe[`H_NE-1:0] | (|FullRe[`Q_NE:`H_NE]);
            endcase
            // a left shift of intlen+1 is still in range but any more than that is an overflow
            //           inital: |      64 0's         |    XLEN     |
            //                   |      64 0's         |    XLEN     | << 64
            //                   |      XLEN           |    00000... |
            // 65 = ...0 0 0 0   0 1 0 0   0 0 0 1
            //      |     or      | |     or      |
            // 33 = ...0 0 0 0   0 0 1 0   0 0 0 1
            //      |     or        | |     or    |
            // larger or equal if:
            //      - any of the bits after the most significan 1 is one
            //      - the most signifcant in 65 or 33 is still a one in the number and
            //        one of the later bits is one
            assign ShiftGtIntSz = (|FullRe[`Q_NE:7]|(FullRe[6]&~Int64)) | ((|FullRe[4:0]|(FullRe[5]&Int64))&((FullRe[5]&~Int64) | FullRe[6]&Int64));
    end

    //                 if the result is greater than or equal to the max exponent(not taking into account sign)
    //                 |           and the exponent isn't negitive
    //                 |           |                   if the input isnt infinity or NaN
    //                 |           |                   |            
    assign Overflow = ResExpGteMax & ~FullRe[`NE+1]&~(InfIn|NaNIn|DivByZero);

    // detecting tininess after rounding
    //                  the exponent is negitive
    //                  |                    the result is denormalized
    //                  |                    |                    the result is normal and rounded from a denorm
    //                  |                    |                    |                                      and if given an unbounded exponent the result does not round
    //                  |                    |                    |                                      |                     and if the result is not exact
    //                  |                    |                    |                                      |                     |               and if the input isnt infinity or NaN
    //                  |                    |                    |                                      |                     |               |
    assign Underflow = ((FullRe[`NE+1] | (FullRe == 0) | ((FullRe == 1) & (Me == 0) & ~(UfPlus1&UfL)))&(R|S))&~(InfIn|NaNIn|DivByZero);

    // Set Inexact flag if the res is diffrent from what would be outputed given infinite precision
    //      - Don't set the underflow flag if an underflowed res isn't outputed
    assign FpInexact = (S|Overflow|R)&~(InfIn|NaNIn|DivByZero);

    //                  if the res is too small to be represented and not 0
    //                  |                                     and if the res is not invalid (outside the integer bounds)
    //                  |                                     |
    assign IntInexact = ((CvtCe[`NE]&~XZero)|S|R)&~IntInvalid;

    // select the inexact flag to output
    assign Inexact = ToInt ? IntInexact : FpInexact;

    // Set Invalid flag for following cases:
    //   1) any input is a signaling NaN
    //   2) Inf - Inf (unless x or y is NaN)
    //   3) 0 * Inf

    //                  if the input is NaN or infinity
    //                  |           if the integer res overflows (out of range) 
    //                  |           |                                  if the input was negitive but ouputing to a unsigned number
    //                  |           |                                  |                    the res doesn't round to zero
    //                  |           |                                  |                    |               or the res rounds up out of bounds
    //                  |           |                                  |                    |                       and the res didn't underflow
    //                  |           |                                  |                    |                       |
    assign IntInvalid = NaNIn|InfIn|(ShiftGtIntSz&~FullRe[`NE+1])|((Xs&~Signed)&(~((CvtCe[`NE]|(~|CvtCe))&~Plus1)))|(CvtNegResMsbs[1]^CvtNegResMsbs[0]);
    //                                                                                                     |
    //                                                                                                     or when the positive res rounds up out of range
    assign SigNaN = (XSNaN&~(IntToFp&CvtOp)) | (YSNaN&~CvtOp) | (ZSNaN&FmaOp);
    assign FmaInvalid = ((XInf | YInf) & ZInf & (FmaPs ^ FmaAs) & ~NaNIn) | (XZero & YInf) | (YZero & XInf);
    assign DivInvalid = ((XInf & YInf) | (XZero & YZero))&~Sqrt | (Xs&Sqrt);

    assign Invalid = SigNaN | (FmaInvalid&FmaOp) | (DivInvalid&DivOp);

    // if dividing by zero and not 0/0
    //  - don't set flag if an input is NaN or Inf(IEEE says has to be a finite numerator)
    assign DivByZero = YZero&DivOp&~(XZero|NaNIn|InfIn);  

    // Combine flags
    //      - to integer results do not set the underflow or overflow flags
    assign PostProcFlg = {Invalid|(IntInvalid&CvtOp&ToInt), DivByZero, Overflow&~(ToInt&CvtOp), Underflow&~(ToInt&CvtOp), Inexact};

endmodule




