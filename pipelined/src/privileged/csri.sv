///////////////////////////////////////////
// csri.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Interrupt Control & Status Registers (IP, EI)
//          See RISC-V Privileged Mode Specification 20190608 & 20210108 draft
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

module csri #(parameter 
  // Machine CSRs
  MIE = 12'h304,
  MIP = 12'h344,
  SIE = 12'h104,
  SIP = 12'h144) (
    input  logic             clk, reset, 
    input  logic             InstrValidNotFlushedM, StallW,
    input  logic             CSRMWriteM, CSRSWriteM,
    input  logic [11:0]      CSRAdrM,
    input  logic             ExtIntM, ExtIntS, TimerIntM, SwIntM,
    input  logic [`XLEN-1:0]      MIDELEG_REGW,
    output logic [11:0]      MIP_REGW, MIE_REGW, SIP_REGW, SIE_REGW,
    input  logic [`XLEN-1:0] CSRWriteValM
  );

  logic [9:0]      IP_REGW_writeable;
  logic [11:0]     IntInM, IP_REGW, IE_REGW;
  logic [11:0]     MIP_WRITE_MASK, SIP_WRITE_MASK;
  logic            WriteMIPM, WriteMIEM, WriteSIPM, WriteSIEM;

  // Determine which interrupts need to be set
  // assumes no N-mode user interrupts

  always_comb begin
    IntInM     = 0; 
    IntInM[11] = ExtIntM;                               // MEIP
    IntInM[9]  = ExtIntS | (ExtIntM & MIDELEG_REGW[9]); // SEIP
    IntInM[7]  = TimerIntM;                             // MTIP
    IntInM[5]  = TimerIntM &  MIDELEG_REGW[5];          // STIP
    IntInM[3]  = SwIntM;                                // MSIP
    IntInM[1]  = SwIntM &  MIDELEG_REGW[1];             // SSIP
   end

  // Interrupt Write Enables
  assign WriteMIPM = CSRMWriteM & (CSRAdrM == MIP) & InstrValidNotFlushedM;
  assign WriteMIEM = CSRMWriteM & (CSRAdrM == MIE) & InstrValidNotFlushedM;
  assign WriteSIPM = CSRSWriteM & (CSRAdrM == SIP) & InstrValidNotFlushedM;
  assign WriteSIEM = CSRSWriteM & (CSRAdrM == SIE) & InstrValidNotFlushedM;

// Interrupt Pending and Enable Registers
// MEIP, MTIP, MSIP are read-only
// SEIP, STIP, SSIP is writable in MIP if S mode exists
// SSIP is writable in SIP if S mode exists
  if (`S_SUPPORTED) begin:mask
    assign MIP_WRITE_MASK = 12'h222; // SEIP, STIP, SSIP are writable in MIP (20210108-draft 3.1.9)
    assign SIP_WRITE_MASK = 12'h002; // SSIP is writable in SIP (privileged 20210108-draft 4.1.3)
  end else begin:mask
    assign MIP_WRITE_MASK = 12'h000;
    assign SIP_WRITE_MASK = 12'h000;
  end
  always @(posedge clk)
    if (reset)          IP_REGW_writeable <= 10'b0;
    else if (WriteMIPM) IP_REGW_writeable <= (CSRWriteValM[9:0] & MIP_WRITE_MASK[9:0]) | {1'b0,IntInM[8:0]}; // MTIP unclearable
    else if (WriteSIPM) IP_REGW_writeable <= (CSRWriteValM[9:0] & SIP_WRITE_MASK[9:0]) | {1'b0,IntInM[8:0]}; // MTIP unclearable
    else                IP_REGW_writeable <= IP_REGW_writeable | {1'b0, IntInM[8:0]}; // *** check this turns off interrupts properly even when MIDELEG changes
  always @(posedge clk)
    if (reset)          IE_REGW <= 12'b0;
    else if (WriteMIEM) IE_REGW <= (CSRWriteValM[11:0] & 12'hAAA); // MIE controls M and S fields
    else if (WriteSIEM) IE_REGW <= (CSRWriteValM[11:0] & 12'h222) | (IE_REGW & 12'h888); // only S fields

  // restricted views of registers
  // Add ExtIntM read-only signal
  assign IP_REGW = {ExtIntM,1'b0,ExtIntS,9'b0} | {2'b0,IP_REGW_writeable};

    // Machine Mode
  assign MIP_REGW = IP_REGW;
  assign MIE_REGW = IE_REGW;

  // Supervisor mode
  if (`S_SUPPORTED) begin
    assign SIP_REGW = IP_REGW & MIDELEG_REGW[11:0] & 'h222; // only delegated interrupts visible
    assign SIE_REGW = IE_REGW & MIDELEG_REGW[11:0] & 'h222;
  end else begin
    assign SIP_REGW = 12'b0;
    assign SIE_REGW = 12'b0;
  end

endmodule
