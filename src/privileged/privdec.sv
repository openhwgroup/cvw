///////////////////////////////////////////
// privdec.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified:
//
// Purpose: Decode Privileged & related instructions
//          See RISC-V Privileged Mode Specification 20190608 3.1.10-11
//
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
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
  input  logic         StallW, FlushW,
  input  logic [31:7 ] InstrM,                              // privileged instruction function field
  input  logic         PrivilegedM,                         // is this a privileged instruction (from IEU controller)
  input  logic         IllegalIEUFPUInstrM,                 // Not a legal IEU instruction
  input  logic         IllegalCSRAccessM,                   // Not a legal CSR access
  input  logic [1:0]   PrivilegeModeW,                      // current privilege level
  input  logic         VirtModeW,                           // current V
  input  logic         STATUS_TSR, STATUS_TVM, STATUS_TW,   // status bits (HS)
  input  logic         HSTATUS_VTSR, HSTATUS_VTVM, HSTATUS_VTW, // status bits (VS)
  output logic         IllegalInstrFaultM,                  // Illegal instruction
  output logic         VirtualInstrFaultM,                  // Virtual instruction exception
  output logic         EcallFaultM, BreakpointFaultM,       // Ecall or breakpoint; must retire, so don't flush it when the trap occurs
  output logic         sretM, mretM, RetM,                  // return instructions
  output logic         wfiM, wfiW, sfencevmaM               // wfi / sfence.vma / sinval.vma instructions
);

  logic                rs1zeroM, rdzeroM;                   // rs1 / rd field = 0
  logic                IllegalPrivilegedInstrM;             // privileged instruction isn't a legal one or in legal mode
  logic                WFITimeoutM;                         // WFI reaches timeout threshold
  logic                ebreakM, ecallM;                     // ebreak / ecall instructions
  logic                sinvalvmaM;                          // sinval.vma
  logic                presfencevmaM;                       // sfence.vma before checking privilege mode
  logic                sfencewinvalM, sfenceinvalirM;       // sfence.w.inval, sfence.inval.ir
  logic                hfencevvmaM, hfencegvmaM;            // hfence.vvma, hfence.gvma
  logic                vmaM;                                // sfence.vma or sinval.vma
  logic                fenceinvalM;                         // sfence.w.inval or sfence.inval.ir
  logic                TSRM, TVMM, TWM;

  ///////////////////////////////////////////
  // Decode privileged instructions
  ///////////////////////////////////////////

  assign rs1zeroM =    InstrM[19:15] == 5'b0;
  assign rdzeroM  =    InstrM[11:7]  == 5'b0;

  // svinval instructions
  // any svinval instruction is treated as sfence.vma on Wally
  assign sinvalvmaM     = (InstrM[31:25] ==  7'b0001011)                 & rdzeroM;
  assign sfencewinvalM  = (InstrM[31:20] == 12'b000110000000) & rs1zeroM & rdzeroM;
  assign sfenceinvalirM = (InstrM[31:20] == 12'b000110000001) & rs1zeroM & rdzeroM;
  assign presfencevmaM  = (InstrM[31:25] ==  7'b0001001)                 & rdzeroM;
  assign hfencevvmaM    = (InstrM[31:25] ==  7'b0010001)                 & rdzeroM; // hfence.vvma
  assign hfencegvmaM    = (InstrM[31:25] ==  7'b0110001)                 & rdzeroM; // hfence.gvma
  assign vmaM           =  presfencevmaM | (sinvalvmaM & P.SVINVAL_SUPPORTED);      // sfence.vma or sinval.vma
  assign fenceinvalM    = (sfencewinvalM | sfenceinvalirM) & P.SVINVAL_SUPPORTED;   // sfence.w.inval or sfence.inval.ir

  // In VS-mode, use hstatus.V* bits instead of mstatus.T* bits.
  assign TSRM = VirtModeW ? HSTATUS_VTSR : STATUS_TSR;
  assign TVMM = VirtModeW ? HSTATUS_VTVM : STATUS_TVM;
  assign TWM  = VirtModeW ? HSTATUS_VTW : STATUS_TW;

  assign sretM =      PrivilegedM & (InstrM[31:20] == 12'b000100000010) & rs1zeroM & P.S_SUPPORTED &
                      (PrivilegeModeW == P.M_MODE | PrivilegeModeW == P.S_MODE & ~TSRM);
  assign mretM =      PrivilegedM & (InstrM[31:20] == 12'b001100000010) & rs1zeroM & (PrivilegeModeW == P.M_MODE);
  assign RetM =       sretM | mretM;
  assign ecallM =     PrivilegedM & (InstrM[31:20] == 12'b000000000000) & rs1zeroM;
  assign ebreakM =    PrivilegedM & (InstrM[31:20] == 12'b000000000001) & rs1zeroM;
  assign wfiM =       PrivilegedM & (InstrM[31:20] == 12'b000100000101) & rs1zeroM;

  // all of sinval.vma, sfence.w.inval, sfence.inval.ir are treated as sfence.vma
  assign sfencevmaM = PrivilegedM & P.VIRTMEM_SUPPORTED &
                      ((PrivilegeModeW == P.M_MODE & (vmaM | fenceinvalM)) |
                       (PrivilegeModeW == P.S_MODE & (vmaM & ~TVMM  | fenceinvalM)) |
                       (PrivilegeModeW == P.S_MODE & ~VirtModeW & (hfencevvmaM | hfencegvmaM))); // hfence treated as sfence.vma in HS

  ///////////////////////////////////////////
  // WFI timeout Privileged Spec 3.1.6.5
  ///////////////////////////////////////////

  if (P.U_SUPPORTED) begin:wfi
    logic [P.WFI_TIMEOUT_BIT:0] WFICount, WFICountPlus1;
    assign WFICountPlus1 = wfiM ? WFICount + 1 : '0; // restart counting on WFI
    flopr #(P.WFI_TIMEOUT_BIT+1) wficountreg(clk, reset, WFICountPlus1, WFICount);  // count while in WFI
  // coverage off -item e 1 -fecexprrow 1
  // WFI Timeout trap will not occur when STATUS_TW is low while in supervisor mode, so the system gets stuck waiting for an interrupt and triggers a watchdog timeout.
    assign WFITimeoutM = ((TWM & PrivilegeModeW != P.M_MODE) | (P.S_SUPPORTED & PrivilegeModeW == P.U_MODE)) & WFICount[P.WFI_TIMEOUT_BIT];
  // coverage on
  end else assign WFITimeoutM = 1'b0;

  flopenrc #(1) wfiWReg(clk, reset, FlushW, ~StallW, wfiM, wfiW);

  ///////////////////////////////////////////
  // Extract exceptions by name and handle them
  ///////////////////////////////////////////

  assign BreakpointFaultM = ebreakM; // could have other causes from a debugger
  assign EcallFaultM = ecallM;

  ///////////////////////////////////////////
  // Fault on illegal instructions
  ///////////////////////////////////////////

  assign IllegalPrivilegedInstrM = PrivilegedM & ~(sretM|mretM|ecallM|ebreakM|wfiM|sfencevmaM);

  // Virtual Instruction Exception Detection
  // 1. hfence in VS-mode (VirtModeW & PrivilegedM & (hfencevvmaM | hfencegvmaM))
  // 2. sret in VS-mode when VTSR=1 (VirtModeW & sret & HSTATUS_VTSR) - wait, sretM is suppressed by VTSR logic?
  //    sretM logic: ... & (PrivilegeModeW == P.M_MODE | PrivilegeModeW == P.S_MODE & ~TSRM);
  //    If TSRM (which is VTSR in VS-mode) is 1, sretM is 0.
  //    So we detect the attempt: PrivilegedM & opcode==sret & VirtModeW & HSTATUS_VTSR
  // 3. satp access in VS-mode when VTVM=1
  //    IllegalCSRAccessM will be high. We need to distinguish.
  //    Check opcode? CSRRW/RS/RC?
  //    If IllegalCSRAccessM & VirtModeW & HSTATUS_VTVM & (CSRAdr == SATP) -> Virtual Instr.

  // Re-deriving raw instruction decodes for fault detection since sretM/sfencevmaM might be gated
  logic is_sret, is_hfence;
  assign is_sret = (InstrM[31:20] == 12'b000100000010) & rs1zeroM;
  assign is_hfence = (InstrM[31:25] == 7'b0010001 | InstrM[31:25] == 7'b0110001) & rdzeroM; // hfence.vvma | hfence.gvma

  logic VSTSRFault, VTVMFault, HFenceFault;
  assign VSTSRFault = PrivilegedM & is_sret & VirtModeW & HSTATUS_VTSR;
  assign HFenceFault = PrivilegedM & is_hfence & VirtModeW;
  // Note: VTVM fault is tricky because 'satp' access isn't explicitly decoded here, it's in csr.sv.
  // However, csr.sv reports IllegalCSRAccessM.
  // We can rely on IllegalCSRAccessM being high, and verify if it matches VTVM condition.
  // BUT privdec doesn't know the CSR address.
  // We will output VirtualInstrFaultM primarily for the instruction faults we can see.
  // For VTVM, csr.sv logic handles the illegality, but trap.sv needs to know the Cause.
  // Ideally, csr.sv should report 'VirtualInstructionFault' separate from 'IllegalAccess'.
  // Given constraints, we will handle HFence and SRET here.
  // For SATP/VTVM: If we can't change csr.sv interface easily to output specific fault type,
  // we might have to accept Illegal Instruction for SATP/VTVM or move decoding here.
  // Moving decoding: 'satp' is 0x180.
  logic is_satp_access;
  assign is_satp_access = (InstrM[31:20] == 12'h180);
  assign VTVMFault = PrivilegedM & is_satp_access & VirtModeW & HSTATUS_VTVM;

  assign VirtualInstrFaultM = VSTSRFault | HFenceFault | VTVMFault;

  // Prevent double-reporting. If it's Virtual, it's not Illegal.
  assign IllegalInstrFaultM = (IllegalIEUFPUInstrM | IllegalPrivilegedInstrM | IllegalCSRAccessM |
                               WFITimeoutM) & ~VirtualInstrFaultM;
endmodule
