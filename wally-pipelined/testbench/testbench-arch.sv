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
  parameter TESTSPERIPH = 0; // set to 0 for regression
  parameter TESTSPRIV = 0; // set to 0 for regression
  
  logic        clk;
  logic        reset;

  parameter SIGNATURESIZE = 5000000;

  int test, i, errors, totalerrors;
  logic [31:0] sig32[0:SIGNATURESIZE];
  logic [`XLEN-1:0] signature[0:SIGNATURESIZE];
  logic [`XLEN-1:0] testadr;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  logic [`XLEN-1:0] meminit;

  string tests32mmu[] = '{
    "rv32mmu/WALLY-MMU-SV32", "3000"
    //"rv32mmu/WALLY-PMA", "3000",
    //"rv32mmu/WALLY-PMA", "3000"
    };

  string tests64mmu[] = '{
    "rv64mmu/WALLY-MMU-SV48", "3000",
    "rv64mmu/WALLY-MMU-SV39", "3000"
    //"rv64mmu/WALLY-PMA", "3000",
    //"rv64mmu/WALLY-PMA", "3000"
  };

  
string tests32f[] = '{
    "rv32f/I-FADD-S-01", "2000",
    "rv32f/I-FCLASS-S-01", "2000",
    "rv32f/I-FCVT-S-W-01", "2000",
    "rv32f/I-FCVT-S-WU-01", "2000",
    "rv32f/I-FCVT-W-S-01", "2000",
    "rv32f/I-FCVT-WU-S-01", "2000",
    "rv32f/I-FDIV-S-01", "2000",
    "rv32f/I-FEQ-S-01", "2000",
    "rv32f/I-FLE-S-01", "2000",
    "rv32f/I-FLT-S-01", "2000",
    "rv32f/I-FMADD-S-01", "2000",
    "rv32f/I-FMAX-S-01", "2000",
    "rv32f/I-FMIN-S-01", "2000",
    "rv32f/I-FMSUB-S-01", "2000",
    "rv32f/I-FMUL-S-01", "2000",
    "rv32f/I-FMV-W-X-01", "2000",
    "rv32f/I-FMV-X-W-01", "2000",
    "rv32f/I-FNMADD-S-01", "2000",
    "rv32f/I-FNMSUB-S-01", "2000",
    "rv32f/I-FSGNJ-S-01", "2000",
    "rv32f/I-FSGNJN-S-01", "2000",
    "rv32f/I-FSGNJX-S-01", "2000",
    "rv32f/I-FSQRT-S-01", "2000",
    "rv32f/I-FSW-01", "2000",
    "rv32f/I-FLW-01", "2110",
    "rv32f/I-FSUB-S-01", "2000"
  };

  string tests64f[] = '{
    "rv64f/I-FLW-01", "2110",
    "rv64f/I-FMV-W-X-01", "2000",
    "rv64f/I-FMV-X-W-01", "2000",
    "rv64f/I-FSW-01", "2000",
    "rv64f/I-FCLASS-S-01", "2000",
    "rv64f/I-FADD-S-01", "2000",
//    "rv64f/I-FCVT-S-L-01", "2000",
//    "rv64f/I-FCVT-S-LU-01", "2000",
//    "rv64f/I-FCVT-S-W-01", "2000",
//    "rv64f/I-FCVT-S-WU-01", "2000",
    "rv64f/I-FCVT-L-S-01", "2000",
    "rv64f/I-FCVT-LU-S-01", "2000",
    "rv64f/I-FCVT-W-S-01", "2000",
    "rv64f/I-FCVT-WU-S-01", "2000",
    "rv64f/I-FDIV-S-01", "2000",
    "rv64f/I-FEQ-S-01", "2000",
    "rv64f/I-FLE-S-01", "2000",
    "rv64f/I-FLT-S-01", "2000",
    "rv64f/I-FMADD-S-01", "2000",
    "rv64f/I-FMAX-S-01", "2000",
    "rv64f/I-FMIN-S-01", "2000",
    "rv64f/I-FMSUB-S-01", "2000",
    "rv64f/I-FMUL-S-01", "2000",
    "rv64f/I-FNMADD-S-01", "2000",
    "rv64f/I-FNMSUB-S-01", "2000",
    "rv64f/I-FSGNJ-S-01", "2000",
    "rv64f/I-FSGNJN-S-01", "2000",
    "rv64f/I-FSGNJX-S-01", "2000",
    "rv64f/I-FSQRT-S-01", "2000",
    "rv64f/I-FSUB-S-01", "2000"
  };

  string tests64d[] = '{
    "rv64d/I-FSD-01", "2000",
    "rv64d/I-FLD-01", "2420",
    "rv64d/I-FMV-X-D-01", "2000",
    "rv64d/I-FMV-D-X-01", "2000",
    "rv64d/I-FDIV-D-01", "2000",
    "rv64d/I-FNMADD-D-01", "2000",
    "rv64d/I-FNMSUB-D-01", "2000",
    "rv64d/I-FMSUB-D-01", "2000",
    "rv64d/I-FMAX-D-01", "2000",
    "rv64d/I-FMIN-D-01", "2000",
    "rv64d/I-FLE-D-01", "2000",
    "rv64d/I-FLT-D-01", "2000",
    "rv64d/I-FEQ-D-01", "2000",
    "rv64d/I-FADD-D-01", "2000",
    "rv64d/I-FCLASS-D-01", "2000",
    "rv64d/I-FMADD-D-01", "2000",
    "rv64d/I-FMUL-D-01", "2000",
    "rv64d/I-FSGNJ-D-01", "2000",
    "rv64d/I-FSGNJN-D-01", "2000",
    "rv64d/I-FSGNJX-D-01", "2000",
    "rv64d/I-FSQRT-D-01", "2000",
    "rv64d/I-FSUB-D-01", "2000",
//    "rv64d/I-FCVT-D-L-01", "2000",
//    "rv64d/I-FCVT-D-LU-01", "2000",
    "rv64d/I-FCVT-D-S-01", "2000", 
//    "rv64d/I-FCVT-D-W-01", "2000",
//    "rv64d/I-FCVT-D-WU-01", "2000",
    "rv64d/I-FCVT-L-D-01", "2000",
    "rv64d/I-FCVT-LU-D-01", "2000",
    "rv64d/I-FCVT-S-D-01", "2000", 
    "rv64d/I-FCVT-W-D-01", "2000",
    "rv64d/I-FCVT-WU-D-01", "2000"
};

  string tests64a[] = '{
    "rv64a/WALLY-AMO", "2110",
    "rv64a/WALLY-LRSC", "2110"
  };

  string tests64priv[] = '{
    "rv64i_m/privilege/ebreak", "2090",
    "rv64i_m/privilege/ecall", "2090",
    "rv64i_m/privilege/misalign-beq-01", "20a0",
    "rv64i_m/privilege/misalign-bge-01", "20a0",
    "rv64i_m/privilege/misalign-bgeu-01", "20a0",
    "rv64i_m/privilege/misalign-blt-01", "20a0",
    "rv64i_m/privilege/misalign-bltu-01", "20a0",
    "rv64i_m/privilege/misalign-bne-01", "20a0",
    "rv64i_m/privilege/misalign-jal-01", "20a0",
    "rv64i_m/privilege/misalign-ld-01", "20a0",
    "rv64i_m/privilege/misalign-lh-01", "20a0",
    "rv64i_m/privilege/misalign-lhu-01", "20a0",
    "rv64i_m/privilege/misalign-lw-01", "20a0",
    "rv64i_m/privilege/misalign-lwu-01", "20a0",
    "rv64i_m/privilege/misalign-sd-01", "20a0",
    "rv64i_m/privilege/misalign-sh-01", "20a0",
    "rv64i_m/privilege/misalign-sw-01", "20a0",
    "rv64i_m/privilege/misalign1-jalr-01", "20a0",
    "rv64i_m/privilege/misalign2-jalr-01", "20a0"
    };

  string tests64m[] = '{
    "rv64i_m/M/div-01", "9010",
    "rv64i_m/M/divu-01", "a010",
    "rv64i_m/M/divuw-01", "a010",
    "rv64i_m/M/divw-01", "9010",
    "rv64i_m/M/mul-01", "9010",
    "rv64i_m/M/mulh-01", "9010",
    "rv64i_m/M/mulhsu-01", "9010",
    "rv64i_m/M/mulhu-01", "a010",
    "rv64i_m/M/mulw-01", "9010",
    "rv64i_m/M/rem-01", "9010",
    "rv64i_m/M/remu-01", "a010",
    "rv64i_m/M/remuw-01", "a010",
    "rv64i_m/M/remw-01", "9010"
   };

  string tests64ic[] = '{
    "rv64i_m/C/cadd-01", "8010",
    "rv64i_m/C/caddi-01", "4010",
    "rv64i_m/C/caddi16sp-01", "2010",
    "rv64i_m/C/caddi4spn-01", "2010",
    "rv64i_m/C/caddiw-01", "4010",
    "rv64i_m/C/caddw-01", "8010",
    "rv64i_m/C/cand-01", "8010",
    "rv64i_m/C/candi-01", "4010",
    "rv64i_m/C/cbeqz-01", "4010",
    "rv64i_m/C/cbnez-01", "5010",
    "rv64i_m/C/cebreak-01", "2070",
    "rv64i_m/C/cj-01", "3010",
    "rv64i_m/C/cjalr-01", "2010",
    "rv64i_m/C/cjr-01", "2010",
    "rv64i_m/C/cld-01", "2010",
    "rv64i_m/C/cldsp-01", "2010",
    "rv64i_m/C/cli-01", "2010",
    "rv64i_m/C/clui-01", "2010",
    "rv64i_m/C/clw-01", "2010",
    "rv64i_m/C/clwsp-01", "2010",
    "rv64i_m/C/cmv-01", "2010",
    "rv64i_m/C/cnop-01", "2010",
    "rv64i_m/C/cor-01", "8010",
    "rv64i_m/C/csd-01", "3010",
    "rv64i_m/C/csdsp-01", "3010",
    "rv64i_m/C/cslli-01", "2010",
    "rv64i_m/C/csrai-01", "2010",
    "rv64i_m/C/csrli-01", "2010",
    "rv64i_m/C/csub-01", "8010",
    "rv64i_m/C/csubw-01", "8010",
    "rv64i_m/C/csw-01", "3010",
    "rv64i_m/C/cswsp-01", "3010",
    "rv64i_m/C/cxor-01", "8010"
  };

  string tests64i[] = '{
    "rv64i_m/I/add-01", "9010",
    "rv64i_m/I/addi-01", "6010",
    "rv64i_m/I/addiw-01", "6010",
    "rv64i_m/I/addw-01", "9010",
    "rv64i_m/I/and-01", "9010",
    "rv64i_m/I/andi-01", "6010",
    "rv64i_m/I/auipc-01", "2010",
    "rv64i_m/I/beq-01", "47010",
    "rv64i_m/I/bge-01", "47010",
    "rv64i_m/I/bgeu-01", "56010",
    "rv64i_m/I/blt-01", "4d010",
    "rv64i_m/I/bltu-01", "57010",
    "rv64i_m/I/bne-01", "43010",
    "rv64i_m/I/fence-01", "2010",
    "rv64i_m/I/jal-01", "122010",
    "rv64i_m/I/jalr-01", "2010",
    "rv64i_m/I/lb-align-01", "2010",
    "rv64i_m/I/lbu-align-01", "2010",
    "rv64i_m/I/ld-align-01", "2010",
    "rv64i_m/I/lh-align-01", "2010",
    "rv64i_m/I/lhu-align-01", "2010",
    "rv64i_m/I/lui-01", "2010",
    "rv64i_m/I/lw-align-01", "2010",
    "rv64i_m/I/lwu-align-01", "2010",
    "rv64i_m/I/or-01", "9010",
    "rv64i_m/I/ori-01", "6010",
    "rv64i_m/I/sb-align-01", "3010",
    "rv64i_m/I/sd-align-01", "3010",
    "rv64i_m/I/sh-align-01", "3010",
    "rv64i_m/I/sll-01", "3010",
    "rv64i_m/I/slli-01", "2010",
    "rv64i_m/I/slliw-01", "2010",
    "rv64i_m/I/sllw-01", "3010",
    "rv64i_m/I/slt-01", "9010",
    "rv64i_m/I/slti-01", "6010",
    "rv64i_m/I/sltiu-01", "6010",
    "rv64i_m/I/sltu-01", "a010",
    "rv64i_m/I/sra-01", "3010",
    "rv64i_m/I/srai-01", "2010",
    "rv64i_m/I/sraiw-01", "2010",
    "rv64i_m/I/sraw-01", "3010",
    "rv64i_m/I/srl-01", "3010",
    "rv64i_m/I/srli-01", "2010",
    "rv64i_m/I/srliw-01", "2010",
    "rv64i_m/I/srlw-01", "3010",
    "rv64i_m/I/sub-01", "9010",
    "rv64i_m/I/subw-01", "9010",
    "rv64i_m/I/sw-align-01", "3010",
    "rv64i_m/I/xor-01", "9010",
    "rv64i_m/I/xori-01", "6010"
  };

    string tests32priv[] = '{
    "rv32i_m/privilege/ebreak", "2090",
    "rv32i_m/privilege/ecall", "2090",
    "rv32i_m/privilege/misalign-beq-01", "20a0",
    "rv32i_m/privilege/misalign-bge-01", "20a0",
    "rv32i_m/privilege/misalign-bgeu-01", "20a0",
    "rv32i_m/privilege/misalign-blt-01", "20a0",
    "rv32i_m/privilege/misalign-bltu-01", "20a0",
    "rv32i_m/privilege/misalign-bne-01", "20a0",
    "rv32i_m/privilege/misalign-jal-01", "20a0",
    "rv32i_m/privilege/misalign-lh-01", "20a0",
    "rv32i_m/privilege/misalign-lhu-01", "20a0",
    "rv32i_m/privilege/misalign-lw-01", "20a0",
    "rv32i_m/privilege/misalign-lwu-01", "20a0",
    "rv32i_m/privilege/misalign-sh-01", "20a0",
    "rv32i_m/privilege/misalign-sw-01", "20a0",
    "rv32i_m/privilege/misalign1-jalr-01", "20a0",
    "rv32i_m/privilege/misalign2-jalr-01", "20a0"
    };

  string tests32m[] = '{
    "rv32i_m/M/div-01", "9010",
    "rv32i_m/M/divu-01", "a010",
    "rv32i_m/M/mul-01", "9010",
    "rv32i_m/M/mulh-01", "9010",
    "rv32i_m/M/mulhsu-01", "9010",
    "rv32i_m/M/mulhu-01", "a010",
    "rv32i_m/M/rem-01", "9010",
    "rv32i_m/M/remu-01", "a010",
   };

  string tests32ic[] = '{
    "rv32i_m/C/cadd-01", "8010",
    "rv32i_m/C/caddi-01", "4010",
    "rv32i_m/C/caddi16sp-01", "2010",
    "rv32i_m/C/caddi4spn-01", "2010",
    "rv32i_m/C/cand-01", "8010",
    "rv32i_m/C/candi-01", "4010",
    "rv32i_m/C/cbeqz-01", "4010",
    "rv32i_m/C/cbnez-01", "5010",
    "rv32i_m/C/cebreak-01", "2070",
    "rv32i_m/C/cj-01", "3010",
    "rv32i_m/C/cjal-01", "",
    "rv32i_m/C/cjalr-01", "2010",
    "rv32i_m/C/cjr-01", "2010",
    "rv32i_m/C/cli-01", "2010",
    "rv32i_m/C/clui-01", "2010",
    "rv32i_m/C/clw-01", "2010",
    "rv32i_m/C/clwsp-01", "2010",
    "rv32i_m/C/cmv-01", "2010",
    "rv32i_m/C/cnop-01", "2010",
    "rv32i_m/C/cor-01", "8010",
    "rv32i_m/C/cslli-01", "2010",
    "rv32i_m/C/csrai-01", "2010",
    "rv32i_m/C/csrli-01", "2010",
    "rv32i_m/C/csub-01", "8010",
    "rv32i_m/C/csw-01", "3010",
    "rv32i_m/C/cswsp-01", "3010",
    "rv32i_m/C/cxor-01", "8010"
  };

  string tests32i[] = '{
    "rv32i_m/I/add-01", "9010",
    "rv32i_m/I/addi-01", "6010",
    "rv32i_m/I/and-01", "9010",
    "rv32i_m/I/andi-01", "6010",
    "rv32i_m/I/auipc-01", "2010",
    "rv32i_m/I/beq-01", "47010",
    "rv32i_m/I/bge-01", "47010",
    "rv32i_m/I/bgeu-01", "56010",
    "rv32i_m/I/blt-01", "4d010",
    "rv32i_m/I/bltu-01", "57010",
    "rv32i_m/I/bne-01", "43010",
    "rv32i_m/I/fence-01", "2010",
    "rv32i_m/I/jal-01", "122010",
    "rv32i_m/I/jalr-01", "2010",
    "rv32i_m/I/lb-align-01", "2010",
    "rv32i_m/I/lbu-align-01", "2010",
    "rv32i_m/I/lh-align-01", "2010",
    "rv32i_m/I/lhu-align-01", "2010",
    "rv32i_m/I/lui-01", "2010",
    "rv32i_m/I/lw-align-01", "2010",
    "rv32i_m/I/or-01", "9010",
    "rv32i_m/I/ori-01", "6010",
    "rv32i_m/I/sb-align-01", "3010",
    "rv32i_m/I/sh-align-01", "3010",
    "rv32i_m/I/sll-01", "3010",
    "rv32i_m/I/slli-01", "2010",
    "rv32i_m/I/slt-01", "9010",
    "rv32i_m/I/slti-01", "6010",
    "rv32i_m/I/sltiu-01", "6010",
    "rv32i_m/I/sltu-01", "a010",
    "rv32i_m/I/sra-01", "3010",
    "rv32i_m/I/srai-01", "2010",
    "rv32i_m/I/srl-01", "3010",
    "rv32i_m/I/srli-01", "2010",
    "rv32i_m/I/sub-01", "9010",
    "rv32i_m/I/sw-align-01", "3010",
    "rv32i_m/I/xor-01", "9010",
    "rv32i_m/I/xori-01", "6010"
  };

   string tests[];
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
  logic [`XLEN-1:0] PCW;

  logic 	    DCacheFlushDone, DCacheFlushStart;
    
  flopenr #(`XLEN) PCWReg(clk, reset, ~dut.hart.ieu.dp.StallW, dut.hart.ifu.PCM, PCW);
  flopenr  #(32)   InstrWReg(clk, reset, ~dut.hart.ieu.dp.StallW,  dut.hart.ifu.InstrM, InstrW);

  // check assertions for a legal configuration
  riscvassertions riscvassertions();
  logging logging(clk, reset, dut.uncore.HADDR, dut.uncore.HTRANS);

  // pick tests based on modes supported
  initial begin
    if (`XLEN == 64) begin // RV64
      if (`TESTSBP) begin
        tests = testsBP64;
	// testsbp should not run the other tests. It starts at address 0 rather than
	// 0x8000_0000, the next if must remain an else if.	
      end else if (TESTSPERIPH)
        tests = tests64periph;
      else if (TESTSPRIV)
        tests = tests64p;
      else begin
        tests = {tests64priv, tests64i};
//        tests = {tests64p,tests64i, tests64periph};
        if (`C_SUPPORTED) tests = {tests, tests64ic};
//        else              tests = {tests, tests64iNOc};
        if (`M_SUPPORTED) tests = {tests, tests64m};
/*        if (`F_SUPPORTED) tests = {tests64f, tests};
        if (`D_SUPPORTED) tests = {tests64d, tests};
        if (`MEM_VIRTMEM) tests = {tests64mmu, tests};
        if (`A_SUPPORTED) tests = {tests64a, tests}; */
      end
      //tests = {tests64a, tests};
    end else begin // RV32
      // *** add the 32 bit bp tests
      if (TESTSPERIPH)
        tests = tests32periph;
      else if (TESTSPRIV)
        tests = tests32p;
      else begin
          tests = {tests32i, tests32p};//,tests32periph}; *** broken at the moment
          if (`C_SUPPORTED % 2 == 1) tests = {tests, tests32ic};    
          else                       tests = {tests, tests32iNOc};
          if (`M_SUPPORTED % 2 == 1) tests = {tests, tests32m};
          if (`F_SUPPORTED) tests = {tests32f, tests};
          if (`MEM_VIRTMEM) tests = {tests32mmu, tests};
          if (`A_SUPPORTED) tests = {tests32a, tests};
     end
    end
  end

  string tvroot, bootroot, signame, memfilename, romfilename;

  logic [31:0] GPIOPinsIn, GPIOPinsOut, GPIOPinsEn;
  logic UARTSin, UARTSout;

  // instantiate device to be tested
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;
  assign HREADYEXT = 1;
  assign HRESPEXT = 0;
  assign HRDATAEXT = 0;

  wallypipelinedsoc dut(.*); 

  // Track names of instructions
  instrTrackerTB it(clk, reset, dut.hart.ieu.dp.FlushE,
                dut.hart.ifu.icache.FinalInstrRawF,
                dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM,  dut.hart.ifu.InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // initialize tests
  localparam integer 	   MemStartAddr = `TIM_BASE>>(1+`XLEN/32);
  localparam integer 	   MemEndAddr = (`TIM_RANGE+`TIM_BASE)>>1+(`XLEN/32);

  initial
    begin
      test = 0;
      totalerrors = 0;
      testadr = 0;
      // fill memory with defined values to reduce Xs in simulation
      // Quick note the memory will need to be initialized.  The C library does not
      //  guarantee the  initialized reads.  For example a strcmp can read 6 byte
      //  strings, but uses a load double to read them in.  If the last 2 bytes are
      //  not initialized the compare results in an 'x' which propagates through 
      // the design.
      if (`XLEN == 32) meminit = 32'hFEDC0123;
      else meminit = 64'hFEDCBA9876543210;
      // *** broken because DTIM also drives RAM
      if (`TESTSBP) begin
	for (i=MemStartAddr; i<MemEndAddr; i = i+1) begin
	  dut.uncore.dtim.RAM[i] = meminit;
	end
      end
      // read test vectors into memory
      bootroot = "../../imperas-riscv-tests/";
      tvroot = "/home/harris/github/riscv-arch-test/";
      memfilename = {tvroot, "work/", tests[test], ".elf.memfile"};
//      romfilename = {bootroot, "imperas-boottim.txt"};
      $readmemh(memfilename, dut.uncore.dtim.RAM);
//      $readmemh(romfilename, dut.uncore.bootdtim.bootdtim.RAM);
      ProgramAddrMapFile = {tvroot, "work/", tests[test], ".elf.objdump.addr"};
      ProgramLabelMapFile = {tvroot, "work/", tests[test], ".elf.objdump.lab"};
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
/* -----\/----- EXCLUDED -----\/-----
      if (dut.hart.priv.EcallFaultM && 
			    (dut.hart.ieu.dp.regf.rf[3] == 1 || 
			     (dut.hart.ieu.dp.regf.we3 && 
			      dut.hart.ieu.dp.regf.a3 == 3 && 
			      dut.hart.ieu.dp.regf.wd3 == 1))) begin
 -----/\----- EXCLUDED -----/\----- */
      if (DCacheFlushDone) begin
        //$display("Code ended with ecall with gp = 1");

        #600; // give time for instructions in pipeline to finish
        // clear signature to prevent contamination from previous tests
        for(i=0; i<SIGNATURESIZE; i=i+1) begin
          sig32[i] = 'bx;
        end

        // read signature, reformat in 64 bits if necessary
        signame = {tvroot, "work/", tests[test], ".signature.output"};
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
          if (sig32[i-1] === 'bx) begin
            if (i == 1) begin
              i = SIGNATURESIZE+1; // flag empty file
              $display("  Error: empty test file");
            end else i = SIGNATURESIZE; // skip over the rest of the x's for efficiency
          end
        end

        // Check errors
        errors = (i == SIGNATURESIZE+1); // error if file is empty
        i = 0;
        testadr = (`TIM_BASE+tests[test+1].atohex())/(`XLEN/8);
        /* verilator lint_off INFINITELOOP */
        while (signature[i] !== 'bx) begin
          //$display("signature[%h] = %h", i, signature[i]);
          if (signature[i] !== dut.uncore.dtim.RAM[testadr+i] &&
	      (signature[i] !== DCacheFlushFSM.ShadowRAM[testadr+i])) begin
            if (signature[i+4] !== 'bx || signature[i] !== 32'hFFFFFFFF) begin
              // report errors unless they are garbage at the end of the sim
              // kind of hacky test for garbage right now
              errors = errors+1;
              $display("  Error on test %s result %d: adr = %h sim (D$) %h sim (TIM) = %h, signature = %h", 
                    tests[test], i, (testadr+i)*(`XLEN/8), DCacheFlushFSM.ShadowRAM[testadr+i], dut.uncore.dtim.RAM[testadr+i], signature[i]);
              $stop;//***debug
            end
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
        test = test + 2;
        if (test == tests.size()) begin
          if (totalerrors == 0) $display("SUCCESS! All tests ran without failures.");
          else $display("FAIL: %d test programs had errors", totalerrors);
          $stop;
        end
        else begin
          memfilename = {tvroot, "work/",tests[test], ".elf.memfile"};
          $readmemh(memfilename, dut.uncore.dtim.RAM);
          $display("Read memfile %s", memfilename);
	  ProgramAddrMapFile = {tvroot, "work/", tests[test], ".elf.objdump.addr"};
	  ProgramLabelMapFile = {tvroot, "work/", tests[test], ".elf.objdump.lab"};
          reset = 1; # 17; reset = 0;
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

    // flush cache and halt on infinite loop at end of riscv-arch-test
    assign DCacheFlushStart = dut.hart.ifu.InstrM == 32'h6f && dut.hart.ieu.c.InstrValidM;
//  assign DCacheFlushStart = dut.hart.lsu.dcache.MemPAdrM[31:0] == 32'h80008000 & 
//            dut.hart.lsu.dcache.MemRWM == 2'b01;

/*  assign DCacheFlushStart = dut.hart.priv.EcallFaultM && 
			    (dut.hart.ieu.dp.regf.rf[3] == 1 || 
			     (dut.hart.ieu.dp.regf.we3 && 
			      dut.hart.ieu.dp.regf.a3 == 3 && 
			      dut.hart.ieu.dp.regf.wd3 == 1));
 */ 
  DCacheFlushFSM DCacheFlushFSM(.clk(clk),
				.reset(reset),
				.start(DCacheFlushStart),
				.done(DCacheFlushDone));
  

  generate
    // initialize the branch predictor
    if (`BPRED_ENABLED == 1) begin : bpred
      
      initial begin
	$readmemb(`TWO_BIT_PRELOAD, dut.hart.ifu.bpred.bpred.Predictor.DirPredictor.PHT.memory);
	$readmemb(`BTB_PRELOAD, dut.hart.ifu.bpred.bpred.TargetPredictor.memory.memory);    
      end
    end
  endgenerate
  
endmodule

module riscvassertions();
  // Legal number of PMP entries are 0, 16, or 64
  initial begin
    assert (`PMP_ENTRIES == 0 || `PMP_ENTRIES==16 || `PMP_ENTRIES==64) else $error("Illegal number of PMP entries: PMP_ENTRIES must be 0, 16, or 64");
    assert (`F_SUPPORTED || ~`D_SUPPORTED) else $error("Can't support double without supporting float");
    assert (`XLEN == 64 || ~`D_SUPPORTED) else $error("Wally does not yet support D extensions on RV32");
    assert (`DCACHE_WAYSIZEINBYTES <= 4096 || `MEM_DCACHE == 0 || `MEM_VIRTMEM == 0) else $error("DCACHE_WAYSIZEINBYTES cannot exceed 4 KiB when caches and vitual memory is enabled (to prevent aliasing)");
    assert (`DCACHE_BLOCKLENINBITS >= 128 || `MEM_DCACHE == 0) else $error("DCACHE_BLOCKLENINBITS must be at least 128 when caches are enabled");
    assert (`DCACHE_BLOCKLENINBITS < `DCACHE_WAYSIZEINBYTES*8) else $error("DCACHE_BLOCKLENINBITS must be smaller than way size");
    assert (`ICACHE_WAYSIZEINBYTES <= 4096 || `MEM_ICACHE == 0 || `MEM_VIRTMEM == 0) else $error("ICACHE_WAYSIZEINBYTES cannot exceed 4 KiB when caches and vitual memory is enabled (to prevent aliasing)");
    assert (`ICACHE_BLOCKLENINBITS >= 32 || `MEM_ICACHE == 0) else $error("ICACHE_BLOCKLENINBITS must be at least 32 when caches are enabled");
    assert (`ICACHE_BLOCKLENINBITS < `ICACHE_WAYSIZEINBYTES*8) else $error("ICACHE_BLOCKLENINBITS must be smaller than way size");
    assert (2**$clog2(`DCACHE_BLOCKLENINBITS) == `DCACHE_BLOCKLENINBITS) else $error("DCACHE_BLOCKLENINBITS must be a power of 2");
    assert (2**$clog2(`DCACHE_WAYSIZEINBYTES) == `DCACHE_WAYSIZEINBYTES) else $error("DCACHE_WAYSIZEINBYTES must be a power of 2");
    assert (2**$clog2(`ICACHE_BLOCKLENINBITS) == `ICACHE_BLOCKLENINBITS) else $error("ICACHE_BLOCKLENINBITS must be a power of 2");
    assert (2**$clog2(`ICACHE_WAYSIZEINBYTES) == `ICACHE_WAYSIZEINBYTES) else $error("ICACHE_WAYSIZEINBYTES must be a power of 2");
    assert (`ICACHE_NUMWAYS == 1 || `MEM_ICACHE == 0) else $warning("Multiple Instruction Cache ways not yet implemented");
    assert (2**$clog2(`ITLB_ENTRIES) == `ITLB_ENTRIES) else $error("ITLB_ENTRIES must be a power of 2");
    assert (2**$clog2(`DTLB_ENTRIES) == `DTLB_ENTRIES) else $error("DTLB_ENTRIES must be a power of 2");
    assert (`TIM_RANGE >= 56'h07FFFFFF) else $error("Some regression tests will fail if TIM_RANGE is less than 56'h07FFFFFF");
  end
endmodule


/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */

module DCacheFlushFSM
  (input logic clk,
   input logic reset,
   input logic start,
   output logic done);

  localparam integer numlines = testbench.dut.hart.lsu.dcache.NUMLINES;
  localparam integer numways = testbench.dut.hart.lsu.dcache.NUMWAYS;
  localparam integer blockbytelen = testbench.dut.hart.lsu.dcache.BLOCKBYTELEN;
  localparam integer numwords = testbench.dut.hart.lsu.dcache.BLOCKLEN/`XLEN;  
  localparam integer lognumlines = $clog2(numlines);
  localparam integer logblockbytelen = $clog2(blockbytelen);
  localparam integer lognumways = $clog2(numways);
  localparam integer tagstart = lognumlines + logblockbytelen;



  genvar index, way, cacheWord;
  logic [`XLEN-1:0]  CacheData [numways-1:0] [numlines-1:0] [numwords-1:0];
  logic [`XLEN-1:0]  CacheTag [numways-1:0] [numlines-1:0] [numwords-1:0];
  logic CacheValid  [numways-1:0] [numlines-1:0] [numwords-1:0];
  logic CacheDirty  [numways-1:0] [numlines-1:0] [numwords-1:0];
  logic [`PA_BITS-1:0] CacheAdr [numways-1:0] [numlines-1:0] [numwords-1:0];
  genvar adr;

  logic [`XLEN-1:0] ShadowRAM[`TIM_BASE>>(1+`XLEN/32):(`TIM_RANGE+`TIM_BASE)>>1+(`XLEN/32)];
  
  generate
    for(index = 0; index < numlines; index++) begin
      for(way = 0; way < numways; way++) begin
	for(cacheWord = 0; cacheWord < numwords; cacheWord++) begin
	  copyShadow #(.tagstart(tagstart),
		       .logblockbytelen(logblockbytelen))
	  copyShadow(.clk,
		     .start,
		     .tag(testbench.dut.hart.lsu.dcache.MemWay[way].CacheTagMem.StoredData[index]),
		     .valid(testbench.dut.hart.lsu.dcache.MemWay[way].ValidBits[index]),
		     .dirty(testbench.dut.hart.lsu.dcache.MemWay[way].DirtyBits[index]),
		     .data(testbench.dut.hart.lsu.dcache.MemWay[way].word[cacheWord].CacheDataMem.StoredData[index]),
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
  endgenerate

  integer i, j, k;
  
  always @(posedge clk) begin
    if (start) begin #1
      #1
      for(i = 0; i < numlines; i++) begin
	for(j = 0; j < numways; j++) begin
	  for(k = 0; k < numwords; k++) begin
	  if (CacheValid[j][i][k] && CacheDirty[j][i][k]) begin
	    ShadowRAM[CacheAdr[j][i][k] >> $clog2(`XLEN/8)] = CacheData[j][i][k];
	    end
	  end	
	end
      end
    end
  end


  flop #(1) doneReg(.clk(clk),
		    .d(start),
		    .q(done));
		    
endmodule

module copyShadow
  #(parameter tagstart, logblockbytelen)
  (input logic clk,
   input logic 			     start,
   input logic [`PA_BITS-1:tagstart] tag,
   input logic 			     valid, dirty,
   input logic [`XLEN-1:0] 	     data,
   input logic [32-1:0] 	     index,
   input logic [32-1:0] 	     cacheWord,
   output logic [`XLEN-1:0] 	     CacheData,
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
      CacheAdr = (tag << tagstart) + (index << logblockbytelen) + (cacheWord << $clog2(`XLEN/8));
    end
  end
  
endmodule		      

