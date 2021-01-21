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
