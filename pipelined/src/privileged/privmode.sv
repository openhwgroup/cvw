///////////////////////////////////////////
// privmode.sv
//
// Written: David_Harris@hmc.edu 12 May 2022
// Modified: 
//
// Purpose: Track privilege mode
//          See RISC-V Privileged Mode Specification 20190608 3.1.10-11
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

module privmode (
  input  logic             clk, reset,
  input  logic             StallW, TrapM, mretM, sretM,
  input  logic             DelegateM,
  input  logic [1:0]       STATUS_MPP,
  input  logic             STATUS_SPP,
  output logic [1:0]       NextPrivilegeModeM, PrivilegeModeW
); 
  
  if (`U_SUPPORTED) begin:privmode
    // PrivilegeMode FSM
    always_comb begin
      if (TrapM) begin // Change privilege based on DELEG registers (see 3.1.8)
        if (`S_SUPPORTED & DelegateM)
                          NextPrivilegeModeM = `S_MODE;
        else              NextPrivilegeModeM = `M_MODE;
      end else if (mretM) NextPrivilegeModeM = STATUS_MPP;
      else if (sretM)     NextPrivilegeModeM = {1'b0, STATUS_SPP};
      else                NextPrivilegeModeM = PrivilegeModeW;
    end

    flopenl #(2) privmodereg(clk, reset, ~StallW, NextPrivilegeModeM, `M_MODE, PrivilegeModeW);
  end else begin  // only machine mode supported
    assign NextPrivilegeModeM = `M_MODE;
    assign PrivilegeModeW = `M_MODE;
  end
endmodule