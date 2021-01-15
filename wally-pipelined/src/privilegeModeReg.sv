///////////////////////////////////////////
// privilegeModeReg.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Track current privilege mode
//          See RISC-V Privileged Mode Specification 20190608 
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

`include "wally-macros.sv"

module privilegeModeReg #(parameter XLEN=32, MISA=0) (
  input  logic       clk, reset,
  input  logic       mretM, sretM, uretM, TrapM,
  input  logic [1:0] STATUS_MPP, 
  input  logic       STATUS_SPP,
  input  logic [XLEN-1:0] MEDELEG_REGW, MIDELEG_REGW, SEDELEG_REGW, SIDELEG_REGW, CauseM,
  output logic [1:0] NextPrivilegeModeM, PrivilegeModeW);

  logic md, sd;
  // get bits of DELEG registers based on CAUSE
  assign md = CauseM[XLEN-1] ? MIDELEG_REGW[CauseM[4:0]] : MEDELEG_REGW[CauseM[4:0]];
  assign sd = CauseM[XLEN-1] ? SIDELEG_REGW[CauseM[4:0]] : SEDELEG_REGW[CauseM[4:0]]; // depricated
  
  always_comb
    if      (reset) NextPrivilegeModeM = `M_MODE; // Privilege resets to 11 (Machine Mode)
    else if (mretM) NextPrivilegeModeM = STATUS_MPP;
    else if (sretM) NextPrivilegeModeM = {1'b0, STATUS_SPP};
    else if (uretM) NextPrivilegeModeM = `U_MODE;
    else if (TrapM) begin // Change privilege based on DELEG registers (see 3.1.8)
      if (PrivilegeModeW == `U_MODE)
        if (`N_SUPPORTED & `U_SUPPORTED & md & sd) NextPrivilegeModeM = `U_MODE;
        else if (`S_SUPPORTED & md)                NextPrivilegeModeM = `S_MODE;
        else                                       NextPrivilegeModeM = `M_MODE;
      else if (PrivilegeModeW == `S_MODE) 
        if (`S_SUPPORTED & md)                     NextPrivilegeModeM = `S_MODE;
        else                                       NextPrivilegeModeM = `M_MODE;
      else                                         NextPrivilegeModeM = `M_MODE;
    end else NextPrivilegeModeM = PrivilegeModeW; // stay at same level when there is no exception or return
  flop #(2) PrivlegeReg(clk, NextPrivilegeModeM, PrivilegeModeW);

endmodule
