///////////////////////////////////////////
// wally-pipelinedsoc.sv
//
// Written: David_Harris@hmc.edu 6 November 2020
// Modified: 
//
// Purpose: System on chip including pipelined processor and uncore memories/peripherals
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
////////////////////////////////////////////////////////////////////////////////////////////////

module wallypipelinedsoc import cvw::*; #(parameter cvw_t P)  (
  input  logic                 clk, 
  input  logic                 reset_ext,         // external asynchronous reset pin
  output logic                 reset,             // reset synchronized to clk to prevent races on release
  // JTAG signals                                                                                                                    
  input  logic                 tck,
  input  logic                 tdi,
  input  logic                 tms,
  output logic                 tdo,
  // AHB Interface
  input  logic [P.AHBW-1:0]    HRDATAEXT,
  input  logic                 HREADYEXT, HRESPEXT,
  output logic                 HSELEXT,
  output logic                 HSELEXTSDC, 
  // outputs to external memory, shared with uncore memory
  output logic                 HCLK, HRESETn,
  output logic [P.PA_BITS-1:0] HADDR,
  output logic [P.AHBW-1:0]    HWDATA,
  output logic [P.XLEN/8-1:0]  HWSTRB,
  output logic                 HWRITE,
  output logic [2:0]           HSIZE,
  output logic [2:0]           HBURST,
  output logic [3:0]           HPROT,
  output logic [1:0]           HTRANS,
  output logic                 HMASTLOCK,
  output logic                 HREADY,
  // I/O Interface
  input  logic                 TIMECLK,           // optional for CLINT MTIME counter
  input  logic [31:0]          GPIOIN,            // inputs from GPIO
  output logic [31:0]          GPIOOUT,           // output values for GPIO
  output logic [31:0]          GPIOEN,            // output enables for GPIO
  input  logic                 UARTSin,           // UART serial data input
  output logic                 UARTSout,          // UART serial data output
  input  logic                 SDCIntr,
  input  logic                 SPIIn,             // SPI pins in
  output logic                 SPIOut,            // SPI pins out
  output logic [3:0]           SPICS              // SPI chip select pins                    
);

  // Uncore signals
  logic [P.AHBW-1:0]           HRDATA;            // from AHB mux in uncore
  logic                        HRESP;             // response from AHB
  logic                        MTimerInt, MSwInt; // timer and software interrupts from CLINT
  logic [63:0]                 MTIME_CLINT;       // from CLINT to CSRs
  logic                        MExtInt,SExtInt;   // from PLIC

  // Debug Mode control signals
  logic                        NdmReset;
  logic                        HaltReq;
  logic                        ResumeReq;
  logic                        HaltOnReset;
  logic                        AckHaveReset;
  logic                        ResumeAck;
  logic                        HaveReset;
  logic                        DebugStall;
  logic                        ExecProgBuf;

  // Debug Module signals
  logic                        DebugScanEn;
  logic                        DebugScanIn;
  logic                        GPRScanIn;
  logic                        FPRScanIn;
  logic                        CSRScanIn;
  logic                        DebugScanOut;
  logic                        MiscSel;
  logic                        GPRSel;
  logic                        FPRSel;
  logic                        CSRSel;
  logic [11:0]                 DebugRegAddr;
  logic                        DebugCapture;
  logic                        DebugRegUpdate;
  logic [P.XLEN-1:0]           ProgBufAddr;
  logic                        ProgBuffScanEn;
  logic                        DebugStopTime_REGW;

  // synchronize reset to SOC clock domain
  synchronizer resetsync(.clk, .d(reset_ext), .q(reset));
   
  // instantiate processor and internal memories
  wallypipelinedcore #(P) core (
    .clk, .reset(reset || NdmReset), .MTimerInt, .MExtInt, .SExtInt, .MSwInt, .MTIME_CLINT,
    .HRDATA, .HREADY, .HRESP, .HCLK, .HRESETn, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST,
    .HPROT, .HTRANS, .HMASTLOCK, .HaltReq, .ResumeReq, .HaltOnReset, .AckHaveReset, .ResumeAck,
    .HaveReset, .DebugStall, .ExecProgBuf, .DebugScanEn, .DebugScanOut(DebugScanIn),
    .GPRScanOut(GPRScanIn), .FPRScanOut(FPRScanIn), .CSRScanOut(CSRScanIn),
    .DebugScanIn(DebugScanOut), .MiscSel, .GPRSel, .FPRSel, .CSRSel, .DebugRegAddr, .DebugCapture,
    .DebugRegUpdate, .ProgBufAddr, .ProgBuffScanEn, .DebugStopTime_REGW
  );

  // instantiate uncore if a bus interface exists
  if (P.BUS_SUPPORTED) begin : uncoregen // Hack to work around Verilator bug https://github.com/verilator/verilator/issues/4769
    uncore #(P) uncore (
      .HCLK, .HRESETn, .TIMECLK, .HADDR, .HWDATA, .HWSTRB, .HWRITE, .HSIZE, .HBURST, .HPROT,
      .HTRANS, .HMASTLOCK, .HRDATAEXT, .HREADYEXT, .HRESPEXT, .HRDATA, .HREADY, .HRESP, .HSELEXT,
      .HSELEXTSDC, .MTimerInt, .MSwInt, .MExtInt, .SExtInt, .GPIOIN, .GPIOOUT, .GPIOEN, .UARTSin,
      .UARTSout, .MTIME_CLINT, .SDCIntr, .SPIIn, .DebugStopTime_REGW, .SPIOut, .SPICS
    );
  end else begin
    assign {HRDATA, HREADY, HRESP, HSELEXT, HSELEXTSDC, MTimerInt, MSwInt, MExtInt, SExtInt,
            MTIME_CLINT, GPIOOUT, GPIOEN, UARTSout, SPIOut, SPICS} = '0; 
  end

  // instantiate debug module
  if (P.DEBUG_SUPPORTED) begin : dm
    dm #(P) dm (
      .clk, .rst(reset), .tck, .tdi, .tms, .tdo, .NdmReset, .HaltReq, .ResumeReq, .HaltOnReset,
      .AckHaveReset, .ResumeAck, .HaveReset, .DebugStall, .DebugScanEn, .DebugScanIn, .GPRScanIn,
      .FPRScanIn, .CSRScanIn, .DebugScanOut, .MiscSel, .GPRSel, .FPRSel, .CSRSel,
      .RegAddr(DebugRegAddr), .DebugCapture, .DebugRegUpdate, .ProgBufAddr, .ProgBuffScanEn,
      .ExecProgBuf
    );
  end else begin
    assign {tdo, HaltReq, ResumeReq, HaltOnReset, AckHaveReset, DebugScanEn, DebugScanOut, MiscSel,
            NdmReset, GPRSel, FPRSel, CSRSel, DebugRegAddr, DebugCapture, DebugRegUpdate,
            ProgBufAddr, ProgBuffScanEn, ExecProgBuf} = '0;
  end

endmodule
