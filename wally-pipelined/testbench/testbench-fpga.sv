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

  string tests64m[] = '{
    "rv64m/I-MUL-01", "3000",
    "rv64m/I-MULH-01", "3000",
    "rv64m/I-MULHSU-01", "3000",
    "rv64m/I-MULHU-01", "3000",
    "rv64m/I-MULW-01", "3000",
    "rv64m/I-DIV-01", "3000",
    "rv64m/I-DIVU-01", "3000",
    "rv64m/I-DIVUW-01", "3000",
    "rv64m/I-DIVW-01", "3000",
    "rv64m/I-REM-01", "3000",
    "rv64m/I-REMU-01", "3000",
    "rv64m/I-REMUW-01", "3000",
    "rv64m/I-REMW-01", "3000"
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
    //"rv64i/WALLY-PIPELINE-100K", "f7ff0",
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
    "rv32a/WALLY-AMO", "2110",
    "rv32a/WALLY-LRSC", "2110"
  };

  string tests32m[] = '{
    "rv32m/I-MUL-01", "2000",
    "rv32m/I-MULH-01", "2000",
    "rv32m/I-MULHSU-01", "2000",
    "rv32m/I-MULHU-01", "2000",
    "rv32m/I-DIV-01", "2000",
    "rv32m/I-DIVU-01", "2000",
    "rv32m/I-REM-01", "2000",
    "rv32m/I-REMU-01", "2000"
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
    //"rv32i/WALLY-PIPELINE-100K", "10a800",
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
    "rv64BP/blink-led", "10000"
/* -----\/----- EXCLUDED -----\/-----
    "rv64BP/simple", "10000",
    "rv64BP/mmm", "1000000",
    "rv64BP/linpack_bench", "1000000",
    "rv64BP/sieve", "1000000",
    "rv64BP/qsort", "1000000",
    "rv64BP/dhrystone", "1000000"
 -----/\----- EXCLUDED -----/\----- */
  };

  string tests64p[] = '{
    "rv64p/WALLY-MSTATUS", "2000",
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
    "rv32p/WALLY-MSTATUS", "2000",
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
    "rv64i-periph/WALLY-PERIPH", "2000"
  };

  string tests32periph[] = '{
    "rv32i-periph/WALLY-PLIC", "2080"
  };

   string tests[];
  string ProgramAddrMapFile, ProgramLabelMapFile;
  logic [`AHBW-1:0] HRDATAEXT;
  logic             HREADYEXT, HRESPEXT, HREADY;
  logic 	    HSELEXT;
  
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
    
  flopenr #(`XLEN) PCWReg(clk, reset, ~dut.wallypipelinedsoc.hart.ieu.dp.StallW, dut.wallypipelinedsoc.hart.ifu.PCM, PCW);
  flopenr  #(32)   InstrWReg(clk, reset, ~dut.wallypipelinedsoc.hart.ieu.dp.StallW,  dut.wallypipelinedsoc.hart.ifu.InstrM, InstrW);

  // check assertions for a legal configuration
  riscvassertions riscvassertions();
  logging logging(clk, reset, dut.wallypipelinedsoc.uncore.HADDR, dut.wallypipelinedsoc.uncore.HTRANS);

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
        tests = {tests64p,tests64i, tests64periph};
        if (`C_SUPPORTED) tests = {tests, tests64ic};
        else              tests = {tests, tests64iNOc};
        if (`M_SUPPORTED) tests = {tests, tests64m};
        if (`F_SUPPORTED) tests = {tests64f, tests};
        if (`D_SUPPORTED) tests = {tests64d, tests};
        if (`MEM_VIRTMEM) tests = {tests64mmu, tests};
        if (`A_SUPPORTED) tests = {tests64a, tests};
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

  string signame, memfilename, romfilename, sdcfilename;

  logic [3:0] GPIOPinsIn_IO;
  logic [4:0] GPIOPinsOut_IO;
  logic UARTSin, UARTSout;
  logic ddr4_calib_complete;
  

  logic SDCCLK;
  tri1 SDCCmd;
  tri1 [3:0] SDCDat;
  logic      SDCCmdIn;
  logic      SDCCmdOut;
  logic      SDCCmdOE;
  logic [3:0] SDCDatIn;

  assign SDCCmd = SDCCmdOE ? SDCCmdOut : 1'bz;
  assign SDCCmdIn = SDCCmd;
  assign SDCDatIn = SDCDat;
    
  sdModel sdcard
    (.sdClk(SDCCLK),
    .cmd(SDCCmd), 
    .dat(SDCDat));

  // instantiate device to be tested
  assign GPIOPinsIn = 0;
  assign UARTSin = 1;
 
  ram #(.BASE(`RAM_BASE), .RANGE(`RAM_RANGE)) 
  ram (.HCLK, .HRESETn, .HADDR, .HWRITE, .HTRANS, .HWDATA, .HSELTim(HSELEXT), 
        .HREADTim(HRDATAEXT), .HREADYTim(HREADYEXT), .HRESPTim(HRESPEXT));
 

  wallypipelinedsocwrapper dut(.clk, .reset_ext, .HRDATAEXT,.HREADYEXT, .HRESPEXT,.HSELEXT,
                        .HCLK, .HRESETn, .HADDR, .HWDATA, .HWRITE, .HSIZE, .HBURST, .HPROT,
                        .HTRANS, .HMASTLOCK, .HREADY, .TIMECLK(0), .GPIOPinsIn, .GPIOPinsOut, .GPIOPinsEn,
                        .UARTSin, .UARTSout, .SDCCmdIn, .SDCCmdOut, .SDCCmdOE, .SDCDatIn, .SDCCLK); 

  // Track names of instructions
  instrTrackerTB it(clk, reset, dut.wallypipelinedsoc.hart.ieu.dp.FlushE,
                dut.wallypipelinedsoc.hart.ifu.icache.FinalInstrRawF,
                dut.wallypipelinedsoc.hart.ifu.InstrD, dut.wallypipelinedsoc.hart.ifu.InstrE,
                dut.wallypipelinedsoc.hart.ifu.InstrM,  InstrW,
                InstrFName, InstrDName, InstrEName, InstrMName, InstrWName);

  // initialize tests
  localparam integer 	   MemStartAddr = `RAM_BASE>>(1+`XLEN/32);
  localparam integer 	   MemEndAddr = (`RAM_RANGE+`RAM_BASE)>>1+(`XLEN/32);

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
/* -----\/----- EXCLUDED -----\/-----
      if (`TESTSBP) begin
	for (i=MemStartAddr; i<MemEndAddr; i = i+1) begin
	  ram.RAM[i] = meminit;
	end
      end
 -----/\----- EXCLUDED -----/\----- */
      // read test vectors into memory
      memfilename = {"../../imperas-riscv-tests/work/", tests[test], ".elf.memfile"};
      //romfilename = {"../../testsBP/fpga-test-sdc/bin/fpga-test-sdc.hex"};
      romfilename = {"../../tests/testsBP/fpga-test-sdc/bin/fpga-test-sdc.memfile"};
      sdcfilename = {"../src/sdc/tb/ramdisk2.hex"};      
      $readmemh(memfilename, ram.RAM);
      $readmemh(romfilename, dut.wallypipelinedsoc.uncore.bootram.bootram.RAM);
      $readmemh(sdcfilename, sdcard.FLASHmem);
      ProgramAddrMapFile = {"../../imperas-riscv-tests/work/rv64BP/fpga-test-sdc.objdump.addr"};
      ProgramLabelMapFile = {"../../imperas-riscv-tests/work/rv64BP/fpga-test-sdc.objdump.lab"};
      $display("Read memfile %s", memfilename);
      reset = 0; #97; reset = 1; # 1000; reset = 0;
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
      if (dut.wallypipelinedsoc.hart.priv.EcallFaultM & 
			    (dut.wallypipelinedsoc.hart.ieu.dp.regf.rf[3] == 1 | 
			     (dut.wallypipelinedsoc.hart.ieu.dp.regf.we3 & 
			      dut.wallypipelinedsoc.hart.ieu.dp.regf.a3 == 3 & 
			      dut.wallypipelinedsoc.hart.ieu.dp.regf.wd3 == 1))) begin
 -----/\----- EXCLUDED -----/\----- */
      if (DCacheFlushDone) begin
        //$display("Code ended with ecall with gp = 1");

        #600; // give time for instructions in pipeline to finish
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
        testadr = (`RAM_BASE+tests[test+1].atohex())/(`XLEN/8);
        /* verilator lint_off INFINITELOOP */
        while (signature[i] !== 'bx) begin
          //$display("signature[%h] = %h", i, signature[i]);
          if (signature[i] !== ram.RAM[testadr+i] &
	      (signature[i] !== DCacheFlushFSM.ShadowRAM[testadr+i])) begin
            if (signature[i+4] !== 'bx | signature[i] !== 32'hFFFFFFFF) begin
              // report errors unless they are garbage at the end of the sim
              // kind of hacky test for garbage right now
              errors = errors+1;
              $display("  Error on test %s result %d: adr = %h sim (D$) %h sim (TIM) = %h, signature = %h", 
                    tests[test], i, (testadr+i)*(`XLEN/8), DCacheFlushFSM.ShadowRAM[testadr+i], ram.RAM[testadr+i], signature[i]);
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
          memfilename = {"../../imperas-riscv-tests/work/", tests[test], ".elf.memfile"};
          $readmemh(memfilename, ram.RAM);
          $display("Read memfile %s", memfilename);
	  ProgramAddrMapFile = {"../../imperas-riscv-tests/work/", tests[test], ".elf.objdump.addr"};
	  ProgramLabelMapFile = {"../../imperas-riscv-tests/work/", tests[test], ".elf.objdump.lab"};
	  reset = 0; #97; reset = 1; # 1000; reset = 0;
        end
      end
    end // always @ (negedge clk)

  // track the current function or global label
/* -----\/----- EXCLUDED -----\/-----
  if (DEBUG == 1) begin : FunctionName
    FunctionName FunctionName(.reset(reset),
			      .clk(clk),
			      .ProgramAddrMapFile(ProgramAddrMapFile),
			      .ProgramLabelMapFile(ProgramLabelMapFile));
  end
 -----/\----- EXCLUDED -----/\----- */

  assign DCacheFlushStart = dut.wallypipelinedsoc.hart.priv.EcallFaultM & 
			    (dut.wallypipelinedsoc.hart.ieu.dp.regf.rf[3] == 1 | 
			     (dut.wallypipelinedsoc.hart.ieu.dp.regf.we3 & 
			      dut.wallypipelinedsoc.hart.ieu.dp.regf.a3 == 3 & 
			      dut.wallypipelinedsoc.hart.ieu.dp.regf.wd3 == 1));
  
  DCacheFlushFSM DCacheFlushFSM(.clk(clk),
				.reset(reset),
				.start(DCacheFlushStart),
				.done(DCacheFlushDone));
  

  generate
    // initialize the branch predictor
    if (`BPRED_ENABLED == 1) begin : bpred
      
      initial begin
	$readmemb(`TWO_BIT_PRELOAD, dut.wallypipelinedsoc.hart.ifu.bpred.bpred.Predictor.DirPredictor.PHT.mem);
	$readmemb(`BTB_PRELOAD, dut.wallypipelinedsoc.hart.ifu.bpred.bpred.TargetPredictor.memory.mem);
      end
    end
  endgenerate
  
endmodule

module riscvassertions();
  // Legal number of PMP entries are 0, 16, or 64
  initial begin
    assert (`PMP_ENTRIES == 0 | `PMP_ENTRIES==16 | `PMP_ENTRIES==64) else $error("Illegal number of PMP entries: PMP_ENTRIES must be 0, 16, or 64");
    assert (`F_SUPPORTED | ~`D_SUPPORTED) else $error("Can't support double without supporting float");
    assert (`XLEN == 64 | ~`D_SUPPORTED) else $error("Wally does not yet support D extensions on RV32");
    assert (`DCACHE_WAYSIZEINBYTES <= 4096 | `MEM_DCACHE == 0 | `MEM_VIRTMEM == 0) else $error("DCACHE_WAYSIZEINBYTES cannot exceed 4 KiB when caches and vitual memory is enabled (to prevent aliasing)");
    assert (`DCACHE_BLOCKLENINBITS >= 128 | `MEM_DCACHE == 0) else $error("DCACHE_BLOCKLENINBITS must be at least 128 when caches are enabled");
    assert (`DCACHE_BLOCKLENINBITS < `DCACHE_WAYSIZEINBYTES*8) else $error("DCACHE_BLOCKLENINBITS must be smaller than way size");
    assert (`ICACHE_WAYSIZEINBYTES <= 4096 | `MEM_ICACHE == 0 | `MEM_VIRTMEM == 0) else $error("ICACHE_WAYSIZEINBYTES cannot exceed 4 KiB when caches and vitual memory is enabled (to prevent aliasing)");
    assert (`ICACHE_BLOCKLENINBITS >= 32 | `MEM_ICACHE == 0) else $error("ICACHE_BLOCKLENINBITS must be at least 32 when caches are enabled");
    assert (`ICACHE_BLOCKLENINBITS < `ICACHE_WAYSIZEINBYTES*8) else $error("ICACHE_BLOCKLENINBITS must be smaller than way size");
    assert (2**$clog2(`DCACHE_BLOCKLENINBITS) == `DCACHE_BLOCKLENINBITS) else $error("DCACHE_BLOCKLENINBITS must be a power of 2");
    assert (2**$clog2(`DCACHE_WAYSIZEINBYTES) == `DCACHE_WAYSIZEINBYTES) else $error("DCACHE_WAYSIZEINBYTES must be a power of 2");
    assert (2**$clog2(`ICACHE_BLOCKLENINBITS) == `ICACHE_BLOCKLENINBITS) else $error("ICACHE_BLOCKLENINBITS must be a power of 2");
    assert (2**$clog2(`ICACHE_WAYSIZEINBYTES) == `ICACHE_WAYSIZEINBYTES) else $error("ICACHE_WAYSIZEINBYTES must be a power of 2");
    assert (`ICACHE_NUMWAYS == 1 | `MEM_ICACHE == 0) else $warning("Multiple Instruction Cache ways not yet implemented");
    assert (2**$clog2(`ITLB_ENTRIES) == `ITLB_ENTRIES) else $error("ITLB_ENTRIES must be a power of 2");
    assert (2**$clog2(`DTLB_ENTRIES) == `DTLB_ENTRIES) else $error("DTLB_ENTRIES must be a power of 2");
    assert (`RAM_RANGE >= 56'h07FFFFFF) else $error("Some regression tests will fail if RAM_RANGE is less than 56'h07FFFFFF");
  end
endmodule


/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */

module DCacheFlushFSM
  (input logic clk,
   input logic reset,
   input logic start,
   output logic done);

  localparam integer numlines = testbench.dut.wallypipelinedsoc.hart.lsu.dcache.NUMLINES;
  localparam integer numways = testbench.dut.wallypipelinedsoc.hart.lsu.dcache.NUMWAYS;
  localparam integer blockbytelen = testbench.dut.wallypipelinedsoc.hart.lsu.dcache.BLOCKBYTELEN;
  localparam integer numwords = testbench.dut.wallypipelinedsoc.hart.lsu.dcache.BLOCKLEN/`XLEN;  
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

  logic [`XLEN-1:0] ShadowRAM[`RAM_BASE>>(1+`XLEN/32):(`RAM_RANGE+`RAM_BASE)>>1+(`XLEN/32)];
  
  generate
    for(index = 0; index < numlines; index++) begin
      for(way = 0; way < numways; way++) begin
	for(cacheWord = 0; cacheWord < numwords; cacheWord++) begin
	  copyShadow #(.tagstart(tagstart),
		       .logblockbytelen(logblockbytelen))
	  copyShadow(.clk,
		     .start,
		     .tag(testbench.dut.wallypipelinedsoc.hart.lsu.dcache.MemWay[way].CacheTagMem.StoredData[index]),
		     .valid(testbench.dut.wallypipelinedsoc.hart.lsu.dcache.MemWay[way].ValidBits[index]),
		     .dirty(testbench.dut.wallypipelinedsoc.hart.lsu.dcache.MemWay[way].DirtyBits[index]),
		     .data(testbench.dut.wallypipelinedsoc.hart.lsu.dcache.MemWay[way].word[cacheWord].CacheDataMem.StoredData[index]),
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
	  if (CacheValid[j][i][k] & CacheDirty[j][i][k]) begin
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

