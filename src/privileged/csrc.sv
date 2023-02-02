

///////////////////////////////////////////
// csrc.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Counter CSRs
//          See RISC-V Privileged Mode Specification 20190608 3.1.10-11
// 
// Documentation: RISC-V System on Chip Design Chapter 5
//    MHPMEVENT is not supported
//
// A component of the CORE-V-WALLY configurable RISC-V project.
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

`include "wally-config.vh"
module csrc #(parameter 
  MHPMCOUNTERBASE = 12'hB00,
  MHPMCOUNTERHBASE = 12'hB80,
  MHPMEVENTBASE = 12'h320,
  HPMCOUNTERBASE = 12'hC00,
  HPMCOUNTERHBASE = 12'hC80,
  TIME  = 12'hC01,
  TIMEH = 12'hC81
) (
  input  logic 	            clk, reset,
  input  logic 	            StallE, StallM, 
  input  logic              FlushM, 
  input  logic 	            InstrValidNotFlushedM, LoadStallD, CSRMWriteM,
  input  logic 	            DirPredictionWrongM,
  input  logic 	            BTBPredPCWrongM,
  input  logic 	            RASPredPCWrongM,
  input  logic 	            PredictionInstrClassWrongM,
  input  logic              BPPredWrongM,                              // branch predictor is wrong
  input  logic [3:0]        InstrClassM,
  input  logic              JumpOrTakenBranchM,                               // actual instruction class
  input  logic 	            DCacheMiss,
  input  logic 	            DCacheAccess,
  input  logic 	            ICacheMiss,
  input  logic 	            ICacheAccess,
  input  logic [11:0] 	    CSRAdrM,
  input  logic [1:0] 	      PrivilegeModeW,
  input  logic [`XLEN-1:0]  CSRWriteValM,
  input  logic [31:0] 	    MCOUNTINHIBIT_REGW, MCOUNTEREN_REGW, SCOUNTEREN_REGW,
  input  logic [63:0] 	    MTIME_CLINT, 
  output logic [`XLEN-1:0]  CSRCReadValM,
  output logic 	            IllegalCSRCAccessM
);

  logic [4:0]               CounterNumM;
  logic [`XLEN-1:0] HPMCOUNTER_REGW[`COUNTERS-1:0];
  logic [`XLEN-1:0]         HPMCOUNTERH_REGW[`COUNTERS-1:0];
  logic                     LoadStallE, LoadStallM;
  logic [`COUNTERS-1:0]     WriteHPMCOUNTERM;
  logic [`COUNTERS-1:0]     CounterEvent;
  logic [63:0]              HPMCOUNTERPlusM[`COUNTERS-1:0];
  logic [`XLEN-1:0]         NextHPMCOUNTERM[`COUNTERS-1:0];
  genvar i;

  // Interface signals
  flopenrc #(1) LoadStallEReg(.clk, .reset, .clear(1'b0), .en(~StallE), .d(LoadStallD), .q(LoadStallE));  // don't flush the load stall during a load stall.
  flopenrc #(1) LoadStallMReg(.clk, .reset, .clear(FlushM), .en(~StallM), .d(LoadStallE), .q(LoadStallM));	
  
  // Determine when to increment each counter
  assign CounterEvent[0] = 1'b1;                                                        // MCYCLE always increments
  assign CounterEvent[1] = 1'b0;                                                        // Counter 1 doesn't exist
  assign CounterEvent[2] = InstrValidNotFlushedM;                                       // MINSTRET instructions retired
  if(`QEMU) begin: cevent // No other performance counters in QEMU
    assign CounterEvent[`COUNTERS-1:3] = 0;
  end else begin: cevent                                                                // User-defined counters
    assign CounterEvent[3] = LoadStallM;                                                // Load Stalls. don't want to suppress on flush as this only happens if flushed.
    assign CounterEvent[4] = DirPredictionWrongM & InstrValidNotFlushedM;               // Branch predictor wrong direction
    assign CounterEvent[5] = InstrClassM[0] & InstrValidNotFlushedM;                    // branch instruction
    assign CounterEvent[6] = BTBPredPCWrongM & InstrValidNotFlushedM;                   // branch predictor wrong target
    assign CounterEvent[7] = JumpOrTakenBranchM & InstrValidNotFlushedM;                // jump or taken branch instructions
    assign CounterEvent[8] = RASPredPCWrongM & InstrValidNotFlushedM;                   // return address stack wrong address
    assign CounterEvent[9] = InstrClassM[2] & InstrValidNotFlushedM;                    // return instructions
    assign CounterEvent[10] = PredictionInstrClassWrongM & InstrValidNotFlushedM;       // instruction class predictor wrong
    assign CounterEvent[11] = DCacheAccess;                                             // data cache access
    assign CounterEvent[12] = DCacheMiss;                                               // data cache miss
    assign CounterEvent[13] = ICacheAccess;                                             // instruction cache access
    assign CounterEvent[14] = ICacheMiss;                                               // instruction cache miss
	assign CounterEvent[15] = BPPredWrongM & InstrValidNotFlushedM;                     // branch predictor wrong
    assign CounterEvent[`COUNTERS-1:16] = 0; // eventually give these sources, including FP instructions, I$/D$ misses, branches and mispredictions
  end
  
  // Counter update and write logic
  for (i = 0; i < `COUNTERS; i = i+1) begin:cntr
      assign WriteHPMCOUNTERM[i] = CSRMWriteM & (CSRAdrM == MHPMCOUNTERBASE + i);
      assign NextHPMCOUNTERM[i][`XLEN-1:0] = WriteHPMCOUNTERM[i] ? CSRWriteValM : HPMCOUNTERPlusM[i][`XLEN-1:0];
      always_ff @(posedge clk) //, posedge reset) // ModelSim doesn't like syntax of passing array element to flop
        if (reset) HPMCOUNTER_REGW[i][`XLEN-1:0] <= #1 0;
        else       HPMCOUNTER_REGW[i][`XLEN-1:0] <= #1 NextHPMCOUNTERM[i];

      if (`XLEN==32) begin // write high and low separately
        logic [`COUNTERS-1:0] WriteHPMCOUNTERHM;
        logic [`XLEN-1:0] NextHPMCOUNTERHM[`COUNTERS-1:0];
        assign HPMCOUNTERPlusM[i] = {HPMCOUNTERH_REGW[i], HPMCOUNTER_REGW[i]} + {63'b0, CounterEvent[i] & ~MCOUNTINHIBIT_REGW[i]};
        assign WriteHPMCOUNTERHM[i] = CSRMWriteM & (CSRAdrM == MHPMCOUNTERHBASE + i);
        assign NextHPMCOUNTERHM[i] = WriteHPMCOUNTERHM[i] ? CSRWriteValM : HPMCOUNTERPlusM[i][63:32];
        always_ff @(posedge clk) //, posedge reset) // ModelSim doesn't like syntax of passing array element to flop
            if (reset) HPMCOUNTERH_REGW[i][`XLEN-1:0] <= #1 0;
            else       HPMCOUNTERH_REGW[i][`XLEN-1:0] <= #1 NextHPMCOUNTERHM[i];
      end else begin // XLEN=64; write entire register
          assign HPMCOUNTERPlusM[i] = HPMCOUNTER_REGW[i] + {63'b0, CounterEvent[i] & ~MCOUNTINHIBIT_REGW[i]};
      end
  end

  // Read Counters, or cause excepiton if insufficient privilege in light of COUNTEREN flags
  assign CounterNumM = CSRAdrM[4:0]; // which counter to read?
  always_comb 
    if (PrivilegeModeW == `M_MODE | 
        MCOUNTEREN_REGW[CounterNumM] & (!`S_SUPPORTED | PrivilegeModeW == `S_MODE | SCOUNTEREN_REGW[CounterNumM])) begin
      IllegalCSRCAccessM = 0;
      if (`XLEN==64) begin // 64-bit counter reads
        // Veri lator doesn't realize this only occurs for XLEN=64
        /* verilator lint_off WIDTH */  
        if      (CSRAdrM == TIME)  CSRCReadValM = MTIME_CLINT; // TIME register is a shadow of the memory-mapped MTIME from the CLINT
        /* verilator lint_on WIDTH */  
        else if (CSRAdrM >= MHPMCOUNTERBASE & CSRAdrM < MHPMCOUNTERBASE+`COUNTERS) CSRCReadValM = HPMCOUNTER_REGW[CounterNumM];
        else if (CSRAdrM >= HPMCOUNTERBASE & CSRAdrM  < HPMCOUNTERBASE+`COUNTERS)  CSRCReadValM = HPMCOUNTER_REGW[CounterNumM];
        else begin
            CSRCReadValM = 0;
            IllegalCSRCAccessM = 1;  // requested CSR doesn't exist
        end
      end else begin // 32-bit counter reads
        // Veri lator doesn't realize this only occurs for XLEN=32
        /* verilator lint_off WIDTH */  
        if      (CSRAdrM == TIME)  CSRCReadValM = MTIME_CLINT[31:0];// TIME register is a shadow of the memory-mapped MTIME from the CLINT
        else if (CSRAdrM == TIMEH) CSRCReadValM = MTIME_CLINT[63:32];
        /* verilator lint_on WIDTH */  
        else if (CSRAdrM >= MHPMCOUNTERBASE  & CSRAdrM < MHPMCOUNTERBASE+`COUNTERS)   CSRCReadValM = HPMCOUNTER_REGW[CounterNumM];
        else if (CSRAdrM >= HPMCOUNTERBASE   & CSRAdrM < HPMCOUNTERBASE+`COUNTERS)    CSRCReadValM = HPMCOUNTER_REGW[CounterNumM];
        else if (CSRAdrM >= MHPMCOUNTERHBASE & CSRAdrM < MHPMCOUNTERHBASE+`COUNTERS)  CSRCReadValM = HPMCOUNTERH_REGW[CounterNumM];
        else if (CSRAdrM >= HPMCOUNTERHBASE  & CSRAdrM < HPMCOUNTERHBASE+`COUNTERS)   CSRCReadValM = HPMCOUNTERH_REGW[CounterNumM];
        else begin
          CSRCReadValM = 0;
          IllegalCSRCAccessM = 1; // requested CSR doesn't exist
        end            
      end
    end else begin 
      CSRCReadValM = 0;
      IllegalCSRCAccessM = 1; // no privileges for this csr
    end
endmodule

//  mounteren should only exist if u-mode exists
