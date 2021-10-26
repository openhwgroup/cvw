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

module csri #(parameter 
  // Machine CSRs
  MIE = 12'h304,
  MIP = 12'h344,
  SIE = 12'h104,
  SIP = 12'h144) (
    input  logic             clk, reset, 
    input  logic             StallW,
    input  logic             CSRMWriteM, CSRSWriteM,
    input  logic [11:0]      CSRAdrM,
    input  logic             ExtIntM, TimerIntM, SwIntM,
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
    IntInM[11] = ExtIntM;;                     // MEIP
    IntInM[9]  = ExtIntM &  MIDELEG_REGW[9];   // SEIP
    IntInM[7]  = TimerIntM;                    // MTIP
    IntInM[5]  = TimerIntM &  MIDELEG_REGW[5]; // STIP
    IntInM[3]  = SwIntM;                       // MSIP
    IntInM[1]  = SwIntM &  MIDELEG_REGW[1];    // SSIP
   end

  // Interrupt Write Enables
  assign WriteMIPM = CSRMWriteM && (CSRAdrM == MIP) && ~StallW;
  assign WriteMIEM = CSRMWriteM && (CSRAdrM == MIE) && ~StallW;
  assign WriteSIPM = CSRSWriteM && (CSRAdrM == SIP) && ~StallW;
  assign WriteSIEM = CSRSWriteM && (CSRAdrM == SIE) && ~StallW;

  // Interrupt Pending and Enable Registers
  // MEIP, MTIP, MSIP are read-only
  // SEIP, STIP, SSIP is writable in MIP if S mode exists
  // SSIP is writable in SIP if S mode exists
  generate
    if (`S_SUPPORTED) begin
      assign MIP_WRITE_MASK = 12'h222; // SEIP, STIP, SSIP are writable in MIP (20210108-draft 3.1.9)
      assign SIP_WRITE_MASK = 12'h002; // SSIP is writable in SIP (privileged 20210108-draft 4.1.3)
    end else begin
      assign MIP_WRITE_MASK = 12'h000;
      assign SIP_WRITE_MASK = 12'h000;
    end
    always @(posedge clk) //, posedge reset) begin // *** I strongly feel that IntInM should go directly to IP_REGW -- Ben 9/7/21
      if (reset)          IP_REGW_writeable <= 10'b0;
      else if (WriteMIPM) IP_REGW_writeable <= (CSRWriteValM[9:0] & MIP_WRITE_MASK[9:0]) | IntInM[9:0]; // MTIP unclearable
      else if (WriteSIPM) IP_REGW_writeable <= (CSRWriteValM[9:0] & SIP_WRITE_MASK[9:0]) | IntInM[9:0]; // MTIP unclearable
//      else if (WriteUIPM) IP_REGW = (CSRWriteValM & 12'hBBB) | (NextIPM & 12'h080); // MTIP unclearable
      else                IP_REGW_writeable <= IP_REGW_writeable | IntInM[9:0]; // *** check this turns off interrupts properly even when MIDELEG changes
    always @(posedge clk) //, posedge reset) begin
      if (reset)          IE_REGW <= 12'b0;
      else if (WriteMIEM) IE_REGW <= (CSRWriteValM[11:0] & 12'hAAA); // MIE controls M and S fields
      else if (WriteSIEM) IE_REGW <= (CSRWriteValM[11:0] & 12'h222) | (IE_REGW & 12'h888); // only S fields
//      else if (WriteUIEM) IE_REGW = (CSRWriteValM & 12'h111) | (IE_REGW & 12'hAAA); // only U field
  endgenerate

  // restricted views of registers
  generate
    always_comb begin
      // Add MEIP read-only signal
      IP_REGW = {IntInM[11],1'b0,IP_REGW_writeable};

      // Machine Mode
      MIP_REGW = IP_REGW;
      MIE_REGW = IE_REGW;

      // Supervisor mode
      if (`S_SUPPORTED) begin
        SIP_REGW = IP_REGW & MIDELEG_REGW[11:0] & 'h222; // only delegated interrupts visible
        SIE_REGW = IE_REGW & MIDELEG_REGW[11:0] & 'h222;
      end else begin
        SIP_REGW = 12'b0;
        SIE_REGW = 12'b0;
      end

      // User Modes iterrupts depricated
      /*if (`U_SUPPORTED & `N_SUPPORTED) begin
        UIP_REGW = IP_REGW & MIDELEG_REGW & SIDELEG_REGW & 'h111; // only delegated interrupts visible
        UIE_REGW = IE_REGW & MIDELEG_REGW & SIDELEG_REGW & 'h111; // only delegated interrupts visible
      end else begin
        UIP_REGW = 12'b0;
        UIE_REGW = 12'b0;
      end */
    end
  endgenerate
endmodule
