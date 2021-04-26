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

module csrc ( 
    input logic 	     clk, reset,
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

    // create Counter arrays to store address of each counter 
    integer MHPMCOUNTER [`COUNTERS:0];
    integer MHPMCOUNTERH [`COUNTERS:0]; 
    integer HPMCOUNTER [`COUNTERS:0];
    integer HPMCOUNTERH [`COUNTERS:0];
    integer MHPEVENT [`COUNTERS:0];

    genvar i;
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

