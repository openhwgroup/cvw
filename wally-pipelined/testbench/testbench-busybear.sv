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
    data_file_PC = $fopen("../busybear-testgen/parsedPC.txt", "r");
    if (data_file_PC == 0) begin
      $display("file couldn't be opened");
      $stop;
    end 
  end

  // read register trace file
  integer data_file_rf, scan_file_rf;
  initial begin
    data_file_rf = $fopen("../busybear-testgen/parsedRegs.txt", "r");
    if (data_file_rf == 0) begin
      $display("file couldn't be opened");
      $stop;
    end 
  end

  // read memreads trace file
  integer data_file_memR, scan_file_memR;
  initial begin
    data_file_memR = $fopen("../busybear-testgen/parsedMemRead.txt", "r");
    if (data_file_memR == 0) begin
      $display("file couldn't be opened");
      $stop;
    end 
  end
  
  // read memwrite trace file
  integer data_file_memW, scan_file_memW;
  initial begin
    data_file_memW = $fopen("../busybear-testgen/parsedMemWrite.txt", "r");
    if (data_file_memW == 0) begin
      $display("file couldn't be opened");
      $stop;
    end 
  end

  logic [63:0] rfExpected[31:1];
  logic [63:0] pcExpected;
  // I apologize for this hack, I don't have a clue how to properly work with packed arrays
  logic [64*32:64] rf;
  genvar i;
  generate
  for(i=1; i<32; i++) begin
    assign rf[i*64+63:i*64] = dut.ieu.dp.regf.rf[i];
  end
  endgenerate

  always @(rf) begin
    for(int j=1; j<32; j++) begin
      if($feof(data_file_rf)) begin
        $display("no more rf data to read");
        $stop;
      end
      // read 31 integer registers
      scan_file_rf = $fscanf(data_file_rf, "%x\n", rfExpected[j]);
      // check things!
      if (rf[j*64+63 -: 64] != rfExpected[j]) begin
        $display("%t ps, instr %0d: rf[%0d] does not equal rf expected: %x, %x", $time, instrs, j, rf[j*64+63 -: 64], rfExpected[j]);
    //    $stop;
      end
    end
  end

  logic [`XLEN-1:0] readAdrExpected;
  // this might need to change
  always @(dut.MemRWM[1] or HADDR) begin
    if (dut.MemRWM[1]) begin
      if($feof(data_file_memR)) begin
        $display("no more memR data to read");
        $stop;
      end
      scan_file_memR = $fscanf(data_file_memR, "%x\n", readAdrExpected);
      scan_file_memR = $fscanf(data_file_memR, "%x\n", HRDATA);
      #1;
      if (HADDR != readAdrExpected) begin
        $display("%t ps, instr %0d: HADDR does not equal readAdrExpected: %x, %x", $time, instrs, HADDR, readAdrExpected);
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
        $stop;
      end
      scan_file_memW = $fscanf(data_file_memW, "%x\n", writeDataExpected);
      scan_file_memW = $fscanf(data_file_memW, "%x\n", writeAdrExpected);
      if (writeDataExpected != HWDATA) begin
        $display("%t ps, instr %0d: HWDATA does not equal writeDataExpected: %x, %x", $time, instrs, HWDATA, writeDataExpected);
      end
      if (writeAdrExpected != HADDR) begin
        $display("%t ps, instr %0d: HADDR does not equal writeAdrExpected: %x, %x", $time, instrs, HADDR, writeAdrExpected);
      end
    end
  end

  logic speculative;
  initial begin
    speculative = 0;
    speculative = 0;
  end
  logic [63:0] lastInstrF, lastPC, lastPC2;
  
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
    //if (~speculative) begin
      if($feof(data_file_PC)) begin
        $display("no more PC data to read");
        $stop;
      end
      // first read instruction
      scan_file_PC = $fscanf(data_file_PC, "%s\n", PCtext);
      if (PCtext != "ret") begin
        scan_file_PC = $fscanf(data_file_PC, "%s\n", PCtext2);
        PCtext = {PCtext, " ", PCtext2};
      end
      scan_file_PC = $fscanf(data_file_PC, "%x\n", InstrF);
      if(InstrF[6:0] == 7'b1010011) // for now, NOP out any float instrs
        InstrF = 32'b0010011;
      // then expected PC value
      scan_file_PC = $fscanf(data_file_PC, "%x\n", pcExpected);
      if (instrs <= 10 || (instrs <= 100 && instrs % 10 == 0) ||
         (instrs <= 1000 && instrs % 100 == 0) || (instrs <= 10000 && instrs % 1000 == 0) ||
         (instrs <= 100000 && instrs % 10000 == 0)) begin
        $display("loaded %0d instructions", instrs);
      end
      instrs += 1;
      // are we at a branch/jump?
      casex (lastInstrF[15:0]) 
        16'bXXXXXXXXX1101111, // JAL
        16'bXXXXXXXXX1100111, // JALR
        16'bXXXXXXXXX1100011, // B
        16'b110XXXXXXXXXXX01, // C.BEQZ
        16'b111XXXXXXXXXXX01, // C.BNEZ
        16'b101XXXXXXXXXXX01: // C.J
          speculative = 1;
        16'b1001000000000010: // C.EBREAK:
          speculative = 0; // tbh don't really know what should happen here
        16'b1000XXXXX0000010, // C.JR
        16'b1001XXXXX0000010: // C.JALR //this is RV64 only so no C.JAL
          speculative = 1;
        default:
          speculative = 0;
      endcase

      //check things!
      if ((~speculative) && (PCF !== pcExpected)) begin
        $display("%t ps, instr %0d: PC does not equal PC expected: %x, %x", $time, instrs, PCF, pcExpected);
      //  $stop;
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

  //// check results
  //always @(negedge clk)
  //  begin
  //    if(MemWrite) begin
  //      if(DataAdr === 84 & WriteData === 71) begin
  //        $display("Simulation succeeded");
  //        $stop;
  //      end else if (DataAdr !== 80) begin
  //        $display("Simulation failed");
  //        $stop;
  //      end
  //    end
  //  end
endmodule
