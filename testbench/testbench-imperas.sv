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

`include "config.vh"


// This is set from the command line script
// `define USE_IMPERAS_DV

`ifdef USE_IMPERAS_DV
  `include "idv/idv.svh"
`endif

import cvw::*;

module testbench;
  parameter DEBUG=0;

`ifdef USE_IMPERAS_DV
  import idvPkg::*;
  import rvviApiPkg::*;
  import idvApiPkg::*;
`endif

  `include "parameter-defs.vh"

  logic        clk;
  logic        reset_ext, reset;


  logic [P.XLEN-1:0] testadr, testadrNoBase;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;

  logic [3:0]  dummy;

  logic [P.AHBW-1:0] HRDATAEXT;
  logic             HREADYEXT, HRESPEXT;
  logic             HSELEXTSDC;
  logic [P.PA_BITS-1:0] HADDR;
  logic [P.AHBW-1:0] HWDATA;
  logic [P.XLEN/8-1:0] HWSTRB;
  logic             HWRITE;
  logic [2:0]       HSIZE;
  logic [2:0]       HBURST;
  logic [3:0]       HPROT;
  logic [1:0]       HTRANS;
  logic             HMASTLOCK;
  logic             HCLK, HRESETn;
  logic [P.XLEN-1:0] PCW;
  logic [31:0]      NextInstrE, InstrM;

  string ProgramAddrMapFile, ProgramLabelMapFile;
  integer   	ProgramAddrLabelArray [string] = '{ "begin_signature" : 0, "tohost" : 0 };
  logic 	    DCacheFlushDone, DCacheFlushStart;
  string 		testName;
  string memfilename, testDir, adrstr, elffilename;

  logic [31:0] GPIOIN, GPIOOUT, GPIOEN;
  logic        UARTSin, UARTSout;
  logic        SPIIn, SPIOut;
  logic [3:0]  SPICS;
  logic        SDCIntr;

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

      if (P.BUS_SUPPORTED) $readmemh(memfilename, dut.uncoregen.uncore.ram.ram.memory.RAM);
	  else $error("Imperas test bench requires BUS.");

      ProgramAddrMapFile = {testDir, "/ref/ref.elf.objdump.addr"};
      ProgramLabelMapFile = {testDir, "/ref/ref.elf.objdump.lab"};
      
      // declare memory labels that interest us, the updateProgramAddrLabelArray task will find the addr of each label and fill the array
      // to expand, add more elements to this array and initialize them to zero (also initilaize them to zero at the start of the next test)
      updateProgramAddrLabelArray(ProgramAddrMapFile, ProgramLabelMapFile, ProgramAddrLabelArray);
      $display("Read memfile %s", memfilename);
      
    end

`ifdef USE_IMPERAS_DV

    rvviTrace #(.XLEN(P.XLEN), .FLEN(P.FLEN)) rvvi();
    wallyTracer #(P) wallyTracer(rvvi);

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
      
      IDV_MAX_ERRORS = 3;

      // Initialize REF (do this before initializing the DUT)
      if (!rvviVersionCheck(RVVI_API_VERSION)) begin
        $display($sformatf("%m @ t=%0t: Expecting RVVI API version %0d.", $time, RVVI_API_VERSION));
        $fatal;
      end
      void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_VENDOR,            "riscv.ovpworld.org"));
      void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_NAME,              "riscv"));
      void'(rvviRefConfigSetString(IDV_CONFIG_MODEL_VARIANT,           "RV64GC"));
      void'(rvviRefConfigSetInt(IDV_CONFIG_MODEL_ADDRESS_BUS_WIDTH,     39));
      void'(rvviRefConfigSetInt(IDV_CONFIG_MAX_NET_LATENCY_RETIREMENTS, 6));

      if (!rvviRefInit(elffilename)) begin
        $display($sformatf("%m @ t=%0t: rvviRefInit failed", $time));
        $fatal;
      end

      // Volatile CSRs
      void'(rvviRefCsrSetVolatile(0, 32'hC00));   // CYCLE
      void'(rvviRefCsrSetVolatile(0, 32'hB00));   // MCYCLE
      void'(rvviRefCsrSetVolatile(0, 32'hC02));   // INSTRET
      void'(rvviRefCsrSetVolatile(0, 32'hB02));   // MINSTRET
      void'(rvviRefCsrSetVolatile(0, 32'hC01));   // TIME
      
      // cannot predict this register due to latency between
      // pending and taken
      void'(rvviRefCsrSetVolatile(0, 32'h344));   // MIP
      void'(rvviRefCsrSetVolatile(0, 32'h144));   // SIP

      // Privileges for PMA are set in the imperas.ic
      // volatile (IO) regions are defined here
      // only real ROM/RAM areas are BOOTROM and UNCORE_RAM
      if (P.CLINT_SUPPORTED) begin
          void'(rvviRefMemorySetVolatile(P.CLINT_BASE, (P.CLINT_BASE + P.CLINT_RANGE)));
      end
      if (P.GPIO_SUPPORTED) begin
          void'(rvviRefMemorySetVolatile(P.GPIO_BASE, (P.GPIO_BASE + P.GPIO_RANGE)));
      end
      if (P.UART_SUPPORTED) begin
          void'(rvviRefMemorySetVolatile(P.UART_BASE, (P.UART_BASE + P.UART_RANGE)));
      end
      if (P.PLIC_SUPPORTED) begin
          void'(rvviRefMemorySetVolatile(P.PLIC_BASE, (P.PLIC_BASE + P.PLIC_RANGE)));
      end
      if (P.SDC_SUPPORTED) begin
          void'(rvviRefMemorySetVolatile(P.SDC_BASE, (P.SDC_BASE + P.SDC_RANGE)));
      end      
      if (P.SPI_SUPPORTED) begin
          void'(rvviRefMemorySetVolatile(P.SPI_BASE, (P.SPI_BASE + P.SPI_RANGE)));
      end

      if(P.XLEN==32) begin
          void'(rvviRefCsrSetVolatile(0, 32'hC80));   // CYCLEH
          void'(rvviRefCsrSetVolatile(0, 32'hB80));   // MCYCLEH
          void'(rvviRefCsrSetVolatile(0, 32'hC82));   // INSTRETH
          void'(rvviRefCsrSetVolatile(0, 32'hB82));   // MINSTRETH
      end

      void'(rvviRefCsrSetVolatile(0, 32'h104));   // SIE - Temporary!!!!
      
    end

    always @(dut.core.priv.priv.csr.csri.MIP_REGW[7])   void'(rvvi.net_push("MTimerInterrupt",    dut.core.priv.priv.csr.csri.MIP_REGW[7]));
    always @(dut.core.priv.priv.csr.csri.MIP_REGW[11])  void'(rvvi.net_push("MExternalInterrupt", dut.core.priv.priv.csr.csri.MIP_REGW[11]));
    always @(dut.core.priv.priv.csr.csri.MIP_REGW[9])   void'(rvvi.net_push("SExternalInterrupt", dut.core.priv.priv.csr.csri.MIP_REGW[9]));
    always @(dut.core.priv.priv.csr.csri.MIP_REGW[3])   void'(rvvi.net_push("MSWInterrupt",       dut.core.priv.priv.csr.csri.MIP_REGW[3]));
    always @(dut.core.priv.priv.csr.csri.MIP_REGW[1])   void'(rvvi.net_push("SSWInterrupt",       dut.core.priv.priv.csr.csri.MIP_REGW[1]));
    always @(dut.core.priv.priv.csr.csri.MIP_REGW[5])   void'(rvvi.net_push("STimerInterrupt",    dut.core.priv.priv.csr.csri.MIP_REGW[5]));

    final begin
      void'(rvviRefShutdown());
    end

`endif

  flopenr #(P.XLEN) PCWReg(clk, reset, ~dut.core.ieu.dp.StallW, dut.core.ifu.PCM, PCW);
  flopenr  #(32)   InstrWReg(clk, reset, ~dut.core.ieu.dp.StallW,  InstrM, InstrW);

  // check assertions for a legal configuration
  riscvassertions #(P) riscvassertions();


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

  if(P.SDC_SUPPORTED) begin : sdcard
    // *** fix later
/* -----\/----- EXCLUDED -----\/-----
    sdModel sdcard
      (.sdClk(SDCCLK),
       .cmd(SDCCmd), 
       .dat(SDCDat));

    assign SDCCmd = SDCCmdOE ? SDCCmdOut : 1'bz;
    assign SDCCmdIn = SDCCmd;
    assign SDCDatIn = SDCDat;
 -----/\----- EXCLUDED -----/\----- */
    assign SDCIntr = 0;
  end else begin
    assign SDCIntr = 0;
  end

  wallypipelinedsoc #(P) dut(.clk, .reset_ext, .reset, .HRDATAEXT, .HREADYEXT, .HRESPEXT, .HSELEXT, .HSELEXTSDC,
                        .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
                        .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(1'b0), .GPIOIN, .GPIOOUT, .GPIOEN,
                        .UARTSin, .UARTSout, .SDCIntr, .SPICS, .SPIOut, .SPIIn); 

  // Track names of instructions
  instrTrackerTB it(clk, reset, dut.core.ieu.dp.FlushE,
                dut.core.ifu.InstrRawF[31:0],
                dut.core.ifu.InstrD, dut.core.ifu.InstrE,
                InstrM,  InstrW,
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
    FunctionName #(P) FunctionName(.reset(reset),
			      .clk(clk),
			      .ProgramAddrMapFile(ProgramAddrMapFile),
			      .ProgramLabelMapFile(ProgramLabelMapFile));
  end

  // Duplicate copy of pipeline registers that are optimized out of some configurations
  mux2    #(32)     FlushInstrMMux(dut.core.ifu.InstrE, dut.core.ifu.nop, dut.core.ifu.FlushM, NextInstrE);
  flopenr #(32)     InstrMReg(clk, reset, ~dut.core.ifu.StallM, NextInstrE, InstrM);

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
           ((InstrM == 32'h6f | InstrM == 32'hfc32a423 | InstrM == 32'hfc32a823) & dut.core.ieu.c.InstrValidM ) |
           ((dut.core.lsu.IEUAdrM == ProgramAddrLabelArray["tohost"]) & InstrMName == "SW" ); 

  DCacheFlushFSM #(P) DCacheFlushFSM(.clk(clk),
	    		.start(DCacheFlushStart),
		    	.done(DCacheFlushDone));

  // initialize the branch predictor
  if (P.BPRED_SUPPORTED == 1)
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

  watchdog #(P.XLEN, 1000000) watchdog(.clk, .reset);  // check if PCW is stuck

endmodule


/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */


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

