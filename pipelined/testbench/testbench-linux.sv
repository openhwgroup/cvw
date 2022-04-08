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

// When letting Wally go for it, let wally make own interrupts
///////////////////////////////////////////

`include "wally-config.vh"

`define DEBUG_TRACE 2
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
      logic [`XLEN-1:0] ExpectedPC``STAGE; \
      logic [31:0]      ExpectedInstr``STAGE; \
      string            text``STAGE; \
      string            MemOp``STAGE; \
      string            RegWrite``STAGE; \
      integer           ExpectedRegAdr``STAGE; \
      logic [`XLEN-1:0] ExpectedRegValue``STAGE; \
      logic [`XLEN-1:0] ExpectedIEUAdr``STAGE, ExpectedMemReadData``STAGE, ExpectedMemWriteData``STAGE; \
      string            ExpectedCSRArray``STAGE[10:0]; \
      logic [`XLEN-1:0] ExpectedCSRArrayValue``STAGE[10:0];
  `DECLARE_TRACE_SCANNER_SIGNALS(E)
  `DECLARE_TRACE_SCANNER_SIGNALS(M)
  //  M-stage expected values
  logic             checkInstrM;
  integer           MIPexpected, SIPexpected;
  string            name;
  logic [`AHBW-1:0] readDataExpected;
  // W-stage expected values
  logic             checkInstrW;
  logic [`XLEN-1:0] ExpectedPCW;
  logic [31:0]      ExpectedInstrW;
  string            textW;
  string            RegWriteW;
  integer           ExpectedRegAdrW;
  logic [`XLEN-1:0] ExpectedRegValueW;
  string            MemOpW;
  logic [`XLEN-1:0] ExpectedIEUAdrW, ExpectedMemReadDataW, ExpectedMemWriteDataW;
  integer           NumCSRW;
  string            ExpectedCSRArrayW[10:0];
  logic [`XLEN-1:0] ExpectedCSRArrayValueW[10:0];
  logic [`XLEN-1:0] ExpectedIntType;
  integer           NumCSRWIndex;
  integer           NumCSRPostWIndex;
  logic [`XLEN-1:0] InstrCountW;
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
  logic [`XLEN-1:0] AttemptedInstructionCount;
  // ========== Misc Aliases ==========
  `define RF dut.core.ieu.dp.regf.rf
  `define PC dut.core.ifu.pcreg.q
  `define PRIV dut.core.priv.priv.privmodereg.q
  `define CSR_BASE    dut.core.priv.priv.csr
  `define HPMCOUNTER  `CSR_BASE.counters.counters.HPMCOUNTER_REGW
  `define MEDELEG     `CSR_BASE.csrm.deleg.MEDELEGreg.q
  `define MIDELEG     `CSR_BASE.csrm.deleg.MIDELEGreg.q
  `define MIE         `CSR_BASE.csri.IE_REGW
  `define MIP         `CSR_BASE.csri.IP_REGW_writeable
  `define MCAUSE      `CSR_BASE.csrm.MCAUSEreg.q
  `define SCAUSE      `CSR_BASE.csrs.csrs.SCAUSEreg.q
  `define MEPC        `CSR_BASE.csrm.MEPCreg.q
  `define SEPC        `CSR_BASE.csrs.csrs.SEPCreg.q
  `define MCOUNTEREN  `CSR_BASE.csrm.MCOUNTERENreg.q
  `define SCOUNTEREN  `CSR_BASE.csrs.csrs.SCOUNTERENreg.q
  `define MSCRATCH    `CSR_BASE.csrm.MSCRATCHreg.q
  `define SSCRATCH    `CSR_BASE.csrs.csrs.SSCRATCHreg.q
  `define MTVEC       `CSR_BASE.csrm.MTVECreg.q
  `define STVEC       `CSR_BASE.csrs.csrs.STVECreg.q
  `define SATP        `CSR_BASE.csrs.csrs.genblk1.SATPreg.q
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
  `define STATUS_UPIE `CSR_BASE.csrsr.STATUS_UPIE
  `define STATUS_MIE  `CSR_BASE.csrsr.STATUS_MIE
  `define STATUS_SIE  `CSR_BASE.csrsr.STATUS_SIE
  `define STATUS_UIE  `CSR_BASE.csrsr.STATUS_UIE
  `define UART dut.uncore.uart.uart.u
  `define UART_IER `UART.IER
  `define UART_LCR `UART.LCR
  `define UART_MCR `UART.MCR
  `define UART_SCR `UART.SCR
  `define PLIC dut.uncore.plic.plic
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
  ////////////////////////////////// HARDWARE ///////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Clock and Reset
  logic clk, reset_ext; 
  logic reset;
  initial begin reset_ext <= 1; # 22; reset_ext <= 0; end
  always begin clk <= 1; # 5; clk <= 0; # 5; end
  // Wally Interface
  logic [`AHBW-1:0] HRDATAEXT;
  logic             HREADYEXT, HRESPEXT;
  logic             HCLK, HRESETn;
  logic             HREADY;
  logic 	    HSELEXT;
  logic [31:0]      HADDR;
  logic [`AHBW-1:0] HWDATA;
  logic             HWRITE;
  logic [2:0]       HSIZE;
  logic [2:0]       HBURST;
  logic [3:0]       HPROT;
  logic [1:0]       HTRANS;
  logic             HMASTLOCK;
  logic [31:0]      GPIOPinsIn;
  logic [31:0]      GPIOPinsOut, GPIOPinsEn;
  logic             UARTSin, UARTSout;

  // FPGA-specific Stuff
  logic SDCCLK;
  logic SDCCmdIn;
  logic SDCCmdOut;
  logic SDCCmdOE;
  logic [3:0] SDCDatIn;

  // Hardwire UART, GPIO pins
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;

  // Wally
  wallypipelinedsoc dut(.clk, .reset, .reset_ext,
                        .HRDATAEXT, .HREADYEXT, .HREADY, .HSELEXT, .HRESPEXT, .HCLK, 
			.HRESETn, .HADDR, .HWDATA, .HWRITE, .HSIZE, .HBURST, .HPROT, 
			.HTRANS, .HMASTLOCK, 
			.TIMECLK('0), .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn,
                        .UARTSin, .UARTSout,
			.SDCCLK, .SDCCmdIn, .SDCCmdOut, .SDCCmdOE, .SDCDatIn);

  // W-stage hardware not needed by Wally itself 
  parameter nop = 'h13;
  logic [`XLEN-1:0] PCW;
  logic [31:0]      InstrW;
  logic             InstrValidW;
  logic [`XLEN-1:0] IEUAdrW, WriteDataW;
  logic             TrapW;
  `define FLUSHW dut.core.FlushW
  `define STALLW dut.core.StallW
  flopenrc #(`XLEN)         PCWReg(clk, reset, `FLUSHW, ~`STALLW, `PCM, PCW);
  flopenr #(32)          InstrWReg(clk, reset, ~`STALLW, `FLUSHW ? nop : dut.core.ifu.InstrM, InstrW);
  flopenrc #(1)        controlregW(clk, reset, `FLUSHW, ~`STALLW, dut.core.ieu.c.InstrValidM, InstrValidW);
  flopenrc #(`XLEN)     IEUAdrWReg(clk, reset, `FLUSHW, ~`STALLW, dut.core.IEUAdrM, IEUAdrW);
  flopenrc #(`XLEN)  WriteDataWReg(clk, reset, `FLUSHW, ~`STALLW, dut.core.lsu.WriteDataM, WriteDataW);  
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

  genvar i;
  `INIT_CHECKPOINT_SIMPLE_ARRAY(RF,         [`XLEN-1:0],31,1);
  `INIT_CHECKPOINT_SIMPLE_ARRAY(HPMCOUNTER, [`XLEN-1:0],`COUNTERS-1,0);
  `INIT_CHECKPOINT_VAL(PC,         [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MEDELEG,    [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MIDELEG,    [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MIE,        [11:0]);
  `INIT_CHECKPOINT_VAL(MIP,        [11:0]);
  `INIT_CHECKPOINT_VAL(MCAUSE,     [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(SCAUSE,     [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MEPC,       [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(SEPC,       [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MCOUNTEREN, [31:0]);
  `INIT_CHECKPOINT_VAL(SCOUNTEREN, [31:0]);
  `INIT_CHECKPOINT_VAL(MSCRATCH,   [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(SSCRATCH,   [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(MTVEC,      [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(STVEC,      [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(SATP,       [`XLEN-1:0]);
  `INIT_CHECKPOINT_VAL(PRIV,       [1:0]);
  `INIT_CHECKPOINT_PACKED_ARRAY(PLIC_INT_PRIORITY, [2:0],`PLIC_NUM_SRC,1);
  `INIT_CHECKPOINT_PACKED_ARRAY(PLIC_INT_ENABLE, [`PLIC_NUM_SRC:1],1,0);
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
  `MAKE_CHECKPOINT_INIT_SIGNAL(MSTATUS, [`XLEN-1:0],0,0);
  `MAKE_CHECKPOINT_INIT_SIGNAL(SSTATUS, [`XLEN-1:0],0,0);  

  // ========== INITIALIZATION ==========
  initial begin
    //force dut.core.priv.priv.SwIntM = 0;
    force dut.core.priv.priv.TimerIntM = 0;
    force dut.core.priv.priv.MExtIntM = 0;    
    force dut.core.priv.priv.SExtIntM = 0;    
    $sformat(testvectorDir,"%s/linux-testvectors/",RISCV_DIR);
    $sformat(linuxImageDir,"%s/buildroot/output/images/",RISCV_DIR);
    if (CHECKPOINT!=0)
      $sformat(checkpointDir,"%s/linux-testvectors/checkpoint%0d/",RISCV_DIR,CHECKPOINT);
    $readmemb(`TWO_BIT_PRELOAD, dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem);
    $readmemb(`BTB_PRELOAD, dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem);
    ProgramAddrMapFile = {linuxImageDir,"disassembly/vmlinux.objdump.addr"};
    ProgramLabelMapFile = {linuxImageDir,"disassembly/vmlinux.objdump.lab"};
    // initialize bootrom
    memFile = $fopen({testvectorDir,"bootmem.bin"}, "rb");
    readResult = $fread(dut.uncore.bootrom.bootrom.memory.RAM,memFile);
    $fclose(memFile);
    // initialize RAM
    if (CHECKPOINT==0) 
      memFile = $fopen({testvectorDir,"ram.bin"}, "rb");
    else
      memFile = $fopen({checkpointDir,"ram.bin"}, "rb");
    readResult = $fread(dut.uncore.ram.ram.memory.RAM,memFile);
    $fclose(memFile);
    // ---------- Ground-Zero -----------
    if (CHECKPOINT==0) begin
      traceFileM = $fopen({testvectorDir,"all.txt"}, "r");
      traceFileE = $fopen({testvectorDir,"all.txt"}, "r");
      interruptFile = $fopen({testvectorDir,"interrupts.txt"}, "r");
      `SCAN_NEW_INTERRUPT
      InstrCountW = '0;
      AttemptedInstructionCount = '0;
    // ---------- Checkpoint ----------
    end else begin
      //$readmemh({checkpointDir,"ram.txt"}, dut.uncore.ram.ram.memory.RAM);
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
      force {`STATUS_SPIE,`STATUS_UPIE,`STATUS_MIE} = initMSTATUS[0][5:3];
      force {`STATUS_SIE,`STATUS_UIE} = initMSTATUS[0][1:0];
      force `INSTRET = CHECKPOINT;
      while (reset!==1) #1;
      while (reset!==0) #1;
      #1;
      release {`STATUS_TSR,`STATUS_TW,`STATUS_TVM,`STATUS_MXR,`STATUS_SUM,`STATUS_MPRV};
      release {`STATUS_FS,`STATUS_MPP};
      release {`STATUS_SPP,`STATUS_MPIE};
      release {`STATUS_SPIE,`STATUS_UPIE,`STATUS_MIE};
      release {`STATUS_SIE,`STATUS_UIE};
      release `INSTRET;
    end
    // Get the E-stage trace reader ahead of the M-stage trace reader
    matchCountE = $fgets(lineE,traceFileE);
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
          if (line``STAGE[index``STAGE] == "\n" & `"STAGE`"=="M") begin \
            AttemptedInstructionCount += 1; \
          end \
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
        if ((dut.core.lsu.LSUPAdrM == 'h10000002) | (dut.core.lsu.LSUPAdrM == 'h10000005) | (dut.core.lsu.LSUPAdrM == 'h10000006)) \
          //$display("%tns, %d instrs: Overwrite UART's LSR in memory stage.", $time, InstrCountW-1); \
          force dut.core.ieu.dp.ReadDataM = ExpectedMemReadDataM; \
        else \
          release dut.core.ieu.dp.ReadDataM; \
        if(textM.substr(0,5) == "rdtime") begin \
          //$display("%tns, %d instrs: Overwrite MTIME_CLINT on read of MTIME in memory stage.", $time, InstrCountW-1); \
          force dut.uncore.clint.clint.MTIME = ExpectedRegValueM; \
        end \
      end \
    end \
    
  // ========== VALUE-CHECKING MACROS ==========
  `define checkEQ(NAME, VAL, EXPECTED) \
    if(VAL != EXPECTED) begin \
      $display("%tns, %d instrs: %s %x differs from expected %x", $time, InstrCountW, NAME, VAL, EXPECTED); \
      if ((NAME == "PCW") | (`DEBUG_TRACE >= 2)) fault = 1; \
    end

  `define checkCSR(CSR) \
    begin \
      if (CSR != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin \
        $display("%tns, %d instrs: CSR %s = %016x, does not equal expected value %016x", $time, InstrCountW, ExpectedCSRArrayW[NumCSRPostWIndex], CSR, ExpectedCSRArrayValueW[NumCSRPostWIndex]); \
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
          //$display("%tns, %d instrs: Releasing force of MTIME_CLINT.", $time, InstrCountW);
          release dut.uncore.clint.clint.MTIME;
        end 
        //if (ExpectedIEUAdrM == 'h10000005) begin
          //$display("%tns, %d instrs: releasing force of ReadDataM.", $time, InstrCountW);
          //release dut.core.ieu.dp.ReadDataM;
        //end
      end
    end
  end
  
  // step2: make all checks in the write back stage.
  assign checkInstrW = InstrValidW & ~dut.core.StallW; // trapW will already be invalid in there was an InstrPageFault in the previous instruction.
  always @(negedge clk) begin
    // always check PC, instruction bits
    if (checkInstrW) begin
      InstrCountW += 1;
      // print progress message
      if (InstrCountW % 'd100000 == 0) $display("Reached %d instructions", InstrCountW);
      // turn on waves
      if (InstrCountW == INSTR_WAVEON) $stop;
      // end sim
      if ((InstrCountW == INSTR_LIMIT) & (INSTR_LIMIT!=0)) $stop;
      fault = 0;
      if (`DEBUG_TRACE >= 1) begin
        `checkEQ("PCW",PCW,ExpectedPCW)
        //`checkEQ("InstrW",InstrW,ExpectedInstrW) <-- not viable because of
        // compressed to uncompressed conversion
        `checkEQ("Instr Count",dut.core.priv.priv.csr.counters.counters.INSTRET_REGW,InstrCountW)
        #2; // delay 2 ns.
        if(`DEBUG_TRACE >= 5) begin
          $display("%tns, %d instrs: Reg Write Address %02d ? expected value: %02d", $time, InstrCountW, dut.core.ieu.dp.regf.a3, ExpectedRegAdrW);
          $display("%tns, %d instrs: RF[%02d] %016x ? expected value: %016x", $time, InstrCountW, ExpectedRegAdrW, dut.core.ieu.dp.regf.rf[ExpectedRegAdrW], ExpectedRegValueW);
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
            "mhartid": `checkCSR(dut.core.priv.priv.csr.csrm.MHARTID_REGW)
            "mstatus": `checkCSR(dut.core.priv.priv.csr.csrm.MSTATUS_REGW)
            "sstatus": `checkCSR(dut.core.priv.priv.csr.csrs.SSTATUS_REGW)
            "mtvec":   `checkCSR(dut.core.priv.priv.csr.csrm.MTVEC_REGW)
            "mip":     `checkCSR(dut.core.priv.priv.csr.csrm.MIP_REGW)
            "mie":     `checkCSR(dut.core.priv.priv.csr.csrm.MIE_REGW)
            "sip":     `checkCSR(dut.core.priv.priv.csr.csrs.SIP_REGW)
            "sie":     `checkCSR(dut.core.priv.priv.csr.csrs.SIE_REGW)
            "mideleg": `checkCSR(dut.core.priv.priv.csr.csrm.MIDELEG_REGW)
            "medeleg": `checkCSR(dut.core.priv.priv.csr.csrm.MEDELEG_REGW)
            "mepc":    `checkCSR(dut.core.priv.priv.csr.csrm.MEPC_REGW)
            "mtval":   `checkCSR(dut.core.priv.priv.csr.csrm.MTVAL_REGW)
            "sepc":    `checkCSR(dut.core.priv.priv.csr.csrs.SEPC_REGW)
            "scause":  `checkCSR(dut.core.priv.priv.csr.csrs.csrs.SCAUSE_REGW)
            "stvec":   `checkCSR(dut.core.priv.priv.csr.csrs.STVEC_REGW)
            "stval":   `checkCSR(dut.core.priv.priv.csr.csrs.csrs.STVAL_REGW)
          endcase
        end
        if (fault == 1) begin
          errorCount +=1;
          $display("processed %0d instructions with %0d warnings", InstrCountW, warningCount);
          $stop;
        end
      end // if (`DEBUG_TRACE >= 1)
    end // if (checkInstrW)
  end // always @ (negedge clk)


  // New IP spoofing
  always @(posedge clk) begin
    #1
    if(checkInstrM) begin
      if((interruptInstrCount+1) == AttemptedInstructionCount) begin
        force dut.core.priv.priv.csr.csri.IP_REGW = 32'b1 << interruptCauseVal;
        $display("Forcing interrupt.");
        `SCAN_NEW_INTERRUPT
        garbageInt = $fgets(garbageString,traceFileE);
        garbageInt = $fgets(garbageString,traceFileM);
      end
    end
  end
  









  ///////////////////////////////////////////////////////////////////////////////
  //////////////////////////////// Extra Features ///////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Function Tracking
  FunctionName FunctionName(.reset(reset),
                            .clk(clk),
                            .ProgramAddrMapFile(ProgramAddrMapFile),
                            .ProgramLabelMapFile(ProgramLabelMapFile));
  
  // Instr Opcode Tracking
  //   For waveview convenience
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  instrTrackerTB it(clk, reset, dut.core.ieu.dp.FlushE,
                dut.core.ifu.FinalInstrRawF[31:0],
                dut.core.ifu.InstrD, dut.core.ifu.InstrE,
                dut.core.ifu.InstrM,  InstrW,
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
  logic [`XLEN-1:0] SATP, PTE;
  logic [55:0]      BaseAdr, PAdr;
  logic [8:0]       VPN [2:0];
  logic [11:0]      Offset;
  function logic [`XLEN-1:0] adrTranslator( 
    input logic [`XLEN-1:0] adrIn);
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
      if (SvMode & (dut.core.priv.priv.PrivilegeModeW != `M_MODE)) begin
        BaseAdr = SATP[43:0] << 12;
        for (i = 2; i >= 0; i--) begin
          PAdr = BaseAdr + (VPN[i] << 3);
          // ram.memory.RAM is 64-bit addressed. PAdr specifies a byte. We right shift
          // by 3 (the PTE size) to get the requested 64-bit PTE.
          PTE = dut.uncore.ram.ram.memory.RAM[PAdr >> 3];
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
