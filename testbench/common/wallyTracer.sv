///////////////////////////////////////////
// wallyTracer.sv
//
// A component of the Wally configurable RISC-V project.
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


`define NUM_REGS 32
`define NUM_CSRS 4096

`define STD_LOG 0
`define PRINT_PC_INSTR 0
`define PRINT_MOST 0
`define PRINT_ALL 0
`define PRINT_CSRS 0


module wallyTracer import cvw::*; #(parameter cvw_t P) (rvviTrace rvvi);

  localparam NUMREGS = P.E_SUPPORTED ? 16 : 32;
  
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
  logic [P.XLEN-1:0]     rf[NUMREGS];
  logic [NUMREGS-1:0]    rf_wb;
  logic [4:0]            rf_a3;
  logic                  rf_we3;
  logic [P.FLEN-1:0]     frf[32];
  logic [`NUM_REGS-1:0]  frf_wb;
  logic [4:0]            frf_a4;
  logic                  frf_we4;
  logic [P.XLEN-1:0]     CSRArray [4095:0];
  logic [P.XLEN-1:0]     CSRArrayOld [4095:0];
  logic [`NUM_CSRS-1:0]  CSR_W;
  logic                  CSRWriteM, CSRWriteW;
  logic [11:0]           CSRAdrM, CSRAdrW;
  logic                  wfiM;
  logic                  InterruptM, InterruptW;

  //For VM Verification
  logic [(P.XLEN-1):0]     IVAdrF,IVAdrD,IVAdrE,IVAdrM,IVAdrW,DVAdrM,DVAdrW;
  logic [(P.XLEN-1):0]     IPTEF,IPTED,IPTEE,IPTEM,IPTEW,DPTEM,DPTEW;
  logic [(P.PA_BITS-1):0]  IPAF,IPAD,IPAE,IPAM,IPAW,DPAM,DPAW;
  logic [(P.PPN_BITS-1):0] IPPNF,IPPND,IPPNE,IPPNM,IPPNW,DPPNM,DPPNW;
  logic [1:0]              IPageTypeF, IPageTypeD, IPageTypeE, IPageTypeM, IPageTypeW, DPageTypeM, DPageTypeW;
  logic ReadAccessM,WriteAccessM,ReadAccessW,WriteAccessW;
  logic ExecuteAccessF,ExecuteAccessD,ExecuteAccessE,ExecuteAccessM,ExecuteAccessW;

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
  assign SelHPTW        = testbench.dut.core.lsu.hptw.hptw.SelHPTW;
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
  end else begin
    assign PrivilegeModeW = 2'b11;
    assign STATUS_SXL     = 0;
    assign STATUS_UXL     = 0;
    assign wfiM           = 0;
    assign InterruptM     = 0;
  end

  //For VM Verification
  assign IVAdrF         = testbench.dut.core.ifu.immu.immu.tlb.tlb.VAdr;
  assign DVAdrM         = testbench.dut.core.lsu.dmmu.dmmu.tlb.tlb.VAdr;
  assign IPAF           = testbench.dut.core.ifu.immu.immu.PhysicalAddress;
  assign DPAM           = testbench.dut.core.lsu.dmmu.dmmu.PhysicalAddress;
  assign ReadAccessM    = testbench.dut.core.lsu.dmmu.dmmu.ReadAccessM;
  assign WriteAccessM   = testbench.dut.core.lsu.dmmu.dmmu.WriteAccessM;
  assign ExecuteAccessF = testbench.dut.core.ifu.immu.immu.ExecuteAccessF;
  assign IPTEF         = testbench.dut.core.ifu.immu.immu.PTE;
  assign DPTEM         = testbench.dut.core.lsu.dmmu.dmmu.PTE;
  assign IPPNF         = testbench.dut.core.ifu.immu.immu.tlb.tlb.PPN;
  assign DPPNM         = testbench.dut.core.lsu.dmmu.dmmu.tlb.tlb.PPN; 
  assign IPageTypeF    = testbench.dut.core.ifu.immu.immu.PageTypeWriteVal;
  assign DPageTypeM    = testbench.dut.core.lsu.dmmu.dmmu.PageTypeWriteVal;

  logic valid;
  
  if (P.ZICSR_SUPPORTED) begin
    always_comb begin
      // Since we are detected the CSR change by comparing the old value we need to
      // ensure the CSR is detected when the pipeline's Writeback stage is not
      // stalled.  If it is stalled we want CSRArray to hold the old value.
      if(valid) begin 
        // PMPCFG CSRs (space is 0-15 3a0 - 3af)
        localparam inc = P.XLEN == 32 ? 4 : 8;
        int i, i4, i8, csrid;
        logic [P.XLEN-1:0] pmp;

        for (i=0; i<P.PMP_ENTRIES; i+=inc) begin
          i4 = i / 4;
          i8 = (i / inc) * inc;
          csrid = 12'h3A0 + i4;
          pmp = 0;
          pmp |= testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[i8+0] << 0;
          pmp |= testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[i8+1] << 8;
          pmp |= testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[i8+2] << 16;
          pmp |= testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[i8+3] << 24;
          pmp |= testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[i8+4] << 32;
          pmp |= testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[i8+5] << 40;
          pmp |= testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[i8+6] << 48;
          pmp |= testbench.dut.core.priv.priv.csr.csrm.PMPCFG_ARRAY_REGW[i8+7] << 56;
          
          CSRArray[csrid] = pmp;
        end

        // PMPADDR CSRs (space is 0-63 3b0 - 3ef)
        for (i=0; i<P.PMP_ENTRIES; i++) begin
          csrid = 12'h3B0 + i;;
          pmp = testbench.dut.core.priv.priv.csr.csrm.PMPADDR_ARRAY_REGW[i];
          CSRArray[csrid] = pmp;
        end

        // M-mode trap CSRs
        CSRArray[12'h300] = testbench.dut.core.priv.priv.csr.csrm.MSTATUS_REGW;
        CSRArray[12'h302] = testbench.dut.core.priv.priv.csr.csrm.MEDELEG_REGW;
        CSRArray[12'h303] = testbench.dut.core.priv.priv.csr.csrm.MIDELEG_REGW;
        CSRArray[12'h304] = testbench.dut.core.priv.priv.csr.csrm.MIE_REGW;
        CSRArray[12'h305] = testbench.dut.core.priv.priv.csr.csrm.MTVEC_REGW;
        CSRArray[12'h340] = testbench.dut.core.priv.priv.csr.csrm.MSCRATCH_REGW;
        CSRArray[12'h341] = testbench.dut.core.priv.priv.csr.csrm.MEPC_REGW;
        CSRArray[12'h342] = testbench.dut.core.priv.priv.csr.csrm.MCAUSE_REGW;
        CSRArray[12'h343] = testbench.dut.core.priv.priv.csr.csrm.MTVAL_REGW;
        CSRArray[12'h344] = testbench.dut.core.priv.priv.csr.csrm.MIP_REGW;
        
        // S-mode trap CSRs
        CSRArray[12'h100] = testbench.dut.core.priv.priv.csr.csrs.csrs.SSTATUS_REGW;
        CSRArray[12'h104] = testbench.dut.core.priv.priv.csr.csrm.MIE_REGW & 12'h222;
        CSRArray[12'h105] = testbench.dut.core.priv.priv.csr.csrs.csrs.STVEC_REGW;
        CSRArray[12'h140] = testbench.dut.core.priv.priv.csr.csrs.csrs.SSCRATCH_REGW;
        CSRArray[12'h141] = testbench.dut.core.priv.priv.csr.csrs.csrs.SEPC_REGW;
        CSRArray[12'h142] = testbench.dut.core.priv.priv.csr.csrs.csrs.SCAUSE_REGW;
        CSRArray[12'h143] = testbench.dut.core.priv.priv.csr.csrs.csrs.STVAL_REGW;
        CSRArray[12'h144] = testbench.dut.core.priv.priv.csr.csrm.MIP_REGW & 12'h222 & testbench.dut.core.priv.priv.csr.csrm.MIDELEG_REGW;

        // Virtual Memory CSRs
        CSRArray[12'h180] = testbench.dut.core.priv.priv.csr.csrs.csrs.SATP_REGW;

        // Floating-Point CSRs
        CSRArray[12'h001] = testbench.dut.core.priv.priv.csr.csru.csru.FFLAGS_REGW;
        CSRArray[12'h002] = testbench.dut.core.priv.priv.csr.csru.csru.FRM_REGW;
        CSRArray[12'h003] = {testbench.dut.core.priv.priv.csr.csru.csru.FRM_REGW, testbench.dut.core.priv.priv.csr.csru.csru.FFLAGS_REGW};

        // Counters / Performance Monitoring CSRs
        CSRArray[12'h306] = testbench.dut.core.priv.priv.csr.csrm.MCOUNTEREN_REGW;
        CSRArray[12'h106] = testbench.dut.core.priv.priv.csr.csrs.csrs.SCOUNTEREN_REGW;
        CSRArray[12'h320] = testbench.dut.core.priv.priv.csr.csrm.MCOUNTINHIBIT_REGW;
        // mhpmevent3-31 not connected (232-33F)
        CSRArray[12'hB00] = testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[0]; // MCYCLE
        CSRArray[12'hB02] = testbench.dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[2]; // MINSTRET
        // mhpmcounter3-31 not connected (B03-B1F)
        // cycle, time, instret not connected (C00-C02)
        // hpmcounter3-31 not connected (C03-C1F)

        // Machine Information Registers and Configuration CSRs
        CSRArray[12'h301] = testbench.dut.core.priv.priv.csr.csrm.MISA_REGW;
        CSRArray[12'h30A] = testbench.dut.core.priv.priv.csr.csrm.MENVCFG_REGW;
        CSRArray[12'h10A] = testbench.dut.core.priv.priv.csr.csrs.csrs.SENVCFG_REGW;
        CSRArray[12'h747] = 0; // mseccfg
        CSRArray[12'hF11] = 0; //mvendorid
        CSRArray[12'hF12] = 0; // marchid
        CSRArray[12'hF13] = {{P.XLEN-12{1'b0}}, 12'h100}; // mimpid
        CSRArray[12'hF14] = testbench.dut.core.priv.priv.csr.csrm.MHARTID_REGW;
        CSRArray[12'hF15] = 0; //mconfigptr

        // Sstc CSRs
        CSRArray[12'h14D] = testbench.dut.core.priv.priv.csr.csrs.csrs.STIMECMP_REGW[P.XLEN-1:0];
        
        // Zkr CSRs
        // seed not connected (015)

        // extra CSRs for RV32
        if (P.XLEN == 32) begin
          CSRArray[12'h310] = testbench.dut.core.priv.priv.csr.csrsr.MSTATUSH_REGW;
          CSRArray[12'h31A] = testbench.dut.core.priv.priv.csr.csrm.MENVCFGH_REGW;
          CSRArray[12'h757] = 0; // mseccfgh
          CSRArray[12'h15D] = testbench.dut.core.priv.priv.csr.csrs.csrs.STIMECMP_REGW[63:32];
        end
      end else begin // hold the old value if the pipeline is stalled.
        // PMP CFG 3A0 to 3AF
        int csrid;
        for(csrid='h3A0; csrid<='h3AF; csrid++)
          CSRArray[csrid] = CSRArrayOld[csrid];
        
        // PMP ADDR 3B0 to 3EF
        for(csrid='h3B0; csrid<='h3EF; csrid++)
          CSRArray[csrid] = CSRArrayOld[csrid];

        // M-mode trap CSRs
        CSRArray[12'h300] = CSRArrayOld[12'h300];
        CSRArray[12'h302] = CSRArrayOld[12'h302];
        CSRArray[12'h303] = CSRArrayOld[12'h303];
        CSRArray[12'h304] = CSRArrayOld[12'h304];
        CSRArray[12'h305] = CSRArrayOld[12'h305];
        CSRArray[12'h340] = CSRArrayOld[12'h340];
        CSRArray[12'h341] = CSRArrayOld[12'h341];
        CSRArray[12'h342] = CSRArrayOld[12'h342];
        CSRArray[12'h343] = CSRArrayOld[12'h343];
        CSRArray[12'h344] = CSRArrayOld[12'h344];

        // S-mode trap CSRs
        CSRArray[12'h100] = CSRArrayOld[12'h100];
        CSRArray[12'h104] = CSRArrayOld[12'h104];
        CSRArray[12'h105] = CSRArrayOld[12'h105];
        CSRArray[12'h140] = CSRArrayOld[12'h140];
        CSRArray[12'h141] = CSRArrayOld[12'h141];
        CSRArray[12'h142] = CSRArrayOld[12'h142];
        CSRArray[12'h143] = CSRArrayOld[12'h143];
        CSRArray[12'h144] = CSRArrayOld[12'h144];

        // Virtual Memory CSRs
        CSRArray[12'h180] = CSRArrayOld[12'h180] ;

        // Floating-Point CSRs
        CSRArray[12'h001] = CSRArrayOld[12'h001];
        CSRArray[12'h002] = CSRArrayOld[12'h002];
        CSRArray[12'h003] = CSRArrayOld[12'h003];

        // Counters / Performance Monitoring CSRs
        CSRArray[12'h306] = CSRArrayOld[12'h306];
        CSRArray[12'h106] = CSRArrayOld[12'h106];
        CSRArray[12'h320] = CSRArrayOld[12'h320];
        // mhpmevent3-31 not connected (232-33F)
        CSRArray[12'hB00] = CSRArrayOld[12'hB00];
        CSRArray[12'hB02] = CSRArrayOld[12'hB02];
        // mhpmcounter3-31 not connected (B03-B1F)
        // cycle, time, instret not connected (C00-C02)
        // hpmcounter3-31 not connected (C03-C1F)

        // Machine Information Registers and Configuration CSRs
        CSRArray[12'h301] = CSRArrayOld[12'h301];
        CSRArray[12'h30A] = CSRArrayOld[12'h30A];
        CSRArray[12'h10A] = CSRArrayOld[12'h10A];
        CSRArray[12'h747] = CSRArrayOld[12'h747];
        CSRArray[12'hF11] = CSRArrayOld[12'hF11];
        CSRArray[12'hF12] = CSRArrayOld[12'hF12];
        CSRArray[12'hF13] = CSRArrayOld[12'hF13];
        CSRArray[12'hF14] = CSRArrayOld[12'hF14];
        CSRArray[12'hF15] = CSRArrayOld[12'hF15];

        // Sstc CSRs
        CSRArray[12'h14D] = CSRArrayOld[12'h14D];
        
        // Zkr CSRs
        // seed not connected (015)

        // extra CSRs for RV32
        if (P.XLEN == 32) begin
          CSRArray[12'h310] = CSRArrayOld[12'h310];
          CSRArray[12'h31A] = CSRArrayOld[12'h31A];
          CSRArray[12'h757] = CSRArrayOld[12'h757];
          CSRArray[12'h15D] = CSRArrayOld[12'h15D];
        end
      end    
    end
  end else begin
    // no CSRArray
  end

  genvar index;
  assign rf[0] = 0;
  for(index = 1; index < NUMREGS; index += 1) 
  assign rf[index] = testbench.dut.core.ieu.dp.regf.rf[index];

  assign rf_a3  = testbench.dut.core.ieu.dp.regf.a3;
  assign rf_we3 = testbench.dut.core.ieu.dp.regf.we3;
  
  always_comb begin
    rf_wb <= 0;
    if(rf_we3)
      rf_wb[rf_a3] <= 1'b1;
  end

  if (P.F_SUPPORTED) begin
    assign frf_a4  = testbench.dut.core.fpu.fpu.fregfile.a4;
    assign frf_we4 = testbench.dut.core.fpu.fpu.fregfile.we4;
    for(index = 0; index < NUMREGS; index += 1) 
      assign frf[index] = testbench.dut.core.fpu.fpu.fregfile.rf[index];
  end else begin
    assign frf_a4  = '0;
    assign frf_we4 = 0;
    for(index = 0; index < NUMREGS; index += 1) 
      assign frf[index] = '0;
  end
  
  
  always_comb begin
    frf_wb <= 0;
    if(frf_we4)
      frf_wb[frf_a4] <= 1'b1;
  end

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
  flopenrc #(P.XLEN)     IVAdrMReg (clk, reset, 1'b0, ~StallM, IVAdrE, IVAdrM); //Virtual Address for IMMU
  flopenrc #(P.XLEN)     IVAdrWReg (clk, reset, 1'b0, SelHPTW, IVAdrM, IVAdrW); //Virtual Address for IMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW
  flopenrc #(P.XLEN)     DVAdrWReg (clk, reset, 1'b0, SelHPTW, DVAdrM, DVAdrW); //Virtual Address for DMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW

  flopenrc #(P.PA_BITS)  IPADReg (clk, reset, 1'b0, SelHPTW, IPAF, IPAD); //Physical Address for IMMU // *** RT: possible bug SelHPTW probably should be ~StallD
  flopenrc #(P.PA_BITS)  IPAEReg (clk, reset, 1'b0, ~StallE, IPAD, IPAE); //Physical Address for IMMU
  flopenrc #(P.PA_BITS)  IPAMReg (clk, reset, 1'b0, ~StallM, IPAE, IPAM); //Physical Address for IMMU
  flopenrc #(P.PA_BITS)  IPAWReg (clk, reset, 1'b0, SelHPTW, IPAM, IPAW); //Physical Address for IMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW
  flopenrc #(P.PA_BITS)  DPAWReg (clk, reset, 1'b0, SelHPTW, DPAM, DPAW); //Physical Address for DMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW

  flopenrc #(P.XLEN)     IPTEDReg (clk, reset, 1'b0, SelHPTW, IPTEF, IPTED); //PTE for IMMU // *** RT: possible bug SelHPTW probably should be ~StallD
  flopenrc #(P.XLEN)     IPTEEReg (clk, reset, 1'b0, ~StallE, IPTED, IPTEE); //PTE for IMMU
  flopenrc #(P.XLEN)     IPTEMReg (clk, reset, 1'b0, ~StallM, IPTEE, IPTEM); //PTE for IMMU
  flopenrc #(P.XLEN)     IPTEWReg (clk, reset, 1'b0, SelHPTW, IPTEM, IPTEW); //PTE for IMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW
  flopenrc #(P.XLEN)     DPTEWReg (clk, reset, 1'b0, SelHPTW, DPTEM, DPTEW); //PTE for DMMU // *** RT: possible bug SelHPTW probably should be ~GatedStallW

  flopenrc #(2)     IPageTypeDReg (clk, reset, 1'b0, SelHPTW, IPageTypeF, IPageTypeD); //PageType (kilo, mega, giga, tera) from IMMU // *** RT: possible bug SelHPTW probably should be ~StallD
  flopenrc #(2)     IPageTypeEReg (clk, reset, 1'b0, ~StallE, IPageTypeD, IPageTypeE); //PageType (kilo, mega, giga, tera) from IMMU
  flopenrc #(2)     IPageTypeMReg (clk, reset, 1'b0, ~StallM, IPageTypeE, IPageTypeM); //PageType (kilo, mega, giga, tera) from IMMU
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

  assign valid  = ((InstrValidW | TrapW) & ~StallW) & ~reset;
  assign rvvi.clk = clk;
  assign rvvi.valid[0][0]    = valid;
  assign rvvi.order[0][0]    = CSRArray[12'hB02];  // TODO: IMPERAS Should be event order
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

  for(index = 0; index < `NUM_REGS; index += 1) begin
    assign rvvi.x_wdata[0][0][index] = rf[index];
    assign rvvi.x_wb[0][0][index]    = rf_wb[index];
    assign rvvi.f_wdata[0][0][index] = frf[index];
    assign rvvi.f_wb[0][0][index]    = frf_wb[index];
  end

  // record previous csr value.
  integer index4;
  always_ff @(posedge clk) begin
    int csrid;
    // PMP CFG 3A0 to 3AF
    for(csrid='h3A0; csrid<='h3AF; csrid++)
      CSRArrayOld[csrid] = CSRArray[csrid];
    
    // PMP ADDR 3B0 to 3EF
    for(csrid='h3B0; csrid<='h3EF; csrid++)
      CSRArrayOld[csrid] = CSRArray[csrid];

    // M-mode trap CSRs
    CSRArrayOld[12'h300] = CSRArray[12'h300];
    CSRArrayOld[12'h302] = CSRArray[12'h302];
    CSRArrayOld[12'h303] = CSRArray[12'h303];
    CSRArrayOld[12'h304] = CSRArray[12'h304];
    CSRArrayOld[12'h305] = CSRArray[12'h305];
    CSRArrayOld[12'h340] = CSRArray[12'h340];
    CSRArrayOld[12'h341] = CSRArray[12'h341];
    CSRArrayOld[12'h342] = CSRArray[12'h342];
    CSRArrayOld[12'h343] = CSRArray[12'h343];
    CSRArrayOld[12'h344] = CSRArray[12'h344];

    // S-mode trap CSRs
    CSRArrayOld[12'h100] = CSRArray[12'h100];
    CSRArrayOld[12'h104] = CSRArray[12'h104];
    CSRArrayOld[12'h105] = CSRArray[12'h105];
    CSRArrayOld[12'h140] = CSRArray[12'h140];
    CSRArrayOld[12'h141] = CSRArray[12'h141];
    CSRArrayOld[12'h142] = CSRArray[12'h142];
    CSRArrayOld[12'h143] = CSRArray[12'h143];
    CSRArrayOld[12'h144] = CSRArray[12'h144];

    // Virtual Memory CSRs
    CSRArrayOld[12'h180] = CSRArray[12'h180] ;

    // Floating-Point CSRs
    CSRArrayOld[12'h001] = CSRArray[12'h001];
    CSRArrayOld[12'h002] = CSRArray[12'h002];
    CSRArrayOld[12'h003] = CSRArray[12'h003];

    // Counters / Performance Monitoring CSRs
    CSRArrayOld[12'h306] = CSRArray[12'h306];
    CSRArrayOld[12'h106] = CSRArray[12'h106];
    CSRArrayOld[12'h320] = CSRArray[12'h320];
    // mhpmevent3-31 not connected (232-33F)
    CSRArrayOld[12'hB00] = CSRArray[12'hB00];
    CSRArrayOld[12'hB02] = CSRArray[12'hB02];
    // mhpmcounter3-31 not connected (B03-B1F)
    // cycle, time, instret not connected (C00-C02)
    // hpmcounter3-31 not connected (C03-C1F)

    // Machine Information Registers and Configuration CSRs
    CSRArrayOld[12'h301] = CSRArray[12'h301];
    CSRArrayOld[12'h30A] = CSRArray[12'h30A];
    CSRArrayOld[12'h10A] = CSRArray[12'h10A];
    CSRArrayOld[12'h747] = CSRArray[12'h747];
    CSRArrayOld[12'hF11] = CSRArray[12'hF11];
    CSRArrayOld[12'hF12] = CSRArray[12'hF12];
    CSRArrayOld[12'hF13] = CSRArray[12'hF13];
    CSRArrayOld[12'hF14] = CSRArray[12'hF14];
    CSRArrayOld[12'hF15] = CSRArray[12'hF15];

    // Sstc CSRs
    CSRArrayOld[12'h14D] = CSRArray[12'h14D];
    
    // Zkr CSRs
    // seed not connected (015)

    // extra CSRs for RV32
    if (P.XLEN == 32) begin
      CSRArrayOld[12'h310] = CSRArray[12'h310];
      CSRArrayOld[12'h31A] = CSRArray[12'h31A];
      CSRArrayOld[12'h757] = CSRArray[12'h757];
      CSRArrayOld[12'h15D] = CSRArray[12'h15D];
    end
  end
  
  // check for csr value change.
  // M-mode trap CSRs
  assign CSR_W[12'h300] = (CSRArrayOld[12'h300] != CSRArray[12'h300]) ? 1 : 0;
  assign CSR_W[12'h302] = (CSRArrayOld[12'h302] != CSRArray[12'h302]) ? 1 : 0;
  assign CSR_W[12'h303] = (CSRArrayOld[12'h303] != CSRArray[12'h303]) ? 1 : 0;
  assign CSR_W[12'h304] = (CSRArrayOld[12'h304] != CSRArray[12'h304]) ? 1 : 0;
  assign CSR_W[12'h305] = (CSRArrayOld[12'h305] != CSRArray[12'h305]) ? 1 : 0;
  assign CSR_W[12'h340] = (CSRArrayOld[12'h340] != CSRArray[12'h340]) ? 1 : 0;
  assign CSR_W[12'h341] = (CSRArrayOld[12'h341] != CSRArray[12'h341]) ? 1 : 0;
  assign CSR_W[12'h342] = (CSRArrayOld[12'h342] != CSRArray[12'h342]) ? 1 : 0;
  assign CSR_W[12'h343] = (CSRArrayOld[12'h343] != CSRArray[12'h343]) ? 1 : 0;
  assign CSR_W[12'h344] = (CSRArrayOld[12'h344] != CSRArray[12'h344]) ? 1 : 0;

  // S-mode trap CSRs
  assign CSR_W[12'h100] = (CSRArrayOld[12'h100] != CSRArray[12'h100]) ? 1 : 0;
  assign CSR_W[12'h104] = (CSRArrayOld[12'h104] != CSRArray[12'h104]) ? 1 : 0;
  assign CSR_W[12'h105] = (CSRArrayOld[12'h105] != CSRArray[12'h105]) ? 1 : 0;
  assign CSR_W[12'h140] = (CSRArrayOld[12'h140] != CSRArray[12'h140]) ? 1 : 0;
  assign CSR_W[12'h141] = (CSRArrayOld[12'h141] != CSRArray[12'h141]) ? 1 : 0;
  assign CSR_W[12'h142] = (CSRArrayOld[12'h142] != CSRArray[12'h142]) ? 1 : 0;
  assign CSR_W[12'h143] = (CSRArrayOld[12'h143] != CSRArray[12'h143]) ? 1 : 0;
  assign CSR_W[12'h144] = (CSRArrayOld[12'h144] != CSRArray[12'h144]) ? 1 : 0;

  // Virtual Memory CSRs
  assign CSR_W[12'h180] = (CSRArrayOld[12'h180] != CSRArray[12'h180]) ? 1 : 0;

  // Floating-Point CSRs
  assign CSR_W[12'h001] = (CSRArrayOld[12'h001] != CSRArray[12'h001]) ? 1 : 0;
  assign CSR_W[12'h002] = (CSRArrayOld[12'h002] != CSRArray[12'h002]) ? 1 : 0;
  assign CSR_W[12'h003] = (CSRArrayOld[12'h003] != CSRArray[12'h003]) ? 1 : 0;

  // Counters / Performance Monitoring CSRs
  assign CSR_W[12'h306] = (CSRArrayOld[12'h306] != CSRArray[12'h306]) ? 1 : 0;
  assign CSR_W[12'h106] = (CSRArrayOld[12'h106] != CSRArray[12'h106]) ? 1 : 0;
  assign CSR_W[12'h320] = (CSRArrayOld[12'h320] != CSRArray[12'h320]) ? 1 : 0;
  // mhpmevent3-31 not connected (232-33F)
  assign CSR_W[12'hB00] = (CSRArrayOld[12'hB00] != CSRArray[12'hB00]) ? 1 : 0;
  assign CSR_W[12'hB02] = (CSRArrayOld[12'hB02] != CSRArray[12'hB02]) ? 1 : 0;
  // mhpmcounter3-31 not connected (B03-B1F)
  // cycle, time, instret not connected (C00-C02)
  // hpmcounter3-31 not connected (C03-C1F)

  // Machine Information Registers and Configuration CSRs
  assign CSR_W[12'h301] = (CSRArrayOld[12'h301] != CSRArray[12'h301]) ? 1 : 0;
  assign CSR_W[12'h30A] = (CSRArrayOld[12'h30A] != CSRArray[12'h30A]) ? 1 : 0;
  assign CSR_W[12'h10A] = (CSRArrayOld[12'h10A] != CSRArray[12'h10A]) ? 1 : 0;
  assign CSR_W[12'h747] = (CSRArrayOld[12'h747] != CSRArray[12'h747]) ? 1 : 0;
  assign CSR_W[12'hF11] = (CSRArrayOld[12'hF11] != CSRArray[12'hF11]) ? 1 : 0;
  assign CSR_W[12'hF12] = (CSRArrayOld[12'hF12] != CSRArray[12'hF12]) ? 1 : 0;
  assign CSR_W[12'hF13] = (CSRArrayOld[12'hF13] != CSRArray[12'hF13]) ? 1 : 0;
  assign CSR_W[12'hF14] = (CSRArrayOld[12'hF14] != CSRArray[12'hF14]) ? 1 : 0;
  assign CSR_W[12'hF15] = (CSRArrayOld[12'hF15] != CSRArray[12'hF15]) ? 1 : 0;

  // Sstc CSRs
  assign CSR_W[12'h14D] = (CSRArrayOld[12'h14D] != CSRArray[12'h14D]) ? 1 : 0;
  
  // Zkr CSRs
  // seed not connected (015)

  // extra CSRs for RV32
  if (P.XLEN == 32) begin
    assign CSR_W[12'h310] = (CSRArrayOld[12'h310] != CSRArray[12'h310]) ? 1 : 0;
    assign CSR_W[12'h31A] = (CSRArrayOld[12'h31A] != CSRArray[12'h31A]) ? 1 : 0;
    assign CSR_W[12'h757] = (CSRArrayOld[12'h757] != CSRArray[12'h757]) ? 1 : 0;
    assign CSR_W[12'h15D] = (CSRArrayOld[12'h15D] != CSRArray[12'h15D]) ? 1 : 0;
  end



  // M-mode trap CSRs
  assign rvvi.csr_wb[0][0][12'h300] = CSR_W[12'h300];
  assign rvvi.csr_wb[0][0][12'h302] = CSR_W[12'h302];
  assign rvvi.csr_wb[0][0][12'h303] = CSR_W[12'h303];
  assign rvvi.csr_wb[0][0][12'h304] = CSR_W[12'h304];
  assign rvvi.csr_wb[0][0][12'h305] = CSR_W[12'h305];
  assign rvvi.csr_wb[0][0][12'h340] = CSR_W[12'h340];
  assign rvvi.csr_wb[0][0][12'h341] = CSR_W[12'h341];
  assign rvvi.csr_wb[0][0][12'h342] = CSR_W[12'h342];
  assign rvvi.csr_wb[0][0][12'h343] = CSR_W[12'h343];
  assign rvvi.csr_wb[0][0][12'h344] = CSR_W[12'h344];

  // S-mode trap CSRs
  assign rvvi.csr_wb[0][0][12'h100] = CSR_W[12'h100];
  assign rvvi.csr_wb[0][0][12'h104] = CSR_W[12'h104];
  assign rvvi.csr_wb[0][0][12'h105] = CSR_W[12'h105];
  assign rvvi.csr_wb[0][0][12'h140] = CSR_W[12'h140];
  assign rvvi.csr_wb[0][0][12'h141] = CSR_W[12'h141];
  assign rvvi.csr_wb[0][0][12'h142] = CSR_W[12'h142];
  assign rvvi.csr_wb[0][0][12'h143] = CSR_W[12'h143];
  assign rvvi.csr_wb[0][0][12'h144] = CSR_W[12'h144];

  // Virtual Memory CSRs
  assign rvvi.csr_wb[0][0][12'h180] = CSR_W[12'h180];

  // Floating-Point CSRs
  assign rvvi.csr_wb[0][0][12'h001] = CSR_W[12'h001];
  assign rvvi.csr_wb[0][0][12'h002] = CSR_W[12'h002];
  assign rvvi.csr_wb[0][0][12'h003] = CSR_W[12'h003];

  // Counters / Performance Monitoring CSRs
  assign rvvi.csr_wb[0][0][12'h306] = CSR_W[12'h306];
  assign rvvi.csr_wb[0][0][12'h106] = CSR_W[12'h106];
  assign rvvi.csr_wb[0][0][12'h320] = CSR_W[12'h320];
  // mhpmevent3-31 not connected (232-33F)
  assign rvvi.csr_wb[0][0][12'hB00] = CSR_W[12'hB00];
  assign rvvi.csr_wb[0][0][12'hB02] = CSR_W[12'hB02];
  // mhpmcounter3-31 not connected (B03-B1F)
  // cycle, time, instret not connected (C00-C02)
  // hpmcounter3-31 not connected (C03-C1F)

  // Machine Information Registers and Configuration CSRs
  assign rvvi.csr_wb[0][0][12'h301] = CSR_W[12'h301];
  assign rvvi.csr_wb[0][0][12'h30A] = CSR_W[12'h30A];
  assign rvvi.csr_wb[0][0][12'h10A] = CSR_W[12'h10A];
  assign rvvi.csr_wb[0][0][12'h747] = CSR_W[12'h747];
  assign rvvi.csr_wb[0][0][12'hF11] = CSR_W[12'hF11];
  assign rvvi.csr_wb[0][0][12'hF12] = CSR_W[12'hF12];
  assign rvvi.csr_wb[0][0][12'hF13] = CSR_W[12'hF13];
  assign rvvi.csr_wb[0][0][12'hF14] = CSR_W[12'hF14];
  assign rvvi.csr_wb[0][0][12'hF15] = CSR_W[12'hF15];

  // Sstc CSRs
  assign rvvi.csr_wb[0][0][12'h14D] = CSR_W[12'h14D];
  
  // Zkr CSRs
  // seed not connected (015)

  // extra CSRs for RV32
  if (P.XLEN == 32) begin
    assign rvvi.csr_wb[0][0][12'h310] = CSR_W[12'h310];
    assign rvvi.csr_wb[0][0][12'h31A] = CSR_W[12'h31A];
    assign rvvi.csr_wb[0][0][12'h757] = CSR_W[12'h757];
    assign rvvi.csr_wb[0][0][12'h15D] = CSR_W[12'h15D];
  end



// M-mode trap CSRs
  assign rvvi.csr[0][0][12'h300] = CSRArray[12'h300];
  assign rvvi.csr[0][0][12'h302] = CSRArray[12'h302];
  assign rvvi.csr[0][0][12'h303] = CSRArray[12'h303];
  assign rvvi.csr[0][0][12'h304] = CSRArray[12'h304];
  assign rvvi.csr[0][0][12'h305] = CSRArray[12'h305];
  assign rvvi.csr[0][0][12'h340] = CSRArray[12'h340];
  assign rvvi.csr[0][0][12'h341] = CSRArray[12'h341];
  assign rvvi.csr[0][0][12'h342] = CSRArray[12'h342];
  assign rvvi.csr[0][0][12'h343] = CSRArray[12'h343];
  assign rvvi.csr[0][0][12'h344] = CSRArray[12'h344];

  // S-mode trap CSRs
  assign rvvi.csr[0][0][12'h100] = CSRArray[12'h100];
  assign rvvi.csr[0][0][12'h104] = CSRArray[12'h104];
  assign rvvi.csr[0][0][12'h105] = CSRArray[12'h105];
  assign rvvi.csr[0][0][12'h140] = CSRArray[12'h140];
  assign rvvi.csr[0][0][12'h141] = CSRArray[12'h141];
  assign rvvi.csr[0][0][12'h142] = CSRArray[12'h142];
  assign rvvi.csr[0][0][12'h143] = CSRArray[12'h143];
  assign rvvi.csr[0][0][12'h144] = CSRArray[12'h144];

  // Virtual Memory CSRs
  assign rvvi.csr[0][0][12'h180] = CSRArray[12'h180];

  // Floating-Point CSRs
  assign rvvi.csr[0][0][12'h001] = CSRArray[12'h001];
  assign rvvi.csr[0][0][12'h002] = CSRArray[12'h002];
  assign rvvi.csr[0][0][12'h003] = CSRArray[12'h003];

  // Counters / Performance Monitoring CSRs
  assign rvvi.csr[0][0][12'h306] = CSRArray[12'h306];
  assign rvvi.csr[0][0][12'h106] = CSRArray[12'h106];
  assign rvvi.csr[0][0][12'h320] = CSRArray[12'h320];
  // mhpmevent3-31 not connected (232-33F)
  assign rvvi.csr[0][0][12'hB00] = CSRArray[12'hB00];
  assign rvvi.csr[0][0][12'hB02] = CSRArray[12'hB02];
  // mhpmcounter3-31 not connected (B03-B1F)
  // cycle, time, instret not connected (C00-C02)
  // hpmcounter3-31 not connected (C03-C1F)

  // Machine Information Registers and Configuration CSRs
  assign rvvi.csr[0][0][12'h301] = CSRArray[12'h301];
  assign rvvi.csr[0][0][12'h30A] = CSRArray[12'h30A];
  assign rvvi.csr[0][0][12'h10A] = CSRArray[12'h10A];
  assign rvvi.csr[0][0][12'h747] = CSRArray[12'h747];
  assign rvvi.csr[0][0][12'hF11] = CSRArray[12'hF11];
  assign rvvi.csr[0][0][12'hF12] = CSRArray[12'hF12];
  assign rvvi.csr[0][0][12'hF13] = CSRArray[12'hF13];
  assign rvvi.csr[0][0][12'hF14] = CSRArray[12'hF14];
  assign rvvi.csr[0][0][12'hF15] = CSRArray[12'hF15];

  // Sstc CSRs
  assign rvvi.csr[0][0][12'h14D] = CSRArray[12'h14D];
  
  // Zkr CSRs
  // seed not connected (015)

  // extra CSRs for RV32
  if (P.XLEN == 32) begin
    assign rvvi.csr[0][0][12'h310] = CSRArray[12'h310];
    assign rvvi.csr[0][0][12'h31A] = CSRArray[12'h31A];
    assign rvvi.csr[0][0][12'h757] = CSRArray[12'h757];
    assign rvvi.csr[0][0][12'h15D] = CSRArray[12'h15D];
  end


  // PMP CFG 3A0 to 3AF
  for(index='h3A0; index<='h3AF; index++) begin
    assign CSR_W[index] = (CSRArrayOld[index] != CSRArray[index]) ? 1 : 0;
    assign rvvi.csr_wb[0][0][index] = CSR_W[index];
    assign rvvi.csr[0][0][index] = CSRArray[index];  
  end

  // PMP ADDR 3B0 to 3EF
  for(index='h3B0; index<='h3EF; index++) begin
    assign CSR_W[index] = (CSRArrayOld[index] != CSRArray[index]) ? 1 : 0;
    assign rvvi.csr_wb[0][0][index] = CSR_W[index];
    assign rvvi.csr[0][0][index] = CSRArray[index];  
  end

  // *** implementation only cancel? so sc does not clear?
  assign rvvi.lrsc_cancel[0][0] = 0;

  integer index2;

  string  instrWName;
  int     file;
  string  LogFile;
  if(`STD_LOG) begin
    instrNameDecTB NameDecoder(rvvi.insn[0][0], instrWName);
    initial begin
      LogFile = "logs/boottrace.log";
      file = $fopen(LogFile, "w");
    end
  end
  
  always_ff @(posedge clk) begin
	if(valid) begin
      if(`STD_LOG) begin
        $fwrite(file, "%016x, %08x, %s\t\t", rvvi.pc_rdata[0][0], rvvi.insn[0][0], instrWName);
        for(index2 = 0; index2 < `NUM_REGS; index2 += 1) begin
          if(rvvi.x_wb[0][0][index2]) begin
            $fwrite(file, "rf[%02d] = %016x ", index2, rvvi.x_wdata[0][0][index2]);
          end
        end
      end
      for(index2 = 0; index2 < `NUM_REGS; index2 += 1) begin
        if(rvvi.f_wb[0][0][index2]) begin
          $fwrite(file, "frf[%02d] = %016x ", index2, rvvi.f_wdata[0][0][index2]);
        end
      end
      for(index2 = 0; index2 < `NUM_CSRS; index2 += 1) begin
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
        for(index2 = 0; index2 < `NUM_REGS; index2 += 1) begin
          $display("x%02d = %08x", index2, rvvi.x_wdata[0][0][index2]);
        end
        for(index2 = 0; index2 < `NUM_REGS; index2 += 1) begin
          $display("f%02d = %08x", index2, rvvi.f_wdata[0][0][index2]);
        end
      end
      if (`PRINT_CSRS) begin
        for(index2 = 0; index2 < `NUM_CSRS; index2 += 1) begin
          if(CSR_W[index2]) begin
            $display("%t: CSR %03x = %x", $time(), index2, CSRArray[index2]);
          end
        end
      end
    end
    if(HaltW) $finish;
  end
endmodule

