///////////////////////////////////////////
// plic_temp.sv
//
// This was made to provide a register interface to busybear. I think we'll end up replacing it with our more configurable plic.
//
// Written: bbracker@hmc.edu 18 January 2021
// Modified: 
//
// Purpose: Platform-Level Interrupt Controller
//   See FU540-C000-Manual-v1p0 for specifications
//   *** we might want to add support for FE310-G002-Manual-v19p05 version
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

module plic_temp (
  input  logic             HCLK, HRESETn,
  input  logic             HSELPLIC,
  input  logic [27:0]      HADDR,
  input  logic             HWRITE,
  input  logic [`XLEN-1:0] HWDATA,
  output logic [`XLEN-1:0] HREADPLIC,
  output logic             HRESPPLIC, HREADYPLIC);

  logic memread, memwrite;
  parameter numSrc = 53;
  logic [2:0] intPriority [numSrc:1];
  logic [2:0] intThreshold;
  logic [numSrc:1] intPending, intEn;
  logic [31:0] intClaim;
  logic [27:0] entry;

  // AHB I/O
  assign memread  = HSELPLIC & ~HWRITE;
  assign memwrite = HSELPLIC & HWRITE;
  assign HRESPPLIC = 0; // OK
  assign HREADYPLIC = 1'b1; // will need to be modified if PLIC ever needs more than 1 cycle to do something
  
  // word aligned reads
  generate
    if (`XLEN==64)
      assign #2 entry = {HADDR[15:3], 3'b000};
    else
      assign #2 entry = {HADDR[15:2], 2'b00}; 
  endgenerate

  // register access
  generate
    if (`XLEN==64) begin
      always @(posedge HCLK) begin
        // reading
        case(entry)
          // priority assignments
          28'hc000004: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[1]};
          28'hc000008: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[2]};
          28'hc00000c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[3]};
          28'hc000010: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[4]};
          28'hc000014: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[5]};
          28'hc000018: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[6]};
          28'hc00001c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[7]};
          28'hc000020: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[8]};
          28'hc000024: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[9]};
          28'hc000028: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[10]};
          28'hc00002c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[11]};
          28'hc000030: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[12]};
          28'hc000034: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[13]};
          28'hc000038: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[14]};
          28'hc00003c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[15]};
          28'hc000040: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[16]};
          28'hc000044: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[17]};
          28'hc000048: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[18]};
          28'hc00004c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[19]};
          28'hc000050: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[20]};
          28'hc000054: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[21]};
          28'hc000058: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[22]};
          28'hc00005c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[23]};
          28'hc000060: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[24]};
          28'hc000064: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[25]};
          28'hc000068: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[26]};
          28'hc00006c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[27]};
          28'hc000070: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[28]};
          28'hc000074: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[29]};
          28'hc000078: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[30]};
          28'hc00007c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[31]};
          28'hc000080: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[32]};
          28'hc000084: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[33]};
          28'hc000088: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[34]};
          28'hc00008c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[35]};
          28'hc000090: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[36]};
          28'hc000094: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[37]};
          28'hc000098: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[38]};
          28'hc00009c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[39]};
          28'hc0000a0: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[40]};
          28'hc0000a4: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[41]};
          28'hc0000a8: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[42]};
          28'hc0000ac: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[43]};
          28'hc0000b0: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[44]};
          28'hc0000b4: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[45]};
          28'hc0000b8: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[46]};
          28'hc0000bc: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[47]};
          28'hc0000c0: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[48]};
          28'hc0000c4: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[49]};
          28'hc0000c8: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[50]};
          28'hc0000cc: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[51]};
          28'hc0000d0: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[52]};
          28'hc0000d4: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[53]};
          // hart 0 configurations
          28'hc001000: HREADPLIC <= {{(`XLEN-32){1'b0}},intPending[31:1],1'b0};
          28'hc001004: HREADPLIC <= {{(`XLEN-22){1'b0}},intPending[53:32]};
          28'hc002000: HREADPLIC <= {{(`XLEN-32){1'b0}},intEn[31:1],1'b0};
          28'hc002004: HREADPLIC <= {{(`XLEN-22){1'b0}},intEn[53:32]};
          28'hc200000: HREADPLIC <= {{(`XLEN-3){1'b0}},intThreshold[2:0]};
          28'hc200004: HREADPLIC <= {{(`XLEN-32){1'b0}},intClaim[31:0]};
          default:  HREADPLIC <= 0;
        endcase
        // writing
        case(entry)
          // priority assignments
          28'hc000004: if (memwrite) intPriority[1] <= HWDATA[2:0];
          28'hc000008: if (memwrite) intPriority[2] <= HWDATA[2:0];
          28'hc00000c: if (memwrite) intPriority[3] <= HWDATA[2:0];
          28'hc000010: if (memwrite) intPriority[4] <= HWDATA[2:0];
          28'hc000014: if (memwrite) intPriority[5] <= HWDATA[2:0];
          28'hc000018: if (memwrite) intPriority[6] <= HWDATA[2:0];
          28'hc00001c: if (memwrite) intPriority[7] <= HWDATA[2:0];
          28'hc000020: if (memwrite) intPriority[8] <= HWDATA[2:0];
          28'hc000024: if (memwrite) intPriority[9] <= HWDATA[2:0];
          28'hc000028: if (memwrite) intPriority[10] <= HWDATA[2:0];
          28'hc00002c: if (memwrite) intPriority[11] <= HWDATA[2:0];
          28'hc000030: if (memwrite) intPriority[12] <= HWDATA[2:0];
          28'hc000034: if (memwrite) intPriority[13] <= HWDATA[2:0];
          28'hc000038: if (memwrite) intPriority[14] <= HWDATA[2:0];
          28'hc00003c: if (memwrite) intPriority[15] <= HWDATA[2:0];
          28'hc000040: if (memwrite) intPriority[16] <= HWDATA[2:0];
          28'hc000044: if (memwrite) intPriority[17] <= HWDATA[2:0];
          28'hc000048: if (memwrite) intPriority[18] <= HWDATA[2:0];
          28'hc00004c: if (memwrite) intPriority[19] <= HWDATA[2:0];
          28'hc000050: if (memwrite) intPriority[20] <= HWDATA[2:0];
          28'hc000054: if (memwrite) intPriority[21] <= HWDATA[2:0];
          28'hc000058: if (memwrite) intPriority[22] <= HWDATA[2:0];
          28'hc00005c: if (memwrite) intPriority[23] <= HWDATA[2:0];
          28'hc000060: if (memwrite) intPriority[24] <= HWDATA[2:0];
          28'hc000064: if (memwrite) intPriority[25] <= HWDATA[2:0];
          28'hc000068: if (memwrite) intPriority[26] <= HWDATA[2:0];
          28'hc00006c: if (memwrite) intPriority[27] <= HWDATA[2:0];
          28'hc000070: if (memwrite) intPriority[28] <= HWDATA[2:0];
          28'hc000074: if (memwrite) intPriority[29] <= HWDATA[2:0];
          28'hc000078: if (memwrite) intPriority[30] <= HWDATA[2:0];
          28'hc00007c: if (memwrite) intPriority[31] <= HWDATA[2:0];
          28'hc000080: if (memwrite) intPriority[32] <= HWDATA[2:0];
          28'hc000084: if (memwrite) intPriority[33] <= HWDATA[2:0];
          28'hc000088: if (memwrite) intPriority[34] <= HWDATA[2:0];
          28'hc00008c: if (memwrite) intPriority[35] <= HWDATA[2:0];
          28'hc000090: if (memwrite) intPriority[36] <= HWDATA[2:0];
          28'hc000094: if (memwrite) intPriority[37] <= HWDATA[2:0];
          28'hc000098: if (memwrite) intPriority[38] <= HWDATA[2:0];
          28'hc00009c: if (memwrite) intPriority[39] <= HWDATA[2:0];
          28'hc0000a0: if (memwrite) intPriority[40] <= HWDATA[2:0];
          28'hc0000a4: if (memwrite) intPriority[41] <= HWDATA[2:0];
          28'hc0000a8: if (memwrite) intPriority[42] <= HWDATA[2:0];
          28'hc0000ac: if (memwrite) intPriority[43] <= HWDATA[2:0];
          28'hc0000b0: if (memwrite) intPriority[44] <= HWDATA[2:0];
          28'hc0000b4: if (memwrite) intPriority[45] <= HWDATA[2:0];
          28'hc0000b8: if (memwrite) intPriority[46] <= HWDATA[2:0];
          28'hc0000bc: if (memwrite) intPriority[47] <= HWDATA[2:0];
          28'hc0000c0: if (memwrite) intPriority[48] <= HWDATA[2:0];
          28'hc0000c4: if (memwrite) intPriority[49] <= HWDATA[2:0];
          28'hc0000c8: if (memwrite) intPriority[50] <= HWDATA[2:0];
          28'hc0000cc: if (memwrite) intPriority[51] <= HWDATA[2:0];
          28'hc0000d0: if (memwrite) intPriority[52] <= HWDATA[2:0];
          28'hc0000d4: if (memwrite) intPriority[53] <= HWDATA[2:0];
          // hart 0 configurations
          28'hc002000: if (memwrite) intEn[31:1] <= HWDATA[31:1];
          28'hc002004: if (memwrite) intEn[53:32] <= HWDATA[22:0];
        endcase
      end
    end else begin // 32-bit
      always @(posedge HCLK) begin
        // reading
        case(entry)
          // priority assignments
          28'hc000004: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[1]};
          28'hc000008: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[2]};
          28'hc00000c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[3]};
          28'hc000010: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[4]};
          28'hc000014: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[5]};
          28'hc000018: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[6]};
          28'hc00001c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[7]};
          28'hc000020: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[8]};
          28'hc000024: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[9]};
          28'hc000028: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[10]};
          28'hc00002c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[11]};
          28'hc000030: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[12]};
          28'hc000034: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[13]};
          28'hc000038: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[14]};
          28'hc00003c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[15]};
          28'hc000040: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[16]};
          28'hc000044: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[17]};
          28'hc000048: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[18]};
          28'hc00004c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[19]};
          28'hc000050: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[20]};
          28'hc000054: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[21]};
          28'hc000058: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[22]};
          28'hc00005c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[23]};
          28'hc000060: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[24]};
          28'hc000064: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[25]};
          28'hc000068: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[26]};
          28'hc00006c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[27]};
          28'hc000070: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[28]};
          28'hc000074: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[29]};
          28'hc000078: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[30]};
          28'hc00007c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[31]};
          28'hc000080: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[32]};
          28'hc000084: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[33]};
          28'hc000088: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[34]};
          28'hc00008c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[35]};
          28'hc000090: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[36]};
          28'hc000094: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[37]};
          28'hc000098: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[38]};
          28'hc00009c: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[39]};
          28'hc0000a0: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[40]};
          28'hc0000a4: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[41]};
          28'hc0000a8: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[42]};
          28'hc0000ac: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[43]};
          28'hc0000b0: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[44]};
          28'hc0000b4: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[45]};
          28'hc0000b8: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[46]};
          28'hc0000bc: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[47]};
          28'hc0000c0: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[48]};
          28'hc0000c4: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[49]};
          28'hc0000c8: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[50]};
          28'hc0000cc: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[51]};
          28'hc0000d0: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[52]};
          28'hc0000d4: HREADPLIC <= {{(`XLEN-3){1'b0}},intPriority[53]};
          // hart 0 configurations
          28'hc001000: HREADPLIC <= {{(`XLEN-32){1'b0}},intPending[31:1],1'b0};
          28'hc001004: HREADPLIC <= {{(`XLEN-22){1'b0}},intPending[53:32]};
          28'hc002000: HREADPLIC <= {{(`XLEN-32){1'b0}},intEn[31:1],1'b0};
          28'hc002004: HREADPLIC <= {{(`XLEN-22){1'b0}},intEn[53:32]};
          28'hc200000: HREADPLIC <= {{(`XLEN-3){1'b0}},intThreshold[2:0]};
          28'hc200004: HREADPLIC <= {{(`XLEN-32){1'b0}},intClaim[31:0]};
          default:  HREADPLIC <= 0;
        endcase
        // writing
        case(entry)
          // priority assignments
          28'hc000004: if (memwrite) intPriority[1] <= HWDATA[2:0];
          28'hc000008: if (memwrite) intPriority[2] <= HWDATA[2:0];
          28'hc00000c: if (memwrite) intPriority[3] <= HWDATA[2:0];
          28'hc000010: if (memwrite) intPriority[4] <= HWDATA[2:0];
          28'hc000014: if (memwrite) intPriority[5] <= HWDATA[2:0];
          28'hc000018: if (memwrite) intPriority[6] <= HWDATA[2:0];
          28'hc00001c: if (memwrite) intPriority[7] <= HWDATA[2:0];
          28'hc000020: if (memwrite) intPriority[8] <= HWDATA[2:0];
          28'hc000024: if (memwrite) intPriority[9] <= HWDATA[2:0];
          28'hc000028: if (memwrite) intPriority[10] <= HWDATA[2:0];
          28'hc00002c: if (memwrite) intPriority[11] <= HWDATA[2:0];
          28'hc000030: if (memwrite) intPriority[12] <= HWDATA[2:0];
          28'hc000034: if (memwrite) intPriority[13] <= HWDATA[2:0];
          28'hc000038: if (memwrite) intPriority[14] <= HWDATA[2:0];
          28'hc00003c: if (memwrite) intPriority[15] <= HWDATA[2:0];
          28'hc000040: if (memwrite) intPriority[16] <= HWDATA[2:0];
          28'hc000044: if (memwrite) intPriority[17] <= HWDATA[2:0];
          28'hc000048: if (memwrite) intPriority[18] <= HWDATA[2:0];
          28'hc00004c: if (memwrite) intPriority[19] <= HWDATA[2:0];
          28'hc000050: if (memwrite) intPriority[20] <= HWDATA[2:0];
          28'hc000054: if (memwrite) intPriority[21] <= HWDATA[2:0];
          28'hc000058: if (memwrite) intPriority[22] <= HWDATA[2:0];
          28'hc00005c: if (memwrite) intPriority[23] <= HWDATA[2:0];
          28'hc000060: if (memwrite) intPriority[24] <= HWDATA[2:0];
          28'hc000064: if (memwrite) intPriority[25] <= HWDATA[2:0];
          28'hc000068: if (memwrite) intPriority[26] <= HWDATA[2:0];
          28'hc00006c: if (memwrite) intPriority[27] <= HWDATA[2:0];
          28'hc000070: if (memwrite) intPriority[28] <= HWDATA[2:0];
          28'hc000074: if (memwrite) intPriority[29] <= HWDATA[2:0];
          28'hc000078: if (memwrite) intPriority[30] <= HWDATA[2:0];
          28'hc00007c: if (memwrite) intPriority[31] <= HWDATA[2:0];
          28'hc000080: if (memwrite) intPriority[32] <= HWDATA[2:0];
          28'hc000084: if (memwrite) intPriority[33] <= HWDATA[2:0];
          28'hc000088: if (memwrite) intPriority[34] <= HWDATA[2:0];
          28'hc00008c: if (memwrite) intPriority[35] <= HWDATA[2:0];
          28'hc000090: if (memwrite) intPriority[36] <= HWDATA[2:0];
          28'hc000094: if (memwrite) intPriority[37] <= HWDATA[2:0];
          28'hc000098: if (memwrite) intPriority[38] <= HWDATA[2:0];
          28'hc00009c: if (memwrite) intPriority[39] <= HWDATA[2:0];
          28'hc0000a0: if (memwrite) intPriority[40] <= HWDATA[2:0];
          28'hc0000a4: if (memwrite) intPriority[41] <= HWDATA[2:0];
          28'hc0000a8: if (memwrite) intPriority[42] <= HWDATA[2:0];
          28'hc0000ac: if (memwrite) intPriority[43] <= HWDATA[2:0];
          28'hc0000b0: if (memwrite) intPriority[44] <= HWDATA[2:0];
          28'hc0000b4: if (memwrite) intPriority[45] <= HWDATA[2:0];
          28'hc0000b8: if (memwrite) intPriority[46] <= HWDATA[2:0];
          28'hc0000bc: if (memwrite) intPriority[47] <= HWDATA[2:0];
          28'hc0000c0: if (memwrite) intPriority[48] <= HWDATA[2:0];
          28'hc0000c4: if (memwrite) intPriority[49] <= HWDATA[2:0];
          28'hc0000c8: if (memwrite) intPriority[50] <= HWDATA[2:0];
          28'hc0000cc: if (memwrite) intPriority[51] <= HWDATA[2:0];
          28'hc0000d0: if (memwrite) intPriority[52] <= HWDATA[2:0];
          28'hc0000d4: if (memwrite) intPriority[53] <= HWDATA[2:0];
          // hart 0 configurations
          28'hc002000: if (memwrite) intEn[31:1] <= HWDATA[31:1];
          28'hc002004: if (memwrite) intEn[53:32] <= HWDATA[22:0];
        endcase
      end
    end
  endgenerate

endmodule

