///////////////////////////////////////////
// ahblite.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: AHB Lite External Bus Unit
//          See ARM_HIH0033A_AMBA_AHB-Lite_SPEC 1.0
//          Arbitrates requests from instruction and data streams
//          Connects core to peripherals and I/O pins on SOC
//          Bus width presently matches XLEN
//          Anticipate replacing this with an AXI bus interface to communicate with FPGA DRAM/Flash controllers
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module ahblite (
  input logic 				 clk, reset,
  // Load control
  input logic 				 UnsignedLoadM,
  input logic [1:0] 		 AtomicMaskedM,
  // Signals from Instruction Cache
  input logic [`PA_BITS-1:0] IFUBusAdr, 
  input logic 				 IFUBusRead,
  output logic [`XLEN-1:0] 	 IFUBusHRDATA,
  output logic 				 IFUBusAck,
  output logic         IFUBusInit,
  input logic [2:0]    IFUBurstType,
  input logic [1:0]    IFUTransType,
  input logic          IFUTransComplete,

  // Signals from Data Cache
  input logic [`PA_BITS-1:0] LSUBusAdr,
  input logic 				 LSUBusRead, 
  input logic 				 LSUBusWrite,
  input logic [`XLEN-1:0] 	 LSUBusHWDATA,
  output logic [`XLEN-1:0] 	 LSUBusHRDATA,
  input logic [2:0] 		 LSUBusSize,
  input logic [2:0]      LSUBurstType,
  input logic [1:0]    LSUTransType,
  input logic          LSUTransComplete,
  output logic 				 LSUBusAck,
  output logic         LSUBusInit,
  // AHB-Lite external signals
  (* mark_debug = "true" *) input logic [`AHBW-1:0] HRDATA,
  (* mark_debug = "true" *) input logic HREADY, HRESP,
  (* mark_debug = "true" *) output logic HCLK, HRESETn,
  (* mark_debug = "true" *) output logic [31:0] HADDR, // *** one day switch to a different bus that supports the full physical address
  (* mark_debug = "true" *) output logic [`AHBW-1:0] HWDATA,
   output logic [`XLEN/8-1:0] HWSTRB,
  (* mark_debug = "true" *) output logic HWRITE, 
  (* mark_debug = "true" *) output logic [2:0] HSIZE,
  (* mark_debug = "true" *) output logic [2:0] HBURST,
  (* mark_debug = "true" *) output logic [3:0] HPROT,
  (* mark_debug = "true" *) output logic [1:0] HTRANS,
  (* mark_debug = "true" *) output logic HMASTLOCK,
  // Delayed signals for writes
  (* mark_debug = "true" *) output logic [2:0] HADDRD,
  (* mark_debug = "true" *) output logic [3:0] HSIZED,
  (* mark_debug = "true" *) output logic HWRITED
);

  typedef enum logic [1:0] {IDLE, MEMREAD, MEMWRITE, INSTRREAD} statetype;
  statetype BusState, NextBusState;

  logic GrantData;
  logic [31:0] AccessAddress;
  logic [2:0] ISize;

  assign HCLK = clk;
  assign HRESETn = ~reset;

  // initially support AHBW = XLEN

  // track bus state
  // Data accesses have priority over instructions.  However, if a data access comes
  // while an instruction read is occuring, the instruction read finishes before
  // the data access can take place.
  //  *** This is no longer true when adding burst mode. We need to finish the current
  //  read before doing another read. Need to work this out, but preliminarily we can
  //  store the current read type in a flop and use that to figure out what burst type to use.

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
      IDLE: if (LSUBusRead)                               NextBusState = MEMREAD;  // Memory has priority over instructions
            else if (LSUBusWrite)                         NextBusState = MEMWRITE;
            else if (IFUBusRead)                          NextBusState = INSTRREAD;
            else                                          NextBusState = IDLE;
      MEMREAD: if (LSUTransComplete & IFUBusRead)         NextBusState = INSTRREAD;
               else if (LSUTransComplete)                 NextBusState = IDLE;
               else                                       NextBusState = MEMREAD;
      MEMWRITE: if (LSUTransComplete & IFUBusRead)        NextBusState = INSTRREAD;
                else if (LSUTransComplete)                NextBusState = IDLE;
                else                                      NextBusState = MEMWRITE;
      INSTRREAD: if (IFUTransComplete & LSUBusRead)       NextBusState = MEMREAD;
                 else if (IFUTransComplete & LSUBusWrite) NextBusState = MEMWRITE;
                 else if (IFUTransComplete)               NextBusState = IDLE;
                 else                                     NextBusState = INSTRREAD;
      default:                                            NextBusState = IDLE;
    endcase


  //  bus outputs
  assign #1 GrantData = (NextBusState == MEMREAD) | (NextBusState == MEMWRITE);
  assign AccessAddress = (GrantData) ? LSUBusAdr[31:0] : IFUBusAdr[31:0];
  assign HADDR = AccessAddress;
  assign ISize = 3'b010; // 32 bit instructions for now; later improve for filling cache with full width; ignored on reads anyway
  assign HSIZE = (GrantData) ? {1'b0, LSUBusSize[1:0]} : ISize;
  assign HBURST = (GrantData) ? LSUBurstType : IFUBurstType; // If doing memory accesses, use LSUburst, else use Instruction burst.

  /* Cache burst read/writes case statement (hopefully) WRAPS only have access to 4 wraps. X changes position based on HSIZE.
        000: Single (SINGLE)
        001: Increment burst of undefined length (INCR)
        010: 4-beat wrapping burst (WRAP4) [wraps if X in 000X0000] 
        011: 4-beat incrementing burst (INCR4)
        100: 8-beat wrapping burst (WRAP8) [wraps if X in 00X00000 changes]
        101: 8-beat incrementing burst (INCR8)
        110: 16-beat wrapping burst (WRAP16) [wraps if X in 0X000000]
        111: 16-beat incrementing burst (INCR16)
        *** Remove if not necessary
  */ 


  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HTRANS = (GrantData) ? LSUTransType : IFUTransType; // SEQ if not first read or write, NONSEQ if first read or write, IDLE otherwise
  assign HMASTLOCK = 0; // no locking supported
  assign HWRITE = (NextBusState == MEMWRITE);
  // Byte mask for HWSTRB
  swbytemask swbytemask(.Size(HSIZED[1:0]), .Adr(HADDRD[2:0]), .ByteMask(HWSTRB));

  // delay write data by one cycle for
  flopen #(`XLEN) wdreg(HCLK, (LSUBusAck | LSUBusInit), LSUBusHWDATA, HWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN
  // delay signals for subword writes
  flop #(3)   adrreg(HCLK, HADDR[2:0], HADDRD);
  flop #(4)   sizereg(HCLK, {UnsignedLoadM, HSIZE}, HSIZED);
  flop #(1)   writereg(HCLK, HWRITE, HWRITED);

    // Route signals to Instruction and Data Caches
  // *** assumes AHBW = XLEN
  assign IFUBusHRDATA = HRDATA;
  assign LSUBusHRDATA = HRDATA;
  assign IFUBusInit = (BusState != INSTRREAD) & (NextBusState == INSTRREAD);
  assign LSUBusInit = (((BusState != MEMREAD) & (NextBusState == MEMREAD)) | (BusState != MEMWRITE) & (NextBusState == MEMWRITE));
  assign IFUBusAck = HREADY & (BusState == INSTRREAD);
  assign LSUBusAck = HREADY & ((BusState == MEMREAD) | (BusState == MEMWRITE));
endmodule
