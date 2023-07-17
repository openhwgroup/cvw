///////////////////////////////////////////
// fdivsqrtexpcalc.sv
//
// Written: David_Harris@hmc.edu, me@KatherineParry.com, cturek@hmc.edu
// Modified:13 January 2022
//
// Purpose: Exponent caclulation for divide and square root
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

module fdivsqrtexpcalc import cvw::*;  #(parameter cvw_t P) (
  input  logic [P.FMTBITS-1:0] Fmt,
  input  logic [P.NE-1:0]      Xe, Ye,
  input  logic                 Sqrt,
  input  logic                 XZero, 
  input  logic [P.DIVBLEN:0]   ell, m,
  output logic [P.NE+1:0]      Qe
  );
  logic [P.NE-2:0] Bias;
  logic [P.NE+1:0] SXExp;
  logic [P.NE+1:0] SExp;
  logic [P.NE+1:0] DExp;
  
  if (P.FPSIZES == 1) begin
    assign Bias = (P.NE-1)'(P.BIAS); 

  end else if (P.FPSIZES == 2) begin
    assign Bias = Fmt ? (P.NE-1)'(P.BIAS) : (P.NE-1)'(P.BIAS1); 

  end else if (P.FPSIZES == 3) begin
    always_comb
      case (Fmt)
        P.FMT: Bias  =  (P.NE-1)'(P.BIAS);
        P.FMT1: Bias = (P.NE-1)'(P.BIAS1);
        P.FMT2: Bias = (P.NE-1)'(P.BIAS2);
        default: Bias = 'x;
      endcase

  end else if (P.FPSIZES == 4) begin        
  always_comb
    case (Fmt)
      2'h3: Bias =  (P.NE-1)'(P.Q_BIAS);
      2'h1: Bias =  (P.NE-1)'(P.D_BIAS);
      2'h0: Bias =  (P.NE-1)'(P.S_BIAS);
      2'h2: Bias =  (P.NE-1)'(P.H_BIAS);
    endcase
  end
  assign SXExp = {2'b0, Xe} - {{(P.NE+1-P.DIVBLEN){1'b0}}, ell} - (P.NE+2)'(P.BIAS);
  assign SExp  = {SXExp[P.NE+1], SXExp[P.NE+1:1]} + {2'b0, Bias};
  
  // correct exponent for subnormal input's normalization shifts
  assign DExp  = ({2'b0, Xe} - {{(P.NE+1-P.DIVBLEN){1'b0}}, ell} - {2'b0, Ye} + {{(P.NE+1-P.DIVBLEN){1'b0}}, m} + {3'b0, Bias}); 
  assign Qe = Sqrt ? SExp : DExp;
endmodule
