///////////////////////////////////////////
// privdec.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Decode Privileged & related instructions 
//          See RISC-V Privileged Mode Specification 20190608 3.1.10-11
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
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
