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

module testbench();
  
  parameter waveOnICount = `BUSYBEAR*140000 + `BUILDROOT*3080000; // # of instructions at which to turn on waves in graphical sim
  parameter stopICount   = `BUSYBEAR*143898 + `BUILDROOT*0000000; // # instructions at which to halt sim completely (set to 0 to let it run as far as it can)  

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
  integer instrs;
  integer warningCount = 0;
  string trashString; // should never be read from
  logic [31:0] InstrMask;
  logic forcedInstr;
  logic [63:0] lastPCD;
  logic PCDwrong;
  // PC, Instr Checking
  logic [`XLEN-1:0] PCW;
  logic [63:0] lastInstrDExpected, lastPC, lastPC2;
  integer data_file_PCF, scan_file_PCF;
  integer data_file_PCD, scan_file_PCD;
  integer data_file_PCM, scan_file_PCM;
  integer data_file_PCW, scan_file_PCW;
  string PCtextF, PCtextF2;
  string PCtextD, PCtextD2;
  string PCtextE;
  string PCtextM;
  string PCtextW;
  logic [31:0] InstrFExpected, InstrDExpected, InstrMExpected, InstrWExpected;
  logic [63:0] PCFexpected, PCDexpected, PCMexpected, PCWexpected;
  // RegFile Write Checking
  logic ignoreRFwrite;
  logic [63:0] regExpected;
  integer regNumExpected;
  integer data_file_rf, scan_file_rf;
  // Bus Unit Read/Write Checking
  logic [`XLEN-1:0] readAdrExpected, readAdrTranslated;
  logic [`XLEN-1:0] writeDataExpected, writeAdrExpected, writeAdrTranslated;
  integer data_file_memR, scan_file_memR;
  integer data_file_memW, scan_file_memW;
  // CSR Checking
  integer totalCSR = 0;
  logic [99:0] StartCSRexpected[63:0];
  string StartCSRname[99:0];
  integer data_file_csr, scan_file_csr;
  logic IllegalInstrFaultd;
  
  // -----------
  // Error Macro
  // -----------
  `define ERROR \
    #10; \
    $display("processed %0d instructions with %0d warnings", instrs, warningCount); \
    $stop;

  // ----------------
  // PC Updater Macro
  // ----------------
  `define SCAN_PC(DATAFILE,SCANFILE,PCTEXT,PCTEXT2,CHECKINSTR,PCEXPECTED) \
    SCANFILE = $fscanf(DATAFILE, "%s\n", PCTEXT); \
    PCTEXT2 = ""; \
    while (PCTEXT2 != "***") begin \
      PCTEXT = {PCTEXT, " ", PCTEXT2}; \
      SCANFILE = $fscanf(DATAFILE, "%s\n", PCTEXT2); \
    end \
    SCANFILE = $fscanf(DATAFILE, "%x\n", CHECKINSTR); \
    SCANFILE = $fscanf(DATAFILE, "%x\n", PCEXPECTED);

  ///////////////////////////////////////////////////////////////////////////////
  //////////////////////////////// Testbench Core ///////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // --------------
  // Initialization
  // --------------
  initial
    begin
      instrs = 0;
      PCDwrong = 0;
      reset <= 1; # 22; reset <= 0;
    end
  // initial loading of memories
  initial begin
    $readmemh({`LINUX_TEST_VECTORS,"bootmem.txt"}, dut.uncore.bootdtim.bootdtim.RAM, 'h1000 >> 3);
    $readmemh({`LINUX_TEST_VECTORS,"ram.txt"}, dut.uncore.dtim.RAM);
    $readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.bpred.Predictor.DirPredictor.PHT.memory);
    $readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.bpred.TargetPredictor.memory.memory);
  end
  
  // -------
  // Running
  // -------
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // -------------------
  // Additional Hardware
  // -------------------
  always @(posedge clk)
    IllegalInstrFaultd = dut.hart.priv.IllegalInstrFaultM;

  // -------------------------------------
  // Special warnings for important faults
  // -------------------------------------
  always @(dut.hart.priv.csr.genblk1.csrm.MCAUSE_REGW) begin
    if (dut.hart.priv.csr.genblk1.csrm.MCAUSE_REGW == 2 && instrs > 1) begin
      // This is sometimes okay if the source code intentionally causes it.
      $display("Warning: illegal instruction exception at %0t ps, InstrNum %0d, PCM %x, InstrM %s", $time, instrs, dut.hart.ifu.PCM, PCtextM);
    end
    if (dut.hart.priv.csr.genblk1.csrm.MCAUSE_REGW == 5 && instrs != 0) begin
      $display("Warning: illegal physical memory access exception at %0t ps, InstrNum %0d, PCM %x, InstrM %s", $time, instrs, dut.hart.ifu.PCM, PCtextM);
    end
  end

  // -----------------------
  // RegFile Write Hijacking
  // -----------------------
  always @(PCW or dut.hart.ieu.InstrValidW) begin
    if(dut.hart.ieu.InstrValidW && PCW != 0) begin
      // Hack to compensate for how Wally's MTIME may diverge from QEMU's MTIME (and that is okay)
      if (PCtextW.substr(0,5) == "rdtime") begin
        ignoreRFwrite <= 1;
        scan_file_rf = $fscanf(data_file_rf, "%d\n", regNumExpected);
        scan_file_rf = $fscanf(data_file_rf, "%x\n", regExpected);
        force dut.hart.ieu.dp.regf.wd3 = regExpected;
      // Hack to compensate for QEMU's incorrect MSTATUS (Wally correctly identifies MXL, SXL to be 2 whereas QEMU sets them to an invalid value of 0
      end else if (PCtextW.substr(0,3) == "csrr" && PCtextW.substr(10,16) == "mstatus") begin
        force dut.hart.ieu.dp.regf.wd3 = dut.hart.ieu.dp.WriteDataW & ~64'ha00000000;
            // Hack to compensate for QEMU's incorrect SSTATUS (Wally correctly identifies UXL to be 2 whereas QEMU sets it to an invalid value of 0
      end else if (PCtextW.substr(0,3) == "csrr" && ((PCtextW.substr(10,16) == "sstatus") || (PCtextW.substr(11,17) == "sstatus"))) begin
        force dut.hart.ieu.dp.regf.wd3 = dut.hart.ieu.dp.WriteDataW & ~64'h200000000;
      end else release dut.hart.ieu.dp.regf.wd3;
      // Hack to compensate for QEMU's correct but different MTVAL (according to spec, storing the faulting instr is an optional feature)
      if (PCtextW.substr(0,3) == "csrr" && PCtextW.substr(10,14) == "mtval") begin
        force dut.hart.ieu.dp.WriteDataW = 0;
      // Hack to compensate for QEMU's correct but different mhpmcounter's (these too are optional)
      end else if (PCtextW.substr(0,3) == "csrr" && PCtextW.substr(10,20) == "mhpmcounter") begin
        force dut.hart.ieu.dp.WriteDataW = 0;
      end else release dut.hart.ieu.dp.WriteDataW;
    end
  end

  // ----------------
  // Big Chunky Block
  // ----------------
  always @(reset or dut.hart.ifu.InstrRawD or dut.hart.ifu.PCD) begin// or negedge dut.hart.ifu.StallE) begin // Why do we care about StallE? Everything seems to run fine without it.
    #2;
    // If PCD/InstrD aren't garbage
    if (~reset && dut.hart.ifu.InstrRawD[15:0] !== {16{1'bx}} && dut.hart.ifu.PCD !== 64'h0) begin // && ~dut.hart.ifu.StallE) begin
      // If Wally's PCD has updated
      if (dut.hart.ifu.PCD !== lastPCD) begin
        lastInstrDExpected = InstrDExpected;
        lastPC <= dut.hart.ifu.PCD;
        lastPC2 <= lastPC;
        // If PCD isn't going to be flushed
        if (~PCDwrong || lastPC == PCDexpected) begin
          // Stop if we've reached the end
          if($feof(data_file_PCF)) begin
            $display("no more PC data to read... CONGRATULATIONS!!!");
            `ERROR
          end

          // Increment PC
          `SCAN_PC(data_file_PCF, scan_file_PCF, PCtextF, PCtextF2, InstrFExpected, PCFexpected);
          `SCAN_PC(data_file_PCD, scan_file_PCD, PCtextD, PCtextD2, InstrDExpected, PCDexpected);

          // NOP out certain instructions <-- commented out because no duh hardcoded addressses break easily
          //if(dut.hart.ifu.PCD===PCDexpected) begin
          //  if((dut.hart.ifu.PCD == 32'h80001dc6) || // for now, NOP out any stores to PLIC
          //      (dut.hart.ifu.PCD == 32'h80001de0) ||
          //      (dut.hart.ifu.PCD == 32'h80001de2)) begin
          //    $display("warning: NOPing out %s at PCD=%0x, instr %0d, time %0t", PCtextD, dut.hart.ifu.PCD, instrs, $time);
          //    force InstrDExpected = 32'b0010011;
          //    force dut.hart.ifu.InstrRawD = 32'b0010011;
          //    while (clk != 0) #1;
          //    while (clk != 1) #1;                
          //    release dut.hart.ifu.InstrRawD;
          //    release InstrDExpected;
          //    warningCount += 1;
          //    forcedInstr = 1;
          // end else begin
          //    forcedInstr = 0;
          //  end
          //end

          // Increment instruction count
          if (instrs <= 10 || (instrs <= 100 && instrs % 10 == 0) ||
              (instrs <= 1000 && instrs % 100 == 0) || (instrs <= 10000 && instrs % 1000 == 0) ||
              (instrs <= 100000 && instrs % 10000 == 0) || (instrs % 100000 == 0)) begin
            $display("loaded %0d instructions", instrs);
          end
          instrs += 1;
          
          // Stop before bugs so "do" file can turn on waves
          if (instrs == waveOnICount) begin
            $display("turning on waves at %0d instructions", instrs);
            $stop;
          end else if (instrs == stopICount && stopICount != 0) begin
            $display("Ending sim at %0d instructions (set stopICount to 0 to let the sim go on)", instrs);
            $stop;
          end

          // Check if PCD is going to be flushed due to a branch or jump
          if (`BPRED_ENABLED) begin
            PCDwrong = dut.hart.hzu.FlushD || (PCtextE.substr(0,3) == "mret") || dut.hart.priv.InstrPageFaultF || dut.hart.priv.InstrPageFaultD || dut.hart.priv.InstrPageFaultE || dut.hart.priv.InstrPageFaultM;
          end

          // Check PCD, InstrD
          if (~PCDwrong && ~(dut.hart.ifu.PCD === PCDexpected)) begin
            $display("%0t ps, instr %0d: PCD does not equal PCD expected: %x, %x", $time, instrs, dut.hart.ifu.PCD, PCDexpected);
            `ERROR
          end
          InstrMask = InstrDExpected[1:0] == 2'b11 ? 32'hFFFFFFFF : 32'h0000FFFF;
          if ((~forcedInstr) && (~PCDwrong) && ((InstrMask & dut.hart.ifu.InstrRawD) !== (InstrMask & InstrDExpected))) begin
            $display("%0t ps, PCD %x, instr %0d: InstrD %x %s does not equal InstrDExpected %x %s", $time, dut.hart.ifu.PCD, instrs, dut.hart.ifu.InstrRawD, InstrDName, InstrDExpected, PCtextD);
            `ERROR
          end

          // Repeated instruction means QEMU had an interrupt which we need to spoof
          if (PCFexpected == PCDexpected) begin
            $display("Note at %0t ps, PCM %x %s, instr %0d: spoofing an interrupt", $time, dut.hart.ifu.PCM, PCtextM, instrs);
            // Increment file pointers past the repeated instruction.
            `SCAN_PC(data_file_PCF, scan_file_PCF, PCtextF, PCtextF2, InstrFExpected, PCFexpected);
            `SCAN_PC(data_file_PCD, scan_file_PCD, PCtextD, PCtextD2, InstrDExpected, PCDexpected);
            scan_file_memR = $fscanf(data_file_memR, "%x\n", readAdrExpected);
            scan_file_memR = $fscanf(data_file_memR, "%x\n", readDataExpected);
            // Next force a timer interrupt (*** this may later need generalizing)
            force dut.uncore.clint.clint.MTIME = dut.uncore.clint.clint.MTIMECMP + 1;
            while (clk != 0) #1;
            while (clk != 1) #1;
            release dut.uncore.clint.clint.MTIME;
          end
        end
      end
      lastPCD = dut.hart.ifu.PCD;
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////// PC,Instr Checking ///////////////////////////////
  /////////////////////// (outside of Big Chunky Block) /////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // --------------
  // Initialization
  // --------------
  initial begin
    data_file_PCF = $fopen({`LINUX_TEST_VECTORS,"parsedPC.txt"}, "r");
    data_file_PCD = $fopen({`LINUX_TEST_VECTORS,"parsedPC.txt"}, "r");
    data_file_PCM = $fopen({`LINUX_TEST_VECTORS,"parsedPC.txt"}, "r");
    data_file_PCW = $fopen({`LINUX_TEST_VECTORS,"parsedPC.txt"}, "r");
    if (data_file_PCW == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
    // This makes sure PCF is one instr ahead of PCD
    `SCAN_PC(data_file_PCF, scan_file_PCF, PCtextF, PCtextF2, InstrFExpected, PCFexpected);
    // This makes sure PCM is one instr ahead of PCW
    `SCAN_PC(data_file_PCM, scan_file_PCM, trashString, trashString, InstrMExpected, PCMexpected);
  end

  // Removed because this is MMU's job
  // and it'd take some work to upgrade away from Bus to Cache signals)
  //logging logging(clk, reset, dut.uncore.dut.hart.lsu.dcache.MemPAdrM, dut.uncore.HWRITE);

  // -------------------
  // Additional Hardware
  // -------------------
  flopenr #(`XLEN) PCWReg(clk, reset, ~dut.hart.ieu.dp.StallW, dut.hart.ifu.PCM, PCW);

  // PCF stuff isn't actually checked
  //   it only exists for helping detecting duplicate instructions in PCD
  //   which are the result of interrupts hitting QEMU
  // PCD checking already happens in "Big Chunky Block"
  // PCM stuff isn't actually checked
  //   it only exists for helping detecting duplicate instructions in PCW
  //   which are the result of interrupts hitting QEMU
  // ------------
  // PCW Checking
  // ------------
  always @(PCW or dut.hart.ieu.InstrValidW) begin
   if(dut.hart.ieu.InstrValidW && PCW != 0) begin
      if($feof(data_file_PCW)) begin
        $display("no more PC data to read");
        `ERROR
      end
      `SCAN_PC(data_file_PCM, scan_file_PCM, trashString, trashString, InstrMExpected, PCMexpected);
      `SCAN_PC(data_file_PCW, scan_file_PCW, trashString, trashString, InstrWExpected, PCWexpected);
      // If repeated or instruction, we want to skip over it (indicates an interrupt)
      if (PCMexpected == PCWexpected) begin
        `SCAN_PC(data_file_PCM, scan_file_PCM, trashString, trashString, InstrMExpected, PCMexpected);
        `SCAN_PC(data_file_PCW, scan_file_PCW, trashString, trashString, InstrWExpected, PCWexpected);
      end
      if(~(PCW === PCWexpected)) begin
        $display("%0t ps, instr %0d: PCW does not equal PCW expected: %x, %x", $time, instrs, PCW, PCWexpected);
        `ERROR
      end
    end
    // Skip over faulting instructions because they do not make it to the W stage.
    if (IllegalInstrFaultd) begin
      `SCAN_PC(data_file_PCM, scan_file_PCM, trashString, trashString, InstrMExpected, PCMexpected);
      `SCAN_PC(data_file_PCW, scan_file_PCW, trashString, trashString, InstrWExpected, PCWexpected);
    end
  end
  

  ///////////////////////////////////////////////////////////////////////////////
  /////////////////////////// RegFile Write Checking ////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // --------------
  // Initialization
  // --------------
  initial begin
    data_file_rf = $fopen({`LINUX_TEST_VECTORS,"parsedRegs.txt"}, "r");
    if (data_file_rf == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end
  initial
      ignoreRFwrite <= 0;
  // --------
  // Checking
  // --------
  genvar i;
  generate
    for(i=1; i<32; i++) begin
      always @(dut.hart.ieu.dp.regf.rf[i]) begin
        if ($time == 0) begin
          scan_file_rf = $fscanf(data_file_rf, "%x\n", regExpected);
          if (dut.hart.ieu.dp.regf.rf[i] != regExpected) begin
            $display("%0t ps, InstrNum %0d, PCW %x, InstrW %s: rf[%0d] does not equal rf expected: %x, %x", $time, instrs, PCW, PCtextW, i, dut.hart.ieu.dp.regf.rf[i], regExpected);
            `ERROR
          end
        end else begin
          if (ignoreRFwrite) // this allows other testbench elements to force WriteData to take on the next regExpected
            ignoreRFwrite <= 0;
          else begin
            scan_file_rf = $fscanf(data_file_rf, "%d\n", regNumExpected);
            scan_file_rf = $fscanf(data_file_rf, "%x\n", regExpected);
          end
          if (i != regNumExpected) begin
            $display("%0t ps, InstrNum %0d, PCW %x, InstrW %s: wrong register changed: %0d, %0d expected to switch to %x from %x", $time, instrs, PCW, PCtextW, i, regNumExpected, regExpected, dut.hart.ieu.dp.regf.rf[regNumExpected]);
            `ERROR
          end
          if (~(dut.hart.ieu.dp.regf.rf[i] === regExpected)) begin
            $display("%0t ps, InstrNum %0d, PCW %x, InstrW %s: rf[%0d] does not equal rf expected: %x, %x", $time, instrs, PCW, PCtextW, i, dut.hart.ieu.dp.regf.rf[i], regExpected);
            `ERROR
          end
        end
      end
    end
  endgenerate

  /////////////////////////////////////////////////////////////////////////////
  //////////////////////// Memory Read/Write Checking /////////////////////////
  /////////////////////////////////////////////////////////////////////////////
  // RAM and bootram are addressed in 64-bit blocks - this logic handles R/W
  // including subwords. Brief explanation on signals:
  //
  // In the linux boot, the processor spends the first ~5 instructions in
  // bootram, before jr jumps to main RAM

  // --------------
  // Initialization
  // --------------
  initial begin
    data_file_memR = $fopen({`LINUX_TEST_VECTORS,"parsedMemRead.txt"}, "r");
    if (data_file_memR == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end
  initial begin
    data_file_memW = $fopen({`LINUX_TEST_VECTORS,"parsedMemWrite.txt"}, "r");
    if (data_file_memW == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // ------------
  // Read Checker
  // ------------
  always @(negedge clk) begin
    if (dut.hart.MemRWM[1] && ~dut.hart.StallM && ~dut.hart.FlushM && dut.hart.ieu.InstrValidM) begin
      if($feof(data_file_memR)) begin
        $display("no more memR data to read");
        `ERROR
      end
      scan_file_memR = $fscanf(data_file_memR, "%x\n", readAdrExpected);
      scan_file_memR = $fscanf(data_file_memR, "%x\n", readDataExpected);
      assign readAdrTranslated = adrTranslator(readAdrExpected);
      if (~(dut.hart.ieu.MemAdrM === readAdrExpected)) begin
        $display("%0t ps, InstrNum %0d, PCM %x, InstrM %s: MemAdrM does not equal virtual readAdrExpected: %x, %x", $time, instrs, dut.hart.ifu.PCM, PCtextM, dut.hart.ieu.MemAdrM, readAdrExpected);
        `ERROR
      end
      //if (~(dut.hart.lsu.dcache.MemPAdrM === readAdrTranslated)) begin
      //  $display("%0t ps, InstrNum %0d, PCM %x, InstrM %s: MemPAdrM does not equal physical readAdrExpected: %x, %x", $time, instrs, dut.hart.ifu.PCM, PCtextM, dut.hart.lsu.dcache.MemPAdrM, readAdrTranslated);
      //  `ERROR
      //end
      if (readDataExpected !== dut.hart.lsu.dcache.ReadDataM) begin
        if (dut.hart.lsu.dcache.MemPAdrM inside `LINUX_FIX_READ) begin
          if (dut.hart.lsu.dcache.MemPAdrM != 'h10000005) // Suppress the warning for UART LSR so we can read UART output
            $display("%0t ps, InstrNum %0d, PCM %x, InstrM %s:: forcing readDataExpected to expected: %x, %x", $time, instrs, dut.hart.ifu.PCM, PCtextM, dut.hart.lsu.dcache.MemPAdrM, readDataExpected, dut.hart.lsu.dcache.ReadDataM);
          force dut.hart.lsu.dcache.ReadDataM = readDataExpected;
          #9;
          release dut.hart.lsu.dcache.ReadDataM;
        end else begin
          $display("%0t ps, InstrNum %0d, PCM %x, InstrM %s: ReadDataM does not equal readDataExpected: %x, %x from address %x", $time, instrs, dut.hart.ifu.PCM, PCtextM, dut.hart.lsu.dcache.ReadDataM, readDataExpected, dut.hart.lsu.dcache.MemPAdrM);
          `ERROR
        end
      end
    end
  end

  // -------------
  // Write Checker
  // -------------
  always @(negedge clk) begin
    if (dut.hart.MemRWM[0] && ~dut.hart.StallM && ~dut.hart.FlushM && dut.hart.ieu.InstrValidM && ($time != 0)) begin
      if($feof(data_file_memW)) begin
        $display("no more memW data to read");
        `ERROR
      end
      scan_file_memW = $fscanf(data_file_memW, "%x\n", writeDataExpected);
      scan_file_memW = $fscanf(data_file_memW, "%x\n", writeAdrExpected);
      assign writeAdrTranslated = adrTranslator(writeAdrExpected);
      if (~(dut.hart.ieu.MemAdrM === writeAdrExpected)) begin
        $display("%0t ps, InstrNum %0d, PCM %x, InstrM %s: MemAdrM does not equal virtual writeAdrExpected: %x, %x", $time, instrs, dut.hart.ifu.PCM, PCtextM, dut.hart.ieu.MemAdrM, writeAdrExpected);
        `ERROR
      end
      if (writeDataExpected != dut.hart.lsu.dcache.WriteDataM && ~dut.uncore.HSELPLICD) begin
        $display("%0t ps, InstrNum %0d, PCM %x, InstrM %s: WriteDataM does not equal writeDataExpected: %x, %x", $time, instrs, dut.hart.ifu.PCM, PCtextM, dut.hart.lsu.dcache.WriteDataM, writeDataExpected);
        `ERROR
      end
      //if (~(writeAdrTranslated === dut.hart.lsu.dcache.MemPAdrM) && ~dut.uncore.HSELPLICD) begin
      //  $display("%0t ps, InstrNum %0d, PCM %x, InstrM %s: MemPAdrM does not equal physical writeAdrExpected: %x, %x", $time, instrs, dut.hart.ifu.PCM, PCtextM, dut.hart.lsu.dcache.MemPAdrM, writeAdrTranslated);
      //  `ERROR
      //end
    end
  end

  ///////////////////////////////////////////////////////////////////////////////
  //////////////////////////////// CSR Checking /////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // --------------
  // Initialization
  // --------------
  initial begin
    data_file_csr = $fopen({`LINUX_TEST_VECTORS,"parsedCSRs.txt"}, "r");
    if (data_file_csr == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
    while(1) begin
      scan_file_csr = $fscanf(data_file_csr, "%s\n", StartCSRname[totalCSR]);
      if(StartCSRname[totalCSR] == "---") begin
        break;
      end
      scan_file_csr = $fscanf(data_file_csr, "%x\n", StartCSRexpected[totalCSR]);
      totalCSR = totalCSR + 1;
    end
  end

  // --------------
  // Checker Macros
  // --------------
  // String variables seem to compare more reliably than string literals (they gave me a lot of hassle),
  // but *** there's probably a better way to do this.
  // You can't just use the "__name" variables though because you need to declare variables before using them.
  string MSTATUSstring = "MSTATUS";
  string MIPstring = "MIP";
  string MEPCstring = "MEPC";
  string MCAUSEstring = "MCAUSE";
  string MTVALstring = "MTVAL";
  string SEPCstring = "SEPC";
  string SCAUSEstring = "SCAUSE";
  string STVALstring = "STVAL";
  string SSTATUSstring = "SSTATUS";

  logic [63:0] expectedCSR;
  string expectedCSRname;
  `define CHECK_CSR2(CSR, PATH) \
    string ``CSR``name = `"CSR`"; \
    always @(``PATH``.``CSR``_REGW) begin \
      if (instrs == 0 && ~reset) begin \
        for(integer j=0; j<totalCSR; j++) begin \
          if(!StartCSRname[j].icompare(``CSR``name)) begin \
            if(``PATH``.``CSR``_REGW != StartCSRexpected[j]) begin \
              $display("%0t ps, PCM %x %s, instr %0d: %s does not equal %s expected: %x, %x", $time, dut.hart.ifu.PCM, PCtextM, instrs, ``CSR``name, StartCSRname[j], ``PATH``.``CSR``_REGW, StartCSRexpected[j]); \
              `ERROR \
            end \
          end \
        end \
        $display("CSRs' intital states look good"); \
      end else begin \
        // MIP is not checked because QEMU bodges it (MTIP in particular), and even if QEMU reported it correctly, the timing would still be off \
        // MTVAL is not checked on illegal instr faults because QEMU chooses not to implement the behavior where MTVAL is written with the faulting instruction \
        if  (~reset && ``CSR``name != MIPstring && ~(IllegalInstrFaultd && ``CSR``name == MTVALstring)) begin \
          // This is some feeble hackery designed to control the order in which CSRs are checked \
          // when multiple change at the same time. \
          // *** it would be better for each CSR to have its own testvector file \
          // so as to avoid this awkward ordering problem. \
          if (``CSR``name == MEPCstring) #1; \
          if (``CSR``name == MCAUSEstring) #2; \
          if (``CSR``name == MTVALstring) #3; \
          if (``CSR``name == SEPCstring) #1; \
          if (``CSR``name == SCAUSEstring) #2; \
          if (``CSR``name == STVALstring) #3; \
          if (``CSR``name == SSTATUSstring) #3; \
          scan_file_csr = $fscanf(data_file_csr, "%s\n", expectedCSRname); \
          scan_file_csr = $fscanf(data_file_csr, "%x\n", expectedCSR); \
          if(expectedCSRname.icompare(``CSR``name)) begin \
            $display("%0t ps, PCM %x %s, instr %0d: %s changed, expected %s", $time, dut.hart.ifu.PCM, PCtextM, instrs, `"CSR`", expectedCSRname); \
          end \
          if (``CSR``name == MSTATUSstring) begin \
            if (``PATH``.``CSR``_REGW != ((expectedCSR) | 64'ha00000000)) begin \
              $display("%0t ps, PCM %x %s, instr %0d: %s (should be MSTATUS) does not equal %s expected: %x, %x", $time, dut.hart.ifu.PCM, PCtextM, instrs, ``CSR``name, expectedCSRname, ``PATH``.``CSR``_REGW, expectedCSR | 64'ha00000000); \
              `ERROR \
            end \
          end else begin \
            if (``PATH``.``CSR``_REGW != expectedCSR[$bits(``PATH``.``CSR``_REGW)-1:0]) begin \
              $display("%0t ps, PCM %x %s, instr %0d: %s does not equal %s expected: %x, %x", $time, dut.hart.ifu.PCM, PCtextM, instrs, ``CSR``name, expectedCSRname, ``PATH``.``CSR``_REGW, expectedCSR); \
              `ERROR \
            end \
          end \
        end \
      end \
    end
  
  `define CHECK_CSR(CSR) \
     `CHECK_CSR2(CSR, dut.hart.priv.csr)
  `define CSRM dut.hart.priv.csr.genblk1.csrm
  `define CSRS dut.hart.priv.csr.genblk1.csrs.genblk1

  // --------
  // Checking
  // --------
  // Which CSRs we check depends upon which ones QEMU outputs
  // *** can we fix QEMU to output a defined set of CSRs?
  `CHECK_CSR2(MHARTID, `CSRM)
  `CHECK_CSR(MSTATUS)
  `CHECK_CSR(MIP)
  `CHECK_CSR(MIE)
  `CHECK_CSR(MIDELEG)
  `CHECK_CSR(MEDELEG)
  `CHECK_CSR(MTVEC)
  `CHECK_CSR(STVEC)
  `CHECK_CSR(MEPC)
  `CHECK_CSR(SEPC)
  `CHECK_CSR2(MCAUSE, `CSRM)
  `CHECK_CSR2(SCAUSE, `CSRS)
  `CHECK_CSR2(MTVAL, `CSRM)
  `CHECK_CSR2(STVAL, `CSRS)

  //`CHECK_CSR(FCSR)
  //`CHECK_CSR(MCOUNTEREN)
  //`CHECK_CSR2(MISA, `CSRM)
  //`CHECK_CSR2(MSCRATCH, `CSRM)
  //`CHECK_CSR2(PMPADDR0, `CSRM)
  //`CHECK_CSR2(PMdut.PCFG0, `CSRM)
  //`CHECK_CSR(SATP)
  //`CHECK_CSR(SCOUNTEREN)
  //`CHECK_CSR(SIE)
  //`CHECK_CSR2(SSCRATCH, `CSRS)
  //`CHECK_CSR(SSTATUS)
  
  

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////// Miscellaneous ///////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  // Instr Opcode Tracking
  //   For waveview convenience
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  instrTrackerTB it(clk, reset,
                dut.hart.ifu.icache.controller.FinalInstrRawF,
                dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM,  dut.hart.ifu.InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // Instr Assembly Tracking
  //   For waveview convenience
  //   PCtextF, PCtextD are read from testvectors
  //   You could just as well read the others from testvectors,
  //   but I really like how the pipeline synchronizes with Wally so cleanly
  always_ff @(posedge clk, posedge reset)
    if (reset) begin
      PCtextE = "(reset)";
      PCtextM = "(reset)";
      PCtextW = "(reset)";
    end else begin
      if (~dut.hart.StallW) 
        if (dut.hart.FlushW) PCtextW = "(flushed)";
        else                 PCtextW = PCtextM;
      if (~dut.hart.StallM) 
        if (dut.hart.FlushM) PCtextM = "(flushed)";
        else                 PCtextM = PCtextE;
      if (~dut.hart.StallE) 
        if (dut.hart.FlushE) PCtextE = "(flushed)";
        else                 PCtextE = PCtextD;
    end
  
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

//module logging(
//  input logic clk, reset,
//  input logic [31:0] dut.hart.lsu.dcache.MemPAdrM,
//  input logic [1:0]  (|dut.hart.lsu.dcache.MemRWM || dut.hart.lsu.dcache.AtomicM));
//
//  always @(posedge clk)
//    if ((|dut.hart.lsu.dcache.MemRWM || dut.hart.lsu.dcache.AtomicM) != 2'b00 && dut.hart.lsu.dcache.MemPAdrM == 0)
//      $display("Warning: access to memory address 0\n");
//endmodule


module instrTrackerTB(
  input  logic            clk, reset,
  input  logic [31:0]     InstrF,InstrD,InstrE,InstrM,InstrW,
  output string           InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);     
  instrNameDecTB fdec(InstrF, InstrFName);
  instrNameDecTB ddec(InstrD, InstrDName);
  instrNameDecTB edec(InstrE, InstrEName);
  instrNameDecTB mdec(InstrM, InstrMName);
  instrNameDecTB wdec(InstrW, InstrWName);
endmodule

// decode the instruction name, to help the test bench
module instrNameDecTB(
  input  logic [31:0] instr,
  output string       name);

  logic [6:0] op;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [11:0] imm;

  assign op = instr[6:0];
  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];
  assign imm = instr[31:20];

  // it would be nice to add the operands to the name 
  // create another variable called decoded

  always_comb 
    casez({op, funct3})
      10'b0000000_000: name = "BAD";
      10'b0000011_000: name = "LB";
      10'b0000011_001: name = "LH";
      10'b0000011_010: name = "LW";
      10'b0000011_011: name = "LD";
      10'b0000011_100: name = "LBU";
      10'b0000011_101: name = "LHU";
      10'b0000011_110: name = "LWU";
      10'b0010011_000: if (instr[31:15] == 0 && instr[11:7] ==0) name = "NOP/FLUSH";
                       else                                      name = "ADDI";
      10'b0010011_001: if (funct7[6:1] == 6'b000000) name = "SLLI";
                       else                      name = "ILLEGAL";
      10'b0010011_010: name = "SLTI";
      10'b0010011_011: name = "SLTIU";
      10'b0010011_100: name = "XORI";
      10'b0010011_101: if (funct7[6:1] == 6'b000000)      name = "SRLI";
                       else if (funct7[6:1] == 6'b010000) name = "SRAI"; 
                       else                           name = "ILLEGAL"; 
      10'b0010011_110: name = "ORI";
      10'b0010011_111: name = "ANDI";
      10'b0010111_???: name = "AUIPC";
      10'b0100011_000: name = "SB";
      10'b0100011_001: name = "SH";
      10'b0100011_010: name = "SW";
      10'b0100011_011: name = "SD";
      10'b0011011_000: name = "ADDIW";
      10'b0011011_001: name = "SLLIW";
      10'b0011011_101: if      (funct7 == 7'b0000000) name = "SRLIW";
                       else if (funct7 == 7'b0100000) name = "SRAIW";
                       else                           name = "ILLEGAL";
      10'b0111011_000: if      (funct7 == 7'b0000000) name = "ADDW";
                       else if (funct7 == 7'b0100000) name = "SUBW";
                       else                           name = "ILLEGAL";
      10'b0111011_001: name = "SLLW";
      10'b0111011_101: if      (funct7 == 7'b0000000) name = "SRLW";
                       else if (funct7 == 7'b0100000) name = "SRAW";
                       else                           name = "ILLEGAL";
      10'b0110011_000: if      (funct7 == 7'b0000000) name = "ADD";
                       else if (funct7 == 7'b0000001) name = "MUL";
                       else if (funct7 == 7'b0100000) name = "SUB"; 
                       else                           name = "ILLEGAL"; 
      10'b0110011_001: if      (funct7 == 7'b0000000) name = "SLL";
                       else if (funct7 == 7'b0000001) name = "MULH";
                       else                           name = "ILLEGAL";
      10'b0110011_010: if      (funct7 == 7'b0000000) name = "SLT";
                       else if (funct7 == 7'b0000001) name = "MULHSU";
                       else                           name = "ILLEGAL";
      10'b0110011_011: if      (funct7 == 7'b0000000) name = "SLTU";
                       else if (funct7 == 7'b0000001) name = "DIV";
                       else                           name = "ILLEGAL";
      10'b0110011_100: if      (funct7 == 7'b0000000) name = "XOR";
                       else if (funct7 == 7'b0000001) name = "MUL";
                       else                           name = "ILLEGAL";
      10'b0110011_101: if      (funct7 == 7'b0000000) name = "SRL";
                       else if (funct7 == 7'b0000001) name = "DIVU";
                       else if (funct7 == 7'b0100000) name = "SRA";
                       else                           name = "ILLEGAL";
      10'b0110011_110: if      (funct7 == 7'b0000000) name = "OR";
                       else if (funct7 == 7'b0000001) name = "REM";
                       else                           name = "ILLEGAL";
      10'b0110011_111: if      (funct7 == 7'b0000000) name = "AND";
                       else if (funct7 == 7'b0000001) name = "REMU";
                       else                           name = "ILLEGAL";
      10'b0110111_???: name = "LUI";
      10'b1100011_000: name = "BEQ";
      10'b1100011_001: name = "BNE";
      10'b1100011_100: name = "BLT";
      10'b1100011_101: name = "BGE";
      10'b1100011_110: name = "BLTU";
      10'b1100011_111: name = "BGEU";
      10'b1100111_000: name = "JALR";
      10'b1101111_???: name = "JAL";
      10'b1110011_000: if      (imm == 0) name = "ECALL";
                       else if (imm == 1) name = "EBREAK";
                       else if (imm == 2) name = "URET";
                       else if (imm == 258) name = "SRET";
                       else if (imm == 770) name = "MRET";
                       else              name = "ILLEGAL";
      10'b1110011_001: name = "CSRRW";
      10'b1110011_010: name = "CSRRS";
      10'b1110011_011: name = "CSRRC";
      10'b1110011_101: name = "CSRRWI";
      10'b1110011_110: name = "CSRRSI";
      10'b1110011_111: name = "CSRRCI";
      10'b0001111_???: name = "FENCE";
      default:         name = "ILLEGAL";
    endcase
endmodule

