`include "wally-config.vh"

module testbench();
  logic        clk;
  logic        reset;

  string memfilename;

  logic [`AHBW-1:0] HRDATAEXT;
  logic             HREADYEXT, HRESPEXT;
  logic [31:0]      HADDR;
  logic [`AHBW-1:0] HWDATA;
  logic             HWRITE;
  logic [2:0]       HSIZE;
  logic [2:0]       HBURST;
  logic [3:0]       HPROT;
  logic [1:0]       HTRANS;
  logic             HMASTLOCK;
  logic             HCLK, HRESETn;

  logic [31:0] GPIOPinsIn, GPIOPinsOut, GPIOPinsEn;
  logic UARTSin, UARTSout;

  // instantiate device to be tested
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;
  assign HREADYEXT = 1;
  assign HRESPEXT = 0;
  assign HRDATAEXT = 0;

  wallypipelinedsoc dut(.*);

  // initialize tests
  initial
    begin
      memfilename = "../../imperas-riscv-tests/riscv-ovpsim-plus/examples/CoreMark/coremark.RV64I.bare.elf.memfile";
      $readmemh(memfilename, dut.imem.RAM);
      $readmemh(memfilename, dut.uncore.dtim.RAM);
      reset = 1; # 22; reset = 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk = 1; # 5; clk = 0; # 5;
    end
endmodule
