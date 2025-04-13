///////////////////////////////////////////
// fetchbuffer.sv
//
// Written: vkrishna@hmc.edu 3 April 2025
// Modified:
//
// Purpose: Cacheline buffer for instruction fetch
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
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

module fetchbuffer import cvw::*;  #(parameter cvw_t P) (
  input logic                 clk, reset,
  input logic                 disableRead, disableWrite,
  input logic   [P.XLEN-1:0]  PCF, // PC of the instruction
  input logic   [P.XLEN-1:0]  PCCacheF, // Address of the instruction
  input logic   [P.LINELEN-1:0]       fetchData, // Data fetched from memory
  output logic                empty, full,
  output logic                FetchBufferStallD,
  output logic  [31:0]        InstrD, // Instruction to be decoded
  output logic  [P.XLEN-1:0]  PCD // PC of the instruction to be decoded
);

  logic readPtr, writePtr;
  logic prevReadPtr; // used to invalidate old cacheline
  logic spill;
  logic [5:0] PCF_6; // used to get the last 6 bits of PCF

  logic valid [1:0];
  logic [P.XLEN-1-6:0] PCTag [1:0];
  logic [P.LINELEN-1:0] data [1:0];

  assign writePtr = ~readPtr;
  assign full = valid[0] & valid[1];
  assign FetchBufferStallD = empty | (spill & ~full);
  assign PCF_6 = PCF[5:0];

  always_comb begin : readPtrLogic
    if (reset) begin
      readPtr = 1'b1;
      empty = 1'b1;
    end else if (disableRead) begin
      readPtr = readPtr;
      empty = empty;
    end else if (PCF[P.XLEN-1:6] == PCTag[0]) begin
      readPtr = 1'b0;
      empty = 1'b0;
    end else if (PCF[P.XLEN-1:6] == PCTag[1]) begin
      readPtr = 1'b1;
      empty = 1'b0;
    end else begin
      readPtr = readPtr;
      empty = 1'b1; // think this was an easier way to handle empty, but should be checked
    end
  end

  always_ff @( posedge clk ) begin : readPtrFsm
    if (reset) prevReadPtr <= 1'b1;
    else prevReadPtr <= readPtr;
  end


  // The priority for writing is:
  // 1. If the buffer is empty, write the new data
  // 2. If the buffer is not empty, check if the new data isn't already in the buffer
  // 3. If the new data is not in the buffer, always write to writePtr
  // 4. If the new data is already in the buffer, check readPtr to invalidate the old data
  always_ff @( posedge clk ) begin : writeLogic
    if (reset) valid <= 2'b0;
    else if (~disableWrite & empty) begin
      valid[writePtr] <= 1'b1;
      PCTag[writePtr] <= PCCacheF[P.XLEN-1:6];
      data[writePtr] <= fetchData;
    end else if (~disableWrite & (prevReadPtr != readPtr)) 
      valid[prevReadPtr] <= 1'b0;
    else begin
      valid[writePtr] <= valid[writePtr];
      PCTag[writePtr] <= PCTag[writePtr];
      data[writePtr] <= data[writePtr];
    end
  end

  // Decode Logic:
  always_ff @( posedge clk ) begin : decodeLogic
    if (reset) begin
      InstrD <= 32'b0;
      PCD <= P.XLEN'b0;
      spill <= 1'b0;
    end else if (disableRead) begin
      InstrD <= InstrD;
      PCD <= PCD;
      spill <= spill;
    end else if (empty) begin
      InstrD <= 32'b0;
      PCD <= P.XLEN'b0;
      spill <= 1'b0;
    end else begin
      PCD <= PCF;
      
      // spill logic
      if (PCF_6 == (P.LINELEN/8-2)) begin 
        if (PCTag[~readPtr] == PCTag[readPtr]+1) begin 
          // next cacheline holds the spill
          spill <= 1'b0;
          InstrD <= {data[~readPtr][15:0], data[readPtr][P.LINELEN-1:P.LINELEN-16]};
        end else if (data[readPtr][P.LINELEN-15:P.LINELEN-16] == 2'b11) begin 
          // next cacheline doesn't hold spill but instruction is compressed so doesn't spill over
          spill <= 1'b0;
          InstrD <= {16'b0, data[readPtr][P.LINELEN-1:P.LINELEN-16]};
        end else begin
          // next cacheline doesn't hold spill, but it is needed as the instruction is not compressed
          spill <= 1'b1;
          InstrD <= P.XLEN'b0;
        end
      end
      else begin
        // fetch instruction from the cacheline as needed
        spill <= 1'b0;
        InstrD <= data[readPtr][PCF_6*8 + 31:PCF_6*8];
      end
    end
  end
endmodule
