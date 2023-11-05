///////////////////////////////////////////
// testbench-linux.sv
//
// Written: nboorstin@g.hmc.edu 2021
// Modified: 
//
// Purpose: Testbench for Buildroot Linux
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

`include "config.vh"
`include "BranchPredictorType.vh"

// This is set from the command line script
// `define USE_IMPERAS_DV

`ifdef USE_IMPERAS_DV
    `include "idv/idv.svh"
`endif

import cvw::*;

`define DEBUG_TRACE 0
// Debug Levels
// 0: don't check against QEMU
// 1: print disagreements with QEMU, but only halt on PCW disagreements
// 2: halt on any disagreement with QEMU except CSRs
// 3: halt on all disagreements with QEMU
// 4: print memory accesses whenever they happen
// 5: print everything

module testbench;
  ///////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////// CONFIG ////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Recommend setting all of these in 'do' script using -G option
  parameter INSTR_LIMIT  = 0; // # of instructions at which to stop
  parameter INSTR_WAVEON = 0; // # of instructions at which to turn on waves in graphical sim
  parameter CHECKPOINT   = 0;
  parameter RISCV_DIR = "/opt/riscv";
  parameter NO_SPOOFING = 0;


  `ifdef USE_IMPERAS_DV
    import idvPkg::*;
    import rvviApiPkg::*;
    import idvApiPkg::*;
  `endif


  `include "parameter-defs.vh"



  ////////////////////////////////////////////////////////////////////////////////////
  //////////////////////// SIGNAL / VAR / MACRO DECLARATIONS /////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////
  // ========== Testbench Core ==========
  integer warningCount = 0;
  integer errorCount = 0;
  integer fault;
  string  ProgramAddrMapFile, ProgramLabelMapFile;
  // ========== Initialization ==========
  string  testvectorDir;
  string  linuxImageDir;
  integer memFile;
  integer readResult;
  // ========== Checkpointing ==========
  string checkpointDir;
  logic [1:0] initPriv;
  // ========== Trace parsing & checking ==========
  integer garbageInt;
  string  garbageString;
  `define DECLARE_TRACE_SCANNER_SIGNALS(STAGE) \
      integer traceFile``STAGE; \
      integer matchCount``STAGE; \
      string  line``STAGE; \
      string  token``STAGE; \
      string  ExpectedTokens``STAGE [31:0]; \
      integer index``STAGE; \
      integer StartIndex``STAGE, EndIndex``STAGE; \
      integer TokenIndex``STAGE; \
      integer MarkerIndex``STAGE; \
      integer NumCSR``STAGE; \
      logic [P.XLEN-1:0] ExpectedPC``STAGE; \
      logic [31:0]      ExpectedInstr``STAGE; \
      string            text``STAGE; \
      string            MemOp``STAGE; \
      string            RegWrite``STAGE; \
      integer           ExpectedRegAdr``STAGE; \
      logic [P.XLEN-1:0] ExpectedRegValue``STAGE; \
      logic [P.XLEN-1:0] ExpectedIEUAdr``STAGE, ExpectedMemReadData``STAGE, ExpectedMemWriteData``STAGE; \
      string            ExpectedCSRArray``STAGE[10:0]; \
      logic [P.XLEN-1:0] ExpectedCSRArrayValue``STAGE[10:0]; // *** might be redundant?
  `DECLARE_TRACE_SCANNER_SIGNALS(E)
  `DECLARE_TRACE_SCANNER_SIGNALS(M)
  //  M-stage expected values
  logic             checkInstrM;
  integer           MIPexpected, SIPexpected;
  string            name;
  logic [P.AHBW-1:0] readDataExpected;
  // W-stage expected values
  logic             checkInstrW;
  logic [P.XLEN-1:0] ExpectedPCW;
  logic [31:0]      ExpectedInstrW;
  string            textW;
  string            RegWriteW;
  integer           ExpectedRegAdrW;
  logic [P.XLEN-1:0] ExpectedRegValueW;
  string            MemOpW;
  logic [P.XLEN-1:0] ExpectedIEUAdrW, ExpectedMemReadDataW, ExpectedMemWriteDataW;
  integer           NumCSRW;
  string            ExpectedCSRArrayW[10:0];
  logic [P.XLEN-1:0] ExpectedCSRArrayValueW[10:0];
  logic [P.XLEN-1:0] ExpectedIntType;
  integer           NumCSRWIndex;
  integer           NumCSRPostWIndex;
  logic [P.XLEN-1:0] InstrCountW;
  // ========== Interrupt parsing & spoofing ==========
  string  interrupt;
  string  interruptLine;
  integer interruptFile;
  integer interruptInstrCount;
  integer interruptHartVal;
  integer interruptAsyncVal;
  longint interruptCauseVal;
  longint interruptEpcVal;
  longint interruptTVal;
  string  interruptDesc;
  integer           NextMIPexpected, NextSIPexpected;
  integer           NextMepcExpected;
  logic [P.XLEN-1:0] AttemptedInstructionCount;
  // ========== Misc Aliases ==========
  `define RF dut.core.ieu.dp.regf.rf
  `define PC dut.core.ifu.pcreg.q
  `define PRIV_BASE   dut.core.priv.priv
  `define PRIV        `PRIV_BASE.privmode.privmode.privmodereg.q
  `define CSR_BASE    `PRIV_BASE.csr
  `define MEIP        `PRIV_BASE.MExtInt
  `define SEIP        `PRIV_BASE.SExtInt
  `define MTIP        `PRIV_BASE.MTimerInt
  `define HPMCOUNTER  `CSR_BASE.counters.counters.HPMCOUNTER_REGW
  `define MEDELEG     `CSR_BASE.csrm.deleg.MEDELEGreg.q
  `define MIDELEG     `CSR_BASE.csrm.deleg.MIDELEGreg.q
  `define MIE         `CSR_BASE.csri.MIE_REGW
  `define MIP         `CSR_BASE.csri.MIP_REGW_writeable
  `define MCAUSE      `CSR_BASE.csrm.MCAUSEreg.q
  `define SCAUSE      `CSR_BASE.csrs.csrs.SCAUSEreg.q
  `define MEPC        `CSR_BASE.csrm.MEPCreg.q
  `define SEPC        `CSR_BASE.csrs.csrs.SEPCreg.q
  `define MCOUNTEREN  `CSR_BASE.csrm.mcounteren.MCOUNTERENreg.q
  `define SCOUNTEREN  `CSR_BASE.csrs.csrs.SCOUNTERENreg.q
  `define MSCRATCH    `CSR_BASE.csrm.MSCRATCHreg.q
  `define SSCRATCH    `CSR_BASE.csrs.csrs.SSCRATCHreg.q
  `define MTVEC       `CSR_BASE.csrm.MTVECreg.q
  `define STVEC       `CSR_BASE.csrs.csrs.STVECreg.q
  `define SATP        `CSR_BASE.csrs.csrs.genblk2.SATPreg.q
  `define INSTRET     `CSR_BASE.counters.counters.HPMCOUNTER_REGW[2]
  `define MSTATUS     `CSR_BASE.csrsr.MSTATUS_REGW
  `define SSTATUS     `CSR_BASE.csrsr.SSTATUS_REGW  
  `define STATUS_TSR  `CSR_BASE.csrsr.STATUS_TSR_INT
  `define STATUS_TW   `CSR_BASE.csrsr.STATUS_TW_INT
  `define STATUS_TVM  `CSR_BASE.csrsr.STATUS_TVM_INT
  `define STATUS_MXR  `CSR_BASE.csrsr.STATUS_MXR_INT
  `define STATUS_SUM  `CSR_BASE.csrsr.STATUS_SUM_INT
  `define STATUS_MPRV `CSR_BASE.csrsr.STATUS_MPRV_INT
  `define STATUS_FS   `CSR_BASE.csrsr.STATUS_FS_INT
  `define STATUS_MPP  `CSR_BASE.csrsr.STATUS_MPP
  `define STATUS_SPP  `CSR_BASE.csrsr.STATUS_SPP
  `define STATUS_MPIE `CSR_BASE.csrsr.STATUS_MPIE
  `define STATUS_SPIE `CSR_BASE.csrsr.STATUS_SPIE
  `define STATUS_MIE  `CSR_BASE.csrsr.STATUS_MIE
  `define STATUS_SIE  `CSR_BASE.csrsr.STATUS_SIE
  `define UART dut.uncore.uncore.uart.uart.u
  `define UART_IER `UART.IER
  `define UART_LCR `UART.LCR
  `define UART_MCR `UART.MCR
  `define UART_SCR `UART.SCR
  `define UART_IP `UART.INTR
  `define PLIC dut.uncore.uncore.plic.plic
  `define PLIC_INT_PRIORITY `PLIC.intPriority
  `define PLIC_INT_ENABLE   `PLIC.intEn
  `define PLIC_THRESHOLD    `PLIC.intThreshold
  `define PCM dut.core.ifu.PCM
  // ========== COMMON MACROS ==========
  // Needed for initialization and core
  `define SCAN_NEW_INTERRUPT \
    begin \
      $fgets(interruptLine, interruptFile); \
      //$display("Time %t, interruptLine %x", $time, interruptLine); \
      $fgets(interruptLine, interruptFile); \
      $sscanf(interruptLine, "%d", interruptInstrCount); \
      $fgets(interruptLine, interruptFile); \
      $sscanf(interruptLine, "%d", interruptHartVal); \
      $fgets(interruptLine, interruptFile); \
      $sscanf(interruptLine, "%d", interruptAsyncVal); \
      $fgets(interruptLine, interruptFile); \
      $sscanf(interruptLine, "%x", interruptCauseVal); \
      $fgets(interruptLine, interruptFile); \
      $sscanf(interruptLine, "%x", interruptEpcVal); \
      $fgets(interruptLine, interruptFile); \
      $sscanf(interruptLine, "%x", interruptTVal); \
      $fgets(interruptLine, interruptFile); \
      $sscanf(interruptLine, "%s", interruptDesc); \
    end 







  ///////////////////////////////////////////////////////////////////////////////
  /////////////////////////////// Cache Issue ///////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
 
   // Duplicate copy of pipeline registers that are optimized out of some configurations
  logic [31:0] NextInstrE, InstrM;
  mux2    #(32)     FlushInstrMMux(dut.core.ifu.InstrE, dut.core.ifu.nop, dut.core.ifu.FlushM, NextInstrE);
  flopenr #(32)     InstrMReg(clk, reset, ~dut.core.ifu.StallM, NextInstrE, InstrM);

  logic       probe;
  if (NO_SPOOFING)
    assign probe = testbench.dut.core.PCM == 64'hffffffff80200c8c
                   & InstrM != 32'h14021273
                   & testbench.dut.core.InstrValidM;








  ///////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////// HARDWARE ///////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Clock and Reset
  logic clk, reset_ext; 
  logic reset;
  initial begin reset_ext <= 1; # 22; reset_ext <= 0; end
  always begin clk <= 1; # 5; clk <= 0; # 5; end
  // Wally Interface
  logic [P.AHBW-1:0] HRDATAEXT;
  logic             HREADYEXT, HRESPEXT;
  logic             HCLK, HRESETn;
  logic             HREADY;
  logic 	    HSELEXT;
  logic [P.PA_BITS-1:0] HADDR;
  logic [P.AHBW-1:0] HWDATA;
  logic [P.XLEN/8-1:0] HWSTRB;
  logic             HWRITE;
  logic [2:0]       HSIZE;
  logic [2:0]       HBURST;
  logic [3:0]       HPROT;
  logic [1:0]       HTRANS;
  logic             HMASTLOCK;
  logic [31:0]      GPIOIN;
  logic [31:0]      GPIOOUT, GPIOEN;
  logic             UARTSin, UARTSout;

  // FPGA-specific Stuff
  logic SDCCLK;
  logic SDCCmdIn;
  logic SDCCmdOut;
  logic SDCCmdOE;
  logic [3:0] SDCDatIn;
  logic       SDCIntr;
  logic        SPIIn, SPIOut;
  logic [3:0]  SPICS;


  // Hardwire UART, GPIO pins
  assign GPIOIN = 0;
  assign UARTSin = 1;
  assign SDCIntr = 0;

  
  
  `ifdef USE_IMPERAS_DV

      logic         DCacheFlushDone, DCacheFlushStart;

      rvviTrace #(.XLEN(P.XLEN), .FLEN(P.FLEN)) rvvi();
      wallyTracer #(P) wallyTracer(rvvi);

      trace2log idv_trace2log(rvvi);
//      trace2cov idv_trace2cov(rvvi);

      // enabling of comparison types
      trace2api #(.CMP_PC      (1),
                  .CMP_INS     (1),
                  .CMP_GPR     (1),
                  .CMP_FPR     (1),
                  .CMP_VR      (0),
                  .CMP_CSR     (1)
                 ) idv_trace2api(rvvi);

      initial begin
        int iter;
        #1;
        IDV_MAX_ERRORS = 3;

        // Initialize REF (do this before initializing the DUT)
        if (!rvviVersionCheck(RVVI_API_VERSION)) begin
          $display($sformatf("%m @ t=%0t: Expecting RVVI API version %0d.", $time, RVVI_API_VERSION));
          $fatal;
        end
      
        void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_VENDOR,            "riscv.ovpworld.org"));
        void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_NAME,              "riscv"));
        void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_VARIANT,           "RV64GC"));
        void'(rvviRefConfigSetInt(IDV_CONFIG_MODEL_ADDRESS_BUS_WIDTH,     56));
        void'(rvviRefConfigSetInt(IDV_CONFIG_MAX_NET_LATENCY_RETIREMENTS, 6));

        if (!rvviRefInit("")) begin
          $display($sformatf("%m @ t=%0t: rvviRefInit failed", $time));
          $fatal;
        end

        // Volatile CSRs
        void'(rvviRefCsrSetVolatile(0, 32'hC00));   // CYCLE
        void'(rvviRefCsrSetVolatile(0, 32'hB00));   // MCYCLE
        void'(rvviRefCsrSetVolatile(0, 32'hC02));   // INSTRET
        void'(rvviRefCsrSetVolatile(0, 32'hB02));   // MINSTRET
        void'(rvviRefCsrSetVolatile(0, 32'hC01));   // TIME
        
        // User HPMCOUNTER3 - HPMCOUNTER31
        for (iter='hC03; iter<='hC1F; iter++) begin
          void'(rvviRefCsrSetVolatile(0, iter));   // HPMCOUNTERx
        end       
        
        // Machine MHPMCOUNTER3 - MHPMCOUNTER31
        for (iter='hB03; iter<='hB1F; iter++) begin
          void'(rvviRefCsrSetVolatile(0, iter));   // MHPMCOUNTERx
        end       
        
        // cannot predict this register due to latency between
        // pending and taken
        void'(rvviRefCsrSetVolatile(0, 32'h344));   // MIP
        void'(rvviRefCsrSetVolatile(0, 32'h144));   // SIP

        // Privileges for PMA are set in the imperas.ic
        // volatile (IO) regions are defined here
        // only real ROM/RAM areas are BOOTROM and UNCORE_RAM
        if (P.CLINT_SUPPORTED) begin
            void'(rvviRefMemorySetVolatile(P.CLINT_BASE, (P.CLINT_BASE + P.CLINT_RANGE)));
        end
        if (P.GPIO_SUPPORTED) begin
            void'(rvviRefMemorySetVolatile(P.GPIO_BASE, (P.GPIO_BASE + P.GPIO_RANGE)));
        end
        if (P.UART_SUPPORTED) begin
            void'(rvviRefMemorySetVolatile(P.UART_BASE, (P.UART_BASE + P.UART_RANGE)));
        end
        if (P.PLIC_SUPPORTED) begin
            void'(rvviRefMemorySetVolatile(P.PLIC_BASE, (P.PLIC_BASE + P.PLIC_RANGE)));
        end
        if (P.SDC_SUPPORTED) begin
            void'(rvviRefMemorySetVolatile(P.SDC_BASE, (P.SDC_BASE + P.SDC_RANGE)));
        end

        if(P.XLEN==32) begin
            void'(rvviRefCsrSetVolatile(0, 32'hC80));   // CYCLEH
            void'(rvviRefCsrSetVolatile(0, 32'hB80));   // MCYCLEH
            void'(rvviRefCsrSetVolatile(0, 32'hC82));   // INSTRETH
            void'(rvviRefCsrSetVolatile(0, 32'hB82));   // MINSTRETH
        end

        void'(rvviRefCsrSetVolatile(0, 32'h104));   // SIE - Temporary!!!!
        
        // Load memory
        begin
            longint x64;
            int x32[2];
            longint index;
            
            $sformat(testvectorDir,"%s/linux-testvectors/",RISCV_DIR);

            $display("RVVI Loading bootmem.bin");
            memFile = $fopen({testvectorDir,"bootmem.bin"}, "rb");
            index = 'h1000 - 8;
            while(!$feof(memFile)) begin
                index+=8;
                readResult = $fread(x64, memFile);
                if (x64 == 0) continue;
                x32[0] = x64 & 'hffffffff;
                x32[1] = x64 >> 32;
                rvviRefMemoryWrite(0, index+0, x32[0], 4);
                rvviRefMemoryWrite(0, index+4, x32[1], 4);
                //$display("boot %08X x32[0]=%08X x32[1]=%08X", index, x32[0], x32[1]);
            end
            $fclose(memFile);
            
            $display("RVVI Loading ram.bin");
            memFile = $fopen({testvectorDir,"ram.bin"}, "rb");
            index = 'h80000000 - 8;
            while(!$feof(memFile)) begin
                index+=8;
                readResult = $fread(x64, memFile);
                if (x64 == 0) continue;
                x32[0] = x64 & 'hffffffff;
                x32[1] = x64 >> 32;
                rvviRefMemoryWrite(0, index+0, x32[0], 4);
                rvviRefMemoryWrite(0, index+4, x32[1], 4);
                //$display("ram  %08X x32[0]=%08X x32[1]=%08X", index, x32[0], x32[1]);
            end
            $fclose(memFile);
            
            $display("RVVI Loading Complete");
            
            void'(rvviRefPcSet(0, 'h1000)); // set BOOTROM address
        end
      end

      always @(dut.core.MTimerInt)   void'(rvvi.net_push("MTimerInterrupt",    dut.core.MTimerInt));
      always @(dut.core.MExtInt)     void'(rvvi.net_push("MExternalInterrupt", dut.core.MExtInt));
      always @(dut.core.SExtInt)     void'(rvvi.net_push("SExternalInterrupt", dut.core.SExtInt));
      always @(dut.core.MSwInt)      void'(rvvi.net_push("MSWInterrupt",       dut.core.MSwInt));
      always @(dut.core.priv.priv.csr.csrs.csrs.STimerInt) void'(rvvi.net_push("STimerInterrupt", dut.core.priv.priv.csr.csrs.csrs.STimerInt));

      final begin
        void'(rvviRefShutdown());
      end

  `endif
  

  // Wally
  wallypipelinedsoc #(P) dut(.clk, .reset_ext, .reset, .HRDATAEXT, .HREADYEXT, .HRESPEXT, .HSELEXT, .HSELEXTSDC,
                        .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
                        .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), .GPIOIN, .GPIOOUT, .GPIOEN,
                        .UARTSin, .UARTSout, .SDCIntr, .SPICS, .SPIOut, .SPIIn); 

  // W-stage hardware not needed by Wally itself 
  parameter nop = 'h13;
  logic [P.XLEN-1:0] PCW;
  logic [31:0]      InstrW;
  logic             InstrValidW;
  logic [P.XLEN-1:0] IEUAdrW, WriteDataW;
  logic             TrapW;
  `define FLUSHW dut.core.FlushW
  `define STALLW dut.core.StallW
  flopenrc #(P.XLEN)         PCWReg(clk, reset, `FLUSHW, ~`STALLW, `PCM, PCW);
  flopenr #(32)          InstrWReg(clk, reset, ~`STALLW, `FLUSHW ? nop : InstrM, InstrW);
  flopenrc #(1)        controlregW(clk, reset, `FLUSHW, ~`STALLW, dut.core.ieu.c.InstrValidM, InstrValidW);
  flopenrc #(P.XLEN)     IEUAdrWReg(clk, reset, `FLUSHW, ~`STALLW, dut.core.IEUAdrM, IEUAdrW);
  flopenrc #(P.XLEN)  WriteDataWReg(clk, reset, `FLUSHW, ~`STALLW, dut.core.lsu.WriteDataM, WriteDataW);  
  flopenr #(1)            TrapWReg(clk, reset, ~`STALLW, dut.core.hzu.TrapM, TrapW);










  ///////////////////////////////////////////////////////////////////////////////
  /////////////////////////////// INITIALIZATION ////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // ========== CHECKPOINTING ==========
  `define MAKE_CHECKPOINT_INIT_SIGNAL(SIGNAL,DIM,ARRAY_MAX,ARRAY_MIN) \
    logic DIM init``SIGNAL[ARRAY_MAX:ARRAY_MIN]; \
    initial begin \
      #1; \
      if (CHECKPOINT!=0) $readmemh({checkpointDir,"checkpoint-",`"SIGNAL`"}, init``SIGNAL); \
    end

  `define INIT_CHECKPOINT_SIMPLE_ARRAY(SIGNAL,DIM,ARRAY_MAX,ARRAY_MIN) \
    `MAKE_CHECKPOINT_INIT_SIGNAL(SIGNAL,DIM,ARRAY_MAX,ARRAY_MIN) \
    initial begin \
      if (CHECKPOINT!=0) begin \
        force `SIGNAL = init``SIGNAL[ARRAY_MAX:ARRAY_MIN]; \
        while (reset!==1) #1; \
        while (reset!==0) #1; \
        #1; \
        release `SIGNAL; \
      end \
    end

  `define INIT_CHECKPOINT_PACKED_ARRAY(SIGNAL,DIM,ARRAY_MAX,ARRAY_MIN) \
    `MAKE_CHECKPOINT_INIT_SIGNAL(SIGNAL,DIM,ARRAY_MAX,ARRAY_MIN) \
    for (i=ARRAY_MIN; i<ARRAY_MAX+1; i=i+1) begin \
      initial begin \
        if (CHECKPOINT!=0) begin \
          force `SIGNAL[i] = init``SIGNAL[i]; \
          while (reset!==1) #1; \
          while (reset!==0) #1; \
          #1; \
          release `SIGNAL[i]; \
        end \
      end \
    end

  // Note that dimension usage is very intentional here.
  // We are dancing around (un)packed type requirements.
  `define INIT_CHECKPOINT_VAL(SIGNAL,DIM) \
    `MAKE_CHECKPOINT_INIT_SIGNAL(SIGNAL,DIM,0,0) \
    initial begin \
      if (CHECKPOINT!=0) begin \
        force `SIGNAL = init``SIGNAL[0]; \
        while (reset!==1) #1; \
        while (reset!==0) #1; \
        #1; \
        release `SIGNAL; \
      end \
    end

  // Initializing all zeroes into the branch predictor memory.
  genvar adrindex;      
    for(adrindex = 0; adrindex < 1024; adrindex++) begin
      initial begin 
      force dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem[adrindex] = 0;
      force dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem[adrindex] = 0;
      #1;
      release dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem[adrindex];
      release dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem[adrindex];
      end
    end

  genvar i;
  `INIT_CHECKPOINT_SIMPLE_ARRAY(RF,         [P.XLEN-1:0],31,1);
  `INIT_CHECKPOINT_SIMPLE_ARRAY(HPMCOUNTER, [P.XLEN-1:0],P.COUNTERS-1,0);
  `INIT_CHECKPOINT_VAL(PC,         [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MEDELEG,    [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MIDELEG,    [P.XLEN-1:0]);
  if(!NO_SPOOFING) begin
    `INIT_CHECKPOINT_VAL(MIE,        [11:0]);
    `INIT_CHECKPOINT_VAL(MIP,        [11:0]);
    end
  `INIT_CHECKPOINT_VAL(MCAUSE,     [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(SCAUSE,     [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MEPC,       [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(SEPC,       [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MCOUNTEREN, [31:0]);
  `INIT_CHECKPOINT_VAL(SCOUNTEREN, [31:0]);
  `INIT_CHECKPOINT_VAL(MSCRATCH,   [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(SSCRATCH,   [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MTVEC,      [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(STVEC,      [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(SATP,       [P.XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(PRIV,       [1:0]);
  `INIT_CHECKPOINT_PACKED_ARRAY(PLIC_INT_PRIORITY, [2:0],P.PLIC_NUM_SRC,1);
  `MAKE_CHECKPOINT_INIT_SIGNAL(PLIC_INT_ENABLE, [P.PLIC_NUM_SRC:0],1,0);
  `INIT_CHECKPOINT_PACKED_ARRAY(PLIC_THRESHOLD, [2:0],1,0);
  // UART checkpointing does not cover entire UART state
  //     Many UART registers are difficult to initialize because under the hood
  //     they are not simple registers. Instead some are generated by interesting
  //     combinational blocks such that they depend upon a variety of different
  //     underlying flops. See for example how RBR might be the actual RXBR
  //     register, but it could also just as well be 0 or the tail of the fifo
  //     array.
  `INIT_CHECKPOINT_VAL(UART_IER,   [7:0]);
  `INIT_CHECKPOINT_VAL(UART_LCR,   [7:0]);
  `INIT_CHECKPOINT_VAL(UART_MCR,   [4:0]);
  `INIT_CHECKPOINT_VAL(UART_SCR,   [7:0]);
  // xSTATUS need to be handled manually because the most upstream signals
  // are made of individual bits, not registers
  `MAKE_CHECKPOINT_INIT_SIGNAL(MSTATUS, [P.XLEN-1:0],0,0);
  `MAKE_CHECKPOINT_INIT_SIGNAL(SSTATUS, [P.XLEN-1:0],0,0);  

  // ========== INITIALIZATION ==========
  initial begin
    if(!NO_SPOOFING) begin
      force `MEIP = 0;
      force `SEIP = 0;
      force `UART_IP = 0;
      force `MTIP = 0;
    end
    $sformat(testvectorDir,"%s/linux-testvectors/",RISCV_DIR);
    $sformat(linuxImageDir,"%s/buildroot/output/images/",RISCV_DIR);
    if (CHECKPOINT!=0)
      $sformat(checkpointDir,"%s/linux-testvectors/checkpoint%0d/",RISCV_DIR,CHECKPOINT);
    ProgramAddrMapFile = {linuxImageDir,"disassembly/vmlinux.objdump.addr"};
    ProgramLabelMapFile = {linuxImageDir,"disassembly/vmlinux.objdump.lab"};
    // initialize bootrom
    memFile = $fopen({testvectorDir,"bootmem.bin"}, "rb");
    readResult = $fread(dut.uncore.uncore.bootrom.bootrom.memory.ROM,memFile);
    $fclose(memFile);
    // initialize RAM and ROM
    if (CHECKPOINT==0) 
      memFile = $fopen({testvectorDir,"ram.bin"}, "rb");
    else
      memFile = $fopen({checkpointDir,"ram.bin"}, "rb");
    readResult = $fread(dut.uncore.uncore.ram.ram.memory.RAM,memFile);
    $fclose(memFile);
  
    // ---------- Ground-Zero -----------
    if (CHECKPOINT==0) begin
      traceFileM = $fopen({testvectorDir,"all.txt"}, "r");
      traceFileE = $fopen({testvectorDir,"all.txt"}, "r");
      interruptFile = $fopen({testvectorDir,"interrupts.txt"}, "r");
      `SCAN_NEW_INTERRUPT
      InstrCountW = '0;
      AttemptedInstructionCount = 1; // offset needed here when running from ground zero
    // ---------- Checkpoint ----------
    end else begin
      //$readmemh({checkpointDir,"ram.txt"}, dut.uncore.uncore.ram.ram.memory.RAM);
      traceFileE = $fopen({checkpointDir,"all.txt"}, "r");
      traceFileM = $fopen({checkpointDir,"all.txt"}, "r");
      interruptFile = $fopen({testvectorDir,"interrupts.txt"}, "r");
      `SCAN_NEW_INTERRUPT
      while(interruptInstrCount < CHECKPOINT) begin
        `SCAN_NEW_INTERRUPT
      end
      InstrCountW = CHECKPOINT;
      AttemptedInstructionCount = CHECKPOINT;
      // manual checkpoint initializations
      force {`STATUS_TSR,`STATUS_TW,`STATUS_TVM,`STATUS_MXR,`STATUS_SUM,`STATUS_MPRV} = initMSTATUS[0][22:17];
      force {`STATUS_FS,`STATUS_MPP} = initMSTATUS[0][14:11];
      force {`STATUS_SPP,`STATUS_MPIE} = initMSTATUS[0][8:7];
//      force {`STATUS_SPIE,`STATUS_UPIE,`STATUS_MIE} = initMSTATUS[0][5:3]; // dh removed UPIE and UIE 4/25/22 from depricated n-mode
      force {`STATUS_SPIE} = initMSTATUS[0][5];
      force {`STATUS_MIE} = initMSTATUS[0][3];
      force {`STATUS_SIE} = initMSTATUS[0][1];
      force `PLIC_INT_ENABLE = {initPLIC_INT_ENABLE[1][P.PLIC_NUM_SRC:1],initPLIC_INT_ENABLE[0][P.PLIC_NUM_SRC:1]}; // would need to expand into a generate loop to cover an arbitrary number of contexts
      force `INSTRET = CHECKPOINT;
      while (reset!==1) #1;
      while (reset!==0) #1;
      #1;
      release {`STATUS_TSR,`STATUS_TW,`STATUS_TVM,`STATUS_MXR,`STATUS_SUM,`STATUS_MPRV};
      release {`STATUS_FS,`STATUS_MPP};
      release {`STATUS_SPP,`STATUS_MPIE};
      release {`STATUS_SPIE,`STATUS_MIE};
      release {`STATUS_SIE};
      release `PLIC_INT_ENABLE;
      release `INSTRET;
    end
    // Get the E-stage trace reader ahead of the M-stage trace reader
    matchCountE = $fgets(lineE,traceFileE); // *** look at removing?
  end

  ///////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////// CORE /////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // =========== TRACE PARSING MACRO ==========
  // Because qemu does not match exactly to wally it is necessary to read the the
  // trace in the memory stage and detect if anything in wally must be overwritten.
  // This includes mtimer, interrupts, and various bits in mstatus and xtval.

  // then on the next posedge the expected state is registered.
  // on the next falling edge the expected state is compared to the wally state.

  // step 0: read the expected state
  `define SCAN_NEW_INSTR_FROM_TRACE(STAGE) \
    // always check PC, instruction bits \
    if (checkInstrM) begin \
      // read 1 line of the trace file \
      matchCount``STAGE = $fgets(line``STAGE, traceFile``STAGE); \
      if(`DEBUG_TRACE >= 5) $display("Time %t, line %x", $time, line``STAGE); \
      // extract PC, Instr \
      matchCount``STAGE = $sscanf(line``STAGE, "%x %x %s", ExpectedPC``STAGE, ExpectedInstr``STAGE, text``STAGE); \
      if (`"STAGE`"=="M") begin \
        AttemptedInstructionCount += 1; \
      end \
 \
      // for the life of me I cannot get any build in C or C++ string parsing functions/methods to work. \
      // strtok was the best idea but it cannot be used correctly as system verilog does not have null \
      // terminated strings. \
 \
      // Just going to do this char by char. \
      StartIndex``STAGE = 0; \
      TokenIndex``STAGE = 0; \
      //$display("len = %d", line``STAGE.len()); \
      for(index``STAGE = 0; index``STAGE < line``STAGE.len(); index``STAGE++) begin \
        //$display("char = %s", line``STAGE[index]); \
        if (line``STAGE[index``STAGE] == " " | line``STAGE[index``STAGE] == "\n") begin \
          EndIndex``STAGE = index``STAGE; \
          ExpectedTokens``STAGE[TokenIndex``STAGE] = line``STAGE.substr(StartIndex``STAGE, EndIndex``STAGE-1); \
          //$display("In Tokenizer %s", line``STAGE.substr(StartIndex, EndIndex-1)); \
          StartIndex``STAGE = EndIndex``STAGE + 1; \
          TokenIndex``STAGE++; \
        end \
      end \
 \
      MarkerIndex``STAGE = 3; \
      NumCSR``STAGE = 0; \
      MemOp``STAGE = ""; \
      RegWrite``STAGE = ""; \
 \
      #2; \
 \
      while(TokenIndex``STAGE > MarkerIndex``STAGE) begin \
        // parse the GPR \
        if (ExpectedTokens``STAGE[MarkerIndex``STAGE] == "GPR") begin \
          RegWrite``STAGE = ExpectedTokens``STAGE[MarkerIndex``STAGE]; \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+1], "%d", ExpectedRegAdr``STAGE); \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+2], "%x", ExpectedRegValue``STAGE); \
          MarkerIndex``STAGE += 3; \
        // parse memory address, read data, and/or write data \
        end else if(ExpectedTokens``STAGE[MarkerIndex``STAGE].substr(0, 2) == "Mem") begin \
          MemOp``STAGE = ExpectedTokens``STAGE[MarkerIndex``STAGE]; \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+1], "%x", ExpectedIEUAdr``STAGE); \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+2], "%x", ExpectedMemWriteData``STAGE); \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+3], "%x", ExpectedMemReadData``STAGE); \
          MarkerIndex``STAGE += 4; \
        // parse CSRs, because there are 1 or more CSRs after the CSR token \
        // we check if the CSR token or the number of CSRs is greater than 0. \
        // if so then we want to parse for a CSR. \
        end else if(ExpectedTokens``STAGE[MarkerIndex``STAGE] == "CSR" | NumCSR``STAGE > 0) begin \
          if(ExpectedTokens``STAGE[MarkerIndex``STAGE] == "CSR") begin \
            // all additional CSR's won't have this token. \
            MarkerIndex``STAGE++; \
          end \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE], "%s", ExpectedCSRArray``STAGE[NumCSR``STAGE]); \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+1], "%x", ExpectedCSRArrayValue``STAGE[NumCSR``STAGE]); \
          MarkerIndex``STAGE += 2; \
           \
          NumCSR``STAGE++; \
        end \
      end \
      if(`"STAGE`"=="M") begin \
        // override on special conditions \
        if ((dut.core.lsu.PAdrM == 'h10000002) | (dut.core.lsu.PAdrM == 'h10000005) | (dut.core.lsu.PAdrM == 'h10000006)) begin \
          if(!NO_SPOOFING) begin \
            $display("%tns, %d instrs: Overwrite UART's Register in memory stage.", $time, AttemptedInstructionCount); \
            force dut.core.lsu.ReadDataM = ExpectedMemReadDataM; \
          end \
        end else \
          if(!NO_SPOOFING) \
            release dut.core.lsu.ReadDataM; \
        if(textM.substr(0,5) == "rdtime") begin \
          //$display("%tns, %d instrs: Overwrite MTIME_CLINT on read of MTIME in memory stage.", $time, InstrCountW-1); \
          if(!NO_SPOOFING) \
            force dut.uncore.uncore.clint.clint.MTIME = ExpectedRegValueM; \
        end \
      end \
    end \
    
  // ========== VALUE-CHECKING MACROS ==========
  `define checkEQ(NAME, VAL, EXPECTED) \
    if(VAL != EXPECTED) begin \
      $display("%tns, %d instrs: %s %x differs from expected %x", $time, AttemptedInstructionCount, NAME, VAL, EXPECTED); \
      if ((NAME == "PCW") | (`DEBUG_TRACE >= 2)) fault = 1; \
    end

  `define checkCSR(CSR) \
    begin \
      if (CSR != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin \
        $display("%tns, %d instrs: CSR %s = %016x, does not equal expected value %016x", $time, AttemptedInstructionCount, ExpectedCSRArrayW[NumCSRPostWIndex], CSR, ExpectedCSRArrayValueW[NumCSRPostWIndex]); \
        if(`DEBUG_TRACE >= 3) fault = 1; \
      end \
    end

  // =========== CORE ===========
  assign checkInstrM = dut.core.ieu.InstrValidM & ~dut.core.priv.priv.trap.InstrPageFaultM & ~dut.core.priv.priv.trap.InterruptM & ~dut.core.StallM;
  always @(negedge clk) begin
    `SCAN_NEW_INSTR_FROM_TRACE(E)
    `SCAN_NEW_INSTR_FROM_TRACE(M)
  end

  // step 1: register expected state into the write back stage.
  always @(posedge clk) begin
    if (reset) begin
      ExpectedPCW <= '0;
      ExpectedInstrW <= '0;
      textW <= "";
      RegWriteW <= "";
      ExpectedRegAdrW <= '0;
      ExpectedRegValueW <= '0;
      ExpectedIEUAdrW <= '0;
      MemOpW <= "";
      ExpectedMemWriteDataW <= '0;
      ExpectedMemReadDataW <= '0;
      NumCSRW <= '0;
    end else if(~dut.core.StallW) begin
      if(dut.core.FlushW) begin
        ExpectedPCW <= '0;
        ExpectedInstrW <= '0;
        textW <= "";
        RegWriteW <= "";
        ExpectedRegAdrW <= '0;
        ExpectedRegValueW <= '0;
        ExpectedIEUAdrW <= '0;
        MemOpW <= "";
        ExpectedMemWriteDataW <= '0;
        ExpectedMemReadDataW <= '0;
        NumCSRW <= '0;
      end else if (dut.core.ieu.c.InstrValidM) begin 
        ExpectedPCW <= ExpectedPCM;
        ExpectedInstrW <= ExpectedInstrM;
        textW <= textM;
        RegWriteW <= RegWriteM;
        ExpectedRegAdrW <= ExpectedRegAdrM;
        ExpectedRegValueW <= ExpectedRegValueM;
        ExpectedIEUAdrW <= ExpectedIEUAdrM;
        MemOpW <= MemOpM;
        ExpectedMemWriteDataW <= ExpectedMemWriteDataM;
        ExpectedMemReadDataW <= ExpectedMemReadDataM;
        NumCSRW <= NumCSRM;
        for(NumCSRWIndex = 0; NumCSRWIndex < NumCSRM; NumCSRWIndex++) begin
          ExpectedCSRArrayW[NumCSRWIndex] = ExpectedCSRArrayM[NumCSRWIndex];
          ExpectedCSRArrayValueW[NumCSRWIndex] = ExpectedCSRArrayValueM[NumCSRWIndex];
        end
      end
      #1;
      // override on special conditions
      if(~dut.core.StallW) begin
        if(textW.substr(0,5) == "rdtime") begin
          //$display("%tns, %d instrs: Releasing force of MTIME_CLINT.", $time, AttemptedInstructionCount);
          if(!NO_SPOOFING)
            release dut.uncore.uncore.clint.clint.MTIME;
        end 
        //if (ExpectedIEUAdrM == 'h10000005) begin
          //$display("%tns, %d instrs: releasing force of ReadDataM.", $time, AttemptedInstructionCount);
          //release dut.core.ieu.dp.ReadDataM;
        //end
      end
    end
  end
  
  // step2: make all checks in the write back stage.
  assign checkInstrW = InstrValidW & ~dut.core.StallW; // trapW will already be invalid in there was an InstrPageFault in the previous instruction.
  always @(negedge clk) begin
    #1; // small delay allows interrupt spoofing to happen first
    // always check PC, instruction bits
    if (checkInstrW) begin
      InstrCountW += 1;
      // print progress message
      if (AttemptedInstructionCount % 'd100000 == 0) $display("Reached %d instructions", AttemptedInstructionCount);
      // turn on waves
      if (AttemptedInstructionCount == INSTR_WAVEON) $stop;
      // end sim
      if ((AttemptedInstructionCount == INSTR_LIMIT) & (INSTR_LIMIT!=0)) begin $stop; $stop; end
      fault = 0;
      if (`DEBUG_TRACE >= 1) begin
        `checkEQ("PCW",PCW,ExpectedPCW)
        //`checkEQ("InstrW",InstrW,ExpectedInstrW) <-- not viable because of
        // compressed to uncompressed conversion
        `checkEQ("Instr Count",dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[2],InstrCountW)
        #2; // delay 2 ns.
        if(`DEBUG_TRACE >= 5) begin
          $display("%tns, %d instrs: Reg Write Address %02d ? expected value: %02d", $time, AttemptedInstructionCount, dut.core.ieu.dp.regf.a3, ExpectedRegAdrW);
          $display("%tns, %d instrs: RF[%02d] %016x ? expected value: %016x", $time, AttemptedInstructionCount, ExpectedRegAdrW, dut.core.ieu.dp.regf.rf[ExpectedRegAdrW], ExpectedRegValueW);
        end
        if (RegWriteW == "GPR") begin
          `checkEQ("Reg Write Address",dut.core.ieu.dp.regf.a3,ExpectedRegAdrW)
          $sformat(name,"RF[%02d]",ExpectedRegAdrW);
          `checkEQ(name, dut.core.ieu.dp.regf.rf[ExpectedRegAdrW], ExpectedRegValueW)
        end
        if (MemOpW.substr(0,2) == "Mem") begin
          if(`DEBUG_TRACE >= 4) $display("\tIEUAdrW: %016x ? expected: %016x", IEUAdrW, ExpectedIEUAdrW);
          `checkEQ("IEUAdrW",IEUAdrW,ExpectedIEUAdrW)
          if(MemOpW == "MemR" | MemOpW == "MemRW") begin
            if(`DEBUG_TRACE >= 4) $display("\tReadDataW: %016x ? expected: %016x", dut.core.ieu.dp.ReadDataW, ExpectedMemReadDataW);
            `checkEQ("ReadDataW",dut.core.ieu.dp.ReadDataW,ExpectedMemReadDataW)
          end else if(MemOpW == "MemW" | MemOpW == "MemRW") begin
            if(`DEBUG_TRACE >= 4) $display("\tWriteDataW: %016x ? expected: %016x", WriteDataW, ExpectedMemWriteDataW);
            `checkEQ("WriteDataW",ExpectedMemWriteDataW,ExpectedMemWriteDataW)
          end
        end
        // check csr
        for(NumCSRPostWIndex = 0; NumCSRPostWIndex < NumCSRW; NumCSRPostWIndex++) begin
          case(ExpectedCSRArrayW[NumCSRPostWIndex])
            "mhartid": `checkCSR(`CSR_BASE.csrm.MHARTID_REGW)
            "mstatus": `checkCSR(`CSR_BASE.csrm.MSTATUS_REGW)
            "sstatus": `checkCSR(`CSR_BASE.csrs.csrs.SSTATUS_REGW)
            "mtvec":   `checkCSR(`CSR_BASE.csrm.MTVEC_REGW)
            "mie":     `checkCSR(`CSR_BASE.csrm.MIE_REGW)
            "mideleg": `checkCSR(`CSR_BASE.csrm.MIDELEG_REGW)
            "medeleg": `checkCSR(`CSR_BASE.csrm.MEDELEG_REGW)
            "mepc":    `checkCSR(`CSR_BASE.csrm.MEPC_REGW)
            "mtval":   `checkCSR(`CSR_BASE.csrm.MTVAL_REGW)
            "menvcfg": `checkCSR(`CSR_BASE.csrm.MENVCFG_REGW)
            "sepc":    `checkCSR(`CSR_BASE.csrs.csrs.SEPC_REGW)
            "scause":  `checkCSR(`CSR_BASE.csrs.csrs.SCAUSE_REGW)
            "stvec":   `checkCSR(`CSR_BASE.csrs.csrs.STVEC_REGW)
            "stval":   `checkCSR(`CSR_BASE.csrs.csrs.STVAL_REGW)
            // "senvcfg": `checkCSR(`CSR_BASE.csrs.SENVCFG_REGW) // *** fix me
            "mip": begin
                       `checkCSR(`CSR_BASE.csrm.MIP_REGW)
                       if(!NO_SPOOFING) begin
                         if ((ExpectedCSRArrayValueW[NumCSRPostWIndex] & 1<<11) == 0)
                           force `MEIP = 0;
                         if ((ExpectedCSRArrayValueW[NumCSRPostWIndex] & 1<<09) == 0)
                           force `SEIP = 0;
                         if ((ExpectedCSRArrayValueW[NumCSRPostWIndex] & ((1<<11) | (1<<09))) == 0)
                           force `UART_IP = 0;
                         if ((ExpectedCSRArrayValueW[NumCSRPostWIndex] & 1<<07) == 0)
                           force `MTIP = 0;
                       end
                   end
          endcase
        end
        if (fault == 1) begin
          errorCount +=1;
          $display("processed %0d instructions with %0d warnings", AttemptedInstructionCount, warningCount);
          $stop; $stop;
        end
      end // if (`DEBUG_TRACE >= 1)
    end // if (checkInstrW)
  end // always @ (negedge clk)


  // New IP spoofing
  logic globalIntsBecomeEnabled;
  assign globalIntsBecomeEnabled = (`CSR_BASE.csrm.WriteMSTATUSM || `CSR_BASE.csrs.csrs.WriteSSTATUSM) && (|(`CSR_BASE.CSRWriteValM & (~`CSR_BASE.csrm.MSTATUS_REGW) & 32'h22));
  logic checkInterruptM;
  assign checkInterruptM = dut.core.ieu.InstrValidM & ~dut.core.priv.priv.trap.InstrPageFaultM & ~dut.core.priv.priv.trap.InterruptM;
  
  always @(negedge clk) begin
    if(checkInterruptM) begin
      if((interruptInstrCount+1) == AttemptedInstructionCount) begin
        if(!NO_SPOOFING) begin
          case (interruptCauseVal)
            11: begin
                  force `MEIP = 1;
                  force `UART_IP = 1;
                end
            09: begin 
                  force `SEIP = 1;
                  force `UART_IP = 1;
                end
            07: force `MTIP = 1;
            default: $display("Unsupported interrupt in interrupts.txt. cause = %0d",interruptCauseVal);
          endcase
          $display("Forcing interrupt.");
        end
        `SCAN_NEW_INTERRUPT
        if (globalIntsBecomeEnabled) begin
            $display("Enabled global interrupts");
            // The idea here is if a CSR instruction causes an interrupt by
            // enabling interrupts, that CSR instruction will commit.
        end else begin
            // Other instructions, however, will get interrupted and not
            // commit, so we don't want our W-stage checker to look for them
            // and get confused when it doesn't find them.
            garbageInt = $fgets(garbageString,traceFileE);
            garbageInt = $fgets(garbageString,traceFileM);
            AttemptedInstructionCount += 1;
        end
      end
    end
  end










  ///////////////////////////////////////////////////////////////////////////////
  //////////////////////////////// Extra Features ///////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Function Tracking
  FunctionName #(P) FunctionName(.reset(reset),
                            .clk(clk),
                            .ProgramAddrMapFile(ProgramAddrMapFile),
                            .ProgramLabelMapFile(ProgramLabelMapFile));
  
  // Instr Opcode Tracking
  //   For waveview convenience
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  instrTrackerTB it(clk, reset, dut.core.ieu.dp.FlushE,
                dut.core.ifu.InstrRawF[31:0],
                dut.core.ifu.InstrD, dut.core.ifu.InstrE,
                InstrM,  InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // ------------------
  // Address Translator
  // ------------------
   /**
   * Walk the page table stored in ram according to sv39 logic and translate a
   * virtual address to a physical address.
   *
   * See section 4.3.2 of the RISC-V Privileged specification for a full
   * explanation of the below algorithm.
   */
  logic             SvMode, PTE_R, PTE_X;
  logic [P.XLEN-1:0] SATP, PTE;
  logic [55:0]      BaseAdr, PAdr;
  logic [8:0]       VPN [2:0];
  logic [11:0]      Offset;
  function logic [P.XLEN-1:0] adrTranslator( 
    input logic [P.XLEN-1:0] adrIn);
    begin
      int i;
      // Grab the SATP register from privileged unit
      SATP = dut.core.priv.priv.csr.SATP_REGW;
      // Split the virtual address into page number segments and offset
      VPN[2] = adrIn[38:30];
      VPN[1] = adrIn[29:21];
      VPN[0] = adrIn[20:12];
      Offset = adrIn[11:0];
      // We do not support sv48; only sv39
      SvMode = SATP[63];
      // Only perform translation if translation is on and the processor is not
      // in machine mode
      if (SvMode & (dut.core.priv.priv.PrivilegeModeW != P.M_MODE)) begin
        BaseAdr = SATP[43:0] << 12;
        for (i = 2; i >= 0; i--) begin
          PAdr = BaseAdr + (VPN[i] << 3);
          // ram.memory.RAM is 64-bit addressed. PAdr specifies a byte. We right shift
          // by 3 (the PTE size) to get the requested 64-bit PTE.
          PTE = dut.uncore.uncore.ram.ram.memory.RAM[PAdr >> 3];
          PTE_R = PTE[1];
          PTE_X = PTE[3];
          if (PTE_R | PTE_X) begin
            // Leaf page found
            break;
          end else begin
            // Go to next level of table
            BaseAdr = PTE[53:10] << 12;
          end
        end
        // Determine which parts of the PTE page number to use based on the
        // level of the page table we reached.
        if (i == 2) begin
          // Gigapage
          assign adrTranslator = {8'b0, PTE[53:28], VPN[1], VPN[0], Offset};
        end else if (i == 1) begin
          // Megapage
          assign adrTranslator = {8'b0, PTE[53:19], VPN[0], Offset};
        end else begin
          // Kilopage
          assign adrTranslator = {8'b0, PTE[53:10], Offset};
        end
      end else begin
        // Direct translation if address translation is not on
        assign adrTranslator = adrIn;
      end
    end
  endfunction
endmodule
