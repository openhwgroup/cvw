

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
// Ben 06/17/21: I brought in MTIME, MTIMECMP from CLINT. *** this probably isn't perfect though because it doesn't yet provide the ability to change these through CSR writes; overall this whole thing might need some rethinking
module csrc #(parameter 
  MCYCLE = 12'hB00,
  MTIME = 12'hB01, // address not specified in privileged spec.  Consider moving to CLINT to match SiFive
  MTIMECMP = 12'hB21, // not specified in privileged spec.  Move to CLINT
  MINSTRET = 12'hB02,
  MHPMCOUNTERBASE = 12'hB00,
  //MHPMCOUNTER3 = 12'hB03,
  //MHPMCOUNTER4 = 12'hB04,
  // ... more counters
  //MHPMCOUNTER31 = 12'hB1F,
  MCYCLEH = 12'hB80,
  MTIMEH = 12'hB81,  // address not specified in privileged spec.  Consider moving to CLINT to match SiFive
  MTIMECMPH = 12'hBA1, // not specified in privileged spec.  Move to CLINT
  MINSTRETH = 12'hB82,
  MHPMCOUNTERHBASE = 12'hB80,
  //MHPMCOUNTER3H = 12'hB83,
  //MHPMCOUNTER4H = 12'hB84,
  // ... more counters
  //MHPMCOUNTER31H = 12'hB9F,
  MCOUNTERINHIBIT = 12'h320,
  MHPMEVENTBASE = 12'h320,
  //MHPMEVENT3 = 12'h323,
  //MHPMEVENT4 = 12'h324,
  // ... more counters
  //MHPMEVENT31 = 12'h33F,
  CYCLE = 12'hC00, 
  TIME = 12'hC01, 
  INSTRET = 12'hC02,
  HPMCOUNTERBASE = 12'hC00,
  //HPMCOUNTER3 = 12'hC03,
  //HPMCOUNTER4 = 12'hC04,
  //  ...more counters
  //HPMCOUNTER31 = 12'hC1F,
  CYCLEH = 12'hC80,
  TIMEH = 12'hC81, // not specified
  INSTRETH = 12'hC82,
  HPMCOUNTERHBASE = 12'hC80
  //HPMCOUNTER3H = 12'hC83,
  //HPMCOUNTER4H = 12'hC84,
  //  ... more counters
  //HPMCOUNTER31H = 12'hC9F
) (
    input  logic             clk, reset,
    input  logic             StallD, StallE, StallM, StallW,
    input  logic             InstrValidW, LoadStallD, CSRMWriteM,
    input  logic             BPPredDirWrongM,
    input  logic             BTBPredPCWrongM,
    input  logic             RASPredPCWrongM,
    input  logic             BPPredClassNonCFIWrongM,
    input  logic [4:0]       InstrClassM,
    input  logic [11:0]      CSRAdrM,
    input  logic [1:0]       PrivilegeModeW,
    input  logic [`XLEN-1:0] CSRWriteValM,
    input  logic [31:0]      MCOUNTINHIBIT_REGW, MCOUNTEREN_REGW, SCOUNTEREN_REGW,
    input  logic [63:0]      MTIME_CLINT, MTIMECMP_CLINT,
    output logic [`XLEN-1:0] CSRCReadValM,
    output logic             IllegalCSRCAccessM
  );

  generate 
    if (`ZCOUNTERS_SUPPORTED) begin
      //  logic [63:0] TIME_REGW, TIMECMP_REGW;
      logic [63:0] CYCLE_REGW, INSTRET_REGW;
      logic [63:0] HPMCOUNTER3_REGW, HPMCOUNTER4_REGW; // add more performance counters here if desired
      logic [63:0] CYCLEPlusM, INSTRETPlusM;
      logic [63:0] HPMCOUNTER3PlusM, HPMCOUNTER4PlusM;
    //  logic [`XLEN-1:0] NextTIMEM;
      logic [`XLEN-1:0] NextCYCLEM, NextINSTRETM;
      logic [`XLEN-1:0] NextHPMCOUNTER3M, NextHPMCOUNTER4M;
      logic        WriteCYCLEM, WriteINSTRETM;
      logic        WriteHPMCOUNTER3M, WriteHPMCOUNTER4M;
      logic [4:0]  CounterNumM;
      logic [`COUNTERS-1:3][`XLEN-1:0] HPMCOUNTER_REGW, HPMCOUNTERH_REGW;
      //logic [`COUNTERS-1:3][`XLEN-1:0] HPMCOUNTERH_REGW;

      // Write enables
      //  assign WriteTIMEM = CSRMWriteM && (CSRAdrM == MTIME);
      //  assign WriteTIMECMPM = CSRMWriteM && (CSRAdrM == MTIMECMP);
      assign WriteCYCLEM = CSRMWriteM && (CSRAdrM == MCYCLE);
      assign WriteINSTRETM = CSRMWriteM && (CSRAdrM == MINSTRET);
      //assign WriteHPMCOUNTER3M = CSRMWriteM && (CSRAdrM == MHPMCOUNTER3);
      //assign WriteHPMCOUNTER4M = CSRMWriteM && (CSRAdrM == MHPMCOUNTER4);

      // Counter adders with inhibits for power savings
      assign CYCLEPlusM = CYCLE_REGW + {63'b0, ~MCOUNTINHIBIT_REGW[0]};
      //assign TIMEPlusM = TIME_REGW + 1; // can't be inhibited
      assign INSTRETPlusM = INSTRET_REGW + {63'b0, InstrValidW & ~MCOUNTINHIBIT_REGW[2]};
      //assign HPMCOUNTER3PlusM = HPMCOUNTER3_REGW + {63'b0, LoadStallD & ~MCOUNTINHIBIT_REGW[3]}; // count load stalls
      //assign HPMCOUNTER4PlusM = HPMCOUNTER4_REGW + {63'b0, 1'b0 & ~MCOUNTINHIBIT_REGW[4]}; // change to count signals
      assign NextCYCLEM = WriteCYCLEM ? CSRWriteValM : CYCLEPlusM[`XLEN-1:0];
      //assign NextTIMEM = WriteTIMEM ? CSRWriteValM : TIMEPlusM[`XLEN-1:0];
      assign NextINSTRETM = WriteINSTRETM ? CSRWriteValM : INSTRETPlusM[`XLEN-1:0];
      //assign NextHPMCOUNTER3M = WriteHPMCOUNTER3M ? CSRWriteValM : HPMCOUNTER3PlusM[`XLEN-1:0]; 
      //assign NextHPMCOUNTER4M = WriteHPMCOUNTER4M ? CSRWriteValM : HPMCOUNTER4PlusM[`XLEN-1:0];

    // parameterized number of additional counters
    if (`COUNTERS > 3) begin
        logic [`COUNTERS-1:3] WriteHPMCOUNTERM;
        logic [`COUNTERS-1:0] CounterEvent;
        logic [63:0] /*HPMCOUNTER_REGW[`COUNTERS-1:3], */ HPMCOUNTERPlusM[`COUNTERS-1:3];
        logic [`XLEN-1:0] NextHPMCOUNTERM[`COUNTERS-1:3];
        genvar i;

        // could replace special counters 0-2 with this loop for all counters
        assign CounterEvent[0] = 1'b1;
        assign CounterEvent[1] = 1'b0;
        assign CounterEvent[2] = InstrValidW & ~StallW;
        assign CounterEvent[3] = LoadStallD & ~StallD;
        assign CounterEvent[4] = BPPredDirWrongM & ~StallM;
        assign CounterEvent[5] = InstrClassM[0] & ~StallM;
        assign CounterEvent[6] = BTBPredPCWrongM & ~StallM;
        assign CounterEvent[7] = (InstrClassM[4] | InstrClassM[2] | InstrClassM[1]) & ~StallM;
        assign CounterEvent[8] = RASPredPCWrongM & ~StallM;
        assign CounterEvent[9] = InstrClassM[3] & ~StallM;
        assign CounterEvent[10] = BPPredClassNonCFIWrongM & ~StallM;
        assign CounterEvent[`COUNTERS-1:11] = 0; // eventually give these sources, including FP instructions, I$/D$ misses, branches and mispredictions

        for (i = 3; i < `COUNTERS; i = i+1) begin
            assign WriteHPMCOUNTERM[i] = CSRMWriteM && (CSRAdrM == MHPMCOUNTERBASE + i);
            assign NextHPMCOUNTERM[i][`XLEN-1:0] = WriteHPMCOUNTERM[i] ? CSRWriteValM : HPMCOUNTERPlusM[i][`XLEN-1:0];
            always @(posedge clk, posedge reset) // ModelSim doesn't like syntax of passing array element to flop
              if (reset) HPMCOUNTER_REGW[i][`XLEN-1:0] <= #1 0;
              else if (~StallW) HPMCOUNTER_REGW[i][`XLEN-1:0] <= #1 NextHPMCOUNTERM[i];
            //flopr #(`XLEN) HPMCOUNTERreg[i](clk, reset, NextHPMCOUNTERM[i], HPMCOUNTER_REGW[i]);

            if (`XLEN==32) begin
                logic [`COUNTERS-1:3] WriteHPMCOUNTERHM;
                logic [`XLEN-1:0] NextHPMCOUNTERHM[`COUNTERS-1:3];
                assign HPMCOUNTERPlusM[i] = {HPMCOUNTERH_REGW[i], HPMCOUNTER_REGW[i]} + {63'b0, CounterEvent[i] & ~MCOUNTINHIBIT_REGW[i]};
                assign WriteHPMCOUNTERHM[i] = CSRMWriteM && (CSRAdrM == MHPMCOUNTERHBASE + i);
                assign NextHPMCOUNTERHM[i] = WriteHPMCOUNTERHM[i] ? CSRWriteValM : HPMCOUNTERPlusM[i][63:32];
                always @(posedge clk, posedge reset) // ModelSim doesn't like syntax of passing array element to flop
                    if (reset) HPMCOUNTERH_REGW[i][`XLEN-1:0] <= #1 0;
                    else if (~StallW) HPMCOUNTERH_REGW[i][`XLEN-1:0] <= #1 NextHPMCOUNTERHM[i];
                //flopr #(`XLEN) HPMCOUNTERHreg[i](clk, reset, NextHPMCOUNTERHM[i], HPMCOUNTER_REGW[i][63:32]);
            end else begin
                assign HPMCOUNTERPlusM[i] = HPMCOUNTER_REGW[i] + {63'b0, CounterEvent[i] & ~MCOUNTINHIBIT_REGW[i]};
            end
        end
    end

      // Write / update counters
      // Only the Machine mode versions of the counter CSRs are writable
        if (`XLEN==64) begin// 64-bit counters
    //      flopr   #(64) TIMEreg(clk, reset,  WriteTIMEM ? CSRWriteValM : TIME_REGW + 1, TIME_REGW); // may count off a different clock***
    //      flopenr #(64) TIMECMPreg(clk, reset, WriteTIMECMPM, CSRWriteValM, TIMECMP_REGW);
          flopr   #(64) CYCLEreg(clk, reset, NextCYCLEM, CYCLE_REGW);
          flopr   #(64) INSTRETreg(clk, reset, NextINSTRETM, INSTRET_REGW);
          //flopr   #(64) HPMCOUNTER3reg(clk, reset, NextHPMCOUNTER3M, HPMCOUNTER3_REGW);
          //flopr   #(64) HPMCOUNTER4reg(clk, reset, NextHPMCOUNTER4M, HPMCOUNTER4_REGW);
        end else begin // 32-bit low and high counters
          logic  WriteTIMEHM, WriteTIMECMPHM, WriteCYCLEHM, WriteINSTRETHM;
          //logic  WriteHPMCOUNTER3HM, WriteHPMCOUNTER4HM;
          logic  [`XLEN-1:0] NextCYCLEHM, NextTIMEHM, NextINSTRETHM;
          //logic  [`XLEN-1:0] NextHPMCOUNTER3HM, NextHPMCOUNTER4HM;

          // Write Enables
    //      assign WriteTIMEHM = CSRMWriteM && (CSRAdrM == MTIMEH);
    //      assign WriteTIMECMPHM = CSRMWriteM && (CSRAdrM == MTIMECMPH);
          assign WriteCYCLEHM = CSRMWriteM && (CSRAdrM == MCYCLEH);
          assign WriteINSTRETHM = CSRMWriteM && (CSRAdrM == MINSTRETH);
          //assign WriteHPMCOUNTER3HM = CSRMWriteM && (CSRAdrM == MHPMCOUNTER3H);
          //assign WriteHPMCOUNTER4HM = CSRMWriteM && (CSRAdrM == MHPMCOUNTER4H);
          assign NextCYCLEHM = WriteCYCLEM ? CSRWriteValM : CYCLEPlusM[63:32];
    //      assign NextTIMEHM = WriteTIMEHM ? CSRWriteValM : TIMEPlusM[63:32];
          assign NextINSTRETHM = WriteINSTRETHM ? CSRWriteValM : INSTRETPlusM[63:32];
          //assign NextHPMCOUNTER3HM = WriteHPMCOUNTER3HM ? CSRWriteValM : HPMCOUNTER3PlusM[63:32]; 
          //assign NextHPMCOUNTER4HM = WriteHPMCOUNTER4HM ? CSRWriteValM : HPMCOUNTER4PlusM[63:32];

          // Counter CSRs
    //      flopr   #(32) TIMEreg(clk, reset,  NextTIMEM, TIME_REGW); // may count off a different clock***
    //      flopenr #(32) TIMECMPreg(clk, reset, WriteTIMECMPM, CSRWriteValM, TIMECMP_REGW[31:0]);
          flopr   #(32) CYCLEreg(clk, reset, NextCYCLEM, CYCLE_REGW[31:0]);
          flopr   #(32) INSTRETreg(clk, reset, NextINSTRETM, INSTRET_REGW[31:0]);
          //flopr   #(32) HPMCOUNTER3reg(clk, reset, NextHPMCOUNTER3M, HPMCOUNTER3_REGW[31:0]);
          //flopr   #(32) HPMCOUNTER4reg(clk, reset, NextHPMCOUNTER4M, HPMCOUNTER4_REGW[31:0]);
    //      flopr   #(32) TIMEHreg(clk, reset,  NextTIMEHM, TIME_REGW); // may count off a different clock***
    //      flopenr #(32) TIMECMPHreg(clk, reset, WriteTIMECMPHM, CSRWriteValM, TIMECMP_REGW[63:32]);
          flopr   #(32) CYCLEHreg(clk, reset, NextCYCLEHM, CYCLE_REGW[63:32]);
          flopr   #(32) INSTRETHreg(clk, reset, NextINSTRETHM, INSTRET_REGW[63:32]);
          //flopr   #(32) HPMCOUNTER3Hreg(clk, reset, NextHPMCOUNTER3HM, HPMCOUNTER3_REGW[63:32]);
          //flopr   #(32) HPMCOUNTER4Hreg(clk, reset, NextHPMCOUNTER4HM, HPMCOUNTER4_REGW[63:32]);
        end

    // eventually move TIME and TIMECMP to the CLINT -- Ben 06/17/21: sure let's give that a shot!
    //  run TIME off asynchronous reference clock
    //  synchronize write enable to TIME
    //  four phase handshake to synchronize reads from TIME

    // interrupt on timer compare
    // ability to disable optional CSRs
    
      // Read Counters, or cause excepiton if insufficient privilege in light of COUNTEREN flags
      assign CounterNumM = CSRAdrM[4:0]; // which counter to read?
        if (`XLEN==64) // 64-bit counter reads
          always_comb 
            if (PrivilegeModeW == `M_MODE || 
                MCOUNTEREN_REGW[CounterNumM] && (PrivilegeModeW == `S_MODE || SCOUNTEREN_REGW[CounterNumM])) begin
              IllegalCSRCAccessM = 0;
              if      (CSRAdrM >= MHPMCOUNTERBASE+3 && CSRAdrM < MHPMCOUNTERBASE+`COUNTERS) CSRCReadValM = HPMCOUNTER_REGW[CSRAdrM-MHPMCOUNTERBASE];
              else if (CSRAdrM >= HPMCOUNTERBASE+3 && CSRAdrM  < HPMCOUNTERBASE+`COUNTERS)  CSRCReadValM = HPMCOUNTER_REGW[CSRAdrM-HPMCOUNTERBASE];
              else case (CSRAdrM) 
                MTIME:     CSRCReadValM = MTIME_CLINT;
                MTIMECMP:  CSRCReadValM = MTIMECMP_CLINT;
                MCYCLE:       CSRCReadValM = CYCLE_REGW;
                MINSTRET:     CSRCReadValM = INSTRET_REGW;
                //MHPMCOUNTER3: CSRCReadValM = HPMCOUNTER3_REGW;
                //MHPMCOUNTER4: CSRCReadValM = HPMCOUNTER4_REGW;
                TIME:         CSRCReadValM = MTIME_CLINT;
                CYCLE:        CSRCReadValM = CYCLE_REGW;
                INSTRET:      CSRCReadValM = INSTRET_REGW;
                //HPMCOUNTER3:  CSRCReadValM = HPMCOUNTER3_REGW;
                //HPMCOUNTER4:  CSRCReadValM = HPMCOUNTER4_REGW;
                default:   begin
                  CSRCReadValM = 0;
                  IllegalCSRCAccessM = 1;
                end
              endcase
            end else begin 
              IllegalCSRCAccessM = 1; // no privileges for this csr
              CSRCReadValM = 0;
            end
        else // 32-bit counter reads
          always_comb 
            if (PrivilegeModeW == `M_MODE || MCOUNTEREN_REGW[CounterNumM] && (PrivilegeModeW == `S_MODE || SCOUNTEREN_REGW[CounterNumM])) begin
              IllegalCSRCAccessM = 0;
              if      (CSRAdrM >= MHPMCOUNTERBASE+3 && CSRAdrM  < MHPMCOUNTERBASE+`COUNTERS)  CSRCReadValM = HPMCOUNTER_REGW[CSRAdrM-MHPMCOUNTERBASE];
              else if (CSRAdrM >= HPMCOUNTERBASE+3 && CSRAdrM   < HPMCOUNTERBASE+`COUNTERS)   CSRCReadValM = HPMCOUNTER_REGW[CSRAdrM-HPMCOUNTERBASE];
              else if (CSRAdrM >= MHPMCOUNTERHBASE+3 && CSRAdrM < MHPMCOUNTERHBASE+`COUNTERS) CSRCReadValM = HPMCOUNTERH_REGW[CSRAdrM-MHPMCOUNTERHBASE];
              else if (CSRAdrM >= HPMCOUNTERHBASE+3 && CSRAdrM  < HPMCOUNTERHBASE+`COUNTERS)  CSRCReadValM = HPMCOUNTERH_REGW[CSRAdrM-HPMCOUNTERHBASE];
              else case (CSRAdrM) 
                MTIME:     CSRCReadValM = MTIME_CLINT[31:0];
                MTIMECMP:  CSRCReadValM = MTIMECMP_CLINT[31:0];
                MCYCLE:       CSRCReadValM = CYCLE_REGW[31:0];
                MINSTRET:     CSRCReadValM = INSTRET_REGW[31:0];
                //MHPMCOUNTER3: CSRCReadValM = HPMCOUNTER3_REGW[31:0];
                //MHPMCOUNTER4: CSRCReadValM = HPMCOUNTER4_REGW[31:0];
                TIME:         CSRCReadValM = MTIME_CLINT[31:0];
                CYCLE:        CSRCReadValM = CYCLE_REGW[31:0];
                INSTRET:      CSRCReadValM = INSTRET_REGW[31:0];
                //HPMCOUNTER3:  CSRCReadValM = HPMCOUNTER3_REGW[31:0];
                //HPMCOUNTER4:  CSRCReadValM = HPMCOUNTER4_REGW[31:0];
                MTIMEH:     CSRCReadValM = MTIME_CLINT[63:32];
                MTIMECMPH:  CSRCReadValM = MTIMECMP_CLINT[63:32];
                MCYCLEH:       CSRCReadValM = CYCLE_REGW[63:32];
                MINSTRETH:     CSRCReadValM = INSTRET_REGW[63:32];
                //MHPMCOUNTER3H: CSRCReadValM = HPMCOUNTER3_REGW[63:32];
                //MHPMCOUNTER4H: CSRCReadValM = HPMCOUNTER4_REGW[63:32];
                TIMEH:         CSRCReadValM = MTIME_CLINT[63:32];
                CYCLEH:        CSRCReadValM = CYCLE_REGW[63:32];
                INSTRETH:      CSRCReadValM = INSTRET_REGW[63:32];
                //HPMCOUNTER3H:  CSRCReadValM = HPMCOUNTER3_REGW[63:32];
                //HPMCOUNTER4H:  CSRCReadValM = HPMCOUNTER4_REGW[63:32];
                default:   begin
                  CSRCReadValM = 0;
                  IllegalCSRCAccessM = 1;
                end
              endcase
            end else begin 
              IllegalCSRCAccessM = 1; // no privileges for this csr
              CSRCReadValM = 0;
            end
    end else begin
      assign CSRCReadValM = 0;
      assign IllegalCSRCAccessM = 1;
    end
  endgenerate
endmodule

/* Bad code from class

///////////////////////////////////////////
// csrc.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified:ssanghai@hmc.edu 2nd March 
// Added a configurable number of counters
//          dottolia@hmc.edu 20 April 2021
// Make counters synthesizable
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
  // counters
  MHPMCOUNTERBASE = 12'hB00,
  MHPMCOUNTERHBASE = 12'hB80,
  MPHMEVENTBASE = 12'h320,
  HPMCOUNTERBASE = 12'hC00,
  HPMCOUNTERHBASE = 12'hC80,
  )(input logic 	     clk, reset,
    input logic 	     StallD, StallE, StallM, StallW,
    input logic 	     InstrValidW, LoadStallD, CSRMWriteM,
    input logic 	     BPPredDirWrongM,
    input logic 	     BTBPredPCWrongM,
    input logic 	     RASPredPCWrongM,
    input logic 	     BPPredClassNonCFIWrongM,
    input logic [4:0] 	     InstrClassM,
    input logic [11:0] 	     CSRAdrM,
    input logic [1:0] 	     PrivilegeModeW,
    input logic [`XLEN-1:0]  CSRWriteValM,
    input logic [31:0] 	     MCOUNTINHIBIT_REGW, MCOUNTEREN_REGW, SCOUNTEREN_REGW,
    output logic [`XLEN-1:0] CSRCReadValM,
    output logic 	     IllegalCSRCAccessM);

    // counters


    // create Counter arrays to store address of each counter 
    integer MHPMCOUNTER [`COUNTERS:0];
    integer MHPMCOUNTERH [`COUNTERS:0]; 
    integer HPMCOUNTER [`COUNTERS:0];
    integer HPMCOUNTERH [`COUNTERS:0];
    integer MHPEVENT [`COUNTERS:0];

    genvar i;
    // *** this is totally incorrect.  Fix parameterized counters dh 6/9/21
    generate
    for (i = 0; i <= `COUNTERS; i = i + 1) begin 
        if (i != 1) begin
            always @(posedge reset) begin
                MHPMCOUNTER[i] = 12'hB00 + i;  // not sure this addition is legit 
                MHPMCOUNTERH[i] = 12'hB80 + i; 
                HPMCOUNTER[i] = 12'hC00 + i;
                HPMCOUNTERH[i] = 12'hC80 + i;
                MHPEVENT[i] = 12'h320 + i; // MHPEVENT[0] = MCOUNTERINHIBIT
            end
        end 
    end //end for loop
    endgenerate

    logic [`COUNTERS:0] MCOUNTEN;
    assign MCOUNTEN[0] = 1'b1;
    assign MCOUNTEN[1] = 1'b0;
    assign MCOUNTEN[2] = InstrValidW & ~StallW;
    assign MCOUNTEN[3] = LoadStallD & ~StallD;
    assign MCOUNTEN[4] = BPPredDirWrongM & ~StallM;
    assign MCOUNTEN[5] = InstrClassM[0] & ~StallM;
    assign MCOUNTEN[6] = BTBPredPCWrongM & ~StallM;
    assign MCOUNTEN[7] = (InstrClassM[4] | InstrClassM[2] | InstrClassM[1]) & ~StallM;
    assign MCOUNTEN[8] = RASPredPCWrongM & ~StallM;
    assign MCOUNTEN[9] = InstrClassM[3] & ~StallM;
    assign MCOUNTEN[10] = BPPredClassNonCFIWrongM & ~StallM;
    assign MCOUNTEN[`COUNTERS:11] = 0; 

    genvar j;       
    generate
        if (`ZCOUNTERS_SUPPORTED) begin
            logic [`COUNTERS:0][63:0] HPMCOUNTER_REGW;
            logic [`COUNTERS:0][63:0] HPMCOUNTERPlusM;
            logic [`COUNTERS:0][`XLEN-1:0] NextHPMCOUNTERM;
            logic [`COUNTERS:0]  WriteHPMCOUNTERM;
            logic [4:0]  CounterNumM;

            assign CounterNumM = CSRAdrM[4:0]; // which counter to read? *** 

            for (j=0; j<= `COUNTERS; j = j+1) begin 
                // Write enables
                if (j != 1) begin
                    assign WriteHPMCOUNTERM[j] = CSRMWriteM && (CSRAdrM == MHPMCOUNTER[j]);
                    // Count Signals 
                    assign HPMCOUNTERPlusM[j] = HPMCOUNTER_REGW[j] + {63'b0, MCOUNTEN[j] & ~MCOUNTINHIBIT_REGW[j]}; 
            
                    assign NextHPMCOUNTERM[j] = WriteHPMCOUNTERM[j] ? CSRWriteValM : HPMCOUNTERPlusM[j][`XLEN-1:0]; 
                end 

                // Write / update counters
                // Only the Machine mode versions of the counter CSRs are writable
                if (`XLEN==64) begin // 64-bit counters
                    flopenr   #(64) HPMCOUNTERreg_j(clk, reset, ~StallW, NextHPMCOUNTERM[j], HPMCOUNTER_REGW[j]);
                end
                else begin // 32-bit low and high counters
                    logic [`COUNTERS:0] WriteHPMCOUNTERHM;
                    logic  [`COUNTERS:0] [`XLEN-1:0] NextHPMCOUNTERHM;

                    // Write Enables
                    assign WriteHPMCOUNTERHM[j] = CSRMWriteM && (CSRAdrM == MHPMCOUNTERH[j]);
                    assign NextHPMCOUNTERHM[j] = WriteHPMCOUNTERHM[j] ? CSRWriteValM : HPMCOUNTERPlusM[j][63:32]; 

                    // Counter CSRs
                    flopenr   #(32) HPMCOUNTERreg_j(clk, reset, ~StallW, NextHPMCOUNTERM[j], HPMCOUNTER_REGW[j][31:0]);
                    flopenr   #(32) HPMCOUNTERHreg_j(clk, reset, ~StallW, NextHPMCOUNTERHM[j], HPMCOUNTER_REGW[j][63:32]);
                end
            end // end for 

            // eventually move TIME and TIMECMP to the CLINT
            //  run TIME off asynchronous reference clock
            //  synchronize write enable to TIME
            //  four phase handshake to synchronize reads from TIME

            // interrupt on timer compare
            // ability to disable optional CSRs
            
            // Read Counters, or cause excepiton if insufficient privilege in light of COUNTEREN flags
            if (`XLEN==64) begin // 64-bit counter reads
            always_comb 
                if (PrivilegeModeW == `M_MODE || 
                    MCOUNTEREN_REGW[CounterNumM] && (PrivilegeModeW == `S_MODE || SCOUNTEREN_REGW[CounterNumM])) begin

                    if (CSRAdrM[11:5] == MHPMCOUNTER[0][11:5] || CSRAdrM[11:5] == HPMCOUNTER[0][11:5]) begin
                        CSRCReadValM = HPMCOUNTER_REGW[CSRAdrM[4:0]];
                        IllegalCSRCAccessM = 0;
                    end 
                    // //case (CSRAdrM) 
                    //     MHPMCOUNTER[j]: CSRCReadValM = HPMCOUNTER_REGW[j];
                    //     HPMCOUNTER[j]:  CSRCReadValM = HPMCOUNTER_REGW[j];
                    //     default:   begin
                    //         CSRCReadValM = 0;
                    //         IllegalCSRCAccessM = 1;
                    //     end
                    // endcase
                    // end 
                    else begin 
                        IllegalCSRCAccessM = 1; // no privileges for this csr
                        CSRCReadValM = 0;
                    end 
                end 
                else begin 
                    IllegalCSRCAccessM = 1; // no privileges for this csr
                    CSRCReadValM = 0;
                end
            end
            else begin  // 32-bit counter reads
            always_comb 
                if (PrivilegeModeW == `M_MODE || 
                    MCOUNTEREN_REGW[CounterNumM] && (PrivilegeModeW == `S_MODE || SCOUNTEREN_REGW[CounterNumM])) begin

                    if (CSRAdrM[11:5] == MHPMCOUNTER[0][11:5] || CSRAdrM[11:5] == HPMCOUNTER[0][11:5] || 
                        CSRAdrM[11:5] == MHPMCOUNTERH[0][11:5] || CSRAdrM[11:5] == HPMCOUNTERH[0][11:5]) begin
                        CSRCReadValM = HPMCOUNTER_REGW[CSRAdrM[4:0]];
                        IllegalCSRCAccessM = 0;
                    end 
                    
                    else begin 
                        IllegalCSRCAccessM = 1; // no privileges for this csr
                        CSRCReadValM = 0;
                    end 

                    // IllegalCSRCAccessM = 0;
                    // case (CSRAdrM) 
                    //     MHPMCOUNTER[j]: CSRCReadValM = HPMCOUNTER_REGW[j][31:0];
                    //     HPMCOUNTER[j]:  CSRCReadValM = HPMCOUNTER_REGW[j][31:0];
                    //     MHPMCOUNTERH[j]: CSRCReadValM = HPMCOUNTER_REGW[j][63:32];
                    //     HPMCOUNTERH[j]:  CSRCReadValM = HPMCOUNTER_REGW[j][63:32];
                    //     default:   begin
                    //         CSRCReadValM = 0;
                    //         IllegalCSRCAccessM = 1;
                    //     end
                    // endcase
                end 
                else begin 
                    IllegalCSRCAccessM = 1; // no privileges for this csr
                    CSRCReadValM = 0;
                end
            end // 32-bit counter end 
        end // end for big if 
        else begin
            assign CSRCReadValM = 0;
            assign IllegalCSRCAccessM = 1;
        end // end for else
    endgenerate
endmodule
*/