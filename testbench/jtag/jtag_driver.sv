///////////////////////////////////////////
// jtag_driver.sv
//
// Written: matthew.n.otto@okstate.edu
// Created: 28 June 2024
//
// Purpose: Drives JTAG inputs to test Debug Module in simulation
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License Version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module jtag_driver(
  input  logic clk, reset,

  output logic tdi, tms, tck,
  input  logic tdo
);
  localparam logic [2:0] INSTR_RUN = 3'b000;
  localparam logic [2:0] INSTR_SIR = 3'b001;
  localparam logic [2:0] INSTR_SDR = 3'b010;

  localparam CMD_BITS = 3;
  localparam LENGTH_BITS = 10;
  localparam DATA_BITS = 48;
  localparam WIDTH = CMD_BITS + LENGTH_BITS + DATA_BITS*3;
  localparam DEPTH = 100;
  
  enum logic [4:0] {RESET, NOP, LOAD, DECODE, COMPLETE, ERROR, DR1, DR2, DR3, SHIFTDR, 
                    IR1, IR2, IR3, IR4, SHIFTIR, RTI1, RTI2} State;

  bit [WIDTH-1:0] MEM [DEPTH-1:0];

  logic [$clog2(DEPTH)-1:0] IP;
  logic [CMD_BITS-1:0] Instruction;
  logic [LENGTH_BITS-1:0] Length, Idx;
  logic [DATA_BITS-1:0] ScanIn, ScanOut, Mask, ScanData;

  
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      IP <= 0;
      Idx <= 0;
      State <= RESET;
    end else
      case (State)
        RESET : begin
          // TAP controller has no reset signal
          // we must clock a 111110 into TMS to guarantee Run-Test/Idle state
          if (Idx == 5)
            State <= LOAD;
          else
            Idx <= Idx + 1;
        end

        LOAD : begin
          {Instruction, Length, ScanIn, ScanOut, Mask} <= MEM[IP];
          if (|MEM[IP])
            State <= DECODE;
          else
            State <= COMPLETE;
          IP <= IP + 1;
        end

        DECODE : begin
          ScanData <= '0;
          Idx <= 0;
          case (Instruction)
            INSTR_RUN  : State <= NOP;
            INSTR_SDR  : State <= DR1;
            INSTR_SIR  : State <= IR1;
            default    : State <= ERROR;
          endcase
        end

        NOP : begin
          if (Idx == Length-1)
            State <= LOAD;
          else
            Idx <= Idx + 1;
        end

        DR1 : State <= DR2;
        DR2 : State <= DR3;
        DR3 : State <= SHIFTDR;

        SHIFTDR : begin
          ScanData[Idx[$clog2(DATA_BITS)-1:0]] <= tdo;
          if (Idx == Length-1)
            State <= RTI1;
          else
            Idx <= Idx + 1;
        end

        IR1 : State <= IR2;
        IR2 : State <= IR3;
        IR3 : State <= IR4;
        IR4 : State <= SHIFTIR;

        SHIFTIR : begin
          ScanData[Idx[$clog2(DATA_BITS)-1:0]] <= tdo;
          if (Idx == Length-1)
            State <= RTI1;
          else
            Idx <= Idx + 1;
        end

        RTI1 : begin
          if (|(ScanOut & Mask) & ((ScanData & Mask) != (ScanOut & Mask)))
            State <= ERROR;
          else
            State <= RTI2;
        end
        RTI2 : State <= LOAD;

        COMPLETE : State <= COMPLETE;
        ERROR : State <= ERROR;

        default: State <= RESET;
      endcase
  end

  // Drive TMS/TDI on falling edge of clock to match spec and also avoid weird simulation bugs
  always_ff @(negedge clk) begin
    // default values
    tdi <= 1'bx;
    tms <= 1'b1;

    case (State)
      RESET : tms <= (Idx != 5);

      LOAD,
      DECODE,
      NOP,
      COMPLETE : tms <= 0;

      DR1 : tms <= 1;
      DR2 : tms <= 0;
      DR3 : tms <= 0;

      SHIFTDR : begin
        tms <= (Idx == Length-1);
        tdi <= ScanIn[Idx[$clog2(DATA_BITS)-1:0]];
      end

      IR1 : tms <= 1;
      IR2 : tms <= 1;
      IR3 : tms <= 0;
      IR4 : tms <= 0;

      SHIFTIR : begin
        tms <= (Idx == Length-1);
        tdi <= ScanIn[Idx[$clog2(DATA_BITS)-1:0]];
      end

      RTI1 : tms <= 1;
      RTI2 : tms <= 0;

      default;
    endcase
  end

  // tck driver
  always_comb begin
    case (State)
      RESET,
      NOP,
      DR1,
      DR2,
      DR3,
      SHIFTDR,
      IR1,
      IR2,
      IR3,
      IR4,
      SHIFTIR,
      RTI1,
      RTI2 : tck = clk;

      default : tck = 0;
    endcase
  end

endmodule