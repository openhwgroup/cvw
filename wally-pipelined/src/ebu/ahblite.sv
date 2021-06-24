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

package ahbliteState;
  typedef enum logic [3:0] {IDLE, MEMREAD, MEMWRITE, INSTRREAD, ATOMICREAD, ATOMICWRITE, MMUTRANSLATE} statetype;
endpackage

module ahblite (
  input  logic             clk, reset,
  input  logic             StallW, FlushW,
  // Load control
  input  logic             UnsignedLoadM,
  input  logic [1:0]       AtomicMaskedM,
  input  logic [6:0]       Funct7M,
  // Signals from Instruction Cache
  input  logic [`PA_BITS-1:0] InstrPAdrF, // *** rename these to match block diagram
  input  logic             InstrReadF,
  output logic [`XLEN-1:0] InstrRData,
  output logic             InstrAckF,
  // Signals from Data Cache
  input  logic [`PA_BITS-1:0] MemPAdrM,
  input  logic             MemReadM, MemWriteM,
  input  logic [`XLEN-1:0] WriteDataM,
  input  logic [1:0]       MemSizeM,
  // Signals from MMU
/* -----\/----- EXCLUDED -----\/-----
  input  logic             MMUStall,
  input  logic [`XLEN-1:0] MMUPAdr,
  input  logic             MMUTranslate,
  output logic [`XLEN-1:0] MMUReadPTE,
  output logic             MMUReady,
 -----/\----- EXCLUDED -----/\----- */
  // Signals from PMA checker
  input  logic             DSquashBusAccessM, ISquashBusAccessF,
  // Signals to PMA checker (metadata of proposed access)
  output logic             AtomicAccessM, ExecuteAccessF, WriteAccessM, ReadAccessM,
  // Return from bus
  output logic [`XLEN-1:0] HRDATAW,
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
  output logic CommitM, MemAckW
);

  logic GrantData;
  logic [31:0] AccessAddress;
  logic [2:0] AccessSize, PTESize, ISize;
  logic [`AHBW-1:0] HRDATAMasked, ReadDataM, CapturedHRDATAMasked, HRDATANext, WriteData;
  logic IReady, DReady;
  logic CaptureDataM,CapturedDataAvailable;

  assign HCLK = clk;
  assign HRESETn = ~reset;

  // *** initially support AHBW = XLEN

  // track bus state
  // Data accesses have priority over instructions.  However, if a data access comes
  // while an instruction read is occuring, the instruction read finishes before
  // the data access can take place.
  import ahbliteState::*;
  statetype BusState, ProposedNextBusState, NextBusState;

  flopenl #(.TYPE(statetype)) busreg(HCLK, ~HRESETn, 1'b1, NextBusState, IDLE, BusState);

  // This case statement computes the desired next state for the AHBlite,
  // prioritizing address translations, then atomics, then data accesses, and
  // finally instructions. This proposition controls HADDR so the PMA and PMP
  // checkers can determine whether the access is allowed. If not, the actual
  // NextWalkerState is set to IDLE.

  // *** This ability to squash accesses must be replicated by any bus
  // interface that might be used in place of the ahblite.
  always_comb 
    case (BusState) 
      IDLE: /*if      (MMUTranslate) ProposedNextBusState = MMUTRANSLATE;
            else*/ if (AtomicMaskedM[1])   ProposedNextBusState = ATOMICREAD;
            else if (MemReadM)     ProposedNextBusState = MEMREAD;  // Memory has priority over instructions
            else if (MemWriteM)    ProposedNextBusState = MEMWRITE;
            else if (InstrReadF)   ProposedNextBusState = INSTRREAD;
            else                   ProposedNextBusState = IDLE;
/* -----\/----- EXCLUDED -----\/-----
      MMUTRANSLATE: if (~HREADY)   ProposedNextBusState = MMUTRANSLATE;
            else                   ProposedNextBusState = IDLE;
 -----/\----- EXCLUDED -----/\----- */
      ATOMICREAD: if (~HREADY)     ProposedNextBusState = ATOMICREAD;
            else                   ProposedNextBusState = ATOMICWRITE;
      ATOMICWRITE: if (~HREADY)    ProposedNextBusState = ATOMICWRITE;
            else if (InstrReadF)   ProposedNextBusState = INSTRREAD;
            else                   ProposedNextBusState = IDLE;
      MEMREAD: if (~HREADY)        ProposedNextBusState = MEMREAD;
            else if (InstrReadF)   ProposedNextBusState = INSTRREAD;
            else                   ProposedNextBusState = IDLE;
      MEMWRITE: if (~HREADY)       ProposedNextBusState = MEMWRITE;
            else if (InstrReadF)   ProposedNextBusState = INSTRREAD;
            else                   ProposedNextBusState = IDLE;
      INSTRREAD: if (~HREADY)      ProposedNextBusState = INSTRREAD;
            else                   ProposedNextBusState = IDLE;  // if (InstrReadF still high)
      default:                     ProposedNextBusState = IDLE;
    endcase

  // Determine access type (important for determining whether to fault)
  assign AtomicAccessM = (ProposedNextBusState == ATOMICREAD) || (ProposedNextBusState == ATOMICWRITE);
  assign ExecuteAccessF = (ProposedNextBusState == INSTRREAD);
  assign WriteAccessM = (ProposedNextBusState == MEMWRITE) || (ProposedNextBusState == ATOMICWRITE);
  assign ReadAccessM = (ProposedNextBusState == MEMREAD) || (ProposedNextBusState == ATOMICREAD);// ||
//              (ProposedNextBusState == MMUTRANSLATE);

  // The PMA and PMP checkers can decide to squash the access 
  assign NextBusState = (DSquashBusAccessM || ISquashBusAccessF) ? IDLE : ProposedNextBusState;

  // stall signals
  // Note that we need to extend both stalls when MMUTRANSLATE goes to idle,
  // since translation might not be complete.
  // *** Ross Thompson remove this datastall
/* -----\/----- EXCLUDED -----\/-----
  assign #2 DataStall = ((NextBusState == MEMREAD) || (NextBusState == MEMWRITE) || 
                    (NextBusState == ATOMICREAD) || (NextBusState == ATOMICWRITE) ||
                    MMUStall);
 -----/\----- EXCLUDED -----/\----- */

  //assign #1 InstrStall = ((NextBusState == INSTRREAD) || (NextBusState == INSTRREADC) ||
  //                        MMUStall);

  //  bus outputs
  assign #1 GrantData = (ProposedNextBusState == MEMREAD) || (ProposedNextBusState == MEMWRITE) || 
                        (ProposedNextBusState == ATOMICREAD) || (ProposedNextBusState == ATOMICWRITE);
  assign #1 AccessAddress = (GrantData) ? MemPAdrM[31:0] : InstrPAdrF[31:0];
  //assign #1 HADDR = (MMUTranslate) ? MMUPAdr[31:0] : AccessAddress;
  assign #1 HADDR = AccessAddress;
  generate
    if (`XLEN == 32) assign PTESize = 3'b010;  // in rv32, PTEs are 4 bytes
    else             assign PTESize = 3'b011;  // in rv64, PTEs are 8 bytes
  endgenerate
  assign ISize = 3'b010; // 32 bit instructions for now; later improve for filling cache with full width; ignored on reads anyway
  assign #1 AccessSize = (GrantData) ? {1'b0, MemSizeM} : ISize;
  //assign #1 HSIZE = (MMUTranslate) ? PTESize : AccessSize;
  assign #1 HSIZE = AccessSize;
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

  //assign MMUReady = (BusState == MMUTRANSLATE && HREADY);

  assign InstrRData = HRDATA;
  assign InstrAckF = (BusState == INSTRREAD) && (NextBusState != INSTRREAD);
  assign CommitM = (BusState == MEMREAD) || (BusState == MEMWRITE) || (BusState == ATOMICREAD) || (BusState == ATOMICWRITE);
  // *** Bracker 6/5/21: why is this W stage?
  assign MemAckW = (BusState == MEMREAD) && (NextBusState != MEMREAD) || (BusState == MEMWRITE) && (NextBusState != MEMWRITE) ||
		   ((BusState == ATOMICREAD) && (NextBusState != ATOMICREAD)) || ((BusState == ATOMICWRITE) && (NextBusState != ATOMICWRITE));
  //assign MMUReadPTE = HRDATA;
  // Carefully decide when to update ReadDataW
  //   ReadDataMstored holds the most recent memory read.
  //   We need to wait until the pipeline actually advances before we can update the contents of ReadDataW
  //   (or else the W stage will accidentally get the M stage's data when the pipeline does advance).
  assign CaptureDataM = ((BusState == MEMREAD) && (NextBusState != MEMREAD)) ||
                        ((BusState == ATOMICREAD) && (NextBusState != ATOMICREAD));
  flopenr #(`XLEN) ReadDataNewWReg(clk, reset, CaptureDataM, HRDATAMasked, CapturedHRDATAMasked);

  always @(posedge HCLK, negedge HRESETn)
    if (~HRESETn)
      CapturedDataAvailable <= #1 1'b0;
    else
      CapturedDataAvailable <= #1 (StallW) ? (CaptureDataM | CapturedDataAvailable) : 1'b0;
  always_comb
    casez({StallW && (BusState != ATOMICREAD),CapturedDataAvailable})
      2'b00: HRDATANext = HRDATAMasked;
      2'b01: HRDATANext = CapturedHRDATAMasked;
      2'b1?: HRDATANext = HRDATAW;
    endcase
  flopr #(`XLEN) ReadDataOldWReg(clk, reset, HRDATANext, HRDATAW); 

  // Extract and sign-extend subwords if necessary
  subwordread swr(.*);

  // Handle AMO instructions if applicable
  generate 
    if (`A_SUPPORTED) begin
      logic [`XLEN-1:0] AMOResult;
//      amoalu amoalu(.a(HRDATA), .b(WriteDataM), .funct(Funct7M), .width(MemSizeM), 
//                    .result(AMOResult));
      amoalu amoalu(.srca(HRDATAW), .srcb(WriteDataM), .funct(Funct7M), .width(MemSizeM), 
                    .result(AMOResult));
      mux2 #(`XLEN) wdmux(WriteDataM, AMOResult, AtomicMaskedM[1], WriteData);
    end else
      assign WriteData = WriteDataM;
  endgenerate

endmodule
