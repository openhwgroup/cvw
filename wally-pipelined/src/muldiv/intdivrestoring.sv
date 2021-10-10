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

  logic [`XLEN-1:0] WM[`DIV_BITSPERCYCLE:0];
  logic [`XLEN-1:0] XQM[`DIV_BITSPERCYCLE:0];
  logic [`XLEN-1:0] DinE, XinE, DnE, DAbsBE, DAbsBM, XnE, XInitE, WnM, XQnM;
  localparam STEPBITS = $clog2(`XLEN/`DIV_BITSPERCYCLE);
  logic [STEPBITS:0] step;
  logic Div0E, Div0M;
  logic DivStartE, SignXE, SignXM, SignDE, SignDM, NegWM, NegQM;
  logic BusyE, DivDoneM;

  logic [`XLEN-1:0] WNextE, XQNextE;
 
  //////////////////////////////
  // Execute Stage: prepare for division calculation with control logic, W logic and absolute values, initialize W and XQ
  //////////////////////////////

  // Divider control signals
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

  // Take absolute value for signed operations, and negate D to handle subtraction in divider stages
  neg #(`XLEN) negd(DinE, DnE);
  mux2 #(`XLEN) dabsmux(DnE, DinE, SignDE, DAbsBE);  // take absolute value for signed operations, and negate for subtraction setp
  neg #(`XLEN) negx(XinE, XnE);
  mux3 #(`XLEN) xabsmux(XinE, XnE, SrcAE, {Div0E, SignXE}, XInitE);  // take absolute value for signed operations, or keep original value for divide by 0

  // initialization multiplexers on first cycle of operation
  mux2 #(`XLEN) wmux(WM[`DIV_BITSPERCYCLE], {`XLEN{1'b0}}, DivStartE, WNextE);
  mux2 #(`XLEN) xmux(XQM[`DIV_BITSPERCYCLE], XInitE, DivStartE, XQNextE);

  //////////////////////////////
  // Memory Stage: division iterations, output sign correction
  //////////////////////////////

  // registers before division steps
  // *** maybe change this stuff to M stage
  flopen #(`XLEN) wreg(clk, DivBusyE, WNextE, WM[0]); 
  flopen #(`XLEN) xreg(clk, DivBusyE, XQNextE, XQM[0]);
  flopen #(`XLEN) dabsreg(clk, DivStartE, DAbsBE, DAbsBM);
  flopen #(3) Div0eMReg(clk, DivStartE, {Div0E, SignDE, SignXE}, {Div0M, SignDM, SignXM});
  
  // one copy of divstep for each bit produced per cycle
  generate
      genvar i;
      for (i=0; i<`DIV_BITSPERCYCLE; i = i+1)
        intdivrestoringstep divstep(WM[i], XQM[i], DAbsBM, WM[i+1], XQM[i+1]);
  endgenerate

  // Output selection logic in Memory Stage
  // On final setp of signed operations, negate outputs as needed
  assign NegWM = SignXM; // Remainder should have same sign as X 
  assign NegQM = SignXM ^ SignDM; // Quotient should be negative if one operand is positive and the other is negative
  neg #(`XLEN) qneg(XQM[0], XQnM);
  neg #(`XLEN) wneg(WM[0], WnM);
  // Select appropriate output: normal, negated, or for divide by zero
  mux3 #(`XLEN) qmux(XQM[0], XQnM, {`XLEN{1'b1}}, {Div0M, NegQM}, QuotM); // Q taken from XQ register, negated if necessary, or all 1s when dividing by zero
  mux3 #(`XLEN) remmux(WM[0], WnM, XQM[0], {Div0M, NegWM}, RemM); // REM taken from W register, negated if necessary, or from X when dividing by zero

  //////////////////////////////
  // Divider FSM to sequence Busy and Done
  //////////////////////////////

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

  //counter #(STEPBITS+1) stepcnt(clk, cntrst, cnten, step);

endmodule 

/* verilator lint_on UNOPTFLAT */
