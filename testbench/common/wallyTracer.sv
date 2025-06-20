///////////////////////////////////////////
// wallyTracer.sv
//
// A component of the Wally configurable RISC-V project.
// Implements a RISC-V Verification Interface (RVVI)
// to support functional coverage and lockstep simulation.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
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

`define STD_LOG 0
`define PRINT_PC_INSTR 0
`define PRINT_MOST 0
`define PRINT_ALL 0
`define PRINT_CSRS 0

// Since we are detecting the CSR change by comparing the old value, we need to
// ensure the CSR is detected when the pipeline's Writeback stage is not
// stalled.  If it is stalled we want to hold the old value.
`define CONNECT_CSR(name, addr, val) \
  logic [P.XLEN-1:0] prev_csr_``name; \
  always_ff @(posedge clk) \
    prev_csr_``name <= rvvi.csr[0][0][addr]; \
  assign rvvi.csr_wb[0][0][addr] = (rvvi.csr[0][0][addr] != prev_csr_``name); \
  assign rvvi.csr[0][0][addr] = valid ? val : prev_csr_``name;

module wallyTracer import cvw::*; #(parameter cvw_t P) (rvviTrace rvvi);

  localparam NUM_REGS = P.E_SUPPORTED ? 16 : 32;
  localparam NUM_CSRS = 4096;
  
  // wally specific signals
  logic                  reset;
  logic                  clk;
  logic                  InstrValidD, InstrValidE;
  logic                  StallF, StallD;
  logic                  STATUS_SXL, STATUS_UXL;
  logic [P.XLEN-1:0]     PCNextF, PCF, PCD, PCE, PCM, PCW;
  logic [31:0]           InstrRawD, InstrRawE, InstrRawM, InstrRawW;
  logic                  InstrValidM, InstrValidW;
  logic                  StallE, StallM, StallW;
  logic                  GatedStallW;
  logic                  SelHPTW;
  logic                  FlushD, FlushE, FlushM, FlushW;
  logic                  TrapM, TrapW;
  logic                  HaltM, HaltW;
  logic [1:0]            PrivilegeModeW;
  logic [P.XLEN-1:0]     rf[NUM_REGS];
  logic [NUM_REGS-1:0]   rf_wb;
  logic [4:0]            rf_a3;
  logic                  rf_we3;
  logic [P.FLEN-1:0]     frf[32];
  logic [31:0]           frf_wb;
  logic [4:0]            frf_a4;
  logic                  frf_we4;
  logic                  CSRWriteM, CSRWriteW;
  logic [11:0]           CSRAdrM, CSRAdrW;
  logic                  wfiM;
  logic                  InterruptM, InterruptW;
  logic                  MExtInt, SExtInt, MTimerInt, MSwInt;
  logic                  valid;

  //For VM Verification
  logic [(P.XLEN-1):0]     IVAdrF,IVAdrD,IVAdrE,IVAdrM,IVAdrW,DVAdrM,DVAdrW;
  logic [(P.XLEN-1):0]     IPTEF,IPTED,IPTEE,IPTEM,IPTEW,DPTEM,DPTEW;
  logic [(P.PA_BITS-1):0]  IPAF,IPAD,IPAE,IPAM,IPAW,DPAM,DPAW;
  logic [(P.PPN_BITS-1):0] IPPNF,IPPND,IPPNE,IPPNM,IPPNW,DPPNM,DPPNW;
  logic [1:0]              IPageTypeF, IPageTypeD, IPageTypeE, IPageTypeM, IPageTypeW, DPageTypeM, DPageTypeW;
  logic                    ReadAccessM,WriteAccessM,ReadAccessW,WriteAccessW;
  logic                    ExecuteAccessF,ExecuteAccessD,ExecuteAccessE,ExecuteAccessM,ExecuteAccessW;
  logic [P.XLEN-1:0]       order;

  assign clk = testbench.dut.clk;
  //  assign InstrValidF = testbench.dut.core.ieu.InstrValidF;  // not needed yet
  assign InstrValidD    = testbench.dut.core.ieu.c.InstrValidD;
  assign InstrValidE    = testbench.dut.core.ieu.c.InstrValidE;
  assign InstrValidM    = testbench.dut.core.ieu.InstrValidM;
  assign InstrRawD      = testbench.dut.core.ifu.InstrRawD;
  assign PCNextF        = testbench.dut.core.ifu.PCNextF;
  assign PCF            = testbench.dut.core.ifu.PCF;
  assign PCD            = testbench.dut.core.ifu.PCD;
  assign PCE            = testbench.dut.core.ifu.PCE;
  assign PCM            = testbench.dut.core.ifu.PCM;
  assign reset          = testbench.reset;
  assign StallF         = testbench.dut.core.StallF;
  assign StallD         = testbench.dut.core.StallD;
  assign StallE         = testbench.dut.core.StallE;
  assign StallM         = testbench.dut.core.StallM;
  assign StallW         = testbench.dut.core.StallW;
  assign GatedStallW    = testbench.dut.core.lsu.GatedStallW;
  assign FlushD         = testbench.dut.core.FlushD;
  assign FlushE         = testbench.dut.core.FlushE;
  assign FlushM         = testbench.dut.core.FlushM;
  assign FlushW         = testbench.dut.core.FlushW;
  assign TrapM          = testbench.dut.core.TrapM;
  assign HaltM          = testbench.DCacheFlushStart;
  if (P.ZICSR_SUPPORTED) begin
    assign PrivilegeModeW = testbench.dut.core.priv.priv.privmode.PrivilegeModeW;
    assign STATUS_SXL     = testbench.dut.core.priv.priv.csr.csrsr.STATUS_SXL;
    assign STATUS_UXL     = testbench.dut.core.priv.priv.csr.csrsr.STATUS_UXL;
    assign wfiM           = testbench.dut.core.priv.priv.wfiM;
    assign InterruptM     = testbench.dut.core.priv.priv.InterruptM;
    assign MExtInt        = testbench.dut.MExtInt;
    assign SExtInt        = testbench.dut.SExtInt;
    assign MTimerInt      = testbench.dut.MTimerInt;
    assign MSwInt         = testbench.dut.MSwInt;
  end else begin
    assign PrivilegeModeW = 2'b11;
    assign STATUS_SXL     = 0;
    assign STATUS_UXL     = 0;
    assign wfiM           = 0;
    assign InterruptM     = 0;
    assign MExtInt        = 0;
    assign SExtInt        = 0;
    assign MTimerInt      = 0;
    assign MSwInt         = 0;
  end

  //For VM Verification
  if (P.VIRTMEM_SUPPORTED) begin
    assign SelHPTW        = testbench.dut.core.lsu.hptw.hptw.SelHPTW;
    assign IVAdrF         = testbench.dut.core.ifu.immu.immu.tlb.tlb.VAdr;
    assign DVAdrM         = testbench.dut.core.lsu.dmmu.dmmu.tlb.tlb.VAdr;
    assign IPAF           = testbench.dut.core.ifu.immu.immu.PhysicalAddress;
    assign DPAM           = testbench.dut.core.lsu.dmmu.dmmu.PhysicalAddress;
    assign ReadAccessM    = testbench.dut.core.lsu.dmmu.dmmu.ReadAccessM;
    assign WriteAccessM   = testbench.dut.core.lsu.dmmu.dmmu.WriteAccessM;
    assign ExecuteAccessF = testbench.dut.core.ifu.immu.immu.ExecuteAccessF;
    assign IPTEF          = testbench.dut.core.ifu.immu.immu.PTE;
    assign DPTEM          = testbench.dut.core.lsu.dmmu.dmmu.PTE;
    assign IPPNF          = testbench.dut.core.ifu.immu.immu.tlb.tlb.PPN;
    assign DPPNM          = testbench.dut.core.lsu.dmmu.dmmu.tlb.tlb.PPN; 
    assign IPageTypeF     = testbench.dut.core.ifu.immu.immu.PageTypeWriteVal;
    assign DPageTypeM     = testbench.dut.core.lsu.dmmu.dmmu.PageTypeWriteVal;
  end else begin
    assign SelHPTW        = 1'b0;
    assign IVAdrF         = 0;
    assign DVAdrM         = 0;
    assign IPAF           = 0;
    assign DPAM           = 0;
    assign ReadAccessM    = 0;
    assign WriteAccessM   = 0;
    assign ExecuteAccessF = 0;
    assign IPTEF          = 0;
    assign DPTEM          = 0;
    assign IPPNF          = 0;
    assign DPPNM          = 0;
    assign IPageTypeF     = 0;
    assign DPageTypeM     = 0;
  end


  // CSR connections
  if (P.ZICSR_SUPPORTED) begin
    // M-mode trap CSRs
    `CONNECT_CSR(MSTATUS, 12'h300, testbench.dut.core.priv.priv.csr.csrm.MSTATUS_REGW);
    `CONNECT_CSR(MEDELEG, 12'h302, testbench.dut.core.priv.priv.csr.csrm.MEDELEG_REGW);
    `CONNECT_CSR(MIDELEG, 12'h303, testbench.dut.core.priv.priv.csr.csrm.MIDELEG_REGW);
    `CONNECT_CSR(MIE, 12'h304, testbench.dut.core.priv.priv.csr.csrm.MIE_REGW);
    `CONNECT_CSR(MTVEC, 12'h305, testbench.dut.core.priv.priv.csr.csrm.MTVEC_REGW);
    `CONNECT_CSR(MSCRATCH, 12'h340, testbench.dut.core.priv.priv.csr.csrm.MSCRATCH_REGW);
    `CONNECT_CSR(MEPC, 12'h341, testbench.dut.core.priv.priv.csr.csrm.MEPC_REGW);
    `CONNECT_CSR(MCAUSE, 12'h342, testbench.dut.core.priv.priv.csr.csrm.MCAUSE_REGW);
    `CONNECT_CSR(MTVAL, 12'h343, testbench.dut.core.priv.priv.csr.csrm.MTVAL_REGW);
    `CONNECT_CSR(MIP, 12'h344, testbench.dut.core.priv.priv.csr.csrm.MIP_REGW);

    // S-mode trap CSRs
    if (P.S_SUPPORTED) begin
      `CONNECT_CSR(SSTATUS, 12'h100, testbench.dut.core.priv.priv.csr.csrs.csrs.SSTATUS_REGW);
      `CONNECT_CSR(SIE, 12'h104, testbench.dut.core.priv.priv.csr.csrm.MIE_REGW & 12'h222 & testbench.dut.core.priv.priv.csr.csrm.MIDELEG_REGW);
      `CONNECT_CSR(STVEC, 12'h105, testbench.dut.core.priv.priv.csr.csrs.csrs.STVEC_REGW);
      `CONNECT_CSR(SSCRATCH, 12'h140, testbench.dut.core.priv.priv.csr.csrs.csrs.SSCRATCH_REGW);
      `CONNECT_CSR(SEPC, 12'h141, testbench.dut.core.priv.priv.csr.csrs.csrs.SEPC_REGW);
      `CONNECT_CSR(SCAUSE, 12'h142, testbench.dut.core.priv.priv.csr.csrs.csrs.SCAUSE_REGW);
      `CONNECT_CSR(STVAL, 12'h143, testbench.dut.core.priv.priv.csr.csrs.csrs.STVAL_REGW);
      `CONNECT_CSR(SIP, 12'h144, testbench.dut.core.priv.priv.csr.csrm.MIP_REGW & 12'h222 & testbench.dut.core.priv.priv.csr.csrm.MIDELEG_REGW);
    end

    // Virtual Memory CSRs
    if (P.VIRTMEM_SUPPORTED) begin
      `CONNECT_CSR(SATP, 12'h180, testbench.dut.core.priv.priv.csr.csrs.csrs.SATP_REGW);
    end

    // Floating-Point CSRs
    if (P.F_SUPPORTED) begin
      `CONNECT_CSR(FFLAGS, 12'h001, testbench.dut.core.priv.priv.csr.csru.csru.FFLAGS_REGW);
      `CONNECT_CSR(FRM, 12'h002, testbench.dut.core.priv.priv.csr.csru.csru.FRM_REGW);
      `CONNECT_CSR(FCSR, 12'h003, {testbench.dut.core.priv.priv.csr.csru.csru.FRM_REGW, testbench.dut.core.priv.priv.csr.csru.csru.FFLAGS_REGW});
    end

    // Counters / Performance Monitoring CSRs
    if (P.U_SUPPORTED) begin
      `CONNECT_CSR(MCOUNTEREN, 12'h306, testbench.dut.core.priv.priv.csr.csrm.MCOUNTEREN_REGW);
    end
    if (P.S_SUPPORTED) begin
      `CONNECT_CSR(SCOUNTEREN, 12'h106, testbench.dut.core.priv.priv.csr.csrs.csrs.SCOUNTEREN_REGW);
    end
    `CONNECT_CSR(MCOUNTINHIBIT, 12'h320, testbench.dut.core.priv.priv.csr.csrm.MCOUNTINHIBIT_REGW);
    // mhpmevent3-31 not connected (232-33F)
    if (P.ZICNTR_SUPPORTED) begin
      `CONNECT_CSR(MCYCLE, 12'hB00, testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[0]); // MCYCLE
      `CONNECT_CSR(MINSTRET, 12'hB02, testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[2]); // MINSTRET
      // mhpmcounter3-31 not connected (B03-B1F)
      // cycle, time, instret not connected (C00-C02)
      // hpmcounter3-31 not connected (C03-C1F)
    end

    // Machine Information Registers and Configuration CSRs
    `CONNECT_CSR(MISA, 12'h301, testbench.dut.core.priv.priv.csr.csrm.MISA_REGW);
    `CONNECT_CSR(MENVCFG, 12'h30A, testbench.dut.core.priv.priv.csr.csrm.MENVCFG_REGW);
    `CONNECT_CSR(MSECCFG, 12'h747, 0); // mseccfg
    `CONNECT_CSR(MVENDORID, 12'hF11, 0); //mvendorid
    `CONNECT_CSR(MARCHID, 12'hF12, 0); // marchid
    `CONNECT_CSR(MIMPID, 12'hF13, {{P.XLEN-12{1'b0}}, 12'h100}); // mimpid
    `CONNECT_CSR(MHARTID, 12'hF14, testbench.dut.core.priv.priv.csr.csrm.MHARTID_REGW);
    `CONNECT_CSR(MCONFIGPTR, 12'hF15, 0); //mconfigptr

    // Supervisor Information Registers and Configuration CSRs
    if (P.S_SUPPORTED) begin
      `CONNECT_CSR(SENVCFG, 12'h10A, testbench.dut.core.priv.priv.csr.csrs.csrs.SENVCFG_REGW);
    end

    // Sstc CSRs
    if (P.SSTC_SUPPORTED) begin
      `CONNECT_CSR(STIMECMP, 12'h14D, testbench.dut.core.priv.priv.csr.csrs.csrs.STIMECMP_REGW[P.XLEN-1:0]);
      if (P.XLEN == 32) begin
        `CONNECT_CSR(STIMECMPH, 12'h15D, testbench.dut.core.priv.priv.csr.csrs.csrs.STIMECMP_REGW[63:32]);
      end
    end
    
    // Zkr CSRs
    // seed not connected (015)

    // extra M mode CSRs for RV32
    if (P.XLEN == 32) begin
      `CONNECT_CSR(MSTATUSH, 12'h310, testbench.dut.core.priv.priv.csr.csrsr.MSTATUSH_REGW);
      `CONNECT_CSR(MENVCFGH, 12'h31A, testbench.dut.core.priv.priv.csr.csrm.MENVCFGH_REGW);
      `CONNECT_CSR(MSECCFGH, 12'h757, 0); // mseccfgh
    end
  end

  if (P.PMP_ENTRIES > 0) begin
    localparam inc = P.XLEN == 32 ? 4 : 8;
    // PMPCFG CSRs (space is 0-15 3a0 - 3af)
    for (genvar pmpCfgID = 0; pmpCfgID < P.PMP_ENTRIES; pmpCfgID += inc) begin
      logic [P.XLEN-1:0] pmp;
      localparam int i4 = pmpCfgID / 4;
      if (P.XLEN == 32) begin
        // For RV32, only access 4 entries
        assign pmp = {testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+3],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+2],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+1],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+0]};
      end else begin
        // For RV64, access all 8 entries
        assign pmp = {testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+7],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+6],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+5],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+4],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+3],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+2],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+1],
                      testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[pmpCfgID+0]};
      end
      `CONNECT_CSR(PMPCFG``i4, 12'h3A0 + i4, pmp);
    end

  // PMPADDR CSRs 3B0 to 3EF
    for(genvar pmpAddrID = 0; pmpAddrID < P.PMP_ENTRIES; pmpAddrID++) begin
      `CONNECT_CSR(PMPADDR``pmpAddrID, 12'h3B0 + pmpAddrID, testbench.dut.core.priv.priv.csr.csrm.PMPADDR_ARRAY_REGW[pmpAddrID]); // aligned to grain
    end
  end

  // Integer register file
  assign rf[0] = 0;
  for(genvar index = 1; index < NUM_REGS; index += 1) 
    assign rf[index] = testbench.dut.core.ieu.dp.regf.rf[index];

  assign rf_a3  = testbench.dut.core.ieu.dp.regf.a3;
  assign rf_we3 = testbench.dut.core.ieu.dp.regf.we3;

  always_comb begin
    rf_wb <= 0;
    if(rf_we3)
      rf_wb[rf_a3] <= 1'b1;
  end

  // Floating-point register file
  if (P.F_SUPPORTED) begin
    assign frf_a4  = testbench.dut.core.fpu.fpu.fregfile.a4;
    assign frf_we4 = testbench.dut.core.fpu.fpu.fregfile.we4;
    for(genvar index = 0; index < 32; index += 1) 
      assign frf[index] = testbench.dut.core.fpu.fpu.fregfile.rf[index];
  end else begin
    assign frf_a4  = '0;
    assign frf_we4 = 0;
    for(genvar index = 0; index < 32; index += 1) 
      assign frf[index] = '0;
  end

  always_comb begin
    frf_wb <= 0;
    if(frf_we4)
      frf_wb[frf_a4] <= 1'b1;
  end

  // CSR writes
  assign CSRAdrM  = testbench.dut.core.priv.priv.csr.CSRAdrM;
  assign CSRWriteM = testbench.dut.core.priv.priv.csr.CSRWriteM;
  
  // pipeline to writeback stage
  flopenrc #(32)    InstrRawEReg (clk, reset, FlushE, ~StallE, InstrRawD, InstrRawE);
  flopenrc #(32)    InstrRawMReg (clk, reset, FlushM, ~StallM, InstrRawE, InstrRawM);
  flopenrc #(32)    InstrRawWReg (clk, reset, FlushW & ~TrapM, ~StallW, InstrRawM, InstrRawW);
  flopenrc #(P.XLEN)PCWReg       (clk, reset, FlushW & ~TrapM, ~StallW, PCM, PCW);
  flopenrc #(1)     InstrValidMReg (clk, reset, FlushW & ~TrapM, ~StallW, InstrValidM, InstrValidW);
  flopenrc #(1)     TrapWReg (clk, reset, 1'b0, ~StallW, TrapM, TrapW);
  flopenrc #(1)     InterruptWReg (clk, reset, 1'b0, ~StallW, InterruptM, InterruptW);
  flopenrc #(1)     HaltWReg (clk, reset, 1'b0, ~StallW, HaltM, HaltW);

  flopenrc #(12)    CSRAdrWReg (clk, reset, FlushW, ~StallW, CSRAdrM, CSRAdrW);
  flopenrc #(1)     CSRWriteWReg (clk, reset, FlushW, ~StallW, CSRWriteM, CSRWriteW);

  //for VM Verification
  flopenrc #(P.XLEN)     IVAdrDReg (clk, reset, 1'b0, SelHPTW, IVAdrF, IVAdrD); //Virtual Address for IMMU // *** RT: possible bug SelHPTW probably should be ~StallD
  flopenrc #(P.XLEN)     IVAdrEReg (clk, reset, 1'b0, ~StallE, IVAdrD, IVAdrE); //Virtual Address for IMMU
  flopenrc #(P.XLEN)     IVAdrMReg (clk, reset, 1'b0, ~(StallM & ~SelHPTW), IVAdrE, IVAdrM); //Virtual Address for IMMU
  flopenrc #(P.XLEN)     IVAdrWReg (clk, reset, 1'b0, SelHPTW, IVAdrM, IVAdrW); //Virtual Address for IMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW
  flopenrc #(P.XLEN)     DVAdrWReg (clk, reset, 1'b0, SelHPTW, DVAdrM, DVAdrW); //Virtual Address for DMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW

  flopenrc #(P.PA_BITS)  IPADReg (clk, reset, 1'b0, SelHPTW, IPAF, IPAD); //Physical Address for IMMU // *** RT: possible bug SelHPTW probably should be ~StallD
  flopenrc #(P.PA_BITS)  IPAEReg (clk, reset, 1'b0, ~StallE, IPAD, IPAE); //Physical Address for IMMU
  flopenrc #(P.PA_BITS)  IPAMReg (clk, reset, 1'b0, ~(StallM & ~SelHPTW), IPAE, IPAM); //Physical Address for IMMU
  flopenrc #(P.PA_BITS)  IPAWReg (clk, reset, 1'b0, SelHPTW, IPAM, IPAW); //Physical Address for IMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW
  flopenrc #(P.PA_BITS)  DPAWReg (clk, reset, 1'b0, SelHPTW, DPAM, DPAW); //Physical Address for DMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW

  flopenrc #(P.XLEN)     IPTEDReg (clk, reset, 1'b0, SelHPTW, IPTEF, IPTED); //PTE for IMMU // *** RT: possible bug SelHPTW probably should be ~StallD
  flopenrc #(P.XLEN)     IPTEEReg (clk, reset, 1'b0, ~StallE, IPTED, IPTEE); //PTE for IMMU
  flopenrc #(P.XLEN)     IPTEMReg (clk, reset, 1'b0, ~(StallM & ~SelHPTW), IPTEE, IPTEM); //PTE for IMMU
  flopenrc #(P.XLEN)     IPTEWReg (clk, reset, 1'b0, SelHPTW, IPTEM, IPTEW); //PTE for IMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW
  flopenrc #(P.XLEN)     DPTEWReg (clk, reset, 1'b0, SelHPTW, DPTEM, DPTEW); //PTE for DMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW

  flopenrc #(2)     IPageTypeDReg (clk, reset, 1'b0, SelHPTW, IPageTypeF, IPageTypeD); //PageType (kilo, mega, giga, tera) from IMMU // *** RT: possible bug SelHPTW probably should be ~StallD
  flopenrc #(2)     IPageTypeEReg (clk, reset, 1'b0, ~StallE, IPageTypeD, IPageTypeE); //PageType (kilo, mega, giga, tera) from IMMU
  flopenrc #(2)     IPageTypeMReg (clk, reset, 1'b0, ~(StallM & ~SelHPTW), IPageTypeE, IPageTypeM); //PageType (kilo, mega, giga, tera) from IMMU
  flopenrc #(2)     IPageTypeWReg (clk, reset, 1'b0, SelHPTW, IPageTypeM, IPageTypeW); //PageType (kilo, mega, giga, tera) from IMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW
  flopenrc #(2)     DPageTypeWReg (clk, reset, 1'b0, SelHPTW, DPageTypeM, DPageTypeW); //PageType (kilo, mega, giga, tera) from DMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW

  flopenrc #(P.PPN_BITS) IPPNDReg (clk, reset, 1'b0, ~StallD, IPPNF, IPPND); //Physical Page Number for IMMU
  flopenrc #(P.PPN_BITS) IPPNEReg (clk, reset, 1'b0, ~StallE, IPPND, IPPNE); //Physical Page Number for IMMU
  flopenrc #(P.PPN_BITS) IPPNMReg (clk, reset, 1'b0, ~StallM, IPPNE, IPPNM); //Physical Page Number for IMMU
  flopenrc #(P.PPN_BITS) IPPNWReg (clk, reset, 1'b0, ~StallW, IPPNM, IPPNW); //Physical Page Number for IMMU
  flopenrc #(P.PPN_BITS) DPPNWReg (clk, reset, 1'b0, ~StallW, DPPNM, DPPNW); //Physical Page Number for DMMU

  flopenrc #(1)  ReadAccessWReg    (clk, reset, 1'b0, ~GatedStallW, ReadAccessM, ReadAccessW);   //LoadAccess
  flopenrc #(1)  WriteAccessWReg   (clk, reset, 1'b0, ~GatedStallW, WriteAccessM, WriteAccessW); //StoreAccess

  flopenrc #(1)  ExecuteAccessDReg (clk, reset, 1'b0, ~StallD, ExecuteAccessF, ExecuteAccessD); //Instruction Fetch Access
  flopenrc #(1)  ExecuteAccessEReg (clk, reset, 1'b0, ~StallE, ExecuteAccessD, ExecuteAccessE); //Instruction Fetch Access
  flopenrc #(1)  ExecuteAccessMReg (clk, reset, 1'b0, ~StallM, ExecuteAccessE, ExecuteAccessM); //Instruction Fetch Access
  flopenrc #(1)  ExecuteAccessWReg (clk, reset, 1'b0, ~StallW, ExecuteAccessM, ExecuteAccessW); //Instruction Fetch Access

  // Initially connecting the writeback stage signals, but may need to use M stage
  // and gate on ~FlushW.


  // count the number of valid instructions to provide ordering to RVVI tracer
  always @(posedge clk)
    if (reset) order <= 0;
    else if (valid) order <= order + 1;

  assign valid  = ((InstrValidW | TrapW) & ~StallW) & ~reset;
  assign rvvi.clk = clk;
  assign rvvi.valid[0][0]    = valid;
  assign rvvi.order[0][0]    = order; 
  assign rvvi.insn[0][0]     = InstrRawW;
  assign rvvi.pc_rdata[0][0] = PCW;
  assign rvvi.trap[0][0]     = TrapW;
  assign rvvi.halt[0][0]     = HaltW;
  assign rvvi.intr[0][0]     = InterruptW;
  assign rvvi.mode[0][0]     = PrivilegeModeW;
  assign rvvi.ixl[0][0]      = PrivilegeModeW == 2'b11 ? 2'b10 :
                               PrivilegeModeW == 2'b01 ? STATUS_SXL : STATUS_UXL;
  assign rvvi.pc_wdata[0][0] = ~FlushW ? PCM :
                               ~FlushM ? PCE :
                               ~FlushE ? PCD :
                               ~FlushD ? PCF : PCNextF;

  for(genvar index = 0; index < NUM_REGS; index += 1) begin
    assign rvvi.x_wdata[0][0][index] = rf[index];
    assign rvvi.x_wb[0][0][index]    = rf_wb[index];
  end
  for(genvar index = 0; index < 32; index += 1) begin
    assign rvvi.f_wdata[0][0][index] = frf[index];
    assign rvvi.f_wb[0][0][index]    = frf_wb[index];
  end

`ifdef FCOV
  // Interrupts
  assign rvvi.m_ext_intr[0][0]   = MExtInt;
  assign rvvi.s_ext_intr[0][0]   = SExtInt;
  assign rvvi.m_timer_intr[0][0] = MTimerInt;
  assign rvvi.m_soft_intr[0][0]  = MSwInt;
`endif

  // *** implementation only cancel? so sc does not clear?
  assign rvvi.lrsc_cancel[0][0] = 0;

`ifdef FCOV
  // Virtual Memory signals for verification
  assign rvvi.virt_adr_i[0][0]     = IVAdrW;
  assign rvvi.virt_adr_d[0][0]     = DVAdrW;
  assign rvvi.phys_adr_i[0][0]     = IPAW;
  assign rvvi.phys_adr_d[0][0]     = DPAW;
  assign rvvi.read_access[0][0]    = ReadAccessW;
  assign rvvi.write_access[0][0]   = WriteAccessW;
  assign rvvi.execute_access[0][0] = ExecuteAccessW;
  assign rvvi.pte_i[0][0]          = IPTEW;
  assign rvvi.pte_d[0][0]          = DPTEW;
  assign rvvi.ppn_i[0][0]          = IPPNW;
  assign rvvi.ppn_d[0][0]          = DPPNW;
  assign rvvi.page_type_i[0][0]    = IPageTypeW;
  assign rvvi.page_type_d[0][0]    = DPageTypeW;
`endif

  integer index2;

  string  instrWName;
  int     file;
  string  LogFile;
  if(`STD_LOG) begin
    instrNameDecTB #(P.XLEN) NameDecoder(rvvi.insn[0][0], instrWName);
    initial begin
      LogFile = "logs/boottrace.log";
      file = $fopen(LogFile, "w");
    end
  end
  
  always_ff @(posedge clk) begin
    if(valid) begin
      if(`STD_LOG) begin
        $fwrite(file, "%016x, %08x, %s\t\t", rvvi.pc_rdata[0][0], rvvi.insn[0][0], instrWName);
        for(index2 = 0; index2 < NUM_REGS; index2 += 1) begin
          if(rvvi.x_wb[0][0][index2]) begin
            $fwrite(file, "rf[%02d] = %016x ", index2, rvvi.x_wdata[0][0][index2]);
          end
        end
      end
      for(index2 = 0; index2 < 32; index2 += 1) begin
        if(rvvi.f_wb[0][0][index2]) begin
          $fwrite(file, "frf[%02d] = %016x ", index2, rvvi.f_wdata[0][0][index2]);
        end
      end
      for(index2 = 0; index2 < NUM_CSRS; index2 += 1) begin
        if(rvvi.csr_wb[0][0][index2]) begin
          $fwrite(file, "csr[%03x] = %016x ", index2, rvvi.csr[0][0][index2]);
        end
      end
      $fwrite(file, "\n");
      if(`PRINT_PC_INSTR & !(`PRINT_ALL | `PRINT_MOST))
        $display("order = %08d, PC = %08x, insn = %08x", rvvi.order[0][0], rvvi.pc_rdata[0][0], rvvi.insn[0][0]);
      else if(`PRINT_MOST & !`PRINT_ALL)
        $display("order = %08d, PC = %010x, insn = %08x, trap = %1d, halt = %1d, intr = %1d, mode = %1x, ixl = %1x, pc_wdata = %010x, x%02d = %016x, f%02d = %016x, csr%03x = %016x", 
                 rvvi.order[0][0], rvvi.pc_rdata[0][0], rvvi.insn[0][0], rvvi.trap[0][0], rvvi.halt[0][0], rvvi.intr[0][0], rvvi.mode[0][0], rvvi.ixl[0][0], rvvi.pc_wdata[0][0], rf_a3, rvvi.x_wdata[0][0][rf_a3], frf_a4, rvvi.f_wdata[0][0][frf_a4], CSRAdrW, rvvi.csr[0][0][CSRAdrW]);
      else if(`PRINT_ALL) begin
        $display("order = %08d, PC = %08x, insn = %08x, trap = %1d, halt = %1d, intr = %1d, mode = %1x, ixl = %1x, pc_wdata = %08x", 
                 rvvi.order[0][0], rvvi.pc_rdata[0][0], rvvi.insn[0][0], rvvi.trap[0][0], rvvi.halt[0][0], rvvi.intr[0][0], rvvi.mode[0][0], rvvi.ixl[0][0], rvvi.pc_wdata[0][0]);
        for(index2 = 0; index2 < NUM_REGS; index2 += 1) begin
          $display("x%02d = %08x", index2, rvvi.x_wdata[0][0][index2]);
        end
        for(index2 = 0; index2 < 32; index2 += 1) begin
          $display("f%02d = %08x", index2, rvvi.f_wdata[0][0][index2]);
        end
      end
      // Need to figure out how to print values on change if they are not in a large array
      // if (`PRINT_CSRS) begin
      //   for(index2 = 0; index2 < NUM_CSRS; index2 += 1) begin
      //     if((rvvi.csr[0][0][index2] != CSRArrayOld[index2])) begin
      //       $display("%t: CSR %03x = %x", $time(), index2, rvvi.csr[0][0][index2]);
      //     end
      //   end
      // end
    end
    if(HaltW) begin
`ifdef FCOV
      $display("Functional coverage test complete.");
`endif
`ifdef QUESTA
      $stop;  // if this is changed to $finish for Questa, wally.do does not go to the next step to run coverage and terminates without allowing GUI debug
`else
      $finish;
`endif
    end
  end
endmodule
