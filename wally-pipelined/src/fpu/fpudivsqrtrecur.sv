///////////////////////////////////////////
//
// Written: David Harris
// Modified: 11 September 2021
//
// Purpose: Recurrence-based SRT Division and Square Root
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module fpudivsqrtrecur (
    input logic                 clk,
    input logic                 reset,
    input logic                 FlushM,     // flush the memory stage
    input logic                 StallM,     // stall memory stage
    input logic                 FDivSqrtStart, // start a computation
    input logic                 FmtE, // precision 1 = double 0 = single
    input logic                 FDivE, FSqrtE,
    input logic  [2:0]          FrmM,               // rounding mode 000 = rount to nearest, ties to even   001 = round twords zero  010 = round down  011 = round up  100 = round to nearest, ties to max magnitude
    input logic                 XSgnE, YSgnE,    // input signs - execute stage
    input logic [`NE-1:0]       XExpE, YExpE,    // input exponents - execute stage
    input logic [`NF:0]         XManE, YManE,    // input mantissa - execute stage
    input logic                 XDenormE, YDenormE, // is denorm
    input logic                 XZeroE, YZeroE,     // is zero - execute stage
    input logic                 XNaNE, YNaNE,        // is NaN
    input logic                 XSNaNE, YSNaNE,     // is signaling NaN
    input logic                 XInfE, YInfE, ZInfE,        // is infinity
    input logic [10:0]          BiasE,      // bias (max exponent/2) ***parameterize in unpacking unit
    output logic                FDviSqrtBusy, FDivSqrtDone, //currently occpied, or done with operation
	  output logic [`FLEN-1:0]    FDivSqrtResM,    // result
	  output logic [4:0]		      FDivSqrtFlgM   // flags
  );
   
  logic FDivSqrtResSgn;
  logic [`FLEN-1:0] FDivSqrtRecurRes;

  // Radix-2 SRT Division and Square Root

  // Special Cases
  // *** shift to handle denorms in hardware

  assign FDivSqrtResSgn = FDivE & (XSgnE ^ YSgnE); // Sign is negative for division if inputs have opposite signs

  always_comb begin 
      if (FSqrtE & XSgnE | FDivE & XZeroE & YZeroE | XNaNE | FDivE & YNaNE) FDivSqrtResM = 0; // ***replace with NAN; // *** which one
      else if (FDivE & YZeroE | XInfE) FDivSqrtResM = {FDivSqrtResSgn, `NE'b1, `NF'b0}; // infinity
      else if (FDivE & YInfE) FDivSqrtResM = {FDivSqrtResSgn, `NE'b0, `NF'b0}; // zero
      else FDivSqrtResM = FDivSqrtRecurRes;
  end

  // *** handle early termination in the special cases
  // *** handle signaling NANs
endmodule