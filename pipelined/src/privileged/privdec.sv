///////////////////////////////////////////
// privdec.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Decode Privileged & related instructions 
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

module privdec (
  input  logic         clk, reset,
  input  logic         StallM,
  input  logic [31:20] InstrM,
  input  logic         PrivilegedM, IllegalIEUInstrFaultM, IllegalCSRAccessM, IllegalFPUInstrM, 
  input  logic [1:0]   PrivilegeModeW, 
  input  logic         STATUS_TSR, STATUS_TVM, STATUS_TW,
  output logic         IllegalInstrFaultM,
  output logic         EcallFaultM, BreakpointFaultM,
  output logic         sretM, mretM, wfiM, sfencevmaM);

  logic IllegalPrivilegedInstrM;
  logic WFITimeoutM;
  logic       StallMQ;
  logic       ebreakM, ecallM;

  ///////////////////////////////////////////
  // Decode privileged instructions
  ///////////////////////////////////////////
  assign sretM =      PrivilegedM & (InstrM[31:20] == 12'b000100000010) & `S_SUPPORTED & 
                      (PrivilegeModeW == `M_MODE | PrivilegeModeW == `S_MODE & ~STATUS_TSR); 
  assign mretM =      PrivilegedM & (InstrM[31:20] == 12'b001100000010) & (PrivilegeModeW == `M_MODE);
  assign ecallM =     PrivilegedM & (InstrM[31:20] == 12'b000000000000);
  assign ebreakM =    PrivilegedM & (InstrM[31:20] == 12'b000000000001);
  assign wfiM =       PrivilegedM & (InstrM[31:20] == 12'b000100000101);
  assign sfencevmaM = PrivilegedM & (InstrM[31:25] ==  7'b0001001) & 
                      (PrivilegeModeW == `M_MODE | (PrivilegeModeW == `S_MODE & ~STATUS_TVM)); 

  ///////////////////////////////////////////
  // WFI timeout Privileged Spec 3.1.6.5
  ///////////////////////////////////////////
  if (`U_SUPPORTED) begin:wfi
    logic [`WFI_TIMEOUT_BIT:0] WFICount, WFICountPlus1;
    assign WFICountPlus1 = WFICount + 1;
    floprc #(`WFI_TIMEOUT_BIT+1) wficountreg(clk, reset, ~wfiM, WFICountPlus1, WFICount);  // count while in WFI
    assign WFITimeoutM = ((STATUS_TW & PrivilegeModeW != `M_MODE) | (`S_SUPPORTED & PrivilegeModeW == `U_MODE)) & WFICount[`WFI_TIMEOUT_BIT]; 
  end else assign WFITimeoutM = 0;

  ///////////////////////////////////////////
  // Extract exceptions by name and handle them 
  ///////////////////////////////////////////
  assign BreakpointFaultM = ebreakM; // could have other causes from a debugger
  assign EcallFaultM = ecallM;

  ///////////////////////////////////////////
  // sfence.vma causes TLB flushes
  ///////////////////////////////////////////
  // sets ITLBFlush to pulse for one cycle of the sfence.vma instruction
  // In this instr we want to flush the tlb and then do a pagetable walk to update the itlb and continue the program.
  // But we're still in the stalled sfence instruction, so if itlbflushf == sfencevmaM, tlbflush would never drop and 
  // the tlbwrite would never take place after the pagetable walk. by adding in ~StallMQ, we are able to drop itlbflush 
  // after a cycle AND pulse it for another cycle on any further back-to-back sfences. 
//  flopr #(1) StallMReg(.clk, .reset, .d(StallM), .q(StallMQ));
//  assign ITLBFlushF = sfencevmaM & ~StallMQ;
//  assign DTLBFlushM = sfencevmaM;

  ///////////////////////////////////////////
  // Fault on illegal instructions
  ///////////////////////////////////////////
  assign IllegalPrivilegedInstrM = PrivilegedM & ~(sretM|mretM|ecallM|ebreakM|wfiM|sfencevmaM);
  assign IllegalInstrFaultM = (IllegalIEUInstrFaultM & IllegalFPUInstrM) | IllegalPrivilegedInstrM | IllegalCSRAccessM | 
                               WFITimeoutM; 
endmodule
