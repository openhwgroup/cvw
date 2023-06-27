
///////////////////////////////////////////
// flags.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Post-Processing flag calculation
// 
// Documentation: RISC-V System on Chip Design Chapter 13
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module divremsqrtflags import cvw::*;  #(parameter cvw_t P) (
  input  logic                Xs,                     // X sign
  input  logic [P.FMTBITS-1:0] OutFmt,                 // output format
  input  logic                InfIn,                  // is a Inf input being used
  input  logic                XInf, YInf,             // inputs are infinity
  input  logic                NaNIn,                  // is a NaN input being used
  input  logic                XSNaN, YSNaN,           // inputs are signaling NaNs
  input  logic                XZero, YZero,           // inputs are zero
  input  logic [P.NE+1:0]      FullRe,                 // Re with bits to determine sign and overflow
  input  logic [P.NE+1:0]      Me,                     // exponent of the normalized sum
  // rounding
  input  logic                Plus1,                  // do you add one for rounding
  input  logic                Round, Guard, Sticky,   // bits used to determine rounding
  input  logic                UfPlus1,                // do you add one for rounding for the unbounded exponent result
  // divsqrt
  input  logic                DivOp,                  // conversion opperation?
  input  logic                Sqrt,                   // Sqrt?
  // flags
  output logic                DivByZero,              // divide by zero flag
  output logic                Overflow,               // overflow flag to select result
  output logic                Invalid,                // invalid flag to select the result
  output logic [4:0]          PostProcFlg             // flags
);

  logic               SigNaN;         // is an input a signaling NaN
  logic               Inexact;        // final inexact flag
  logic               FpInexact;      // floating point inexact flag
  logic               DivInvalid;     // integer invalid flag
  logic               Underflow;      // Underflow flag
  logic               ResExpGteMax;   // is the result greater than or equal to the maximum floating point expoent

  ///////////////////////////////////////////////////////////////////////////////
  // Overflow
  ///////////////////////////////////////////////////////////////////////////////

  // determine if the result exponent is greater than or equal to the maximum exponent or 
  // the shift amount is greater than the integers size (for cvt to int)
  // ShiftGtIntSz calculation:  
  //      a left shift of intlen+1 is still in range but any more than that is an overflow
  //              inital: |      64 0's         |    XLEN     |
  //                      |      64 0's         |    XLEN     | << 64
  //                      |      XLEN           |    00000... |
  //      65 = ...0 0 0 0   0 1 0 0   0 0 0 1
  //          |     or      | |     or      |
  //      33 = ...0 0 0 0   0 0 1 0   0 0 0 1
  //          |     or        | |     or    |
  //      larger or equal if:
  //          - any of the bits after the most significan 1 is one
  //          - the most signifcant in 65 or 33 is still a one in the number and
  //            one of the later bits is one
  if (P.FPSIZES == 1) begin
      assign ResExpGteMax = &FullRe[P.NE-1:0] | FullRe[P.NE];

  end else if (P.FPSIZES == 2) begin    
      assign ResExpGteMax = OutFmt ? &FullRe[P.NE-1:0] | FullRe[P.NE] : &FullRe[P.NE1-1:0] | (|FullRe[P.NE:P.NE1]);

  end else if (P.FPSIZES == 3) begin
      always_comb
          case (OutFmt)
              P.FMT: ResExpGteMax = &FullRe[P.NE-1:0] | FullRe[P.NE];
              P.FMT1: ResExpGteMax = &FullRe[P.NE1-1:0] | (|FullRe[P.NE:P.NE1]);
              P.FMT2: ResExpGteMax = &FullRe[P.NE2-1:0] | (|FullRe[P.NE:P.NE2]);
              default: ResExpGteMax = 1'bx;
          endcase

  end else if (P.FPSIZES == 4) begin        
      always_comb
          case (OutFmt)
              P.Q_FMT: ResExpGteMax = &FullRe[P.Q_NE-1:0] | FullRe[P.Q_NE];
              P.D_FMT: ResExpGteMax = &FullRe[P.D_NE-1:0] | (|FullRe[P.Q_NE:P.D_NE]);
              P.S_FMT: ResExpGteMax = &FullRe[P.S_NE-1:0] | (|FullRe[P.Q_NE:P.S_NE]);
              P.H_FMT: ResExpGteMax = &FullRe[P.H_NE-1:0] | (|FullRe[P.Q_NE:P.H_NE]);
          endcase
  end


  // calulate overflow flag:
  //                 if the result is greater than or equal to the max exponent(not taking into account sign)
  //                 |           and the exponent isn't negitive
  //                 |           |                   if the input isnt infinity or NaN
  //                 |           |                   |            
  assign Overflow = ResExpGteMax & ~FullRe[P.NE+1]&~(InfIn|NaNIn|DivByZero);

  ///////////////////////////////////////////////////////////////////////////////
  // Underflow
  ///////////////////////////////////////////////////////////////////////////////

  // calculate underflow flag: detecting tininess after rounding
  //                  the exponent is negitive
  //                  |                    the result is subnormal
  //                  |                    |                    the result is normal and rounded from a Subnorm
  //                  |                    |                    |                                      and if given an unbounded exponent the result does not round
  //                  |                    |                    |                                      |                     and if the result is not exact
  //                  |                    |                    |                                      |                     |               and if the input isnt infinity or NaN
  //                  |                    |                    |                                      |                     |               |
  assign Underflow = ((FullRe[P.NE+1] | (FullRe == 0) | ((FullRe == 1) & (Me == 0) & ~(UfPlus1&Guard)))&(Round|Sticky|Guard))&~(InfIn|NaNIn|DivByZero|Invalid);


  ///////////////////////////////////////////////////////////////////////////////
  // Inexact
  ///////////////////////////////////////////////////////////////////////////////

  // Set Inexact flag if the result is diffrent from what would be outputed given infinite precision
  //      - Don't set the underflow flag if an underflowed res isn't outputed
  assign FpInexact = (Sticky|Guard|Overflow|Round)&~(InfIn|NaNIn|DivByZero|Invalid);
  //assign FpInexact = (Sticky|Guard|Overflow|Round)&~(InfIn|NaNIn|DivByZero|Invalid|XZero);

  //                  if the res is too small to be represented and not 0
  //                  |                                     and if the res is not invalid (outside the integer bounds)
  //                  |                                     |

  // select the inexact flag to output
  assign Inexact = FpInexact;

  ///////////////////////////////////////////////////////////////////////////////
  // Invalid
  ///////////////////////////////////////////////////////////////////////////////

  // Set Invalid flag for following cases:
  //   1) any input is a signaling NaN
  //   2) Inf - Inf (unless x or y is NaN)
  //   3) 0 * Inf

  
  assign SigNaN = (XSNaN) | (YSNaN) ;
  
  //invalid flag for division
  assign DivInvalid = ((XInf & YInf) | (XZero & YZero))&~Sqrt | (Xs&Sqrt&~NaNIn&~XZero);

  assign Invalid = SigNaN | (DivInvalid&DivOp);

  ///////////////////////////////////////////////////////////////////////////////
  // Divide by Zero
  ///////////////////////////////////////////////////////////////////////////////

  // if dividing by zero and not 0/0
  //  - don't set flag if an input is NaN or Inf(IEEE says has to be a finite numerator)
  assign DivByZero = YZero&DivOp&~Sqrt&~(XZero|NaNIn|InfIn);  


  ///////////////////////////////////////////////////////////////////////////////
  // final flags
  ///////////////////////////////////////////////////////////////////////////////

  // Combine flags
  //      - to integer results do not set the underflow or overflow flags
  assign PostProcFlg = {Invalid, DivByZero, Overflow, Underflow, Inexact};

endmodule




