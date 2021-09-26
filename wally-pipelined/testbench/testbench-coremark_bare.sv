///////////////////////////////////////////
// testbench-imperas.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wally Testbench and helper modules
//          Applies test programs from the Imperas suite
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
  logic        clk;
  logic        reset;
  int test, i, errors, totalerrors;
  logic [31:0] sig32[10000:0];
  logic [`XLEN-1:0] signature[10000:0];
  logic [`XLEN-1:0] testadr;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [`XLEN-1:0] meminit;
  string tests[];
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
  
  // pick tests based on modes supported
  initial 
  tests = {"../../imperas-riscv-tests/riscv-ovpsim-plus/examples/CoreMark/coremarkcodemod.bare.riscv.memfile", "1000"};
  string signame, memfilename;
  logic [31:0] GPIOPinsIn, GPIOPinsOut, GPIOPinsEn;
  logic UARTSin, UARTSout;
  logic SDCCLK;
  tri1 SDCCmd;
  tri1 [3:0] SDCDat;

  assign SDCmd = 1'bz;
  assign SDCDat = 4'bz;
  

  // instantiate device to be tested
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;
  assign HREADYEXT = 1;
  assign HRESPEXT = 0;
  assign HRDATAEXT = 0;
  wallypipelinedsoc dut(.*); 

  logic [31:0] InstrW;
  flopenr  #(32)   InstrWReg(clk, reset, ~dut.hart.ieu.dp.StallW,  dut.hart.ifu.InstrM, InstrW);

  // Track names of instructions
  instrTrackerTB it(clk, reset, dut.hart.ieu.dp.FlushE,
                dut.hart.ifu.icache.controller.FinalInstrRawF,
                dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM, InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  logic [`XLEN-1:0] PCW;
  flopenr #(`XLEN) PCWReg(clk, reset, ~StallW, dut.hart.ifu.PCM, PCW);
  
  // initialize tests
  integer j;
  initial
    begin
      totalerrors = 0;
      // read test vectors into memory
      memfilename = tests[0];
      $readmemh(memfilename, dut.uncore.dtim.RAM);
      //for(j=268437955; j < 268566528; j = j+1)
        //dut.uncore.dtim.RAM[j] = 64'b0;
//      ProgramAddrMapFile = "../../imperas-riscv-tests/riscv-ovpsim-plus/examples/CoreMark/coremark.RV64IM.bare.elf.objdump.addr";
//      ProgramAddrMapFile = "../../imperas-riscv-tests/riscv-ovpsim-plus/examples/CoreMark/coremark.RV64IM.bare.elf.objdump.lab";
        //dut.uncore.dtim.RAM[268437713]=64'b1;
    reset = 1; # 22; reset = 0;
    end
  // generate clock to sequence tests
  always
    begin
      clk = 1; # 5; clk = 0; # 5;
    end
  always @(negedge clk)
    begin
      if (dut.hart.priv.ecallM) begin
        #20;
        $display("Code ended with ebreakM");
        $stop;
      end
    end

  initial begin
    $readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.bpred.Predictor.DirPredictor.PHT.memory);
    $readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.bpred.TargetPredictor.memory.memory);
  end
   
endmodule
/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */
