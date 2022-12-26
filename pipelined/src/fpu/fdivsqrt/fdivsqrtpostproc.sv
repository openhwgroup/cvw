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
  input  logic              clk, reset,
  input  logic              StallM,
  input  logic [`DIVb+3:0]  WS, WC,
  input  logic [`DIVb-1:0]  D, 
  input  logic [`DIVb:0]    FirstU, FirstUM, 
  input  logic [`DIVb+1:0]  FirstC,
  input  logic              SqrtE, MDUE,
  input  logic              Firstun, SqrtM, SpecialCaseM, OTFCSwapEM,
	input  logic [`XLEN-1:0]  ForwardedSrcAM,
  input  logic              RemOpM, ALTBM, BZeroM, AsM, 
  input  logic [`DIVBLEN:0] nM, mM,
  output logic [`DIVb:0]    QmM, 
  output logic              WZeroE,
  output logic              DivSM,
  output logic [`XLEN-1:0]  FPIntDivResultM
);
  
  logic [`DIVb+3:0] W, Sum, DM;
  logic [`DIVb:0] PreQmM;
  logic NegStickyM, PostIncM;
  logic weq0E;
  logic [`DIVBLEN:0] NormShiftM;
  logic [`DIVb:0] IntQuotM, NormQuotM;
  logic [`DIVb+3:0] IntRemM, NormRemM;
  logic signed [`DIVb+3:0] PreResultM, PreFPIntDivResultM;
  logic WZeroM;

  //////////////////////////
  // Execute Stage: Detect early termination for an exact result
  //////////////////////////

  // check for early termination on an exact result. 
  aplusbeq0 #(`DIVb+4) wspluswceq0(WS, WC, weq0E);

  if (`RADIX == 2) begin: R2EarlyTerm
    logic [`DIVb+3:0] FZeroE;
    logic [`DIVb+2:0] FirstK;
    logic wfeq0E;
    logic [`DIVb+3:0] WCF, WSF;

    assign FirstK = ({1'b1, FirstC} & ~({1'b1, FirstC} << 1));
    assign FZeroE = (SqrtE & ~MDUE) ? {FirstUM[`DIVb], FirstUM, 2'b0} | {FirstK,1'b0} : {3'b001,D,1'b0};
    csa #(`DIVb+4) fadd(WS, WC, FZeroE, 1'b0, WSF, WCF); // compute {WCF, WSF} = {WS + WC + FZero};
    aplusbeq0 #(`DIVb+4) wcfpluswsfeq0(WCF, WSF, wfeq0E);
    assign WZeroE = weq0E|(wfeq0E & Firstun);
  end else begin
    assign WZeroE = weq0E;
  end 

  //////////////////////////
  // E/M Pipeline register
  //////////////////////////
 
  flopenr #(1) WZeroMReg(clk, reset, ~StallM, WZeroE, WZeroM);

  //////////////////////////
  // Memory Stage: Postprocessing
  //////////////////////////

  //  If the result is not exact, the sticky should be set
  assign DivSM = ~WZeroM & ~(SpecialCaseM & SqrtM); // ***unsure why SpecialCaseM has to be gated by SqrtM, but otherwise fails regression on divide

  // Determine if sticky bit is negative  // *** look for ways to optimize this
  assign Sum = WC + WS;
  assign W = $signed(Sum) >>> `LOGR;
  assign NegStickyM = W[`DIVb+3];
  assign DM = {4'b0001, D};

  // *** put conditionals on integer division hardware, move to its own module

  // Integer division: sign handling for div and rem
  always_comb 
    if (~AsM)
      if (NegStickyM) begin
        NormQuotM = FirstUM;
        NormRemM  = W + DM;
        PostIncM  = 0;
      end else begin
        NormQuotM = FirstU;
        NormRemM  = W;
        PostIncM  = 0;
      end
    else 
//      if (NegStickyM | weq0) begin // *** old code, replaced by the one below in the right stage and more comprehensive
      if (NegStickyM | WZeroM) begin
        NormQuotM = FirstU;
        NormRemM  = W;
        PostIncM  = 0;
      end else begin 
        NormQuotM = FirstU;
        NormRemM  = W - DM;
        PostIncM  = ~ALTBM;
      end

  // Integer division: Special cases
  always_comb
    if (BZeroM) begin
      IntQuotM = '1;
      IntRemM  = {{(`DIVb-`XLEN+4){1'b0}}, ForwardedSrcAM};
    end else if (ALTBM) begin
      IntQuotM = '0;
      IntRemM  = {{(`DIVb-`XLEN+4){1'b0}}, ForwardedSrcAM};
    end else if (WZeroM) begin
    // *** dh: 12/26: don't understand this logic and why weq0 inside WZero check.  Need a divide by 0 check here
/*      if (weq0) begin */
        IntQuotM = FirstU;
        IntRemM  = '0;
/*      end else begin
        IntQuotM = FirstUM;
        IntRemM  = '0;
      end */
    end else begin 
      IntQuotM = NormQuotM;
      IntRemM  = NormRemM;
    end 
  
  always_comb
    if (RemOpM) begin
      NormShiftM = (mM + (`DIVBLEN+1)'(`DIVa));
      PreResultM = IntRemM;
    end else begin
      NormShiftM = ((`DIVBLEN+1)'(`DIVb) - (nM * (`DIVBLEN+1)'(`LOGR)));
      if (BZeroM | (~ALTBM & OTFCSwapEM)) begin
        PreResultM = {3'b111, IntQuotM};
      end else begin
        PreResultM = {3'b000, IntQuotM};
      end
      //PreResultM = {IntQuotM[`DIVb], IntQuotM[`DIVb], IntQuotM[`DIVb], IntQuotM}; // Suspicious Sign Extender
    end
  

   // division takes the result from the next cycle, which is shifted to the left one more time so the square root also needs to be shifted
  
  assign PreFPIntDivResultM = $signed(PreResultM >>> NormShiftM) + {{(`DIVb+3){1'b0}}, (PostIncM & ~RemOpM)};
  assign FPIntDivResultM = PreFPIntDivResultM[`XLEN-1:0];
 
  assign PreQmM = NegStickyM ? FirstUM : FirstU; // Select U or U-1 depending on negative sticky bit
  assign QmM = SqrtM ? (PreQmM << 1) : PreQmM;
endmodule