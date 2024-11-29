///////////////////////////////////////////
// instrNameDecTB.sv
//
// Purpose: decode name of function
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

// decode the instruction name, to help the test bench
module instrNameDecTB(
  input  logic [31:0] instr,
  output string       name);

  logic [6:0] op;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [11:0] imm;
  logic [4:0] rs2, rd;

  assign op = instr[6:0];
  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];
  assign imm = instr[31:20];
  assign rs2 = instr[24:20];
  assign rd = instr[11:7];

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
      10'b0010011_000: if (instr[31:15] == 0 & instr[11:7] ==0) name = "NOP/FLUSH";
                       else                                      name = "ADDI";
      10'b0010011_001: if (funct7[6:1] == 6'b000000) name = "SLLI";
                       else if (funct7[6:1] == 6'b010010) name = "BCLRI";
                       else if (funct7[6:1] == 6'b011010) name = "BINVI";
                       else if (funct7[6:1] == 6'b001010) name = "BSETI";
                       else if (funct7 == 7'b0000100 & rs2 == 5'b01111) name = "ZIP";
                       else if (funct7 == 7'b0011000 & rs2 == 5'b00000) name = "AES64IM";
                       else if (funct7 == 7'b0011000 & rs2[4] == 1'b1) name = "AES64KS1I";
                       else if (funct7 == 7'b0001000 & rs2 == 5'b00010) name = "SHA256SIG0";
                       else if (funct7 == 7'b0001000 & rs2 == 5'b00011) name = "SHA256SIG1";
                       else if (funct7 == 7'b0001000 & rs2 == 5'b00000) name = "SHA256SUM0";
                       else if (funct7 == 7'b0001000 & rs2 == 5'b00001) name = "SHA256SUM1";
                       else if (funct7 == 7'b0001000 & rs2 == 5'b00110) name = "SHA512SIG0";
                       else if (funct7 == 7'b0001000 & rs2 == 5'b00111) name = "SHA512SIG1";
                       else if (funct7 == 7'b0001000 & rs2 == 5'b00100) name = "SHA512SUM0";
                       else if (funct7 == 7'b0001000 & rs2 == 5'b00101) name = "SHA512SUM1";
                       else if (funct7 == 7'b0110000) begin
                         case (rs2)
                           5'b00000: name = "CLZ";
                           5'b00010: name = "CPOP";
                           5'b00001: name = "CTZ";
                           5'b00100: name = "SEXT.B";
                           5'b00101: name = "SEXT.H";
                           default:  name = "ILLEGAL";
                         endcase
                       end else                      name = "ILLEGAL";
      10'b0010011_010: name = "SLTI";
      10'b0010011_011: name = "SLTIU";
      10'b0010011_100: name = "XORI";
      10'b0010011_101: if (funct7[6:1] == 6'b000000)      name = "SRLI";
                       else if (funct7[6:1] == 6'b010000) name = "SRAI"; 
                       else if (funct7[6:1] == 6'b011010 & rs2 == 5'b11000) name = "REV8";
                       else if (funct7[6:1] == 6'b011000) name = "RORI";
                       else if (funct7[6:1] == 6'b010010) name = "BEXTI";
                       else if (funct7 == 7'b0010100 & rs2 == 5'b00111) name = "ORC.B";
                       else if (imm == 12'b011010000111) name = "BREV8";
                       else if (funct7 == 7'b0000100 & rs2 == 5'b01111) name = "UNZIP";
                       else                           name = "ILLEGAL"; 
      10'b0010011_110: if      (rd == 0 & rs2 == 0) name = "PREFETCH.I";
                       else if (rd == 0 & rs2 == 1) name = "PREFETCH.R";
                       else if (rd == 0 & rs2 == 3) name = "PREFETCH.W";
                       else                         name = "ORI";
      10'b0010011_111: name = "ANDI";
      10'b0010111_???: name = "AUIPC";
      10'b0100011_000: name = "SB";
      10'b0100011_001: name = "SH";
      10'b0100011_010: name = "SW";
      10'b0100011_011: name = "SD";
      10'b0011011_000: name = "ADDIW";
      10'b0011011_001: if      (funct7 == 7'b0000000 )name = "SLLIW";
                       else if (funct7[6:1] == 6'b000010) name = "SLLI.UW";
                       else if (funct7 == 7'b0110000) begin
                         case (rs2)
                           5'b00000:                  name = "CLZW";
                           5'b00010:                  name = "CPOPW";
                           5'b00001:                  name = "CTZW";
                           default:                   name = "ILLEGAL";
                         endcase
                       end else                       name = "ILLEGAL";
      10'b0011011_101: if      (funct7 == 7'b0000000) name = "SRLIW";
                       else if (funct7 == 7'b0100000) name = "SRAIW";
                       else if (funct7 == 7'b0110000) name = "RORIW";
                       else                           name = "ILLEGAL";
      10'b0111011_000: if      (funct7 == 7'b0000000) name = "ADDW";
                       else if (funct7 == 7'b0100000) name = "SUBW";
                       else if (funct7 == 7'b0000001) name = "MULW";
                       else if (funct7 == 7'b0000100) name = "ADD.UW";
                       else                           name = "ILLEGAL";
      10'b0111011_001: if      (funct7 == 7'b0000000) name = "SLLW";
                       else if (funct7 == 7'b0000001) name = "DIVW";
                       else if (funct7 == 7'b0110000) name = "ROLW";
                       else                           name = "ILLEGAL";
      10'b0111011_010: if      (funct7 == 7'b0010000) name = "SH1ADD.UW";
                       else                           name = "ILLEGAL";
      10'b0111011_100: if      (funct7 == 7'b0010000) name = "SH2ADD.UW";
                       else if (funct7 == 7'b0000100) name = "ZEXT.H";
                       else                           name = "ILLEGAL";
      10'b0111011_101: if      (funct7 == 7'b0000000) name = "SRLW";
                       else if (funct7 == 7'b0100000) name = "SRAW";
                       else if (funct7 == 7'b0000001) name = "DIVUW";
                       else if (funct7 == 7'b0110000) name = "RORW";
                       else                           name = "ILLEGAL";
      10'b0111011_110: if      (funct7 == 7'b0000001) name = "REMW";
                       else if (funct7 == 7'b0010000) name = "SH3ADD.UW";
                       else                           name = "ILLEGAL";
      10'b0111011_111: if      (funct7 == 7'b0000001) name = "REMUW";
                       else                           name = "ILLEGAL";
      10'b0110011_000: if      (funct7 == 7'b0000000) name = "ADD";
                       else if (funct7 == 7'b0000001) name = "MUL";
                       else if (funct7 == 7'b0100000) name = "SUB"; 
                       else if (funct7[4:0] == 5'b10101) name = "AES32DSI";
                       else if (funct7[4:0] == 5'b10111) name = "AES32DSMI";
                       else if (funct7 == 7'b0011101)    name = "AES64DS";
                       else if (funct7 == 7'b0011111)    name = "AES64DSM";
                       else if (funct7[4:0] == 5'b10001) name = "AES32ESI";
                       else if (funct7[4:0] == 5'b10011) name = "AES32ESMI";
                       else if (funct7 == 7'b0011001)    name = "AES64ES";
                       else if (funct7 == 7'b0011011)    name = "AES64ESM";
                       else if (funct7 == 7'b0111111)    name = "AES64KS2";
                       else if (funct7 == 7'b0101110) name = "SHA512SIG0H";
                       else if (funct7 == 7'b0101010) name = "SHA512SIG0L";
                       else if (funct7 == 7'b0101111) name = "SHA512SIG1H";
                       else if (funct7 == 7'b0101011) name = "SHA512SIG1L";
                       else if (funct7 == 7'b0101000) name = "SHA512SUM0R";
                       else if (funct7 == 7'b0101001) name = "SHA512SUM1R";
                       else                           name = "ILLEGAL"; 
      10'b0110011_001: if      (funct7 == 7'b0000000) name = "SLL";
                       else if (funct7 == 7'b0000001) name = "MULH";
                       else if (funct7 == 7'b0110000) name = "ROL";
                       else if (funct7 == 7'b0000101) name = "CLMUL";
                       else if (funct7 == 7'b0100100) name = "BCLR";
                       else if (funct7 == 7'b0110100) name = "BINV";
                       else if (funct7 == 7'b0010100) name = "BSET";
                       else                           name = "ILLEGAL";
      10'b0110011_010: if      (funct7 == 7'b0000000) name = "SLT";
                       else if (funct7 == 7'b0000001) name = "MULHSU";
                       else if (funct7 == 7'b0010000) name = "SH1ADD";
                       else if (funct7 == 7'b0000101) name = "CLMULR";
                       else                           name = "ILLEGAL";
      10'b0110011_011: if      (funct7 == 7'b0000000) name = "SLTU";
                       else if (funct7 == 7'b0000001) name = "MULHU";
                       else if (funct7 == 7'b0000101) name = "CLMULH";
                       else                           name = "ILLEGAL";
      10'b0110011_100: if      (funct7 == 7'b0000000) name = "XOR";
                       else if (funct7 == 7'b0000001) name = "DIV";
                       else if (funct7 == 7'b0010000) name = "SH2ADD";
                       else if (funct7 == 7'b0000101) name = "MIN";
                       else if (funct7 == 7'b0100000) name = "ORN";
                       else if (funct7 == 7'b0000100 & rs2 == 5'b00000) name = "ZEXT.H";
                       else if (funct7 == 7'b0000100 & op == 7'b0110011) name = "PACK";
                       else if (funct7 == 7'b0000100 & op == 7'b0111011) name = "PACKW";
                       else                           name = "ILLEGAL";
      10'b0110011_101: if      (funct7 == 7'b0000000) name = "SRL";
                       else if (funct7 == 7'b0000001) name = "DIVU";
                       else if (funct7 == 7'b0100000) name = "SRA";
                       else if (funct7 == 7'b0000101) name = "MINU";
                       else if (funct7 == 7'b0110000) name = "ROR";
                       else if (funct7 == 7'b0100100) name = "BEXT";
                       else if (funct7 == 7'b0000111) name = "CZERO.EQZ";
                       else                           name = "ILLEGAL";
      10'b0110011_110: if      (funct7 == 7'b0000000) name = "OR";
                       else if (funct7 == 7'b0000001) name = "REM";
                       else if (funct7 == 7'b0010000) name = "SH3ADD";
                       else if (funct7 == 7'b0000101) name = "MAX";
                       else if (funct7 == 7'b0100000) name = "XNOR";
                       else                           name = "ILLEGAL";
      10'b0110011_111: if      (funct7 == 7'b0000000) name = "AND";
                       else if (funct7 == 7'b0000001) name = "REMU";
                       else if (funct7 == 7'b0000101) name = "MAXU";
                       else if (funct7 == 7'b0100000) name = "ANDN";
                       else if (funct7 == 7'b0000111) name = "CZERO.NEZ";
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
                       else if (imm == 258) name = "SRET";
                       else if (imm == 770) name = "MRET";
                       else if (funct7 == 9) name = "SFENCE.VMA";
                       else if (funct7 == 11) name = "SINVAL.VMA";
                       else if (funct7 == 12 & rs2 == 0) name = "SFENCE.W.INVAL";
                       else if (funct7 == 12 & rs2 == 1) name = "SFENCE.INVAL.IR";
                       else if (imm == 259) name = "WFI";
                       else if (imm == 261) name = "WFI";
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
      10'b0001111_000: name = "FENCE";
      10'b0001111_001: name = "FENCE.I";
      10'b0001111_010: if      (instr[31:20] == 12'd0) name = "CBO.INVAL";
                       else if (instr[31:20] == 12'd1) name = "CBO.CLEAN";
                       else if (instr[31:20] == 12'd2) name = "CBO.FLUSH";
                       else if (instr[31:20] == 12'd4) name = "CBO.ZERO";    
                       else                            name = "ILLEGAL";                   
      10'b1000011_???: name = "FMADD";
      10'b1000111_???: name = "FMSUB";
      10'b1001011_???: name = "FNMSUB";
      10'b1001111_???: name = "FNMADD";
      10'b1010011_???: if      (funct7[6:2] == 5'b00000) name = "FADD";
                       else if (funct7[6:2] == 5'b00001) name = "FSUB";
                       else if (funct7[6:2] == 5'b00010) name = "FMUL";
                       else if (funct7[6:2] == 5'b00011) name = "FDIV";
                       else if (funct7[6:2] == 5'b01011) name = "FSQRT";
                       else if (funct7 == 7'b1100000 & rs2 == 5'b00000) name = "FCVT.W.S";
                       else if (funct7 == 7'b1100000 & rs2 == 5'b00001) name = "FCVT.WU.S";
                       else if (funct7 == 7'b1100000 & rs2 == 5'b00010) name = "FCVT.L.S";
                       else if (funct7 == 7'b1100000 & rs2 == 5'b00011) name = "FCVT.LU.S";
                       else if (funct7 == 7'b1101000 & rs2 == 5'b00000) name = "FCVT.S.W";
                       else if (funct7 == 7'b1101000 & rs2 == 5'b00001) name = "FCVT.S.WU";
                       else if (funct7 == 7'b1101000 & rs2 == 5'b00010) name = "FCVT.S.L";
                       else if (funct7 == 7'b1101000 & rs2 == 5'b00011) name = "FCVT.S.LU";
                       else if (funct7 == 7'b1100001 & rs2 == 5'b00000) name = "FCVT.W.D";
                       else if (funct7 == 7'b1100001 & rs2 == 5'b00001) name = "FCVT.WU.D";
                       else if (funct7 == 7'b1100001 & rs2 == 5'b00010) name = "FCVT.L.D";
                       else if (funct7 == 7'b1100001 & rs2 == 5'b00011) name = "FCVT.LU.D";
                       else if (funct7 == 7'b1101001 & rs2 == 5'b00000) name = "FCVT.D.W";
                       else if (funct7 == 7'b1101001 & rs2 == 5'b00001) name = "FCVT.D.WU";
                       else if (funct7 == 7'b1101001 & rs2 == 5'b00010) name = "FCVT.D.L";
                       else if (funct7 == 7'b1101001 & rs2 == 5'b00011) name = "FCVT.D.LU";
                       else if (funct7 == 7'b0100000 & rs2 == 5'b00001) name = "FCVT.S.D";
                       else if (funct7 == 7'b0100001 & rs2 == 5'b00000) name = "FCVT.D.S";
                       else if (funct7 == 7'b1100010 & rs2 == 5'b00000) name = "FCVT.W.H";
                       else if (funct7 == 7'b1100010 & rs2 == 5'b00001) name = "FCVT.WU.H";
                       else if (funct7 == 7'b1100010 & rs2 == 5'b00010) name = "FCVT.L.H";
                       else if (funct7 == 7'b1100010 & rs2 == 5'b00011) name = "FCVT.LU.H";
                       else if (funct7 == 7'b1101010 & rs2 == 5'b00000) name = "FCVT.H.W";
                       else if (funct7 == 7'b1101010 & rs2 == 5'b00001) name = "FCVT.H.WU";
                       else if (funct7 == 7'b1101010 & rs2 == 5'b00010) name = "FCVT.H.L";
                       else if (funct7 == 7'b1101010 & rs2 == 5'b00011) name = "FCVT.H.LU";
                       else if (funct7 == 7'b1100011 & rs2 == 5'b00000) name = "FCVT.W.Q";
                       else if (funct7 == 7'b1100011 & rs2 == 5'b00001) name = "FCVT.WU.Q";
                       else if (funct7 == 7'b1100011 & rs2 == 5'b00010) name = "FCVT.L.Q";
                       else if (funct7 == 7'b1100011 & rs2 == 5'b00011) name = "FCVT.LU.Q";
                       else if (funct7 == 7'b1101011 & rs2 == 5'b00000) name = "FCVT.Q.W";
                       else if (funct7 == 7'b1101011 & rs2 == 5'b00001) name = "FCVT.Q.WU";
                       else if (funct7 == 7'b1101011 & rs2 == 5'b00010) name = "FCVT.Q.L";
                       else if (funct7 == 7'b1101011 & rs2 == 5'b00011) name = "FCVT.Q.LU";
                       else if (funct7 == 7'b0100000 & rs2 == 5'b00001) name = "FCVT.S.D";
                       else if (funct7 == 7'b0100000 & rs2 == 5'b00010) name = "FCVT.S.H";
                       else if (funct7 == 7'b0100000 & rs2 == 5'b00011) name = "FCVT.S.Q";
                       else if (funct7 == 7'b0100001 & rs2 == 5'b00000) name = "FCVT.D.S";
                       else if (funct7 == 7'b0100001 & rs2 == 5'b00010) name = "FCVT.D.H";
                       else if (funct7 == 7'b0100001 & rs2 == 5'b00011) name = "FCVT.D.Q";
                       else if (funct7 == 7'b0100010 & rs2 == 5'b00000) name = "FCVT.H.S";
                       else if (funct7 == 7'b0100010 & rs2 == 5'b00001) name = "FCVT.H.D";
                       else if (funct7 == 7'b0100010 & rs2 == 5'b00011) name = "FCVT.H.Q";
                       else if (funct7 == 7'b0100011 & rs2 == 5'b00000) name = "FCVT.Q.S";
                       else if (funct7 == 7'b0100011 & rs2 == 5'b00001) name = "FCVT.Q.D";
                       else if (funct7 == 7'b0100011 & rs2 == 5'b00010) name = "FCVT.Q.H";
                       else if (funct7 == 7'b1110000 & rs2 == 5'b00000 & funct3 == 3'b000) name = "FMV.X.W";
                       else if (funct7 == 7'b1111000 & rs2 == 5'b00000 & funct3 == 3'b000) name = "FMV.W.X";
                       else if (funct7 == 7'b1110001 & rs2 == 5'b00000 & funct3 == 3'b000) name = "FMV.X.D";
                       else if (funct7 == 7'b1111001 & rs2 == 5'b00000 & funct3 == 3'b000) name = "FMV.D.X"; 
                       else if (funct7 == 7'b1110010 & rs2 == 5'b00000 & funct3 == 3'b000) name = "FMV.X.H";
                       else if (funct7 == 7'b1111010 & rs2 == 5'b00000 & funct3 == 3'b000) name = "FMV.H.X";
                       else if (funct7[6:2] == 5'b00100 & funct3 == 3'b000) name = "FSGNJ";
                       else if (funct7[6:2] == 5'b00101 & funct3 == 3'b000) name = "FMIN";
                       else if (funct7[6:2] == 5'b10100 & funct3 == 3'b000) name = "FLE";
                       else if (funct7[6:2] == 5'b00100 & funct3 == 3'b001) name = "FSGNJN";
                       else if (funct7[6:2] == 5'b00101 & funct3 == 3'b001) name = "FMAX";
                       else if (funct7[6:2] == 5'b10100 & funct3 == 3'b001) name = "FLT";
                       else if (funct7[6:2] == 5'b11100 & funct3 == 3'b001) name = "FCLASS";
                       else if (funct7[6:2] == 5'b00100 & funct3 == 3'b010) name = "FSGNJX";
                       else if (funct7[6:2] == 5'b10100 & funct3 == 3'b010) name = "FEQ";
                       else if (funct7[6:2] == 5'b11110 & funct3 == 3'b000 & rs2 == 5'b00001) name = "FLI";
                       else if (funct7[6:2] == 5'b00101 & funct3 == 3'b010) name = "FMINM";
                       else if (funct7[6:2] == 5'b00101 & funct3 == 3'b011) name = "FMAXM";
                       else if (funct7[6:2] == 5'b01000 & rs2 == 5'b00100) name = "FROUND";
                       else if (funct7[6:2] == 5'b01000 & rs2 == 5'b00101) name = "FROUNDNX";
                       else if (funct7[6:2] == 5'b10100 & funct3 == 3'b100) name = "FLEQ";
                       else if (funct7[6:2] == 5'b10100 & funct3 == 3'b101) name = "FLTQ";
                       else if (funct7 == 7'b1110001 & funct3 == 3'b000 & rs2 == 5'b00001) name = "FMVH.X.D";
                       else if (funct7 == 7'b1110011 & funct3 == 3'b000 & rs2 == 5'b00001) name = "FMVH.X.Q";
                       else if (funct7 == 7'b1011001 & funct3 == 3'b000) name = "FMVP.D.X";
                       else if (funct7 == 7'b1011011 & funct3 == 3'b000) name = "FMVP.Q.X";
                       else if (funct7 == 7'b1100001 & funct3 == 3'b001 & rs2 == 5'b01000) name = "FCVTMOD.W.D";
                       else                              name = "ILLEGAL";
      10'b0000111_001: name = "FLH";
      10'b0000111_010: name = "FLW";
      10'b0000111_011: name = "FLD";
      10'b0000111_100: name = "FLQ";
      10'b0100111_001: name = "FSH";
      10'b0100111_010: name = "FSW";
      10'b0100111_011: name = "FSD";
      10'b0100111_100: name = "FSQ";
      default:         name = "ILLEGAL";
    endcase
endmodule
