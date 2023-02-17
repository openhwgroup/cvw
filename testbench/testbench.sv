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
`include "tests.vh"

`define PrintHPMCounters 0
`define BPRED_LOGGER 0

module testbench;
  parameter DEBUG=0;
  parameter TEST="none";
 
  logic        clk;
  logic        reset_ext, reset;

  parameter SIGNATURESIZE = 5000000;

  int test, i, errors, totalerrors;
  logic [31:0] sig32[0:SIGNATURESIZE];
  logic [`XLEN-1:0] signature[0:SIGNATURESIZE];
  logic [`XLEN-1:0] testadr, testadrNoBase;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;

string tests[];
logic [3:0] dummy;

  logic [`AHBW-1:0] HRDATAEXT;
  logic             HREADYEXT, HRESPEXT;
  logic [`PA_BITS-1:0] HADDR;
  logic [`AHBW-1:0] HWDATA;
  logic [`XLEN/8-1:0] HWSTRB;
  logic             HWRITE;
  logic [2:0]       HSIZE;
  logic [2:0]       HBURST;
  logic [3:0]       HPROT;
  logic [1:0]       HTRANS;
  logic             HMASTLOCK;
  logic             HCLK, HRESETn;
  logic [`XLEN-1:0] PCW;

  string ProgramAddrMapFile, ProgramLabelMapFile;
  integer   	ProgramAddrLabelArray [string] = '{ "begin_signature" : 0, "tohost" : 0 };

  logic 	    DCacheFlushDone, DCacheFlushStart;
  logic riscofTest; 
    
  flopenr #(`XLEN) PCWReg(clk, reset, ~dut.core.ieu.dp.StallW, dut.core.ifu.PCM, PCW);
  flopenr  #(32)   InstrWReg(clk, reset, ~dut.core.ieu.dp.StallW,  dut.core.ifu.InstrM, InstrW);

  // check assertions for a legal configuration
  riscvassertions riscvassertions();

  // pick tests based on modes supported
  initial begin
    $display("TEST is %s", TEST);
    //tests = '{};
    if (`XLEN == 64) begin // RV64
      case (TEST)
        "arch64i":                        tests = arch64i;
        "arch64priv":                     tests = arch64priv;
        "arch64c":      if (`C_SUPPORTED) 
                          if (`ZICSR_SUPPORTED) tests = {arch64c, arch64cpriv};
                          else                  tests = {arch64c};
        "arch64m":      if (`M_SUPPORTED) tests = arch64m;
        "arch64f":      if (`F_SUPPORTED) tests = arch64f;
        "arch64d":      if (`D_SUPPORTED) tests = arch64d;  
        "arch64zi":     if (`ZIFENCEI_SUPPORTED) tests = arch64zi;
        "imperas64i":                     tests = imperas64i;
        "imperas64f":   if (`F_SUPPORTED) tests = imperas64f;
        "imperas64d":   if (`D_SUPPORTED) tests = imperas64d;
        "imperas64m":   if (`M_SUPPORTED) tests = imperas64m;
        "wally64a":     if (`A_SUPPORTED) tests = wally64a;
        "imperas64c":   if (`C_SUPPORTED) tests = imperas64c;
                        else              tests = imperas64iNOc;
        "custom":                         tests = custom;
        "wally64i":                       tests = wally64i; 
        "wally64priv":                    tests = wally64priv;
        "wally64periph":                  tests = wally64periph;
        "coremark":                       tests = coremark;
        "fpga":                           tests = fpga;
        "ahb" :                           tests = ahb;
      endcase 
    end else begin // RV32
      case (TEST)
        "arch32i":                        tests = arch32i;
        "arch32priv":                     tests = arch32priv;
        "arch32c":      if (`C_SUPPORTED) 
                          if (`ZICSR_SUPPORTED) tests = {arch32c, arch32cpriv};
                          else                  tests = {arch32c};
        "arch32m":      if (`M_SUPPORTED) tests = arch32m;
        "arch32f":      if (`F_SUPPORTED) tests = arch32f;
        "arch32d":      if (`D_SUPPORTED) tests = arch32d;
        "arch32zi":     if (`ZIFENCEI_SUPPORTED) tests = arch32zi;
        "imperas32i":                     tests = imperas32i;
        "imperas32f":   if (`F_SUPPORTED) tests = imperas32f;
        "imperas32m":   if (`M_SUPPORTED) tests = imperas32m;
        "wally32a":     if (`A_SUPPORTED) tests = wally32a;
        "imperas32c":   if (`C_SUPPORTED) tests = imperas32c;
                        else              tests = imperas32iNOc;
        "wally32i":                       tests = wally32i; 
        "wally32e":                       tests = wally32e; 
        "wally32priv":                    tests = wally32priv;
        "wally32periph":                   tests = wally32periph;
        "embench":                        tests = embench;
        "coremark":                       tests = coremark;
        "arch32ba":     if (`ZBA_SUPPORTED) tests = arch32ba;
      endcase
    end
    if (tests.size() == 0) begin
      $display("TEST %s not supported in this configuration", TEST);
      $stop;
    end
  end

  string signame, memfilename, pathname, objdumpfilename, adrstr, outputfile;
  integer outputFilePointer;

  logic [31:0] GPIOPinsIn, GPIOPinsOut, GPIOPinsEn;
  logic        UARTSin, UARTSout;

  logic        SDCCLK;
  logic        SDCCmdIn;
  logic        SDCCmdOut;
  logic        SDCCmdOE;
  logic [3:0]  SDCDatIn;
  tri1 [3:0]   SDCDat;
  tri1         SDCCmd;

  logic        HREADY;
  logic        HSELEXT;
  
  logic             InitializingMemories;
  integer           ResetCount, ResetThreshold;
  logic             InReset;

  // instantiate device to be tested
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;

  if(`EXT_MEM_SUPPORTED) begin
    ram_ahb #(.BASE(`EXT_MEM_BASE), .RANGE(`EXT_MEM_RANGE)) 
    ram (.HCLK, .HRESETn, .HADDR, .HWRITE, .HTRANS, .HWDATA, .HSELRam(HSELEXT), 
         .HREADRam(HRDATAEXT), .HREADYRam(HREADYEXT), .HRESPRam(HRESPEXT), .HREADY,
         .HWSTRB);
  end else begin 
    assign HREADYEXT = 1;
    assign HRESPEXT = 0;
    assign HRDATAEXT = 0;
  end

  if(`FPGA) begin : sdcard
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

  wallypipelinedsoc dut(.clk, .reset_ext, .reset, .HRDATAEXT,.HREADYEXT, .HRESPEXT,.HSELEXT,
                        .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
                        .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn,
                        .UARTSin, .UARTSout, .SDCCmdIn, .SDCCmdOut, .SDCCmdOE, .SDCDatIn, .SDCCLK); 

  // Track names of instructions
  instrTrackerTB it(clk, reset, dut.core.ieu.dp.FlushE,
                dut.core.ifu.InstrRawF[31:0],
                dut.core.ifu.InstrD, dut.core.ifu.InstrE,
                dut.core.ifu.InstrM,  InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // initialize tests
  localparam 	   MemStartAddr = 0;
  localparam 	   MemEndAddr = `UNCORE_RAM_RANGE>>1+(`XLEN/32);

  initial
    begin
      ResetCount = 0;
      ResetThreshold = 2;
      InReset = 1;
      test = 1;
      totalerrors = 0;
      testadr = 0;
      testadrNoBase = 0;
      // riscof tests have a different signature, tests[0] == "1" refers to RiscvArchTests and  tests[0] == "2" refers to WallyRiscvArchTests 
      riscofTest = tests[0] == "1" | tests[0] == "2"; 
      // fill memory with defined values to reduce Xs in simulation
      // Quick note the memory will need to be initialized.  The C library does not
      //  guarantee the  initialized reads.  For example a strcmp can read 6 byte
      //  strings, but uses a load double to read them in.  If the last 2 bytes are
      //  not initialized the compare results in an 'x' which propagates through 
      // the design.
      if (TEST == "coremark") 
        for (i=MemStartAddr; i<MemEndAddr; i = i+1) 
          dut.uncore.uncore.ram.ram.memory.RAM[i] = 64'h0; 

      // read test vectors into memory
      pathname = tvpaths[tests[0].atoi()];
      /* if (tests[0] == `IMPERASTEST)
        pathname = tvpaths[0];
       else pathname = tvpaths[1]; */
      if (riscofTest) memfilename = {pathname, tests[test], "/ref/ref.elf.memfile"};
      else memfilename = {pathname, tests[test], ".elf.memfile"};
      if (`FPGA) begin
        string romfilename, sdcfilename;
        romfilename = {"../tests/custom/fpga-test-sdc/bin/fpga-test-sdc.memfile"};
        sdcfilename = {"../testbench/sdc/ramdisk2.hex"};   
        $readmemh(romfilename, dut.uncore.uncore.bootrom.bootrom.memory.ROM);
        $readmemh(sdcfilename, sdcard.sdcard.FLASHmem);
        // force sdc timers
        force dut.uncore.uncore.sdc.SDC.LimitTimers = 1;
      end else begin
        if (`IROM_SUPPORTED) $readmemh(memfilename, dut.core.ifu.irom.irom.rom.ROM);
        else if (`BUS_SUPPORTED) $readmemh(memfilename, dut.uncore.uncore.ram.ram.memory.RAM);
        if (`DTIM_SUPPORTED) $readmemh(memfilename, dut.core.lsu.dtim.dtim.ram.RAM);
      end

      if (riscofTest) begin
        ProgramAddrMapFile = {pathname, tests[test], "/ref/ref.elf.objdump.addr"};
        ProgramLabelMapFile = {pathname, tests[test], "/ref/ref.elf.objdump.lab"};
      end else begin
        ProgramAddrMapFile = {pathname, tests[test], ".elf.objdump.addr"};
        ProgramLabelMapFile = {pathname, tests[test], ".elf.objdump.lab"};
      end
      // declare memory labels that interest us, the updateProgramAddrLabelArray task will find the addr of each label and fill the array
      // to expand, add more elements to this array and initialize them to zero (also initilaize them to zero at the start of the next test)
      if(!`FPGA) begin
        updateProgramAddrLabelArray(ProgramAddrMapFile, ProgramLabelMapFile, ProgramAddrLabelArray);
        $display("Read memfile %s", memfilename);
      end
    end

  // generate clock to sequence tests
  always
    begin
      clk = 1; # 5; clk = 0; # 5;
      // if ($time % 100000 == 0) $display("Time is %0t", $time);
    end
   
  logic [`XLEN-1:0] debugmemoryadr;
//  assign debugmemoryadr = dut.uncore.uncore.ram.ram.memory.RAM[5140];

  // check results
  assign reset_ext = InReset;
  
  always @(negedge clk)
    begin    
      InitializingMemories = 0;
      if(InReset == 1) begin
        // once the test inidicates it's done we need to immediately hold reset for a number of cycles.
        if(ResetCount < ResetThreshold) ResetCount = ResetCount + 1;
        else begin // hit reset threshold so we remove reset.
          InReset = 0; 
          ResetCount = 0;
        end
      end else begin
      if (TEST == "coremark")
        if (dut.core.priv.priv.EcallFaultM) begin
          $display("Benchmark: coremark is done.");
          $stop;
        end
      // Termination condition (i.e. we finished running current test) 
      if (DCacheFlushDone) begin
        integer begin_signature_addr;
        InReset = 1;
        begin_signature_addr = ProgramAddrLabelArray["begin_signature"];
        if (!begin_signature_addr)
          $display("begin_signature addr not found in %s", ProgramLabelMapFile);
        testadr = ($unsigned(begin_signature_addr))/(`XLEN/8);
        testadrNoBase = (begin_signature_addr - `UNCORE_RAM_BASE)/(`XLEN/8);
        #600; // give time for instructions in pipeline to finish
        if (TEST == "embench") begin
          // Writes contents of begin_signature to .sim.output file
          // this contains instret and cycles for start and end of test run, used by embench python speed script to calculate embench speed score
          // also begin_signature contains the results of the self checking mechanism, which will be read by the python script for error checking
          $display("Embench Benchmark: %s is done.", tests[test]);
          if (riscofTest) outputfile = {pathname, tests[test], "/ref/ref.sim.output"};
          else outputfile = {pathname, tests[test], ".sim.output"};
          outputFilePointer = $fopen(outputfile);
          i = 0;
          while ($unsigned(i) < $unsigned(5'd5)) begin
            $fdisplayh(outputFilePointer, DCacheFlushFSM.ShadowRAM[testadr+i]);
            i = i + 1;
          end
          $fclose(outputFilePointer);
          $display("Embench Benchmark: created output file: %s", outputfile);
        end else begin 
          // for tests with no self checking mechanism, read .signature.output file and compare to check for errors
          // clear signature to prevent contamination from previous tests
          for(i=0; i<SIGNATURESIZE; i=i+1) begin
            sig32[i] = 'bx;
          end
          if (riscofTest) signame = {pathname, tests[test], "/ref/Reference-sail_c_simulator.signature"};
          else signame = {pathname, tests[test], ".signature.output"};
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
          /* verilator lint_off INFINITELOOP */
          while (signature[i] !== 'bx) begin
            logic [`XLEN-1:0] sig;
            if (`DTIM_SUPPORTED) sig = dut.core.lsu.dtim.dtim.ram.RAM[testadrNoBase+i];
            else if (`UNCORE_RAM_SUPPORTED) sig = dut.uncore.uncore.ram.ram.memory.RAM[testadrNoBase+i];
            //$display("signature[%h] = %h sig = %h", i, signature[i], sig);
            if (signature[i] !== sig & (signature[i] !== DCacheFlushFSM.ShadowRAM[testadr+i])) begin  
              errors = errors+1;
              $display("  Error on test %s result %d: adr = %h sim (D$) %h sim (DTIM_SUPPORTED) = %h, signature = %h", 
                    tests[test], i, (testadr+i)*(`XLEN/8), DCacheFlushFSM.ShadowRAM[testadr+i], sig, signature[i]);
              $stop;//***debug
             end
            i = i + 1;
          end
          /* verilator lint_on INFINITELOOP */
          if (errors == 0) begin
            $display("%s succeeded.  Brilliant!!!", tests[test]);
          end
          else begin
            $display("%s failed with %d errors. :(", tests[test], errors);
            totalerrors = totalerrors+1;
          end
        end
        // move onto the next test, check to see if we're done
        test = test + 1;
        if (test == tests.size()) begin
          if (totalerrors == 0) $display("SUCCESS! All tests ran without failures.");
          else $display("FAIL: %d test programs had errors", totalerrors);
          $stop;
        end
        else begin
            InitializingMemories = 1;
            // If there are still additional tests to run, read in information for the next test
            //pathname = tvpaths[tests[0]];
            if (riscofTest) memfilename = {pathname, tests[test], "/ref/ref.elf.memfile"};
            else memfilename = {pathname, tests[test], ".elf.memfile"};
            //$readmemh(memfilename, dut.uncore.uncore.ram.ram.memory.RAM);
            if (`IROM_SUPPORTED)               $readmemh(memfilename, dut.core.ifu.irom.irom.rom.ROM);
            else if (`UNCORE_RAM_SUPPORTED) $readmemh(memfilename, dut.uncore.uncore.ram.ram.memory.RAM);
            if (`DTIM_SUPPORTED)               $readmemh(memfilename, dut.core.lsu.dtim.dtim.ram.RAM);

            if (riscofTest) begin
              ProgramAddrMapFile = {pathname, tests[test], "/ref/ref.elf.objdump.addr"};
              ProgramLabelMapFile = {pathname, tests[test], "/ref/ref.elf.objdump.lab"};
            end else begin
              ProgramAddrMapFile = {pathname, tests[test], ".elf.objdump.addr"};
              ProgramLabelMapFile = {pathname, tests[test], ".elf.objdump.lab"};
            end
            ProgramAddrLabelArray = '{ "begin_signature" : 0, "tohost" : 0 };
          if(!`FPGA) begin
            updateProgramAddrLabelArray(ProgramAddrMapFile, ProgramLabelMapFile, ProgramAddrLabelArray);
            $display("Read memfile %s", memfilename);
          end
        end
      end // if (DCacheFlushDone)
      end
    end // always @ (negedge clk)


  if(`PrintHPMCounters & `ZICOUNTERS_SUPPORTED) begin
    integer HPMCindex;
    string  HPMCnames[] = '{"Mcycle",
                            "------",
                            "InstRet",
                            "Load Stall",
                            "Br Dir Wrong",
                            "Br Count",
                            "Br Target Wrong",
                            "Jump, JR, Jal",
                            "RAS Wrong",
                            "ret",
                            "Instr Class Wrong",
                            "D Cache Access",
                            "D Cache Miss",
                            "I Cache Access",
                            "I Cache Miss",
							"Br Pred Wrong"};
    always @(negedge clk) begin
      if(DCacheFlushStart & ~DCacheFlushDone) begin
        for(HPMCindex = 0; HPMCindex < HPMCnames.size(); HPMCindex += 1) begin
          // unlikely to have more than 10M in any counter.
          $display("Cnt[%2d] = %7d %s", HPMCindex, dut.core.priv.priv.csr.counters.counters.HPMCOUNTER_REGW[HPMCindex], HPMCnames[HPMCindex]);
        end
      end
    end
  end

  // track the current function or global label
  if (DEBUG == 1) begin : FunctionName
    FunctionName FunctionName(.reset(reset),
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
  if (`ZICSR_SUPPORTED) assign ecf = dut.core.priv.priv.EcallFaultM;
  else                  assign ecf = 0;
  assign DCacheFlushStart = ecf & 
			    (dut.core.ieu.dp.regf.rf[3] == 1 | 
			     (dut.core.ieu.dp.regf.we3 & 
			      dut.core.ieu.dp.regf.a3 == 3 & 
			      dut.core.ieu.dp.regf.wd3 == 1)) |
           ((dut.core.ifu.InstrM == 32'h6f | dut.core.ifu.InstrM == 32'hfc32a423 | dut.core.ifu.InstrM == 32'hfc32a823) & dut.core.ieu.c.InstrValidM ) |
           ((dut.core.lsu.IEUAdrM == ProgramAddrLabelArray["tohost"]) & InstrMName == "SW" ); 

  DCacheFlushFSM DCacheFlushFSM(.clk(clk),
    			.reset(reset),
	    		.start(DCacheFlushStart),
		    	.done(DCacheFlushDone));

  // initialize the branch predictor
  if (`BPRED_SUPPORTED == 1)
    begin
      genvar adrindex;
      
      // Initializing all zeroes into the branch predictor memory.
      for(adrindex = 0; adrindex < 2**10; adrindex++) begin
        initial begin 
        force dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem[adrindex] = 0;
        #1;
        release dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem[adrindex];
        end
      end
      for(adrindex = 0; adrindex < 2**`BPRED_SIZE; adrindex++) begin
        initial begin 
        force dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem[adrindex] = 0;
        #1;
        release dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem[adrindex];
        end
      end

      if (`BPRED_LOGGER) begin
        string direction;
        int    file;
		logic  PCSrcM;
		flopenrc #(1) PCSrcMReg(clk, reset, dut.core.FlushM, ~dut.core.StallM, dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PCSrcE, PCSrcM);
        initial
          file = $fopen("branch.log", "w");
        always @(posedge clk) begin
           if(dut.core.ifu.InstrClassM[0] & ~dut.core.StallW & ~dut.core.FlushW & dut.core.InstrValidM) begin
             direction = PCSrcM ? "t" : "n";
             $fwrite(file, "%h %s\n", dut.core.PCM, direction);
           end
        end
      end
    end

  // check for hange up.
  logic [`XLEN-1:0] OldPCW;
  integer 			WatchDogTimerCount;
  localparam WatchDogTimerThreshold = 1000000;
  logic 			WatchDogTimeOut;
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

module DCacheFlushFSM
  (input logic clk,
   input logic reset,
   input logic start,
   output logic done);

  genvar adr;

  logic [`XLEN-1:0] ShadowRAM[`UNCORE_RAM_BASE>>(1+`XLEN/32):(`UNCORE_RAM_RANGE+`UNCORE_RAM_BASE)>>1+(`XLEN/32)];
  
	if(`DCACHE_SUPPORTED) begin
	  localparam numlines = testbench.dut.core.lsu.bus.dcache.dcache.NUMLINES;
	  localparam numways = testbench.dut.core.lsu.bus.dcache.dcache.NUMWAYS;
	  localparam linebytelen = testbench.dut.core.lsu.bus.dcache.dcache.LINEBYTELEN;
	  localparam linelen = testbench.dut.core.lsu.bus.dcache.dcache.LINELEN;
	  localparam sramlen = testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[0].SRAMLEN;            
	  localparam cachesramwords = testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[0].NUMSRAM;
	  localparam numwords = sramlen/`XLEN;
    localparam lognumlines = $clog2(numlines);
	  localparam loglinebytelen = $clog2(linebytelen);
	  localparam lognumways = $clog2(numways);
	  localparam tagstart = lognumlines + loglinebytelen;



	  genvar 			 index, way, cacheWord;
	  logic [sramlen-1:0] CacheData [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
    logic [sramlen-1:0] cacheline;
	  logic [`XLEN-1:0]  CacheTag [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
	  logic 			 CacheValid  [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
	  logic 			 CacheDirty  [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
	  logic [`PA_BITS-1:0] CacheAdr [numways-1:0] [numlines-1:0] [cachesramwords-1:0];
    for(index = 0; index < numlines; index++) begin
		  for(way = 0; way < numways; way++) begin
		    for(cacheWord = 0; cacheWord < cachesramwords; cacheWord++) begin
			    copyShadow #(.tagstart(tagstart),
					.loglinebytelen(loglinebytelen), .sramlen(sramlen))
			    copyShadow(.clk,
          .start,
          .tag(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].CacheTagMem.RAM[index][`PA_BITS-1-tagstart:0]),
          .valid(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].ValidBits[index]),
          .dirty(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].DirtyBits[index]),
                           // these dirty bit selections would be needed if dirty is moved inside the tag array.
          //.dirty(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].dirty.DirtyMem.RAM[index]),
          //.dirty(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].CacheTagMem.RAM[index][`PA_BITS+tagstart]),
          .data(testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[way].word[cacheWord].CacheDataMem.RAM[index]),
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
      if (start) begin #1
        #1
        for(i = 0; i < numlines; i++) begin
          for(j = 0; j < numways; j++) begin
            for(l = 0; l < cachesramwords; l++) begin
              if (CacheValid[j][i][l] & CacheDirty[j][i][l]) begin
                for(k = 0; k < numwords; k++) begin
                  //cacheline = CacheData[j][i][0];
                  // does not work with modelsim
                  // # ** Error: ../testbench/testbench.sv(483): Range must be bounded by constant expressions.
                  // see https://verificationacademy.com/forums/systemverilog/range-must-be-bounded-constant-expressions
                  //ShadowRAM[CacheAdr[j][i][k] >> $clog2(`XLEN/8)] = cacheline[`XLEN*(k+1)-1:`XLEN*k];
                  ShadowRAM[(CacheAdr[j][i][l] >> $clog2(`XLEN/8)) + k] = CacheData[j][i][l][`XLEN*k +: `XLEN];
                end
              end
            end
          end
        end
      end
    end  
  end
  flop #(1) doneReg(.clk, .d(start), .q(done));
endmodule

module copyShadow
  #(parameter tagstart, loglinebytelen, sramlen)
  (input logic clk,
   input logic 			     start,
   input logic [`PA_BITS-1:tagstart] tag,
   input logic 			     valid, dirty,
   input logic [sramlen-1:0] 	     data,
   input logic [32-1:0] 	     index,
   input logic [32-1:0] 	     cacheWord,
   output logic [sramlen-1:0] 	     CacheData,
   output logic [`PA_BITS-1:0] 	     CacheAdr,
   output logic [`XLEN-1:0] 	     CacheTag,
   output logic 		     CacheValid,
   output logic 		     CacheDirty);
  

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
      if (ProgramAddrLabelArray.exists(label)) 
        ProgramAddrLabelArray[label] = adrstr.atohex();
    end
  end
  $fclose(ProgramLabelMapFP);
  $fclose(ProgramAddrMapFP);
endtask

