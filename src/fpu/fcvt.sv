
///////////////////////////////////////////
// fcvt.sv
//
// Written: me@KatherineParry.com
// Modified: 7/5/2022
//
// Purpose: Floating point conversions of configurable size
// 
// Documentation: RISC-V System on Chip Design Chapter 13
//
// Int component of the Wally configurable RISC-V project.
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

module fcvt (
  input  logic                    Xs,         // input's sign
  input  logic [`NE-1:0]          Xe,         // input's exponent
  input  logic [`NF:0]            Xm,         // input's fraction
  input  logic [`XLEN-1:0]        Int,        // integer input - from IEU
  input  logic [2:0]              OpCtrl,     // choose which opperation (look below for values)
  input  logic                    ToInt,      // is fp->int (since it's writting to the integer register)
  input  logic                    XZero,      // is the input zero
  input  logic [`FMTBITS-1:0]     Fmt,        // the input's precision (11=quad 01=double 00=single 10=half)
  output logic [`NE:0]            Ce,         // the calculated expoent
  output logic [`LOGCVTLEN-1:0]   ShiftAmt,   // how much to shift by
  output logic                    ResSubnormUf,// does the result underflow or is subnormal
  output logic                    Cs,         // the result's sign
  output logic                    IntZero,    // is the integer zero?
  output logic [`CVTLEN-1:0]      LzcIn       // input to the Leading Zero Counter (priority encoder)
  );

  // OpCtrls:
  //  fp->fp conversions: {0, output precision} - only one of the operations writes to the int register
  //      half   - 10
  //      single - 00
  //      double - 01
  //      quad   - 11
  //  int<->fp conversions: {is int->fp?, is the integer 64-bit?, is the integer signed?}
  //                            bit 2              bit 1                   bit 0
  //      for example: signed long -> single floating point has the OpCode 101

  logic [`FMTBITS-1:0]    OutFmt;     // format of the output
  logic [`XLEN-1:0]       PosInt;     // the positive integer input
  logic [`XLEN-1:0]       TrimInt;    // integer trimmed to the correct size
  logic [`NE-2:0]         NewBias;    // the bias of the final result
  logic [`NE-1:0]	        OldExp;     // the old exponent
  logic                   Signed;     // is the opperation with a signed integer?
  logic                   Int64;      // is the integer 64 bits?
  logic                   IntToFp;    // is the opperation an int->fp conversion?
  logic [`CVTLEN:0]       LzcInFull;  // input to the Leading Zero Counter (priority encoder)
  logic [`LOGCVTLEN-1:0]  LeadingZeros; // output from the LZC


  // seperate OpCtrl for code readability
  assign Signed =  OpCtrl[0];
  assign Int64 =   OpCtrl[1];
  assign IntToFp = OpCtrl[2];

  // choose the ouptut format depending on the opperation
  //      - fp -> fp: OpCtrl contains the percision of the output
  //      - int -> fp: Fmt contains the percision of the output
  if (`FPSIZES == 2) 
      assign OutFmt = IntToFp ? Fmt : (OpCtrl[1:0] == `FMT); 
  else if (`FPSIZES == 3 | `FPSIZES == 4) 
      assign OutFmt = IntToFp ? Fmt : OpCtrl[1:0]; 


  ///////////////////////////////////////////////////////////////////////////
  // negation
  ///////////////////////////////////////////////////////////////////////////
  // 1) negate the input if the input is a negitive singed integer
  // 2) trim the input to the proper size (kill the 32 most significant zeroes if needed)

  assign PosInt = Cs ? -Int : Int;
  assign TrimInt = {{`XLEN-32{Int64}}, {32{1'b1}}} & PosInt;
  assign IntZero = ~|TrimInt;

  ///////////////////////////////////////////////////////////////////////////
  // lzc 
  ///////////////////////////////////////////////////////////////////////////
  
  // choose the input to the leading zero counter i.e. priority encoder
  //             int -> fp : | positive integer | 00000... (if needed) | 
  //             fp  -> fp : | fraction         | 00000... (if needed) | 
  assign LzcInFull = IntToFp ? {TrimInt, {`CVTLEN-`XLEN+1{1'b0}}} :
                            {Xm, {`CVTLEN-`NF{1'b0}}};

  // used as shifter input in postprocessor
  assign LzcIn = LzcInFull[`CVTLEN-1:0];
  
  lzc #(`CVTLEN+1) lzc (.num(LzcInFull), .ZeroCnt(LeadingZeros));
  
  ///////////////////////////////////////////////////////////////////////////
  // exp calculations
  ///////////////////////////////////////////////////////////////////////////

  // Select the bias of the output
  //      fp -> int : select 1
  //      ??? -> fp : pick the new bias depending on the output format 
  if (`FPSIZES == 1) begin
      assign NewBias = ToInt ? (`NE-1)'(1) : (`NE-1)'(`BIAS); 

  end else if (`FPSIZES == 2) begin
      logic [`NE-2:0] NewBiasToFp;
      assign NewBiasToFp = OutFmt ? (`NE-1)'(`BIAS) : (`NE-1)'(`BIAS1); 
      assign NewBias = ToInt ? (`NE-1)'(1) : NewBiasToFp; 

  end else if (`FPSIZES == 3) begin
      logic [`NE-2:0] NewBiasToFp;
      always_comb
          case (OutFmt)
              `FMT: NewBiasToFp =  (`NE-1)'(`BIAS);
              `FMT1: NewBiasToFp = (`NE-1)'(`BIAS1);
              `FMT2: NewBiasToFp = (`NE-1)'(`BIAS2);
              default: NewBiasToFp = {`NE-1{1'bx}};
          endcase
      assign NewBias = ToInt ? (`NE-1)'(1) : NewBiasToFp; 

  end else if (`FPSIZES == 4) begin        
      logic [`NE-2:0] NewBiasToFp;
      always_comb
          case (OutFmt)
              2'h3: NewBiasToFp =  (`NE-1)'(`Q_BIAS);
              2'h1: NewBiasToFp =  (`NE-1)'(`D_BIAS);
              2'h0: NewBiasToFp =  (`NE-1)'(`S_BIAS);
              2'h2: NewBiasToFp =  (`NE-1)'(`H_BIAS);
          endcase
      assign NewBias = ToInt ? (`NE-1)'(1) : NewBiasToFp; 
  end


  // select the old exponent
  //      int -> fp : largest bias + XLEN-1
  //      fp -> ??? : XExp
  assign OldExp = IntToFp ? (`NE)'(`BIAS)+(`NE)'(`XLEN-1) : Xe;
  
  // calculate CalcExp
  //      fp -> fp : 
  //          - XExp - Largest bias + new bias - (LeadingZeros+1)
  //                                          only do ^ if the input was subnormal
  //              - convert the expoenent to the final preciaion (Exp - oldBias + newBias)
  //              - correct the expoent when there is a normalization shift ( + LeadingZeros+1) 
  //              - the plus 1 is built into the leading zeros by counting the leading zeroes in the mantissa rather than the fraction
  //      fp -> int : XExp - Largest Bias + 1 - (LeadingZeros+1)
  //          |  `XLEN  zeros |     Mantissa      | 0's if nessisary | << CalcExp
  //          process:
  //              - start
  //                  |  `XLEN  zeros     |     Mantissa      | 0's if nessisary |
  //
  //              - shift left 1 (1)
  //                  | `XLEN-1 zeros |bit|     frac      | 0's if nessisary |
  //                                      . <- binary point
  //
  //              - shift left till unbiased exponent is 0 (XExp - Largest Bias)
  //                  |  0's |     Mantissa      |      0's if nessisary     |
  //                  |     keep        |
  //
  //              - if the input is subnormal then we dont shift... so the  "- LeadingZeros" is just leftovers from other options
  //      int -> fp : largest bias +  XLEN-1 - Largest bias + new bias - LeadingZeros = XLEN-1 + NewBias - LeadingZeros
  //              Process:
  //                      |XLEN|.0000
  //                  - shifted right by XLEN (XLEN)
  //                      000000.|XLEN|
  //                  - shift left to normilize (-LeadingZeros)
  //                      000000.1...
  //                  - shift left 1 to normalize
  //                      000001.stuff
  //                  - newBias to make the biased exponent
  //
  //          oldexp         - biasold         - LeadingZeros                               + newbias
  assign Ce = {1'b0, OldExp} - (`NE+1)'(`BIAS) - {{`NE-`LOGCVTLEN+1{1'b0}}, (LeadingZeros)} + {2'b0, NewBias};


  // find if the result is dnormal or underflows
  //      - if Calculated expoenent is 0 or negitive (and the input/result is not exactaly 0)
  //      - can't underflow an integer to Fp conversion
  assign ResSubnormUf = (~|Ce | Ce[`NE])&~XZero&~IntToFp;


  ///////////////////////////////////////////////////////////////////////////
  // shifter
  ///////////////////////////////////////////////////////////////////////////

  // kill the shift if it's negitive
  // select the amount to shift by
  //      fp -> int: 
  //          - shift left by CalcExp - essentially shifting until the unbiased exponent = 0
  //              - don't shift if supposed to shift right (underflowed or Subnorm input)
  //      subnormal/undeflowed result fp -> fp:
  //          - shift left by NF-1+CalcExp - to shift till the biased expoenent is 0
  //      ??? -> fp: 
  //          - shift left by LeadingZeros - to shift till the result is normalized
  //              - only shift fp -> fp if the intital value is subnormal
  //                  - this is a problem because the input to the lzc was the fraction rather than the mantissa
  //                  - rather have a few and-gates than an extra bit in the priority encoder??? *** is this true?
  always_comb
      if(ToInt)                       ShiftAmt = Ce[`LOGCVTLEN-1:0]&{`LOGCVTLEN{~Ce[`NE]}};
      else if (ResSubnormUf)  ShiftAmt = (`LOGCVTLEN)'(`NF-1)+Ce[`LOGCVTLEN-1:0];
      else                            ShiftAmt = LeadingZeros;

      
  ///////////////////////////////////////////////////////////////////////////
  // sign
  ///////////////////////////////////////////////////////////////////////////

  // determine the sign of the result
  //      - if int -> fp
  //          - if 64-bit : check the msb of the 64-bit integer input and if it's signed
  //          - if 32-bit : check the msb of the 32-bit integer input and if it's signed
  //      - otherwise: the floating point input's sign
  always_comb
      if(IntToFp)
          if(Int64)   Cs = Int[`XLEN-1]&Signed;
          else        Cs = Int[31]&Signed;
      else            Cs = Xs;

endmodule

