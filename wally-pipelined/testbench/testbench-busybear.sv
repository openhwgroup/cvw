`include "wally-config.vh"

module testbench_busybear();

  logic            clk, reset;
  logic [31:0]     GPIOPinsIn;
  logic [31:0]     GPIOPinsOut, GPIOPinsEn;

  // instantiate device to be tested
  logic [31:0] CheckInstrF;

  logic [`AHBW-1:0] HRDATA;
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
  logic             UARTSout;

  assign GPIOPinsIn = 0;
  assign UARTSin = 1;

  // instantiate processor and memories
  wallypipelinedsoc dut(.*);


  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // read pc trace file
  integer data_file_PC, scan_file_PC;
  initial begin
    data_file_PC = $fopen("/courses/e190ax/busybear_boot/parsedPC.txt", "r");
    if (data_file_PC == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  integer data_file_PCW, scan_file_PCW;
  initial begin
    data_file_PCW = $fopen("/courses/e190ax/busybear_boot/parsedPC.txt", "r");
    if (data_file_PCW == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // read register trace file
  integer data_file_rf, scan_file_rf;
  initial begin
    data_file_rf = $fopen("/courses/e190ax/busybear_boot/parsedRegs.txt", "r");
    if (data_file_rf == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // read CSR trace file
  integer data_file_csr, scan_file_csr;
  initial begin
    data_file_csr = $fopen("/courses/e190ax/busybear_boot/parsedCSRs.txt", "r");
    if (data_file_csr == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // read memreads trace file
  integer data_file_memR, scan_file_memR;
  initial begin
    data_file_memR = $fopen("/courses/e190ax/busybear_boot/parsedMemRead.txt", "r");
    if (data_file_memR == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // read memwrite trace file
  integer data_file_memW, scan_file_memW;
  initial begin
    data_file_memW = $fopen("/courses/e190ax/busybear_boot/parsedMemWrite.txt", "r");
    if (data_file_memW == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // initial loading of memories
  initial begin
    $readmemh("/courses/e190ax/busybear_boot/bootmem.txt", dut.uncore.bootdtim.RAM, 'h1000 >> 3);
    $readmemh("/courses/e190ax/busybear_boot/ram.txt", dut.uncore.dtim.RAM);
    $readmemh("/courses/e190ax/busybear_boot/bootmem.txt", dut.imem.bootram, 'h1000 >> 3);
    $readmemh("/courses/e190ax/busybear_boot/ram.txt", dut.imem.RAM);
    $readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.Predictor.DirPredictor.PHT.memory);
    $readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.TargetPredictor.memory.memory);
  end

  integer warningCount = 0;
  integer instrs;

  //logic[63:0] adrTranslation[4:0];
  //string translationType[4:0] = {"rf", "writeAdr", "PCW", "PC", "readAdr"};
  //initial begin
  //  for(int i=0; i<5; i++) begin
  //    adrTranslation[i] = 64'b0;
  //  end
  //end

  //function logic equal(logic[63:0] adr, logic[63:0] adrExpected, integer func);
  //  if (adr[11:0] !== adrExpected[11:0]) begin
  //    equal = 1'b0;
  //  end else begin
  //    equal = 1'b1;
  //    if ((adr+adrTranslation[func]) !== adrExpected) begin
  //      adrTranslation[func] = adrExpected - adr;
  //      $display("warning: probably new address translation %x for %s at instr %0d", adrTranslation[func], translationType[func], instrs);
  //      warningCount += 1;
  //    end
  //  end
  //endfunction

  // pretty sure this isn't necessary anymore, but keeping this for now since its easier
  function logic equal(logic[63:0] adr, logic[63:0] adrExpected, integer func);
    equal = adr === adrExpected;
  endfunction


  `define ERROR \
    #10; \
    $display("processed %0d instructions with %0d warnings", instrs, warningCount); \
    $stop;

  logic [63:0] pcExpected;
  logic [63:0] regExpected;
  integer regNumExpected;

  genvar i;
  generate
    for(i=1; i<32; i++) begin
      always @(dut.hart.ieu.dp.regf.rf[i]) begin
        if ($time == 0) begin
          scan_file_rf = $fscanf(data_file_rf, "%x\n", regExpected);
          if (dut.hart.ieu.dp.regf.rf[i] != regExpected) begin
            $display("%0t ps, instr %0d: rf[%0d] does not equal rf expected: %x, %x", $time, instrs, i, dut.hart.ieu.dp.regf.rf[i], regExpected);
            `ERROR
          end
        end else begin
          scan_file_rf = $fscanf(data_file_rf, "%d\n", regNumExpected);
          scan_file_rf = $fscanf(data_file_rf, "%x\n", regExpected);
          if (i != regNumExpected) begin
            $display("%0t ps, instr %0d: wrong register changed: %0d, %0d expected to switch to %x from %x", $time, instrs, i, regNumExpected, regExpected, dut.hart.ieu.dp.regf.rf[regNumExpected]);
            `ERROR
          end
          if (~equal(dut.hart.ieu.dp.regf.rf[i],regExpected, 0)) begin
            $display("%0t ps, instr %0d: rf[%0d] does not equal rf expected: %x, %x", $time, instrs, i, dut.hart.ieu.dp.regf.rf[i], regExpected);
            `ERROR
          end
          //if (dut.hart.ieu.dp.regf.rf[i] !== regExpected) begin
          //  force dut.hart.ieu.dp.regf.rf[i] = regExpected;
          //  release dut.hart.ieu.dp.regf.rf[i];
          //end
        end
      end
    end
  endgenerate

  // RAM and bootram are addressed in 64-bit blocks - this logic handles R/W
  // including subwords. Brief explanation on signals:
  //
  // readMask: bitmask of bits to read / write, left-shifted to align with
  // nearest 64-bit boundary - examples
  //    HSIZE = 0 -> readMask = 11111111
  //    HSIZE = 1 -> readMask = 1111111111111111
  //
  // In the linux boot, the processor spends the first ~5 instructions in
  // bootram, before jr jumps to main RAM

  logic [63:0] readMask;
  assign readMask = ((1 << (8*(1 << HSIZE))) - 1) << 8 * HADDR[2:0];

  logic [`XLEN-1:0] readAdrExpected;

  always @(dut.HRDATA) begin
    #1;
    if (dut.hart.MemRWM[1] && HADDR != dut.PCF && dut.HRDATA !== {64{1'bx}}) begin
      //$display("%0t", $time);
      if($feof(data_file_memR)) begin
        $display("no more memR data to read");
        `ERROR
      end
      scan_file_memR = $fscanf(data_file_memR, "%x\n", readAdrExpected);
      scan_file_memR = $fscanf(data_file_memR, "%x\n", HRDATA);
      if (~equal(HADDR,readAdrExpected,4)) begin
        $display("%0t ps, instr %0d: HADDR does not equal readAdrExpected: %x, %x", $time, instrs, HADDR, readAdrExpected);
        `ERROR
      end
      if ((readMask & HRDATA) !== (readMask & dut.HRDATA)) begin
        if (HADDR inside `BUSYBEAR_FIX_READ) begin
          //$display("warning %0t ps, instr %0d, adr %0d: forcing HRDATA to expected: %x, %x", $time, instrs, HADDR, HRDATA, dut.HRDATA);
          force dut.uncore.HRDATA = HRDATA;
          #9;
          release dut.uncore.HRDATA;
          warningCount += 1;
        end else begin
          $display("%0t ps, instr %0d: ExpectedHRDATA does not equal dut.HRDATA: %x, %x from address %x, %x", $time, instrs, HRDATA, dut.HRDATA, HADDR, HSIZE);
          `ERROR
        end
      end
    //end else if(dut.hart.MemRWM[1]) begin
    //  $display("%x, %x, %x, %t", HADDR, dut.PCF, dut.HRDATA, $time);

    end

  end

  logic [`XLEN-1:0] writeDataExpected, writeAdrExpected;

  // this might need to change
  //always @(HWDATA or HADDR or HSIZE or HWRITE) begin
  always @(negedge HWRITE) begin
    //#1;
    if ($time != 0) begin
      if($feof(data_file_memW)) begin
        $display("no more memW data to read");
        `ERROR
      end
      scan_file_memW = $fscanf(data_file_memW, "%x\n", writeDataExpected);
      scan_file_memW = $fscanf(data_file_memW, "%x\n", writeAdrExpected);
      if (writeDataExpected != HWDATA) begin
        $display("%0t ps, instr %0d: HWDATA does not equal writeDataExpected: %x, %x", $time, instrs, HWDATA, writeDataExpected);
        `ERROR
      end
      if (~equal(writeAdrExpected,HADDR,1)) begin
        $display("%0t ps, instr %0d: HADDR does not equal writeAdrExpected: %x, %x", $time, instrs, HADDR, writeAdrExpected);
        `ERROR
      end
    end
  end

  integer totalCSR = 0;
  logic [99:0] StartCSRexpected[63:0];
  string StartCSRname[99:0];
  initial begin
    while(1) begin
      scan_file_csr = $fscanf(data_file_csr, "%s\n", StartCSRname[totalCSR]);
      if(StartCSRname[totalCSR] == "---") begin
        break;
      end
      scan_file_csr = $fscanf(data_file_csr, "%x\n", StartCSRexpected[totalCSR]);
      totalCSR = totalCSR + 1;
    end
  end

  always @(dut.hart.priv.csr.genblk1.csrm.MCAUSE_REGW) begin
    if (dut.hart.priv.csr.genblk1.csrm.MCAUSE_REGW == 2 && instrs != 0) begin
      $display("!!!!!! illegal instruction !!!!!!!!!!");
      $display("(as a reminder, MCAUSE and MEPC are set by this)");
      $display("at %0t ps, instr %0d, HADDR %x", $time, instrs, HADDR);
      `ERROR
    end
    if (dut.hart.priv.csr.genblk1.csrm.MCAUSE_REGW == 5 && instrs != 0) begin
      $display("!!!!!! illegal (physical) memory access !!!!!!!!!!");
      $display("(as a reminder, MCAUSE and MEPC are set by this)");
      $display("at %0t ps, instr %0d, HADDR %x", $time, instrs, HADDR);
      `ERROR
    end
  end

  `define CHECK_CSR2(CSR, PATH) \
    string CSR; \
    logic [63:0] expected``CSR``; \
    //CSR checking \
    always @(``PATH``.``CSR``_REGW) begin \
        if ($time > 1) begin \
          scan_file_csr = $fscanf(data_file_csr, "%s\n", CSR); \
          scan_file_csr = $fscanf(data_file_csr, "%x\n", expected``CSR``); \
          if(CSR.icompare(`"CSR`")) begin \
            $display("%0t ps, instr %0d: %s changed, expected %s", $time, instrs, `"CSR`", CSR); \
          end \
          if(``PATH``.``CSR``_REGW != ``expected``CSR) begin \
            $display("%0t ps, instr %0d: %s does not equal %s expected: %x, %x", $time, instrs, `"CSR`", CSR, ``PATH``.``CSR``_REGW, ``expected``CSR); \
            `ERROR \
          end \
        end else begin \
          for(integer j=0; j<totalCSR; j++) begin \
            if(!StartCSRname[j].icompare(`"CSR`")) begin \
              if(``PATH``.``CSR``_REGW != StartCSRexpected[j]) begin \
                $display("%0t ps, instr %0d: %s does not equal %s expected: %x, %x", $time, instrs, `"CSR`", StartCSRname[j], ``PATH``.``CSR``_REGW, StartCSRexpected[j]); \
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

  //`CHECK_CSR(FCSR)
  `CHECK_CSR2(MCAUSE, `CSRM)
  `CHECK_CSR(MCOUNTEREN)
  `CHECK_CSR(MEDELEG)
  `CHECK_CSR(MEPC)
  //`CHECK_CSR(MHARTID)
  `CHECK_CSR(MIDELEG)
  `CHECK_CSR(MIE)
  //`CHECK_CSR(MIP)
  `CHECK_CSR2(MISA, `CSRM)
  `CHECK_CSR2(MSCRATCH, `CSRM)
  `CHECK_CSR(MSTATUS)
  `CHECK_CSR2(MTVAL, `CSRM)
  `CHECK_CSR(MTVEC)
  //`CHECK_CSR2(PMPADDR0, `CSRM)
  //`CHECK_CSR2(PMdut.PCFG0, `CSRM)
  `CHECK_CSR(SATP)
  `CHECK_CSR2(SCAUSE, `CSRS)
  `CHECK_CSR(SCOUNTEREN)
  `CHECK_CSR(SEPC)
  `CHECK_CSR(SIE)
  `CHECK_CSR2(SSCRATCH, `CSRS)
  `CHECK_CSR(SSTATUS)
  `CHECK_CSR2(STVAL, `CSRS)
  `CHECK_CSR(STVEC)

  initial begin //this is temporary until the bug can be fixed!!!
    #18909760;
    force dut.hart.ieu.dp.regf.rf[5] = 64'h0000000080000004;
    #100;
    release dut.hart.ieu.dp.regf.rf[5];
  end

  logic speculative;
  initial begin
    speculative = 0;
  end
  logic [63:0] lastCheckInstrF, lastPC, lastPC2;

  string PCtextW, PCtext2W;
  logic [31:0] InstrWExpected;
  logic [63:0] PCWExpected;
  always @(dut.hart.ifu.PCW or dut.hart.ieu.InstrValidW) begin
   if(dut.hart.ieu.InstrValidW && dut.hart.ifu.PCW != 0) begin
      if($feof(data_file_PCW)) begin
        $display("no more PC data to read");
        `ERROR
      end
      scan_file_PCW = $fscanf(data_file_PCW, "%s\n", PCtextW);
      if (PCtextW != "ret" && PCtextW != "fence" && PCtextW != "nop" && PCtextW != "mret" && PCtextW != "sfence.vma" && PCtextW != "unimp") begin
        scan_file_PC = $fscanf(data_file_PCW, "%s\n", PCtext2W);
        PCtextW = {PCtextW, " ", PCtext2W};
      end
      scan_file_PCW = $fscanf(data_file_PCW, "%x\n", InstrWExpected);
      // then expected PC value
      scan_file_PCW = $fscanf(data_file_PCW, "%x\n", PCWExpected);
      if(~equal(dut.hart.ifu.PCW,PCWExpected,2)) begin
        $display("%0t ps, instr %0d: PCW does not equal PCW expected: %x, %x", $time, instrs, dut.hart.ifu.PCW, PCWExpected);
        `ERROR
      end
      //if(it.InstrW != InstrWExpected) begin
      //  $display("%0t ps, instr %0d: InstrW does not equal InstrW expected: %x, %x", $time, instrs, it.InstrW, InstrWExpected);
      //end
    end
  end

  string PCtext, PCtext2;
  initial begin
    instrs = 0;
  end
  logic [31:0] InstrMask;
  logic forcedInstr;
  logic [63:0] lastPCF;
  always @(dut.PCF or dut.hart.ifu.InstrF or reset) begin
    if(~HWRITE) begin
    #3;
    if (~reset && dut.hart.ifu.InstrF[15:0] !== {16{1'bx}} && ~dut.hart.StallD) begin
      if (dut.PCF !== lastPCF) begin
        lastCheckInstrF = CheckInstrF;
        lastPC <= dut.PCF;
        lastPC2 <= lastPC;
        if (speculative && (lastPC != pcExpected)) begin
          speculative = ~equal(dut.PCF,pcExpected,3);
          if(dut.PCF===pcExpected) begin
            if(dut.hart.ifu.InstrF[6:0] == 7'b1010011) begin // for now, NOP out any float instrs
              force CheckInstrF = 32'b0010011;
              release CheckInstrF;
              force dut.hart.ifu.InstrF = 32'b0010011;
              #7;
              release dut.hart.ifu.InstrF;
              $display("warning: NOPing out %s at PC=%0x, instr %0d, time %0t", PCtext, dut.PCF, instrs, $time);
              warningCount += 1;
              forcedInstr = 1;
            end
            else begin
              if(dut.hart.ifu.InstrF[28:27] != 2'b11 && dut.hart.ifu.InstrF[6:0] == 7'b0101111) begin //for now, replace non-SC A instrs with LD
                force CheckInstrF = {12'b0, CheckInstrF[19:7], 7'b0000011};
                release CheckInstrF;
                force dut.hart.ifu.InstrF = {12'b0, dut.hart.ifu.InstrF[19:7], 7'b0000011};
                #7;
                release dut.hart.ifu.InstrF;
                $display("warning: replacing AMO instr %s at PC=%0x with ld", PCtext, dut.PCF);
                warningCount += 1;
                forcedInstr = 1;
              end
              else begin
                forcedInstr = 0;
              end
            end
          end
        end
        else begin
          if($feof(data_file_PC)) begin
            $display("no more PC data to read");
            `ERROR
          end
          scan_file_PC = $fscanf(data_file_PC, "%s\n", PCtext);
          if (PCtext != "ret" && PCtext != "fence" && PCtext != "nop" && PCtext != "mret" && PCtext != "sfence.vma" && PCtext != "unimp") begin
            scan_file_PC = $fscanf(data_file_PC, "%s\n", PCtext2);
            PCtext = {PCtext, " ", PCtext2};
          end
          scan_file_PC = $fscanf(data_file_PC, "%x\n", CheckInstrF);
          if(dut.PCF === pcExpected) begin
            if(dut.hart.ifu.InstrF[6:0] == 7'b1010011) begin // for now, NOP out any float instrs
              force CheckInstrF = 32'b0010011;
              release CheckInstrF;
              force dut.hart.ifu.InstrF = 32'b0010011;
              #7;
              release dut.hart.ifu.InstrF;
              $display("warning: NOPing out %s at PC=%0x, instr %0d, time %0t", PCtext, dut.PCF, instrs, $time);
              warningCount += 1;
              forcedInstr = 1;
            end
            else begin
              if(dut.hart.ifu.InstrF[28:27] != 2'b11 && dut.hart.ifu.InstrF[6:0] == 7'b0101111) begin //for now, replace non-SC A instrs with LD
                force CheckInstrF = {12'b0, CheckInstrF[19:7], 7'b0000011};
                release CheckInstrF;
                force dut.hart.ifu.InstrF = {12'b0, dut.hart.ifu.InstrF[19:7], 7'b0000011};
                #7;
                release dut.hart.ifu.InstrF;
                $display("warning: replacing AMO instr %s at PC=%0x with ld", PCtext, dut.PCF);
                warningCount += 1;
                forcedInstr = 1;
              end
              else begin
                forcedInstr = 0;
              end
            end
          end
          // then expected PC value
          scan_file_PC = $fscanf(data_file_PC, "%x\n", pcExpected);
          if (instrs <= 10 || (instrs <= 100 && instrs % 10 == 0) ||
             (instrs <= 1000 && instrs % 100 == 0) || (instrs <= 10000 && instrs % 1000 == 0) ||
             (instrs <= 100000 && instrs % 10000 == 0) || (instrs <= 1000000 && instrs % 100000 == 0)) begin
            $display("loaded %0d instructions", instrs);
          end
          instrs += 1;
          // are we at a branch/jump?
          casex (lastCheckInstrF[31:0])
            32'b00000000001000000000000001110011, // URET
            32'b00010000001000000000000001110011, // SRET
            32'b00110000001000000000000001110011, // MRET
            32'bXXXXXXXXXXXXXXXXXXXXXXXXX1101111, // JAL
            32'bXXXXXXXXXXXXXXXXXXXXXXXXX1100111, // JALR
            32'bXXXXXXXXXXXXXXXXXXXXXXXXX1100011, // B
            32'bXXXXXXXXXXXXXXXX110XXXXXXXXXXX01, // C.BEQZ
            32'bXXXXXXXXXXXXXXXX111XXXXXXXXXXX01, // C.BNEZ
            32'bXXXXXXXXXXXXXXXX101XXXXXXXXXXX01: // C.J
              speculative = 1;
            32'bXXXXXXXXXXXXXXXX1001000000000010: // C.EBREAK:
              speculative = 0; // tbh don't really know what should happen here
            32'bXXXXXXXXXXXXXXXX1000XXXXX0000010, // C.JR
            32'bXXXXXXXXXXXXXXXX1001XXXXX0000010: // C.JALR //this is RV64 only so no C.JAL
              speculative = 1;
            default:
              speculative = 0;
          endcase

          //check things!
          if ((~speculative) && (~equal(dut.PCF,pcExpected,3))) begin
            $display("%0t ps, instr %0d: PC does not equal PC expected: %x, %x", $time, instrs, dut.PCF, pcExpected);
            `ERROR
          end
          InstrMask = CheckInstrF[1:0] == 2'b11 ? 32'hFFFFFFFF : 32'h0000FFFF;
          if ((~forcedInstr) && (~speculative) && ((InstrMask & dut.hart.ifu.InstrF) !== (InstrMask & CheckInstrF))) begin
            $display("%0t ps, instr %0d: InstrF does not equal CheckInstrF: %x, %x, PC: %x", $time, instrs, dut.hart.ifu.InstrF, CheckInstrF, dut.PCF);
            `ERROR
          end
        end
      end
      lastPCF = dut.PCF;
    end
    end
  end

  // Track names of instructions
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  instrNameDecTB dec(dut.hart.ifu.InstrF, InstrFName);
  instrTrackerTB it(clk, reset, dut.hart.ieu.dp.FlushE,
                dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM,  InstrW,
                InstrDName, InstrEName, InstrMName, InstrWName);

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

endmodule
