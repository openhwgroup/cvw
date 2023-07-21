///////////////////////////////////////////
// specialcase.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: special case selection
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

module specialcase(
  input  logic                Xs,         // X sign
  input  logic [`NF:0]        Xm, Ym, Zm, // input significand's
  input  logic                XNaN, YNaN, ZNaN, // are the inputs NaN
  input  logic [2:0]          Frm,        // rounding mode
  input  logic [`FMTBITS-1:0] OutFmt,     // output format
  input  logic                InfIn,      // are any inputs infinity
  input  logic                NaNIn,      // are any input NaNs
  input  logic                XInf, YInf, // are X or Y inifnity
  input  logic                XZero,      // is X zero
  input  logic                Plus1,      // do you add one for rounding
  input  logic                Rs,         // the result's sign
  input  logic                Invalid, Overflow,  // flags to choose the result
  input  logic [`NE-1:0]      Re,         // Result exponent
  input  logic [`NE+1:0]      FullRe,     // Result full exponent
  input  logic [`NF-1:0]      Rf,         // Result fraction
  // fma
  input  logic                FmaOp,      // is it a fma opperation
  // divsqrt
  input  logic                DivOp,      // is it a divsqrt opperation
  input  logic                DivByZero,  // divide by zero flag
  // cvt
  input  logic                CvtOp,      // is it a conversion opperation
  input  logic                IntZero,    // is the integer input zero
  input  logic                IntToFp,    // is cvt int -> fp opperation
  input  logic                Int64,      // is the integer 64 bits
  input  logic                Signed,     // is the integer signed
  input  logic [`NE:0]        CvtCe,      // the calculated expoent for cvt
  input  logic                IntInvalid, // integer invalid flag to choose the result
  input  logic                CvtResUf,   // does the convert result underflow
  input  logic [`XLEN+1:0]    CvtNegRes,  // the possibly negated of the integer result
  // outputs
  output logic [`FLEN-1:0]    PostProcRes,// final result
  output logic [`XLEN-1:0]    FCvtIntRes  // final integer result
);

  logic [`FLEN-1:0]   XNaNRes;    // X is NaN result
  logic [`FLEN-1:0]   YNaNRes;    // Y is NaN result
  logic [`FLEN-1:0]   ZNaNRes;    // Z is NaN result
  logic [`FLEN-1:0]   InvalidRes; // Invalid result result
  logic [`FLEN-1:0]   UfRes;      // underflowed result result
  logic [`FLEN-1:0]   OfRes;      // overflowed result result
  logic [`FLEN-1:0]   NormRes;    // normal result
  logic [`XLEN-1:0]   OfIntRes;   // the overflow result for integer output
  logic               OfResMax;   // does the of result output maximum norm fp number
  logic               KillRes;    // kill the result for underflow
  logic               SelOfRes;   // should the overflow result be selected


  // does the overflow result output the maximum normalized floating point number
  //                output infinity if the input is infinity
  assign OfResMax = (~InfIn|(IntToFp&CvtOp))&~DivByZero&((Frm[1:0]==2'b01) | (Frm[1:0]==2'b10&~Rs) | (Frm[1:0]==2'b11&Rs));

  // select correct outputs for special cases
  if (`FPSIZES == 1) begin
      //NaN res selection depending on standard
      if(`IEEE754) begin
          assign XNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Xm[`NF-2:0]};
          assign YNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Ym[`NF-2:0]};
          assign ZNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Zm[`NF-2:0]};
          assign InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
      end else begin
          assign InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
      end

      assign OfRes =  OfResMax ? {Rs, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {Rs, {`NE{1'b1}}, {`NF{1'b0}}};
      assign UfRes = {Rs, {`FLEN-2{1'b0}}, Plus1&Frm[1]&~(DivOp&YInf)};
      assign NormRes = {Rs, Re, Rf};

  end else if (`FPSIZES == 2) begin
      if(`IEEE754) begin
          assign XNaNRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, Xm[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, Xm[`NF-2:`NF-`NF1]};
          assign YNaNRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, Ym[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, Ym[`NF-2:`NF-`NF1]};
          assign ZNaNRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, Zm[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, Zm[`NF-2:`NF-`NF1]};
          assign InvalidRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
      end else begin 
          assign InvalidRes = OutFmt ? {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
      end

      always_comb
          if(OutFmt)
              if(OfResMax)    OfRes = {Rs, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}};
              else            OfRes = {Rs, {`NE{1'b1}}, {`NF{1'b0}}};
          else
              if(OfResMax)    OfRes = {{`FLEN-`LEN1{1'b1}}, Rs, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}};
              else            OfRes = {{`FLEN-`LEN1{1'b1}}, Rs, {`NE1{1'b1}}, (`NF1)'(0)};
      assign UfRes = OutFmt ? {Rs, (`FLEN-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)} : {{`FLEN-`LEN1{1'b1}}, Rs, (`LEN1-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)};
      assign NormRes = OutFmt ? {Rs, Re, Rf} : {{`FLEN-`LEN1{1'b1}}, Rs, Re[`NE1-1:0], Rf[`NF-1:`NF-`NF1]};

  end else if (`FPSIZES == 3) begin
      always_comb
          case (OutFmt)
              `FMT: begin  
                  if(`IEEE754) begin
                      XNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Xm[`NF-2:0]};
                      YNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Ym[`NF-2:0]};
                      ZNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Zm[`NF-2:0]};
                      InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                  end else begin 
                      InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                  end
                  
                  OfRes = OfResMax ? {Rs, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {Rs, {`NE{1'b1}}, {`NF{1'b0}}};
                  UfRes = {Rs, (`FLEN-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)};
                  NormRes = {Rs, Re, Rf};
              end
              `FMT1: begin  
                  if(`IEEE754) begin
                      XNaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, Xm[`NF-2:`NF-`NF1]};
                      YNaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, Ym[`NF-2:`NF-`NF1]};
                      ZNaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, Zm[`NF-2:`NF-`NF1]};
                      InvalidRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
                  end else begin 
                      InvalidRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
                  end
                  OfRes = OfResMax ? {{`FLEN-`LEN1{1'b1}}, Rs, {`NE1-1{1'b1}}, 1'b0, {`NF1{1'b1}}} : {{`FLEN-`LEN1{1'b1}}, Rs, {`NE1{1'b1}}, (`NF1)'(0)};
                  UfRes = {{`FLEN-`LEN1{1'b1}}, Rs, (`LEN1-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)};
                  NormRes = {{`FLEN-`LEN1{1'b1}}, Rs, Re[`NE1-1:0], Rf[`NF-1:`NF-`NF1]};
              end
              `FMT2: begin  
                  if(`IEEE754) begin
                      XNaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, Xm[`NF-2:`NF-`NF2]};
                      YNaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, Ym[`NF-2:`NF-`NF2]};
                      ZNaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, Zm[`NF-2:`NF-`NF2]};
                      InvalidRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, (`NF2-1)'(0)};
                  end else begin 
                      InvalidRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, (`NF2-1)'(0)};
                  end
                  
                  OfRes = OfResMax ? {{`FLEN-`LEN2{1'b1}}, Rs, {`NE2-1{1'b1}}, 1'b0, {`NF2{1'b1}}} : {{`FLEN-`LEN2{1'b1}}, Rs, {`NE2{1'b1}}, (`NF2)'(0)};
                  UfRes = {{`FLEN-`LEN2{1'b1}}, Rs, (`LEN2-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)};
                  NormRes = {{`FLEN-`LEN2{1'b1}}, Rs, Re[`NE2-1:0], Rf[`NF-1:`NF-`NF2]};
              end
              default: begin
                  if(`IEEE754) begin
                      XNaNRes = (`FLEN)'(0);
                      YNaNRes = (`FLEN)'(0);
                      ZNaNRes = (`FLEN)'(0);
                      InvalidRes = (`FLEN)'(0);
                  end else begin 
                      InvalidRes = (`FLEN)'(0);
                  end
                  OfRes = (`FLEN)'(0);
                  UfRes = (`FLEN)'(0);
                  NormRes = (`FLEN)'(0);
              end
          endcase

  end else if (`FPSIZES == 4) begin 
      always_comb
          case (OutFmt)
              2'h3: begin  
                  if(`IEEE754) begin
                      XNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Xm[`NF-2:0]};
                      YNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Ym[`NF-2:0]};
                      ZNaNRes = {1'b0, {`NE{1'b1}}, 1'b1, Zm[`NF-2:0]};
                      InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                  end else begin 
                      InvalidRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
                  end
                  
                  OfRes = OfResMax ? {Rs, {`NE-1{1'b1}}, 1'b0, {`NF{1'b1}}} : {Rs, {`NE{1'b1}}, {`NF{1'b0}}};
                  UfRes = {Rs, (`FLEN-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)};
                  NormRes = {Rs, Re, Rf};
              end
              2'h1: begin  
                  if(`IEEE754) begin
                      XNaNRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, Xm[`NF-2:`NF-`D_NF]};
                      YNaNRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, Ym[`NF-2:`NF-`D_NF]};
                      ZNaNRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, Zm[`NF-2:`NF-`D_NF]};
                      InvalidRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, (`D_NF-1)'(0)};
                  end else begin 
                      InvalidRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, (`D_NF-1)'(0)};
                  end
                  OfRes = OfResMax ? {{`FLEN-`D_LEN{1'b1}}, Rs, {`D_NE-1{1'b1}}, 1'b0, {`D_NF{1'b1}}} : {{`FLEN-`D_LEN{1'b1}}, Rs, {`D_NE{1'b1}}, (`D_NF)'(0)};
                  UfRes = {{`FLEN-`D_LEN{1'b1}}, Rs, (`D_LEN-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)};
                  NormRes = {{`FLEN-`D_LEN{1'b1}}, Rs, Re[`D_NE-1:0], Rf[`NF-1:`NF-`D_NF]};
              end
              2'h0: begin  
                  if(`IEEE754) begin
                      XNaNRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, Xm[`NF-2:`NF-`S_NF]};
                      YNaNRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, Ym[`NF-2:`NF-`S_NF]};
                      ZNaNRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, Zm[`NF-2:`NF-`S_NF]};
                      InvalidRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, (`S_NF-1)'(0)};
                  end else begin 
                      InvalidRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, (`S_NF-1)'(0)};
                  end
                  
                  OfRes = OfResMax ? {{`FLEN-`S_LEN{1'b1}}, Rs, {`S_NE-1{1'b1}}, 1'b0, {`S_NF{1'b1}}} : {{`FLEN-`S_LEN{1'b1}}, Rs, {`S_NE{1'b1}}, (`S_NF)'(0)};
                  UfRes = {{`FLEN-`S_LEN{1'b1}}, Rs, (`S_LEN-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)};
                  NormRes = {{`FLEN-`S_LEN{1'b1}}, Rs, Re[`S_NE-1:0], Rf[`NF-1:`NF-`S_NF]};
              end
              2'h2: begin  
                  if(`IEEE754) begin
                      XNaNRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, Xm[`NF-2:`NF-`H_NF]};
                      YNaNRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, Ym[`NF-2:`NF-`H_NF]};
                      ZNaNRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, Zm[`NF-2:`NF-`H_NF]};
                      InvalidRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, (`H_NF-1)'(0)};
                  end else begin 
                      InvalidRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, (`H_NF-1)'(0)};
                  end
                  
                  OfRes = OfResMax ? {{`FLEN-`H_LEN{1'b1}}, Rs, {`H_NE-1{1'b1}}, 1'b0, {`H_NF{1'b1}}} : {{`FLEN-`H_LEN{1'b1}}, Rs, {`H_NE{1'b1}}, (`H_NF)'(0)};      
                // zero is exact if dividing by infinity so don't add 1
                  UfRes = {{`FLEN-`H_LEN{1'b1}}, Rs, (`H_LEN-2)'(0), Plus1&Frm[1]&~(DivOp&YInf)};
                  NormRes = {{`FLEN-`H_LEN{1'b1}}, Rs, Re[`H_NE-1:0], Rf[`NF-1:`NF-`H_NF]};
              end
          endcase
  end

  // determine if you shoould kill the res - Cvt
  //      - do so if the res underflows, is zero (the exp doesnt calculate correctly). or the integer input is 0
  //      - dont set to zero if fp input is zero but not using the fp input
  //      - dont set to zero if int input is zero but not using the int input
  assign KillRes = CvtOp ? (CvtResUf|(XZero&~IntToFp)|(IntZero&IntToFp)) : FullRe[`NE+1] | (((YInf&~XInf)|XZero)&DivOp);//Underflow & ~ResSubnorm & (Re!=1);
  
  // calculate if the overflow result should be selected
  assign SelOfRes = Overflow|DivByZero|(InfIn&~(YInf&DivOp));
  
  // output infinity with result sign if divide by zero
  if(`IEEE754)
    always_comb
      if(XNaN&~(IntToFp&CvtOp))   PostProcRes = XNaNRes;
      else if(YNaN&~CvtOp)        PostProcRes = YNaNRes;
      else if(ZNaN&FmaOp)         PostProcRes = ZNaNRes;
      else if(Invalid)            PostProcRes = InvalidRes;
      else if(SelOfRes)           PostProcRes = OfRes;
      else if(KillRes)            PostProcRes = UfRes;
      else                        PostProcRes = NormRes;
  else
    always_comb
      if(NaNIn|Invalid)           PostProcRes = InvalidRes;
      else if(SelOfRes)           PostProcRes = OfRes;
      else if(KillRes)            PostProcRes = UfRes;
      else                        PostProcRes = NormRes;

  ///////////////////////////////////////////////////////////////////////////////////////
  // integer result selection        
  ///////////////////////////////////////////////////////////////////////////////////////        

  // select the overflow integer res
  //      - negitive infinity and out of range negitive input
  //                 |  int  |  long  |
  //          signed | -2^31 | -2^63  |
  //        unsigned |   0   |    0   |
  //
  //      - positive infinity and out of range positive input and NaNs
  //                 |   int  |  long  |
  //          signed | 2^31-1 | 2^63-1 |
  //        unsigned | 2^32-1 | 2^64-1 |
  //
  //      other: 32 bit unsinged res should be sign extended as if it were a signed number
  always_comb
    if(Signed)
      if(Xs&~NaNIn) // signed negitive
        if(Int64)   OfIntRes = {1'b1, {`XLEN-1{1'b0}}};
        else        OfIntRes = {{`XLEN-32{1'b1}}, 1'b1, {31{1'b0}}};
      else          // signed positive
        if(Int64)   OfIntRes = {1'b0, {`XLEN-1{1'b1}}};
        else        OfIntRes = {{`XLEN-32{1'b0}}, 1'b0, {31{1'b1}}};
    else
      if(Xs&~NaNIn) OfIntRes = {`XLEN{1'b0}}; // unsigned negitive
      else          OfIntRes = {`XLEN{1'b1}}; // unsigned positive


  // select the integer output
  //      - if the input is invalid (out of bounds NaN or Inf) then output overflow res
  //      - if the input underflows
  //          - if rounding and signed opperation and negitive input, output -1
  //          - otherwise output a rounded 0
  //      - otherwise output the normal res (trmined and sign extended if nessisary)
  always_comb
    if(IntInvalid)          FCvtIntRes = OfIntRes;
    else if(CvtCe[`NE]) 
      if(Xs&Signed&Plus1)   FCvtIntRes = {{`XLEN{1'b1}}};
      else                  FCvtIntRes = {{`XLEN-1{1'b0}}, Plus1};
    else if(Int64)          FCvtIntRes = CvtNegRes[`XLEN-1:0];
    else                    FCvtIntRes = {{`XLEN-32{CvtNegRes[31]}}, CvtNegRes[31:0]};
endmodule