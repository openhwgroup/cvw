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
  MCYCLE = 12'hB00,
//  MTIME = 12'hB01, // address not specified in privileged spec.  Consider moving to CLINT to match SiFive
 // MTIMECMP = 12'hB21, // not specified in privileged spec.  Move to CLINT
  MINSTRET = 12'hB02,
  MHPMCOUNTER3 = 12'hB03,
  MHPMCOUNTER4 = 12'hB04,
  // ... more counters
  MHPMCOUNTER31 = 12'hB1F,
  MCYCLEH = 12'hB80,
//  MTIMEH = 12'hB81,  // address not specified in privileged spec.  Consider moving to CLINT to match SiFive
//  MTIMECMPH = 12'hBA1, // not specified in privileged spec.  Move to CLINT
  MINSTRETH = 12'hB82,
  MHPMCOUNTER3H = 12'hB83,
  MHPMCOUNTER4H = 12'hB84,
  // ... more counters
  MHPMCOUNTER31H = 12'hB9F,
  MCOUNTERINHIBIT = 12'h320,
  MHPMEVENT3 = 12'h323,
  MHPMEVENT4 = 12'h324,
  // ... more counters
  MHPMEVENT31 = 12'h33F,
  CYCLE = 12'hC00, 
//  TIME = 12'hC01, // not specified
  INSTRET = 12'hC02,
  HPMCOUNTER3 = 12'hC03,
  HPMCOUNTER4 = 12'hC04,
  //  ...more counters
  HPMCOUNTER31 = 12'hC1F,
  CYCLEH = 12'hC80,
//  TIMEH = 12'hC81, // not specified
  INSTRETH = 12'hC82,
  HPMCOUNTER3H = 12'hC83,
  HPMCOUNTER4H = 12'hC84,
  //  ... more counters
  HPMCOUNTER31H = 12'hC9F
) (
    input  logic clk, reset,
    input  logic InstrValidW, LoadStallD, CSRMWriteM,
    input  logic [11:0] CSRAdrM,
    input  logic [1:0] PrivilegeModeW,
    input  logic [`XLEN-1:0] CSRWriteValM,
    input  logic [31:0] MCOUNTINHIBIT_REGW, MCOUNTEREN_REGW, SCOUNTEREN_REGW,
    output logic [`XLEN-1:0] CSRCReadValM,
    output logic            IllegalCSRCAccessM
  );

  generate 
    if (`ZCOUNTERS_SUPPORTED) begin
      //  logic [63:0] TIME_REGW, TIMECMP_REGW;
      logic [63:0] CYCLE_REGW, INSTRET_REGW;
      logic [63:0] HPMCOUNTER3_REGW, HPMCOUNTER4_REGW; // add more performance counters here if desired
      logic [63:0] CYCLEPlusM, TIMEPlusM, INSTRETPlusM;
      logic [63:0] HPMCOUNTER3PlusM, HPMCOUNTER4PlusM;
    //  logic [`XLEN-1:0] NextTIMEM;
      logic [`XLEN-1:0] NextCYCLEM, NextINSTRETM;
      logic [`XLEN-1:0] NextHPMCOUNTER3M, NextHPMCOUNTER4M;
      logic        WriteTIMEM, WriteTIMECMPM, WriteCYCLEM, WriteINSTRETM;
      logic        WriteHPMCOUNTER3M, WriteHPMCOUNTER4M;
      logic [4:0]  CounterNumM;

      // Write enables
      //  assign WriteTIMEM = CSRMWriteM && (CSRAdrM == MTIME);
      //  assign WriteTIMECMPM = CSRMWriteM && (CSRAdrM == MTIMECMP);
      assign WriteCYCLEM = CSRMWriteM && (CSRAdrM == MCYCLE);
      assign WriteINSTRETM = CSRMWriteM && (CSRAdrM == MINSTRET);
      assign WriteHPMCOUNTER3M = CSRMWriteM && (CSRAdrM == MHPMCOUNTER3);
      assign WriteHPMCOUNTER4M = CSRMWriteM && (CSRAdrM == MHPMCOUNTER4);

      // Counter adders with inhibits for power savings
      assign CYCLEPlusM = CYCLE_REGW + {63'b0, ~MCOUNTINHIBIT_REGW[0]};
    //  assign TIMEPlusM = TIME_REGW + 1; // can't be inhibited
      assign INSTRETPlusM = INSTRET_REGW + {63'b0, InstrValidW & ~MCOUNTINHIBIT_REGW[2]};
      assign HPMCOUNTER3PlusM = HPMCOUNTER3_REGW + {63'b0, LoadStallD & ~MCOUNTINHIBIT_REGW[3]}; // count load stalls
      assign HPMCOUNTER4PlusM = HPMCOUNTER4_REGW + {63'b0, 1'b0 & ~MCOUNTINHIBIT_REGW[4]}; // change to count signals
      assign NextCYCLEM = WriteCYCLEM ? CSRWriteValM : CYCLEPlusM[`XLEN-1:0];
    //  assign NextTIMEM = WriteTIMEM ? CSRWriteValM : TIMEPlusM[`XLEN-1:0];
      assign NextINSTRETM = WriteINSTRETM ? CSRWriteValM : INSTRETPlusM[`XLEN-1:0];
      assign NextHPMCOUNTER3M = WriteHPMCOUNTER3M ? CSRWriteValM : HPMCOUNTER3PlusM[`XLEN-1:0]; 
      assign NextHPMCOUNTER4M = WriteHPMCOUNTER4M ? CSRWriteValM : HPMCOUNTER4PlusM[`XLEN-1:0];

      // Write / update counters
      // Only the Machine mode versions of the counter CSRs are writable
        if (`XLEN==64) begin// 64-bit counters
    //      flopr   #(64) TIMEreg(clk, reset,  WriteTIMEM ? CSRWriteValM : TIME_REGW + 1, TIME_REGW); // may count off a different clock***
    //      flopenr #(64) TIMECMPreg(clk, reset, WriteTIMECMPM, CSRWriteValM, TIMECMP_REGW);
          flopr   #(64) CYCLEreg(clk, reset, NextCYCLEM, CYCLE_REGW);
          flopr   #(64) INSTRETreg(clk, reset, NextINSTRETM, INSTRET_REGW);
          flopr   #(64) HPMCOUNTER3reg(clk, reset, NextHPMCOUNTER3M, HPMCOUNTER3_REGW);
          flopr   #(64) HPMCOUNTER4reg(clk, reset, NextHPMCOUNTER4M, HPMCOUNTER4_REGW);
        end else begin // 32-bit low and high counters
          logic  WriteTIMEHM, WriteTIMECMPHM, WriteCYCLEHM, WriteINSTRETHM;
          logic  WriteHPMCOUNTER3HM, WriteHPMCOUNTER4HM;
          logic  [`XLEN-1:0] NextCYCLEHM, NextTIMEHM, NextINSTRETHM;
          logic  [`XLEN-1:0] NextHPMCOUNTER3HM, NextHPMCOUNTER4HM;

          // Write Enables
    //      assign WriteTIMEHM = CSRMWriteM && (CSRAdrM == MTIMEH);
    //      assign WriteTIMECMPHM = CSRMWriteM && (CSRAdrM == MTIMECMPH);
          assign WriteCYCLEHM = CSRMWriteM && (CSRAdrM == MCYCLEH);
          assign WriteINSTRETHM = CSRMWriteM && (CSRAdrM == MINSTRETH);
          assign WriteHPMCOUNTER3HM = CSRMWriteM && (CSRAdrM == MHPMCOUNTER3H);
          assign WriteHPMCOUNTER4HM = CSRMWriteM && (CSRAdrM == MHPMCOUNTER4H);
          assign NextCYCLEHM = WriteCYCLEM ? CSRWriteValM : CYCLEPlusM[63:32];
    //      assign NextTIMEHM = WriteTIMEHM ? CSRWriteValM : TIMEPlusM[63:32];
          assign NextINSTRETHM = WriteINSTRETHM ? CSRWriteValM : INSTRETPlusM[63:32];
          assign NextHPMCOUNTER3HM = WriteHPMCOUNTER3HM ? CSRWriteValM : HPMCOUNTER3PlusM[63:32]; 
          assign NextHPMCOUNTER4HM = WriteHPMCOUNTER4HM ? CSRWriteValM : HPMCOUNTER4PlusM[63:32];

          // Counter CSRs
    //      flopr   #(32) TIMEreg(clk, reset,  NextTIMEM, TIME_REGW); // may count off a different clock***
    //      flopenr #(32) TIMECMPreg(clk, reset, WriteTIMECMPM, CSRWriteValM, TIMECMP_REGW[31:0]);
          flopr   #(32) CYCLEreg(clk, reset, NextCYCLEM, CYCLE_REGW[31:0]);
          flopr   #(32) INSTRETreg(clk, reset, NextINSTRETM, INSTRET_REGW[31:0]);
          flopr   #(32) HPMCOUNTER3reg(clk, reset, NextHPMCOUNTER3M, HPMCOUNTER3_REGW[31:0]);
          flopr   #(32) HPMCOUNTER4reg(clk, reset, NextHPMCOUNTER4M, HPMCOUNTER4_REGW[31:0]);
    //      flopr   #(32) TIMEHreg(clk, reset,  NextTIMEHM, TIME_REGW); // may count off a different clock***
    //      flopenr #(32) TIMECMPHreg(clk, reset, WriteTIMECMPHM, CSRWriteValM, TIMECMP_REGW[63:32]);
          flopr   #(32) CYCLEHreg(clk, reset, NextCYCLEHM, CYCLE_REGW[63:32]);
          flopr   #(32) INSTRETHreg(clk, reset, NextINSTRETHM, INSTRET_REGW[63:32]);
          flopr   #(32) HPMCOUNTER3Hreg(clk, reset, NextHPMCOUNTER3HM, HPMCOUNTER3_REGW[63:32]);
          flopr   #(32) HPMCOUNTER4Hreg(clk, reset, NextHPMCOUNTER4HM, HPMCOUNTER4_REGW[63:32]);
        end

    // eventually move TIME and TIMECMP to the CLINT
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
              case (CSRAdrM) 
      //          MTIME:        CSRCReadValM = TIME_REGW;
      //          MTIMECMP:     CSRCReadValM = TIMECMP_REGW;
                MCYCLE:       CSRCReadValM = CYCLE_REGW;
                MINSTRET:     CSRCReadValM = INSTRET_REGW;
                MHPMCOUNTER3: CSRCReadValM = HPMCOUNTER3_REGW;
                MHPMCOUNTER4: CSRCReadValM = HPMCOUNTER4_REGW;
      //          TIME:         CSRCReadValM = TIME_REGW;
                CYCLE:        CSRCReadValM = CYCLE_REGW;
                INSTRET:      CSRCReadValM = INSTRET_REGW;
                HPMCOUNTER3:  CSRCReadValM = HPMCOUNTER3_REGW;
                HPMCOUNTER4:  CSRCReadValM = HPMCOUNTER4_REGW;
                default:   begin
                  CSRCReadValM = 0;
                  IllegalCSRCAccessM = 1;
                end
              endcase
            end else IllegalCSRCAccessM = 1; // no privileges for this coute
        else // 32-bit counter reads
          always_comb 
            if (PrivilegeModeW == `M_MODE || 
                MCOUNTEREN_REGW[CounterNumM] && (PrivilegeModeW == `S_MODE || SCOUNTEREN_REGW[CounterNumM])) begin
              IllegalCSRCAccessM = 0;
              case (CSRAdrM) 
      //          MTIME:        CSRCReadValM = TIME_REGW[31:0];
      //          MTIMECMP:     CSRCReadValM = TIMECMP_REGW[31:0];
                MCYCLE:       CSRCReadValM = CYCLE_REGW[31:0];
                MINSTRET:     CSRCReadValM = INSTRET_REGW[31:0];
                MHPMCOUNTER3: CSRCReadValM = HPMCOUNTER3_REGW[31:0];
                MHPMCOUNTER4: CSRCReadValM = HPMCOUNTER4_REGW[31:0];
      //          TIME:         CSRCReadValM = TIME_REGW[31:0];
                CYCLE:        CSRCReadValM = CYCLE_REGW[31:0];
                INSTRET:      CSRCReadValM = INSTRET_REGW[31:0];
                HPMCOUNTER3:  CSRCReadValM = HPMCOUNTER3_REGW[31:0];
                HPMCOUNTER4:  CSRCReadValM = HPMCOUNTER4_REGW[31:0];
      //          MTIMEH:        CSRCReadValM = TIME_REGW[63:32];
      //          MTIMECMPH:     CSRCReadValM = TIMECMP_REGW[63:32];
                MCYCLEH:       CSRCReadValM = CYCLE_REGW[63:32];
                MINSTRETH:     CSRCReadValM = INSTRET_REGW[63:32];
                MHPMCOUNTER3H: CSRCReadValM = HPMCOUNTER3_REGW[63:32];
                MHPMCOUNTER4H: CSRCReadValM = HPMCOUNTER4_REGW[63:32];
      //          TIMEH:         CSRCReadValM = TIME_REGW[63:32];
                CYCLEH:        CSRCReadValM = CYCLE_REGW[63:32];
                INSTRETH:      CSRCReadValM = INSTRET_REGW[63:32];
                HPMCOUNTER3H:  CSRCReadValM = HPMCOUNTER3_REGW[63:32];
                HPMCOUNTER4H:  CSRCReadValM = HPMCOUNTER4_REGW[63:32];
                default:   begin
                  CSRCReadValM = 0;
                  IllegalCSRCAccessM = 1;
                end
              endcase
            end else IllegalCSRCAccessM = 1;
    end else begin
      assign CSRCReadValM = 0;
      assign IllegalCSRCAccessM = 1;
    end
  endgenerate
endmodule

