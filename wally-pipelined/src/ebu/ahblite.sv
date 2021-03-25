///////////////////////////////////////////
// ahblite.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: AHB Lite External Bus Unit
//          See ARM_HIH0033A_AMBA_AHB-Lite_SPEC 1.0
//          Arbitrates requests from instruction and data streams
//          Connects hart to peripherals and I/O pins on SOC
//          Bus width presently matches XLEN
//          Anticipate replacing this with an AXI bus interface to communicate with FPGA DRAM/Flash controllers
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

module ahblite (
  input  logic             clk, reset,
  input  logic             StallW, FlushW,
  // Load control
  input  logic             UnsignedLoadM,
  input  logic [1:0]       AtomicM,
  input  logic [6:0]       Funct7M,
  // Signals from Instruction Cache
  input  logic [`XLEN-1:0] InstrPAdrF, // *** rename these to match block diagram
  input  logic             InstrReadF,
  output logic [`XLEN-1:0] InstrRData,
  output logic             InstrAckF,
  // Signals from Data Cache
  input  logic [`XLEN-1:0] MemPAdrM,
  input  logic             MemReadM, MemWriteM,
  input  logic [`XLEN-1:0] WriteDataM,
  input  logic [1:0]       MemSizeM,
  // Signals from MMU
  input  logic [`XLEN-1:0] MMUPAdr,
  input  logic             MMUTranslate, MMUTranslationComplete,
  output logic [`XLEN-1:0] MMUReadPTE,
  output logic             MMUReady,
  // Return from bus
  output logic [`XLEN-1:0] ReadDataW,
  // AHB-Lite external signals
  input  logic [`AHBW-1:0] HRDATA,
  input  logic             HREADY, HRESP,
  output logic             HCLK, HRESETn,
  output logic [31:0]      HADDR, 
  output logic [`AHBW-1:0] HWDATA,
  output logic             HWRITE, 
  output logic [2:0]       HSIZE,
  output logic [2:0]       HBURST,
  output logic [3:0]       HPROT,
  output logic [1:0]       HTRANS,
  output logic             HMASTLOCK,
  // Delayed signals for writes
  output logic [2:0]       HADDRD,
  output logic [3:0]       HSIZED,
  output logic             HWRITED,
  // Stalls
  output logic             /*InstrUpdate, */DataStall
  // *** add a chip-level ready signal as part of handshake
);

  logic GrantData;
  logic [31:0] AccessAddress;
  logic [2:0] AccessSize, PTESize, ISize;
  logic [`AHBW-1:0] HRDATAMasked, ReadDataM, ReadDataNewW, ReadDataOldW, WriteData;
  logic IReady, DReady;
  logic CaptureDataM;

  assign HCLK = clk;
  assign HRESETn = ~reset;

  // *** initially support AHBW = XLEN

  // track bus state
  // Data accesses have priority over instructions.  However, if a data access comes
  // while an instruction read is occuring, the instruction read finishes before
  // the data access can take place.
  typedef enum {IDLE, MEMREAD, MEMWRITE, INSTRREAD, INSTRREADC, ATOMICREAD, ATOMICWRITE, MMUTRANSLATE, MMUIDLE} statetype;
  statetype BusState, NextBusState;

  flopenl #(.TYPE(statetype)) busreg(HCLK, ~HRESETn, 1'b1, NextBusState, IDLE, BusState);

  always_comb 
    case (BusState) 
      IDLE: if      (MMUTranslate) NextBusState = MMUTRANSLATE;
            else if (AtomicM[1])   NextBusState = ATOMICREAD;
            else if (MemReadM)     NextBusState = MEMREAD;  // Memory has priority over instructions
            else if (MemWriteM)    NextBusState = MEMWRITE;
            else if (InstrReadF)   NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;
      MMUTRANSLATE: if (~HREADY)   NextBusState = MMUTRANSLATE;
            else                   NextBusState = MMUIDLE;
      // *** Could the MMUIDLE state just be the normal idle state?
      // Do we trust MMUTranslate to be high exactly when we need translation?
      MMUIDLE: if (~MMUTranslationComplete)
                                   NextBusState = MMUTRANSLATE;
            else if (AtomicM[1])   NextBusState = ATOMICREAD;
            else if (MemReadM)     NextBusState = MEMREAD;  // Memory has priority over instructions
            else if (MemWriteM)    NextBusState = MEMWRITE;
            else if (InstrReadF)   NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;
      ATOMICREAD: if (~HREADY)     NextBusState = ATOMICREAD;
            else                   NextBusState = ATOMICWRITE;
      ATOMICWRITE: if (~HREADY)    NextBusState = ATOMICWRITE;
            else if (InstrReadF)   NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;
      MEMREAD: if (~HREADY)        NextBusState = MEMREAD;
            else if (InstrReadF)   NextBusState = INSTRREADC;
            else                   NextBusState = IDLE;
      MEMWRITE: if (~HREADY)       NextBusState = MEMWRITE;
            else if (InstrReadF)   NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;
      INSTRREAD:
            if (~HREADY)           NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;  // if (InstrReadF still high)
      INSTRREADC: if (~HREADY)     NextBusState = INSTRREADC; // "C" for "competing", meaning please don't mess up the memread in the W stage.
            else                   NextBusState = IDLE;
    endcase

  // stall signals
  assign #2 DataStall = (NextBusState == MEMREAD) || (NextBusState == MEMWRITE) || 
                        (NextBusState == ATOMICREAD) || (NextBusState == ATOMICWRITE);
  // *** Could get finer grained stalling if we distinguish between MMU
  //     instruction address translation and data address translation
  assign #1 InstrStall = (NextBusState == INSTRREAD) || (NextBusState == INSTRREADC) ||
                         (NextBusState == MMUTRANSLATE) || (NextBusState == MMUIDLE);

  //  bus outputs
  assign #1 GrantData = (NextBusState == MEMREAD) || (NextBusState == MEMWRITE) || 
                        (NextBusState == ATOMICREAD) || (NextBusState == ATOMICWRITE);
  assign #1 AccessAddress = (GrantData) ? MemPAdrM[31:0] : InstrPAdrF[31:0];
  assign #1 HADDR = (MMUTranslate) ? MMUPAdr[31:0] : AccessAddress;
  generate
    if (`XLEN == 32) assign PTESize = 3'b010;  // in rv32, PTEs are 4 bytes
    else             assign PTESize = 3'b011;  // in rv64, PTEs are 8 bytes
  endgenerate
  assign ISize = 3'b010; // 32 bit instructions for now; later improve for filling cache with full width; ignored on reads anyway
  assign #1 AccessSize = (GrantData) ? {1'b0, MemSizeM} : ISize;
  assign #1 HSIZE = (MMUTranslate) ? PTESize : AccessSize;
  assign HBURST = 3'b000; // Single burst only supported; consider generalizing for cache fillsfH
  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HTRANS = (NextBusState != IDLE) ? 2'b10 : 2'b00; // NONSEQ if reading or writing, IDLE otherwise
  assign HMASTLOCK = 0; // no locking supported
  assign HWRITE = (NextBusState == MEMWRITE) || (NextBusState == ATOMICWRITE);
  // delay write data by one cycle for 
  flop #(`XLEN) wdreg(HCLK, WriteData, HWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN
  // delay signals for subword writes
  flop #(3)   adrreg(HCLK, HADDR[2:0], HADDRD);
  flop #(4)   sizereg(HCLK, {UnsignedLoadM, HSIZE}, HSIZED);
  flop #(1)   writereg(HCLK, HWRITE, HWRITED);

    // Route signals to Instruction and Data Caches
  // *** assumes AHBW = XLEN

  assign #1 MMUReady = (NextBusState == MMUIDLE);

  assign InstrRData = HRDATA;
  assign InstrAckF = (BusState == INSTRREAD) && (NextBusState != INSTRREAD) || (BusState == INSTRREADC) && (NextBusState != INSTRREADC);
  assign MMUReadPTE = HRDATA;
  assign ReadDataM = HRDATAMasked; // changed from W to M dh 2/7/2021
  assign CaptureDataM = ((BusState == MEMREAD) && (NextBusState != MEMREAD)) ||
                        ((BusState == ATOMICREAD) && (NextBusState == ATOMICWRITE));
  // We think this introduces an unnecessary cycle of latency in memory accesses
  // *** can the following be simplified down to one register?
  // *** examine more closely over summer?
  flopenr #(`XLEN) ReadDataNewWReg(clk, reset, CaptureDataM,    ReadDataM, ReadDataNewW);
  flopenr #(`XLEN) ReadDataOldWReg(clk, reset, CaptureDataM, ReadDataNewW, ReadDataOldW); 
  assign ReadDataW = (BusState == INSTRREADC) ? ReadDataOldW : ReadDataNewW;

  // Extract and sign-extend subwords if necessary
  subwordread swr(.*);

  // Handle AMO instructions if applicable
  generate 
    if (`A_SUPPORTED) begin
      logic [`XLEN-1:0] AMOResult;
//      amoalu amoalu(.a(HRDATA), .b(WriteDataM), .funct(Funct7M), .width(MemSizeM), 
//                    .result(AMOResult));
      amoalu amoalu(.srca(ReadDataW), .srcb(WriteDataM), .funct(Funct7M), .width(MemSizeM), 
                    .result(AMOResult));
      mux2 #(`XLEN) wdmux(WriteDataM, AMOResult, AtomicM[1], WriteData);
    end else
      assign WriteData = WriteDataM;
  endgenerate

endmodule
