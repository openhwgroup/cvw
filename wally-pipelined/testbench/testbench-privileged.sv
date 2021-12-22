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
  parameter DEBUG = 0;
  parameter TESTSBP = 0;
  
  logic        clk;
  logic        reset;

  int test, i, errors, totalerrors;
  logic [31:0] sig32[10000:0];
  logic [`XLEN-1:0] signature[10000:0];
  logic [`XLEN-1:0] testadr;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  //logic [31:0] InstrW;
  logic [`XLEN-1:0] meminit;
 //string tests64i[] = 
  string tests[] = '{                 
                     "rv64p/WALLY-CAUSE", "3000"
                     };
  string ProgramAddrMapFile, ProgramLabelMapFile;
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
  //initial 
 //    if (`XLEN == 64) begin // RV64
 //      if(TESTSBP) begin
 //  tests = testsBP64;  
 //      end else begin 
 //  tests = {tests64i};
 //  if (`C_SUPPORTED) tests = {tests, tests64ic};
 //  else              tests = {tests, tests64iNOc};
 //  if (`M_SUPPORTED) tests = {tests, tests64m};
 //  if (`A_SUPPORTED) tests = {tests, tests64a};
 //      end
 // //     tests = {tests64a, tests};
 //    end else begin // RV32
 //      // *** add the 32 bit bp tests
 //      tests = {tests32i};
 //      if (`C_SUPPORTED % 2 == 1) tests = {tests, tests32ic};    
 //      else                       tests = {tests, tests32iNOc};
 //      if (`M_SUPPORTED % 2 == 1) tests = {tests, tests32m};
 //      if (`A_SUPPORTED) tests = {tests, tests32a};
 //    end
  string signame, memfilename;

  logic [31:0] GPIOPinsIn, GPIOPinsOut, GPIOPinsEn;
  logic UARTSin, UARTSout;

  // instantiate device to be tested
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;
  assign HREADYEXT = 1;
  assign HRESPEXT = 0;
  assign HRDATAEXT = 0;

  wallypipelinedsoc dut(.clk, .reset_ext, .HRDATAEXT,.HREADYEXT, .HRESPEXT,.HSELEXT,
                        .HCLK, .HRESETn, .HADDR, .HWDATA, .HWRITE, .HSIZE, .HBURST, .HPROT,
                        .HTRANS, .HMASTLOCK, .HREADY, .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn,
                        .UARTSin, .UARTSout, .SDCCmdIn, .SDCCmdOut, .SDCCmdOE, .SDCDatIn, .SDCCLK); 
  flopenr  #(32)   InstrWReg(clk, reset, ~dut.hart.ieu.dp.StallW,  dut.hart.ifu.InstrM, InstrW);
  // Track names of instructions
  instrTrackerTBPriv it(clk, reset, dut.hart.ieu.dp.FlushE,
                dut.hart.ifu.InstrF, dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM,  dut.hart.ifu.InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  logic [`XLEN-1:0] PCW;
  flopenr #(`XLEN) PCWReg(clk, reset, ~StallW, dut.hart.ifu.PCM, PCW);
  // initialize tests
  initial
    begin
      test = 0;
      totalerrors = 0;
      testadr = 0;
      // fill memory with defined values to reduce Xs in simulation
      if (`XLEN == 32) meminit = 32'hFEDC0123;
      else meminit = 64'hFEDCBA9876543210;
      for (i=0; i<=65535; i = i+1) begin
        //dut.imem.RAM[i] = meminit;
       // dut.uncore.RAM[i] = meminit;
      end
      // read test vectors into memory
      memfilename = {"../../imperas-riscv-tests/work/", tests[test], ".elf.memfile"};
      $readmemh(memfilename, dut.uncore.ram.RAM);
      ProgramAddrMapFile = {"../../imperas-riscv-tests/work/", tests[test], ".elf.objdump.addr"};
      ProgramLabelMapFile = {"../../imperas-riscv-tests/work/", tests[test], ".elf.objdump.lab"};
      $display("Read memfile %s", memfilename);
      reset = 1; # 42; reset = 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk = 1; # 5; clk = 0; # 5;
    end
   
  // check results
  always @(negedge clk)
    begin    
      if (dut.hart.priv.EcallFaultM && 
          (dut.hart.ieu.dp.regf.rf[3] == 1 || (dut.hart.ieu.dp.regf.we3 && dut.hart.ieu.dp.regf.a3 == 3 && dut.hart.ieu.dp.regf.wd3 == 1))) begin
        $display("Code ended with ecall with gp = 1");
        #60; // give time for instructions in pipeline to finish
        // clear signature to prevent contamination from previous tests
        for(i=0; i<10000; i=i+1) begin
          sig32[i] = 'bx;
        end

        // read signature, reformat in 64 bits if necessary
        signame = {"../../imperas-riscv-tests/work/", tests[test], ".signature.output"};
        $readmemh(signame, sig32);
        i = 0;
        while (i < 10000) begin
          if (`XLEN == 32) begin
            signature[i] = sig32[i];
            i = i+1;
          end else begin
            signature[i/2] = {sig32[i+1], sig32[i]};
            i = i + 2;
          end
        end

        // Check errors
        i = 0;
        errors = 0;
        if (`XLEN == 32)
          testadr = (`RAM_BASE+tests[test+1].atohex())/4;
        else
          testadr = (`RAM_BASE+tests[test+1].atohex())/8;
        /* verilator lint_off INFINITELOOP */
        while (signature[i] !== 'bx) begin
          //$display("signature[%h] = %h", i, signature[i]);
          if (signature[i] !== dut.uncore.ram.RAM[testadr+i]) begin
            if (signature[i+4] !== 'bx || signature[i] !== 32'hFFFFFFFF) begin
              // report errors unless they are garbage at the end of the sim
              // kind of hacky test for garbage right now
              errors = errors+1;
              $display("  Error on test %s result %d: adr = %h sim = %h, signature = %h", 
                    tests[test], i, (testadr+i)*`XLEN/8, dut.uncore.ram.RAM[testadr+i], signature[i]);
            end
          end
          i = i + 1;
        end
        /* verilator lint_on INFINITELOOP */
        if (errors == 0) $display("%s succeeded.  Brilliant!!!", tests[test]);
        else begin
          $display("%s failed with %d errors. :(", tests[test], errors);
          totalerrors = totalerrors+1;
        end
        test = test + 2;
        if (test == tests.size()) begin
          if (totalerrors == 0) $display("SUCCESS! All tests ran without failures.");
          else $display("FAIL: %d test programs had errors", totalerrors);
          $stop;
        end
        else begin
          memfilename = {"../../imperas-riscv-tests/work/", tests[test], ".elf.memfile"};
          $readmemh(memfilename, dut.uncore.ram.RAM);
          $display("Read memfile %s", memfilename);
    ProgramAddrMapFile = {"../../imperas-riscv-tests/work/", tests[test], ".elf.objdump.addr"};
    ProgramLabelMapFile = {"../../imperas-riscv-tests/work/", tests[test], ".elf.objdump.lab"};
          reset = 1; # 17; reset = 0;
        end
      end
    end // always @ (negedge clk)

  // track the current function or global label
  if (DEBUG == 1) begin : functionRadix
    function_radix function_radix(.reset(reset),
          .ProgramAddrMapFile(ProgramAddrMapFile),
          .ProgramLabelMapFile(ProgramLabelMapFile));
  end

  // initialize the branch predictor
  initial begin
    $readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.Predictor.DirPredictor.PHT.memory);
    $readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.TargetPredictor.memory.memory);    
  end
  
endmodule

/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */

