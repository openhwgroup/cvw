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
///////////////////////////////////////////

`include "wally-config.vh"

`define DEBUG_TRACE 0
`define DontHaltOnCSRMisMatch 1

module testbench();
  
  parameter waveOnICount = `BUSYBEAR*140000 + `BUILDROOT*6779000; // # of instructions at which to turn on waves in graphical sim

  string ProgramAddrMapFile, ProgramLabelMapFile;

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////// DUT /////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  logic             clk, reset;
  
  logic [`AHBW-1:0] readDataExpected;
  logic [31:0]      HADDR;
  logic [`AHBW-1:0] HWDATA;
  logic             HWRITE;
  logic [2:0]       HSIZE;
  logic [2:0]       HBURST;
  logic [3:0]       HPROT;
  logic [1:0]       HTRANS;
  logic             HMASTLOCK;
  logic             HCLK, HRESETn;
  logic [`AHBW-1:0] HRDATAEXT;
  logic             HREADYEXT, HRESPEXT;

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

  wallypipelinedsoc dut(.*);

  ///////////////////////////////////////////////////////////////////////////////
  ////////////////////////   Signals & Shared Macros  ///////////////////////////
  //////////////////////// AKA stuff that comes first ///////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Sorry if these have gotten decontextualized.
  // Verilog expects them to be defined before they are used.

  // -------------------
  // Signal Declarations
  // -------------------
  // Testbench Core
  integer warningCount = 0;
  integer errorCount = 0;
  // P, Instr Checking
  logic [`XLEN-1:0] PCW;
  integer data_file_all;

  // Write Back stage signals needed for trace compare, but don't actually
  // exist in CPU.
  logic [`XLEN-1:0] MemAdrW, WriteDataW;

  // Write Back trace signals
  logic checkInstrW;

  //integer        RegAdr;

  integer         fault;
  logic           TrapW;

  // Signals used to parse the trace file.
  logic checkInstrM;  
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
  string            RegWriteM;
  integer           ExpectedRegAdrM;
  logic [`XLEN-1:0] ExpectedRegValueM;
  string            MemOpM;
  logic [`XLEN-1:0] ExpectedMemAdrM, ExpectedMemReadDataM, ExpectedMemWriteDataM;
  string            ExpectedCSRArrayM[10:0];
  logic [`XLEN-1:0] ExpectedCSRArrayValueM[10:0];

  // Write back stage expected values from trace
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
//  logic           CurrentInterruptForce;
  logic [`XLEN-1:0] InstrCountW;
  
  // -----------
  // Error Macro
  // -----------
  `define ERROR \
    errorCount +=1; \
    $display("processed %0d instructions with %0d warnings", InstrCountW, warningCount); \
    $stop;

  initial begin
    data_file_all = $fopen({`LINUX_TEST_VECTORS,"all.txt"}, "r");
    InstrCountW = '0;
    force dut.hart.priv.SwIntM = 0;
    force dut.hart.priv.TimerIntM = 0;
    force dut.hart.priv.ExtIntM = 0;    
  end

/* -----\/----- EXCLUDED -----\/-----
  initial begin
    CurrentInterruptForce = 1'b0;
  end
 -----/\----- EXCLUDED -----/\----- */

  assign checkInstrM = dut.hart.ieu.InstrValidM & ~dut.hart.priv.trap.InstrPageFaultM & ~dut.hart.priv.trap.InterruptM  & ~dut.hart.StallM;
  // trapW will already be invalid in there was an InstrPageFault in the previous instruction.
  assign checkInstrW = dut.hart.ieu.InstrValidW & ~dut.hart.StallW;

  flopenrc #(`XLEN) MemAdrWReg(clk, reset, dut.hart.FlushW, ~dut.hart.StallW, dut.hart.ieu.dp.MemAdrM, MemAdrW);
  flopenrc #(`XLEN) WriteDataWReg(clk, reset, dut.hart.FlushW, ~dut.hart.StallW, dut.hart.WriteDataM, WriteDataW);  
  flopenrc #(`XLEN) PCWReg(clk, reset, dut.hart.FlushW, ~dut.hart.ieu.dp.StallW, dut.hart.ifu.PCM, PCW);
  flopenr #(1) TrapWReg(clk, reset, ~dut.hart.StallW, dut.hart.hzu.TrapM, TrapW);

  // Because qemu does not match exactly to wally it is necessary to read the the
  // trace in the memory stage and detect if anything in wally must be overwritten.
  // This includes mtimer, interrupts, and various bits in mstatus and xtval.

  // then on the next posedge the expected state is registered.
  // on the next falling edge the expected state is compared to the wally state.

  // step 0: read the expected state
  always @(negedge clk) begin
    // always check PC, instruction bits
    if (checkInstrM) begin
      // read 1 line of the trace file
      matchCount =  $fgets(line, data_file_all);
      if(`DEBUG_TRACE > 1) $display("Time %t, line %x", $time, line);
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

          // if we get an xcause with the interrupt bit set we must generate an interrupt as interrupts
          // are imprecise.  Forcing the trap at this time will allow wally to track what qemu does.
          // the msb of xcause will be set.
          // bits 1:0 select mode; 0 = user, 1 = superviser, 3 = machine
          // bits 3:2 select the type of interrupt, 0 = software, 1 = timer, 2 = external
          if(ExpectedCSRArrayM[NumCSRM].substr(1, 5) == "cause" && (ExpectedCSRArrayValueM[NumCSRM][`XLEN-1] == 1'b1)) begin
            //what type?
            ExpectedIntType = ExpectedCSRArrayValueM[NumCSRM] & 64'h0000_000C;
            $display("%tns, %d instrs: CSR = %s. Forcing interrupt of cause = %x", $time, InstrCountW, ExpectedCSRArrayM[NumCSRM], ExpectedCSRArrayValueM[NumCSRM]);
            forcedInterrupt = 1;
            if(ExpectedIntType == 0) begin
              force dut.hart.priv.SwIntM = 1'b1;
              $display("Activate spoofed SwIntM");
            end else if(ExpectedIntType == 4) begin
              force dut.hart.priv.TimerIntM = 1'b1;
              $display("Activate spoofed TimeIntM");
            end else if(ExpectedIntType == 8) begin
              force dut.hart.priv.ExtIntM = 1'b1;
              $display("Activate spoofed ExtIntM");
            end else forcedInterrupt = 0;
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
        $display("%tns, %d instrs: Overwrite MTIME_CLINT on read of MTIME in memory stage.", $time, InstrCountW);
        force dut.uncore.clint.clint.MTIME = ExpectedRegValueM;
        //dut.hart.ieu.dp.regf.wd3
      end

    end // if (checkInstrM)
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
      // override on special conditions
      #1;


      if(~dut.hart.StallW) begin
        if(textW.substr(0,5) == "rdtime") begin
          $display("%tns, %d instrs: Releasing force of MTIME_CLINT.", $time, InstrCountW);
          release dut.uncore.clint.clint.MTIME;
          //release dut.hart.ieu.dp.regf.wd3;
        end
        
        if (ExpectedMemAdrM == 'h10000005) begin
          //$display("%tns, %d instrs: releasing force of ReadDataM.", $time, InstrCountW);
              release dut.hart.ieu.dp.ReadDataM;
        end

        // force interrupts to 0
        if (forcedInterrupt) begin
          forcedInterrupt = 0;
          if(ExpectedIntType == 0) begin
            force dut.hart.priv.SwIntM = 1'b0;
            $display("Deactivate spoofed SwIntM");
          end
          else if(ExpectedIntType == 4) begin
            force dut.hart.priv.TimerIntM = 1'b0;
            $display("Deactivate spoofed TimeIntM");
          end
          else if(ExpectedIntType == 8) begin
            force dut.hart.priv.ExtIntM = 1'b0;
            $display("Deactivate spoofed ExtIntM");
          end
        end
      end
    end
  end
  
  // step2: make all checks in the write back stage.
  always @(negedge clk) begin
    // always check PC, instruction bits
    if (checkInstrW) begin
      InstrCountW += 1;
      // turn on waves at certain point
      if (InstrCountW == waveOnICount) $stop;
      // print progress message
      if (InstrCountW % 'd100000 == 0) $display("Reached %d instructions", InstrCountW);
      // check PCW
      fault = 0;
      if(PCW != ExpectedPCW) begin
        $display("PCW: %016x does not equal ExpectedPCW: %016x", PCW, ExpectedPCW);
        fault = 1;
      end

      // check instruction value
      if(dut.hart.ifu.InstrW != ExpectedInstrW) begin
        $display("InstrW: %x does not equal ExpectedInstrW: %x", dut.hart.ifu.InstrW, ExpectedInstrW);
        fault = 1;
      end

      // check the number of instructions
      if(dut.hart.priv.csr.genblk1.counters.genblk1.INSTRET_REGW != InstrCountW) begin
        $display("%t, Number of instruction Retired = %d does not equal number of instructions in trace = %d", $time, dut.hart.priv.csr.genblk1.counters.genblk1.INSTRET_REGW, InstrCountW);
        if(!`DontHaltOnCSRMisMatch) fault = 1;
      end
      
      #2; // delay 2 ns.

      
      if(`DEBUG_TRACE > 2) begin
        $display("Reg Write Address: %02d ? expected value: %02d", dut.hart.ieu.dp.regf.a3, ExpectedRegAdrW);
        $display("RF[%02d]: %016x ? expected value: %016x", ExpectedRegAdrW, dut.hart.ieu.dp.regf.rf[ExpectedRegAdrW], ExpectedRegValueW);
      end

      if (RegWriteW == "GPR") begin
        if (dut.hart.ieu.dp.regf.a3 != ExpectedRegAdrW) begin
          $display("Reg Write Address: %02d does not equal expected value: %02d", dut.hart.ieu.dp.regf.a3, ExpectedRegAdrW);
          fault = 1;
        end
    
    if (dut.hart.ieu.dp.regf.rf[ExpectedRegAdrW] != ExpectedRegValueW) begin
      $display("RF[%02d]: %016x does not equal expected value: %016x", ExpectedRegAdrW, dut.hart.ieu.dp.regf.rf[ExpectedRegAdrW], ExpectedRegValueW);
      fault = 1;
    end
      end

      if (MemOpW.substr(0,2) == "Mem") begin
    if(`DEBUG_TRACE > 3) $display("\tMemAdrW: %016x ? expected: %016x", MemAdrW, ExpectedMemAdrW);

    // always check address
    if (MemAdrW != ExpectedMemAdrW) begin
      $display("MemAdrW: %016x does not equal expected value: %016x", MemAdrW, ExpectedMemAdrW);
      fault = 1;
    end

    // check read data
    if(MemOpW == "MemR" || MemOpW == "MemRW") begin
      if(`DEBUG_TRACE > 3) $display("\tReadDataW: %016x ? expected: %016x", dut.hart.ieu.dp.ReadDataW, ExpectedMemReadDataW);
      if (dut.hart.ieu.dp.ReadDataW != ExpectedMemReadDataW) begin
        $display("ReadDataW: %016x does not equal expected value: %016x", dut.hart.ieu.dp.ReadDataW, ExpectedMemReadDataW);
        fault = 1;
      end
    end

    // check write data
    else if(ExpectedTokens[MarkerIndex] == "MemW" || ExpectedTokens[MarkerIndex] == "MemRW") begin
      if(`DEBUG_TRACE > 3) $display("\tWriteDataW: %016x ? expected: %016x", WriteDataW, ExpectedMemWriteDataW);
      if (WriteDataW != ExpectedMemWriteDataW) begin
        $display("WriteDataW: %016x does not equal expected value: %016x", WriteDataW, ExpectedMemWriteDataW);
        fault = 1;
      end
    end
      end


      // check csr
      //$display("%t, about to check csr, NumCSRW = %d", $time, NumCSRW);
      for(NumCSRPostWIndex = 0; NumCSRPostWIndex < NumCSRW; NumCSRPostWIndex++) begin
        /* -----\/----- EXCLUDED -----\/-----
            if(`DEBUG_TRACE > 0) begin
              $display("%t, NumCSRPostWIndex = %d, Expected CSR: %s = %016x", $time, NumCSRPostWIndex, ExpectedCSRArrayW[NumCSRPostWIndex], ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
         -----/\----- EXCLUDED -----/\----- */
        case(ExpectedCSRArrayW[NumCSRPostWIndex])
          "mhartid": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MHARTID_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);          
            end 
            if (dut.hart.priv.csr.genblk1.csrm.MHARTID_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MHARTID_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);          
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "mstatus": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MSTATUS_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if ((dut.hart.priv.csr.genblk1.csrm.MSTATUS_REGW) != (ExpectedCSRArrayValueW[NumCSRPostWIndex])) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MSTATUS_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "mtvec": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MTVEC_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrm.MTVEC_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MTVEC_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "mip": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MIP_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrm.MIP_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MIP_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "mie": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MIE_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrm.MIE_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MIE_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "mideleg": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MIDELEG_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrm.MIDELEG_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MIDELEG_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "medeleg": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MEDELEG_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrm.MEDELEG_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MEDELEG_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "mepc": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MEPC_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrm.MEPC_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MEPC_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "mtval": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MTVAL_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrm.MTVAL_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrm.MTVAL_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "sepc": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrs.SEPC_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrs.SEPC_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrs.SEPC_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "scause": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrs.genblk1.SCAUSE_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrs.genblk1.SCAUSE_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrs.genblk1.SCAUSE_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "stvec": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrs.STVEC_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrs.STVEC_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrs.STVEC_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
          "stval": begin
            if(`DEBUG_TRACE > 0) begin
              $display("CSR: %s = %016x, expected = %016x", ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrs.genblk1.STVAL_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
            end
            if (dut.hart.priv.csr.genblk1.csrs.genblk1.STVAL_REGW != ExpectedCSRArrayValueW[NumCSRPostWIndex]) begin
              $display("%t, CSR: %s = %016x, does not equal expected value %016x", $time, ExpectedCSRArrayW[NumCSRPostWIndex], dut.hart.priv.csr.genblk1.csrs.genblk1.STVAL_REGW, ExpectedCSRArrayValueW[NumCSRPostWIndex]);
              if(!`DontHaltOnCSRMisMatch) fault = 1;
            end
          end
        endcase // case (ExpectedCSRArrayW[NumCSRPostWIndex])
      end // for (NumCSRPostWIndex = 0; NumCSRPostWIndex < NumCSRW; NumCSRPostWIndex++)
      if (fault == 1) begin `ERROR end
    end // if (checkInstrW)
  end // always @ (negedge clk)


  // track the current function
  FunctionName FunctionName(.reset(reset),
                .clk(clk),
                .ProgramAddrMapFile(ProgramAddrMapFile),
                .ProgramLabelMapFile(ProgramLabelMapFile));
  

  ///////////////////////////////////////////////////////////////////////////////
  //////////////////////////////// Testbench Core ///////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////

  // --------------
  // Initialization
  // --------------
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end
  // initial loading of memories
  initial begin
    $readmemh({`LINUX_TEST_VECTORS,"bootmem.txt"}, dut.uncore.bootdtim.bootdtim.RAM, 'h1000 >> 3);
    $readmemh({`LINUX_TEST_VECTORS,"ram.txt"}, dut.uncore.dtim.RAM);
    $readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.bpred.Predictor.DirPredictor.PHT.memory);
    $readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.bpred.TargetPredictor.memory.memory);
    ProgramAddrMapFile = {`LINUX_TEST_VECTORS,"vmlinux.objdump.addr"};
    ProgramLabelMapFile = {`LINUX_TEST_VECTORS,"vmlinux.objdump.lab"};
  end
  
  // -------
  // Running
  // -------
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end
  

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////// Miscellaneous ///////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Instr Opcode Tracking
  //   For waveview convenience
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  instrTrackerTB it(clk, reset, dut.hart.ieu.dp.FlushE,
                dut.hart.ifu.icache.FinalInstrRawF,
                dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM,  dut.hart.ifu.InstrW,
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

