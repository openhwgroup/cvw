//////////////////////////////////////////////////////////////////////
// csrd.sv
//
// Written: Jacob Pease jacobpease@protonmail.com 19 September 2025
//
// Purpose: Debug Control and Status Registers
//          See RISC-V Privileged Mode Specification 20190608 
// 
// Documentation: RISC-V System on Chip Design
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
//////////////////////////////////////////////////////////////////////

module csrd import cvw::*;  #(parameter cvw_t P) (
  input logic               clk, reset,
  input logic               CSRDWriteM,
  input logic [P.XLEN-1:0]  CSRWriteValM,
  input logic [11:0]        CSRAdrM,
  output logic [P.XLEN-1:0] CSRDReadValM,
  output logic              DebugMode,
  output logic [P.XLEN-1:0] NextEPCM
);

  localparam DCSR = 12'h7B0;
  localparam DPC = 12'h7B1;
  localparam DSCRATCH0 = 12'h7B2;
  localparam DSCRATCH1 = 12'h7B3;

  // Halting states
  typedef enum 	       logic {RUNNING, HALTED} dbg_state_e;
  dbg_state_e state, state_n;

  logic NextHalt;

  // Write Enables
  logic      WriteDCSR;
  logic      WrtieDPC;
  logic      WriteCause;

  // WriteVals
  logic [31:0] DCSRWriteValM;
  logic [P.XLEN-1:0] DPCWriteValM;
    
  // Register Outputs
  logic [31:0]       DCSR_REGW;
  logic [P.XLEN-1:0] DPC_REGW;

  // DCSR Fields
  logic [3:0] debugver;
  logic [2:0] extcause;  // Irrelevant -> unimplemented
  logic       cetrig;    // Not implemented
  logic       pelp;      // Not implemented
  logic       ebreakvs;  // Not implemented
  logic       ebreakvu;  // Not implemented
  logic       ebreakm;   // Must be implemented
  logic       ebreaks;   // Must be implemented
  logic       ebreaku;   // Must be implemented
  logic       stepie;    // Must be implemented
  logic       stopcount; // Hardcoded to 0, but should implement
  logic       stoptime;  // Hardcoded to 0, but should implement
  logic [2:0] cause;     // Cause of halt
  logic       v;         // Not implemented - related to virtualization
  logic       mprven;    // See note...
  logic       nmip;      // Non-maskable interrupt. Tying to 0
  logic       step;      // Need to implement this. How to track 1 instruction completing?
  logic [1:0] prv;       // Privilege Mode at halt. Set to change mode when resumed.

  // Need this for
  logic [2:0] NextCause;     // Cause of halt
  logic       ebreak;
  
  // NOTE: When set to 0, mprven allows MPRV to be ignored while in
  // DebugMode. This can be added later. For now, tying it to 1
  // implies that MPRV takes effect if it is set, thus DebugMode can't
  // alter it's behavior.

  // Read only and unimplemented DCSR Fields
  assign debugver = 4'b0100; // version 1.0
  assign extcause = 3'd0;
  assign cetrig = 0;
  assign pelp = 0;
  assign ebreakvs = 0;
  assign ebreakvu = 0;
  assign stopcount = 0;
  assign stoptime = 0;
  assign v = 0;
  assign mprven = 1;
  assign nmip = 0;

  assign NextHalt = (state_n == HALTED & state == RUNNING);
  assign WriteDCSR = CSRDWriteM & (CSRAdrM == DCSR) | NextHalt;
  assign WriteDPC = CSRDWriteM & (CSRAdrM == DPC) | NextHalt;
  // Need to assign ebreak appropriately for the combinational logic
  // below. Not sure what signals gets triggered for ebreak.

  assign DCSRWriteValM = CSRDWriteM ?
                         {CSRWriteValM[15], CSRWriteValM[13], CSRWriteValM[12], CSRWriteValM[11], CSRWriteValM[8:6], CSRWriteValM[2], CSRWriteValM[1:0]} :
                         {ebreakm, ebreaks, ebreaku, stepie, cause, step, prv};
  
  localparam dcsrwidth = ($bits(ebreakm) + $bits(ebreaks) + $bits(ebreaku) +
    $bits(stepie) + $bits(cause) + $bits(step) + $bits(prv));

  ////////////////////////////////////////////////////////////////////
  // CSRs
  ////////////////////////////////////////////////////////////////////
  
  flopenr #(dcsrwidth) DCSRreg(clk, reset, WriteDCSR,
    {ebreakm, ebreaks, ebreaku, stepie, cause, step, prv},
    DCSR_REGW);
  
  flopenr #(P.XLEN) DPCreg(clk, reset, WriteDPC, NextEPCM, DPC_REGW);

  assign ebreakm = DCSR_REGW[15];
  assign ebreaks = DCSR_REGW[13];
  assign ebreaku = DCSR_REGW[12];
  assign stepie = DSCR_REGW[11];
  assign cause = DCSR_REGW[8:6];
  assign step = DCSR_REGW[2];
  assign prv = DCSR_REGW[1:0];

  // CSR Reads
  always_comb begin
    case (CSRAdrM)
      DCSR: begin
        CSRDReadValM = {debugver, 1'b0, extcause, 4'd0, cetrig, pelp, ebreakvs, ebreakvu,
                        ebreakm, 1'b0, ebreaks, ebreaku, stepie, stopcount, stoptime,
                        cause, v, mprven, nmip, step, prv};
      end
      
      DPC: CSRDReadValM = DPC_REGW;
      default: CSRDReadValM = '0;
    endcase
  end
  
  ////////////////////////////////////////////////////////////////////
  // Halt Machine
  ////////////////////////////////////////////////////////////////////
  
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= RUNNING;
    end else if (HaltReq | ResumeReq) begin // Using the requests as enables
      state <= state_n;
    end
  end
  
  always_comb begin
    case (state)
	   RUNNING: begin 
        if (HaltReq) state_n = HALTED;
        else state_n = RUNNING;
        end
	   HALTED: begin
        if (ResumeReq) state_n = RUNNING;
        else state_n = HALTED;
        end
      default: state_n = RUNNING;
    endcase
  end

  assign DebugMode = (state == HALTED);

  // Halt cause
  // 000: No cause - Reset
  // 001: ebreak
  // 010: trigger
  // 011: haltreg
  // 100: step
  // 101: resethaltreq
  // 110: group (no groups implemented)
  // 111: other (refer to extcause)
  always_comb begin
    NextCause = '0;
    if (HaltReq) begin
      NextCause = 3'd3;
    /*end else if (ebreak) begin
      NextCause = 3'd1;*/
    end else begin
      NextCause = '0;
    end
  end
  
endmodule
