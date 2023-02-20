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

// This is set from the commsnd line script
// `define USE_IMPERAS_DV

`ifdef USE_IMPERAS_DV
  `include "rvvi/imperasDV.svh"
`endif

module testbench;
  parameter DEBUG=0;

`ifdef USE_IMPERAS_DV
  import rvviPkg::*;
  import rvviApiPkg::*;
`endif

  logic        clk;
  logic        reset_ext, reset;


  logic [`XLEN-1:0] testadr, testadrNoBase;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;

  logic [3:0]  dummy;

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
  string 		testName;
  string memfilename, testDir, adrstr, elffilename;

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

  // Imperas look here.
  initial
    begin
      ResetCount = 0;
      ResetThreshold = 2;
      InReset = 1;
      testadr = 0;
      testadrNoBase = 0;

      if ($value$plusargs("testDir=%s", testDir)) begin
          memfilename = {testDir, "/ref/ref.elf.memfile"};
          elffilename = {testDir, "/ref/ref.elf"};
          $display($sformatf("%m @ t=%0t: loading testDir %0s", $time, testDir));
      end else begin
          $error("Must specify test directory using plusarg testDir");
      end

      if (`BUS_SUPPORTED) $readmemh(memfilename, dut.uncore.uncore.ram.ram.memory.RAM);
	  else $error("Imperas test bench requires BUS.");

      ProgramAddrMapFile = {testDir, "/ref/ref.elf.objdump.addr"};
      ProgramLabelMapFile = {testDir, "/ref/ref.elf.objdump.lab"};
      
      // declare memory labels that interest us, the updateProgramAddrLabelArray task will find the addr of each label and fill the array
      // to expand, add more elements to this array and initialize them to zero (also initilaize them to zero at the start of the next test)
      updateProgramAddrLabelArray(ProgramAddrMapFile, ProgramLabelMapFile, ProgramAddrLabelArray);
      $display("Read memfile %s", memfilename);
      
    end

  rvviTrace #(.XLEN(`XLEN), .FLEN(`FLEN)) rvvi();
  wallyTracer wallyTracer(rvvi);

`ifdef USE_IMPERAS_DV
    trace2log idv_trace2log(rvvi);
    trace2cov idv_trace2cov(rvvi);

    // enabling of comparison types
    trace2api #(.CMP_PC      (1),
                .CMP_INS     (1),
                .CMP_GPR     (1),
                .CMP_FPR     (1),
                .CMP_VR      (0),
                .CMP_CSR     (1)
               ) idv_trace2api(rvvi);

    initial begin 
      MAX_ERRS = 3;

      // Initialize REF (do this before initializing the DUT)
      if (!rvviVersionCheck(RVVI_API_VERSION)) begin
        msgfatal($sformatf("%m @ t=%0t: Expecting RVVI API version %0d.", $time, RVVI_API_VERSION));
      end
      void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_VENDOR,         "riscv.ovpworld.org"));
      void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_NAME,           "riscv"));
      void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_VARIANT,        "RV64GC"));
      void'(rvviRefConfigSetInt(IDV_CONFIG_MODEL_ADDRESS_BUS_WIDTH, 39));
      if (!rvviRefInit(elffilename)) begin
        msgfatal($sformatf("%m @ t=%0t: rvviRefInit failed", $time));
      end

      // Volatile CSRs
      void'(rvviRefCsrSetVolatile(0, 32'hC00));   // CYCLE
      void'(rvviRefCsrSetVolatile(0, 32'hB00));   // MCYCLE
      void'(rvviRefCsrSetVolatile(0, 32'hC02));   // INSTRET
      void'(rvviRefCsrSetVolatile(0, 32'hB02));   // MINSTRET
      void'(rvviRefCsrSetVolatile(0, 32'hC01));   // TIME

      if(`XLEN==32) begin
          void'(rvviRefCsrSetVolatile(0, 32'hC80));   // CYCLEH
          void'(rvviRefCsrSetVolatile(0, 32'hB80));   // MCYCLEH
          void'(rvviRefCsrSetVolatile(0, 32'hC82));   // INSTRETH
          void'(rvviRefCsrSetVolatile(0, 32'hB82));   // MINSTRETH
      end

      // Enable the trace2log module
      if ($value$plusargs("TRACE2LOG_ENABLE=%d", TRACE2LOG_ENABLE)) begin
        msgnote($sformatf("%m @ t=%0t: TRACE2LOG_ENABLE is %0d", $time, TRACE2LOG_ENABLE));
      end
      
      if ($value$plusargs("TRACE2COV_ENABLE=%d", TRACE2COV_ENABLE)) begin
        msgnote($sformatf("%m @ t=%0t: TRACE2COV_ENABLE is %0d", $time, TRACE2COV_ENABLE));
      end
    end

    final begin
      void'(rvviRefShutdown());
    end

`endif

  flopenr #(`XLEN) PCWReg(clk, reset, ~dut.core.ieu.dp.StallW, dut.core.ifu.PCM, PCW);
  flopenr  #(32)   InstrWReg(clk, reset, ~dut.core.ieu.dp.StallW,  dut.core.ifu.InstrM, InstrW);

  // check assertions for a legal configuration
  riscvassertions riscvassertions();


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

  // generate clock to sequence tests
  always
    begin
      clk = 1; # 5; clk = 0; # 5;
      // if ($time % 100000 == 0) $display("Time is %0t", $time);
    end
   
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
      end
    end // always @ (negedge clk)


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
      for(adrindex = 0; adrindex < 1024; adrindex++) begin
        initial begin 
        force dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem[adrindex] = 0;
        force dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem[adrindex] = 0;
        #1;
        release dut.core.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem[adrindex];
        release dut.core.ifu.bpred.bpred.TargetPredictor.memory.mem[adrindex];
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
	  localparam integer numlines = testbench.dut.core.lsu.bus.dcache.dcache.NUMLINES;
	  localparam integer numways = testbench.dut.core.lsu.bus.dcache.dcache.NUMWAYS;
	  localparam integer linebytelen = testbench.dut.core.lsu.bus.dcache.dcache.LINEBYTELEN;
	  localparam integer linelen = testbench.dut.core.lsu.bus.dcache.dcache.LINELEN;
	  localparam integer sramlen = testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[0].SRAMLEN;            
	  localparam integer cachesramwords = testbench.dut.core.lsu.bus.dcache.dcache.CacheWays[0].NUMSRAM;
      
//testbench.dut.core.lsu.bus.dcache.dcache.CacheWays.NUMSRAM;
	  localparam integer numwords = sramlen/`XLEN;
      localparam integer lognumlines = $clog2(numlines);
	  localparam integer loglinebytelen = $clog2(linebytelen);
	  localparam integer lognumways = $clog2(numways);
	  localparam integer tagstart = lognumlines + loglinebytelen;



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

