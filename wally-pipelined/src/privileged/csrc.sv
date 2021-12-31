

///////////////////////////////////////////
// csrc.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Counter CSRs
//          See RISC-V Privileged Mode Specification 20190608 3.1.10-11
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
module csrc #(parameter 
  MHPMCOUNTERBASE = 12'hB00,
  MHPMCOUNTERHBASE = 12'hB80,
  HPMCOUNTERBASE = 12'hC00,
  HPMCOUNTERHBASE = 12'hC80,
  TIME  = 12'hC01,
  TIMEH = 12'hC81
) (
    input logic 	     clk, reset,
    input logic 	     StallE, StallM, StallW,
    input  logic       FlushE, FlushM, FlushW,   
    input logic 	     InstrValidM, LoadStallD, CSRMWriteM,
    input logic 	     BPPredDirWrongM,
    input logic 	     BTBPredPCWrongM,
    input logic 	     RASPredPCWrongM,
    input logic 	     BPPredClassNonCFIWrongM,
    input logic [4:0] 	     InstrClassM,
    input logic 	     DCacheMiss,
    input logic 	     DCacheAccess,
    input logic [11:0] 	     CSRAdrM,
    input logic [1:0] 	     PrivilegeModeW,
    input logic [`XLEN-1:0]  CSRWriteValM,
    input logic [31:0] 	     MCOUNTINHIBIT_REGW, MCOUNTEREN_REGW, SCOUNTEREN_REGW,
    input logic [63:0] 	     MTIME_CLINT, 
    output logic [`XLEN-1:0] CSRCReadValM,
    output logic 	     IllegalCSRCAccessM
  );

  generate
    if (`ZICOUNTERS_SUPPORTED) begin:counters
     (* mark_debug = "true" *) logic [63:0] CYCLE_REGW, INSTRET_REGW;
      logic [63:0] CYCLEPlusM, INSTRETPlusM;
      logic [`XLEN-1:0] NextCYCLEM, NextINSTRETM;
      logic        WriteCYCLEM, WriteINSTRETM;
      logic [4:0]  CounterNumM;
      logic [`XLEN-1:0] HPMCOUNTER_REGW[`COUNTERS-1:0];
      logic [`XLEN-1:0] HPMCOUNTERH_REGW[`COUNTERS-1:0];
      logic 			       InstrValidNotFlushedM;
      logic LoadStallE, LoadStallM;
      logic [`COUNTERS-1:0] WriteHPMCOUNTERM;
      logic [`COUNTERS-1:0] CounterEvent;
      logic [63:0]      HPMCOUNTERPlusM[`COUNTERS-1:0];
      logic [`XLEN-1:0] NextHPMCOUNTERM[`COUNTERS-1:0];
      genvar i;

      // Interface signals
      flopenrc #(1) LoadStallEReg(.clk, .reset, .clear(1'b0), .en(~StallE), .d(LoadStallD), .q(LoadStallE));  // don't flush the load stall during a load stall.
      flopenrc #(1) LoadStallMReg(.clk, .reset, .clear(FlushM), .en(~StallM), .d(LoadStallE), .q(LoadStallM));	
      assign InstrValidNotFlushedM = InstrValidM & ~StallW & ~FlushW;
      
      // Determine when to increment each counter
      assign CounterEvent[0] = 1'b1;  // MCYCLE always increments
      assign CounterEvent[1] = 1'b0;  // Counter 0 doesn't exist
      assign CounterEvent[2] = InstrValidNotFlushedM;
     if(`QEMU) begin // No other performance counters in QEMU
        assign CounterEvent[`COUNTERS-1:3] = 0;
      end else begin // User-defined counters
        assign CounterEvent[3] = LoadStallM;  // don't want to suppress on flush as this only happens if flushed.
        assign CounterEvent[4] = BPPredDirWrongM & InstrValidNotFlushedM;
        assign CounterEvent[5] = InstrClassM[0] & InstrValidNotFlushedM;
        assign CounterEvent[6] = BTBPredPCWrongM & InstrValidNotFlushedM;
        assign CounterEvent[7] = (InstrClassM[4] | InstrClassM[2] | InstrClassM[1]) & InstrValidNotFlushedM;
        assign CounterEvent[8] = RASPredPCWrongM & InstrValidNotFlushedM;
        assign CounterEvent[9] = InstrClassM[3] & InstrValidNotFlushedM;
        assign CounterEvent[10] = BPPredClassNonCFIWrongM & InstrValidNotFlushedM;
        assign CounterEvent[11] = DCacheAccess;
        assign CounterEvent[12] = DCacheMiss;      
        assign CounterEvent[`COUNTERS-1:13] = 0; // eventually give these sources, including FP instructions, I$/D$ misses, branches and mispredictions
      end
      
      // Counter update and write logic
      for (i = 0; i < `COUNTERS; i = i+1) begin
          assign WriteHPMCOUNTERM[i] = CSRMWriteM && (CSRAdrM == MHPMCOUNTERBASE + i);
          assign NextHPMCOUNTERM[i][`XLEN-1:0] = WriteHPMCOUNTERM[i] ? CSRWriteValM : HPMCOUNTERPlusM[i][`XLEN-1:0];
          always_ff @(posedge clk) //, posedge reset) // ModelSim doesn't like syntax of passing array element to flop
            if (reset) HPMCOUNTER_REGW[i][`XLEN-1:0] <= #1 0;
            else       HPMCOUNTER_REGW[i][`XLEN-1:0] <= #1 NextHPMCOUNTERM[i];

          if (`XLEN==32) begin // write high and low separately
            logic [`COUNTERS-1:0] WriteHPMCOUNTERHM;
            logic [`XLEN-1:0] NextHPMCOUNTERHM[`COUNTERS-1:0];
            assign HPMCOUNTERPlusM[i] = {HPMCOUNTERH_REGW[i], HPMCOUNTER_REGW[i]} + {63'b0, CounterEvent[i] & ~MCOUNTINHIBIT_REGW[i]};
            assign WriteHPMCOUNTERHM[i] = CSRMWriteM && (CSRAdrM == MHPMCOUNTERHBASE + i);
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
        if (PrivilegeModeW == `M_MODE || 
            MCOUNTEREN_REGW[CounterNumM] && (!`S_SUPPORTED || PrivilegeModeW == `S_MODE || SCOUNTEREN_REGW[CounterNumM])) begin
          IllegalCSRCAccessM = 0;
          if (`XLEN==64) begin // 64-bit counter reads
            // Veri lator doesn't realize this only occurs for XLEN=64
            /* verilator lint_off WIDTH */  
            if      (CSRAdrM == TIME)  CSRCReadValM = MTIME_CLINT; // TIME register is a shadow of the memory-mapped MTIME from the CLINT
            /* verilator lint_on WIDTH */  
            else if (CSRAdrM >= MHPMCOUNTERBASE && CSRAdrM < MHPMCOUNTERBASE+`COUNTERS) CSRCReadValM = HPMCOUNTER_REGW[CounterNumM];
            else if (CSRAdrM >= HPMCOUNTERBASE && CSRAdrM  < HPMCOUNTERBASE+`COUNTERS)  CSRCReadValM = HPMCOUNTER_REGW[CounterNumM];
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
            else if (CSRAdrM >= MHPMCOUNTERBASE  && CSRAdrM < MHPMCOUNTERBASE+`COUNTERS)   CSRCReadValM = HPMCOUNTER_REGW[CounterNumM];
            else if (CSRAdrM >= HPMCOUNTERBASE   && CSRAdrM < HPMCOUNTERBASE+`COUNTERS)    CSRCReadValM = HPMCOUNTER_REGW[CounterNumM];
            else if (CSRAdrM >= MHPMCOUNTERHBASE && CSRAdrM < MHPMCOUNTERHBASE+`COUNTERS)  CSRCReadValM = HPMCOUNTERH_REGW[CounterNumM];
            else if (CSRAdrM >= HPMCOUNTERHBASE  && CSRAdrM < HPMCOUNTERHBASE+`COUNTERS)   CSRCReadValM = HPMCOUNTERH_REGW[CounterNumM];
            else begin
              CSRCReadValM = 0;
              IllegalCSRCAccessM = 1; // requested CSR doesn't exist
            end            
          end
        end else begin 
          CSRCReadValM = 0;
          IllegalCSRCAccessM = 1; // no privileges for this csr
        end
    end else begin
      assign CSRCReadValM = 0;
      assign IllegalCSRCAccessM = 1; // counters aren't enabled
    end
  endgenerate
endmodule

