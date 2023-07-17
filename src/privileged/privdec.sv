///////////////////////////////////////////
// privdec.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Decode Privileged & related instructions 
//          See RISC-V Privileged Mode Specification 20190608 3.1.10-11
// 
// Documentation: RISC-V System on Chip Design Chapter 5
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

module privdec import cvw::*;  #(parameter cvw_t P) (
  input  logic         clk, reset,
  input  logic         StallM,
  input  logic [31:15] InstrM,                              // privileged instruction function field
  input  logic         PrivilegedM,                         // is this a privileged instruction (from IEU controller)
  input  logic         IllegalIEUFPUInstrM,                 // Not a legal IEU instruction
  input  logic         IllegalCSRAccessM,                   // Not a legal CSR access
  input  logic [1:0]   PrivilegeModeW,                      // current privilege level
  input  logic         STATUS_TSR, STATUS_TVM, STATUS_TW,   // status bits
  output logic         IllegalInstrFaultM,                  // Illegal instruction
  output logic         EcallFaultM, BreakpointFaultM,       // Ecall or breakpoint; must retire, so don't flush it when the trap occurs
  output logic         sretM, mretM,                        // return instructions
  output logic         wfiM, sfencevmaM                     // wfi / sfence.vma / sinval.vma instructions
);

  logic                rs1zeroM;                            // rs1 field = 0
  logic                IllegalPrivilegedInstrM;             // privileged instruction isn't a legal one or in legal mode
  logic                WFITimeoutM;                         // WFI reaches timeout threshold
  logic                ebreakM, ecallM;                     // ebreak / ecall instructions
  logic                sinvalvmaM;                          // sinval.vma
  logic                sfencewinvalM, sfenceinvalirM;       // sfence.w.inval, sfence.inval.ir
  logic                invalM;                              // any of the svinval instructions

  ///////////////////////////////////////////
  // Decode privileged instructions
  ///////////////////////////////////////////

  assign rs1zeroM =    InstrM[19:15] == 5'b0;
  
  // svinval instructions
  // any svinval instruction is treated as sfence.vma on Wally
  assign sinvalvmaM =     (InstrM[31:25] == 7'b0001001);
  assign sfencewinvalM  = (InstrM[31:20] == 12'b000110000000) & rs1zeroM;
  assign sfenceinvalirM = (InstrM[31:20] == 12'b000110000001) & rs1zeroM;
  assign invalM =         P.SVINVAL_SUPPORTED & (sinvalvmaM | sfencewinvalM | sfenceinvalirM); 

  assign sretM =      PrivilegedM & (InstrM[31:20] == 12'b000100000010) & rs1zeroM & P.S_SUPPORTED & 
                      (PrivilegeModeW == P.M_MODE | PrivilegeModeW == P.S_MODE & ~STATUS_TSR); 
  assign mretM =      PrivilegedM & (InstrM[31:20] == 12'b001100000010) & rs1zeroM & (PrivilegeModeW == P.M_MODE);
  assign ecallM =     PrivilegedM & (InstrM[31:20] == 12'b000000000000) & rs1zeroM;
  assign ebreakM =    PrivilegedM & (InstrM[31:20] == 12'b000000000001) & rs1zeroM;
  assign wfiM =       PrivilegedM & (InstrM[31:20] == 12'b000100000101) & rs1zeroM;
  assign sfencevmaM = PrivilegedM & (InstrM[31:25] ==  7'b0001001 | invalM) & 
                      (PrivilegeModeW == P.M_MODE | (PrivilegeModeW == P.S_MODE & ~STATUS_TVM)); 

  ///////////////////////////////////////////
  // WFI timeout Privileged Spec 3.1.6.5
  ///////////////////////////////////////////

  if (P.U_SUPPORTED) begin:wfi
    logic [P.WFI_TIMEOUT_BIT:0] WFICount, WFICountPlus1;
    assign WFICountPlus1 = WFICount + 1;
    floprc #(P.WFI_TIMEOUT_BIT+1) wficountreg(clk, reset, ~wfiM, WFICountPlus1, WFICount);  // count while in WFI
  // coverage off -item e 1 -fecexprrow 1
  // WFI Timout trap will not occur when STATUS_TW is low while in supervisor mode, so the system gets stuck waiting for an interrupt and triggers a watchdog timeout.
    assign WFITimeoutM = ((STATUS_TW & PrivilegeModeW != P.M_MODE) | (P.S_SUPPORTED & PrivilegeModeW == P.U_MODE)) & WFICount[P.WFI_TIMEOUT_BIT]; 
  // coverage on
  end else assign WFITimeoutM = 0;

  ///////////////////////////////////////////
  // Extract exceptions by name and handle them 
  ///////////////////////////////////////////

  assign BreakpointFaultM = ebreakM; // could have other causes from a debugger
  assign EcallFaultM = ecallM;

  ///////////////////////////////////////////
  // Fault on illegal instructions
  ///////////////////////////////////////////
  
  assign IllegalPrivilegedInstrM = PrivilegedM & ~(sretM|mretM|ecallM|ebreakM|wfiM|sfencevmaM);
  assign IllegalInstrFaultM = IllegalIEUFPUInstrM | IllegalPrivilegedInstrM | IllegalCSRAccessM | 
                              WFITimeoutM; 
endmodule
