`include "wally-config.vh"

module testbench_busybear();

  logic            clk, reset;
  logic [31:0]     GPIOPinsIn;
  logic [31:0]     GPIOPinsOut, GPIOPinsEn;

  // instantiate device to be tested
  logic [`XLEN-1:0] PCF; 
  logic [31:0] InstrF;
  logic        InstrAccessFaultF, DataAccessFaultM;
  logic        TimerIntM = 0, SwIntM = 0; // from CLINT
  logic        ExtIntM = 0; // not yet connected

  logic [`AHBW-1:0] HRDATA;
  logic             HREADY, HRESP;
  logic [31:0]      HADDR;
  logic [`AHBW-1:0] HWDATA;
  logic             HWRITE;
  logic [2:0]       HSIZE;
  logic [2:0]       HBURST;
  logic [3:0]       HPROT;
  logic [1:0]       HTRANS;
  logic             HMASTLOCK;
  logic             HCLK, HRESETn;

  assign GPIOPinsIn = 0;
  assign UARTSin = 1;
  assign HREADY = 1;
  assign HRESP = 0;
  assign HRDATA = 0;

  // for now, seem to need these to be zero until we get a better idea
  assign InstrAccessFaultF = 0;
  assign DataAccessFaultM = 0;
   
  // instantiate processor and memories
  wallypipelinedhart dut(.*);

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
  integer warningCount = 0;
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
      always @(dut.ieu.dp.regf.rf[i]) begin
        if ($time == 0) begin
          scan_file_rf = $fscanf(data_file_rf, "%x\n", regExpected);
          if (dut.ieu.dp.regf.rf[i] != regExpected) begin
            $display("%t ps, instr %0d: rf[%0d] does not equal rf expected: %x, %x", $time, instrs, i, dut.ieu.dp.regf.rf[i], regExpected);
            `ERROR
          end
        end else begin
          scan_file_rf = $fscanf(data_file_rf, "%d\n", regNumExpected);
          scan_file_rf = $fscanf(data_file_rf, "%x\n", regExpected);
          if (i != regNumExpected) begin
            $display("%t ps, instr %0d: wrong register changed: %0d, %0d expected", $time, instrs, i, regNumExpected);
          end
          if (dut.ieu.dp.regf.rf[i] != regExpected) begin
            $display("%t ps, instr %0d: rf[%0d] does not equal rf expected: %x, %x", $time, instrs, i, dut.ieu.dp.regf.rf[i], regExpected);
            `ERROR
          end
        end
      end
    end
  endgenerate

  logic [`XLEN-1:0] readAdrExpected;
  // this might need to change
  always @(dut.MemRWM[1] or HADDR) begin
    if (dut.MemRWM[1]) begin
      if($feof(data_file_memR)) begin
        $display("no more memR data to read");
        `ERROR
      end
      scan_file_memR = $fscanf(data_file_memR, "%x\n", readAdrExpected);
      scan_file_memR = $fscanf(data_file_memR, "%x\n", HRDATA);
      #1;
      if (HADDR != readAdrExpected) begin
        $display("%t ps, instr %0d: HADDR does not equal readAdrExpected: %x, %x", $time, instrs, HADDR, readAdrExpected);
        `ERROR
      end
    end
  end
      
  logic [`XLEN-1:0] writeDataExpected, writeAdrExpected;
  // this might need to change
  always @(HWDATA or HADDR or HSIZE) begin
    #1;
    if (HWRITE) begin
      if($feof(data_file_memW)) begin
        $display("no more memW data to read");
        `ERROR
      end
      scan_file_memW = $fscanf(data_file_memW, "%x\n", writeDataExpected);
      scan_file_memW = $fscanf(data_file_memW, "%x\n", writeAdrExpected);
      if (writeDataExpected != HWDATA) begin
        $display("%t ps, instr %0d: HWDATA does not equal writeDataExpected: %x, %x", $time, instrs, HWDATA, writeDataExpected);
        `ERROR
      end
      if (writeAdrExpected != HADDR) begin
        $display("%t ps, instr %0d: HADDR does not equal writeAdrExpected: %x, %x", $time, instrs, HADDR, writeAdrExpected);
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
    
  `define CHECK_CSR2(CSR, PATH) \
    string CSR; \
    logic [63:0] expected``CSR``; \
    //CSR checking \
    always @(``PATH``.``CSR``_REGW) begin \
        if ($time > 1) begin \
          scan_file_csr = $fscanf(data_file_csr, "%s\n", CSR); \
          scan_file_csr = $fscanf(data_file_csr, "%x\n", expected``CSR``); \
          if(CSR.icompare(`"CSR`")) begin \
            $display("%t ps, instr %0d: %s changed, expected %s", $time, instrs, `"CSR`", CSR); \
          end \
          if(``PATH``.``CSR``_REGW != ``expected``CSR) begin \
            $display("%t ps, instr %0d: %s does not equal %s expected: %x, %x", $time, instrs, `"CSR`", CSR, ``PATH``.``CSR``_REGW, ``expected``CSR); \
            `ERROR \
          end \
        end else begin \
          for(integer j=0; j<totalCSR; j++) begin \
            if(!StartCSRname[j].icompare(`"CSR`")) begin \
              if(``PATH``.``CSR``_REGW != StartCSRexpected[j]) begin \
                $display("%t ps, instr %0d: %s does not equal %s expected: %x, %x", $time, instrs, `"CSR`", StartCSRname[j], ``PATH``.``CSR``_REGW, StartCSRexpected[j]); \
                `ERROR \
              end \
            end \
          end \
        end \
    end
  `define CHECK_CSR(CSR) \
     `CHECK_CSR2(CSR, dut.priv.csr) 

  //`CHECK_CSR(FCSR)
  `CHECK_CSR(MCOUNTEREN)
  `CHECK_CSR(MEDELEG)
  `CHECK_CSR(MIDELEG)
  //`CHECK_CSR(MHARTID)
  `CHECK_CSR(MIE)
  `CHECK_CSR2(MISA, dut.priv.csr.genblk1.csrm)
  `CHECK_CSR2(MSCRATCH, dut.priv.csr.genblk1.csrm)
  `CHECK_CSR(MSTATUS)
  `CHECK_CSR(MTVEC)
  `CHECK_CSR2(SATP, dut.priv.csr.genblk1.csrs.genblk1)
  `CHECK_CSR(SCOUNTEREN)
  `CHECK_CSR(SIE)
  //`CHECK_CSR(SSTATUS)

  logic speculative;
  initial begin
    speculative = 0;
    speculative = 0;
  end
  logic [63:0] lastInstrF, lastPC, lastPC2;

  string PCtextW, PCtext2W;
  logic [31:0] InstrWExpected;
  logic [63:0] PCWExpected;
  always @(dut.ifu.PCW or dut.ieu.InstrValidW) begin
   if(dut.ieu.InstrValidW && dut.ifu.PCW != 0) begin
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
      if(dut.ifu.PCW != PCWExpected) begin
        $display("%t ps, instr %0d: PCW does not equal PCW expected: %x, %x", $time, instrs, dut.ifu.PCW, PCWExpected);
        `ERROR
      end
      //if(it.InstrW != InstrWExpected) begin
      //  $display("%t ps, instr %0d: InstrW does not equal InstrW expected: %x, %x", $time, instrs, it.InstrW, InstrWExpected);
      //end
    end
  end

  string PCtext, PCtext2;
  integer instrs;
  initial begin
    instrs = 0;
  end 
  always @(PCF) begin
    lastInstrF = InstrF;
    lastPC <= PCF;
    lastPC2 <= lastPC;
    if (speculative && lastPC != pcExpected) begin
      speculative = (PCF != pcExpected);
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
      scan_file_PC = $fscanf(data_file_PC, "%x\n", InstrF);
      if(InstrF[6:0] == 7'b1010011) begin // for now, NOP out any float instrs
        InstrF = 32'b0010011;
        $display("warning: NOPing out %s at PC=%0x", PCtext, PCF);
        warningCount += 1;
      end
      if(InstrF[28:27] != 2'b11 && InstrF[6:0] == 7'b0101111) begin //for now, replace non-SC A instrs with LD
        InstrF = {12'b0, InstrF[19:7], 7'b0000011};
        $display("warning: replacing AMO instr %s at PC=%0x with ld", PCtext, PCF);
        warningCount += 1;
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
      casex (lastInstrF[31:0]) 
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
      if ((~speculative) && (PCF !== pcExpected)) begin
        $display("%t ps, instr %0d: PC does not equal PC expected: %x, %x", $time, instrs, PCF, pcExpected);
        `ERROR
      end
    end
  end

  // Track names of instructions
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  instrNameDecTB dec(InstrF, InstrFName);
  instrTrackerTB it(clk, reset, dut.ieu.dp.FlushE,
                dut.ifu.InstrD, dut.ifu.InstrE,
                dut.ifu.InstrM,  InstrW,
                InstrDName, InstrEName, InstrMName, InstrWName);

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

endmodule
