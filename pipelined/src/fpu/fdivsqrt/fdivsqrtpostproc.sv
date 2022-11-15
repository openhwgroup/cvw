///////////////////////////////////////////
// fdivsqrtpostproc.sv
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

module fdivsqrtpostproc(
  input  logic [`DIVb+3:0] WS, WC,
  input  logic [`DIVN-2:0]  D, // U0.N-1
  input  logic [`DIVb:0] FirstU, FirstUM, 
  input  logic [`DIVb+1:0] FirstC,
  input  logic Firstun,
  input  logic SqrtM,
  input  logic SpecialCaseM,
  input  logic RemOp, MDUE, ALTB, BZero, As,
  input  logic [`DIVBLEN:0] n, m,
  output logic [`DIVb:0] QmM, 
  output logic WZero,
  output logic DivSM
);
  
  logic [`DIVb+3:0] W, Sum, RemD;
  logic [`DIVb:0] PreQmM;
  logic NegSticky, PostInc;
  logic weq0;
  logic [`DIVBLEN:0] NormShift;
  logic [`DIVb:0] IntQuot, NormQuot;
  logic [`DIVb+3:0] IntRem, NormRem;
  logic [`DIVb:0] PreResult, Result;

  // check for early termination on an exact result.  If the result is not exact, the sticky should be set
  aplusbeq0 #(`DIVb+4) wspluswceq0(WS, WC, weq0);

  if (`RADIX == 2) begin
    logic [`DIVb+3:0] FZero;
    logic [`DIVb+2:0] FirstK;
    logic wfeq0;
    logic [`DIVb+3:0] WCF, WSF;

    assign FirstK = ({1'b1, FirstC} & ~({1'b1, FirstC} << 1));
    assign FZero = SqrtM ? {FirstUM[`DIVb], FirstUM, 2'b0} | {FirstK,1'b0} : {3'b1,D,{`DIVb-`DIVN+2{1'b0}}};
    csa #(`DIVb+4) fadd(WS, WC, FZero, 1'b0, WSF, WCF); // compute {WCF, WSF} = {WS + WC + FZero};
    aplusbeq0 #(`DIVb+4) wcfpluswsfeq0(WCF, WSF, wfeq0);
    assign WZero = weq0|(wfeq0 & Firstun);
  end else begin
    assign WZero = weq0;
  end 
  assign DivSM = ~WZero & ~(SpecialCaseM & SqrtM); // ***unsure why SpecialCaseM has to be gated by SqrtM, but otherwise fails regression on divide

  // Determine if sticky bit is negative
  assign Sum = WC + WS;
  assign W = $signed(Sum) >>> `LOGR;
  assign NegSticky = W[`DIVb+3];
  assign RemD = {4'b0000, D, {(`DIVb-`DIVN+1){1'b0}}};

  always_comb 
    if (~As)
      if (NegSticky) begin
        assign NormQuot = FirstUM;
        assign NormRem  = W + RemD;
        assign PostInc = 0;
      end else begin
        assign NormQuot = FirstU;
        assign NormRem  = W;
        assign PostInc = 0;
      end
    else 
      if (NegSticky | weq0) begin
        assign NormQuot = FirstU;
        assign NormRem  = W;
        assign PostInc = 0;
      end else begin 
        assign NormQuot = FirstU;
        assign NormRem  = W - RemD;
        assign PostInc = 1;
      end

/*
  always_comb
    if(ALTB) begin
      assign   IntQuot = '0;
      assign   IntRem  = ForwardedSrcAE;
    end else if (BZero) begin
      assign   IntQuot = '1;
      assign   IntRem  = ForwardedSrcAE;
    end else if (EarlyTerm) begin
      if (weq0) begin
        assign IntQuot = FirstU;
        assign IntRem  = '0;
      end else begin
        assign IntQuot = FirstUM;
        assign IntRem  = '0;
      end
    end else begin 
      assign   IntQuot = NormQuot;
      assign   IntRem  = NormRem;
    end 
  */
  
  /*
  always_comb
    if (RemOp) begin
      assign NormShift = m + (`DIVBLEN)'(`DIVa);
      assign PreResult = IntRem;
    end else begin
      assign NormShift = DIVb - (j << `LOGR);
      assign PreResult = IntQuot;
    end
  */

   // division takes the result from the next cycle, which is shifted to the left one more time so the square root also needs to be shifted
  
  // assign Result = ($signed(PreResult) >>> NormShift) + (PostInc & ~RemOp);

  assign PreQmM = NegSticky ? FirstUM : FirstU; // Select U or U-1 depending on negative sticky bit
  assign QmM = SqrtM ? (PreQmM << 1) : PreQmM;
endmodule