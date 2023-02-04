
///////////////////////////////////////////
// fcmp.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Floating-point comparison unit
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

// OpCtrl values
//    110   min
//    101   max
//    010   equal
//    001   less than
//    011   less than or equal

module fcmp (   
  input  logic [`FMTBITS-1:0]   Fmt,           // format of fp number
  input  logic [2:0]            OpCtrl,        // see above table
  input  logic                  Xs, Ys,        // input signs
  input  logic [`NE-1:0]        Xe, Ye,        // input exponents
  input  logic [`NF:0]          Xm, Ym,        // input mantissa
  input  logic                  XZero, YZero,  // is zero
  input  logic                  XNaN, YNaN,    // is NaN
  input  logic                  XSNaN, YSNaN,  // is signaling NaN
  input  logic [`FLEN-1:0]      X, Y,          // original inputs (before unpacker)
  output logic                  CmpNV,         // invalid flag
  output logic [`FLEN-1:0]      CmpFpRes,      // compare floating-point result
  output logic [`XLEN-1:0]      CmpIntRes      // compare integer result
);

  logic LTabs, LT, EQ;         // is X < or > or = Y
  logic [`FLEN-1:0] NaNRes;    // NaN result
  logic BothZero;              // are both inputs zero
  logic EitherNaN, EitherSNaN; // are either input a (signaling) NaN
  
  assign LTabs= {1'b0, Xe, Xm} < {1'b0, Ye, Ym}; // unsigned comparison, treating FP as integers
  assign LT = (Xs & ~Ys) | (Xs & Ys & ~LTabs & ~EQ) | (~Xs & ~Ys & LTabs); // signed comparison
  assign EQ = (X == Y);

  assign BothZero = XZero&YZero;
  assign EitherNaN = XNaN|YNaN;
  assign EitherSNaN = XSNaN|YSNaN;


  // flags
  //    Min/Max - if an input is a signaling NaN set invalid flag
  //    LT/LE - signaling - sets invalid if NaN input
  //    EQ - quiet - sets invalid if signaling NaN input
  always_comb begin
    case (OpCtrl[2:0])
        3'b110: CmpNV = EitherSNaN;//min 
        3'b101: CmpNV = EitherSNaN;//max
        3'b010: CmpNV = EitherSNaN;//equal
        3'b001: CmpNV = EitherNaN;//less than
        3'b011: CmpNV = EitherNaN;//less than or equal
        default: CmpNV = 1'bx;
    endcase
  end 

  // fmin/fmax of two NaNs returns a quiet NaN of the appropriate size
  // for IEEE, return the payload of X
  // for RISC-V, return the canonical NaN

  // select the NaN result
  if (`FPSIZES == 1)
    if(`IEEE754) assign NaNRes = {Xs, {`NE{1'b1}}, 1'b1, Xm[`NF-2:0]};
    else         assign NaNRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};

  else if (`FPSIZES == 2) 
    if(`IEEE754) assign NaNRes = Fmt ? {Xs, {`NE{1'b1}}, 1'b1, Xm[`NF-2:0]} : {{`FLEN-`LEN1{1'b1}}, Xs, {`NE1{1'b1}}, 1'b1, Xm[`NF-2:`NF-`NF1]};
    else         assign NaNRes = Fmt ? {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}} : {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
  
  else if (`FPSIZES == 3)
    always_comb
          case (Fmt)
              `FMT:  
                if(`IEEE754) NaNRes = {Xs, {`NE{1'b1}}, 1'b1, Xm[`NF-2:0]};
                else         NaNRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
              `FMT1:
                if(`IEEE754) NaNRes = {{`FLEN-`LEN1{1'b1}}, Xs, {`NE1{1'b1}}, 1'b1, Xm[`NF-2:`NF-`NF1]};
                else         NaNRes = {{`FLEN-`LEN1{1'b1}}, 1'b0, {`NE1{1'b1}}, 1'b1, (`NF1-1)'(0)};
              `FMT2:
                if(`IEEE754) NaNRes = {{`FLEN-`LEN2{1'b1}}, Xs, {`NE2{1'b1}}, 1'b1, Xm[`NF-2:`NF-`NF2]};
                else         NaNRes = {{`FLEN-`LEN2{1'b1}}, 1'b0, {`NE2{1'b1}}, 1'b1, (`NF2-1)'(0)};
              default:        NaNRes = {`FLEN{1'bx}};
          endcase

  else if (`FPSIZES == 4)
    always_comb
          case (Fmt)
              2'h3:  
                if(`IEEE754) NaNRes = {Xs, {`NE{1'b1}}, 1'b1, Xm[`NF-2:0]};
                else         NaNRes = {1'b0, {`NE{1'b1}}, 1'b1, {`NF-1{1'b0}}};
              2'h1:  
                if(`IEEE754) NaNRes = {{`FLEN-`D_LEN{1'b1}}, Xs, {`D_NE{1'b1}}, 1'b1, Xm[`NF-2:`NF-`D_NF]};
                else         NaNRes = {{`FLEN-`D_LEN{1'b1}}, 1'b0, {`D_NE{1'b1}}, 1'b1, (`D_NF-1)'(0)};
              2'h0: 
                if(`IEEE754) NaNRes = {{`FLEN-`S_LEN{1'b1}}, Xs, {`S_NE{1'b1}}, 1'b1, Xm[`NF-2:`NF-`S_NF]};
                else         NaNRes = {{`FLEN-`S_LEN{1'b1}}, 1'b0, {`S_NE{1'b1}}, 1'b1, (`S_NF-1)'(0)};
              2'h2:
                if(`IEEE754) NaNRes = {{`FLEN-`H_LEN{1'b1}}, Xs, {`H_NE{1'b1}}, 1'b1, Xm[`NF-2:`NF-`H_NF]};
                else         NaNRes = {{`FLEN-`H_LEN{1'b1}}, 1'b0, {`H_NE{1'b1}}, 1'b1, (`H_NF-1)'(0)};
          endcase


  // Min/Max
  //    - outputs the min/max of X and Y
  //    - -0 < 0
  //    - if both are NaN return quiet X
  //    - if one is a NaN output the non-NaN
  always_comb
    if(OpCtrl[0]) // MAX
        if(XNaN)
          if(YNaN)    CmpFpRes = NaNRes;   // X = NaN Y = NaN
          else        CmpFpRes = Y;        // X = NaN Y != NaN
        else
          if(YNaN)    CmpFpRes = X; // X != NaN Y = NaN
          else // X,Y != NaN
              if(LT)   CmpFpRes = Y; // X < Y
              else     CmpFpRes = X; // X > Y
    else  // MIN
        if(XNaN)
          if(YNaN)    CmpFpRes = NaNRes;   // X = NaN Y = NaN
          else        CmpFpRes = Y;        // X = NaN Y != NaN
        else
          if(YNaN)    CmpFpRes = X; // X != NaN Y = NaN
          else // X,Y != NaN
              if(LT)   CmpFpRes = X; // X < Y
              else     CmpFpRes = Y; // X > Y
                                  
  // LT/LE/EQ
  //    - -0 = 0
  //    - inf = inf and -inf = -inf
  //    - return 0 if comparison with NaN (unordered)
  assign CmpIntRes = {(`XLEN-1)'(0), (((EQ|BothZero)&OpCtrl[1])|(LT&OpCtrl[0]&~BothZero))&~EitherNaN};
  
endmodule
