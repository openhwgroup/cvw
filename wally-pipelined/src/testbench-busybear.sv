`include "wally-config.vh"

module testbench_busybear();

  logic            clk, reset;
  logic [`XLEN-1:0] WriteDataM, DataAdrM;
  logic [1:0]      MemRWM;
  logic [31:0]     GPIOPinsIn;
  logic [31:0]     GPIOPinsOut, GPIOPinsEn;

  // instantiate device to be tested
  logic [`XLEN-1:0] PCF, ReadDataM;
  logic [31:0] InstrF;
  logic [7:0]  ByteMaskM;
  logic        InstrAccessFaultF, DataAccessFaultM;
  logic        TimerIntM, SwIntM; // from CLINT
  logic        ExtIntM = 0; // not yet connected

  // for now, seem to need these to be zero until we get a better idea
  assign InstrAccessFaultF = 0;
  assign DataAccessFaultM = 0;
   
  // instantiate processor and memories
  wallypipelinedhart #(.PCSTART('h1000)) dut(.ALUResultM(DataAdrM), .*);

  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end
  
  // read pc trace file
  integer data_file_PC, scan_file_PC;
  initial begin
    data_file_PC = $fopen("busybear-testgen/parsedPC.txt", "r");
    if (data_file_PC == 0) begin
      $display("file couldn't be opened");
      $stop;
    end 
  end

  // read register trace file
  integer data_file_rf, scan_file_rf;
  initial begin
    data_file_rf = $fopen("busybear-testgen/parsedRegs.txt", "r");
    if (data_file_rf == 0) begin
      $display("file couldn't be opened");
      $stop;
    end 
  end

  // read memreads trace file
  integer data_file_mem, scan_file_mem;
  initial begin
    data_file_mem = $fopen("busybear-testgen/parsedMemRead.txt", "r");
    if (data_file_mem == 0) begin
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
    assign rf[i*64+63:i*64] = dut.dp.regf.rf[i];
  end
  endgenerate

  always @(rf) begin
    for(int j=1; j<32; j++) begin
      // read 31 integer registers
      scan_file_rf = $fscanf(data_file_rf, "%x\n", rfExpected[j]);
      // check things!
      if (rf[j*64+63 -: 64] != rfExpected[j]) begin
        $display("%t ps: rf[%0d] does not equal rf expected: %x, %x", $time, j, rf[j*64+63 -: 64], rfExpected[j]);
    //    $stop;
      end
    end
  end

  // this might need to change
  always @(MemRWM or DataAdrM) begin
    if (MemRWM != 0) begin
      scan_file_mem = $fscanf(data_file_mem, "%x\n", ReadDataM);
    end
  end

  logic speculative, nextSpec;
  initial begin
    speculative = 0;
    nextSpec = 0;
  end

  always @(PCF) begin
    speculative <= nextSpec;
    if (speculative) begin
      speculative <= (PCF != pcExpected);
    end
    if (~speculative) begin
      // first read instruction
      scan_file_PC = $fscanf(data_file_PC, "%x\n", InstrF);
      // then expected PC value
      scan_file_PC = $fscanf(data_file_PC, "%x\n", pcExpected);
      // are we at a branch/jump?
      case (InstrF[6:0]) //todo: add C versions of these
        7'b1101111, //JAL
        7'b1100111, //JALR
        7'b1100011: //B
          nextSpec <= 1;
        default:
          nextSpec <= 0;
      endcase

      //check things!
      if ((~nextSpec) && (PCF !== pcExpected)) begin
        $display("%t ps: PC does not equal PC expected: %x, %x", $time, PCF, pcExpected);
      //  $stop;
      end
    end
  end

  // Track names of instructions
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  instrNameDecTB dec(InstrF, InstrFName);
  instrTrackerTB it(clk, reset, dut.dp.FlushE,
                dut.dp.InstrDecompD, dut.dp.InstrE,
                dut.dp.InstrM,  InstrW,
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
