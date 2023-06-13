///////////////////////////////////////////
// testbench.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wally Testbench and helper modules
//          Applies test programs from the riscv-arch-test and Imperas suites
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"
`include "config.vh"
`include "tests.vh"

`define PrintHPMCounters 0
`define BPRED_LOGGER 0
`define I_CACHE_ADDR_LOGGER 0
`define D_CACHE_ADDR_LOGGER 0

import cvw::*;

module testbench;
  parameter DEBUG=0;
  parameter TEST="none";
 
`include "parameter-defs.vh"

  logic        clk;
  logic        reset_ext, reset;
  logic        ResetMem;

  parameter SIGNATURESIZE = 5000000;

  int test, i, errors, totalerrors;
  logic [31:0] sig32[0:SIGNATURESIZE];
  logic [P.XLEN-1:0] signature[0:SIGNATURESIZE];
  logic [P.XLEN-1:0] testadr, testadrNoBase;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;

  string tests[];
  logic [3:0] dummy;

  logic [P.AHBW-1:0]    HRDATAEXT;
  logic                HREADYEXT, HRESPEXT;
  logic [P.PA_BITS-1:0] HADDR;
  logic [P.AHBW-1:0]    HWDATA;
  logic [P.XLEN/8-1:0]  HWSTRB;
  logic                HWRITE;
  logic [2:0]          HSIZE;
  logic [2:0]          HBURST;
  logic [3:0]          HPROT;
  logic [1:0]          HTRANS;
  logic                HMASTLOCK;
  logic                HCLK, HRESETn;
  logic [P.XLEN-1:0]    PCW;

  string  ProgramAddrMapFile, ProgramLabelMapFile;
  integer ProgramAddrLabelArray [string] = '{ "begin_signature" : 0, "tohost" : 0 };

  logic DCacheFlushDone, DCacheFlushStart;
  logic riscofTest; 
  logic StartSample, EndSample;
    
  flopenr #(P.XLEN) PCWReg(clk, reset, ~dut.core.ieu.dp.StallW, dut.core.ifu.PCM, PCW);
  flopenr #(32)    InstrWReg(clk, reset, ~dut.core.ieu.dp.StallW,  dut.core.ifu.InstrM, InstrW);

  // check assertions for a legal configuration
  riscvassertions riscvassertions();

  // pick tests based on modes supported
  initial begin
    $display("TEST is %s", TEST);
    //tests = '{};
    if (P.XLEN == 64) begin // RV64
      case (TEST)
        "arch64i":                               tests = arch64i;
        "arch64priv":                            tests = arch64priv;
        "arch64c":      if (P.C_SUPPORTED) 
                          if (P.ZICSR_SUPPORTED)  tests = {arch64c, arch64cpriv};
                          else                   tests = {arch64c};
        "arch64m":      if (P.M_SUPPORTED)        tests = arch64m;
        "arch64f":      if (P.F_SUPPORTED)        tests = arch64f;
        "arch64d":      if (P.D_SUPPORTED)        tests = arch64d;  
        "arch64f_fma":      if (P.F_SUPPORTED)        tests = arch64f_fma;
        "arch64d_fma":      if (P.D_SUPPORTED)        tests = arch64d_fma;  
        "arch64zi":     if (P.ZIFENCEI_SUPPORTED) tests = arch64zi;
        "imperas64i":                            tests = imperas64i;
        "imperas64f":   if (P.F_SUPPORTED)        tests = imperas64f;
        "imperas64d":   if (P.D_SUPPORTED)        tests = imperas64d;
        "imperas64m":   if (P.M_SUPPORTED)        tests = imperas64m;
        "wally64a":     if (P.A_SUPPORTED)        tests = wally64a;
        "imperas64c":   if (P.C_SUPPORTED)        tests = imperas64c;
                        else                     tests = imperas64iNOc;
        "custom":                                tests = custom;
        "wally64i":                              tests = wally64i; 
        "wally64priv":                           tests = wally64priv;
        "wally64periph":                         tests = wally64periph;
        "coremark":                              tests = coremark;
        "fpga":                                  tests = fpga;
        "ahb" :                                  tests = ahb;
        "coverage64gc" :                         tests = coverage64gc;
        "arch64zba":     if (P.ZBA_SUPPORTED)     tests = arch64zba;
        "arch64zbb":     if (P.ZBB_SUPPORTED)     tests = arch64zbb;
        "arch64zbc":     if (P.ZBC_SUPPORTED)     tests = arch64zbc;
        "arch64zbs":     if (P.ZBS_SUPPORTED)     tests = arch64zbs;
      endcase 
    end else begin // RV32
      case (TEST)
        "arch32i":                               tests = arch32i;
        "arch32priv":                            tests = arch32priv;
        "arch32c":      if (P.C_SUPPORTED) 
                          if (P.ZICSR_SUPPORTED)  tests = {arch32c, arch32cpriv};
                          else                   tests = {arch32c};
        "arch32m":      if (P.M_SUPPORTED)        tests = arch32m;
        "arch32f":      if (P.F_SUPPORTED)        tests = arch32f;
        "arch32d":      if (P.D_SUPPORTED)        tests = arch32d;
        "arch32f_fma":      if (P.F_SUPPORTED)        tests = arch32f_fma;
        "arch32d_fma":      if (P.D_SUPPORTED)        tests = arch32d_fma;
        "arch32zi":     if (P.ZIFENCEI_SUPPORTED) tests = arch32zi;
        "imperas32i":                            tests = imperas32i;
        "imperas32f":   if (P.F_SUPPORTED)        tests = imperas32f;
        "imperas32m":   if (P.M_SUPPORTED)        tests = imperas32m;
        "wally32a":     if (P.A_SUPPORTED)        tests = wally32a;
        "imperas32c":   if (P.C_SUPPORTED)        tests = imperas32c;
                        else                     tests = imperas32iNOc;
        "wally32i":                              tests = wally32i; 
        "wally32e":                              tests = wally32e; 
        "wally32priv":                           tests = wally32priv;
        "wally32periph":                         tests = wally32periph;
        "embench":                               tests = embench;
        "coremark":                              tests = coremark;
        "arch32zba":     if (P.ZBA_SUPPORTED)     tests = arch32zba;
        "arch32zbb":     if (P.ZBB_SUPPORTED)     tests = arch32zbb;
        "arch32zbc":     if (P.ZBC_SUPPORTED)     tests = arch32zbc;
        "arch32zbs":     if (P.ZBS_SUPPORTED)     tests = arch32zbs;
      endcase
    end
    if (tests.size() == 0) begin
      $display("TEST %s not supported in this configuration", TEST);
      $stop;
    end
  end // initial begin

  // Model the testbench as an fsm.
  // Do this in parts so it easier to verify
  // part 1: build a version which echos the same behavior as the below code, but does not drive anything
  // part 2: drive some of the controls
  // part 3: drive all logic and remove old inital and always @ negedge clk block

  typedef enum logic [3:0]{STATE_TESTBENCH_RESET,
                           STATE_INIT_TEST,
                           STATE_RESET_MEMORIES,
                           STATE_LOAD_MEMORIES,
                           STATE_RESET_TEST,
                           STATE_RUN_TEST,
                           STATE_CHECK_TEST,
                           STATE_CHECK_TEST_WAIT,
                           STATE_VALIDATE} statetype;
  statetype CurrState, NextState;
  logic        TestBenchReset;
  logic [2:0]  ResetCount, ResetThreshold;
  logic        LoadMem;
  logic        ResetCntEn;
  logic        ResetCntRst;
  

  string  signame, memfilename, pathname;
  integer begin_signature_addr;

  assign ResetThreshold = 3'd5;

  initial begin
    TestBenchReset = 1;
    # 100;
    TestBenchReset = 0;
  end

  always_ff @(negedge clk)
    if (TestBenchReset) CurrState <= #1 STATE_TESTBENCH_RESET;
    else CurrState <= #1 NextState;  


  always_comb begin
    reset_ext = 0;
    ResetMem = 0;
    LoadMem = 0;
    ResetCntEn = 0;
    ResetCntRst = 0;
    // riscof tests have a different signature, tests[0] == "1" refers to RiscvArchTests 
    // and tests[0] == "2" refers to WallyRiscvArchTests 
    riscofTest = tests[0] == "1" | tests[0] == "2"; 
    pathname = tvpaths[tests[0].atoi()];

    case(CurrState)
      STATE_TESTBENCH_RESET: begin
        NextState = STATE_INIT_TEST;
        test = 1;
        reset_ext = 1;
      end
      STATE_INIT_TEST: begin
        NextState = STATE_RESET_MEMORIES;
        ResetCntRst = 1;
        // 4 major steps: select test, reset wally, reset memories, and load memories

        // 1: test selection
        // fill memory with defined values to reduce Xs in simulation
        // Quick note the memory will need to be initialized.  The C library does not
        // guarantee the  initialized reads.  For example a strcmp can read 6 byte
        // strings, but uses a load double to read them in.  If the last 2 bytes are
        // not initialized the compare results in an 'x' which propagates through 
        // the design.

        // read test vectors into memory
        /* if (tests[0] == `IMPERASTEST)
         pathname = tvpaths[0];
         else pathname = tvpaths[1]; */
        if (riscofTest) memfilename = {pathname, tests[test], "/ref/ref.elf.memfile"};
        else            memfilename = {pathname, tests[test], ".elf.memfile"};
        if (riscofTest) begin
          ProgramAddrMapFile = {pathname, tests[test], "/ref/ref.elf.objdump.addr"};
          ProgramLabelMapFile = {pathname, tests[test], "/ref/ref.elf.objdump.lab"};
        end else begin
          ProgramAddrMapFile = {pathname, tests[test], ".elf.objdump.addr"};
          ProgramLabelMapFile = {pathname, tests[test], ".elf.objdump.lab"};
        end

        // declare memory labels that interest us, the updateProgramAddrLabelArray task will find 
        // the addr of each label and fill the array. To expand, add more elements to this array 
        // and initialize them to zero (also initilaize them to zero at the start of the next test)
        if(!P.FPGA) begin
          updateProgramAddrLabelArray(ProgramAddrMapFile, ProgramLabelMapFile, ProgramAddrLabelArray);
        end
        
        // 2: reset wally
        reset_ext = 1;
        
      end
      STATE_RESET_MEMORIES: begin
        NextState = STATE_LOAD_MEMORIES;
        reset_ext = 1;
        // this initialization is very expensive, only do it for coremark.
        if (TEST == "coremark") ResetMem = 1;
      end
      STATE_LOAD_MEMORIES: begin
        NextState = STATE_RESET_TEST;
        reset_ext = 1;
        LoadMem = 1;
      end
      STATE_RESET_TEST: begin
        reset_ext = 1;
        ResetCntEn = 1;
        if(ResetCount < ResetThreshold) begin
          NextState = STATE_RESET_TEST;
        end else begin
          NextState = STATE_RUN_TEST;
        end
      end
      STATE_RUN_TEST:
        if(DCacheFlushStart) begin 
          NextState = STATE_CHECK_TEST;
        end else begin 
          NextState = STATE_RUN_TEST;
        end
      STATE_CHECK_TEST: begin
        if (DCacheFlushDone) begin
          NextState = STATE_VALIDATE;
        end else begin
          NextState = STATE_CHECK_TEST_WAIT;
        end
      end
      STATE_CHECK_TEST_WAIT: begin
        if(DCacheFlushDone) begin
          NextState = STATE_VALIDATE;
        end else begin
          NextState = STATE_CHECK_TEST_WAIT;
        end
      end
      STATE_VALIDATE: begin
        NextState = STATE_INIT_TEST;
        if (TEST == "coremark")
          if (dut.core.priv.priv.EcallFaultM) begin
            $display("Benchmark: coremark is done.");
            $stop;
          end
        if (!begin_signature_addr)
          $display("begin_signature addr not found in %s", ProgramLabelMapFile);
        else begin
          CheckSignature(pathname, tests[test], riscofTest, begin_signature_addr, errors);
        end
        if(errors > 0) totalerrors = totalerrors + 1;
        test = test + 1;
        if (test == tests.size()) begin
          if (totalerrors == 0) $display("SUCCESS! All tests ran without failures.");
          else $display("FAIL: %d test programs had errors", totalerrors);
          $stop;
        end
      end
      default: NextState = STATE_TESTBENCH_RESET;
    endcase
  end // always_comb

  counter #(3) RstCounter(clk, ResetCntRst, ResetCntEn, ResetCount);
  assign begin_signature_addr = ProgramAddrLabelArray["begin_signature"];

  ////////////////////////////////////////////////////////////////////////////////
  // Some memories are not reset, but should be zeros or set to some initial value for simulation
  ////////////////////////////////////////////////////////////////////////////////

  integer adrindex;
  if (P.UNCORE_RAM_SUPPORTED)
    always @(posedge clk)
      if (ResetMem) 
        for (adrindex=0; adrindex<(P.UNCORE_RAM_RANGE>>1+(P.XLEN/32)); adrindex = adrindex+1) 
          dut.uncore.uncore.ram.ram.memory.RAM[adrindex] = '0;

  // *** add resets for each memory

  if (P.BPRED_SUPPORTED) begin
    // local history only
    if (P.BPRED_TYPE == BP_LOCAL_AHEAD | P.BPRED_TYPE == BP_LOCAL_REPAIR) begin
      always @(posedge clk) begin
        if (ResetMem) begin
          for(adrindex = 0; adrindex < 2**P.BPRED_NUM_LHR; adrindex++) begin
            dut.core.ifu.bpred.bpred.Predictor.DirPredictor.BHT.mem[adrindex] = 0;
          end
        end
      end
    end

    always @(posedge clk) begin
      if(ResetMem) begin
        for(adrindex = 0; adrindex < 2**P.BTB_SIZE; adrindex++) begin
          dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem[adrindex] = 0;
        end
        for(adrindex = 0; adrindex < 2**P.BPRED_SIZE; adrindex++) begin
          dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem[adrindex] = 0;
        end
      end
    end
  end

  ////////////////////////////////////////////////////////////////////////////////
  // load memories with program image
  ////////////////////////////////////////////////////////////////////////////////
  always @(posedge clk) begin
    if (LoadMem) begin
      if (P.FPGA) begin
        string romfilename, sdcfilename;
        romfilename = {"../tests/custom/fpga-test-sdc/bin/fpga-test-sdc.memfile"};
        sdcfilename = {"../testbench/sdc/ramdisk2.hex"};   
        $readmemh(romfilename, dut.uncore.uncore.bootrom.bootrom.memory.ROM);
        $readmemh(sdcfilename, sdcard.sdcard.FLASHmem);
        // shorten sdc timers for simulation
        dut.uncore.uncore.sdc.SDC.LimitTimers = 1;
      end 
      else if (P.IROM_SUPPORTED)     $readmemh(memfilename, dut.core.ifu.irom.irom.rom.ROM);
      else if (P.BUS_SUPPORTED) $readmemh(memfilename, dut.uncore.uncore.ram.ram.memory.RAM);
      if (P.DTIM_SUPPORTED)     $readmemh(memfilename, dut.core.lsu.dtim.dtim.ram.RAM);
      $display("Read memfile %s", memfilename);
    end
  end
  
  

  logic [31:0] GPIOIN, GPIOOUT, GPIOEN;
  logic        UARTSin, UARTSout;

  logic        SDCCLK;
  logic        SDCCmdIn;
  logic        SDCCmdOut;
  logic        SDCCmdOE;
  logic [3:0]  SDCDatIn;
  tri1  [3:0]  SDCDat;
  tri1         SDCCmd;

  logic        HREADY;
  logic        HSELEXT;
  
  logic        InReset;
  logic        BeginSample;
  
  // instantiate device to be tested
  assign GPIOIN = 0;
  assign UARTSin = 1;

  if(P.EXT_MEM_SUPPORTED) begin
    ram_ahb #(.BASE(P.EXT_MEM_BASE), .RANGE(P.EXT_MEM_RANGE)) 
    ram (.HCLK, .HRESETn, .HADDR, .HWRITE, .HTRANS, .HWDATA, .HSELRam(HSELEXT), 
         .HREADRam(HRDATAEXT), .HREADYRam(HREADYEXT), .HRESPRam(HRESPEXT), .HREADY,
         .HWSTRB);
  end else begin 
    assign HREADYEXT = 1;
    assign HRESPEXT = 0;
    assign HRDATAEXT = 0;
  end

  if(P.FPGA) begin : sdcard
    sdModel sdcard
      (.sdClk(SDCCLK),
       .cmd(SDCCmd), 
       .dat(SDCDat));

    assign SDCCmd = SDCCmdOE ? SDCCmdOut : 1'bz;
    assign SDCCmdIn = SDCCmd;
    assign SDCDatIn = SDCDat;
  end else begin
    assign SDCCmd = '0;
    assign SDCDat = '0;
  end

  wallypipelinedsoc  #(P) dut(.clk, .reset_ext, .reset, .HRDATAEXT,.HREADYEXT, .HRESPEXT,.HSELEXT,
                        .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
                        .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), .GPIOIN, .GPIOOUT, .GPIOEN,
                        .UARTSin, .UARTSout, .SDCCmdIn, .SDCCmdOut, .SDCCmdOE, .SDCDatIn, .SDCCLK); 

  // Track names of instructions
  instrTrackerTB it(clk, reset, dut.core.ieu.dp.FlushE,
                dut.core.ifu.InstrRawF[31:0],
                dut.core.ifu.InstrD, dut.core.ifu.InstrE,
                dut.core.ifu.InstrM,  InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);


  // generate clock to sequence tests
  always
    begin
      clk = 1; # 5; clk = 0; # 5;
      // if ($time % 100000 == 0) $display("Time is %0t", $time);
    end
   
  // check results

  // *** Probably need to take some of this code about embench and transfer to new fsm.
/* -----\/----- EXCLUDED -----\/-----
  always @(negedge clk)
    begin    
      if(InReset == 1) begin
      end else begin
        // Termination condition (i.e. we finished running current test) 
        if (DCacheFlushDone) begin
          InReset = 1;
          //begin_signature_addr = ProgramAddrLabelArray["begin_signature"];
          if (!begin_signature_addr)
            $display("begin_signature addr not found in %s", ProgramLabelMapFile);
          testadr = ($unsigned(begin_signature_addr))/(P.XLEN/8);
          testadrNoBase = (begin_signature_addr - P.UNCORE_RAM_BASE)/(P.XLEN/8);
          #600; // give time for instructions in pipeline to finish
          if (TEST == "embench") begin
            // Writes contents of begin_signature to .sim.output file
            // this contains instret and cycles for start and end of test run, used by embench 
            // python speed script to calculate embench speed score. 
            // also, begin_signature contains the results of the self checking mechanism, 
            // which will be read by the python script for error checking
            $display("Embench Benchmark: %s is done.", tests[test]);
            if (riscofTest) outputfile = {pathname, tests[test], "/ref/ref.sim.output"};
            else outputfile = {pathname, tests[test], ".sim.output"};
            outputFilePointer = $fopen(outputfile, "w");
            i = 0;
            $fclose(outputFilePointer);
            $display("Embench Benchmark: created output file: %s", outputfile);
          end else if (TEST == "coverage64gc") begin
            $display("Coverage tests don't get checked");
          end else begin 
            // for tests with no self checking mechanism, read .signature.output file and compare to check for errors
            // clear signature to prevent contamination from previous tests
          end
        end // if (DCacheFlushDone)
      end
    end // always @ (negedge clk)
 -----/\----- EXCLUDED -----/\----- */


  if(`PrintHPMCounters & P.ZICOUNTERS_SUPPORTED) begin : HPMCSample
    integer           HPMCindex;
    logic             StartSampleFirst;
    logic             StartSampleDelayed, BeginDelayed;
    logic             EndSampleFirst, EndSampleDelayed;
    logic [P.XLEN-1:0] InitialHPMCOUNTERH[P.COUNTERS-1:0];

    string  HPMCnames[] = '{"Mcycle",
                            "------",
                            "InstRet",
                            "Br Count",
                            "Jump Not Return",
                            "Return",
                            "BP Wrong",
                            "BP Dir Wrong",
                            "BP Target Wrong",
                            "RAS Wrong",
                            "Instr Class Wrong",
                            "Load Stall",
                            "Store Stall",
                            "D Cache Access",
                            "D Cache Miss",
                            "D Cache Cycles",
                            "I Cache Access",
                            "I Cache Miss",
                            "I Cache Cycles",
                            "CSR Write",
                            "FenceI",
                            "SFenceVMA",
                            "Interrupt",
                            "Exception",
                            "Divide Cycles"
                          };

    if(TEST == "embench") begin
      // embench runs warmup then runs start_trigger
      // embench end with stop_trigger.
      assign StartSampleFirst = FunctionName.FunctionName.FunctionName == "start_trigger";
      flopr #(1) StartSampleReg(clk, reset, StartSampleFirst, StartSampleDelayed);
      assign StartSample = StartSampleFirst & ~ StartSampleDelayed;

      assign EndSampleFirst = FunctionName.FunctionName.FunctionName == "stop_trigger";
      flopr #(1) EndSampleReg(clk, reset, EndSampleFirst, EndSampleDelayed);
      assign EndSample = EndSampleFirst & ~ EndSampleDelayed;

    end else if(TEST == "coremark") begin
      // embench runs warmup then runs start_trigger
	    // embench end with stop_trigger.
      assign StartSampleFirst = FunctionName.FunctionName.FunctionName == "start_time";
      flopr #(1) StartSampleReg(clk, reset, StartSampleFirst, StartSampleDelayed);
      assign StartSample = StartSampleFirst & ~ StartSampleDelayed;

      assign EndSampleFirst = FunctionName.FunctionName.FunctionName == "stop_time";
      flopr #(1) EndSampleReg(clk, reset, EndSampleFirst, EndSampleDelayed);
      assign EndSample = EndSampleFirst & ~ EndSampleDelayed;

    end else begin
      // default start condiction is reset
      // default end condiction is end of test (DCacheFlushDone)
      assign StartSampleFirst = reset;
      flopr #(1) StartSampleReg(clk, reset, StartSampleFirst, StartSampleDelayed);
      assign StartSample = StartSampleFirst & ~ StartSampleDelayed;
      assign EndSample = DCacheFlushStart & ~DCacheFlushDone;

      flop #(1) BeginReg(clk, StartSampleFirst, BeginDelayed);
      assign BeginSample = StartSampleFirst & ~BeginDelayed;

    end
    always @(negedge clk) begin
      if(StartSample) begin
        for(HPMCindex = 0; HPMCindex < 32; HPMCindex += 1) begin
          InitialHPMCOUNTERH[HPMCindex] <= dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[HPMCindex];
        end
      end
      if(EndSample) begin
        for(HPMCindex = 0; HPMCindex < HPMCnames.size(); HPMCindex += 1) begin
          // unlikely to have more than 10M in any counter.
          $display("Cnt[%2d] = %7d %s", HPMCindex, dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[HPMCindex] - InitialHPMCOUNTERH[HPMCindex], HPMCnames[HPMCindex]);
        end
      end
    end
  end
  


  // track the current function or global label
  if (DEBUG == 1 | (`PrintHPMCounters & P.ZICOUNTERS_SUPPORTED)) begin : FunctionName
    FunctionName FunctionName(.reset(reset_ext | TestBenchReset),
			      .clk(clk),
			      .ProgramAddrMapFile(ProgramAddrMapFile),
			      .ProgramLabelMapFile(ProgramLabelMapFile));
  end

  // Termination condition
  // terminate on a specific ECALL after li x3,1 for old Imperas tests,  *** remove this when old imperas tests are removed
  // or sw	gp,-56(t0) for new Imperas tests
  // or sd gp, -56(t0) 
  // or on a jump to self infinite loop (6f) for RISC-V Arch tests
  logic ecf; // remove this once we don't rely on old Imperas tests with Ecalls
  if (P.ZICSR_SUPPORTED) assign ecf = dut.core.priv.priv.EcallFaultM;
  else                  assign ecf = 0;
  assign DCacheFlushStart = ecf & 
			    (dut.core.ieu.dp.regf.rf[3] == 1 | 
			     (dut.core.ieu.dp.regf.we3 & 
			      dut.core.ieu.dp.regf.a3 == 3 & 
			      dut.core.ieu.dp.regf.wd3 == 1)) |
           ((dut.core.ifu.InstrM == 32'h6f | dut.core.ifu.InstrM == 32'hfc32a423 | dut.core.ifu.InstrM == 32'hfc32a823) & dut.core.ieu.c.InstrValidM ) |
           ((dut.core.lsu.IEUAdrM == ProgramAddrLabelArray["tohost"]) & InstrMName == "SW" ); 

  DCacheFlushFSM #(P) DCacheFlushFSM(.clk(clk),
    			.reset(reset),
	    		.start(DCacheFlushStart),
		    	.done(DCacheFlushDone));


  // initialize the branch predictor
  if (P.BPRED_SUPPORTED) begin
    integer adrindex;

    // local history only
    if (P.BPRED_TYPE == BP_LOCAL_AHEAD | P.BPRED_TYPE == BP_LOCAL_REPAIR) begin
      always @(*) begin
        if(reset) begin
          for(adrindex = 0; adrindex < 2**P.BPRED_NUM_LHR; adrindex++) begin
            dut.core.ifu.bpred.bpred.Predictor.DirPredictor.BHT.mem[adrindex] = 0;
          end
        end
      end
    end

    always @(*) begin
      if(reset) begin
        for(adrindex = 0; adrindex < 2**P.BTB_SIZE; adrindex++) begin
          dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem[adrindex] = 0;
        end
        for(adrindex = 0; adrindex < 2**P.BPRED_SIZE; adrindex++) begin
          dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem[adrindex] = 0;
        end
      end
    end
  end


  if (P.ICACHE_SUPPORTED && `I_CACHE_ADDR_LOGGER) begin : ICacheLogger
    int    file;
    string LogFile;
    logic  resetD, resetEdge;
    logic  Enable;
    logic  InvalDelayed, InvalEdge;
    
    assign Enable = dut.core.ifu.bus.icache.icache.cachefsm.LRUWriteEn & 
                    dut.core.ifu.immu.immu.pmachecker.Cacheable &
                    ~dut.core.ifu.bus.icache.icache.cachefsm.FlushStage &
                    ~reset;
    flop #(1) ResetDReg(clk, reset, resetD);
    assign resetEdge = ~reset & resetD;

    flop #(1) InvalReg(clk, dut.core.ifu.InvalidateICacheM, InvalDelayed);
    assign InvalEdge = dut.core.ifu.InvalidateICacheM & ~InvalDelayed;

    initial begin
      LogFile = "ICache.log";
      file = $fopen(LogFile, "w");
      $fwrite(file, "BEGIN %s\n", memfilename);
    end
    string AccessTypeString, HitMissString;
    assign HitMissString = dut.core.ifu.bus.icache.icache.CacheHit ? "H" :
                           dut.core.ifu.bus.icache.icache.vict.cacheLRU.AllValid ? "E" : "M";
    always @(posedge clk) begin
    if(resetEdge) $fwrite(file, "TRAIN\n");
    if(BeginSample) $fwrite(file, "BEGIN %s\n", memfilename);
    if(Enable) begin  // only log i cache reads
      $fwrite(file, "%h R %s\n", dut.core.ifu.PCPF, HitMissString);
    end
    if(InvalEdge) $fwrite(file, "0 I X\n");
    if(EndSample) $fwrite(file, "END %s\n", memfilename);
    end
  end


  if (P.DCACHE_SUPPORTED && `D_CACHE_ADDR_LOGGER) begin : DCacheLogger
    int    file;
    string LogFile;
    logic  resetD, resetEdge;
    logic  Enabled;
    string AccessTypeString, HitMissString;

    flop #(1) ResetDReg(clk, reset, resetD);
    assign resetEdge = ~reset & resetD;
    assign HitMissString = dut.core.lsu.bus.dcache.dcache.CacheHit ? "H" :
                           (!dut.core.lsu.bus.dcache.dcache.vict.cacheLRU.AllValid) ? "M" :
                           dut.core.lsu.bus.dcache.dcache.LineDirty ? "D" : "E";
    assign AccessTypeString = dut.core.lsu.bus.dcache.FlushDCache ? "F" :
                              dut.core.lsu.bus.dcache.CacheAtomicM[1] ? "A" :
                              dut.core.lsu.bus.dcache.CacheRWM == 2'b10 ? "R" : 
                              dut.core.lsu.bus.dcache.CacheRWM == 2'b01 ? "W" :
                              "NULL";
    
    assign Enabled = dut.core.lsu.bus.dcache.dcache.cachefsm.LRUWriteEn &
                     ~dut.core.lsu.bus.dcache.dcache.cachefsm.FlushStage &
                     dut.core.lsu.dmmu.dmmu.pmachecker.Cacheable &
                     (AccessTypeString != "NULL");

    initial begin
      LogFile = "DCache.log";
      file = $fopen(LogFile, "w");
      $fwrite(file, "BEGIN %s\n", memfilename);
    end
    always @(posedge clk) begin
      if(resetEdge) $fwrite(file, "TRAIN\n");
      if(BeginSample) $fwrite(file, "BEGIN %s\n", memfilename);
      if(Enabled) begin
        $fwrite(file, "%h %s %s\n", dut.core.lsu.PAdrM, AccessTypeString, HitMissString);
      end
      if(dut.core.lsu.bus.dcache.dcache.cachefsm.FlushFlag) $fwrite(file, "0 F X\n");
      if(EndSample) $fwrite(file, "END %s\n", memfilename);
    end
  end

  if (P.BPRED_SUPPORTED) begin : BranchLogger
    if (`BPRED_LOGGER) begin
      string direction;
      int    file;
      logic  PCSrcM;
      string LogFile;
      logic  resetD, resetEdge;
      flopenrc #(1) PCSrcMReg(clk, reset, dut.core.FlushM, ~dut.core.StallM, dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PCSrcE, PCSrcM);
      flop #(1) ResetDReg(clk, reset, resetD);
      assign resetEdge = ~reset & resetD;
      initial begin
        LogFile = "branch.log"; // will break some of Ross's research analysis scripts
        //LogFile = $psprintf("branch_%s%0d.log", P.BPRED_TYPE, P.BPRED_SIZE);
        file = $fopen(LogFile, "w");
      end
      always @(posedge clk) begin
        if(resetEdge) $fwrite(file, "TRAIN\n");
        if(StartSample) $fwrite(file, "BEGIN %s\n", memfilename);
        if(dut.core.ifu.InstrClassM[0] & ~dut.core.StallW & ~dut.core.FlushW & dut.core.InstrValidM) begin
          direction = PCSrcM ? "t" : "n";
          $fwrite(file, "%h %s\n", dut.core.PCM, direction);
        end
        if(EndSample) $fwrite(file, "END %s\n", memfilename);
      end
    end
  end

  // check for hang up.
  logic [P.XLEN-1:0] OldPCW;
  integer           WatchDogTimerCount;
  localparam        WatchDogTimerThreshold = 1000000;
  logic             WatchDogTimeOut;
  always_ff @(posedge clk) begin
    OldPCW <= PCW;
    if(OldPCW == PCW) WatchDogTimerCount = WatchDogTimerCount + 1'b1;
    else WatchDogTimerCount = '0;
  end

  always_comb begin
    WatchDogTimeOut = WatchDogTimerCount >= WatchDogTimerThreshold;
    if(WatchDogTimeOut) begin
      $display("FAILURE: Watch Dog Time Out triggered. PCW stuck at %x for more than %d cycles", PCW, WatchDogTimerCount);
      $stop;
	  end
  end
  
endmodule

/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */

module DCacheFlushFSM import cvw::*; #(parameter cvw_t P) 
  (input logic clk,
   input logic reset,
   input logic start,
   output logic done);

  genvar adr;

  logic [P.XLEN-1:0] ShadowRAM[P.UNCORE_RAM_BASE>>(1+P.XLEN/32):(P.UNCORE_RAM_RANGE+P.UNCORE_RAM_BASE)>>1+(P.XLEN/32)];
  logic         startD;
  
  if(P.DCACHE_SUPPORTED) begin
    localparam numlines       = testbench.dut.core.lsu.bus.dcache.dcache.NUMLINES;
    localparam numways        = testbench.dut.core.lsu.bus.dcache.dcache.NUMWAYS;
    localparam linebytelen    = testbench.dut.core.lsu.bus.dcache.dcache.LINEBYTELEN;
    localparam linelen        = testbench.dut.core.lsu.bus.dcache.dcache.LINELEN;
    localparam sramlen        = testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[0].SRAMLEN;            
    localparam cachesramwords = testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[0].NUMSRAM;
    localparam numwords       = sramlen/P.XLEN;
    localparam lognumlines    = $clog2(numlines);
    localparam loglinebytelen = $clog2(linebytelen);
    localparam lognumways     = $clog2(numways);
    localparam tagstart       = lognumlines + loglinebytelen;


    
    genvar               index, way, cacheWord;
    logic [sramlen-1:0]  CacheData  [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
    logic [sramlen-1:0]  cacheline;
    logic [P.XLEN-1:0]    CacheTag   [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
    logic                CacheValid [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
    logic                CacheDirty [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
    logic [P.PA_BITS-1:0] CacheAdr   [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
    for(index = 0; index < numlines; index++) begin
      for(way = 0; way < numways; way++) begin
        for(cacheWord = 0; cacheWord < cachesramwords; cacheWord++) begin
          copyShadow #(.P(P), .tagstart(tagstart),
          .loglinebytelen(loglinebytelen), .sramlen(sramlen))
          copyShadow(.clk,
          .start,
          .tag(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].CacheTagMem.RAM[index][P.PA_BITS-1-tagstart:0]),
          .valid(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].ValidBits[index]),
          .dirty(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].DirtyBits[index]),
                           // these dirty bit selections would be needed if dirty is moved inside the tag array.
          //.dirty(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].dirty.DirtyMem.RAM[index]),
          //.dirty(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].CacheTagMem.RAM[index][P.PA_BITS+tagstart]),
          .data(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].word[cacheWord].wordram.CacheDataMem.RAM[index]),
          .index(index),
          .cacheWord(cacheWord),
          .CacheData(CacheData[way][index][cacheWord]),
          .CacheAdr(CacheAdr[way][index][cacheWord]),
          .CacheTag(CacheTag[way][index][cacheWord]),
          .CacheValid(CacheValid[way][index][cacheWord]),
          .CacheDirty(CacheDirty[way][index][cacheWord]));
        end
      end
    end

    integer i, j, k, l;

    always @(posedge clk) begin
      if (startD) begin 
        for(i = 0; i < numlines; i++) begin
          for(j = 0; j < numways; j++) begin
            for(l = 0; l < cachesramwords; l++) begin
              if (CacheValid[j][i][l] & CacheDirty[j][i][l]) begin
                for(k = 0; k < numwords; k++) begin
                  //cacheline = CacheData[j][i][0];
                  // does not work with modelsim
                  // # ** Error: ../testbench/testbench.sv(483): Range must be bounded by constant expressions.
                  // see https://verificationacademy.com/forums/systemverilog/range-must-be-bounded-constant-expressions
                  //ShadowRAM[CacheAdr[j][i][k] >> $clog2(P.XLEN/8)] = cacheline[P.XLEN*(k+1)-1:P.XLEN*k];
                  ShadowRAM[(CacheAdr[j][i][l] >> $clog2(P.XLEN/8)) + k] = CacheData[j][i][l][P.XLEN*k +: P.XLEN];
                end
              end
            end
          end
        end
      end
    end  
  end
  flop #(1) doneReg1(.clk, .d(start), .q(startD));
  flop #(1) doneReg2(.clk, .d(startD), .q(done));
endmodule

module copyShadow import cvw::*; #(parameter cvw_t P,
  parameter tagstart, loglinebytelen, sramlen)
  (input  logic                       clk,
   input  logic                       start,
   input  logic [P.PA_BITS-1:tagstart] tag,
   input  logic                       valid, dirty,
   input  logic [sramlen-1:0]         data,
   input  logic [32-1:0]              index,
   input  logic [32-1:0]              cacheWord,
   output logic [sramlen-1:0]         CacheData,
   output logic [P.PA_BITS-1:0]        CacheAdr,
   output logic [P.XLEN-1:0]           CacheTag,
   output logic                       CacheValid,
   output logic                       CacheDirty);
  

  always_ff @(posedge clk) begin
    if(start) begin
      CacheTag = tag;
      CacheValid = valid;
      CacheDirty = dirty;
      CacheData = data;
      CacheAdr = (tag << tagstart) + (index << loglinebytelen) + (cacheWord << $clog2(sramlen/8));
    end
  end
  
endmodule

task automatic updateProgramAddrLabelArray;
  input string ProgramAddrMapFile, ProgramLabelMapFile;
  inout  integer ProgramAddrLabelArray [string];
  // Gets the memory location of begin_signature
  integer ProgramLabelMapFP, ProgramAddrMapFP;
  ProgramLabelMapFP = $fopen(ProgramLabelMapFile, "r");
  ProgramAddrMapFP = $fopen(ProgramAddrMapFile, "r");
  
  if (ProgramLabelMapFP & ProgramAddrMapFP) begin // check we found both files
    while (!$feof(ProgramLabelMapFP)) begin
      string label, adrstr;
      integer returncode;
      returncode = $fscanf(ProgramLabelMapFP, "%s\n", label);
      returncode = $fscanf(ProgramAddrMapFP, "%s\n", adrstr);
      if (ProgramAddrLabelArray.exists(label)) ProgramAddrLabelArray[label] = adrstr.atohex();
    end
  end
  $fclose(ProgramLabelMapFP);
  $fclose(ProgramAddrMapFP);
endtask


task automatic CheckSignature;
  
  input string  pathname;
  input string  TestName;
  input logic   riscofTest;
  input integer begin_signature_addr;
  output integer errors;

  localparam SIGNATURESIZE = 50000;
  integer       i;
  logic [31:0] sig32[0:SIGNATURESIZE];
  logic [`XLEN-1:0] signature[0:SIGNATURESIZE];
  string  signame, pathname;
  logic [`XLEN-1:0] testadr, testadrNoBase;
  
  // for tests with no self checking mechanism, read .signature.output file and compare to check for errors
  // clear signature to prevent contamination from previous tests
  for(i=0; i<SIGNATURESIZE; i=i+1) begin
    sig32[i] = 'bx;
  end
  if (riscofTest) signame = {pathname, TestName, "/ref/Reference-sail_c_simulator.signature"};
  else signame = {pathname, TestName, ".signature.output"};
  // read signature, reformat in 64 bits if necessary
  $readmemh(signame, sig32);
  i = 0;
  while (i < SIGNATURESIZE) begin
    if (`XLEN == 32) begin
      signature[i] = sig32[i];
      i = i+1;
    end else begin
      signature[i/2] = {sig32[i+1], sig32[i]};
      i = i + 2;
    end
    if (i >= 4 & sig32[i-4] === 'bx) begin
      if (i == 4) begin
        i = SIGNATURESIZE+1; // flag empty file
        $display("  Error: empty test file");
      end else i = SIGNATURESIZE; // skip over the rest of the x's for efficiency
    end
  end

  // Check errors
  errors = (i == SIGNATURESIZE+1); // error if file is empty
  i = 0;
  testadr = ($unsigned(begin_signature_addr))/(`XLEN/8);
  testadrNoBase = (begin_signature_addr - `UNCORE_RAM_BASE)/(`XLEN/8);
  /* verilator lint_off INFINITELOOP */
  while (signature[i] !== 'bx) begin
    logic [`XLEN-1:0] sig;
    if (`DTIM_SUPPORTED) sig = testbench.dut.core.lsu.dtim.dtim.ram.RAM[testadrNoBase+i];
    else if (`UNCORE_RAM_SUPPORTED) sig = testbench.dut.uncore.uncore.ram.ram.memory.RAM[testadrNoBase+i];
    //$display("signature[%h] = %h sig = %h", i, signature[i], sig);
    if (signature[i] !== sig & (signature[i] !== testbench.DCacheFlushFSM.ShadowRAM[testadr+i])) begin  
      errors = errors+1;
      $display("  Error on test %s result %d: adr = %h sim (D$) %h sim (DTIM_SUPPORTED) = %h, signature = %h", 
			   TestName, i, (testadr+i)*(`XLEN/8), testbench.DCacheFlushFSM.ShadowRAM[testadr+i], sig, signature[i]);
      $stop; //***debug
    end
    i = i + 1;
  end
  /* verilator lint_on INFINITELOOP */
  if (errors == 0) begin
    $display("%s succeeded.  Brilliant!!!", TestName);
  end else begin
    $display("%s failed with %d errors. :(", TestName, errors);
    //totalerrors = totalerrors+1;
  end

endtask //
