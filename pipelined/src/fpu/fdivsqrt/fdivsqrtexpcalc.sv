///////////////////////////////////////////
// fdivsqrtpreproc.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: Combined Divide and Square Root Floating Point and Integer Unit
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

module fdivsqrtexpcalc(
  input  logic [`FMTBITS-1:0] Fmt,
  input  logic [`NE-1:0] Xe, Ye,
  input  logic Sqrt,
  input  logic XZero, 
  input  logic [`DIVBLEN:0] ell, m,
  output logic [`NE+1:0] Qe
  );
  logic [`NE-2:0] Bias;
  logic [`NE+1:0] SXExp;
  logic [`NE+1:0] SExp;
  logic [`NE+1:0] DExp;
  
  if (`FPSIZES == 1) begin
      assign Bias = (`NE-1)'(`BIAS); 

  end else if (`FPSIZES == 2) begin
      assign Bias = Fmt ? (`NE-1)'(`BIAS) : (`NE-1)'(`BIAS1); 

  end else if (`FPSIZES == 3) begin
      always_comb
          case (Fmt)
              `FMT: Bias  =  (`NE-1)'(`BIAS);
              `FMT1: Bias = (`NE-1)'(`BIAS1);
              `FMT2: Bias = (`NE-1)'(`BIAS2);
              default: Bias = 'x;
          endcase

  end else if (`FPSIZES == 4) begin        
    always_comb
        case (Fmt)
            2'h3: Bias =  (`NE-1)'(`Q_BIAS);
            2'h1: Bias =  (`NE-1)'(`D_BIAS);
            2'h0: Bias =  (`NE-1)'(`S_BIAS);
            2'h2: Bias =  (`NE-1)'(`H_BIAS);
        endcase
  end
  assign SXExp = {2'b0, Xe} - {{(`NE+1-`DIVBLEN){1'b0}}, ell} - (`NE+2)'(`BIAS);
  assign SExp  = {SXExp[`NE+1], SXExp[`NE+1:1]} + {2'b0, Bias};
  
  // correct exponent for denormalized input's normalization shifts
  assign DExp  = ({2'b0, Xe} - {{(`NE+1-`DIVBLEN){1'b0}}, ell} - {2'b0, Ye} + {{(`NE+1-`DIVBLEN){1'b0}}, m} + {3'b0, Bias}) & {`NE+2{~XZero}};
  assign Qe = Sqrt ? SExp : DExp;
endmodule
