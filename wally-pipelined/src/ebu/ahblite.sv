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
  input  logic             ResolveBranchD,
  output logic [31:0] InstrRData,
//  output logic             IReady,
  // Signals from Data Cache
  input  logic [`XLEN-1:0] MemPAdrM,
  input  logic             MemReadM, MemWriteM,
  input  logic [`XLEN-1:0] WriteDataM,
  input  logic [1:0]       MemSizeM,
  // Return from bus
  output logic [`XLEN-1:0] ReadDataW,
//  output logic             DReady,
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
  // Delayed signals for subword write
  output logic [2:0]       HADDRD,
  output logic [3:0]       HSIZED,
  output logic             HWRITED,
  // Acknowledge
  output logic             InstrAckD, MemAckW,
  // Stalls
  output logic             InstrStall, DataStall
);

  logic GrantData;
  logic [2:0] ISize;
  logic [`AHBW-1:0] HRDATAMasked, ReadDataM;
  logic IReady, DReady;
//  logic [3:0] HSIZED; // size delayed by one cycle for reads
//  logic [2:0] HADDRD; // address delayed for subword reads

  assign HCLK = clk;
  assign HRESETn = ~reset;

  // Arbitrate requests by giving data priority over instructions
  assign GrantData = MemReadM | MemWriteM;

  // *** initially support HABW = XLEN

  // track bus state
  typedef enum {IDLE, MEMREAD, MEMWRITE, INSTRREAD} statetype;
  statetype AdrState, DataState, NextAdrState; // what is happening in the first and second phases of the bus
  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) begin
      AdrState <= IDLE; DataState <= IDLE;
      HWDATA <= 0; // unnecessary but avoids x at startup
      HSIZED <= 0;
      HADDRD <= 0;
      HWRITED <= 0;
    end else begin
      if (HREADY || (DataState == IDLE)) begin // only advance bus state if bus is idle or previous transaction returns ready
        DataState <= AdrState;
        AdrState <= NextAdrState;
        if (HWRITE) HWDATA <= WriteDataM;
        HSIZED <= {UnsignedLoadM, HSIZE};
        HADDRD <= HADDR[2:0];
        HWRITED <= HWRITE;
      end
    end
  always_comb
    if (MemReadM) NextAdrState = MEMREAD;
    else if (MemWriteM) NextAdrState = MEMWRITE;
    else if (InstrReadF) NextAdrState = INSTRREAD;
//    else if (1) NextAdrState = INSTRREAD; // dm 2/9/2021 testing
    else NextAdrState = IDLE;
  
  // Generate acknowledges based on bus state and ready
  assign MemAckW = (AdrState == MEMREAD || AdrState == MEMWRITE) && HREADY;
  assign InstrAckD = (AdrState == INSTRREAD) && HREADY;

  // Choose ISize based on XLen
  generate
   //if (`AHBW == 32) assign ISize = 3'b010; // 32-bit transfers
    //else             assign ISize = 3'b011; // 64-bit transfers
    assign ISize = 3'b010; // 32 bit instructions for now; later improve for filling cache with full width
  endgenerate

  // drive bus outputs
  assign HADDR = GrantData ? MemPAdrM[31:0] : InstrPAdrF[31:0];
  //assign HWDATA = WriteDataW;
  //flop #(`XLEN) wdreg(HCLK, DWDataM, HWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN
  assign HWRITE = MemWriteM; 
  assign HSIZE = GrantData ? {1'b0, MemSizeM} : ISize;
  assign HBURST = 3'b000; // Single burst only supported; consider generalizing for cache fillsfHPROT
  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HTRANS = InstrReadF | MemReadM | MemWriteM ? 2'b10 : 2'b00; // NONSEQ if reading or writing, IDLE otherwise
  assign HMASTLOCK = 0; // no locking supported
                  
  // Route signals to Instruction and Data Caches
  // *** assumes AHBW = XLEN
  assign InstrRData = HRDATAMasked[31:0];
  assign IReady = HREADY & InstrReadF & ~GrantData; // maybe unused?***
//  assign ReadDataW = HRDATAMasked;
  assign ReadDataM = HRDATAMasked; // changed from W to M dh 2/7/2021
  flopenrc #(`XLEN) ReadDataWReg(clk, reset, FlushW, ~StallW, ReadDataM, ReadDataW);
  assign DReady = HREADY & GrantData; // ***unused?


  // State machines for stalls (probably can merge with FSM above***)
  // Idle, DataBusy, InstrBusy.  Stall while in busystate add suffixes
  logic MemState, NextMemState, InstrState, NextInstrState;
  flopr #(1) msreg(HCLK, ~HRESETn, NextMemState, MemState);
  flopr #(1) isreg(HCLK, ~HRESETn, NextInstrState, InstrState);
/*  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) MemState <=  0;
    else MemState <= NextMemState; */
  assign NextMemState = (MemState == 0 && InstrState == 0 && (MemReadM || MemWriteM)) || (MemState == 1 && ~MemAckW);
  assign DataStall = NextMemState;
/*  always_ff @(posedge HCLK, negedge HRESETn)
    if (~HRESETn) InstrState <=  0;
    else InstrState <= NextInstrState;*/

  assign NextInstrState = (InstrState == 0 && MemState == 0 && (~MemReadM  && ~MemWriteM && InstrReadF)) || 
                          (InstrState == 1 && ~InstrAckD)  ||
                          (InstrState == 1 && ResolveBranchD); // dh 2/8/2021 fixing; delete this later 
/*  assign NextInstrState = (InstrState == 0 && MemState == 0 && (~MemReadM  && ~MemWriteM)) || 
                          (InstrState == 1 && ~InstrAckD);  // *** removed InstrReadF above dh 2/9/20 */
  assign InstrStall = NextInstrState | MemState | NextMemState; // *** check this, explain better
  // temporarily turn off stalls and check it works
  //assign DataStall = 0;
  //assign InstrStall = 0;

  // stalls
  // Stall MEM stage if data is being accessed and bus isn't yet ready
  //assign DataStall = GrantData & ~HREADY; 
  // Stall Fetch stage if instruction should be read but reading data or bus isn't ready
  //assign InstrStall = IReadF & (GrantData | ~HREADY); 

  // *** consider adding memory access faults based on HRESP being high
  //   InstrAccessFaultF, DataAccessFaultM,

  subwordread swr(.*);

endmodule

