///////////////////////////////////////////
// privileged.sv
//
// Written: David_Harris@hmc.edu 5 January 2021
// Modified: 
//
// Purpose: Implements the CSRs, Exceptions, and Privileged operations
//          See RISC-V Privileged Mode Specification 20190608 
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

// *** remove signals not needed by PMA/PMP now that it is moved
module privileged (
  input  logic             clk, reset,
  input  logic             StallD, StallE, StallM, StallW,
  input  logic             FlushD, FlushE, FlushM, FlushW, 
(* mark_debug = "true" *)  input  logic             CSRReadM, CSRWriteM,
  input  logic [`XLEN-1:0] SrcAM,
  input  logic [`XLEN-1:0] PCM, PCNext2F,
  input  logic [31:0]      InstrM,
  output logic [`XLEN-1:0] CSRReadValW,
  output logic [`XLEN-1:0] UnalignedPCNextF,
  output logic             RetM, TrapM, 
  output logic             sfencevmaM,
  input  logic             InstrValidM, CommittedM, CommittedF, 
  input  logic             FRegWriteM, LoadStallD,
  input  logic 		       DirPredictionWrongM,
  input  logic 		       BTBPredPCWrongM,
  input  logic 		       RASPredPCWrongM,
  input  logic 		       PredictionInstrClassWrongM,
  input  logic [3:0]       InstrClassM,
  input  logic             DCacheMiss,
  input  logic             DCacheAccess,
  input  logic             ICacheMiss,
  input  logic             ICacheAccess,
  input  logic             PrivilegedM,
  input  logic             HPTWInstrAccessFaultM, 
  input  logic             InstrPageFaultF, LoadPageFaultM, StoreAmoPageFaultM,
  input  logic             InstrMisalignedFaultM, 
  input  logic             LoadMisalignedFaultM, StoreAmoMisalignedFaultM,
  input  logic             IllegalIEUInstrFaultD, IllegalFPUInstrM,
  input  logic             MTimerInt, MExtInt, SExtInt, MSwInt,
  input  logic [63:0]      MTIME_CLINT, 
  input  logic [`XLEN-1:0] IEUAdrM,
  input  logic [4:0]       SetFflagsM,

  // Trap signals from pmp/pma in mmu
  // *** do these need to be split up into one for dmem and one for ifu?
  // instead, could we only care about the instr and F pins that come from ifu and only care about the load/store and m pins that come from dmem?
  
  input logic InstrAccessFaultF,
  input logic LoadAccessFaultM,
  input logic StoreAmoAccessFaultM,
  input logic SelHPTW,

  output logic [1:0]       PrivilegeModeW,
  output logic [`XLEN-1:0] SATP_REGW,
  output logic             STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  output logic  [1:0]      STATUS_MPP,
  output logic [1:0]       STATUS_FS,
  output var logic [7:0]   PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  output var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0], 
  output logic [2:0]       FRM_REGW,
  output logic             BreakpointFaultM, EcallFaultM, WFIStallM, BigEndianM
);

  logic [`LOG_XLEN-1:0] CauseM;
  logic [`XLEN-1:0] MEDELEG_REGW;
  logic [11:0]      MIDELEG_REGW;

  logic sretM, mretM;
  logic IllegalCSRAccessM;
  logic IllegalIEUInstrFaultM;
  logic InstrPageFaultM;
  logic InstrAccessFaultM;
  logic IllegalInstrFaultM;

  (* mark_debug = "true" *)  logic InterruptM; 

  logic       STATUS_SPP, STATUS_TSR, STATUS_TW, STATUS_TVM;
  logic       STATUS_MIE, STATUS_SIE;
  logic [11:0] MIP_REGW, MIE_REGW;
  logic [1:0] NextPrivilegeModeM;
  logic       DelegateM;
  logic       wfiM, IntPendingM;

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
    .DirPredictionWrongM, .BTBPredPCWrongM, .RASPredPCWrongM, 
    .PredictionInstrClassWrongM, .InstrClassM, .DCacheMiss, .DCacheAccess, .ICacheMiss, .ICacheAccess,
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





