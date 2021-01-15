///////////////////////////////////////////
// instrDecompress.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Expand 16-bit compressed instructions to 32 bits
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

module instrDecompress #(parameter XLEN=32, MISA=1) (
  input  logic [31:0]     InstrD,
  output logic [31:0]     InstrDecompD,
  output logic            IllegalCompInstrD);
                        
  logic [15:0] instr16;
  logic [4:0] rds1, rs2, rs1p, rs2p, rds1p, rdp;
  logic [11:0] immCILSP, immCILSPD, immCSS, immCSSD, immCL, immCLD, immCI, immCS, immCSD, immCB, immCIASP, immCIW;
  logic [19:0] immCJ, immCILUI;
  logic [5:0] immSH;
  logic [1:0] op;
    
  // if the system handles compressed instructions, decode appropriately
  generate
    if (!(`C_SUPPORTED)) begin // no compressed mode
      assign InstrDecompD = InstrD;
      assign IllegalCompInstrD = 0;
    end else begin // COMPRESSED mode supported
      assign instr16 = InstrD[15:0]; // instruction is alreay aligned
      assign op = instr16[1:0];
      assign rds1 = instr16[11:7];
      assign rs2 = instr16[6:2];
      assign rs1p = {2'b01, instr16[9:7]};
      assign rds1p = {2'b01, instr16[9:7]};
      assign rs2p = {2'b01, instr16[4:2]};
      assign rdp = {2'b01, instr16[4:2]};
      
      // many compressed immediate formats
      assign immCILSP = {{4{instr16[3]}}, instr16[3:2], instr16[12], instr16[6:4], 2'b00};
      assign immCILSPD = {{3{instr16[4]}}, instr16[4:2], instr16[12], instr16[6:5], 3'b000};
      assign immCSS = {{4{instr16[8]}}, instr16[8:7], instr16[12:9], 2'b00};
      assign immCSSD = {{3{instr16[9]}}, instr16[9:7], instr16[12:10], 3'b000};
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
          InstrDecompD = InstrD; 
          IllegalCompInstrD = 0;
        end else begin  // convert compressed instruction into uncompressed
          IllegalCompInstrD = 0;
          case ({op, instr16[15:13]})
            5'b00000: if (immCIW != 0) InstrDecompD = {immCIW, 5'b00010, 3'b000, rdp, 7'b0010011}; // c.addi4spn
                      else begin // illegal instruction
                        IllegalCompInstrD = 1;
                        InstrDecompD = {16'b0, instr16}; // preserve instruction for mtval on trap
                      end
            5'b00001: InstrDecompD = {immCLD, rs1p, 3'b011, rdp, 7'b0000111}; // c.fld
            5'b00010: InstrDecompD = {immCL, rs1p, 3'b010, rdp, 7'b0000011}; // c.lw
            5'b00011: if (XLEN==32)
                        InstrDecompD = {immCL, rs1p, 3'b010, rdp, 7'b0000111}; // c.flw
                      else
                        InstrDecompD = {immCLD, rs1p, 3'b011, rdp, 7'b0000011}; // c.ld;
            5'b00101: InstrDecompD = {immCSD[11:5], rs2p, rs1p, 3'b011, immCSD[4:0], 7'b0100111}; // c.fsd
            5'b00110: InstrDecompD = {immCS[11:5], rs2p, rs1p, 3'b010, immCS[4:0], 7'b0100011}; // c.sw
            5'b00111: if (XLEN==32)
                        InstrDecompD = {immCS[11:5], rs2p, rs1p, 3'b010, immCS[4:0], 7'b0100111}; // c.fsw
                      else
                        InstrDecompD = {immCSD[11:5], rs2p, rs1p, 3'b011, immCSD[4:0], 7'b0100011}; //c.sd
            5'b01000: InstrDecompD = {immCI, rds1, 3'b000, rds1, 7'b0010011}; // c.addi
            5'b01001: if (XLEN==32) 
                        InstrDecompD = {immCJ, 5'b00001, 7'b1101111}; // c.jal
                      else
                        InstrDecompD = {immCI, rds1, 3'b000, rds1, 7'b0011011}; // c.addiw
            5'b01010: InstrDecompD = {immCI, 5'b00000, 3'b000, rds1, 7'b0010011}; // c.li
            5'b01011: if (rds1 != 5'b00010)
                       InstrDecompD = {immCILUI, rds1, 7'b0110111}; // c.lui
                      else 
                       InstrDecompD = {immCIASP, rds1, 3'b000, rds1, 7'b0010011}; // c.addi16sp
            5'b01100: if (instr16[11:10] == 2'b00)
                        InstrDecompD = {6'b000000, immSH, rds1p, 3'b101, rds1p, 7'b0010011}; // c.srli
                      else if (instr16[11:10] == 2'b01)
                        InstrDecompD = {6'b010000, immSH, rds1p, 3'b101, rds1p, 7'b0010011}; // c.srai
                      else if (instr16[11:10] == 2'b10) 
                        InstrDecompD = {immCI, rds1p, 3'b111, rds1p, 7'b0010011}; // c.andi
                      else if (instr16[12:10] == 3'b011)
                        if (instr16[6:5] == 2'b00) 
                          InstrDecompD = {7'b0100000, rs2p, rds1p, 3'b000, rds1p, 7'b0110011}; // c.sub
                        else if (instr16[6:5] == 2'b01) 
                          InstrDecompD = {7'b0000000, rs2p, rds1p, 3'b100, rds1p, 7'b0110011}; // c.xor
                        else if (instr16[6:5] == 2'b10) 
                          InstrDecompD = {7'b0000000, rs2p, rds1p, 3'b110, rds1p, 7'b0110011}; // c.or
                        else // if (instr16[6:5] == 2'b11) 
                          InstrDecompD = {7'b0000000, rs2p, rds1p, 3'b111, rds1p, 7'b0110011}; // c.and
                      else if (instr16[12:10] == 3'b111 && XLEN > 32)
                        if (instr16[6:5] == 2'b00)
                          InstrDecompD = {7'b0100000, rs2p, rds1p, 3'b000, rds1p, 7'b0111011}; // c.subw
                        else if (instr16[6:5] == 2'b01)
                          InstrDecompD = {7'b0000000, rs2p, rds1p, 3'b000, rds1p, 7'b0111011}; // c.addw
                        else begin // reserved  
                          IllegalCompInstrD = 1;
                          InstrDecompD = {16'b0, instr16}; // preserve instruction for mtval on trap
                        end
                      else begin // illegal instruction
                        IllegalCompInstrD = 1;
                        InstrDecompD = {16'b0, instr16}; // preserve instruction for mtval on trap
                      end
            5'b01101: InstrDecompD = {immCJ, 5'b00000, 7'b1101111}; // c.j
            5'b01110: InstrDecompD = {immCB[11:5], 5'b00000, rs1p, 3'b000, immCB[4:0], 7'b1100011}; // c.beqz
            5'b01111: InstrDecompD = {immCB[11:5], 5'b00000, rs1p, 3'b001, immCB[4:0], 7'b1100011}; // c.bnez
            5'b10000: InstrDecompD = {6'b000000, immSH, rds1, 3'b001, rds1, 7'b0010011}; // c.slli
            5'b10001: InstrDecompD = {immCILSPD, 5'b00010, 3'b011, rds1, 7'b0000111}; // c.fldsp
            5'b10010: InstrDecompD = {immCILSP, 5'b00010, 3'b010, rds1, 7'b0000011}; // c.lwsp
            5'b10011: if (XLEN == 32)
                        InstrDecompD = {immCILSP, 5'b00010, 3'b010, rds1, 7'b0000111}; // c.flwsp
                      else 
                        InstrDecompD = {immCILSPD, 5'b00010, 3'b011, rds1, 7'b0000011}; // c.ldsp
            5'b10100: if (instr16[12] == 0)
                        if (instr16[6:2] == 5'b00000) 
                          InstrDecompD = {7'b0000000, 5'b00000, rds1, 3'b000, 5'b00001, 7'b1100111}; // c.jalr
                        else
                          InstrDecompD = {7'b0000000, rs2, 5'b00000, 3'b000, rds1, 7'b0110011}; // c.mv
                      else
                        if (rs2 == 5'b00000)
                          if (rds1 == 5'b00000) 
                            InstrDecompD = {12'b1, 5'b00000, 3'b000, 5'b00000, 7'b1110011}; // c.ebreak
                          else
                            InstrDecompD = {12'b0, rds1, 3'b000, 5'b00001, 7'b1100111}; // c.jalr
                        else
                          InstrDecompD = {7'b0000000, rs2, rds1, 3'b000, rds1, 7'b0110011}; // c.add
            5'b10101: InstrDecompD = {immCSSD[11:5], rs2, 5'b00010, 3'b011, immCSSD[4:0], 7'b0100111}; // c.fsdsp
            5'b10110: InstrDecompD = {immCSS[11:5], rs2, 5'b00010, 3'b010, immCSS[4:0], 7'b0100011}; // c.swsp
            5'b10111: if (XLEN==32)
                        InstrDecompD = {immCSS[11:5], rs2, 5'b00010, 3'b010, immCSS[4:0], 7'b0100111}; // c.fswsp
                      else
                        InstrDecompD = {immCSSD[11:5], rs2, 5'b00010, 3'b011, immCSSD[4:0], 7'b0100011}; // c.sdsp
            default: begin // illegal instruction
                        IllegalCompInstrD = 1;
                        InstrDecompD = {16'b0, instr16}; // preserve instruction for mtval on trap
                      end
          endcase
        end
     end
  endgenerate
endmodule
    