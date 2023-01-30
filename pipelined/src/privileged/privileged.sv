///////////////////////////////////////////
// privileged.sv
//
// Written: David_Harris@hmc.edu 5 January 2021
// Modified: 
//
// Purpose: Implements the CSRs, Exceptions, and Privileged operations
//          See RISC-V Privileged Mode Specification 20190608 
// 
// Documentation: RISC-V System on Chip Design Chapter 5 (Figure 5.8)
//
// A component of the CORE-V-WALLY configurable RISC-V project.
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
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

module privileged (
  input  logic             clk, reset,
  input  logic             StallD, StallE, StallM, StallW,
  input  logic             FlushD, FlushE, FlushM, FlushW, 
  // CSR Reads and Writes, and values needed for traps
  input  logic  CSRReadM, CSRWriteM,         // Read or write CSRs
  input  logic [`XLEN-1:0] SrcAM,                                     // GPR register to write
  input  logic [31:0]      InstrM,                                    // Instruction
  input  logic [`XLEN-1:0] IEUAdrM,                                   // address from IEU
  input  logic [`XLEN-1:0] PCM, PCNext2F,                             // program counter, next PC going to trap/return PC logic
  // control signals
  input  logic             InstrValidM,                               // Current instruction is valid (not flushed)
  input  logic             CommittedM, CommittedF,                    // current instruction is using bus; don't interrupt
  input  logic             PrivilegedM,                               // privileged instruction
  // processor events for performance counter logging
  input  logic             FRegWriteM,                                // instruction will write floating-point registers
  input  logic             LoadStallD,                                // load instruction is stalling
  input  logic 		         DirPredictionWrongM,                     // branch predictor guessed wrong directoin
  input  logic 		         BTBPredPCWrongM,                         // branch predictor guessed wrong target
  input  logic 		         RASPredPCWrongM,                         // return adddress stack guessed wrong target
  input  logic 		         PredictionInstrClassWrongM,              // branch predictor guessed wrong instruction class
  input  logic             BPPredWrongM,                              // branch predictor is wrong
  input  logic [3:0]       InstrClassM,                               // actual instruction class
  input  logic             JumpOrTakenBranchM,                               // actual instruction class
  input  logic             DCacheMiss,                                // data cache miss
  input  logic             DCacheAccess,                              // data cache accessed (hit or miss)
  input  logic             ICacheMiss,                                // instruction cache miss
  input  logic             ICacheAccess,                              // instruction cache access
  // fault sources
  input  logic             InstrAccessFaultF,                         // instruction access fault
  input  logic             LoadAccessFaultM, StoreAmoAccessFaultM,    // load or store access fault
  input  logic             HPTWInstrAccessFaultM,                     // hardware page table access fault while fetching instruction PTE
  input  logic             InstrPageFaultF,                           // page faults
  input  logic             LoadPageFaultM, StoreAmoPageFaultM,        // page faults
  input  logic             InstrMisalignedFaultM,                     // misaligned instruction fault
  input  logic             LoadMisalignedFaultM, StoreAmoMisalignedFaultM,  // misaligned data fault
  input  logic             IllegalIEUInstrFaultD, IllegalFPUInstrM,   // illegal instruction faults
  input  logic             MTimerInt, MExtInt, SExtInt, MSwInt,       // interrupt sources
  input  logic [63:0]      MTIME_CLINT,                               // timer value from CLINT
  input  logic [4:0]       SetFflagsM,                                // set FCSR flags from FPU
  input  logic             SelHPTW,                                   // HPTW in use.  Causes system to use S-mode endianness for accesses
  // CSR outputs
  output logic [`XLEN-1:0] CSRReadValW,                               // Value read from CSR
  output logic [1:0]       PrivilegeModeW,                            // current privilege mode
  output logic [`XLEN-1:0] SATP_REGW,                                 // supervisor address translation register
  output logic             STATUS_MXR, STATUS_SUM, STATUS_MPRV,       // status register bits
  output logic [1:0]       STATUS_MPP, STATUS_FS,                     // status register bits
  output var logic [7:0]   PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],       // PMP configuration entries to MMU
  output var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0], // PMP address entries to MMU
  output logic [2:0]       FRM_REGW,                                  // FPU rounding mode
  // PC logic output in privileged unit
  output logic [`XLEN-1:0] UnalignedPCNextF,                          // Next PC from trap/return PC logic
  // control outputs  
  output logic             RetM, TrapM,                               // return instruction, or trap
  output logic             sfencevmaM,                                // sfence.vma instruction
  output logic             BigEndianM,                                // Use big endian in current privilege mode
  // Fault outputs
  output logic             BreakpointFaultM, EcallFaultM,             // breakpoint and Ecall traps should retire
  output logic             WFIStallM                                  // Stall in Memory stage for WFI until interrupt or timeout
);

  logic [`LOG_XLEN-1:0]    CauseM;                                    // trap cause
  logic [`XLEN-1:0]        MEDELEG_REGW;                              // exception delegation CSR
  logic [11:0]             MIDELEG_REGW;                              // interrupt delegation CSR
  logic                    sretM, mretM;                              // supervisor / machine return instruction
  logic                    IllegalCSRAccessM;                         // Illegal access to CSR
  logic                    IllegalIEUInstrFaultM;                     // Illegal IEU instruction, delayed to Mem stage
  logic                    InstrPageFaultM;                           // Instruction page fault, delayed to Mem stage
  logic                    InstrAccessFaultM;                         // Instruction access fault, delayed to Mem stages
  logic                    IllegalInstrFaultM;                        // Illegal instruction fault
  logic                    STATUS_SPP, STATUS_TSR, STATUS_TW, STATUS_TVM; // Status bits needed within privileged unit
  logic                    STATUS_MIE, STATUS_SIE;                    // status bits: interrupt enables
  logic [11:0]             MIP_REGW, MIE_REGW;                        // interrupt pending and enable bits
  logic [1:0]              NextPrivilegeModeM;                        // next privilege mode based on trap or return
  logic                    DelegateM;                                 // trap should be delegated
  logic                    wfiM;                                      // wait for interrupt instruction
  logic                    IntPendingM;                               // interrupt is pending, even if not enabled.  ends wfi
  logic InterruptM;                         // interrupt occuring


  // track the current privilege level
  privmode privmode(.clk, .reset, .StallW, .TrapM, .mretM, .sretM, .DelegateM,
    .STATUS_MPP, .STATUS_SPP, .NextPrivilegeModeM, .PrivilegeModeW);

  // decode privileged instructions
  privdec pmd(.clk, .reset, .StallM, .InstrM(InstrM[31:20]), 
    .PrivilegedM, .IllegalIEUInstrFaultM, .IllegalCSRAccessM, .IllegalFPUInstrM, 
    .PrivilegeModeW, .STATUS_TSR, .STATUS_TVM, .STATUS_TW, .IllegalInstrFaultM, 
    .EcallFaultM, .BreakpointFaultM, .sretM, .mretM, .wfiM, .sfencevmaM);

  // Control and Status Registers
  csr csr(.clk, .reset, .FlushM, .FlushW, .StallE, .StallM, .StallW,
    .InstrM, .PCM, .SrcAM, .IEUAdrM, .PCNext2F,
    .CSRReadM, .CSRWriteM, .TrapM, .mretM, .sretM, .wfiM, .IntPendingM, .InterruptM,
    .MTimerInt, .MExtInt, .SExtInt, .MSwInt,
    .MTIME_CLINT, .InstrValidM, .FRegWriteM, .LoadStallD,
    .DirPredictionWrongM, .BTBPredPCWrongM, .RASPredPCWrongM, .BPPredWrongM,
    .PredictionInstrClassWrongM, .InstrClassM, .DCacheMiss, .DCacheAccess, .ICacheMiss, .ICacheAccess, .JumpOrTakenBranchM,
    .NextPrivilegeModeM, .PrivilegeModeW, .CauseM, .SelHPTW,
    .STATUS_MPP, .STATUS_SPP, .STATUS_TSR, .STATUS_TVM,
    .STATUS_MIE, .STATUS_SIE, .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_TW, .STATUS_FS,
    .MEDELEG_REGW, .MIP_REGW, .MIE_REGW, .MIDELEG_REGW,
    .SATP_REGW, .PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW,
    .SetFflagsM, .FRM_REGW, 
    .CSRReadValW,.UnalignedPCNextF, .IllegalCSRAccessM, .BigEndianM);

  // pipeline early-arriving trap sources
  privpiperegs ppr(.clk, .reset, .StallD, .StallE, .StallM, .FlushD, .FlushE, .FlushM,
    .InstrPageFaultF, .InstrAccessFaultF, .IllegalIEUInstrFaultD, 
    .InstrPageFaultM, .InstrAccessFaultM, .IllegalIEUInstrFaultM);

  // trap logic
  trap trap(.reset,
    .InstrMisalignedFaultM, .InstrAccessFaultM, .HPTWInstrAccessFaultM, .IllegalInstrFaultM,
    .BreakpointFaultM, .LoadMisalignedFaultM, .StoreAmoMisalignedFaultM,
    .LoadAccessFaultM, .StoreAmoAccessFaultM, .EcallFaultM, .InstrPageFaultM,
    .LoadPageFaultM, .StoreAmoPageFaultM,
    .mretM, .sretM, .PrivilegeModeW, 
    .MIP_REGW, .MIE_REGW, .MIDELEG_REGW, .MEDELEG_REGW, .STATUS_MIE, .STATUS_SIE,
    .InstrValidM, .CommittedM, .CommittedF,
    .TrapM, .RetM, .wfiM, .InterruptM, .IntPendingM, .DelegateM, .WFIStallM, .CauseM);
endmodule





