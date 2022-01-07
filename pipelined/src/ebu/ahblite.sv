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
  typedef enum logic [3:0] {IDLE, MEMREAD, MEMWRITE, INSTRREAD} statetype;
endpackage

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
  // Signals from Data Cache
  input logic [`PA_BITS-1:0] LSUBusAdr,
  input logic 				 LSUBusRead, 
  input logic 				 LSUBusWrite,
  input logic [`XLEN-1:0] 	 LSUBusHWDATA,
  output logic [`XLEN-1:0] 	 LSUBusHRDATA,
  input logic [2:0] 		 LSUBusSize,
  output logic 				 LSUBusAck,
  // AHB-Lite external signals
  (* mark_debug = "true" *) input logic [`AHBW-1:0] HRDATA,
  (* mark_debug = "true" *) input logic HREADY, HRESP,
  (* mark_debug = "true" *) output logic HCLK, HRESETn,
  (* mark_debug = "true" *) output logic [31:0] HADDR, 
  (* mark_debug = "true" *) output logic [`AHBW-1:0] HWDATA,
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
  import ahbliteState::*;
  statetype BusState, NextBusState;

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
      IDLE: if (LSUBusRead)      NextBusState = MEMREAD;  // Memory has priority over instructions
            else if (LSUBusWrite)NextBusState = MEMWRITE;
            else if (IFUBusRead)   NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;
      MEMREAD: if (~HREADY)        NextBusState = MEMREAD;
            else if (IFUBusRead)   NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;
      MEMWRITE: if (~HREADY)       NextBusState = MEMWRITE;
            else if (IFUBusRead)   NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;
      INSTRREAD: if (~HREADY)      NextBusState = INSTRREAD;
            else                   NextBusState = IDLE;  // if (IFUBusRead still high)
      default:                     NextBusState = IDLE;
    endcase


  //  bus outputs
  assign #1 GrantData = (NextBusState == MEMREAD) | (NextBusState == MEMWRITE);
  assign #1 AccessAddress = (GrantData) ? LSUBusAdr[31:0] : IFUBusAdr[31:0];
  assign #1 HADDR = AccessAddress;
  assign ISize = 3'b010; // 32 bit instructions for now; later improve for filling cache with full width; ignored on reads anyway
  assign HSIZE = (GrantData) ? {1'b0, LSUBusSize[1:0]} : ISize;
  assign HBURST = 3'b000; // Single burst only supported; consider generalizing for cache fillsfH
  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HTRANS = (NextBusState != IDLE) ? 2'b10 : 2'b00; // NONSEQ if reading or writing, IDLE otherwise
  assign HMASTLOCK = 0; // no locking supported
  assign HWRITE = NextBusState == MEMWRITE;
  // delay write data by one cycle for
  flop #(`XLEN) wdreg(HCLK, LSUBusHWDATA, HWDATA); // delay HWDATA by 1 cycle per spec; *** assumes AHBW = XLEN
  // delay signals for subword writes
  flop #(3)   adrreg(HCLK, HADDR[2:0], HADDRD);
  flop #(4)   sizereg(HCLK, {UnsignedLoadM, HSIZE}, HSIZED);
  flop #(1)   writereg(HCLK, HWRITE, HWRITED);

    // Route signals to Instruction and Data Caches
  // *** assumes AHBW = XLEN

 
  assign IFUBusHRDATA = HRDATA;
  assign LSUBusHRDATA = HRDATA;
  assign IFUBusAck = (BusState == INSTRREAD) & (NextBusState != INSTRREAD);
  assign LSUBusAck = (BusState == MEMREAD) & (NextBusState != MEMREAD) | (BusState == MEMWRITE) & (NextBusState != MEMWRITE);

endmodule
