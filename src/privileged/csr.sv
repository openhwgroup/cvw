///////////////////////////////////////////
// csr.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified:
//          dottolia@hmc.edu 7 April 2021
//
// Purpose: Counter Control and Status Registers
//          See RISC-V Privileged Mode Specification 20190608
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

module csr import cvw::*;  #(parameter cvw_t P) (
  input  logic                     clk, reset,
  input  logic                     FlushM, FlushW,
  input  logic                     StallE, StallM, StallW,
  input  logic [31:0]              InstrM,                    // current instruction
  input  logic [31:0]              InstrOrigM,                // Original compressed or uncompressed instruction in Memory stage for Illegal Instruction MTVAL
  input  logic [P.XLEN-1:0]        PCM,                       // program counter, next PC going to trap/return logic
  input  logic [P.XLEN-1:0]        PCSpillM,                  // program counter, next PC going to trap/return logic aligned after an instruction spill
  input  logic [P.XLEN-1:0]        SrcAM, IEUAdrxTvalM,       // SrcA and memory address from IEU
  input  logic                     CSRReadM, CSRWriteM,       // read or write CSR
  input  logic                     TrapM,                     // trap is occurring
  input  logic                     TrapToM, TrapToHSM, TrapToVSM,// resolved trap target
  input  logic                     mretM, sretM,              // return instruction
  input  logic                     InterruptM,                // interrupt is occurring
  input  logic                     ExceptionM,                // interrupt is occurring
  input  logic                     MTimerInt,                 // timer interrupt
  input  logic                     MExtInt, SExtInt,          // external interrupt (from PLIC)
  input  logic                     MSwInt,                    // software interrupt
  input  logic [63:0]              MTIME_CLINT,               // TIME value from CLINT
  input  logic                     InstrValidM,               // current instruction is valid
  input  logic                     FRegWriteM,                // writes to floating point registers change STATUS.FS
  input  logic [4:0]               SetFflagsM,                // Set floating point flag bits in FCSR
  input  logic [1:0]               NextPrivilegeModeM,        // STATUS bits updated based on next privilege mode
  input  logic [1:0]               PrivilegeModeW,            // current privilege mode
  input  logic                     VirtModeW,                 // current V Bit
  input  logic [4:0]               CauseM,                    // Trap cause
  input  logic                     SelHPTW,                   // hardware page table walker active, so base endianness on supervisor mode
  // inputs for performance counters
  input  logic                     LoadStallD, StoreStallD,
  input  logic                     ICacheStallF,
  input  logic                     DCacheStallM,
  input  logic                     BPDirWrongM,
  input  logic                     BTAWrongM,
  input  logic                     RASPredPCWrongM,
  input  logic                     IClassWrongM,
  input  logic                     BPWrongM,                  // branch predictor is wrong
  input  logic [3:0]               IClassM,
  input  logic                     DCacheMiss,
  input  logic                     DCacheAccess,
  input  logic                     ICacheMiss,
  input  logic                     ICacheAccess,
  input  logic                     sfencevmaM,
  input  logic                     InvalidateICacheM,
  input  logic                     DivBusyE,                  // integer divide busy
  input  logic                     FDivBusyE,                 // floating point divide busy
  // outputs from CSRs
  output logic [1:0]               STATUS_MPP,
  output logic                     MSTATUS_MPV,
  output logic                     STATUS_SPP, STATUS_TSR, STATUS_TVM,
  output logic                     HSTATUS_SPV,
  output logic                     HSTATUS_VTSR, HSTATUS_VTW, HSTATUS_VTVM,
  output logic                     VSSTATUS_SPP,
  output logic [15:0]              MEDELEG_REGW,
  output logic [63:0]              HEDELEG_REGW,
  output logic [11:0]              HIDELEG_REGW,
  output logic [P.XLEN-1:0]        SATP_REGW,
  output logic [11:0]              MIP_REGW, MIE_REGW, MIDELEG_REGW,
  output logic                     STATUS_MIE, STATUS_SIE,
  output logic                     STATUS_MXR, STATUS_SUM, STATUS_MPRV, STATUS_TW,
  output logic [1:0]               STATUS_FS,
  output var logic [7:0]           PMPCFG_ARRAY_REGW[P.PMP_ENTRIES-1:0],
  output var logic [P.PA_BITS-3:0] PMPADDR_ARRAY_REGW[P.PMP_ENTRIES-1:0],
  output logic [2:0]               FRM_REGW,
  output logic [3:0]               ENVCFG_CBE,
  output logic                     ENVCFG_PBMTE,              // Page-based memory type enable
  output logic                     ENVCFG_ADUE,               // HPTW A/D Update enable
  // PC logic output from privileged unit to IFU
  output logic [P.XLEN-1:0]        EPCM,                      // Exception Program counter to IFU PC logic
  output logic [P.XLEN-1:0]        TrapVectorM,               // Trap vector, to IFU PC logic
  //
  output logic [P.XLEN-1:0]        CSRReadValW,               // value read from CSR
  output logic                     IllegalCSRAccessM,         // Illegal CSR access: CSR doesn't exist or is inaccessible at this privilege level
  output logic                     BigEndianM                 // memory access is big-endian based on privilege mode and STATUS register endian fields
);

  localparam MIP = 12'h344;
  localparam SIP = 12'h144;

  logic [P.XLEN-1:0]       CSRMReadValM, CSRSReadValM, CSRUReadValM, CSRCReadValM;
  logic [P.XLEN-1:0]       CSRReadValM;
  logic [P.XLEN-1:0]       CSRSrcM;
  logic [P.XLEN-1:0]       CSRRWM, CSRRSM, CSRRCM;
  logic [P.XLEN-1:0]       CSRWriteValM;
  logic [P.XLEN-1:0]       MSTATUS_REGW, SSTATUS_REGW, MSTATUSH_REGW;
  logic                    STATUS_SPP_INT, STATUS_SIE_INT;
  logic                    STATUS_MXR_INT, STATUS_SUM_INT;
  logic [1:0]              STATUS_FS_INT;
  logic                    BigEndianM_Int;
  logic [P.XLEN-1:0]       STVEC_REGW, MTVEC_REGW;
  logic [P.XLEN-1:0]       MEPC_REGW, SEPC_REGW;
  logic [P.XLEN-1:0]       VSTVEC_REGW, VSEPC_REGW;
  logic [P.XLEN-1:0]       SEPCSelM, STVecSelM;
  logic [31:0]             MCOUNTINHIBIT_REGW, MCOUNTEREN_REGW, SCOUNTEREN_REGW;
  logic                    WriteMSTATUSM, WriteMSTATUSHM, WriteSSTATUSM;
  logic                    CSRMWriteM, CSRSWriteM, CSRUWriteM;
  logic                    UngatedCSRMWriteM;
  logic                    WriteFRMM, SetOrWriteFFLAGSM;
  logic [P.XLEN-1:0]       UnalignedNextEPCM, NextEPCM, NextMtvalM;
  logic [5:0]              NextCauseM;
  logic [11:0]             CSRAdrM_In, CSRAdrM;
  logic                    IllegalCSRCAccessM, IllegalCSRMAccessM, IllegalCSRSAccessM, IllegalCSRUAccessM;
  logic                    InsufficientCSRPrivilegeM;
  logic                    IllegalCSRMWriteReadonlyM;
  logic [P.XLEN-1:0]       CSRReadVal2M;
  logic [11:0]             MIP_REGW_writeable;
  logic [P.XLEN-1:0]       TVecM,NextFaultMtvalM;
  logic                    MTrapM, STrapM;
  logic                    SelMtvecM;
  logic [P.XLEN-1:0]       TVecAlignedM;
  logic                    InstrValidNotFlushedM;
  logic                    STimerInt;
  logic [63:0]             MENVCFG_REGW;
  logic [63:0]             HENVCFG_REGW;
  logic [P.XLEN-1:0]       SENVCFG_REGW;
  logic                    ENVCFG_STCE; // supervisor timer counter enable
  logic                    ENVCFG_FIOM; // fence implies io (presently not used)
  logic                    TrapGVAM;
  logic                    CauseWritesTvalM;
  logic                    VSCSRDirectM;
  logic                    VSSTATUS_SUM, VSSTATUS_MXR, VSSTATUS_UBE;
  logic [1:0]              VSSTATUS_FS;
  logic                    HSTATUS_VSBE;
  logic [31:0]             HCOUNTEREN_REGW;
  logic [11:0]             HVIP_REGW;
  logic [63:0]             HTIMEDELTA_REGW;
  logic                    CSRHWriteM;
  logic [P.XLEN-1:0]       CSRHReadValM;
  logic                    IllegalCSRHAccessM;

  // only valid unflushed instructions can access CSRs
  assign InstrValidNotFlushedM = InstrValidM & ~StallW & ~FlushW;

  ///////////////////////////////////////////
  // MTVAL: gets value from PC, Instruction, or load/store address
  ///////////////////////////////////////////

  always_comb
    if (InterruptM)           NextFaultMtvalM = '0;
    else case (CauseM)
      12, 1, 3:               NextFaultMtvalM = PCSpillM;  // Instruction page/access faults, breakpoint
      2:                      NextFaultMtvalM = {{(P.XLEN-32){1'b0}}, InstrOrigM}; // Illegal instruction fault
      0, 4, 6, 13, 15, 5, 7:  NextFaultMtvalM = IEUAdrxTvalM; // Instruction misaligned, Load/Store Misaligned/page/access faults
      default:                NextFaultMtvalM = '0; // Ecall, interrupts
    endcase

  // Identify traps that write a guest virtual address to {m,s}tval.
  always_comb
    case (CauseM)
      4'd0, 4'd1, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd12, 4'd13, 4'd15: CauseWritesTvalM = 1'b1;
      default: CauseWritesTvalM = 1'b0;
    endcase

  ///////////////////////////////////////////
  // Trap Vectoring & Returns; vectored traps must be aligned to 64-byte address boundaries
  ///////////////////////////////////////////

  // Select trap vector from STVEC/MTVEC (and VSTVEC when H is supported) and word-align
  if (P.H_SUPPORTED) begin: tvec_h
    mux2 #(P.XLEN) stvecselmux(STVEC_REGW, VSTVEC_REGW, TrapToVSM, STVecSelM);
    mux2 #(P.XLEN) tvecmux(STVecSelM, MTVEC_REGW, TrapToM, TVecM);
  end else begin: tvec_noh
    assign SelMtvecM = (NextPrivilegeModeM == P.M_MODE);
    mux2 #(P.XLEN) tvecmux(STVEC_REGW, MTVEC_REGW, SelMtvecM, TVecM);
  end
  assign TVecAlignedM = {TVecM[P.XLEN-1:2], 2'b00};

  // Support vectored interrupts
  if(P.VECTORED_INTERRUPTS_SUPPORTED) begin:vec
    logic VectoredM;
    logic [P.XLEN-1:0] TVecPlusCauseM;
    assign VectoredM = InterruptM & (TVecM[1:0] == 2'b01);
    assign TVecPlusCauseM = {TVecAlignedM[P.XLEN-1:6], CauseM, 2'b00}; // 64-byte alignment allows concatenation rather than addition
    mux2 #(P.XLEN) trapvecmux(TVecAlignedM, TVecPlusCauseM, VectoredM, TrapVectorM);
  end else
    assign TrapVectorM = TVecAlignedM; // unvectored interrupt handler can be at any word-aligned address. This is called Sstvecd

  // Trap Returns
  // A trap sets the PC to TrapVector
  // A return sets the PC to MEPC or SEPC/VSEPC (HS sret uses SPV to pick VSEPC)
  if (P.H_SUPPORTED) begin: epc_h
    logic UseVSEPCM;
    assign UseVSEPCM = VirtModeW | (sretM & (PrivilegeModeW == P.S_MODE) & ~VirtModeW & HSTATUS_SPV);
    mux2 #(P.XLEN) sepcselmux(SEPC_REGW, VSEPC_REGW, UseVSEPCM, SEPCSelM);
    mux2 #(P.XLEN) epcmux(SEPCSelM, MEPC_REGW, mretM, EPCM);
  end else begin: epc_noh
    mux2 #(P.XLEN) epcmux(SEPC_REGW, MEPC_REGW, mretM, EPCM);
  end

  ///////////////////////////////////////////
  // CSRWriteValM
  ///////////////////////////////////////////

  always_comb begin
    // Choose either rs1 or uimm[4:0] as source
    CSRSrcM = InstrM[14] ? {{(P.XLEN-5){1'b0}}, InstrM[19:15]} : SrcAM;

    // CSR set and clear for MIP/SIP should only touch internal state, not interrupt inputs
    if (CSRAdrM == MIP | CSRAdrM == SIP) CSRReadVal2M = {{(P.XLEN-12){1'b0}}, MIP_REGW_writeable};
    else                                 CSRReadVal2M = CSRReadValM;

    // Compute AND/OR modification
    CSRRWM =   CSRSrcM;
    CSRRSM =   CSRReadVal2M | CSRSrcM;
    CSRRCM =   CSRReadVal2M & ~CSRSrcM;
    case (InstrM[13:12])
      2'b01:   CSRWriteValM = CSRRWM;
      2'b10:   CSRWriteValM = CSRRSM;
      2'b11:   CSRWriteValM = CSRRCM;
      default: CSRWriteValM = CSRReadValM;
    endcase
  end

  ///////////////////////////////////////////
  // CSR Write values
  ///////////////////////////////////////////

  assign CSRAdrM_In = InstrM[31:20];
  if (P.H_SUPPORTED) begin: csradr_h
    logic MapVSCSR;
    // In VS-mode, map S-level CSR addresses to the VS CSR space by rewriting [9:8] from 01 to 10.
    assign MapVSCSR = VirtModeW & (PrivilegeModeW == P.S_MODE) & (CSRAdrM_In[9:8] == 2'b01);
    mux2 #(12) csradrmux(CSRAdrM_In, {CSRAdrM_In[11:10], 2'b10, CSRAdrM_In[7:0]}, MapVSCSR, CSRAdrM);
    // Track direct VS CSR accesses while V=1 (virtual-instruction behavior).
    assign VSCSRDirectM = VirtModeW & (CSRAdrM_In[9:8] == 2'b10);
    assign TrapGVAM = TrapM & ExceptionM & VirtModeW & CauseWritesTvalM;
  end else begin: csradr_noh
    assign CSRAdrM = CSRAdrM_In;
    assign VSCSRDirectM = 1'b0;
    assign TrapGVAM = 1'b0;
  end
  assign UnalignedNextEPCM = TrapM ? PCM : CSRWriteValM;
  assign NextEPCM = P.ZCA_SUPPORTED ? {UnalignedNextEPCM[P.XLEN-1:1], 1'b0} : {UnalignedNextEPCM[P.XLEN-1:2], 2'b00}; // 3.1.15 alignment
  assign NextCauseM = TrapM ? {InterruptM, CauseM}: {CSRWriteValM[P.XLEN-1], CSRWriteValM[4:0]};
  assign NextMtvalM = TrapM ? NextFaultMtvalM : CSRWriteValM;
  assign UngatedCSRMWriteM = CSRWriteM & (PrivilegeModeW == P.M_MODE);
  assign CSRMWriteM = UngatedCSRMWriteM & InstrValidNotFlushedM;
  assign CSRSWriteM = CSRWriteM & (|PrivilegeModeW) & InstrValidNotFlushedM;
  assign CSRUWriteM = CSRWriteM  & InstrValidNotFlushedM;
  if (P.H_SUPPORTED) begin: csrhwrite
    assign CSRHWriteM = CSRWriteM & (PrivilegeModeW != P.U_MODE) & InstrValidNotFlushedM;
  end else begin: csrhwrite_noh
    assign CSRHWriteM = 1'b0;
  end
  if (P.H_SUPPORTED) begin: trap_sel_h
    assign MTrapM = TrapM & TrapToM;
    assign STrapM = TrapM & TrapToHSM & P.S_SUPPORTED;
  end else begin: trap_sel_noh
    assign MTrapM = TrapM & (NextPrivilegeModeM == P.M_MODE);
    assign STrapM = TrapM & (NextPrivilegeModeM == P.S_MODE) & P.S_SUPPORTED;
  end

  ///////////////////////////////////////////
  // CSRs
  ///////////////////////////////////////////

  csri #(P) csri(.clk, .reset,
    .CSRMWriteM, .CSRSWriteM, .CSRWriteValM, .CSRAdrM,
    .MExtInt, .SExtInt, .MTimerInt, .STimerInt, .MSwInt,
    .HVIP_REGW,
    .MIDELEG_REGW, .ENVCFG_STCE, .MIP_REGW, .MIE_REGW, .MIP_REGW_writeable);

  csrsr #(P) csrsr(.clk, .reset, .StallW,
    .WriteMSTATUSM, .WriteMSTATUSHM, .WriteSSTATUSM,
    .TrapM, .FRegWriteM, .NextPrivilegeModeM, .PrivilegeModeW, .VirtModeW, .TrapGVAM,
    .mretM, .sretM, .WriteFRMM, .SetOrWriteFFLAGSM, .CSRWriteValM, .SelHPTW,
    .MSTATUS_REGW, .SSTATUS_REGW, .MSTATUSH_REGW,
    .STATUS_MPP, .MSTATUS_MPV, .STATUS_SPP(STATUS_SPP_INT), .STATUS_TSR, .STATUS_TW,
    .STATUS_MIE, .STATUS_SIE(STATUS_SIE_INT), .STATUS_MXR(STATUS_MXR_INT), .STATUS_SUM(STATUS_SUM_INT),
    .STATUS_MPRV, .STATUS_TVM, .STATUS_FS(STATUS_FS_INT), .BigEndianM(BigEndianM_Int));

  csrm #(P) csrm(.clk, .reset,
    .UngatedCSRMWriteM, .CSRMWriteM, .MTrapM, .CSRAdrM,
    .NextEPCM, .NextCauseM, .NextMtvalM, .MSTATUS_REGW, .MSTATUSH_REGW,
    .CSRWriteValM, .CSRMReadValM, .MTVEC_REGW,
    .MEPC_REGW, .MCOUNTEREN_REGW, .MCOUNTINHIBIT_REGW,
    .MEDELEG_REGW, .MIDELEG_REGW,.PMPCFG_ARRAY_REGW, .PMPADDR_ARRAY_REGW,
    .MIP_REGW, .MIE_REGW, .WriteMSTATUSM, .WriteMSTATUSHM,
    .IllegalCSRMAccessM, .IllegalCSRMWriteReadonlyM,
    .MENVCFG_REGW);


  if (P.S_SUPPORTED) begin:csrs
    logic STCE;
    assign STCE = P.SSTC_SUPPORTED & (PrivilegeModeW == P.M_MODE | (MCOUNTEREN_REGW[1] & ENVCFG_STCE));
    csrs #(P) csrs(.clk, .reset,
      .CSRSWriteM, .STrapM, .CSRAdrM,
      .NextEPCM, .NextCauseM, .NextMtvalM, .SSTATUS_REGW,
      .STATUS_TVM,
      .CSRWriteValM, .PrivilegeModeW,
      .CSRSReadValM, .STVEC_REGW, .SEPC_REGW,
      .SCOUNTEREN_REGW,
      .SATP_REGW, .MIP_REGW, .MIE_REGW, .MIDELEG_REGW, .MTIME_CLINT, .STCE,
      .WriteSSTATUSM, .IllegalCSRSAccessM, .STimerInt, .SENVCFG_REGW);
  end else begin
    assign WriteSSTATUSM = 1'b0;
    assign CSRSReadValM = '0;
    assign SEPC_REGW = '0;
    assign STVEC_REGW = '0;
    assign SCOUNTEREN_REGW = '0;
    assign SATP_REGW = '0;
    assign IllegalCSRSAccessM = 1'b1;
    assign STimerInt = '0;
    assign SENVCFG_REGW = '0;
  end

  if (P.H_SUPPORTED) begin:csrh
    csrh #(P) csrh(.clk, .reset,
      .CSRHWriteM, .CSRWriteM, .CSRAdrM, .CSRWriteValM,
      .PrivilegeModeW, .VirtModeW, .FRegWriteM, .WriteFRMM, .SetOrWriteFFLAGSM,
      .TrapGVAM, .VSCSRDirectM, .MIP_REGW,
      .TrapM, .TrapToHSM, .TrapToVSM, .sretM, .InstrM,
      .NextEPCM, .NextCauseM, .NextMtvalM, .NextHtvalM(NextMtvalM),
      .CSRHReadValM, .IllegalCSRHAccessM,
      .HSTATUS_SPV, .HSTATUS_VTSR, .HSTATUS_VTW, .HSTATUS_VTVM,
      .HSTATUS_VSBE, .VSSTATUS_SPP, .VSSTATUS_SUM, .VSSTATUS_MXR, .VSSTATUS_UBE, .VSSTATUS_FS,
      .HEDELEG_REGW, .HIDELEG_REGW, .HCOUNTEREN_REGW, .HVIP_REGW, .HTIMEDELTA_REGW, .HENVCFG_REGW,
      .VSTVEC_REGW, .VSEPC_REGW);
  end else begin: no_csrh
    assign CSRHReadValM = '0;
    assign IllegalCSRHAccessM = 1'b1;
    assign HSTATUS_SPV = 1'b0;
    assign HSTATUS_VTSR = 1'b0;
    assign HSTATUS_VTW = 1'b0;
    assign HSTATUS_VTVM = 1'b0;
    assign HSTATUS_VSBE = 1'b0;
    assign VSSTATUS_SPP = 1'b0;
    assign VSSTATUS_SUM = 1'b0;
    assign VSSTATUS_MXR = 1'b0;
    assign VSSTATUS_UBE = 1'b0;
    assign VSSTATUS_FS = '0;
    assign HEDELEG_REGW = '0;
    assign HIDELEG_REGW = '0;
    assign HCOUNTEREN_REGW = '0;
    assign HVIP_REGW = '0;
    assign HTIMEDELTA_REGW = '0;
    assign HENVCFG_REGW = '0;
    assign VSTVEC_REGW = '0;
    assign VSEPC_REGW = '0;
  end

  // Effective status bits for VS-mode
  assign STATUS_SPP = STATUS_SPP_INT;
  assign STATUS_SIE = STATUS_SIE_INT;
  if (P.H_SUPPORTED) begin: status_vs
    assign STATUS_MXR = VirtModeW ? VSSTATUS_MXR : STATUS_MXR_INT;
    assign STATUS_SUM = VirtModeW ? VSSTATUS_SUM : STATUS_SUM_INT;
    assign STATUS_FS  = VirtModeW ? VSSTATUS_FS : STATUS_FS_INT;
  end else begin: status_noh
    assign STATUS_MXR = STATUS_MXR_INT;
    assign STATUS_SUM = STATUS_SUM_INT;
    assign STATUS_FS  = STATUS_FS_INT;
  end

  if (P.BIGENDIAN_SUPPORTED) begin: endian
    if (P.H_SUPPORTED) begin: endian_h
      logic BigEndianVirtM;
      assign BigEndianVirtM = (PrivilegeModeW == P.S_MODE) ? HSTATUS_VSBE : VSSTATUS_UBE;
      mux2 #(1) bigendianmux(BigEndianM_Int, BigEndianVirtM, VirtModeW & ~SelHPTW, BigEndianM);
    end else begin: endian_noh
      assign BigEndianM = BigEndianM_Int;
    end
  end else begin: endian_n
    assign BigEndianM = 1'b0;
  end

  // Floating Point CSRs in User Mode only needed if Floating Point is supported
  if (P.F_SUPPORTED) begin:csru
    csru #(P) csru(.clk, .reset, .InstrValidNotFlushedM,
      .CSRUWriteM, .CSRAdrM, .CSRWriteValM, .STATUS_FS, .CSRUReadValM,
      .SetFflagsM, .FRM_REGW, .WriteFRMM, .SetOrWriteFFLAGSM,
      .IllegalCSRUAccessM);
  end else begin
    assign FRM_REGW = '0;
    assign CSRUReadValM = '0;
    assign IllegalCSRUAccessM = 1'b1;
    assign WriteFRMM = 1'b0;
    assign SetOrWriteFFLAGSM = 1'b0;
  end

  if (P.ZICNTR_SUPPORTED) begin:counters
    csrc #(P) counters(.clk, .reset, .StallE, .StallM, .FlushM,
      .InstrValidNotFlushedM, .LoadStallD, .StoreStallD, .CSRWriteM, .CSRMWriteM,
      .BPDirWrongM, .BTAWrongM, .RASPredPCWrongM, .IClassWrongM, .BPWrongM,
      .IClassM, .DCacheMiss, .DCacheAccess, .ICacheMiss, .ICacheAccess, .sfencevmaM,
      .InterruptM, .ExceptionM, .InvalidateICacheM, .ICacheStallF, .DCacheStallM, .DivBusyE, .FDivBusyE,
      .CSRAdrM, .PrivilegeModeW, .VirtModeW, .CSRWriteValM,
      .MCOUNTINHIBIT_REGW, .MCOUNTEREN_REGW, .SCOUNTEREN_REGW, .HCOUNTEREN_REGW,
      .MTIME_CLINT, .HTIMEDELTA_REGW,  .CSRCReadValM, .IllegalCSRCAccessM);
  end else begin
    assign CSRCReadValM = '0;
    assign IllegalCSRCAccessM = 1'b1; // counters aren't enabled
  end

   // Broadcast appropriate environment configuration based on privilege mode
  assign ENVCFG_STCE =  (P.H_SUPPORTED & VirtModeW) ? HENVCFG_REGW[63] : MENVCFG_REGW[63]; // supervisor timer counter enable
  assign ENVCFG_PBMTE = (P.H_SUPPORTED & VirtModeW) ? HENVCFG_REGW[62] : MENVCFG_REGW[62]; // page-based memory types enable
  assign ENVCFG_ADUE  = (P.H_SUPPORTED & VirtModeW) ? HENVCFG_REGW[61] : MENVCFG_REGW[61]; // Hardware A/D Update enable
  assign ENVCFG_CBE =   (PrivilegeModeW == P.M_MODE) ? 4'b1111 :
                        (PrivilegeModeW == P.S_MODE | !P.S_SUPPORTED) ? ((P.H_SUPPORTED & VirtModeW) ? HENVCFG_REGW[7:4] : MENVCFG_REGW[7:4]) :
                                                                       (((P.H_SUPPORTED & VirtModeW) ? HENVCFG_REGW[7:4] : MENVCFG_REGW[7:4]) & SENVCFG_REGW[7:4]);
  // FIOM presently doesn't do anything because Wally fences don't do anything
  assign ENVCFG_FIOM =  (PrivilegeModeW == P.M_MODE) ? 1'b1 :
                        (PrivilegeModeW == P.S_MODE | !P.S_SUPPORTED) ? ((P.H_SUPPORTED & VirtModeW) ? HENVCFG_REGW[0] : MENVCFG_REGW[0]) :
                                                                       (((P.H_SUPPORTED & VirtModeW) ? HENVCFG_REGW[0] : MENVCFG_REGW[0]) & SENVCFG_REGW[0]);

  // merge CSR Reads
  assign CSRReadValM = CSRUReadValM | CSRSReadValM | CSRMReadValM | CSRCReadValM | CSRHReadValM;
  flopenrc #(P.XLEN) CSRValWReg(clk, reset, FlushW, ~StallW, CSRReadValM, CSRReadValW);

  // merge illegal accesses: illegal if none of the CSR addresses is legal or privilege is insufficient
  assign InsufficientCSRPrivilegeM = (CSRAdrM[9:8] == 2'b11 & PrivilegeModeW != P.M_MODE) |
                                     (CSRAdrM[9:8] == 2'b01 & PrivilegeModeW == P.U_MODE);
  assign IllegalCSRAccessM = ((IllegalCSRCAccessM & IllegalCSRMAccessM &
    IllegalCSRSAccessM & IllegalCSRUAccessM & IllegalCSRHAccessM |
    InsufficientCSRPrivilegeM) & CSRReadM) | IllegalCSRMWriteReadonlyM;
endmodule
