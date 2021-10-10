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

  /* verilator lint_off UNOPTFLAT */

module intdivrestoring (
  input  logic clk,
  input  logic reset,
  input  logic StallM, FlushM,
  input  logic DivSignedE, W64E,
  input  logic DivE,
  input  logic [`XLEN-1:0] SrcAE, SrcBE,
  output logic DivBusyE, 
  output logic [`XLEN-1:0] QuotM, RemM
 );

  logic [`XLEN-1:0] WE[`DIV_BITSPERCYCLE:0];
  logic [`XLEN-1:0] XQE[`DIV_BITSPERCYCLE:0];
  logic [`XLEN-1:0] DSavedE, XSavedE, XSavedM, DinE, XinE, DnE, DAbsBE, DAbsBM, XnE, XInitE, WM, XQM, WnM, XQnM;
  localparam STEPBITS = $clog2(`XLEN/`DIV_BITSPERCYCLE);
  logic [STEPBITS:0] step;
  logic Div0E, Div0M;
  logic DivStartE, SignXE, SignXM, SignDE, SignDM, NegWM, NegQM;
  logic BusyE, DivDoneM;

  logic [`XLEN-1:0] WNextE, XQNextE;
 
  // save inputs on the negative edge of the execute clock.  
  // This is unusual practice, but the inputs are not guaranteed to be stable due to some hazard and forwarding logic.
  // Saving the inputs is the most hardware-efficient way to fix the issue.
  //flopen #(`XLEN) xsavereg(~clk, DivStartE, SrcAE, XSavedE);
 // flopen #(`XLEN) dsavereg(~clk, DivStartE, SrcBE, DSavedE); 

  assign DivStartE = DivE & ~BusyE & ~DivDoneM; 
  assign DivBusyE = BusyE | DivStartE;

  // Handle sign extension for W-type instructions
  generate
    if (`XLEN == 64) begin // RV64 has W-type instructions
      mux2 #(`XLEN) xinmux(SrcAE, {SrcAE[31:0], 32'b0}, W64E, XinE);
      mux2 #(`XLEN) dinmux(SrcBE, {{32{SrcBE[31]&DivSignedE}}, SrcBE[31:0]}, W64E, DinE);
	end else begin // RV32 has no W-type instructions
      assign XinE = SrcAE;
      assign DinE = SrcBE;	    
    end   
  endgenerate 

  // Extract sign bits and check fo division by zero
  assign SignDE = DivSignedE & DinE[`XLEN-1]; 
  assign SignXE = DivSignedE & XinE[`XLEN-1];
  assign Div0E = (DinE == 0);

  // pipeline registers
  flopen #(1) Div0eMReg(clk, DivStartE, Div0E, Div0M);
  flopen #(1) SignDMReg(clk, DivStartE, SignDE, SignDM);
  flopen #(1) SignXMReg(clk, DivStartE, SignXE, SignXM);

  // Take absolute value for signed operations, and negate D to handle subtraction in divider stages
  neg #(`XLEN) negd(DinE, DnE);
  mux2 #(`XLEN) dabsmux(DnE, DinE, SignDE, DAbsBE);  // take absolute value for signed operations, and negate for subtraction setp
  neg #(`XLEN) negx(XinE, XnE);
  mux2 #(`XLEN) xabsmux(XinE, XnE, SignXE, XInitE);  // need original X as remainder if doing divide by 0

  // initialization multiplexers on first cycle of operation (one cycle after start is asserted)
  mux2 #(`XLEN) wmux(WE[`DIV_BITSPERCYCLE], {`XLEN{1'b0}}, DivStartE, WNextE);
  mux2 #(`XLEN) xmux(XQE[`DIV_BITSPERCYCLE], XInitE, DivStartE, XQNextE);

  // registers before division steps
  // *** maybe change this stuff to M stage
  flopen #(`XLEN) dabsreg(clk, DivStartE, DAbsBE, DAbsBM);
  flopen #(`XLEN) wreg(clk, BusyE | DivStartE, WNextE, WE[0]); // *** merge Busy and start without combinational loop
  flopen #(`XLEN) xreg(clk, BusyE | DivStartE, XQNextE, XQE[0]);
  flopen #(`XLEN) XSavedMReg(clk, DivStartE, SrcAE, XSavedM); 
  
  // one copy of divstep for each bit produced per cycle
  generate
      genvar i;
      for (i=0; i<`DIV_BITSPERCYCLE; i = i+1)
        intdivrestoringstep divstep(WE[i], XQE[i], DAbsBM, WE[i+1], XQE[i+1]);
  endgenerate

  assign WM = WE[0];
  assign XQM = XQE[0];

  // Output selection logic in Memory Stage
  // On final setp of signed operations, negate outputs as needed
  assign NegWM = SignXM; // Remainder should have same sign as X 
  assign NegQM = SignXM ^ SignDM; // Quotient should be negative if one operand is positive and the other is negative
  neg #(`XLEN) wneg(WM, WnM);
  neg #(`XLEN) qneg(XQM, XQnM);
  // Select appropriate output: normal, negated, or for divide by zero
  mux3 #(`XLEN) qmux(XQM, XQnM, {`XLEN{1'b1}}, {Div0M, NegQM}, QuotM); // Q taken from XQ register, negated if necessary, or all 1s when dividing by zero
  mux3 #(`XLEN) remmux(WM, WnM, XSavedM, {Div0M, NegWM}, RemM); // REM taken from W register, negated if necessary, or from X when dividing by zero

  // Divider FSM to sequence Busy, and Done
  always_ff @(posedge clk) 
    if (reset) begin
        BusyE = 0; DivDoneM = 0; step = 0; 
    end else if (DivStartE & ~StallM) begin 
        if (Div0E) DivDoneM = 1;
        else begin
            BusyE = 1; step = 0; 
        end
    end else if (BusyE & ~DivDoneM) begin // pause one cycle at beginning of signed operations for absolute value
        step = step + 1;
        if (step[STEPBITS] | (`XLEN==64) & W64E & step[STEPBITS-1]) begin // complete in half the time for W-type instructions
            BusyE = 0;
            DivDoneM = 1;
        end
    end else if (DivDoneM) begin
        DivDoneM = StallM;
    end 

endmodule 

/* verilator lint_on UNOPTFLAT */
