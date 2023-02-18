///////////////////////////////////////////
// unpackinput.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: unpack input: extract sign, exponent, significand, characteristics
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

module unpackinput ( 
  input  logic [`FLEN-1:0]        In,         // inputs from register file
  input  logic                    En,         // enable the input
  input  logic [`FMTBITS-1:0]     Fmt,        // format signal 00 - single 01 - double 11 - quad 10 - half
  output logic                    Sgn,        // sign bits of the number 
  output logic [`NE-1:0]          Exp,        // exponent of the number  (converted to largest supported precision)
  output logic [`NF:0]            Man,        // mantissa of the number  (converted to largest supported precision)
  output logic                    NaN,        // is the number a NaN
  output logic                    SNaN,       // is the number a signaling NaN
  output logic                    Zero,       // is the number zero
  output logic                    Inf,        // is the number infinity
  output logic                    ExpNonZero, // is the exponent not zero
  output logic                    FracZero,   // is the fraction zero
  output logic                    ExpMax,     // does In have the maximum exponent (NaN or Inf)
  output logic                    Subnorm,    // is the number subnormal
  output logic [`FLEN-1:0]        PostBox     // Number reboxed correctly as a NaN
);

  logic [`NF-1:0] Frac;       // Fraction of XYZ
  logic           BadNaNBox;  // incorrectly NaN Boxed

  if (`FPSIZES == 1) begin        // if there is only one floating point format supported
      assign BadNaNBox = 0;
      assign Sgn = In[`FLEN-1];  // sign bit
      assign Frac = In[`NF-1:0];  // fraction (no assumed 1)
      assign ExpNonZero = |In[`FLEN-2:`NF];  // is the exponent non-zero
      assign Exp = {In[`FLEN-2:`NF+1], In[`NF]|~ExpNonZero};  // exponent.  subnormal numbers have effective biased exponent of 1
      assign ExpMax = &In[`FLEN-2:`NF];  // is the exponent all 1's
      assign PostBox = In;
  
  end else if (`FPSIZES == 2) begin   // if there are 2 floating point formats supported
      // largest format | smaller format
      //----------------------------------
      //      `FLEN     |     `LEN1       length of floating point number
      //      `NE       |     `NE1        length of exponent
      //      `NF       |     `NF1        length of fraction
      //      `BIAS     |     `BIAS1      exponent's bias value
      //      `FMT      |     `FMT1       precision's format value - Q=11 D=01 Sticky=00 H=10

      // Possible combinantions specified by spec:
      //      double and single
      //      single and half

      // Not needed but can also handle:
      //      quad   and double
      //      quad   and single
      //      quad   and half
      //      double and half

      assign BadNaNBox = ~(Fmt|(&In[`FLEN-1:`LEN1])); // Check NaN boxing
      always_comb
        if (BadNaNBox) begin
//          PostBox = {{(`FLEN-`LEN1){1'b1}}, 1'b1, {(`NE1+1){1'b1}}, In[`LEN1-`NE1-3:0]};
          PostBox = {{(`FLEN-`LEN1){1'b1}}, 1'b1, {(`NE1+1){1'b1}}, {(`LEN1-`NE1-2){1'b0}}};
        end else 
          PostBox = In;

      // choose sign bit depending on format - 1=larger precsion 0=smaller precision
      assign Sgn = Fmt ? In[`FLEN-1] : (BadNaNBox ? 0 : In[`LEN1-1]); // improperly boxed NaNs are treated as positive

      // extract the fraction, add trailing zeroes to the mantissa if nessisary
      assign Frac = Fmt ? In[`NF-1:0] : {In[`NF1-1:0], (`NF-`NF1)'(0)};

      // is the exponent non-zero
      assign ExpNonZero = Fmt ? |In[`FLEN-2:`NF] : |In[`LEN1-2:`NF1]; 

      // example double to single conversion:
      // 1023 = 0011 1111 1111
      // 127  = 0000 0111 1111 (subtract this)
      // 896  = 0011 1000 0000
      // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
      // dexp = 0bdd dbbb bbbb 
      // also need to take into account possible zero/Subnorm/inf/NaN values

      // extract the exponent, converting the smaller exponent into the larger precision if nessisary
      //      - if the original precision had a Subnormal number convert the exponent value 1
      assign Exp = Fmt ? {In[`FLEN-2:`NF+1], In[`NF]|~ExpNonZero} : {In[`LEN1-2], {`NE-`NE1{~In[`LEN1-2]}}, In[`LEN1-3:`NF1+1], In[`NF1]|~ExpNonZero}; 

      // is the exponent all 1's
      assign ExpMax = Fmt ? &In[`FLEN-2:`NF] : &In[`LEN1-2:`NF1];
  

  end else if (`FPSIZES == 3) begin       // three floating point precsions supported

      // largest format | larger format  | smallest format
      //---------------------------------------------------
      //      `FLEN     |     `LEN1      |    `LEN2       length of floating point number
      //      `NE       |     `NE1       |    `NE2        length of exponent
      //      `NF       |     `NF1       |    `NF2        length of fraction
      //      `BIAS     |     `BIAS1     |    `BIAS2      exponent's bias value
      //      `FMT      |     `FMT1      |    `FMT2       precision's format value - Q=11 D=01 Sticky=00 H=10

      // Possible combinantions specified by spec:
      //      quad   and double and single
      //      double and single and half

      // Not needed but can also handle:
      //      quad   and double and half
      //      quad   and single and half

      // Check NaN boxing
      always_comb
          case (Fmt)
              `FMT:  BadNaNBox = 0;
              `FMT1: BadNaNBox = ~&In[`FLEN-1:`LEN1];
              `FMT2: BadNaNBox = ~&In[`FLEN-1:`LEN2];
              default: BadNaNBox = 1'bx;
          endcase

      always_comb
        if (BadNaNBox) begin
          case (Fmt)
            `FMT: PostBox = In;
//            `FMT1: PostBox = {{(`FLEN-`LEN1){1'b1}}, 1'b1, {(`NE1+1){1'b1}}, In[`LEN1-`NE1-3:0]};
//            `FMT2: PostBox = {{(`FLEN-`LEN2){1'b1}}, 1'b1, {(`NE2+1){1'b1}}, In[`LEN2-`NE2-3:0]};
            `FMT1: PostBox = {{(`FLEN-`LEN1){1'b1}}, 1'b1, {(`NE1+1){1'b1}}, {(`LEN1-`NE1-2){1'b0}}};
            `FMT2: PostBox = {{(`FLEN-`LEN2){1'b1}}, 1'b1, {(`NE2+1){1'b1}}, {(`LEN2-`NE2-2){1'b0}}};
            default: PostBox = 'x;
          endcase
        end else 
          PostBox = In;

      // extract the sign bit
      always_comb
        if (BadNaNBox) Sgn = 0; // improperly boxed NaNs are treated as positive
        else
          case (Fmt)
              `FMT:  Sgn = In[`FLEN-1];
              `FMT1: Sgn = In[`LEN1-1];
              `FMT2: Sgn = In[`LEN2-1];
              default: Sgn = 1'bx;
          endcase

       // extract the fraction
      always_comb
          case (Fmt)
              `FMT: Frac = In[`NF-1:0];
              `FMT1: Frac = {In[`NF1-1:0], (`NF-`NF1)'(0)};
              `FMT2: Frac = {In[`NF2-1:0], (`NF-`NF2)'(0)};
              default: Frac = {`NF{1'bx}};
          endcase

      // is the exponent non-zero
      always_comb
          case (Fmt)
              `FMT:  ExpNonZero = |In[`FLEN-2:`NF];     // if input is largest precision (`FLEN - ie quad or double)
              `FMT1: ExpNonZero = |In[`LEN1-2:`NF1];  // if input is larger precsion (`LEN1 - double or single)
              `FMT2: ExpNonZero = |In[`LEN2-2:`NF2]; // if input is smallest precsion (`LEN2 - single or half)
              default: ExpNonZero = 1'bx; 
          endcase
          
      // example double to single conversion:
      // 1023 = 0011 1111 1111
      // 127  = 0000 0111 1111 (subtract this)
      // 896  = 0011 1000 0000
      // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
      // dexp = 0bdd dbbb bbbb 
      // also need to take into account possible zero/Subnorm/inf/NaN values

      // convert the larger precision's exponent to use the largest precision's bias
      always_comb 
          case (Fmt)
              `FMT:  Exp = {In[`FLEN-2:`NF+1], In[`NF]|~ExpNonZero};
              `FMT1: Exp = {In[`LEN1-2], {`NE-`NE1{~In[`LEN1-2]}}, In[`LEN1-3:`NF1+1], In[`NF1]|~ExpNonZero}; 
              `FMT2: Exp = {In[`LEN2-2], {`NE-`NE2{~In[`LEN2-2]}}, In[`LEN2-3:`NF2+1], In[`NF2]|~ExpNonZero}; 
              default: Exp = {`NE{1'bx}};
          endcase

      // is the exponent all 1's
      always_comb
          case (Fmt)
              `FMT:  ExpMax = &In[`FLEN-2:`NF];
              `FMT1: ExpMax = &In[`LEN1-2:`NF1];
              `FMT2: ExpMax = &In[`LEN2-2:`NF2];
              default: ExpMax = 1'bx;
          endcase

  end else if (`FPSIZES == 4) begin      // if all precsisons are supported - quad, double, single, and half
  
      //    quad   |  double  |  single  |  half    
      //-------------------------------------------------------------------
      //   `Q_LEN  |  `D_LEN  |  `S_LEN  |  `H_LEN     length of floating point number
      //   `Q_NE   |  `D_NE   |  `S_NE   |  `H_NE      length of exponent
      //   `Q_NF   |  `D_NF   |  `S_NF   |  `H_NF      length of fraction
      //   `Q_BIAS |  `D_BIAS |  `S_BIAS |  `H_BIAS    exponent's bias value
      //   `Q_FMT  |  `D_FMT  |  `S_FMT  |  `H_FMT     precision's format value - Q=11 D=01 Sticky=00 H=10

      // Check NaN boxing
      always_comb
          case (Fmt)
              2'b11: BadNaNBox = 0;
              2'b01: BadNaNBox = ~&In[`Q_LEN-1:`D_LEN];
              2'b00: BadNaNBox = ~&In[`Q_LEN-1:`S_LEN];
              2'b10: BadNaNBox = ~&In[`Q_LEN-1:`H_LEN];
          endcase

      always_comb
        if (BadNaNBox) begin
          case (Fmt)
            2'b11: PostBox = In;
//            2'b01: PostBox = {{(`Q_LEN-`D_LEN){1'b1}}, 1'b1, {(`D_NE+1){1'b1}}, In[`D_LEN-`D_NE-3:0]};
//            2'b00: PostBox = {{(`Q_LEN-`S_LEN){1'b1}}, 1'b1, {(`S_NE+1){1'b1}}, In[`S_LEN-`S_NE-3:0]};
//            2'b10: PostBox = {{(`Q_LEN-`H_LEN){1'b1}}, 1'b1, {(`H_NE+1){1'b1}}, In[`H_LEN-`H_NE-3:0]};
            2'b01: PostBox = {{(`Q_LEN-`D_LEN){1'b1}}, 1'b1, {(`D_NE+1){1'b1}}, {(`D_LEN-`D_NE-2){1'b0}}};
            2'b00: PostBox = {{(`Q_LEN-`S_LEN){1'b1}}, 1'b1, {(`S_NE+1){1'b1}}, {(`S_LEN-`S_NE-2){1'b0}}};
            2'b10: PostBox = {{(`Q_LEN-`H_LEN){1'b1}}, 1'b1, {(`H_NE+1){1'b1}}, {(`H_LEN-`H_NE-2){1'b0}}};
          endcase
        end else 
          PostBox = In;

      // extract sign bit
      always_comb
        if (BadNaNBox) Sgn = 0; // improperly boxed NaNs are treated as positive
        else
          case (Fmt)
              2'b11: Sgn = In[`Q_LEN-1];
              2'b01: Sgn = In[`D_LEN-1];
              2'b00: Sgn = In[`S_LEN-1];
              2'b10: Sgn = In[`H_LEN-1];
          endcase
          

      // extract the fraction
      always_comb
          case (Fmt)
              2'b11: Frac = In[`Q_NF-1:0];
              2'b01: Frac = {In[`D_NF-1:0], (`Q_NF-`D_NF)'(0)};
              2'b00: Frac = {In[`S_NF-1:0], (`Q_NF-`S_NF)'(0)};
              2'b10: Frac = {In[`H_NF-1:0], (`Q_NF-`H_NF)'(0)};
          endcase

      // is the exponent non-zero
      always_comb
          case (Fmt)
              2'b11: ExpNonZero = |In[`Q_LEN-2:`Q_NF];
              2'b01: ExpNonZero = |In[`D_LEN-2:`D_NF];
              2'b00: ExpNonZero = |In[`S_LEN-2:`S_NF]; 
              2'b10: ExpNonZero = |In[`H_LEN-2:`H_NF]; 
          endcase


      // example double to single conversion:
      // 1023 = 0011 1111 1111
      // 127  = 0000 0111 1111 (subtract this)
      // 896  = 0011 1000 0000
      // sexp = 0000 bbbb bbbb (add this) b = bit d = ~b 
      // dexp = 0bdd dbbb bbbb 
      // also need to take into account possible zero/Subnorm/inf/NaN values
      
      // convert the double precsion exponent into quad precsion
      // 1 is added to the exponent if the input is zero or subnormal
      always_comb
          case (Fmt)
              2'b11: Exp = {In[`Q_LEN-2:`Q_NF+1], In[`Q_NF]|~ExpNonZero};
              2'b01: Exp = {In[`D_LEN-2], {`Q_NE-`D_NE{~In[`D_LEN-2]}}, In[`D_LEN-3:`D_NF+1], In[`D_NF]|~ExpNonZero};
              2'b00: Exp = {In[`S_LEN-2], {`Q_NE-`S_NE{~In[`S_LEN-2]}}, In[`S_LEN-3:`S_NF+1], In[`S_NF]|~ExpNonZero};
              2'b10: Exp = {In[`H_LEN-2], {`Q_NE-`H_NE{~In[`H_LEN-2]}}, In[`H_LEN-3:`H_NF+1], In[`H_NF]|~ExpNonZero}; 
          endcase


      // is the exponent all 1's
      always_comb 
          case (Fmt)
              2'b11: ExpMax = &In[`Q_LEN-2:`Q_NF];
              2'b01: ExpMax = &In[`D_LEN-2:`D_NF];
              2'b00: ExpMax = &In[`S_LEN-2:`S_NF];
              2'b10: ExpMax = &In[`H_LEN-2:`H_NF];
          endcase

  end

  // Output logic
  assign FracZero = ~|Frac & ~BadNaNBox; // is the fraction zero?
  assign Man = {ExpNonZero, Frac}; // add the assumed one (or zero if Subnormal or zero) to create the significand
  assign NaN = ((ExpMax & ~FracZero)|BadNaNBox)&En; // is the input a NaN?
  assign SNaN = NaN&~Frac[`NF-1]&~BadNaNBox; // is the input a singnaling NaN?
  assign Inf = ExpMax & FracZero &En & ~BadNaNBox; // is the input infinity?
  assign Zero = ~ExpNonZero & FracZero & ~BadNaNBox; // is the input zero?
  assign Subnorm = ~ExpNonZero & ~FracZero & ~BadNaNBox; // is the input subnormal

endmodule