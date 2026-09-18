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
  input  logic         STATUS_TSR, STATUS_TVM, STATUS_TW,   // status bits
  input  logic         TrapM,                               // Trap is occurring
  input  logic         ReservationValidW,                   // a reservation is held; Zawrs wrs only waits while this is set
  output logic         IllegalInstrFaultM,                  // Illegal instruction
  output logic         EcallFaultM, BreakpointFaultM,       // Ecall or breakpoint; must retire, so don't flush it when the trap occurs
  output logic         sretM, mretM, RetM,                  // return instructions
  output logic         wfiM, wfiW, sfencevmaM,              // wfi or Zawrs wrs / sfence.vma / sinval.vma instructions
  output logic         sfencevmaAllM                        // sfence.vma with rs2=x0: flush all TLB entries including global
);

  logic                rs1zeroM, rdzeroM;                   // rs1 / rd field = 0
  logic                IllegalPrivilegedInstrM;             // privileged instruction isn't a legal one or in legal mode
  logic                wfiInstrM;                           // wfi instruction
  logic                wrsntoM, wrsstoM, wrsM;              // Zawrs wrs.nto / wrs.sto instructions
  logic                wrsWaitM;                            // wrs is waiting: reservation still valid and not yet timed out
  logic                WaitTimeoutM;                        // wfi or wrs has waited long enough to reach the timeout threshold
  logic                WFITimeoutM;                         // WFI reaches timeout threshold
  logic                WRSTimeoutM;                         // wrs.nto reaches timeout threshold with mstatus.TW set
  logic                ebreakM, ecallM;                     // ebreak / ecall instructions
  logic                sinvalvmaM;                          // sinval.vma
  logic                presfencevmaM;                       // sfence.vma before checking privilege mode
  logic                sfencewinvalM, sfenceinvalirM;       // sfence.w.inval, sfence.inval.ir
  logic                vmaM;                                // sfence.vma or sinval.vma
  logic                fenceinvalM;                         // sfence.w.inval or sfence.inval.ir

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
  assign vmaM           =  presfencevmaM | (sinvalvmaM & P.SVINVAL_SUPPORTED);      // sfence.vma or sinval.vma
  assign fenceinvalM    = (sfencewinvalM | sfenceinvalirM) & P.SVINVAL_SUPPORTED;   // sfence.w.inval or sfence.inval.ir

  assign sretM =      PrivilegedM & (InstrM[31:20] == 12'b000100000010) & rs1zeroM & P.S_SUPPORTED &
                      (PrivilegeModeW == P.M_MODE | PrivilegeModeW == P.S_MODE & ~STATUS_TSR);
  assign mretM =      PrivilegedM & (InstrM[31:20] == 12'b001100000010) & rs1zeroM & (PrivilegeModeW == P.M_MODE);
  assign RetM =       sretM | mretM;
  assign ecallM =     PrivilegedM & (InstrM[31:20] == 12'b000000000000) & rs1zeroM;
  assign ebreakM =    PrivilegedM & (InstrM[31:20] == 12'b000000000001) & rs1zeroM;
  assign wfiInstrM =  PrivilegedM & (InstrM[31:20] == 12'b000100000101) & rs1zeroM;
  // Zawrs: with a single hart only an interrupt or the timeout ends the wait, so wrs shares the wfi stall path but completes when it times out
  assign wrsntoM =    P.ZAWRS_SUPPORTED & PrivilegedM & (InstrM[31:20] == 12'b000000001101) & rs1zeroM;
  assign wrsstoM =    P.ZAWRS_SUPPORTED & PrivilegedM & (InstrM[31:20] == 12'b000000011101) & rs1zeroM;
  assign wrsM =       wrsntoM | wrsstoM;
  // wrs may only wait while the reservation set is valid.  ReservationValidW is the committed
  // reservation: the lr that set it is in W when the wrs reaches M, and it holds during the wait
  // because a wrs in M is not a memory operation and a wait stall does not disable its flop.
  assign wrsWaitM =   wrsM & ReservationValidW & ~WaitTimeoutM;
  assign wfiM =       wfiInstrM | wrsWaitM;

  // all of sinval.vma, sfence.w.inval, sfence.inval.ir are treated as sfence.vma
  assign sfencevmaM = PrivilegedM & P.VIRTMEM_SUPPORTED &
                      ((PrivilegeModeW == P.M_MODE & (vmaM | fenceinvalM)) |
                       (PrivilegeModeW == P.S_MODE & (vmaM & ~STATUS_TVM  | fenceinvalM))); // sfence.w.inval & sfence.inval.ir not affected by TVM
  // rs2 (InstrM[24:20]) = x0 means flush all ASIDs including global mappings; rs2 != x0 is ASID-specific
  // and must preserve global (G=1) entries (RISC-V Privileged spec sfence.vma semantics).
  assign sfencevmaAllM = sfencevmaM & ~|InstrM[24:20];

  ///////////////////////////////////////////
  // WFI timeout Privileged Spec 3.1.6.5; wrs timeout Zawrs
  ///////////////////////////////////////////

  if (P.U_SUPPORTED | P.ZAWRS_SUPPORTED) begin : wfi
    logic [P.WAIT_TIMEOUT_BIT:0] WFICount, WFICountPlus1;
    logic                        WFICountEn, WFICountRst;
    // Clear counter when reset, when trap is taken, or when no wfi or wrs is waiting
    assign WFICountRst = reset | TrapM | ~(wfiInstrM | wrsM);
    // Stop incrementing the counter once reach the timeout limit
    assign WFICountEn = ~WaitTimeoutM;
    assign WFICountPlus1 = WFICount + 1; // Count while wfi or wrs waits
    flopenr #(P.WAIT_TIMEOUT_BIT+1) wficountreg(clk, WFICountRst, WFICountEn, WFICountPlus1, WFICount);
    // One counter, but each waiting instruction taps its own timeout threshold.  With Zawrs
    // disabled the wrs terms are constant zero and this collapses to the wfi bit.
    assign WaitTimeoutM = wrsntoM ? WFICount[P.WRSNTO_TIMEOUT_BIT] :
                          wrsstoM ? WFICount[P.WRSSTO_TIMEOUT_BIT] :
                                    WFICount[P.WFI_TIMEOUT_BIT];
  end else assign WaitTimeoutM = 1'b0;

  // coverage off -item e 1 -fecexprrow 1
  // WFI Timeout trap will not occur when STATUS_TW is low while in supervisor mode, so the system gets stuck waiting for an interrupt and triggers a watchdog timeout.
  assign WFITimeoutM = ((STATUS_TW & PrivilegeModeW != P.M_MODE) | (P.S_SUPPORTED & PrivilegeModeW == P.U_MODE)) & WaitTimeoutM & wfiInstrM;
  // coverage on
  // wrs.nto traps below M mode when mstatus.TW is set.  Unlike wfi it does not trap in U mode when
  // TW is clear, and wrs.sto never traps; both simply complete when the timeout expires.
  assign WRSTimeoutM = wrsntoM & WaitTimeoutM & STATUS_TW & (PrivilegeModeW != P.M_MODE);

  flopenrc #(1) wfiWReg(clk, reset, FlushW, ~StallW, wfiM, wfiW);

  ///////////////////////////////////////////
  // Extract exceptions by name and handle them
  ///////////////////////////////////////////

  assign BreakpointFaultM = ebreakM; // could have other causes from a debugger
  assign EcallFaultM = ecallM;

  ///////////////////////////////////////////
  // Fault on illegal instructions
  ///////////////////////////////////////////

  assign IllegalPrivilegedInstrM = PrivilegedM & ~(sretM|mretM|ecallM|ebreakM|wfiInstrM|wrsM|sfencevmaM);
  assign IllegalInstrFaultM = IllegalIEUFPUInstrM | IllegalPrivilegedInstrM | IllegalCSRAccessM |
                              WFITimeoutM | WRSTimeoutM;
endmodule
