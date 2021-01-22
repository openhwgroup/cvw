`include "wally-macros.sv"

module testbench_busybear #(parameter XLEN=64, MISA=32'h00000104, ZCSR = 1, ZCOUNTERS = 1)();

  logic            clk, reset;
  logic [XLEN-1:0] WriteDataM, DataAdrM;
  logic [1:0]      MemRWM;
  logic [31:0]     GPIOPinsIn;
  logic [31:0]     GPIOPinsOut, GPIOPinsEn;

  // instantiate device to be tested
  logic [XLEN-1:0] PCF, ReadDataM;
  logic [31:0] InstrF;
  logic [7:0]  ByteMaskM;
  logic        InstrAccessFaultF, DataAccessFaultM;
  logic        TimerIntM, SwIntM; // from CLINT
  logic        ExtIntM = 0; // not yet connected
   
  // instantiate processor and memories
  wallypipelinedhart #(XLEN, MISA, ZCSR, ZCOUNTERS) dut(.ALUResultM(DataAdrM), .*);

  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end
  
  // read instr trace file
  integer data_file, scan_file;
  integer read_data;
  initial begin
    data_file = $fopen("busybear-testgen/parsed.txt", "r");
    if (data_file == 0) begin
      $display("file couldn't be opened");
      $stop;
    end 
   //   scan_file = $fscanf(data_file, "%x\n", read_data);
   //   $display("%x", read_data);

   //   scan_file = $fscanf(data_file, "%s\n", read_data);
   //   $display("%s", read_data);
   //   //if (!$feof(data_file)) begin
   //   //  $display(read_data);
   //   //end
   // end
  end
  logic [63:0] rfExpected[31:1];
  logic [63:0] pcExpected;

  always @(PCF) begin
    //$display("%x", PCF);
    scan_file = $fscanf(data_file, "%x\n", InstrF);
    for(int i=1; i < 32; i++) begin
      scan_file = $fscanf(data_file, "%x\n", rfExpected[i]);
    end
    scan_file = $fscanf(data_file, "%x\n", pcExpected);
    //check things!
    if (PCF != pcExpected) begin
      $display("PC does not equal PC expected: %x, %x", PCF, pcExpected);
    end


    //$display("%x", InstrF);
  end


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
