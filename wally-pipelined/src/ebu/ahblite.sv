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
  // Signals from Instruction Cache
  input  logic [`XLEN-1:0] InstrPAdrF, // *** rename these to match block diagram
  input  logic             InstrReadF,
  output logic [`XLEN-1:0] InstrRData,
  // Signals from Data Cache
  input  logic [`XLEN-1:0] MemPAdrM,
  input  logic             MemReadM, MemWriteM,
  input  logic [`XLEN-1:0] WriteDataM,
  input  logic [1:0]       MemSizeM,
  // Signals from MMU ***
  // MMUPAdr;
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
  output logic             InstrStall,/*InstrUpdate, */DataStall
  // *** add a chip-level ready signal as part of handshake
);

  logic GrantData;
  logic [2:0] ISize;
  logic [`AHBW-1:0] HRDATAMasked, ReadDataM, ReadDataPreW;
  logic IReady, DReady;
  logic CaptureDataM;

  assign HCLK = clk;
  assign HRESETn = ~reset;

  // *** initially support AHBW = XLEN

  // track bus state
  // Data accesses have priority over instructions.  However, if a data access comes
  // while an instruction read is occuring, the instruction read finishes before
  // the data access can take place.
  typedef enum {IDLE, MEMREAD, MEMWRITE, INSTRREAD, INSTRREADMEMPENDING} statetype;
  statetype BusState, NextBusState;

  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) BusState <= #1 IDLE;
    else          BusState <= #1 NextBusState;

  always_comb 
    case (BusState)
      IDLE: if      (MemReadM)   NextBusState = MEMREAD;  // Memory has priority over instructions
            else if (MemWriteM)  NextBusState = MEMWRITE;
            else if (InstrReadF) NextBusState = INSTRREAD;
            else                 NextBusState = IDLE;
      MEMREAD: if (~HREADY)      NextBusState = MEMREAD;
            else if (InstrReadF) NextBusState = INSTRREAD;
            else                 NextBusState = IDLE;
      MEMWRITE: if (~HREADY)     NextBusState = MEMWRITE;
            else if (InstrReadF) NextBusState = INSTRREAD;
            else                 NextBusState = IDLE;
      INSTRREAD: //if (~HREADY & (MemReadM | MemWriteM))  NextBusState = INSTRREADMEMPENDING; // *** shouldn't happen, delete
            if (~HREADY)    NextBusState = INSTRREAD;
            else                 NextBusState = IDLE;
      INSTRREADMEMPENDING: if (~HREADY) NextBusState = INSTRREADMEMPENDING; // *** shouldn't happen, delete
            else if (MemReadM)   NextBusState = MEMREAD;
            else                 NextBusState = MEMWRITE; // must be write if not a read.  Don't return to idle.
    endcase

  // stall signals
  assign #2 DataStall = (NextBusState == MEMREAD) || (NextBusState == MEMWRITE) || (NextBusState == INSTRREADMEMPENDING);
  assign #1 InstrStall = (NextBusState == INSTRREAD);
 
  // DH 2/20/22: A cyclic path presently exists
  // HREADY->NextBusState->GrantData->HSIZE->HSELUART->HREADY
  // This is because the peripherals assert HREADY on the same cycle
  // When memory is working, also fix the peripherals to respond on the subsequent cycle
  // and this path should be fixed.
      
  //  bus outputs
  assign #1 GrantData = (NextBusState == MEMREAD) || (NextBusState == MEMWRITE); 
  assign #1 HADDR = (GrantData) ? MemPAdrM[31:0] : InstrPAdrF[31:0];
  assign ISize = 3'b010; // 32 bit instructions for now; later improve for filling cache with full width; ignored on reads anyway
  assign #1 HSIZE = GrantData ? {1'b0, MemSizeM} : ISize;
  assign HBURST = 3'b000; // Single burst only supported; consider generalizing for cache fillsfH
  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HTRANS = (NextBusState != IDLE) ? 2'b10 : 2'b00; // NONSEQ if reading or writing, IDLE otherwise
  assign HMASTLOCK = 0; // no locking supported
  assign HWRITE = (NextBusState == MEMWRITE);
  // delay write data by one cycle for 
  flop #(`XLEN) wdreg(HCLK, WriteDataM, HWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN
  // delay signals for subword writes
  flop #(3)   adrreg(HCLK, HADDR[2:0], HADDRD);
  flop #(4)   sizereg(HCLK, {UnsignedLoadM, HSIZE}, HSIZED);
  flop #(1)   writereg(HCLK, HWRITE, HWRITED);

    // Route signals to Instruction and Data Caches
  // *** assumes AHBW = XLEN

  assign InstrRData = HRDATA;
  assign ReadDataM = HRDATAMasked; // changed from W to M dh 2/7/2021
  assign CaptureDataM = (BusState == MEMREAD) && (NextBusState != MEMREAD);
  flopenr #(`XLEN) ReadDataPreWReg(clk, reset, CaptureDataM, ReadDataM, ReadDataPreW); // *** this may break when there is no instruction read after data read
  flopenr #(`XLEN) ReadDataWReg(clk, reset, ~StallW, ReadDataPreW, ReadDataW);

  subwordread swr(.*);

endmodule

