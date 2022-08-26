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
  input logic [`PA_BITS-1:0] IFUHADDR, 
  input logic [2:0]    IFUHBURST,
  input logic [1:0]    IFUHTRANS,
  input logic 				 IFUBusRead,
  input logic          IFUTransComplete,
  output logic         IFUBusInit,
  output logic 				 IFUBusAck,

  // Signals from Data Cache
  input logic [`PA_BITS-1:0] LSUHADDR,
  input logic [`XLEN-1:0] 	 LSUHWDATA,   // initially support AHBW = XLEN
  input logic [2:0] 		 LSUHSIZE,
  input logic [2:0]      LSUHBURST,
  input logic [1:0]    LSUHTRANS,
  input logic 				 LSUBusRead, 
  input logic 				 LSUBusWrite,
  input logic          LSUTransComplete,
  output logic         LSUBusInit,
  output logic 				 LSUBusAck,

  // AHB-Lite external signals
  (* mark_debug = "true" *) input logic HREADY, HRESP,
  (* mark_debug = "true" *) output logic HCLK, HRESETn,
  (* mark_debug = "true" *) output logic [`PA_BITS-1:0] HADDR, // *** one day switch to a different bus that supports the full physical address
  (* mark_debug = "true" *) output logic [`AHBW-1:0] HWDATA,
   output logic [`XLEN/8-1:0] HWSTRB,
  (* mark_debug = "true" *) output logic HWRITE, 
  (* mark_debug = "true" *) output logic [2:0] HSIZE,
  (* mark_debug = "true" *) output logic [2:0] HBURST,
  (* mark_debug = "true" *) output logic [3:0] HPROT,
  (* mark_debug = "true" *) output logic [1:0] HTRANS,
  (* mark_debug = "true" *) output logic HMASTLOCK
);

  localparam ADRBITS = $clog2(`XLEN/8); // address bits for Byte Mask generator

  typedef enum logic [1:0] {IDLE, MEMREAD, MEMWRITE, INSTRREAD} statetype;
  statetype BusState, NextBusState;
  logic LSUGrant;
  logic [ADRBITS-1:0] HADDRD;
  logic [1:0] HSIZED;
 
  assign HCLK = clk;
  assign HRESETn = ~reset;

  // Bus State FSM
  // Data accesses have priority over instructions.  However, if a data access comes
  // while an cache line read is occuring, the line read finishes before
  // the data access can take place.
  
  flopenl #(.TYPE(statetype)) busreg(HCLK, ~HRESETn, 1'b1, NextBusState, IDLE, BusState);
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

  //  LSU/IFU mux: choose source of access
  assign #1 LSUGrant = (NextBusState == MEMREAD) | (NextBusState == MEMWRITE);
  assign HADDR = LSUGrant ? LSUHADDR : IFUHADDR;
  assign HSIZE = LSUGrant ? {1'b0, LSUHSIZE[1:0]} : 3'b010; // Instruction reads are always 32 bits
  assign HBURST = LSUGrant ? LSUHBURST : IFUHBURST; // If doing memory accesses, use LSUburst, else use Instruction burst.
  assign HTRANS = LSUGrant ? LSUHTRANS : IFUHTRANS; // SEQ if not first read or write, NONSEQ if first read or write, IDLE otherwise
  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HMASTLOCK = 0; // no locking supported
  assign HWRITE = (NextBusState == MEMWRITE);

  // delay write data by one cycle for
  flopen #(`XLEN) wdreg(HCLK, (LSUBusAck | LSUBusInit), LSUHWDATA, HWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN

  // Byte mask for HWSTRB based on delayed signals
  flop #(ADRBITS)   adrreg(HCLK, HADDR[ADRBITS-1:0], HADDRD);
  flop #(2)   sizereg(HCLK, HSIZE[1:0], HSIZED);
  swbytemask  swbytemask(.Size({1'b0, HSIZED}), .Adr(HADDRD), .ByteMask(HWSTRB));

  // Send control back to IFU and LSU
  assign IFUBusInit = (BusState != INSTRREAD) & (NextBusState == INSTRREAD);
  assign LSUBusInit = (((BusState != MEMREAD) & (NextBusState == MEMREAD)) | (BusState != MEMWRITE) & (NextBusState == MEMWRITE));
  assign IFUBusAck = HREADY & (BusState == INSTRREAD);
  assign LSUBusAck = HREADY & ((BusState == MEMREAD) | (BusState == MEMWRITE));
endmodule
