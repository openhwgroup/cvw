`include "wally-config.vh"
`include "wally-constants.vh"


module testbench();
  logic            clk, reset;
  logic [31:0]     GPIOPinsIn;
  logic [31:0]     GPIOPinsOut, GPIOPinsEn;

  // instantiate device to be tested
  logic [31:0] CheckInstrD;

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

  /**
   * Walk the page table stored in dtim according to sv39 logic and translate a
   * virtual address to a physical address.
   *
   * See section 4.3.2 of the RISC-V Privileged specification for a full
   * explanation of the below algorithm.
   */
  function logic [`XLEN-1:0] adrTranslator( 
    input logic [`XLEN-1:0] adrIn);
    begin
      logic             SvMode, PTE_R, PTE_X;
      logic [`XLEN-1:0] SATP, PTE;
      logic [55:0]      BaseAdr, PAdr;
      logic [8:0]       VPN [0:2];
      logic [11:0]      Offset;

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

  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // read pc trace file
  integer data_file_PC, scan_file_PC;
  initial begin
    data_file_PC = $fopen({`BUSYBEAR_TEST_VECTORS,"parsedPC.txt"}, "r");
    if (data_file_PC == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  integer data_file_PCW, scan_file_PCW;
  initial begin
    data_file_PCW = $fopen({`BUSYBEAR_TEST_VECTORS,"parsedPC.txt"}, "r");
    if (data_file_PCW == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // read register trace file
  integer data_file_rf, scan_file_rf;
  initial begin
    data_file_rf = $fopen({`BUSYBEAR_TEST_VECTORS,"parsedRegs.txt"}, "r");
    if (data_file_rf == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // read CSR trace file
  integer data_file_csr, scan_file_csr;
  initial begin
    data_file_csr = $fopen({`BUSYBEAR_TEST_VECTORS,"parsedCSRs2.txt"}, "r");
    if (data_file_csr == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // read memreads trace file
  integer data_file_memR, scan_file_memR;
  initial begin
    data_file_memR = $fopen({`BUSYBEAR_TEST_VECTORS,"parsedMemRead.txt"}, "r");
    if (data_file_memR == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // read memwrite trace file
  integer data_file_memW, scan_file_memW;
  initial begin
    data_file_memW = $fopen({`BUSYBEAR_TEST_VECTORS,"parsedMemWrite.txt"}, "r");
    if (data_file_memW == 0) begin
      $display("file couldn't be opened");
      $stop;
    end
  end

  // initial loading of memories
  initial begin
    $readmemh({`BUSYBEAR_TEST_VECTORS,"bootmem.txt"}, dut.uncore.bootdtim.RAM, 'h1000 >> 3);
    $readmemh({`BUSYBEAR_TEST_VECTORS,"ram.txt"}, dut.uncore.dtim.RAM);
    $readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.bpred.Predictor.DirPredictor.PHT.memory);
    $readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.bpred.TargetPredictor.memory.memory);
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
  logic [`XLEN-1:0] PCW;
  
  flopenr #(`XLEN) PCWReg(clk, reset, ~dut.hart.ieu.dp.StallW, dut.hart.ifu.PCM, PCW);

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

  logic [`XLEN-1:0] readAdrExpected, readAdrTranslated;

  always @(dut.HRDATA) begin
    #2;
    if (dut.hart.MemRWM[1]
      && (dut.hart.ebu.CaptureDataM)
      && dut.HRDATA !== {64{1'bx}}) begin
      //$display("%0t", $time);
      if($feof(data_file_memR)) begin
        $display("no more memR data to read");
        `ERROR
      end
      scan_file_memR = $fscanf(data_file_memR, "%x\n", readAdrExpected);
      scan_file_memR = $fscanf(data_file_memR, "%x\n", HRDATA);
      assign readAdrTranslated = adrTranslator(readAdrExpected);
      if (~equal(HADDR,readAdrTranslated,4)) begin
        $display("%0t ps, instr %0d: HADDR does not equal readAdrExpected: %x, %x", $time, instrs, HADDR, readAdrTranslated);
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

  logic [`XLEN-1:0] writeDataExpected, writeAdrExpected, writeAdrTranslated;

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
      assign writeAdrTranslated = adrTranslator(writeAdrExpected);

      if (writeDataExpected != HWDATA && ~dut.uncore.HSELPLICD) begin
        $display("%0t ps, instr %0d: HWDATA does not equal writeDataExpected: %x, %x", $time, instrs, HWDATA, writeDataExpected);
        `ERROR
      end
      if (~equal(writeAdrTranslated,HADDR,1) && ~dut.uncore.HSELPLICD) begin
        $display("%0t ps, instr %0d: HADDR does not equal writeAdrExpected: %x, %x", $time, instrs, HADDR, writeAdrTranslated);
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
    if (dut.hart.priv.csr.genblk1.csrm.MCAUSE_REGW == 2 && instrs > 1) begin
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
          if ("SEPC" == `"CSR`") begin #1; end \
          if ("SCAUSE" == `"CSR`") begin #2; end \
          if ("SSTATUS" == `"CSR`") begin #3; end \
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
          if (!(`BUILDROOT == 1 && "MSTATUS" == `"CSR`")) begin \
            for(integer j=0; j<totalCSR; j++) begin \
              if(!StartCSRname[j].icompare(`"CSR`")) begin \
                if(``PATH``.``CSR``_REGW != StartCSRexpected[j]) begin \
                  $display("%0t ps, instr %0d: %s does not equal %s expected: %x, %x", $time, instrs, `"CSR`", StartCSRname[j], ``PATH``.``CSR``_REGW, StartCSRexpected[j]); \
                  `ERROR \
                end \
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

  logic speculative;
  initial begin
    speculative = 0;
  end
  logic [63:0] lastCheckInstrD, lastPC, lastPC2;

  string PCtextW, PCtext2W;
  logic [31:0] InstrWExpected;
  logic [63:0] PCWExpected;
  always @(PCW or dut.hart.ieu.InstrValidW) begin
   if(dut.hart.ieu.InstrValidW && PCW != 0) begin
      if($feof(data_file_PCW)) begin
        $display("no more PC data to read");
        `ERROR
      end
      scan_file_PCW = $fscanf(data_file_PCW, "%s\n", PCtextW);
      PCtext2W = "";
      while (PCtext2W != "***") begin
        PCtextW = {PCtextW, " ", PCtext2W};
        scan_file_PC = $fscanf(data_file_PCW, "%s\n", PCtext2W);
      end
      scan_file_PCW = $fscanf(data_file_PCW, "%x\n", InstrWExpected);
      // then expected PC value
      scan_file_PCW = $fscanf(data_file_PCW, "%x\n", PCWExpected);
      if(~equal(PCW,PCWExpected,2)) begin
        $display("%0t ps, instr %0d: PCW does not equal PCW expected: %x, %x", $time, instrs, PCW, PCWExpected);
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
  logic [63:0] lastPCD;
  always @(dut.hart.ifu.PCD or dut.hart.ifu.InstrRawD or reset or negedge dut.hart.ifu.StallE) begin
    if(~HWRITE) begin
      #2;
      if (~reset && dut.hart.ifu.InstrRawD[15:0] !== {16{1'bx}} && dut.hart.ifu.PCD !== 64'h0 && ~dut.hart.ifu.StallE) begin
        if (dut.hart.ifu.PCD !== lastPCD) begin
          lastCheckInstrD = CheckInstrD;
          lastPC <= dut.hart.ifu.PCD;
          lastPC2 <= lastPC;
          if (speculative && (lastPC != pcExpected)) begin
            speculative = ~equal(dut.hart.ifu.PCD,pcExpected,3);
            if(dut.hart.ifu.PCD===pcExpected) begin
              if((dut.hart.ifu.InstrRawD[6:0] == 7'b1010011) || // for now, NOP out any float instrs
                 (dut.hart.ifu.PCD == 32'h80001dc6) ||          // as well as stores to PLIC
                 (dut.hart.ifu.PCD == 32'h80001de0) ||
                 (dut.hart.ifu.PCD == 32'h80001de2)) begin 
                $display("warning: NOPing out %s at PC=%0x, instr %0d, time %0t", PCtext, dut.hart.ifu.PCD, instrs, $time);
                force CheckInstrD = 32'b0010011;
                force dut.hart.ifu.InstrRawD = 32'b0010011;
                while (clk != 0) #1;
                while (clk != 1) #1;
                release dut.hart.ifu.InstrRawD;
                release CheckInstrD;
                warningCount += 1;
                forcedInstr = 1;
              end
              else begin
                forcedInstr = 0;
              end
            end
          end
          else begin
            if($feof(data_file_PC)) begin
              $display("no more PC data to read");
              `ERROR
            end
            scan_file_PC = $fscanf(data_file_PC, "%s\n", PCtext);
            PCtext2 = "";
            while (PCtext2 != "***") begin
              PCtext = {PCtext, " ", PCtext2};
              scan_file_PC = $fscanf(data_file_PC, "%s\n", PCtext2);
            end
            scan_file_PC = $fscanf(data_file_PC, "%x\n", CheckInstrD);
            if(dut.hart.ifu.PCD === pcExpected) begin
              if((dut.hart.ifu.InstrRawD[6:0] == 7'b1010011) || // for now, NOP out any float instrs
                 (dut.hart.ifu.PCD == 32'h80001dc6) ||          // as well as stores to PLIC
                 (dut.hart.ifu.PCD == 32'h80001de0) ||
                 (dut.hart.ifu.PCD == 32'h80001de2)) begin 
                $display("warning: NOPing out %s at PC=%0x, instr %0d, time %0t", PCtext, dut.hart.ifu.PCD, instrs, $time);
                force CheckInstrD = 32'b0010011;
                force dut.hart.ifu.InstrRawD = 32'b0010011;
                while (clk != 0) #1;
                while (clk != 1) #1;
                release dut.hart.ifu.InstrRawD;
                release CheckInstrD;
                warningCount += 1;
                forcedInstr = 1;
              end
              else begin
                forcedInstr = 0;
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
            if (`BPRED_ENABLED) begin
              speculative = dut.hart.ifu.bpred.bpred.BPPredWrongE;
            end else begin
              casex (lastCheckInstrD[31:0])
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
                32'bXXXXXXXXXXXXXXXX1001000000000010, // C.EBREAK:
                32'bXXXXXXXXXXXXXXXXX000XXXXX1110011: // Something that's not CSRR*
                  speculative = 0; // tbh don't really know what should happen here
                32'b000110000000XXXXXXXXXXXXX1110011, // CSR* SATP, *
                32'bXXXXXXXXXXXXXXXX1000XXXXX0000010, // C.JR
                32'bXXXXXXXXXXXXXXXX1001XXXXX0000010: // C.JALR //this is RV64 only so no C.JAL
                  speculative = 1;
                default:
                  speculative = 0;
              endcase
            end

            //check things!
            if ((~speculative) && (~equal(dut.hart.ifu.PCD,pcExpected,3))) begin
              $display("%0t ps, instr %0d: PC does not equal PC expected: %x, %x", $time, instrs, dut.hart.ifu.PCD, pcExpected);
              `ERROR
            end
            InstrMask = CheckInstrD[1:0] == 2'b11 ? 32'hFFFFFFFF : 32'h0000FFFF;
            if ((~forcedInstr) && (~speculative) && ((InstrMask & dut.hart.ifu.InstrRawD) !== (InstrMask & CheckInstrD))) begin
              $display("%0t ps, instr %0d: InstrD does not equal CheckInstrD: %x, %x, PC: %x", $time, instrs, dut.hart.ifu.InstrRawD, CheckInstrD, dut.hart.ifu.PCD);
              `ERROR
            end
          end
        end
        lastPCD = dut.hart.ifu.PCD;
      end
    end
  end

  // Track names of instructions
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  instrTrackerTB it(clk, reset,
                dut.hart.ifu.icache.controller.FinalInstrRawF,
                dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM,  dut.hart.ifu.InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

endmodule
module instrTrackerTB(
  input  logic            clk, reset,
  input  logic [31:0]     InstrF,InstrD,InstrE,InstrM,InstrW,
  output string           InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);
        
  // stage Instr to Writeback for visualization
  //flopr  #(32) InstrWReg(clk, reset, InstrM, InstrW);

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

