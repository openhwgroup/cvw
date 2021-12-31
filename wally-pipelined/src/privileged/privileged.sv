///////////////////////////////////////////
// privileged.sv
//
// Written: David_Harris@hmc.edu 5 January 2021
// Modified: 
//
// Purpose: Implements the CSRs, Exceptions, and Privileged operations
//          See RISC-V Privileged Mode Specification 20190608 
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
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"

// *** remove signals not needed by PMA/PMP now that it is moved
module privileged (
  input  logic             clk, reset,
  input  logic             FlushD, FlushE, FlushM, FlushW, StallD, StallE, StallM, StallW,
  input  logic             CSRReadM, CSRWriteM,
  input  logic [`XLEN-1:0] SrcAM,
  input  logic [`XLEN-1:0] PCM,
  input  logic [31:0]      InstrM,
  output logic [`XLEN-1:0] CSRReadValW,
  output logic [`XLEN-1:0] PrivilegedNextPCM,
  output logic             RetM, TrapM, 
  output logic             ITLBFlushF, DTLBFlushM,
  input  logic             InstrValidM, CommittedM,
  input  logic             FRegWriteM, LoadStallD,
  input  logic 		   BPPredDirWrongM,
  input  logic 		   BTBPredPCWrongM,
  input  logic 		   RASPredPCWrongM,
  input  logic 		   BPPredClassNonCFIWrongM,
  input  logic [4:0]       InstrClassM,
  input  logic             DCacheMiss,
  input  logic             DCacheAccess,
  input  logic             PrivilegedM,
  input  logic             ITLBInstrPageFaultF, DTLBLoadPageFaultM, DTLBStorePageFaultM,
  input  logic             InstrMisalignedFaultM, IllegalIEUInstrFaultD, IllegalFPUInstrD,
  input  logic             LoadMisalignedFaultM,
  input  logic             StoreMisalignedFaultM,
  input  logic             TimerIntM, ExtIntM, SwIntM,
  input  logic [63:0]      MTIME_CLINT, 
  input  logic [`XLEN-1:0] InstrMisalignedAdrM, IEUAdrM,
  input  logic [4:0]       SetFflagsM,

  // Trap signals from pmp/pma in mmu
  // *** do these need to be split up into one for dmem and one for ifu?
  // instead, could we only care about the instr and F pins that come from ifu and only care about the load/store and m pins that come from dmem?
  
  input logic InstrAccessFaultF,
  input logic LoadAccessFaultM,
  input logic StoreAccessFaultM,

  output logic 		   ExceptionM,
  output logic 		   PendingInterruptM,
  output logic		   IllegalFPUInstrE,
  output logic [1:0]       PrivilegeModeW,
  output logic [`XLEN-1:0] SATP_REGW,
  output logic             STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  output logic  [1:0]      STATUS_MPP,
  output var logic [7:0]   PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  output var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW [`PMP_ENTRIES-1:0], 
  output logic [2:0]       FRM_REGW,
  output logic             BreakpointFaultM, EcallFaultM

);

  logic [1:0] NextPrivilegeModeM;

  logic [`XLEN-1:0] CauseM, NextFaultMtvalM;
  logic [`XLEN-1:0] MEPC_REGW, SEPC_REGW, UEPC_REGW, UTVEC_REGW, STVEC_REGW, MTVEC_REGW;
  //  logic [11:0] MEDELEG_REGW, MIDELEG_REGW, SEDELEG_REGW, SIDELEG_REGW;
  logic [`XLEN-1:0] MEDELEG_REGW, MIDELEG_REGW, SEDELEG_REGW, SIDELEG_REGW;

  logic uretM, sretM, mretM, ecallM, ebreakM, wfiM, sfencevmaM;
  logic IllegalCSRAccessM;
  logic IllegalIEUInstrFaultE, IllegalIEUInstrFaultM;
  logic IllegalFPUInstrM;
  logic LoadPageFaultM, StorePageFaultM; 
  logic InstrPageFaultF, InstrPageFaultD, InstrPageFaultE, InstrPageFaultM;
  logic InstrAccessFaultD, InstrAccessFaultE, InstrAccessFaultM;
  logic IllegalInstrFaultM, TrappedSRETM;

  logic MTrapM, STrapM, UTrapM;
  (* mark_debug = "true" *)  logic InterruptM; 

  logic       STATUS_SPP, STATUS_TSR, STATUS_TW; 
  logic       STATUS_MIE, STATUS_SIE;
  logic [11:0] MIP_REGW, MIE_REGW, SIP_REGW, SIE_REGW;
  logic md, sd;
  logic       StallMQ;


  ///////////////////////////////////////////
  // track the current privilege level
  ///////////////////////////////////////////

  // get bits of DELEG registers based on CAUSE
  //  assign md = CauseM[`XLEN-1] ? MIDELEG_REGW[CauseM[3:0]] : MEDELEG_REGW[CauseM[3:0]];
  //  assign sd = CauseM[`XLEN-1] ? SIDELEG_REGW[CauseM[3:0]] : SEDELEG_REGW[CauseM[3:0]]; // depricated
  assign md = CauseM[`XLEN-1] ? MIDELEG_REGW[CauseM[`LOG_XLEN-1:0]] : MEDELEG_REGW[CauseM[`LOG_XLEN-1:0]];
  assign sd = CauseM[`XLEN-1] ? SIDELEG_REGW[CauseM[`LOG_XLEN-1:0]] : SEDELEG_REGW[CauseM[`LOG_XLEN-1:0]]; // depricated
  
  // PrivilegeMode FSM
  always_comb begin
    TrappedSRETM = 0;
    if (mretM) NextPrivilegeModeM = STATUS_MPP;
    else if (sretM) 
      if (STATUS_TSR & PrivilegeModeW == `S_MODE) begin
        TrappedSRETM = 1;
        NextPrivilegeModeM = PrivilegeModeW;
      end else NextPrivilegeModeM = {1'b0, STATUS_SPP};
    else if (uretM) NextPrivilegeModeM = `U_MODE;
    else if (TrapM) begin // Change privilege based on DELEG registers (see 3.1.8)
      if (PrivilegeModeW == `U_MODE)
        if (`N_SUPPORTED & `U_SUPPORTED & md & sd) NextPrivilegeModeM = `U_MODE;
        else if (`S_SUPPORTED & md)                NextPrivilegeModeM = `S_MODE;
        else                                       NextPrivilegeModeM = `M_MODE;
      else if (PrivilegeModeW == `S_MODE) 
        if (`S_SUPPORTED & md)                     NextPrivilegeModeM = `S_MODE;
        else                                       NextPrivilegeModeM = `M_MODE;
      else                                         NextPrivilegeModeM = `M_MODE;
    end else                                       NextPrivilegeModeM = PrivilegeModeW;
  end
  // *** WFI could be implemented here and depends on TW

  flopenl #(2) privmodereg(clk, reset, ~StallW, NextPrivilegeModeM, `M_MODE, PrivilegeModeW);

  ///////////////////////////////////////////
  // decode privileged instructions
  ///////////////////////////////////////////

   privdec pmd(.InstrM(InstrM[31:20]), 
              .PrivilegedM, .IllegalIEUInstrFaultM, .IllegalCSRAccessM, .IllegalFPUInstrM, .TrappedSRETM,
              .PrivilegeModeW, .STATUS_TSR, .IllegalInstrFaultM, 
              .uretM, .sretM, .mretM, .ecallM, .ebreakM, .wfiM, .sfencevmaM);

  ///////////////////////////////////////////
  // Control and Status Registers
  ///////////////////////////////////////////
  //csr csr(.*);
  csr csr(.clk, .reset,
          .FlushE, .FlushM, .FlushW,
          .StallE, .StallM, .StallW,
          .InstrM, .PCM, .SrcAM,
          .CSRReadM, .CSRWriteM, .TrapM, .MTrapM, .STrapM, .UTrapM, .mretM, .sretM, .uretM,
          .TimerIntM, .ExtIntM, .SwIntM,
          .MTIME_CLINT, 
          .InstrValidM, .FRegWriteM, .LoadStallD,
          .BPPredDirWrongM, .BTBPredPCWrongM, .RASPredPCWrongM, 
          .BPPredClassNonCFIWrongM, .InstrClassM, .DCacheMiss, .DCacheAccess,
          .NextPrivilegeModeM, .PrivilegeModeW,
          .CauseM, .NextFaultMtvalM, .STATUS_MPP,
          .STATUS_SPP, .STATUS_TSR,
          .MEPC_REGW, .SEPC_REGW, .UEPC_REGW, .UTVEC_REGW, .STVEC_REGW, .MTVEC_REGW,
          .MEDELEG_REGW, .MIDELEG_REGW, .SEDELEG_REGW, .SIDELEG_REGW, 
          .SATP_REGW,
          .MIP_REGW, .MIE_REGW, .SIP_REGW, .SIE_REGW,
          .STATUS_MIE, .STATUS_SIE,
          .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_TW,
          .PMPCFG_ARRAY_REGW,
          .PMPADDR_ARRAY_REGW,
          .SetFflagsM,
          .FRM_REGW, 
          .CSRReadValW,
          .IllegalCSRAccessM);

  ///////////////////////////////////////////
  // Extract exceptions by name and handle them 
  ///////////////////////////////////////////

  assign BreakpointFaultM = ebreakM; // could have other causes too
  assign EcallFaultM = ecallM;

  flopr #(1) StallMReg(.clk, .reset, .d(StallM), .q(StallMQ));
  assign ITLBFlushF = sfencevmaM & ~StallMQ;
  assign DTLBFlushM = sfencevmaM;
  // sets ITLBFlush to pulse for one cycle of the sfence.vma instruction
  // In this instr we want to flush the tlb and then do a pagetable walk to update the itlb and continue the program.
  // But we're still in the stalled sfence instruction, so if itlbflushf == sfencevmaM, tlbflush would never drop and 
  // the tlbwrite would never take place after the pagetable walk. by adding in ~StallMQ, we are able to drop itlbflush 
  // after a cycle AND pulse it for another cycle on any further back-to-back sfences. 


  // A page fault might occur because of insufficient privilege during a TLB
  // lookup or a improperly formatted page table during walking

  // *** merge these at the lsu level.
  assign InstrPageFaultF = ITLBInstrPageFaultF;
  assign LoadPageFaultM = DTLBLoadPageFaultM;
  assign StorePageFaultM = DTLBStorePageFaultM;

  // pipeline fault signals
  flopenrc #(2) faultregD(clk, reset, FlushD, ~StallD,
                  {InstrPageFaultF, InstrAccessFaultF},
                  {InstrPageFaultD, InstrAccessFaultD});
  flopenrc #(4) faultregE(clk, reset, FlushE, ~StallE,
                  {IllegalIEUInstrFaultD, InstrPageFaultD, InstrAccessFaultD, IllegalFPUInstrD}, // ** vs IllegalInstrFaultInD
                  {IllegalIEUInstrFaultE, InstrPageFaultE, InstrAccessFaultE, IllegalFPUInstrE});
  flopenrc #(4) faultregM(clk, reset, FlushM, ~StallM,
                  {IllegalIEUInstrFaultE, InstrPageFaultE, InstrAccessFaultE, IllegalFPUInstrE},
                  {IllegalIEUInstrFaultM, InstrPageFaultM, InstrAccessFaultM, IllegalFPUInstrM});
  // *** it should be possible to combine some of these faults earlier to reduce module boundary crossings and save flops dh 5 july 2021
  //trap trap(.*);
  trap trap(.clk, .reset,
            .InstrMisalignedFaultM, .InstrAccessFaultM, .IllegalInstrFaultM,
            .BreakpointFaultM, .LoadMisalignedFaultM, .StoreMisalignedFaultM,
            .LoadAccessFaultM, .StoreAccessFaultM, .EcallFaultM, .InstrPageFaultM,
            .LoadPageFaultM, .StorePageFaultM,
            .mretM, .sretM, .uretM,
            .PrivilegeModeW, .NextPrivilegeModeM,
            .MEPC_REGW, .SEPC_REGW, .UEPC_REGW, .UTVEC_REGW, .STVEC_REGW, .MTVEC_REGW,
            .MIP_REGW, .MIE_REGW, .SIP_REGW, .SIE_REGW,
            .STATUS_MIE, .STATUS_SIE,
            .PCM,
            .InstrMisalignedAdrM, .IEUAdrM, 
            .InstrM,
            .InstrValidM, .CommittedM,
            .TrapM, .MTrapM, .STrapM, .UTrapM, .RetM,
            .InterruptM,
            .ExceptionM,
            .PendingInterruptM,
            .PrivilegedNextPCM, .CauseM, .NextFaultMtvalM);
endmodule





