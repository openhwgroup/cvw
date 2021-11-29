///////////////////////////////////////////
// testbench-linux.sv
//
// Written: nboorstin@g.hmc.edu 2021
// Modified: 
//
// Purpose: Testbench for buildroot or busybear linux
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

// When letting Wally go for it, let wally generate own interrupts
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

module testbench();
  ///////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////// CONFIG ////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Recommend setting all of these in do script using -G option
  parameter INSTR_LIMIT  = 0; // # of instructions at which to stop
  parameter INSTR_WAVEON = 0; // # of instructions at which to turn on waves in graphical sim
  parameter CHECKPOINT   = 0;

  ///////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////// HARDWARE ///////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  logic clk, reset, reset_ext; 
  initial begin reset_ext <= 1; # 22; reset_ext <= 0; end
  always begin clk <= 1; # 5; clk <= 0; # 5; end

  logic [`AHBW-1:0] HRDATAEXT;
  logic             HREADYEXT, HRESPEXT;
  logic             HCLK, HRESETn;
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

  logic SDCCLK;
  tri1 SDCCmd;
  tri1 [3:0] SDCDat;

  assign SDCmd = 1'bz;
  assign SDCDat = 4'bz;
  
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;
  wallypipelinedsoc dut(.clk, .reset_ext, .reset,
                        .HRDATAEXT, .HREADYEXT, .HRESPEXT, .HCLK, .HRESETn, .HADDR,
                        .HWDATA, .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK,
                        .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn,
                        .UARTSin, .UARTSout);

  // Write Back stage signals not needed by Wally itself 
  parameter nop = 'h13;
  logic [`XLEN-1:0] PCW;
  logic [31:0]      InstrW;
  logic             InstrValidW;
  logic [`XLEN-1:0] MemAdrW, WriteDataW;
  logic             TrapW;
  `define FLUSHW dut.hart.FlushW
  `define STALLW dut.hart.StallW
  flopenrc #(`XLEN)         PCWReg(clk, reset, `FLUSHW, ~`STALLW, dut.hart.ifu.PCM, PCW);
  flopenr #(32)          InstrWReg(clk, reset, ~`STALLW, `FLUSHW ? nop : dut.hart.ifu.InstrM, InstrW);
  flopenrc #(1)        controlregW(clk, reset, `FLUSHW, ~`STALLW, dut.hart.ieu.c.InstrValidM, InstrValidW);
  flopenrc #(`XLEN)     MemAdrWReg(clk, reset, `FLUSHW, ~`STALLW, dut.hart.ieu.dp.MemAdrM, MemAdrW);
  flopenrc #(`XLEN)  WriteDataWReg(clk, reset, `FLUSHW, ~`STALLW, dut.hart.WriteDataM, WriteDataW);  
  flopenr #(1)            TrapWReg(clk, reset, ~`STALLW, dut.hart.hzu.TrapM, TrapW);

  ///////////////////////////////////////////////////////////////////////////////
  //////////////////////// Signals & Macro DECLARATIONS /////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Testbench Core
  integer warningCount = 0;
  integer errorCount = 0;
  integer fault;
  string  ProgramAddrMapFile, ProgramLabelMapFile;
  // Checkpointing
  string checkpointDir;
  logic [1:0] initPriv;
  // Signals used to parse the trace file
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
      logic [`XLEN-1:0] ExpectedMemAdr``STAGE, ExpectedMemReadData``STAGE, ExpectedMemWriteData``STAGE; \
      string            ExpectedCSRArray``STAGE[10:0]; \
      logic [`XLEN-1:0] ExpectedCSRArrayValue``STAGE[10:0];
  `DECLARE_TRACE_SCANNER_SIGNALS(E)
  `DECLARE_TRACE_SCANNER_SIGNALS(M)
  integer           NextMIPexpected;
  integer           NextMepcExpected;
  // Memory stage expected values from trace
  logic             checkInstrM;
  integer           MIPexpected;
  string            name;
  logic [`AHBW-1:0] readDataExpected;
  // Write back stage expected values from trace
  logic             checkInstrW;
  logic [`XLEN-1:0] ExpectedPCW;
  logic [31:0]      ExpectedInstrW;
  string            textW;
  string            RegWriteW;
  integer           ExpectedRegAdrW;
  logic [`XLEN-1:0] ExpectedRegValueW;
  string            MemOpW;
  logic [`XLEN-1:0] ExpectedMemAdrW, ExpectedMemReadDataW, ExpectedMemWriteDataW;
  integer           NumCSRW;
  string            ExpectedCSRArrayW[10:0];
  logic [`XLEN-1:0] ExpectedCSRArrayValueW[10:0];
  logic [`XLEN-1:0] ExpectedIntType;
  logic             forcedInterrupt;
  integer           NumCSRMIndex;
  integer           NumCSRWIndex;
  integer           NumCSRPostWIndex;
  logic [`XLEN-1:0] InstrCountW;
  integer           RequestDelayedMIP;
  integer           ForceMIPFuture;
  integer           CSRIndex;
  longint           MepcExpected;
  integer           CheckMIPFutureE;
  integer           CheckMIPFutureM;
  // Useful Aliases
  `define RF          dut.hart.ieu.dp.regf.rf
  `define PC          dut.hart.ifu.pcreg.q
  `define CSR_BASE    dut.hart.priv.csr.genblk1
  `define HPMCOUNTER  `CSR_BASE.counters.genblk1.HPMCOUNTER_REGW
  `define PMP_BASE    `CSR_BASE.csrm.genblk4
  `define PMPCFG      genblk2.PMPCFGreg.q
  `define PMPADDR     PMPADDRreg.q
  `define MEDELEG     `CSR_BASE.csrm.genblk1.MEDELEGreg.q
  `define MIDELEG     `CSR_BASE.csrm.genblk1.MIDELEGreg.q
  `define MIE         `CSR_BASE.csri.MIE_REGW
  `define MIP         `CSR_BASE.csri.MIP_REGW
  `define MCAUSE      `CSR_BASE.csrm.MCAUSEreg.q
  `define SCAUSE      `CSR_BASE.csrs.genblk1.SCAUSEreg.q
  `define MEPC        `CSR_BASE.csrm.MEPCreg.q
  `define SEPC        `CSR_BASE.csrs.genblk1.SEPCreg.q
  `define MCOUNTEREN  `CSR_BASE.csrm.genblk3.MCOUNTERENreg.q
  `define SCOUNTEREN  `CSR_BASE.csrs.genblk1.genblk2.SCOUNTERENreg.q
  `define MSCRATCH    `CSR_BASE.csrm.MSCRATCHreg.q
  `define SSCRATCH    `CSR_BASE.csrs.genblk1.SSCRATCHreg.q
  `define MTVEC       `CSR_BASE.csrm.MTVECreg.q
  `define STVEC       `CSR_BASE.csrs.genblk1.STVECreg.q
  `define SATP        `CSR_BASE.csrs.genblk1.genblk1.SATPreg.q
  `define MSTATUS     `CSR_BASE.csrsr.MSTATUS_REGW
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
  `define PRIV        dut.hart.priv.privmodereg.q
  `define INSTRET     dut.hart.priv.csr.genblk1.counters.genblk1.genblk2.INSTRETreg.q
  // Common Macros
  `define checkCSR(CSR) \
    begin \
      if (CSR != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin \
        $display("%tns, %d instrs: CSR %s = %016x, does not equal expected value %016x", $time, InstrCountW, ExpectedCSRArrayW[NumCSRPostWIndex], CSR, ExpectedCSRArrayValueW[NumCSRPostWIndex]); \
        if(`DEBUG_TRACE >= 3) fault = 1; \
      end \
    end
  `define checkEQ(NAME, VAL, EXPECTED) \
    if(VAL != EXPECTED) begin \
      $display("%tns, %d instrs: %s %x differs from expected %x", $time, InstrCountW, NAME, VAL, EXPECTED); \
      if ((NAME == "PCW") || (`DEBUG_TRACE >= 2)) fault = 1; \
    end

  ///////////////////////////////////////////////////////////////////////////////
  /////////////////////////////// INITIALIZATION ////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Checkpoint initializations
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

  // For the annoying case where the pathname to the array elements includes
  // a "genblk<i>" in the signal name
  `define INIT_CHECKPOINT_GENBLK_ARRAY(SIGNAL_BASE,SIGNAL,DIM,ARRAY_MAX,ARRAY_MIN) \
    `MAKE_CHECKPOINT_INIT_SIGNAL(SIGNAL,DIM,ARRAY_MAX,ARRAY_MIN) \
    for (i=ARRAY_MIN; i<ARRAY_MAX+1; i=i+1) begin \
      initial begin \
        if (CHECKPOINT!=0) begin \
          force `SIGNAL_BASE[i].`SIGNAL = init``SIGNAL[i]; \
          while (reset!==1) #1; \
          while (reset!==0) #1; \
          #1; \
          release `SIGNAL_BASE[i].`SIGNAL; \
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

  `INIT_CHECKPOINT_SIMPLE_ARRAY(RF,         [`XLEN-1:0],31,1);
  `INIT_CHECKPOINT_SIMPLE_ARRAY(HPMCOUNTER, [`XLEN-1:0],`COUNTERS-1,3);
  generate
    genvar i;
    `INIT_CHECKPOINT_GENBLK_ARRAY(PMP_BASE, PMPCFG,  [7:0],`PMP_ENTRIES-1,0);
    `INIT_CHECKPOINT_GENBLK_ARRAY(PMP_BASE, PMPADDR, [`XLEN-1:0],`PMP_ENTRIES-1,0);
  endgenerate
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
  `MAKE_CHECKPOINT_INIT_SIGNAL(MSTATUS, [`XLEN-1:0],0,0);

  integer ramFile;
  integer readResult;
  initial begin
    force dut.hart.priv.SwIntM = 0;
    force dut.hart.priv.TimerIntM = 0;
    force dut.hart.priv.ExtIntM = 0;    
    $readmemh({`LINUX_TEST_VECTORS,"bootmem.txt"}, dut.uncore.bootdtim.bootdtim.RAM, 'h1000 >> 3);
    $readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem);
    $readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.bpred.TargetPredictor.memory.mem);
    ProgramAddrMapFile = {`LINUX_TEST_VECTORS,"vmlinux.objdump.addr"};
    ProgramLabelMapFile = {`LINUX_TEST_VECTORS,"vmlinux.objdump.lab"};
    if (CHECKPOINT==0) begin // normal
      $readmemh({`LINUX_TEST_VECTORS,"ram.txt"}, dut.uncore.dtim.RAM);
      traceFileM = $fopen({`LINUX_TEST_VECTORS,"all.txt"}, "r");
      traceFileE = $fopen({`LINUX_TEST_VECTORS,"all.txt"}, "r");
      InstrCountW = '0;
    end else begin // checkpoint
      $sformat(checkpointDir,"checkpoint%0d/",CHECKPOINT);
      checkpointDir = {`LINUX_TEST_VECTORS,checkpointDir};
      //$readmemh({checkpointDir,"ram.txt"}, dut.uncore.dtim.RAM);
      ramFile = $fopen({checkpointDir,"ram.bin"}, "rb");
      readResult = $fread(dut.uncore.dtim.RAM,ramFile);
      $fclose(ramFile);
      traceFileE = $fopen({checkpointDir,"all.txt"}, "r");
      traceFileM = $fopen({checkpointDir,"all.txt"}, "r");
      InstrCountW = CHECKPOINT;
      // manual checkpoint initializations that don't neatly fit into MACRO
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
  // Because qemu does not match exactly to wally it is necessary to read the the
  // trace in the memory stage and detect if anything in wally must be overwritten.
  // This includes mtimer, interrupts, and various bits in mstatus and xtval.

  // then on the next posedge the expected state is registered.
  // on the next falling edge the expected state is compared to the wally state.

  // step 0: read the expected state
  assign checkInstrM = dut.hart.ieu.InstrValidM & ~dut.hart.priv.trap.InstrPageFaultM & ~dut.hart.priv.trap.InterruptM & ~dut.hart.StallM;
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
        if (line``STAGE[index``STAGE] == " " || line``STAGE[index``STAGE] == "\n") begin \
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
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+1], "%x", ExpectedMemAdr``STAGE); \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+2], "%x", ExpectedMemWriteData``STAGE); \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+3], "%x", ExpectedMemReadData``STAGE); \
          MarkerIndex``STAGE += 4; \
        // parse CSRs, because there are 1 or more CSRs after the CSR token \
        // we check if the CSR token or the number of CSRs is greater than 0. \
        // if so then we want to parse for a CSR. \
        end else if(ExpectedTokens``STAGE[MarkerIndex``STAGE] == "CSR" || NumCSR``STAGE > 0) begin \
          if(ExpectedTokens``STAGE[MarkerIndex``STAGE] == "CSR") begin \
            // all additional CSR's won't have this token. \
            MarkerIndex``STAGE++; \
          end \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE], "%s", ExpectedCSRArray``STAGE[NumCSR``STAGE]); \
          matchCount``STAGE = $sscanf(ExpectedTokens``STAGE[MarkerIndex``STAGE+1], "%x", ExpectedCSRArrayValue``STAGE[NumCSR``STAGE]); \
          MarkerIndex``STAGE += 2; \
          if(`"STAGE`"=="E") begin \
            // match MIP to QEMU's because interrupts are imprecise \
            if(ExpectedCSRArrayE[NumCSRE].substr(0, 2) == "mip") begin \
              CheckMIPFutureE = 1; \
              NextMIPexpected = ExpectedCSRArrayValueE[NumCSRE]; \
            end \
            if(ExpectedCSRArrayE[NumCSRE].substr(0,3) == "mepc") begin \
              $display("hello! we are here."); \
              MepcExpected = ExpectedCSRArrayValueE[NumCSRE]; \
              $display("%tns: MepcExpected: %x",$time,MepcExpected); \
            end \
          end \
           \
          NumCSR``STAGE++; \
        end \
      end \
      if(`"STAGE`"=="M") begin \
        // override on special conditions \
        if (ExpectedMemAdrM == 'h10000005) begin \
          //$display("%tns, %d instrs: Overwriting read data from CLINT.", $time, InstrCountW); \
          force dut.hart.ieu.dp.ReadDataM = ExpectedMemReadDataM; \
        end \
        if(textM.substr(0,5) == "rdtime") begin \
          //$display("%tns, %d instrs: Overwrite MTIME_CLINT on read of MTIME in memory stage.", $time, InstrCountW); \
          force dut.uncore.clint.clint.MTIME = ExpectedRegValueM; \
        end \
      end \
    end \
    
  always @(negedge clk) begin
    `SCAN_NEW_INSTR_FROM_TRACE(E)
  end

  always @(negedge clk) begin
    `SCAN_NEW_INSTR_FROM_TRACE(M)
  end
  
  // MIP spoofing
  always @(posedge clk) begin
    #1;
    if(CheckMIPFutureE) CheckMIPFutureE <= 0;
    CheckMIPFutureM <= CheckMIPFutureE;
    if(CheckMIPFutureM) begin
      // $display("%tns: ExpectedPCM %x",$time,ExpectedPCM);
      // $display("%tns: ExpectedPCE %x",$time,ExpectedPCE);
      // $display("%tns: ExpectedPCW %x",$time,ExpectedPCW);
      if((ExpectedPCE != MepcExpected) & ((MepcExpected - ExpectedPCE) * (MepcExpected - ExpectedPCE) <= 16)) begin
        RequestDelayedMIP <= 1;
        $display("%tns: Requesting Delayed MIP. Current MEPC value is %x",$time,MepcExpected);
      end else begin // update MIP immediately
        $display("%tns: Updating MIP to %x",$time,NextMIPexpected);
        MIPexpected = NextMIPexpected;
        force dut.hart.priv.csr.genblk1.csri.MIP_REGW = MIPexpected;
      end
      // $display("%tn: ExpectedCSRArrayM = %p",$time,ExpectedCSRArrayM);
      // $display("%tn: ExpectedCSRArrayValueM = %p",$time,ExpectedCSRArrayValueM);
      // $display("%tn: ExpectedTokens = %p",$time,ExpectedTokensM);
      // $display("%tn: MepcExpected = %x",$time,MepcExpected);
      // $display("%tn: ExpectedPCE = %x",$time,ExpectedPCE);
      // $display("%tns: Difference/multiplication thing: %x",$time,(MepcExpected - ExpectedPCE) * (MepcExpected - ExpectedPCE));
      // $display("%tn: ExpectedCSRArrayM[NumCSRM] %x",$time,ExpectedCSRArrayM[NumCSRM]);
      // $display("%tn: ExpectedCSRArrayValueM[NumCSRM] %x",$time,ExpectedCSRArrayValueM[NumCSRM]);
    end
    if(RequestDelayedMIP & checkInstrM) begin
      $display("%tns: Executing Delayed MIP. Current MEPC value is %x",$time,dut.hart.priv.csr.genblk1.csrm.MEPC_REGW);
      $display("%tns: Updating MIP to %x",$time,NextMIPexpected);
      MIPexpected = NextMIPexpected;
      force dut.hart.priv.csr.genblk1.csri.MIP_REGW = MIPexpected;
      $display("%tns: Finished Executing Delayed MIP. Current MEPC value is %x",$time,dut.hart.priv.csr.genblk1.csrm.MEPC_REGW);
      RequestDelayedMIP = 0;
    end
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
      ExpectedMemAdrW <= '0;
      MemOpW <= "";
      ExpectedMemWriteDataW <= '0;
      ExpectedMemReadDataW <= '0;
      NumCSRW <= '0;
    end else if(~dut.hart.StallW) begin
      if(dut.hart.FlushW) begin
        ExpectedPCW <= '0;
        ExpectedInstrW <= '0;
        textW <= "";
        RegWriteW <= "";
        ExpectedRegAdrW <= '0;
        ExpectedRegValueW <= '0;
        ExpectedMemAdrW <= '0;
        MemOpW <= "";
        ExpectedMemWriteDataW <= '0;
        ExpectedMemReadDataW <= '0;
        NumCSRW <= '0;
      end else if (dut.hart.ieu.c.InstrValidM) begin 
        ExpectedPCW <= ExpectedPCM;
        ExpectedInstrW <= ExpectedInstrM;
        textW <= textM;
        RegWriteW <= RegWriteM;
        ExpectedRegAdrW <= ExpectedRegAdrM;
        ExpectedRegValueW <= ExpectedRegValueM;
        ExpectedMemAdrW <= ExpectedMemAdrM;
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
      if(~dut.hart.StallW) begin
        if(textW.substr(0,5) == "rdtime") begin
          //$display("%tns, %d instrs: Releasing force of MTIME_CLINT.", $time, InstrCountW);
          release dut.uncore.clint.clint.MTIME;
        end 
        if (ExpectedMemAdrM == 'h10000005) begin
          //$display("%tns, %d instrs: releasing force of ReadDataM.", $time, InstrCountW);
          release dut.hart.ieu.dp.ReadDataM;
        end
      end
    end
  end
  
  // step2: make all checks in the write back stage.
  assign checkInstrW =              InstrValidW & ~dut.hart.StallW; // trapW will already be invalid in there was an InstrPageFault in the previous instruction.
  always @(negedge clk) begin
    // always check PC, instruction bits
    if (checkInstrW) begin
      InstrCountW += 1;
      // print progress message
      if (InstrCountW % 'd100000 == 0) $display("Reached %d instructions", InstrCountW);
      // turn on waves
      if (InstrCountW == INSTR_WAVEON) $stop;
      // end sim
      if ((InstrCountW == INSTR_LIMIT) && (INSTR_LIMIT!=0)) $stop;
      fault = 0;
      if (`DEBUG_TRACE >= 1) begin
        `checkEQ("PCW",PCW,ExpectedPCW)
        //`checkEQ("InstrW",InstrW,ExpectedInstrW) <-- not viable because of
        // compressed to uncompressed conversion
        `checkEQ("Instr Count",dut.hart.priv.csr.genblk1.counters.genblk1.INSTRET_REGW,InstrCountW)
        #2; // delay 2 ns.
        if(`DEBUG_TRACE >= 5) begin
          $display("%tns, %d instrs: Reg Write Address %02d ? expected value: %02d", $time, InstrCountW, dut.hart.ieu.dp.regf.a3, ExpectedRegAdrW);
          $display("%tns, %d instrs: RF[%02d] %016x ? expected value: %016x", $time, InstrCountW, ExpectedRegAdrW, dut.hart.ieu.dp.regf.rf[ExpectedRegAdrW], ExpectedRegValueW);
        end
        if (RegWriteW == "GPR") begin
          `checkEQ("Reg Write Address",dut.hart.ieu.dp.regf.a3,ExpectedRegAdrW)
          $sformat(name,"RF[%02d]",ExpectedRegAdrW);
          `checkEQ(name, dut.hart.ieu.dp.regf.rf[ExpectedRegAdrW], ExpectedRegValueW)
        end
        if (MemOpW.substr(0,2) == "Mem") begin
          if(`DEBUG_TRACE >= 4) $display("\tMemAdrW: %016x ? expected: %016x", MemAdrW, ExpectedMemAdrW);
          `checkEQ("MemAdrW",MemAdrW,ExpectedMemAdrW)
          if(MemOpW == "MemR" || MemOpW == "MemRW") begin
            if(`DEBUG_TRACE >= 4) $display("\tReadDataW: %016x ? expected: %016x", dut.hart.ieu.dp.ReadDataW, ExpectedMemReadDataW);
            `checkEQ("ReadDataW",dut.hart.ieu.dp.ReadDataW,ExpectedMemReadDataW)
          end else if(MemOpW == "MemW" || MemOpW == "MemRW") begin
            if(`DEBUG_TRACE >= 4) $display("\tWriteDataW: %016x ? expected: %016x", WriteDataW, ExpectedMemWriteDataW);
            `checkEQ("WriteDataW",ExpectedMemWriteDataW,ExpectedMemWriteDataW)
          end
        end
        // check csr
        for(NumCSRPostWIndex = 0; NumCSRPostWIndex < NumCSRW; NumCSRPostWIndex++) begin
          case(ExpectedCSRArrayW[NumCSRPostWIndex])
            "mhartid": `checkCSR(dut.hart.priv.csr.genblk1.csrm.MHARTID_REGW)
            "mstatus": `checkCSR(dut.hart.priv.csr.genblk1.csrm.MSTATUS_REGW)
            "mtvec":   `checkCSR(dut.hart.priv.csr.genblk1.csrm.MTVEC_REGW)
            "mip":     `checkCSR(dut.hart.priv.csr.genblk1.csrm.MIP_REGW)
            "mie":     `checkCSR(dut.hart.priv.csr.genblk1.csrm.MIE_REGW)
            "mideleg": `checkCSR(dut.hart.priv.csr.genblk1.csrm.MIDELEG_REGW)
            "medeleg": `checkCSR(dut.hart.priv.csr.genblk1.csrm.MEDELEG_REGW)
            "mepc":    `checkCSR(dut.hart.priv.csr.genblk1.csrm.MEPC_REGW)
            "mtval":   `checkCSR(dut.hart.priv.csr.genblk1.csrm.MTVAL_REGW)
            "sepc":    `checkCSR(dut.hart.priv.csr.genblk1.csrs.SEPC_REGW)
            "scause":  `checkCSR(dut.hart.priv.csr.genblk1.csrs.genblk1.SCAUSE_REGW)
            "stvec":   `checkCSR(dut.hart.priv.csr.genblk1.csrs.STVEC_REGW)
            "stval":   `checkCSR(dut.hart.priv.csr.genblk1.csrs.genblk1.STVAL_REGW)
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


  // track the current function
  FunctionName FunctionName(.reset(reset),
                            .clk(clk),
                            .ProgramAddrMapFile(ProgramAddrMapFile),
                            .ProgramLabelMapFile(ProgramLabelMapFile));
  

  

  ///////////////////////////////////////////////////////////////////////////////
  //////////////////////////////// Extra Features ///////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Instr Opcode Tracking
  //   For waveview convenience
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  instrTrackerTB it(clk, reset, dut.hart.ieu.dp.FlushE,
                dut.hart.ifu.icache.FinalInstrRawF,
                dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM,  InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // ------------------
  // Address Translator
  // ------------------
   /**
   * Walk the page table stored in dtim according to sv39 logic and translate a
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
      SATP = dut.hart.priv.csr.SATP_REGW;
      // Split the virtual address into page number segments and offset
      VPN[2] = adrIn[38:30];
      VPN[1] = adrIn[29:21];
      VPN[0] = adrIn[20:12];
      Offset = adrIn[11:0];
      // We do not support sv48; only sv39
      SvMode = SATP[63];
      // Only perform translation if translation is on and the processor is not
      // in machine mode
      if (SvMode && (dut.hart.priv.PrivilegeModeW != `M_MODE)) begin
        BaseAdr = SATP[43:0] << 12;
        for (i = 2; i >= 0; i--) begin
          PAdr = BaseAdr + (VPN[i] << 3);
          // dtim.RAM is 64-bit addressed. PAdr specifies a byte. We right shift
          // by 3 (the PTE size) to get the requested 64-bit PTE.
          PTE = dut.uncore.dtim.RAM[PAdr >> 3];
          PTE_R = PTE[1];
          PTE_X = PTE[3];
          if (PTE_R || PTE_X) begin
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
