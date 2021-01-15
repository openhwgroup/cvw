///////////////////////////////////////////
// testbench.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Wally Testbench and helper modules
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

`include "wally-macros.sv"

module testbench #(parameter XLEN=64, MISA=32'h00000104, ZCSR = 1, ZCOUNTERS = 1)();
  logic        clk;
  logic        reset;

  logic [XLEN-1:0] WriteData, DataAdr;
  logic [1:0]      MemRW;

  int test, i, errors, totalerrors;
  logic [31:0] sig32[0:10000];
  logic [XLEN-1:0] signature[0:10000];
  logic [XLEN-1:0] testadr;
  string InstrFName, InstrDName, InstrEName, InstrMName, InstrWName;
  logic [31:0] InstrW;
  logic [XLEN-1:0] meminit;
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
                     "rv64i/I-XORI-01", "3000"
  };
string tests32ic[] = '{
//                     "rv32ic/WALLY-C-ADHOC-01", "2000",
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
                     "rv32i/I-IO-01","2030",
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
                     "rv32i/I-XORI-01","2000" 
};
  string tests[];
  
  // pick tests based on modes supported
  initial 
    if (XLEN == 64) begin // RV64
      tests = {tests64i};
      if (`C_SUPPORTED % 2 == 1) tests = {tests, tests64ic};
      else                       tests = {tests, tests64iNOc};
    end else begin // RV32
      tests = {tests32i};
      if (`C_SUPPORTED % 2 == 1) tests = {tests, tests32ic};    
      else                       tests = {tests, tests32iNOc};
    end
  string signame, memfilename;

  logic [31:0] GPIOPinsIn, GPIOPinsOut, GPIOPinsEn;

  // instantiate device to be tested
  wallypipelined #(XLEN, MISA, ZCSR, ZCOUNTERS) dut(
    clk, reset, WriteData, DataAdr, MemRW, 
    GPIOPinsIn, GPIOPinsOut, GPIOPinsEn
  ); 

  // Track names of instructions
  instrTrackerTB #(XLEN) it(clk, reset, dut.hart.dp.FlushE,
                dut.hart.dp.InstrDecompD, dut.hart.dp.InstrE,
                dut.hart.dp.InstrM,  InstrW,
                InstrDName, InstrEName, InstrMName, InstrWName);

  // initialize test
  initial
    begin
      test = 0;
      totalerrors = 0;
      testadr = 0;
      // fill memory with defined values to reduce Xs in simulation
      if (XLEN == 32) meminit = 32'hFEDC0123;
      else meminit = 64'hFEDCBA9876543210;
      for (i=0; i<=65535; i = i+1) begin
        //dut.imem.RAM[i] = meminit;
       // dut.dmem.RAM[i] = meminit;
      end
      // read test vectors into memory
      memfilename = {"../imperas-riscv-tests/work/", tests[test], ".elf.memfile"};
      $readmemh(memfilename, dut.imem.RAM);
      $readmemh(memfilename, dut.dmem.dtim.RAM);
      reset = 1; # 22; reset = 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk = 1; # 5; clk = 0; # 5;
    end
   
  // check results
  always @(negedge clk)
    begin    
      if (dut.hart.dp.priv.EcallFaultM && 
          (dut.hart.dp.regf.rf[3] == 1 || (dut.hart.dp.regf.we3 && dut.hart.dp.regf.a3 == 3 && dut.hart.dp.regf.wd3 == 1))) begin
        $display("Code ended with ecall with gp = 1");
        #60; // give time for instructions in pipeline to finish
        // clear signature to prevent contamination from previous tests
        for(i=0; i<10000; i=i+1) begin
          sig32[i] = 'bx;
        end

        // read signature, reformat in 64 bits if necessary
        signame = {"../imperas-riscv-tests/work/", tests[test], ".signature.output"};
        $readmemh(signame, sig32);
        i = 0;
        while (i < 10000) begin
          if (XLEN == 32) begin
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
        if (XLEN == 32)
          testadr = tests[test+1].atohex()/4;
        else
          testadr = tests[test+1].atohex()/8;
        /* verilator lint_off INFINITELOOP */
        while (signature[i] !== 'bx) begin
          //$display("signature[%h] = %h", i, signature[i]);
          if (signature[i] !== dut.dmem.dtim.RAM[testadr+i]) begin
            if (signature[i+4] !== 'bx || signature[i] !== 32'hFFFFFFFF) begin
              // report errors unless they are garbage at the end of the sim
              // kind of hacky test for garbage right now
              errors = errors+1;
              $display("  Error on test %s result %d: adr = %h sim = %h, signature = %h", 
                    tests[test], i, (testadr+i)*XLEN/8, dut.dmem.dtim.RAM[testadr+i], signature[i]);
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
          memfilename = {"../imperas-riscv-tests/work/", tests[test], ".elf.memfile"};
          $readmemh(memfilename, dut.imem.RAM);
          $readmemh(memfilename, dut.dmem.dtim.RAM);
          $display("Read memfile %s", memfilename);
          reset = 1; # 17; reset = 0;
        end
      end
    end
endmodule

/* verilator lint_on STMTDLY */
/* verilator lint_on WIDTH */

module instrTrackerTB #(parameter XLEN=32) (
  input  logic            clk, reset, FlushE,
  input  logic [31:0]     InstrD,
  input  logic [31:0]     InstrE, InstrM,
  output logic [31:0]     InstrW,
  output string           InstrDName, InstrEName, InstrMName, InstrWName);
        
  // stage Instr to Writeback for visualization
  flopr  #(32) InstrWReg(clk, reset, InstrM, InstrW);

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

  assign op = instr[6:0];
  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];
  assign imm = instr[31:20];

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
                       else                           name = "ILLEGAL";
      10'b0111011_001: name = "SLLW";
      10'b0111011_101: if      (funct7 == 7'b0000000) name = "SRLW";
                       else if (funct7 == 7'b0100000) name = "SRAW";
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
                       else if (funct7 == 7'b0000001) name = "DIV";
                       else                           name = "ILLEGAL";
      10'b0110011_100: if      (funct7 == 7'b0000000) name = "XOR";
                       else if (funct7 == 7'b0000001) name = "MUL";
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
      10'b0001111_???: name = "FENCE";
      default:         name = "ILLEGAL";
    endcase
endmodule
