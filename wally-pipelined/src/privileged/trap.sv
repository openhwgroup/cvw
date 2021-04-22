///////////////////////////////////////////
// trap.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: dottolia@hmc.edu 14 April 2021: Add support for vectored interrupts
//
// Purpose: Handle Traps: Exceptions and Interrupt
//          See RISC-V Privileged Mode Specification 20190608 3.1.10-11
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

module trap (
  input  logic             reset, 
  input  logic             InstrMisalignedFaultM, InstrAccessFaultM, IllegalInstrFaultM,
  input  logic             BreakpointFaultM, LoadMisalignedFaultM, StoreMisalignedFaultM,
  input  logic             LoadAccessFaultM, StoreAccessFaultM, EcallFaultM, InstrPageFaultM,
  input  logic             LoadPageFaultM, StorePageFaultM,
  input  logic             mretM, sretM, uretM,
  input  logic [1:0]       PrivilegeModeW, NextPrivilegeModeM,
  input  logic [`XLEN-1:0] MEPC_REGW, SEPC_REGW, UEPC_REGW, UTVEC_REGW, STVEC_REGW, MTVEC_REGW,
  input  logic [11:0]      MIP_REGW, MIE_REGW,
  input  logic             STATUS_MIE, STATUS_SIE,
  input  logic [`XLEN-1:0] PCM,
  input  logic [`XLEN-1:0] InstrMisalignedAdrM, MemAdrM, 
  input  logic [31:0]      InstrM,
  output logic             TrapM, MTrapM, STrapM, UTrapM, RetM,
  output logic [`XLEN-1:0] PrivilegedNextPCM, CauseM, NextFaultMtvalM
//  output logic [11:0]     MIP_REGW, SIP_REGW, UIP_REGW, MIE_REGW, SIE_REGW, UIE_REGW,
//  input  logic            WriteMIPM, WriteSIPM, WriteUIPM, WriteMIEM, WriteSIEM, WriteUIEM
);

  logic [11:0] MIntGlobalEnM, SIntGlobalEnM, PendingIntsM; 
  logic InterruptM;
  logic [`XLEN-1:0] PrivilegedTrapVector, PrivilegedVectoredTrapVector;

  // Determine pending enabled interrupts
  assign MIntGlobalEnM = {12{(PrivilegeModeW != `M_MODE) || STATUS_MIE}}; // if M ints enabled or lower priv 3.1.9
  assign SIntGlobalEnM = (PrivilegeModeW == `U_MODE) || STATUS_SIE; // if S ints enabled or lower priv 3.1.9
  assign PendingIntsM = (MIP_REGW & MIE_REGW) & ((MIntGlobalEnM & 12'h888) | (SIntGlobalEnM & 12'h222));
  assign InterruptM = |PendingIntsM; // interrupt if any sources are pending
 
  // Trigger Traps and RET
  assign TrapM = InstrMisalignedFaultM | InstrAccessFaultM | IllegalInstrFaultM |
                      BreakpointFaultM | LoadMisalignedFaultM | StoreMisalignedFaultM |
                      LoadAccessFaultM | StoreAccessFaultM | EcallFaultM | InstrPageFaultM |
                      LoadPageFaultM | StorePageFaultM | InterruptM;
  assign MTrapM = TrapM & (NextPrivilegeModeM == `M_MODE);
  assign STrapM = TrapM & (NextPrivilegeModeM == `S_MODE) & `S_SUPPORTED;
  assign UTrapM = TrapM & (NextPrivilegeModeM == `U_MODE) & `N_SUPPORTED;
  assign RetM = mretM | sretM | uretM;

  always_comb
      if      (NextPrivilegeModeM == `U_MODE) PrivilegedTrapVector = UTVEC_REGW; 
      else if (NextPrivilegeModeM == `S_MODE) PrivilegedTrapVector = STVEC_REGW;
      else                                    PrivilegedTrapVector = MTVEC_REGW; 

  // Handle vectored traps (when mtvec/stvec/utvec csr value has bits [1:0] == 01)
  // For vectored traps, set program counter to _tvec value + 4 times the cause code
  generate
    if(`VECTORED_INTERRUPTS_SUPPORTED) begin
        always_comb
          if (PrivilegedTrapVector[1:0] == 2'b01 && CauseM[`XLEN-1] == 1)
            PrivilegedVectoredTrapVector = {PrivilegedTrapVector[`XLEN-1:2] + CauseM[`XLEN-3:0], 2'b00};
          else
            PrivilegedVectoredTrapVector = {PrivilegedTrapVector[`XLEN-1:2], 2'b00};
    end
    else begin
      assign PrivilegedVectoredTrapVector = {PrivilegedTrapVector[`XLEN-1:2], 2'b00};
    end
  endgenerate

  always_comb 
    if      (mretM)                         PrivilegedNextPCM = MEPC_REGW;
    else if (sretM)                         PrivilegedNextPCM = SEPC_REGW;
    else if (uretM)                         PrivilegedNextPCM = UEPC_REGW;
    else                                    PrivilegedNextPCM = PrivilegedTrapVector;

  // Cause priority defined in table 3.7 of 20190608 privileged spec
  // Exceptions are of lower priority than all interrupts (3.1.9)
  always_comb
    if      (reset)                 CauseM = 0; // hard reset 3.3
    else if (PendingIntsM[11])      CauseM = (1 << (`XLEN-1)) + 11; // Machine External Int
    else if (PendingIntsM[3])       CauseM = (1 << (`XLEN-1)) + 3;  // Machine Sw Int
    else if (PendingIntsM[7])       CauseM = (1 << (`XLEN-1)) + 7;  // Machine Timer Int
    else if (PendingIntsM[9])       CauseM = (1 << (`XLEN-1)) + 9;  // Supervisor External Int
    else if (PendingIntsM[1])       CauseM = (1 << (`XLEN-1)) + 1;  // Supervisor Sw Int
    else if (PendingIntsM[5])       CauseM = (1 << (`XLEN-1)) + 5;  // Supervisor Timer Int
    else if (InstrPageFaultM)       CauseM = 12;
    else if (InstrAccessFaultM)     CauseM = 1;
    else if (InstrMisalignedFaultM) CauseM = 0;
    else if (IllegalInstrFaultM)    CauseM = 2;
    else if (BreakpointFaultM)      CauseM = 3;
    else if (EcallFaultM)           CauseM = {{(`XLEN-2){1'b0}}, PrivilegeModeW} + 8;
    else if (LoadMisalignedFaultM)  CauseM = 4;
    else if (StoreMisalignedFaultM) CauseM = 6;
    else if (LoadPageFaultM)        CauseM = 13;
    else if (StorePageFaultM)       CauseM = 15;
    else if (LoadAccessFaultM)      CauseM = 5;
    else if (StoreAccessFaultM)     CauseM = 7;
    else                            CauseM = 0;

  // MTVAL
    // 3.1.17: on instruction fetch, load, or store address misaligned access or page fault
    // mtval is written with the faulting virtual address.
    // On illegal instruction trap, mtval may be written with faulting instruction
    // For other traps (including interrupts), mtval is set to 0
    // *** hardware breakpoint is supposed to write faulting virtual address per priv p. 38
    // *** Page faults not yet implemented
    // Technically 
  
  always_comb 
    if      (InstrMisalignedFaultM) NextFaultMtvalM = InstrMisalignedAdrM;
    else if (LoadMisalignedFaultM)  NextFaultMtvalM = MemAdrM;
    else if (StoreMisalignedFaultM) NextFaultMtvalM = MemAdrM;
    else if (InstrPageFaultM)       NextFaultMtvalM = PCM;
    else if (LoadPageFaultM)        NextFaultMtvalM = MemAdrM;
    else if (StorePageFaultM)       NextFaultMtvalM = MemAdrM;
    else if (IllegalInstrFaultM)    NextFaultMtvalM = {{(`XLEN-32){1'b0}}, InstrM};
    else                            NextFaultMtvalM = 0;
endmodule