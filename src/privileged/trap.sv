///////////////////////////////////////////
// trap.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: dottolia@hmc.edu 14 April 2021: Add support for vectored interrupts
//
// Purpose: Handle Traps: Exceptions and Interrupts
// 
// Documentation: RISC-V System on Chip Design Chapter 5 (Figure 5.9)
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

module trap import cvw::*;  #(parameter cvw_t P) (
  input  logic                 reset, 
  input  logic                 InstrMisalignedFaultM, InstrAccessFaultM, HPTWInstrAccessFaultM, IllegalInstrFaultM,
  input  logic                 BreakpointFaultM, LoadMisalignedFaultM, StoreAmoMisalignedFaultM,
  input  logic                 LoadAccessFaultM, StoreAmoAccessFaultM, EcallFaultM, InstrPageFaultM,
  input  logic                 LoadPageFaultM, StoreAmoPageFaultM,              // various trap sources
  input  logic                 mretM, sretM,                                    // return instructions
  input  logic                 wfiM,                                            // wait for interrupt instruction
  input  logic [1:0]           PrivilegeModeW,                                  // current privilege mode
  input  logic [11:0]          MIP_REGW, MIE_REGW, MIDELEG_REGW,                // interrupt pending, enabled, and delegate CSRs
  input  logic [15:0]          MEDELEG_REGW,                                    // exception delegation SR
  input  logic                 STATUS_MIE, STATUS_SIE,                          // machine/supervisor interrupt enables
  input  logic                 InstrValidM,                                     // current instruction is valid, not flushed
  input  logic                 CommittedM, CommittedF,                          // LSU/IFU has committed to a bus operation that can't be interrupted
  output logic                 TrapM,                                           // Trap is occurring
  output logic                 RetM,                                            // Return instruction being executed
  output logic                 InterruptM,                                      // Interrupt is occurring
  output logic                 ExceptionM,                                      // exception is occurring
  output logic                 IntPendingM,                                     // Interrupt is pending, might occur if enabled
  output logic                 DelegateM,                                       // Delegate trap to supervisor handler
  output logic [3:0]           CauseM                                           // trap cause
);

  logic                        MIntGlobalEnM, SIntGlobalEnM;                    // Global interupt enables
  logic                        Committed;                                       // LSU or IFU has committed to a bus operation that can't be interrupted
  logic                        BothInstrAccessFaultM;                           // instruction or HPTW ITLB fill caused an Instruction Access Fault
  logic [11:0]                 PendingIntsM, ValidIntsM, EnabledIntsM;          // interrupts are pending, valid, or enabled

  ///////////////////////////////////////////
  // Determine pending enabled interrupts
  // interrupt if any sources are pending
  // & with a M stage valid bit to avoid interrupts from interrupt a nonexistent flushed instruction (in the M stage)
  // & with ~CommittedM to make sure MEPC isn't chosen so as to rerun the same instr twice
  ///////////////////////////////////////////

  assign MIntGlobalEnM = (PrivilegeModeW != P.M_MODE) | STATUS_MIE; // if M ints enabled or lower priv 3.1.9
  assign SIntGlobalEnM = (PrivilegeModeW == P.U_MODE) | ((PrivilegeModeW == P.S_MODE) & STATUS_SIE); // if in lower priv mode, or if S ints enabled and not in higher priv mode 3.1.9
  assign PendingIntsM  = MIP_REGW & MIE_REGW;
  assign IntPendingM   = |PendingIntsM;
  assign Committed     = CommittedM | CommittedF;
  assign EnabledIntsM  = ({12{MIntGlobalEnM}} & PendingIntsM & ~MIDELEG_REGW | {12{SIntGlobalEnM}} & PendingIntsM & MIDELEG_REGW);
  assign ValidIntsM    = {12{~Committed}} & EnabledIntsM;
  assign InterruptM    = (|ValidIntsM) & InstrValidM; // suppress interrupt if the memory system has partially processed a request.
  assign DelegateM     = P.S_SUPPORTED & (InterruptM ? MIDELEG_REGW[CauseM] : MEDELEG_REGW[CauseM]) & 
                     (PrivilegeModeW == P.U_MODE | PrivilegeModeW == P.S_MODE);

  ///////////////////////////////////////////
  // Trigger Traps and RET
  // According to RISC-V Spec Section 1.6, exceptions are caused by instructions.  Interrupts are external asynchronous.
  // Traps are the union of exceptions and interrupts.
  ///////////////////////////////////////////
  
  assign BothInstrAccessFaultM = InstrAccessFaultM | HPTWInstrAccessFaultM;
  // coverage off -item e 1 -fecexprrow 2
  // excludes InstrMisalignedFaultM from coverage of this line, since misaligned instructions cannot occur in rv64gc.
  assign ExceptionM = InstrMisalignedFaultM | BothInstrAccessFaultM | IllegalInstrFaultM |
                      LoadMisalignedFaultM | StoreAmoMisalignedFaultM |
                      InstrPageFaultM | LoadPageFaultM | StoreAmoPageFaultM |
                      BreakpointFaultM | EcallFaultM |
                      LoadAccessFaultM | StoreAmoAccessFaultM;
  // coverage on
  assign TrapM = ExceptionM | InterruptM; 
  assign RetM  = mretM | sretM;

  ///////////////////////////////////////////
  // Cause priority defined in table 3.7 of 20190608 privileged spec
  // Exceptions are of lower priority than all interrupts (3.1.9)
  ///////////////////////////////////////////

  always_comb
    if      (reset)                    CauseM = 0; // hard reset 3.3
    else if (ValidIntsM[11])           CauseM = 11; // Machine External Int
    else if (ValidIntsM[3])            CauseM = 3;  // Machine Sw Int
    else if (ValidIntsM[7])            CauseM = 7;  // Machine Timer Int
    else if (ValidIntsM[9])            CauseM = 9;  // Supervisor External Int 
    else if (ValidIntsM[1])            CauseM = 1;  // Supervisor Sw Int       
    else if (ValidIntsM[5])            CauseM = 5;  // Supervisor Timer Int    
    else if (InstrPageFaultM)          CauseM = 12;
    else if (BothInstrAccessFaultM)    CauseM = 1;
    else if (IllegalInstrFaultM)       CauseM = 2;
    // coverage off
    // Misaligned instructions cannot occur in rv64gc
    else if (InstrMisalignedFaultM)    CauseM = 0;
    // coverage on
    else if (BreakpointFaultM)         CauseM = 3;
    else if (EcallFaultM)              CauseM = {2'b10, PrivilegeModeW};
    else if (LoadMisalignedFaultM)     CauseM = 4;
    else if (StoreAmoMisalignedFaultM) CauseM = 6;
    else if (LoadPageFaultM)           CauseM = 13;
    else if (StoreAmoPageFaultM)       CauseM = 15;
    else if (LoadAccessFaultM)         CauseM = 5;
    else if (StoreAmoAccessFaultM)     CauseM = 7;
    else                               CauseM = 0;
endmodule
