///////////////////////////////////////////
// decompress.sv
//
// Written: David_Harris@hmc.edu
// Created: 9 January 2021
// Modified: 18 January 2023
//
// Purpose: Expand 16-bit compressed instructions to 32 bits
//
// Documentation: RISC-V System on Chip Design Chapter 11 (Section 11.3.1)
//                RISC-V Specification 13 Dec 2019 Chapter 16 pg. 97
// *** probably need more documentation in this file since the book is very light on decompression.
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
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


module decompress import cvw::*;  #(parameter cvw_t P) (
  input  logic [31:0] InstrRawD,         // 32-bit instruction or raw compressed 16-bit instruction in bottom half
  output logic [31:0] InstrD,            // Decompressed instruction
  output logic        IllegalCompInstrD  // Invalid decompressed instruction
);
                        
  logic [15:0]        instr16;
  logic [4:0]         rds1, rs2, rs1p, rs2p, rds1p, rdp;
  logic [11:0]        immCILSP, immCILSPD, immCSS, immCSSD, immCL, immCLD, immCI, immCS, immCSD, immCB, immCIASP, immCIW;
  logic [19:0]        immCJ, immCILUI;
  logic [5:0]         immSH;
  logic [1:0]         op;
    
  // Extract op and register source/destination fields
  assign instr16 = InstrRawD[15:0]; // instruction is already aligned
  assign op = instr16[1:0];
  assign rds1 = instr16[11:7];
  assign rs2 = instr16[6:2];
  assign rs1p = {2'b01, instr16[9:7]};
  assign rds1p = {2'b01, instr16[9:7]};
  assign rs2p = {2'b01, instr16[4:2]};
  assign rdp = {2'b01, instr16[4:2]};
  
  // extract compressed immediate formats
  assign immCILSP = {4'b0000, instr16[3:2], instr16[12], instr16[6:4], 2'b00};
  assign immCILSPD = {3'b000, instr16[4:2], instr16[12], instr16[6:5], 3'b000};
  assign immCSS = {4'b0000, instr16[8:7], instr16[12:9], 2'b00}; 
  assign immCSSD = {3'b000, instr16[9:7], instr16[12:10], 3'b000}; 
  assign immCL = {5'b0, instr16[5], instr16[12:10], instr16[6], 2'b00};
  assign immCLD = {4'b0, instr16[6:5], instr16[12:10], 3'b000};
  assign immCS = {5'b0, instr16[5], instr16[12:10], instr16[6], 2'b00};
  assign immCSD = {4'b0, instr16[6:5], instr16[12:10], 3'b000};
  assign immCJ = {instr16[12], instr16[8], instr16[10:9], instr16[6], instr16[7], instr16[2], instr16[11], instr16[5:3], {9{instr16[12]}}};
  assign immCB = {{4{instr16[12]}}, instr16[6:5], instr16[2], instr16[11:10], instr16[4:3], instr16[12]};
  assign immCI = {{7{instr16[12]}}, instr16[6:2]};
  assign immCILUI = {{15{instr16[12]}}, instr16[6:2]};
  assign immCIASP = {{3{instr16[12]}}, instr16[4:3], instr16[5], instr16[2], instr16[6], 4'b0000};
  assign immCIW = {2'b00, instr16[10:7], instr16[12:11], instr16[5], instr16[6], 2'b00};
  assign immSH = {instr16[12], instr16[6:2]};

// only for RV128  
//      assign immCILSPQ = {2{instr16[5]}, instr16[5:2], instr16[12], instr16[6], 4'b0000};
//      assign immCSSQ = {2{instr16[10]}, instr16[10:7], instr16[12:11], 4'b0000};
//      assign immCLQ = {4{instr16[10]}, instr16[6:5], instr16[12:11], 4'b0000};
//      assign immCSQ = {4{instr16[10]}, instr16[6:5], instr16[12:11], 4'b0000};

  always_comb
    if (op == 2'b11) begin // noncompressed instruction
      InstrD = InstrRawD; 
      IllegalCompInstrD = '0;
    end else begin  // convert compressed instruction into uncompressed
      IllegalCompInstrD = '0;
      case ({op, instr16[15:13]})
        5'b00000: if (immCIW != 0) InstrD = {immCIW, 5'b00010, 3'b000, rdp, 7'b0010011}; // c.addi4spn
                  else begin // illegal instruction
                    IllegalCompInstrD = 1'b1;
                    InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                  end
        5'b00001: if (P.C_SUPPORTED & P.D_SUPPORTED | P.ZCD_SUPPORTED)
                    InstrD = {immCLD, rs1p, 3'b011, rdp, 7'b0000111}; // c.fld
                  else begin // unsupported instruction
                    IllegalCompInstrD = 1'b1;
                    InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                  end
        5'b00010: InstrD = {immCL, rs1p, 3'b010, rdp, 7'b0000011}; // c.lw
        5'b00011: if (P.XLEN==32)
                    if (P.C_SUPPORTED & P.F_SUPPORTED | P.ZCF_SUPPORTED) 
                      InstrD = {immCL, rs1p, 3'b010, rdp, 7'b0000111}; // c.flw
                    else begin
                      IllegalCompInstrD = 1'b1;
                      InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                    end
                  else
                    InstrD = {immCLD, rs1p, 3'b011, rdp, 7'b0000011}; // c.ld;
        5'b00100: if (P.ZCB_SUPPORTED) 
                    if (instr16[12:10] == 3'b000) 
                      InstrD = {10'b0, instr16[5], instr16[6], rs1p, 3'b100, rdp, 7'b0000011}; // c.lbu
                    else if (instr16[12:10] == 3'b001) begin
                      if (instr16[6]) 
                        InstrD = {10'b0, instr16[5], 1'b0, rs1p, 3'b001, rdp, 7'b0000011}; // c.lh
                      else
                        InstrD = {10'b0, instr16[5], 1'b0, rs1p, 3'b101, rdp, 7'b0000011}; // c.lhu
                    end else if (instr16[12:10] == 3'b010)
                      InstrD = {7'b0, rs2p, rs1p, 3'b000, 3'b000, instr16[5], instr16[6], 7'b0100011}; // c.sb 
                    else if (instr16[12:10] == 3'b011 & instr16[6] == 1'b0)
                      InstrD = {7'b0, rs2p, rs1p, 3'b001, 3'b000, instr16[5], 1'b0, 7'b0100011}; // c.sh
                    else begin
                      IllegalCompInstrD = 1'b1;
                      InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                    end
                 else begin
                    IllegalCompInstrD = 1'b1;
                    InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                  end
        5'b00101: if (P.C_SUPPORTED & P.D_SUPPORTED | P.ZCD_SUPPORTED)
                    InstrD = {immCSD[11:5], rs2p, rs1p, 3'b011, immCSD[4:0], 7'b0100111}; // c.fsd
                  else begin // unsupported instruction
                    IllegalCompInstrD = 1'b1;
                    InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                  end
        5'b00110: InstrD = {immCS[11:5], rs2p, rs1p, 3'b010, immCS[4:0], 7'b0100011}; // c.sw
        5'b00111: if (P.XLEN==32)
                    if (P.C_SUPPORTED & P.F_SUPPORTED | P.ZCF_SUPPORTED) 
                      InstrD = {immCS[11:5], rs2p, rs1p, 3'b010, immCS[4:0], 7'b0100111}; // c.fsw
                    else begin
                      IllegalCompInstrD = 1'b1;
                      InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                    end
                  else
                    InstrD = {immCSD[11:5], rs2p, rs1p, 3'b011, immCSD[4:0], 7'b0100011}; //c.sd
        5'b01000: InstrD = {immCI, rds1, 3'b000, rds1, 7'b0010011}; // c.addi
        5'b01001: if (P.XLEN==32) 
                    InstrD = {immCJ, 5'b00001, 7'b1101111}; // c.jal
                  else
                    InstrD = {immCI, rds1, 3'b000, rds1, 7'b0011011}; // c.addiw
        5'b01010: InstrD = {immCI, 5'b00000, 3'b000, rds1, 7'b0010011}; // c.li
        5'b01011: if (rds1 != 5'b00010)
                    InstrD = {immCILUI, rds1, 7'b0110111}; // c.lui
                  else 
                    InstrD = {immCIASP, rds1, 3'b000, rds1, 7'b0010011}; // c.addi16sp
        5'b01100: if (instr16[11:10] == 2'b00)
                    InstrD = {6'b000000, immSH, rds1p, 3'b101, rds1p, 7'b0010011}; // c.srli
                  else if (instr16[11:10] == 2'b01)
                    InstrD = {6'b010000, immSH, rds1p, 3'b101, rds1p, 7'b0010011}; // c.srai
                  else if (instr16[11:10] == 2'b10) 
                    InstrD = {immCI, rds1p, 3'b111, rds1p, 7'b0010011}; // c.andi
                  else if (instr16[12:10] == 3'b011)
                    if (instr16[6:5] == 2'b00) 
                      InstrD = {7'b0100000, rs2p, rds1p, 3'b000, rds1p, 7'b0110011}; // c.sub
                    else if (instr16[6:5] == 2'b01) 
                      InstrD = {7'b0000000, rs2p, rds1p, 3'b100, rds1p, 7'b0110011}; // c.xor
                    else if (instr16[6:5] == 2'b10) 
                      InstrD = {7'b0000000, rs2p, rds1p, 3'b110, rds1p, 7'b0110011}; // c.or
                    else // if (instr16[6:5] == 2'b11) 
                      InstrD = {7'b0000000, rs2p, rds1p, 3'b111, rds1p, 7'b0110011}; // c.and
                  else begin // (instr16[12:10] == 3'b111)
                    if (instr16[6:5] == 2'b00 & P.XLEN > 32)
                      InstrD = {7'b0100000, rs2p, rds1p, 3'b000, rds1p, 7'b0111011}; // c.subw
                    else if (instr16[6:5] == 2'b01 & P.XLEN > 32)
                      InstrD = {7'b0000000, rs2p, rds1p, 3'b000, rds1p, 7'b0111011}; // c.addw
                    else if (instr16[6:2] == 5'b11000 & P.ZCB_SUPPORTED) 
                      InstrD = {12'b000011111111, rds1p, 3'b111, rds1p, 7'b0010011}; // c.zext.b = andi rd, rs1, 255
                    else if (instr16[6:2] == 5'b11001 & P.ZCB_SUPPORTED) 
                      InstrD = {12'b011000000100, rds1p, 3'b001, rds1p, 7'b0010011}; // c.sext.b
                    else if (instr16[6:2] == 5'b11010 & P.ZCB_SUPPORTED) 
                      InstrD = {7'b0000100, 5'b00000, rds1p, 3'b100, rds1p, 3'b011, P.XLEN > 32, 3'b011};  // c.zext.h
                    else if (instr16[6:2] == 5'b11011 & P.ZCB_SUPPORTED) 
                      InstrD = {12'b011000000101, rds1p, 3'b001, rds1p, 7'b0010011}; // c.sext.h
                    else if (instr16[6:2] == 5'b11101 & P.ZCB_SUPPORTED) 
                      InstrD = {12'b111111111111, rds1p, 3'b100, rds1p, 7'b0010011}; // c.not = xori
                    else if (instr16[6:2] == 5'b11100 & P.ZCB_SUPPORTED & P.XLEN > 32) 
                      InstrD = {7'b0000100, 5'b00000, rds1p, 3'b000, rds1p, 7'b0111011}; // c.zext.w = add.uw rd, rs1, 0
                    else if (instr16[6:5] == 2'b10 & P.ZCB_SUPPORTED) 
                      InstrD = {7'b0000001, rs2p, rds1p, 3'b000, rds1p, 7'b0110011}; // c.mul
                    else begin // reserved  
                      IllegalCompInstrD = 1'b1;
                      InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                    end
                  /** end else begin // illegal instruction
                    IllegalCompInstrD = 1'b1;
                    InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap **/
                  end
        5'b01101: InstrD = {immCJ, 5'b00000, 7'b1101111}; // c.j
        5'b01110: InstrD = {immCB[11:5], 5'b00000, rs1p, 3'b000, immCB[4:0], 7'b1100011}; // c.beqz
        5'b01111: InstrD = {immCB[11:5], 5'b00000, rs1p, 3'b001, immCB[4:0], 7'b1100011}; // c.bnez
        5'b10000: InstrD = {6'b000000, immSH, rds1, 3'b001, rds1, 7'b0010011}; // c.slli
        5'b10001: if (P.C_SUPPORTED & P.D_SUPPORTED | P.ZCD_SUPPORTED)
                    InstrD = {immCILSPD, 5'b00010, 3'b011, rds1, 7'b0000111}; // c.fldsp
                  else begin // unsupported instruction
                    IllegalCompInstrD = 1'b1;
                    InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                  end
        5'b10010: InstrD = {immCILSP, 5'b00010, 3'b010, rds1, 7'b0000011}; // c.lwsp
        5'b10011: if (P.XLEN == 32)
                    if (P.C_SUPPORTED & P.F_SUPPORTED | P.ZCF_SUPPORTED) 
                      InstrD = {immCILSP, 5'b00010, 3'b010, rds1, 7'b0000111}; // c.flwsp
                    else begin
                      IllegalCompInstrD = 1'b1;
                      InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                    end                    
                  else 
                    InstrD = {immCILSPD, 5'b00010, 3'b011, rds1, 7'b0000011}; // c.ldsp
        5'b10100: if (instr16[12] == 0)
                    if (instr16[6:2] == 5'b00000) 
                      InstrD = {7'b0000000, 5'b00000, rds1, 3'b000, 5'b00000, 7'b1100111}; // c.jr
                    else
                      InstrD = {7'b0000000, rs2, 5'b00000, 3'b000, rds1, 7'b0110011}; // c.mv
                  else
                    if (rs2 == 5'b00000)
                      if (rds1 == 5'b00000) 
                        InstrD = {12'b1, 5'b00000, 3'b000, 5'b00000, 7'b1110011}; // c.ebreak
                      else
                        InstrD = {12'b0, rds1, 3'b000, 5'b00001, 7'b1100111}; // c.jalr
                    else
                      InstrD = {7'b0000000, rs2, rds1, 3'b000, rds1, 7'b0110011}; // c.add
        5'b10101: if (P.C_SUPPORTED & P.D_SUPPORTED | P.ZCD_SUPPORTED)
                    InstrD = {immCSSD[11:5], rs2, 5'b00010, 3'b011, immCSSD[4:0], 7'b0100111}; // c.fsdsp
                  else begin // unsupported instruction
                    IllegalCompInstrD = 1'b1;
                    InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                  end
        5'b10110: InstrD = {immCSS[11:5], rs2, 5'b00010, 3'b010, immCSS[4:0], 7'b0100011}; // c.swsp
        5'b10111: if (P.XLEN==32)
                    if (P.C_SUPPORTED & P.F_SUPPORTED | P.ZCF_SUPPORTED) 
                      InstrD = {immCSS[11:5], rs2, 5'b00010, 3'b010, immCSS[4:0], 7'b0100111}; // c.fswsp
                    else begin
                      IllegalCompInstrD = 1'b1;
                      InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                    end                    
                  else
                    InstrD = {immCSSD[11:5], rs2, 5'b00010, 3'b011, immCSSD[4:0], 7'b0100011}; // c.sdsp
        default: begin // illegal instruction
                    IllegalCompInstrD = 1'b1;
                    InstrD = {16'b0, instr16}; // preserve instruction for mtval on trap
                  end
      endcase
    end
endmodule
