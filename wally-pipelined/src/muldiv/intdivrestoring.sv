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
  input  logic StallM, FlushM,
  input  logic SignedDivideE,
  input  logic StartDivideE,
  input  logic [`XLEN-1:0] X, D,
  output logic BusyE, done,
  output logic [`XLEN-1:0] Q, REM
 );

  logic [`XLEN-1:0] W, W2, Win, Wshift, Wprime, Wn, Wnn, Wnext, XQ, XQin, XQshift, XQn, XQnn, XQnext, Dsaved, Din, Dabs, D2, Dn, Xn, Xabs, X2, Xsaved, Xinit, DAbsB, W1, XQ1;
  logic qi, qib; // curent quotient bit
  localparam STEPBITS = $clog2(`XLEN)-1;
  logic [STEPBITS:0] step;
  logic div0;
  logic init, startd, SignX, SignD, NegW, NegQ;
  logic SignedDivideM;
  // *** add pipe stages to everything

  // save inputs on the negative edge of the execute clock.  
  // This is unusual practice, but the inputs are not guaranteed to be stable due to some hazard and forwarding logic.
  // Saving the inputs is the most hardware-efficient way to fix the issue.
  flopen #(`XLEN) dsavereg(~clk, StartDivideE, D, Dsaved); 
  flopen #(`XLEN) xsavereg(~clk, StartDivideE, X, Xsaved);
  assign SignD = Dsaved[`XLEN-1]; // *** do some of these need pipelining for consecutive divides?
  assign SignX = Xsaved[`XLEN-1];
  assign div0 = (Dsaved == 0); // *** eventually replace with just the negedge saved D

  // Setup for signed division
  neg #(`XLEN) negd(Dsaved, Dn);
  mux2 #(`XLEN) dabsmux(Dsaved, Dn, SignedDivideE & SignD, Din);  // take absolute value for signed operations
  assign DAbsB = ~Din;
//  mux2 #(`XLEN) dfirstmux(Dsaved, D, StartDivideE, Din); 

  neg #(`XLEN) negx(Xsaved, Xn);
  mux2 #(`XLEN) xabsmux(Xsaved, Xn, SignedDivideE & SignX, Xinit);  // need original X as remainder if doing divide by 0
//  mux2 #(`XLEN) xfirstmux(Xsaved, X, StartDivideE, Xinit); 

  mux2 #(`XLEN) wmux(W, {`XLEN{1'b0}}, init, Win);
  mux2 #(`XLEN) xmux(XQ, Xinit, init, XQin);


  // *** parameterize steps per cycle
  intdivrestoringstep step1(Win, XQin, DAbsB, W1, XQ1);
  intdivrestoringstep step2(W1, XQ1, DAbsB, Wnext, XQnext);

  flopen #(`XLEN) wreg(clk, StartDivideE | BusyE, Wnext, W); // *** could become just busy once start moves to its own cycle
  flopen #(`XLEN) xreg(clk, StartDivideE | BusyE, XQnext, XQ);

  // outputs
  // On final setp of signed operations, negate outputs as needed
  //flopen #(2) signflops(clk, StartDivideE, {D[`XLEN-1], X[`XLEN-1]}, {SignD, SignX}); // *** shouldn't be necessary when capturing inputs properly

  assign NegW = SignedDivideM & SignX; 
  assign NegQ = SignedDivideM & (SignX ^ SignD); 
  neg #(`XLEN) wneg(W, Wn);
  neg #(`XLEN) qneg(XQ, XQn);
  mux3 #(`XLEN) qmux(XQ, XQn, {`XLEN{1'b1}}, {div0, NegQ}, Q); // Q taken from XQ register, negated if necessary, or all 1s when dividing by zero
  mux3 #(`XLEN) remmux(W, Wn, Xsaved, {div0, NegW}, REM); // REM taken from W register, negated if necessary, or from X when dividing by zero
 
  // busy logic
  always_ff @(posedge clk) 
    if (reset) begin
        BusyE = 0; done = 0; step = 0; 
    end else if (StartDivideE & ~StallM) begin 
        if (div0) done = 1;
        else begin
            BusyE = 1; step = 0;
        end
    end else if (BusyE & ~done) begin // pause one cycle at beginning of signed operations for absolute value
        step = step + 1;
        if (step[STEPBITS]) begin 
            step = 0;
            BusyE = 0;
            done = 1;
        end
    end else if (done) begin
        done = 0;
        BusyE = 0;
    end
    assign init = (step == 0);
 
  // initialize on the start cycle for unsigned operations, or one cycle later for signed operations (giving time for abs)
//  flop #(1) initflop(clk, StartDivideE, startd);
//  mux2 #(1) initmux(StartDivideE, startd, SignedDivideE, init);

  // save signs of original inputs
	flopenrc #(1) SignedDivideMReg(clk, reset, FlushM, ~StallM, SignedDivideE, SignedDivideM);

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