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
  parameter TESTSPERIPH = 0; // set to 0 for regression
  
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
    "rv32mmu/WALLY-VIRTUALMEMORY", "5000"
  };

  string tests64mmu[] = '{
    "rv64mmu/WALLY-VIRTUALMEMORY", "2000"
  };

  
string tests32f[] = '{
    "rv32f/I-FADD-S-01", "2000",
    "rv32f/I-FCLASS-S-01", "2000",
    "rv32f/I-FCVT-S-L-01", "2000",
    "rv32f/I-FCVT-S-LU-01", "2000",
    "rv32f/I-FCVT-S-W-01", "2000",
    "rv32f/I-FCVT-S-WU-01", "2000",
    "rv32f/I-FCVT-L-S-01", "2000",
    "rv32f/I-FCVT-LU-S-01", "2000",
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
    "rv32f/I-FLW-01", "2000",
    "rv32f/I-FSUB-S-01", "2000"
  };

  string tests64f[] = '{
    "rv64f/I-FADD-S-01", "2000",
    "rv64f/I-FCLASS-S-01", "2000",
    "rv64f/I-FCVT-S-L-01", "2000",
    "rv64f/I-FCVT-S-LU-01", "2000",
    "rv64f/I-FCVT-S-W-01", "2000",
    "rv64f/I-FCVT-S-WU-01", "2000",
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
    "rv64f/I-FMV-W-X-01", "2000",
    "rv64f/I-FNMADD-S-01", "2000",
    "rv64f/I-FNMSUB-S-01", "2000",
    "rv64f/I-FSGNJ-S-01", "2000",
    "rv64f/I-FSGNJN-S-01", "2000",
    "rv64f/I-FSGNJX-S-01", "2000",
    "rv64f/I-FSQRT-S-01", "2000",
    "rv64f/I-FSW-01", "2000",
    "rv64f/I-FLW-01", "2000",
    "rv64f/I-FSUB-S-01", "2000"
  };

  string tests64d[] = '{
    "rv64d/I-FMV-D-X-01", "2000",
    // "rv64d/I-FADD-D-01", "2000",
    // "rv64d/I-FCLASS-D-01", "2000",
    // "rv64d/I-FCVT-D-L-01", "2000",
    // "rv64d/I-FCVT-D-LU-01", "2000",
    // "rv64d/I-FCVT-D-S-01", "2000",
    // "rv64d/I-FCVT-D-W-01", "2000",
    // "rv64d/I-FCVT-D-WU-01", "2000",
    // "rv64d/I-FCVT-L-D-01", "2000",
    // "rv64d/I-FCVT-LU-D-01", "2000",
    // "rv64d/I-FCVT-S-D-01", "2000",
    // "rv64d/I-FCVT-W-D-01", "2000",
    // "rv64d/I-FCVT-WU-D-01", "2000",
    // "rv64d/I-FDIV-D-01", "2000",
    // "rv64d/I-FEQ-D-01", "2000",
    "rv64d/I-FLD-D-01", "2000"
    // "rv64d/I-FLE-D-01", "2000",
    // "rv64d/I-FLT-D-01", "2000",
    // "rv64d/I-FMADD-D-01", "2000",
    // "rv64d/I-FMAX-D-01", "2000",
    // "rv64d/I-FMIN-D-01", "2000",
    // "rv64d/I-FMSUB-D-01", "2000",
    // "rv64d/I-FMUL-D-01", "2000",
    // "rv64d/I-FMV-X-D-01", "2000",
    // "rv64d/I-FNMADD-D-01", "2000",
    // "rv64d/I-FNMSUB-D-01", "2000",
    //"rv64d/I-FSD-01", "2000"
    // "rv64d/I-FSGNJ-D-01", "2000",
    // "rv64d/I-FSGNJN-D-01", "2000",
    // "rv64d/I-FSGNJX-D-01", "2000",
    // "rv64d/I-FSQRTD-01", "2000",
    // "rv64d/I-FSUB-D-01", "2000"
  };

  string tests64a[] = '{
    "rv64a/WALLY-AMO", "2110",
    "rv64a/WALLY-LRSC", "2110"
  };

  string tests64m[] = '{
    "rv64m/I-MUL-01", "3000",
    "rv64m/I-MULH-01", "3000",
    "rv64m/I-MULHSU-01", "3000",
    "rv64m/I-MULHU-01", "3000",
    "rv64m/I-MULW-01", "3000",
    //"rv64m/I-DIV-01", "3000",
    "rv64m/I-DIVU-01", "3000",
    //"rv64m/I-DIVUW-01", "3000",
    //"rv64m/I-DIVW-01", "3000",
    //"rv64m/I-REM-01", "3000",
    "rv64m/I-REMU-01", "3000"
    //"rv64m/I-REMUW-01", "3000",
    //"rv64m/I-REMW-01", "3000"
  };

  string tests64ic[] = '{
    "rv64ic/I-C-ADD-01", "3000",
    "rv64ic/I-C-ADDI-01", "3000",
    "rv64ic/I-C-ADDIW-01", "3000",
    "rv64ic/I-C-ADDW-01", "3000",
    "rv64ic/I-C-AND-01", "3000",
    "rv64ic/I-C-ANDI-01", "3000",
    "rv64ic/I-C-BEQZ-01", "3000",
    "rv64ic/I-C-BNEZ-01", "3000",
    "rv64ic/I-C-EBREAK-01", "2000",
    "rv64ic/I-C-J-01", "3000",
    "rv64ic/I-C-JALR-01", "4000",
    "rv64ic/I-C-JR-01", "4000",
    "rv64ic/I-C-LD-01", "3420",
    "rv64ic/I-C-LDSP-01", "3420",
    "rv64ic/I-C-LI-01", "3000",
    "rv64ic/I-C-LUI-01", "2000",
    "rv64ic/I-C-LW-01", "3110",
    "rv64ic/I-C-LWSP-01", "3110",
    "rv64ic/I-C-MV-01", "3000",
    "rv64ic/I-C-NOP-01", "2000",
    "rv64ic/I-C-OR-01", "3000",
    "rv64ic/I-C-SD-01", "3000",
    "rv64ic/I-C-SDSP-01", "3000",
    "rv64ic/I-C-SLLI-01", "3000",
    "rv64ic/I-C-SRAI-01", "3000",
    "rv64ic/I-C-SRLI-01", "3000",
    "rv64ic/I-C-SUB-01", "3000",
    "rv64ic/I-C-SUBW-01", "3000",
    "rv64ic/I-C-SW-01", "3000",
    "rv64ic/I-C-SWSP-01", "3000",
    "rv64ic/I-C-XOR-01", "3000"
  };

  string tests64iNOc[] = {
    "rv64i/I-MISALIGN_JMP-01","2000"
  };

  string tests64i[] = '{
    "rv64i/WALLY-PIPELINE-100K", "f7ff0",
    "rv64i/I-ADD-01", "3000",
    "rv64i/I-ADDI-01", "3000",
    "rv64i/I-ADDIW-01", "3000",
    "rv64i/I-ADDW-01", "3000",
    "rv64i/I-AND-01", "3000",
    "rv64i/I-ANDI-01", "3000",
    "rv64i/I-AUIPC-01", "3000",
    "rv64i/I-BEQ-01", "4000",
    "rv64i/I-BGE-01", "4000",
    "rv64i/I-BGEU-01", "4000",
    "rv64i/I-BLT-01", "4000",
    "rv64i/I-BLTU-01", "4000",
    "rv64i/I-BNE-01", "4000",
    "rv64i/I-DELAY_SLOTS-01", "2000",
    "rv64i/I-EBREAK-01", "2000",
    "rv64i/I-ECALL-01", "2000",
    "rv64i/I-ENDIANESS-01", "2010",
    "rv64i/I-IO-01", "2050",
    "rv64i/I-JAL-01", "3000",
    "rv64i/I-JALR-01", "4000",
    "rv64i/I-LB-01", "4020",
    "rv64i/I-LBU-01", "4020",
    "rv64i/I-LD-01", "4420",
    "rv64i/I-LH-01", "4050",
    "rv64i/I-LHU-01", "4050",
    "rv64i/I-LUI-01", "2000",
    "rv64i/I-LW-01", "4110",
    "rv64i/I-LWU-01", "4110", 
    "rv64i/I-MISALIGN_LDST-01", "2010",
    "rv64i/I-NOP-01", "2000",
    "rv64i/I-OR-01", "3000",
    "rv64i/I-ORI-01", "3000",
    "rv64i/I-RF_size-01", "2000",
    "rv64i/I-RF_width-01", "2000",
    "rv64i/I-RF_x0-01", "2010",
    "rv64i/I-SB-01", "4000",
    "rv64i/I-SD-01", "4000",
    "rv64i/I-SH-01", "4000",
    "rv64i/I-SLL-01", "3000",
    "rv64i/I-SLLI-01", "3000",
    "rv64i/I-SLLIW-01", "3000",
    "rv64i/I-SLLW-01", "3000",
    "rv64i/I-SLT-01", "3000",
    "rv64i/I-SLTI-01", "3000",
    "rv64i/I-SLTIU-01", "3000",
    "rv64i/I-SLTU-01", "3000",
    "rv64i/I-SRA-01", "3000",
    "rv64i/I-SRAI-01", "3000",
    "rv64i/I-SRAIW-01", "3000",
    "rv64i/I-SRAW-01", "3000",
    "rv64i/I-SRL-01", "3000",
    "rv64i/I-SRLI-01", "3000",
    "rv64i/I-SRLIW-01", "3000",
    "rv64i/I-SRLW-01", "3000",
    "rv64i/I-SUB-01", "3000",
    "rv64i/I-SUBW-01", "3000",
    "rv64i/I-SW-01", "4000",
    "rv64i/I-XOR-01", "3000",
    "rv64i/I-XORI-01", "3000",
    "rv64i/WALLY-ADD", "4000",
    "rv64i/WALLY-SUB", "4000",
    "rv64i/WALLY-ADDI", "3000",
    "rv64i/WALLY-ANDI", "3000",
    "rv64i/WALLY-ORI", "3000",
    "rv64i/WALLY-XORI", "3000",
    "rv64i/WALLY-SLTI", "3000",
    "rv64i/WALLY-SLTIU", "3000",
    "rv64i/WALLY-SLLI", "3000",
    "rv64i/WALLY-SRLI", "3000",
    "rv64i/WALLY-SRAI", "3000",
    "rv64i/WALLY-LOAD", "11bf0",
    "rv64i/WALLY-JAL", "4000",
    "rv64i/WALLY-JALR", "3000",
    "rv64i/WALLY-STORE", "3000",
    "rv64i/WALLY-ADDIW", "3000",
    "rv64i/WALLY-SLLIW", "3000",
    "rv64i/WALLY-SRLIW", "3000",
    "rv64i/WALLY-SRAIW", "3000",
    "rv64i/WALLY-ADDW", "4000",
    "rv64i/WALLY-SUBW", "4000",
    "rv64i/WALLY-SLLW", "3000",
    "rv64i/WALLY-SRLW", "3000",
    "rv64i/WALLY-SRAW", "3000",
    "rv64i/WALLY-BEQ" ,"5000",
    "rv64i/WALLY-BNE", "5000 ",
    "rv64i/WALLY-BLTU", "5000 ",
    "rv64i/WALLY-BLT", "5000",
    "rv64i/WALLY-BGE", "5000 ",
    "rv64i/WALLY-BGEU", "5000 ",
    "rv64i/WALLY-CSRRW", "4000",
    "rv64i/WALLY-CSRRS", "4000",
    "rv64i/WALLY-CSRRC", "5000",
    "rv64i/WALLY-CSRRWI", "4000",
    "rv64i/WALLY-CSRRSI", "4000",
    "rv64i/WALLY-CSRRCI", "4000"
  };

  string tests32a[] = '{
    "rv64a/WALLY-AMO", "2110",
    "rv64a/WALLY-LRSC", "2110"
  };

  string tests32m[] = '{
    "rv32m/I-MUL-01", "2000",
    "rv32m/I-MULH-01", "2000",
    "rv32m/I-MULHSU-01", "2000",
    "rv32m/I-MULHU-01", "2000"
    //"rv32m/I-DIV-01", "2000",
    //"rv32m/I-DIVU-01", "2000",
    //"rv32m/I-REM-01", "2000",
    //"rv32m/I-REMU-01", "2000"
  };

  string tests32ic[] = '{
    "rv32ic/I-C-ADD-01", "2000",
    "rv32ic/I-C-ADDI-01", "2000",
    "rv32ic/I-C-AND-01", "2000",
    "rv32ic/I-C-ANDI-01", "2000",
    "rv32ic/I-C-BEQZ-01", "2000",
    "rv32ic/I-C-BNEZ-01", "2000",
    "rv32ic/I-C-EBREAK-01", "2000",
    "rv32ic/I-C-J-01", "2000",
    "rv32ic/I-C-JALR-01", "3000",
    "rv32ic/I-C-JR-01", "3000",
    "rv32ic/I-C-LI-01", "2000",
    "rv32ic/I-C-LUI-01", "2000",
    "rv32ic/I-C-LW-01", "2110",
    "rv32ic/I-C-LWSP-01", "2110",
    "rv32ic/I-C-MV-01", "2000",
    "rv32ic/I-C-NOP-01", "2000",
    "rv32ic/I-C-OR-01", "2000",
    "rv32ic/I-C-SLLI-01", "2000",
    "rv32ic/I-C-SRAI-01", "2000",
    "rv32ic/I-C-SRLI-01", "2000",
    "rv32ic/I-C-SUB-01", "2000",
    "rv32ic/I-C-SW-01", "2000",
    "rv32ic/I-C-SWSP-01", "2000",
    "rv32ic/I-C-XOR-01", "2000"
  };

  string tests32iNOc[] = {
    "rv32i/I-MISALIGN_JMP-01","2000"
  };

  string tests32i[] = {
    "rv32i/WALLY-PIPELINE-100K", "10a800",
    "rv32i/I-ADD-01", "2000",
    "rv32i/I-ADDI-01","2000",
    "rv32i/I-AND-01","2000",
    "rv32i/I-ANDI-01","2000",
    "rv32i/I-AUIPC-01","2000",
    "rv32i/I-BEQ-01","3000",
    "rv32i/I-BGE-01","3000",
    "rv32i/I-BGEU-01","3000",
    "rv32i/I-BLT-01","3000",
    "rv32i/I-BLTU-01","3000",
    "rv32i/I-BNE-01","3000",
    "rv32i/I-DELAY_SLOTS-01","2000",
    "rv32i/I-EBREAK-01","2000",
    "rv32i/I-ECALL-01","2000",
    "rv32i/I-ENDIANESS-01","2010",
    "rv32i/I-IO-01","2030rv",
    "rv32i/I-JAL-01","3000",
    "rv32i/I-JALR-01","3000",
    "rv32i/I-LB-01","3020",
    "rv32i/I-LBU-01","3020",
    "rv32i/I-LH-01","3050",
    "rv32i/I-LHU-01","3050",
    "rv32i/I-LUI-01","2000",
    "rv32i/I-LW-01","3110",
    "rv32i/I-MISALIGN_LDST-01","2010",
    "rv32i/I-NOP-01","2000",
    "rv32i/I-OR-01","2000",
    "rv32i/I-ORI-01","2000",
    "rv32i/I-RF_size-01","2000",
    "rv32i/I-RF_width-01","2000",
    "rv32i/I-RF_x0-01","2010",
    "rv32i/I-SB-01","3000",
    "rv32i/I-SH-01","3000",
    "rv32i/I-SLL-01","2000",
    "rv32i/I-SLLI-01","2000",
    "rv32i/I-SLT-01","2000",
    "rv32i/I-SLTI-01","2000",
    "rv32i/I-SLTIU-01","2000",
    "rv32i/I-SLTU-01","2000",
    "rv32i/I-SRA-01","2000",
    "rv32i/I-SRAI-01","2000",
    "rv32i/I-SRL-01","2000",
    "rv32i/I-SRLI-01","2000",
    "rv32i/I-SUB-01","2000",
    "rv32i/I-SW-01","3000",
    "rv32i/I-XOR-01","2000",
    "rv32i/I-XORI-01","2000",
    "rv32i/WALLY-ADD", "3000",
    "rv32i/WALLY-SUB", "3000",
    "rv32i/WALLY-ADDI", "2000",
    "rv32i/WALLY-ANDI", "2000",
    "rv32i/WALLY-ORI", "2000",
    "rv32i/WALLY-XORI", "2000",
    "rv32i/WALLY-SLTI", "2000",
    "rv32i/WALLY-SLTIU", "2000",
    "rv32i/WALLY-SLLI", "2000",
    "rv32i/WALLY-SRLI", "2000",
    "rv32i/WALLY-SRAI", "2000",
    "rv32i/WALLY-LOAD", "11c00",
    "rv32i/WALLY-SUB", "3000",
    "rv32i/WALLY-STORE", "2000",
    "rv32i/WALLY-JAL", "3000",
    "rv32i/WALLY-JALR", "2000",
    "rv32i/WALLY-BEQ" ,"4000",
    "rv32i/WALLY-BNE", "4000 ",
    "rv32i/WALLY-BLTU", "4000 ",
    "rv32i/WALLY-BLT", "4000",
    "rv32i/WALLY-BGE", "4000 ",
    "rv32i/WALLY-BGEU", "4000 ",
    "rv32i/WALLY-CSRRW", "3000",
    "rv32i/WALLY-CSRRS", "3000",
    "rv32i/WALLY-CSRRC", "4000",
    "rv32i/WALLY-CSRRWI", "3000",
    "rv32i/WALLY-CSRRSI", "3000",
    "rv32i/WALLY-CSRRCI", "3000"
  };

  string testsBP64[] = '{
    "rv64BP/simple", "10000",
    "rv64BP/qsort", "1000000",
    "rv64BP/sieve", "1000000"
  };

  string tests64p[] = '{
    //"rv64p/WALLY-MSTATUS", "2010",
    "rv64p/WALLY-MCAUSE", "3000",
    "rv64p/WALLY-SCAUSE", "2000",
    "rv64p/WALLY-MEPC", "5000",
    "rv64p/WALLY-SEPC", "4000",
    "rv64p/WALLY-MTVAL", "6000",
    "rv64p/WALLY-STVAL", "4000",
    "rv64p/WALLY-MTVEC", "2000",
    "rv64p/WALLY-STVEC", "2000",
    "rv64p/WALLY-MARCHID", "4000",
    "rv64p/WALLY-MIMPID", "4000",
    "rv64p/WALLY-MHARTID", "4000",
    "rv64p/WALLY-MVENDORID", "4000",
    "rv64p/WALLY-MIE", "3000",
    "rv64p/WALLY-MEDELEG", "4000",
    "rv64p/WALLY-IP", "2000",
    "rv64p/WALLY-CSR-PERMISSIONS-M", "5000",
    "rv64p/WALLY-CSR-PERMISSIONS-S", "3000"
  };

  string tests32p[] = '{
    "rv32p/WALLY-MCAUSE", "3000",
    "rv32p/WALLY-SCAUSE", "2000",
    "rv32p/WALLY-MEPC", "5000",
    "rv32p/WALLY-SEPC", "4000",
    "rv32p/WALLY-MTVAL", "5000",
    "rv32p/WALLY-STVAL", "4000",
    "rv32p/WALLY-MARCHID", "4000",
    "rv32p/WALLY-MIMPID", "4000",
    "rv32p/WALLY-MHARTID", "4000",
    "rv32p/WALLY-MVENDORID", "4000",
    "rv32p/WALLY-MTVEC", "2000",
    "rv32p/WALLY-STVEC", "2000",
    "rv32p/WALLY-MIE", "3000",
    "rv32p/WALLY-MEDELEG", "4000",
    "rv32p/WALLY-IP", "3000",
    "rv32p/WALLY-CSR-PERMISSIONS-M", "5000",
    "rv32p/WALLY-CSR-PERMISSIONS-S", "3000"
  };

  string tests64periph[] = '{
    "rv64i-periph/WALLY-PLIC", "2000"
  };

  string tests32periph[] = '{
    "rv32i-periph/WALLY-PLIC", "2080"
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
  
  flopenr #(`XLEN) PCWReg(clk, reset, ~dut.hart.ieu.dp.StallW, dut.hart.ifu.PCM, PCW);
  flopenr  #(32)   InstrWReg(clk, reset, ~dut.hart.ieu.dp.StallW,  dut.hart.ifu.InstrM, InstrW);
  // pick tests based on modes supported
  initial begin
    if (`XLEN == 64) begin // RV64
      if (`TESTSBP) begin
        tests = {testsBP64,tests64p};
      end if (TESTSPERIPH) begin 
        tests = tests64periph;
      end else begin 
        tests = {tests64p,tests64i,tests64periph};
        if (`C_SUPPORTED) tests = {tests, tests64ic};
        else              tests = {tests, tests64iNOc};
        if (`M_SUPPORTED) tests = {tests, tests64m};
        if (`A_SUPPORTED) tests = {tests, tests64a};
        if (`MEM_VIRTMEM) tests = {tests, tests64mmu};
        // if (`F_SUPPORTED) tests = {tests64f, tests};
        if (`D_SUPPORTED) tests = {tests64d, tests};
      end
      //tests = {tests64a, tests};
    end else begin // RV32
      // *** add the 32 bit bp tests
      if (TESTSPERIPH) begin 
        tests = tests32periph;
      end else begin
          tests = {tests32i, tests32p};//,tests32periph}; *** broken at the moment
          if (`C_SUPPORTED % 2 == 1) tests = {tests, tests32ic};    
          else                       tests = {tests, tests32iNOc};
          if (`M_SUPPORTED % 2 == 1) tests = {tests, tests32m};
          // if (`F_SUPPORTED) tests = {tests32f, tests};
          if (`A_SUPPORTED) tests = {tests, tests32a};
          if (`MEM_VIRTMEM) tests = {tests, tests32mmu};
      end
    end
  end

  string signame, memfilename;

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
                dut.hart.ifu.icache.controller.FinalInstrRawF,
                dut.hart.ifu.InstrD, dut.hart.ifu.InstrE,
                dut.hart.ifu.InstrM,  dut.hart.ifu.InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // initialize tests
  localparam integer 	   MemStartAddr = `TIMBASE>>(1+`XLEN/32);
  localparam integer 	   MemEndAddr = (`TIMRANGE+`TIMBASE)>>1+(`XLEN/32);

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
      /*for (i=MemStartAddr; i<MemEndAddr; i = i+1) begin
	      dut.uncore.dtim.RAM[i] = meminit;
      end*/
      // read test vectors into memory
      memfilename = {"../../imperas-riscv-tests/work/", tests[test], ".elf.memfile"};
      $readmemh(memfilename, dut.uncore.dtim.RAM);
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
        for(i=0; i<SIGNATURESIZE; i=i+1) begin
          sig32[i] = 'bx;
        end

        // read signature, reformat in 64 bits if necessary
        signame = {"../../imperas-riscv-tests/work/", tests[test], ".signature.output"};
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
        if (`XLEN == 32)
          testadr = (`TIMBASE+tests[test+1].atohex())/4;
        else
          testadr = (`TIMBASE+tests[test+1].atohex())/8;
        /* verilator lint_off INFINITELOOP */
        while (signature[i] !== 'bx) begin
          //$display("signature[%h] = %h", i, signature[i]);
          if (signature[i] !== dut.uncore.dtim.RAM[testadr+i]) begin
            if (signature[i+4] !== 'bx || signature[i] !== 32'hFFFFFFFF) begin
              // report errors unless they are garbage at the end of the sim
              // kind of hacky test for garbage right now
              errors = errors+1;
              $display("  Error on test %s result %d: adr = %h sim = %h, signature = %h", 
                    tests[test], i, (testadr+i)*`XLEN/8, dut.uncore.dtim.RAM[testadr+i], signature[i]);
              $stop;//***debug
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
          $readmemh(memfilename, dut.uncore.dtim.RAM);
          $display("Read memfile %s", memfilename);
	  ProgramAddrMapFile = {"../../imperas-riscv-tests/work/", tests[test], ".elf.objdump.addr"};
	  ProgramLabelMapFile = {"../../imperas-riscv-tests/work/", tests[test], ".elf.objdump.lab"};
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

/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */

module instrTrackerTB(
  input  logic            clk, reset, FlushE,
  input  logic [31:0]     InstrF, InstrD,
  input  logic [31:0]     InstrE, InstrM,
  input  logic [31:0]     InstrW,
//  output logic [31:0]     InstrW,
  output string           InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);
        
  // stage Instr to Writeback for visualization
  // flopr  #(32) InstrWReg(clk, reset, InstrM, InstrW);

  instrNameDecTB fdec(InstrF, InstrFName);
  instrNameDecTB ddec(InstrD, InstrDName);
  instrNameDecTB edec(InstrE, InstrEName);
  instrNameDecTB mdec(InstrM, InstrMName);
  instrNameDecTB wdec(InstrW, InstrWName);
endmodule

// decode the instruction name, to help the test bench
module instrNameDecTB(
  input  logic [31:0] instr,
  output string       name);

  logic [6:0] op;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [11:0] imm;
  logic [4:0] rs2;

  assign op = instr[6:0];
  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];
  assign imm = instr[31:20];
  assign rs2 = instr[24:20];

  // it would be nice to add the operands to the name 
  // create another variable called decoded

  always_comb 
    casez({op, funct3})
      10'b0000000_000: name = "BAD";
      10'b0000011_000: name = "LB";
      10'b0000011_001: name = "LH";
      10'b0000011_010: name = "LW";
      10'b0000011_011: name = "LD";
      10'b0000011_100: name = "LBU";
      10'b0000011_101: name = "LHU";
      10'b0000011_110: name = "LWU";
      10'b0010011_000: if (instr[31:15] == 0 && instr[11:7] ==0) name = "NOP/FLUSH";
                       else                                      name = "ADDI";
      10'b0010011_001: if (funct7[6:1] == 6'b000000) name = "SLLI";
                       else                      name = "ILLEGAL";
      10'b0010011_010: name = "SLTI";
      10'b0010011_011: name = "SLTIU";
      10'b0010011_100: name = "XORI";
      10'b0010011_101: if (funct7[6:1] == 6'b000000)      name = "SRLI";
                       else if (funct7[6:1] == 6'b010000) name = "SRAI"; 
                       else                           name = "ILLEGAL"; 
      10'b0010011_110: name = "ORI";
      10'b0010011_111: name = "ANDI";
      10'b0010111_???: name = "AUIPC";
      10'b0100011_000: name = "SB";
      10'b0100011_001: name = "SH";
      10'b0100011_010: name = "SW";
      10'b0100011_011: name = "SD";
      10'b0011011_000: name = "ADDIW";
      10'b0011011_001: name = "SLLIW";
      10'b0011011_101: if      (funct7 == 7'b0000000) name = "SRLIW";
                       else if (funct7 == 7'b0100000) name = "SRAIW";
                       else                           name = "ILLEGAL";
      10'b0111011_000: if      (funct7 == 7'b0000000) name = "ADDW";
                       else if (funct7 == 7'b0100000) name = "SUBW";
                       else if (funct7 == 7'b0000001) name = "MULW";
                       else                           name = "ILLEGAL";
      10'b0111011_001: if      (funct7 == 7'b0000000) name = "SLLW";
                       else if (funct7 == 7'b0000001) name = "DIVW";
                       else                           name = "ILLEGAL";
      10'b0111011_101: if      (funct7 == 7'b0000000) name = "SRLW";
                       else if (funct7 == 7'b0100000) name = "SRAW";
                       else if (funct7 == 7'b0000001) name = "DIVUW";
                       else                           name = "ILLEGAL";
      10'b0111011_110: if      (funct7 == 7'b0000001) name = "REMW";
                       else                           name = "ILLEGAL";
      10'b0111011_111: if      (funct7 == 7'b0000001) name = "REMUW";
                       else                           name = "ILLEGAL";
      10'b0110011_000: if      (funct7 == 7'b0000000) name = "ADD";
                       else if (funct7 == 7'b0000001) name = "MUL";
                       else if (funct7 == 7'b0100000) name = "SUB"; 
                       else                           name = "ILLEGAL"; 
      10'b0110011_001: if      (funct7 == 7'b0000000) name = "SLL";
                       else if (funct7 == 7'b0000001) name = "MULH";
                       else                           name = "ILLEGAL";
      10'b0110011_010: if      (funct7 == 7'b0000000) name = "SLT";
                       else if (funct7 == 7'b0000001) name = "MULHSU";
                       else                           name = "ILLEGAL";
      10'b0110011_011: if      (funct7 == 7'b0000000) name = "SLTU";
                       else if (funct7 == 7'b0000001) name = "MULHU";
                       else                           name = "ILLEGAL";
      10'b0110011_100: if      (funct7 == 7'b0000000) name = "XOR";
                       else if (funct7 == 7'b0000001) name = "DIV";
                       else                           name = "ILLEGAL";
      10'b0110011_101: if      (funct7 == 7'b0000000) name = "SRL";
                       else if (funct7 == 7'b0000001) name = "DIVU";
                       else if (funct7 == 7'b0100000) name = "SRA";
                       else                           name = "ILLEGAL";
      10'b0110011_110: if      (funct7 == 7'b0000000) name = "OR";
                       else if (funct7 == 7'b0000001) name = "REM";
                       else                           name = "ILLEGAL";
      10'b0110011_111: if      (funct7 == 7'b0000000) name = "AND";
                       else if (funct7 == 7'b0000001) name = "REMU";
                       else                           name = "ILLEGAL";
      10'b0110111_???: name = "LUI";
      10'b1100011_000: name = "BEQ";
      10'b1100011_001: name = "BNE";
      10'b1100011_100: name = "BLT";
      10'b1100011_101: name = "BGE";
      10'b1100011_110: name = "BLTU";
      10'b1100011_111: name = "BGEU";
      10'b1100111_000: name = "JALR";
      10'b1101111_???: name = "JAL";
      10'b1110011_000: if      (imm == 0) name = "ECALL";
                       else if (imm == 1) name = "EBREAK";
                       else if (imm == 2) name = "URET";
                       else if (imm == 258) name = "SRET";
                       else if (imm == 770) name = "MRET";
                       else              name = "ILLEGAL";
      10'b1110011_001: name = "CSRRW";
      10'b1110011_010: name = "CSRRS";
      10'b1110011_011: name = "CSRRC";
      10'b1110011_101: name = "CSRRWI";
      10'b1110011_110: name = "CSRRSI";
      10'b1110011_111: name = "CSRRCI";
      10'b0101111_010: if      (funct7[6:2] == 5'b00010) name = "LR.W";
                       else if (funct7[6:2] == 5'b00011) name = "SC.W";
                       else if (funct7[6:2] == 5'b00001) name = "AMOSWAP.W";
                       else if (funct7[6:2] == 5'b00000) name = "AMOADD.W";
                       else if (funct7[6:2] == 5'b00100) name = "AMOAXOR.W";
                       else if (funct7[6:2] == 5'b01100) name = "AMOAND.W";
                       else if (funct7[6:2] == 5'b01000) name = "AMOOR.W";
                       else if (funct7[6:2] == 5'b10000) name = "AMOMIN.W";
                       else if (funct7[6:2] == 5'b10100) name = "AMOMAX.W";
                       else if (funct7[6:2] == 5'b11000) name = "AMOMINU.W";
                       else if (funct7[6:2] == 5'b11100) name = "AMOMAXU.W";
                       else                              name = "ILLEGAL";
      10'b0101111_011: if      (funct7[6:2] == 5'b00010) name = "LR.D";
                       else if (funct7[6:2] == 5'b00011) name = "SC.D";
                       else if (funct7[6:2] == 5'b00001) name = "AMOSWAP.D";
                       else if (funct7[6:2] == 5'b00000) name = "AMOADD.D";
                       else if (funct7[6:2] == 5'b00100) name = "AMOAXOR.D";
                       else if (funct7[6:2] == 5'b01100) name = "AMOAND.D";
                       else if (funct7[6:2] == 5'b01000) name = "AMOOR.D";
                       else if (funct7[6:2] == 5'b10000) name = "AMOMIN.D";
                       else if (funct7[6:2] == 5'b10100) name = "AMOMAX.D";
                       else if (funct7[6:2] == 5'b11000) name = "AMOMINU.D";
                       else if (funct7[6:2] == 5'b11100) name = "AMOMAXU.D";
                       else                              name = "ILLEGAL";
      10'b0001111_???: name = "FENCE";
      10'b1000011_???: name = "FMADD";
      10'b1000111_???: name = "FMSUB";
      10'b1001011_???: name = "FNMSUB";
      10'b1001111_???: name = "FNMADD";
      10'b1010011_000: if      (funct7[6:2] == 5'b00000) name = "FADD";
                       else if (funct7[6:2] == 5'b00001) name = "FSUB";
                       else if (funct7[6:2] == 5'b00010) name = "FMUL";
                       else if (funct7[6:2] == 5'b00011) name = "FDIV";
                       else if (funct7[6:2] == 5'b01011) name = "FSQRT";
                       else if (funct7 == 7'b1100000 && rs2 == 5'b00000) name = "FCVT.W.S";
                       else if (funct7 == 7'b1100000 && rs2 == 5'b00001) name = "FCVT.WU.S";
                       else if (funct7 == 7'b1101000 && rs2 == 5'b00000) name = "FCVT.S.W";
                       else if (funct7 == 7'b1101000 && rs2 == 5'b00001) name = "FCVT.S.WU";
                       else if (funct7 == 7'b1110000 && rs2 == 5'b00000) name = "FMV.X.W";
                       else if (funct7 == 7'b1111000 && rs2 == 5'b00000) name = "FMV.W.X";
                       else if (funct7 == 7'b1110001 && rs2 == 5'b00000) name = "FMV.X.W"; // DOUBLE
                       else if (funct7 == 7'b1111001 && rs2 == 5'b00000) name = "FMV.W.X"; // DOUBLE
                       else if (funct7[6:2] == 5'b00100) name = "FSGNJ";
                       else if (funct7[6:2] == 5'b00101) name = "FMIN";
                       else if (funct7[6:2] == 5'b10100) name = "FLE";
                       else                              name = "ILLEGAL";
      10'b1010011_001: if      (funct7[6:2] == 5'b00000) name = "FADD";
                       else if (funct7[6:2] == 5'b00001) name = "FSUB";
                       else if (funct7[6:2] == 5'b00010) name = "FMUL";
                       else if (funct7[6:2] == 5'b00011) name = "FDIV";
                       else if (funct7[6:2] == 5'b01011) name = "FSQRT";
                       else if (funct7 == 7'b1100000 && rs2 == 5'b00000) name = "FCVT.W.S";
                       else if (funct7 == 7'b1100000 && rs2 == 5'b00001) name = "FCVT.WU.S";
                       else if (funct7 == 7'b1101000 && rs2 == 5'b00000) name = "FCVT.S.W";
                       else if (funct7 == 7'b1101000 && rs2 == 5'b00001) name = "FCVT.S.WU";
                       else if (funct7[6:2] == 5'b00100) name = "FSGNJN";
                       else if (funct7[6:2] == 5'b00101) name = "FMAX";
                       else if (funct7[6:2] == 5'b10100) name = "FLT";
                       else if (funct7[6:2] == 5'b11100) name = "FCLASS";
                       else                              name = "ILLEGAL";
      10'b0101111_010: if      (funct7[6:2] == 5'b00000) name = "FADD";
                       else if (funct7[6:2] == 5'b00001) name = "FSUB";
                       else if (funct7[6:2] == 5'b00010) name = "FMUL";
                       else if (funct7[6:2] == 5'b00011) name = "FDIV";
                       else if (funct7[6:2] == 5'b01011) name = "FSQRT";
                       else if (funct7 == 7'b1100000 && rs2 == 5'b00000) name = "FCVT.W.S";
                       else if (funct7 == 7'b1100000 && rs2 == 5'b00001) name = "FCVT.WU.S";
                       else if (funct7 == 7'b1101000 && rs2 == 5'b00000) name = "FCVT.S.W";
                       else if (funct7 == 7'b1101000 && rs2 == 5'b00001) name = "FCVT.S.WU";
                       else if (funct7[6:2] == 5'b00100) name = "FSGNJX";
                       else if (funct7[6:2] == 5'b10100) name = "FEQ";
                       else                              name = "ILLEGAL";
      10'b1010011_???: if      (funct7[6:2] == 5'b00000) name = "FADD";
                       else if (funct7[6:2] == 5'b00001) name = "FSUB";
                       else if (funct7[6:2] == 5'b00010) name = "FMUL";
                       else if (funct7[6:2] == 5'b00011) name = "FDIV";
                       else if (funct7[6:2] == 5'b01011) name = "FSQRT";
                       else if (funct7 == 7'b1100000 && rs2 == 5'b00000) name = "FCVT.W.S";
                       else if (funct7 == 7'b1100000 && rs2 == 5'b00001) name = "FCVT.WU.S";
                       else if (funct7 == 7'b1101000 && rs2 == 5'b00000) name = "FCVT.S.W";
                       else if (funct7 == 7'b1101000 && rs2 == 5'b00001) name = "FCVT.S.WU";
                       else                              name = "ILLEGAL";
      10'b0000111_010: name = "FLW";
      10'b0100111_010: name = "FSW";
      10'b0000111_011: name = "FLD";
      10'b0100111_011: name = "FSD";
      default:         name = "ILLEGAL";
    endcase
endmodule
