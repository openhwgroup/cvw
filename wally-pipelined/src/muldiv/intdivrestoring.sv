///////////////////////////////////////////
// intdivrestoring.sv
//
// Written: David_Harris@hmc.edu 12 September 2021
// Modified: 
//
// Purpose: Restoring integer division using a shift register and subtractor
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module intdivrestoring (
  input  logic clk,
  input  logic reset,
  input  logic StallM,
  input  logic signedDivide,
  input  logic start,
  input  logic [`XLEN-1:0] X, D,
  output logic busy, done,
  output logic [`XLEN-1:0] Q, REM
 );

  logic [`XLEN-1:0] W, W2, Win, Wshift, Wprime, Wn, Wnn, Wnext, XQ, XQin, XQshift, XQn, XQnn, XQnext, Dsaved, Din, Dabs, D2, Xabs, X2, Xsaved, Xinit, DAbsB, W1, XQ1;
  logic qi, qib; // curent quotient bit
  localparam STEPBITS = $clog2(`XLEN)-1;
  logic [STEPBITS:0] step;
  logic div0;
  logic negate, init, startd, SignX, SignD, NegW, NegQ;

  // Setup for signed division
  abs #(`XLEN) absd(D, Dabs);
  mux2 #(`XLEN) dabsmux(D, Dabs, signedDivide, D2);
  flopen #(`XLEN) dsavereg(clk, start, D2, Dsaved);
  mux2 #(`XLEN) dfirstmux(Dsaved, D, start, Din); 

  abs #(`XLEN) absx(X, Xabs);
  mux2 #(`XLEN) xabsmux(X, Xabs, signedDivide & ~div0, X2);  // need original X as remainder if doing divide by 0
  flopen #(`XLEN) xsavereg(clk, start, X2, Xsaved);
  mux2 #(`XLEN) xfirstmux(Xsaved, X, start, Xinit); 

  mux2 #(`XLEN) wmux(W, {`XLEN{1'b0}}, init, Win);
  mux2 #(`XLEN) xmux(XQ, Xinit, init, XQin);

  assign DAbsB = ~Din;

  intdivrestoringstep step1(Win, XQin, DAbsB, W1, XQ1);
  intdivrestoringstep step2(W1, XQ1, DAbsB, W2, XQshift);

  // conditionally negate outputs at end of signed operation
  // *** move into M stage
  neg #(`XLEN) wneg(W, Wn);
  mux2 #(`XLEN) wnextmux(W2, Wn, NegW, Wnext); //***
  neg #(`XLEN) qneg(XQ, XQn);
  mux2 #(`XLEN) qnextmux(XQshift, XQn, NegQ, XQnext);
  flopen #(`XLEN) wreg(clk, start | (busy & (~negate | NegW)), Wnext, W);
  flopen #(`XLEN) xreg(clk, start | (busy & (~negate | NegQ)), XQnext, XQ);

  // outputs
  assign div0 = (Din == 0);
  mux2 #(`XLEN) qmux(XQ, {`XLEN{1'b1}}, div0, Q); // Q taken from XQ register, or all 1s when dividing by zero
  mux2 #(`XLEN) remmux(W, Xsaved, div0, REM); // REM taken from W register, or from X when dividing by zero
 
  // busy logic
  always_ff @(posedge clk) 
    if (reset) begin
        busy = 0; done = 0; step = 0; negate = 0;
    end else if (start & ~StallM) begin 
        if (div0) done = 1;
        else begin
            busy = 1; step = 1;
        end
    end else if (busy & ~done & ~(startd & signedDivide)) begin // pause one cycle at beginning of signed operations for absolute value
        step = step + 1;
        if (step[STEPBITS]) begin // *** early terminate on division by 0
          if (signedDivide & ~negate) begin
            negate = 1;
          end else begin
            step = 0;
            busy = 0;
            negate = 0;
            done = 1;
          end
        end
    end else if (done) begin
        done = 0;
        busy = 0;
        negate = 0;
    end
 
  // initialize on the start cycle for unsigned operations, or one cycle later for signed operations (giving time for abs)
  flop #(1) initflop(clk, start, startd);
  mux2 #(1) initmux(start, startd, signedDivide, init);

  // save signs of original inputs
  flopen #(2) signflops(clk, start, {D[`XLEN-1], X[`XLEN-1]}, {SignD, SignX});
  // On final setp of signed operations, negate outputs as needed
  assign NegW = SignX & negate;
  assign NegQ = (SignX ^ SignD) & negate;

endmodule // muldiv


module intdivrestoringstep(
  input  logic [`XLEN-1:0] W, XQ, DAbsB,
  output logic [`XLEN-1:0] WOut, XQOut);

  logic [`XLEN-1:0] WShift, WPrime;
  logic qi, qib;
  
  assign {WShift, XQOut} = {W[`XLEN-2:0], XQ, qi};
  assign {qib, WPrime} = {1'b0, WShift} + {1'b1, DAbsB} + 1; // subtractor, carry out determines quotient bit ***replace with add
  assign qi = ~qib;
  mux2 #(`XLEN) wrestoremux(WShift, WPrime, qi, WOut);
endmodule

// *** clean up internal signals