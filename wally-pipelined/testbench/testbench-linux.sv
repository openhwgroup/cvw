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
//
// uncomment the following line to activate checkpoint
`define CHECKPOINT 8500000
`ifdef CHECKPOINT
    `define CHECKPOINT_DIR {`LINUX_TEST_VECTORS, "checkpoint", `"`CHECKPOINT`", "/"}
`endif

module testbench();
  ///////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////// CONFIG ////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  parameter INSTR_LIMIT = 0; // # of instructions at which to stop
  parameter INSTR_WAVEON = 8.7e6;//(INSTR_LIMIT > 10000) ? INSTR_LIMIT-10000 : 1; // # of instructions at which to turn on waves in graphical sim
  //parameter CHECKPOINT = 0;

  ///////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////// HARDWARE ///////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  logic clk, reset; 
  initial begin reset <= 1; # 22; reset <= 0; end
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
  logic             UARTSin;
  logic             UARTSout;
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;
  wallypipelinedsoc dut(.clk, .reset, 
                        .HRDATAEXT, .HREADYEXT, .HRESPEXT, .HCLK, .HRESETn, .HADDR,
                        .HWDATA, .HWRITE, .HSIZE, .HBURST, .HPROT, .HTRANS, .HMASTLOCK,
                        .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn,
                        .UARTSin, .UARTSout);

  // Write Back stage signals not needed by Wally itself
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
  // Signals used to parse the trace file
  integer           data_file_all;
  string            name;
  integer           matchCount;
  string            line;
  logic [`XLEN-1:0] ExpectedPCM;
  logic [31:0]      ExpectedInstrM;
  string            textM;
  string            token;
  string            ExpectedTokens [31:0];
  integer           index;
  integer           StartIndex, EndIndex;
  integer           TokenIndex;
  integer           MarkerIndex;
  integer           NumCSRM;
  // Memory stage expected values from trace
  logic             checkInstrM;
  integer           MIPexpected;
  string            RegWriteM;
  integer           ExpectedRegAdrM;
  logic [`XLEN-1:0] ExpectedRegValueM;
  string            MemOpM;
  logic [`XLEN-1:0] ExpectedMemAdrM, ExpectedMemReadDataM, ExpectedMemWriteDataM;
  string            ExpectedCSRArrayM[10:0];
  logic [`XLEN-1:0] ExpectedCSRArrayValueM[10:0];
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
  `define SCOUNTEREN  `CSR_BASE.csrs.genblk1.genblk3.SCOUNTERENreg.q
  `define MSCRATCH    `CSR_BASE.csrm.MSCRATCHreg.q
  `define SSCRATCH    `CSR_BASE.csrs.genblk1.SSCRATCHreg.q
  `define MTVEC       `CSR_BASE.csrm.MTVECreg.q
  `define STVEC       `CSR_BASE.csrs.genblk1.STVECreg.q
  `define SATP        `CSR_BASE.csrs.genblk1.genblk2.SATPreg.q
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
  `define CURR_PRIV   dut.hart.priv.privmodereg.q
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
  initial begin
    $readmemh({`LINUX_TEST_VECTORS,"bootmem.txt"}, dut.uncore.bootdtim.bootdtim.RAM, 'h1000 >> 3);
    `ifdef CHECKPOINT
      $readmemh({`CHECKPOINT_DIR,"ram.txt"}, dut.uncore.dtim.RAM);
    `else
      $readmemh({`LINUX_TEST_VECTORS,"ram.txt"}, dut.uncore.dtim.RAM);
    `endif
    $readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem);
    $readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.bpred.TargetPredictor.memory.mem);
    ProgramAddrMapFile = {`LINUX_TEST_VECTORS,"vmlinux.objdump.addr"};
    ProgramLabelMapFile = {`LINUX_TEST_VECTORS,"vmlinux.objdump.lab"};
    `ifdef CHECKPOINT
      data_file_all = $fopen({`CHECKPOINT_DIR,"all.txt"}, "r");
    `else
      data_file_all = $fopen({`LINUX_TEST_VECTORS,"all.txt"}, "r");
    `endif
    `ifdef CHECKPOINT
      InstrCountW = `CHECKPOINT;
    `else
      InstrCountW = '0;
    `endif
    force dut.hart.priv.SwIntM = 0;
    force dut.hart.priv.TimerIntM = 0;
    force dut.hart.priv.ExtIntM = 0;    
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
  assign checkInstrM = dut.hart.ieu.InstrValidM & ~dut.hart.priv.trap.InstrPageFaultM & ~dut.hart.priv.trap.InterruptM  & ~dut.hart.StallM;
  always @(negedge clk) begin
    // always check PC, instruction bits
    if (checkInstrM) begin
      // read 1 line of the trace file
      matchCount = $fgets(line, data_file_all);
      if(`DEBUG_TRACE >= 5) $display("Time %t, line %x", $time, line);
      // extract PC, Instr
      matchCount = $sscanf(line, "%x %x %s", ExpectedPCM, ExpectedInstrM, textM);
      //$display("matchCount %d, PCM %x ExpectedInstrM %x textM %x", matchCount, ExpectedPCM, ExpectedInstrM, textM);

      // for the life of me I cannot get any build in C or C++ string parsing functions/methods to work.
      // strtok was the best idea but it cannot be used correctly as system verilog does not have null
      // terminated strings.

      // Just going to do this char by char.
      StartIndex = 0;
      TokenIndex = 0;
      //$display("len = %d", line.len());
      for(index = 0; index < line.len(); index++) begin
        //$display("char = %s", line[index]);
        if (line[index] == " " || line[index] == "\n") begin
          EndIndex = index;
          ExpectedTokens[TokenIndex] = line.substr(StartIndex, EndIndex-1);
          //$display("In Tokenizer %s", line.substr(StartIndex, EndIndex-1));
          StartIndex = EndIndex + 1;
          TokenIndex++;
        end
      end

      MarkerIndex = 3;
      NumCSRM = 0;
      MemOpM = "";
      RegWriteM = "";

      #2;

      while(TokenIndex > MarkerIndex) begin
        // parse the GPR
        if (ExpectedTokens[MarkerIndex] == "GPR") begin
          RegWriteM = ExpectedTokens[MarkerIndex];
          matchCount = $sscanf(ExpectedTokens[MarkerIndex+1], "%d", ExpectedRegAdrM);
          matchCount = $sscanf(ExpectedTokens[MarkerIndex+2], "%x", ExpectedRegValueM);
          MarkerIndex += 3;
        // parse memory address, read data, and/or write data
        end else if(ExpectedTokens[MarkerIndex].substr(0, 2) == "Mem") begin
          MemOpM = ExpectedTokens[MarkerIndex];
          matchCount = $sscanf(ExpectedTokens[MarkerIndex+1], "%x", ExpectedMemAdrM);
          matchCount = $sscanf(ExpectedTokens[MarkerIndex+2], "%x", ExpectedMemWriteDataM);
          matchCount = $sscanf(ExpectedTokens[MarkerIndex+3], "%x", ExpectedMemReadDataM);
          MarkerIndex += 4;
        // parse CSRs, because there are 1 or more CSRs after the CSR token
        // we check if the CSR token or the number of CSRs is greater than 0.
        // if so then we want to parse for a CSR.
        end else if(ExpectedTokens[MarkerIndex] == "CSR" || NumCSRM > 0) begin
          if(ExpectedTokens[MarkerIndex] == "CSR") begin
            // all additional CSR's won't have this token.
            MarkerIndex++;
          end
          matchCount = $sscanf(ExpectedTokens[MarkerIndex], "%s", ExpectedCSRArrayM[NumCSRM]);
          matchCount = $sscanf(ExpectedTokens[MarkerIndex+1], "%x", ExpectedCSRArrayValueM[NumCSRM]);
          MarkerIndex += 2;
          // match MIP to QEMU's because interrupts are imprecise
          if(ExpectedCSRArrayM[NumCSRM].substr(0, 2) == "mip") begin
            $display("%tn: ExpectedCSRArrayM[7] (MEPC) = %x",$time,ExpectedCSRArrayM[7]);
            $display("%tn: ExpectedPCM = %x",$time,ExpectedPCM);
            // if PC does not equal MEPC, request delayed MIP is True
            if(ExpectedPCM != ExpectedCSRArrayM[7]) begin
              RequestDelayedMIP = 1;
            end else begin
              $display("%tns: Updating MIP to %x",$time,ExpectedCSRArrayValueM[NumCSRM]);
              MIPexpected = ExpectedCSRArrayValueM[NumCSRM];
              force dut.hart.priv.csr.genblk1.csri.MIP_REGW = MIPexpected;
            end
          end 
          NumCSRM++;      
        end
      end
      // override on special conditions
      if (ExpectedMemAdrM == 'h10000005) begin
        //$display("%tns, %d instrs: Overwriting read data from CLINT.", $time, InstrCountW);
        force dut.hart.ieu.dp.ReadDataM = ExpectedMemReadDataM;
      end
      if(textM.substr(0,5) == "rdtime") begin
        //$display("%tns, %d instrs: Overwrite MTIME_CLINT on read of MTIME in memory stage.", $time, InstrCountW);
        force dut.uncore.clint.clint.MTIME = ExpectedRegValueM;
      end
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
      end else begin 
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
    if(RequestDelayedMIP) begin
      $display("%tns: Updating MIP to %x",$time,ExpectedCSRArrayValueW[NumCSRM]);
      MIPexpected = ExpectedCSRArrayValueW[NumCSRM];
      force dut.hart.priv.csr.genblk1.csri.MIP_REGW = MIPexpected;
      RequestDelayedMIP = 0;
    end
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
          end else if(ExpectedTokens[MarkerIndex] == "MemW" || ExpectedTokens[MarkerIndex] == "MemRW") begin
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
  

  `ifdef CHECKPOINT
    
    `define INIT_CHECKPOINT_VAL(SIGNAL_BASE,SIGNAL,DIM,LARGE_INDEX,SMALL_INDEX) \
      logic DIM init``SIGNAL [LARGE_INDEX:SMALL_INDEX]; \
      initial $readmemh({`CHECKPOINT_DIR,"checkpoint-",`"SIGNAL`"}, init``SIGNAL); \
      for (i=SMALL_INDEX; i<LARGE_INDEX+1; i=i+1) begin \
        initial begin \
          force `SIGNAL_BASE[i].`SIGNAL = init``SIGNAL[i]; \
          #23; \
          release `SIGNAL_BASE[i].`SIGNAL; \
        end \
      end

    `define INIT_CHECKPOINT_SIMPLE_ARRAY(SIGNAL,DIM,FIRST_INDEX,LAST_INDEX) \
      logic DIM init``SIGNAL [FIRST_INDEX:LAST_INDEX]; \
      initial begin \
        $readmemh({`CHECKPOINT_DIR,"checkpoint-",`"SIGNAL`"}, init``SIGNAL); \
        force `SIGNAL = init``SIGNAL; \
        #23; \
        release `SIGNAL; \
      end

    `define INIT_CHECKPOINT_VAL_SINGLE(SIGNAL,DIM) \
      logic DIM init``SIGNAL[0:0]; \
      initial begin \
        $readmemh({`CHECKPOINT_DIR,"checkpoint-",`"SIGNAL`"}, init``SIGNAL); \
        force `SIGNAL = init``SIGNAL[0]; \
        #23; \
        release `SIGNAL; \
      end

    `define MAKE_INIT_SIGNAL(SIGNAL,DIM) \
      logic DIM init``SIGNAL[0:0]; \
      initial begin \
        $readmemh({`CHECKPOINT_DIR,"checkpoint-",`"SIGNAL`"}, init``SIGNAL); \
      end

    generate
    genvar i;
    `INIT_CHECKPOINT_SIMPLE_ARRAY(RF,         [`XLEN-1:0],31,1);
    `INIT_CHECKPOINT_SIMPLE_ARRAY(HPMCOUNTER, [`XLEN-1:0],`COUNTERS-1,3);
    `INIT_CHECKPOINT_VAL(PMP_BASE, PMPCFG,  [7:0],`PMP_ENTRIES-1,0);
    `INIT_CHECKPOINT_VAL(PMP_BASE, PMPADDR, [`XLEN-1:0],`PMP_ENTRIES-1,0);
    endgenerate
    `INIT_CHECKPOINT_VAL_SINGLE(PC,         [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(MEDELEG,    [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(MIE,        [11:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(MIP,        [11:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(MCAUSE,     [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(SCAUSE,     [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(MEPC,       [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(SEPC,       [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(MCOUNTEREN, [31:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(SCOUNTEREN, [31:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(MSCRATCH,   [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(SSCRATCH,   [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(MTVEC,      [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(STVEC,      [`XLEN-1:0]);
    `INIT_CHECKPOINT_VAL_SINGLE(SATP,       [`XLEN-1:0]);
    `MAKE_INIT_SIGNAL(MSTATUS,      [`XLEN-1:0]);
    initial begin
      force {`STATUS_TSR,`STATUS_TW,`STATUS_TVM,`STATUS_MXR,`STATUS_SUM,`STATUS_MPRV} = initMSTATUS[0][22:17];
      force {`STATUS_FS,`STATUS_MPP} = initMSTATUS[0][14:11];
      force {`STATUS_SPP,`STATUS_MPIE} = initMSTATUS[0][8:7];
      force {`STATUS_SPIE,`STATUS_UPIE,`STATUS_MIE} = initMSTATUS[0][5:3];
      force {`STATUS_SIE,`STATUS_UIE} = initMSTATUS[0][1:0];
      #23;
      release {`STATUS_TSR,`STATUS_TW,`STATUS_TVM,`STATUS_MXR,`STATUS_SUM,`STATUS_MPRV};
      release {`STATUS_FS,`STATUS_MPP};
      release {`STATUS_SPP,`STATUS_MPIE};
      release {`STATUS_SPIE,`STATUS_UPIE,`STATUS_MIE};
      release {`STATUS_SIE,`STATUS_UIE};
    end
    logic [1:0] initPriv;
    assign initPriv = (initPC[0][`XLEN-1]) ? 2'h2 : 2'h3; // *** a hacky way to detect privilege level
    initial begin
      force `CURR_PRIV = initPriv;
      #23;
      release `CURR_PRIV;
    end
    initial begin
      force `INSTRET = `CHECKPOINT;
      #23;
      release `INSTRET;
    end


  `endif
  

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

