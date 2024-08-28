///////////////////////////////////////////
// divremsqrtround.sv
//
// Written: kekim@hmc.edu, me@KatherineParry.com
// Modified: 19 May 2023
//
// Purpose: Rounder
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



module divremsqrtround import cvw::*;  #(parameter cvw_t P)  (
  input  logic [P.FMTBITS-1:0]     OutFmt,             // output format
  input  logic [2:0]              Frm,                // rounding mode
  input  logic                    Ms,                 // normalized sign
  input  logic [P.NORMSHIFTSZDRSU-1:0] Mf,                 // normalized fraction
  // divsqrt
  input  logic                    DivOp,              // is a division opperation being done
  input  logic                    DivSticky,          // divsqrt sticky bit
  input  logic [P.NE+1:0]          Ue,                 // the divsqrt calculated expoent
  // outputs
  output logic [P.NE+1:0]          Me,                 // normalied fraction
  output logic                    UfPlus1,            // do you add one to the result if given an unbounded exponent
  output logic [P.NE+1:0]          FullRe,             // Re with bits to determine sign and overflow
  output logic [P.NE-1:0]          Re,                 // Result exponent
  output logic [P.NF-1:0]          Rf,                 // Result fractionNormS
  output logic                    Sticky,             // sticky bit
  output logic                    Plus1,              // do you add one to the final result
  output logic                    Round, Guard        // bits needed to calculate rounding
);

  logic           UfCalcPlus1;        // calculated plus one for unbounded exponent
  logic           NormSticky;         // normalized sum's sticky bit
  logic [P.NF-1:0] RoundFrac;          // rounded fraction
  logic           FpGuard, FpRound;   // floating point round/guard bits
  logic           FpLsbRes;           // least significant bit of floating point result
  logic           LsbRes;             // lsb of result
  logic           CalcPlus1;          // calculated plus1
  logic           FpPlus1;            // do you add one to the fp result 
  logic [P.FLEN:0] RoundAdd;           // how much to add to the result

// what position is XLEN in?
//  options: 
//     1: XLEN > NF   > NF1
//     2: NF   > XLEN > NF1
//     3: NF   > NF1  > XLEN
//  single and double will always be smaller than XLEN

  ///////////////////////////////////////////////////////////////////////////////
  // Rounding
  ///////////////////////////////////////////////////////////////////////////////

  // round to nearest even
  //      {Round, Sticky}
  //      0x - do nothing
  //      10 - tie - Plus1 if result is odd  (LSBNormSum = 1)
  //          - don't add 1 if a small number was supposed to be subtracted
  //      11 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
  //         - plus 1 otherwise

  //  round to zero - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

  //  round to -infinity
  //          - Plus1 if negative unless a small number was supposed to be subtracted from a result with guard and round bits of 0
  //          - subtract 1 if a small number was supposed to be subtracted from a positive result with guard and round bits of 0

  //  round to infinity
  //          - Plus1 if positive unless a small number was supposed to be subtracted from a result with guard and round bits of 0
  //          - subtract 1 if a small number was supposed to be subtracted from a negative result with guard and round bits of 0

  //  round to nearest max magnitude
  //      {Guard, Round, Sticky}
  //      0x - do nothing
  //      10 - tie - Plus1
  //          - don't add 1 if a small number was supposed to be subtracted
  //      11 - do nothing if a small number was supposed to subtracted (the sticky bit was set by the small number)
  //         - Plus 1 otherwise


  // determine what format the final result is in: int or fp

  // sticky bit calculation
  if (P.FPSIZES == 1) begin
    assign NormSticky = (|Mf[P.NORMSHIFTSZDRSU-P.NF-2:0]);

  end else if (P.FPSIZES == 2) begin
    assign NormSticky = (|Mf[P.NORMSHIFTSZDRSU-P.NF1-2:P.NORMSHIFTSZDRSU-P.NF-1]&(~OutFmt)) |
                                                (|Mf[P.NORMSHIFTSZDRSU-P.NF-2:0]);


  end else if (P.FPSIZES == 3) begin

    assign NormSticky = (|Mf[P.NORMSHIFTSZDRSU-P.NF2-2:P.NORMSHIFTSZDRSU-P.NF1-1]&(OutFmt==P.FMT2)) |
                                                (|Mf[P.NORMSHIFTSZDRSU-P.NF1-2:P.NORMSHIFTSZDRSU-P.NF-1]&(~(OutFmt==P.FMT))) |
                                                (|Mf[P.NORMSHIFTSZDRSU-P.NF-2:0]);

  end else if (P.FPSIZES == 4) begin
    assign NormSticky = (|Mf[P.NORMSHIFTSZDRSU-P.H_NF-2:P.NORMSHIFTSZDRSU-P.Q_NF-1]&(OutFmt==P.H_FMT)) |
                                                (|Mf[P.NORMSHIFTSZDRSU-P.S_NF-2:P.NORMSHIFTSZDRSU-P.Q_NF-1]&((OutFmt==P.S_FMT))) | 
                                                (|Mf[P.NORMSHIFTSZDRSU-P.D_NF-2:P.NORMSHIFTSZDRSU-P.Q_NF-1]&((OutFmt==P.D_FMT))) |
                                                (|Mf[P.NORMSHIFTSZDRSU-P.Q_NF-2:0]&(OutFmt==P.Q_FMT));
  end
  


  // only add the Addend sticky if doing an FMA opperation
  //      - the shifter shifts too far left when there's an underflow (shifting out all possible sticky bits)
  //assign Sticky = DivSticky&DivOp | NormSticky | StickySubnorm;
  assign Sticky = DivSticky&DivOp | NormSticky;
  //assign Sticky = DivSticky&DivOp;
  



  // determine round and LSB of the rounded value
  //      - underflow round bit is used to determint the underflow flag
  if (P.FPSIZES == 1) begin
      assign FpGuard = Mf[P.NORMSHIFTSZDRSU-P.NF-1];
      assign FpLsbRes = Mf[P.NORMSHIFTSZDRSU-P.NF];
      assign FpRound = Mf[P.NORMSHIFTSZDRSU-P.NF-2];

  end else if (P.FPSIZES == 2) begin
      assign FpGuard = OutFmt ? Mf[P.NORMSHIFTSZDRSU-P.NF-1] : Mf[P.NORMSHIFTSZDRSU-P.NF1-1];
      assign FpLsbRes = OutFmt ? Mf[P.NORMSHIFTSZDRSU-P.NF] : Mf[P.NORMSHIFTSZDRSU-P.NF1];
      assign FpRound = OutFmt ? Mf[P.NORMSHIFTSZDRSU-P.NF-2] : Mf[P.NORMSHIFTSZDRSU-P.NF1-2];

  end else if (P.FPSIZES == 3) begin
      always_comb
          case (OutFmt)
              P.FMT: begin
                  FpGuard = Mf[P.NORMSHIFTSZDRSU-P.NF-1];
                  FpLsbRes = Mf[P.NORMSHIFTSZDRSU-P.NF];
                  FpRound = Mf[P.NORMSHIFTSZDRSU-P.NF-2];
              end
              P.FMT1: begin
                  FpGuard = Mf[P.NORMSHIFTSZDRSU-P.NF1-1];
                  FpLsbRes = Mf[P.NORMSHIFTSZDRSU-P.NF1];
                  FpRound = Mf[P.NORMSHIFTSZDRSU-P.NF1-2];
              end
              P.FMT2: begin
                  FpGuard = Mf[P.NORMSHIFTSZDRSU-P.NF2-1];
                  FpLsbRes = Mf[P.NORMSHIFTSZDRSU-P.NF2];
                  FpRound = Mf[P.NORMSHIFTSZDRSU-P.NF2-2];
              end
              default: begin
                  FpGuard = 1'bx;
                  FpLsbRes = 1'bx;
                  FpRound = 1'bx;
              end
          endcase
  end else if (P.FPSIZES == 4) begin
      always_comb
          case (OutFmt)
              2'h3: begin
                  FpGuard = Mf[P.NORMSHIFTSZDRSU-P.Q_NF-1];
                  FpLsbRes = Mf[P.NORMSHIFTSZDRSU-P.Q_NF];
                  FpRound = Mf[P.NORMSHIFTSZDRSU-P.Q_NF-2];
              end
              2'h1: begin
                  FpGuard = Mf[P.NORMSHIFTSZDRSU-P.D_NF-1];
                  FpLsbRes = Mf[P.NORMSHIFTSZDRSU-P.D_NF];
                  FpRound = Mf[P.NORMSHIFTSZDRSU-P.D_NF-2];
              end
              2'h0: begin
                  FpGuard = Mf[P.NORMSHIFTSZDRSU-P.S_NF-1];
                  FpLsbRes = Mf[P.NORMSHIFTSZDRSU-P.S_NF];
                  FpRound = Mf[P.NORMSHIFTSZDRSU-P.S_NF-2];
              end
              2'h2: begin
                  FpGuard = Mf[P.NORMSHIFTSZDRSU-P.H_NF-1];
                  FpLsbRes = Mf[P.NORMSHIFTSZDRSU-P.H_NF];
                  FpRound = Mf[P.NORMSHIFTSZDRSU-P.H_NF-2];
              end
          endcase
  end

  
  assign Guard =  FpGuard;
  assign LsbRes = FpLsbRes;
  assign Round =  FpRound;


  always_comb begin
      // Determine if you add 1
      case (Frm)
          3'b000: CalcPlus1 = Guard & (Round|Sticky|LsbRes);//round to nearest even
          3'b001: CalcPlus1 = 0;//round to zero
          3'b010: CalcPlus1 = Ms;//round down
          3'b011: CalcPlus1 = ~Ms;//round up
          3'b100: CalcPlus1 = Guard;//round to nearest max magnitude
          default: CalcPlus1 = 1'bx;
      endcase
      // Determine if you add 1 (for underflow flag)
      case (Frm)
          3'b000: UfCalcPlus1 = Round & (Sticky|Guard);//round to nearest even
          3'b001: UfCalcPlus1 = 0;//round to zero
          3'b010: UfCalcPlus1 = Ms;//round down
          3'b011: UfCalcPlus1 = ~Ms;//round up
          3'b100: UfCalcPlus1 = Round;//round to nearest max magnitude
          default: UfCalcPlus1 = 1'bx;
      endcase
  
  end

  // If an answer is exact don't round
  assign Plus1 = CalcPlus1 & (Sticky|Round|Guard);
  assign FpPlus1 = Plus1;
  assign UfPlus1 = UfCalcPlus1 & (Sticky|Round);




  // place Plus1 into the proper position for the format
  if (P.FPSIZES == 1) begin
      assign RoundAdd = {{P.FLEN{1'b0}}, FpPlus1};

  end else if (P.FPSIZES == 2) begin
      // \/FLEN+1
      //  | NE+2 |        NF      |
      //  '-NE+2-^----NF1----^
      // P.FLEN+1-P.NE-2-P.NF1 = FLEN-1-NE-NF1
      assign RoundAdd = {(P.NE+1+P.NF1)'(0), FpPlus1&~OutFmt, (P.NF-P.NF1-1)'(0), FpPlus1&OutFmt};

  end else if (P.FPSIZES == 3) begin
      assign RoundAdd = {(P.NE+1+P.NF2)'(0), FpPlus1&(OutFmt==P.FMT2), (P.NF1-P.NF2-1)'(0), FpPlus1&(OutFmt==P.FMT1), (P.NF-P.NF1-1)'(0), FpPlus1&(OutFmt==P.FMT)};

  end else if (P.FPSIZES == 4)      
      assign RoundAdd = {(P.Q_NE+1+P.H_NF)'(0), FpPlus1&(OutFmt==P.H_FMT), (P.S_NF-P.H_NF-1)'(0), FpPlus1&(OutFmt==P.S_FMT), (P.D_NF-P.S_NF-1)'(0), FpPlus1&(OutFmt==P.D_FMT), (P.Q_NF-P.D_NF-1)'(0), FpPlus1&(OutFmt==P.Q_FMT)};



  // trim unneeded bits from fraction
  assign RoundFrac = Mf[P.NORMSHIFTSZDRSU-1:P.NORMSHIFTSZDRSU-P.NF];
  


  // select the exponent
  assign Me = Ue;



  // round the result
  //      - if the fraction overflows one should be added to the exponent
  assign {FullRe, Rf} = {Me, RoundFrac} + RoundAdd;
  assign Re = FullRe[P.NE-1:0];


endmodule
