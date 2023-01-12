///////////////////////////////////////////
// fdivsqrtpreproc.sv
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
  
  // correct exponent for subnormal input's normalization shifts
  assign DExp  = ({2'b0, Xe} - {{(`NE+1-`DIVBLEN){1'b0}}, ell} - {2'b0, Ye} + {{(`NE+1-`DIVBLEN){1'b0}}, m} + {3'b0, Bias}) & {`NE+2{~XZero}};
  assign Qe = Sqrt ? SExp : DExp;
endmodule
