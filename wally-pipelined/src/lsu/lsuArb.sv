///////////////////////////////////////////
// lsuArb.sv
//
// Written: Ross THompson and Kip Macsai-Goren
// Modified: kmacsaigoren@hmc.edu June 23, 2021
//
// Purpose: LSU arbiter between the CPU's demand request for data memory and
//          the page table walker
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

module lsuArb 
  (input  logic clk, reset,

   // from page table walker
   input logic 		    HPTWTranslate,
   input logic [`XLEN-1:0]  HPTWPAdr,
   // to page table walker.
   output logic [`XLEN-1:0] HPTWReadPTE,
   output logic 	    HPTWReady,

   // from CPU
   input logic [1:0] 	    MemRWM,
   input logic [2:0] 	    Funct3M,
   input logic [1:0] 	    AtomicM,
   input logic [`XLEN-1:0]  MemAdrM,
   input logic [`XLEN-1:0]  WriteDataM,
   // to CPU
   output logic [`XLEN-1:0] ReadDataW,
   output logic 	    CommittedM, 
   output logic 	    SquashSCW,
   output logic 	    DataMisalignedM,
   output logic 	    DCacheStall, 
  
   // to LSU   
   output logic 	    DisableTranslation, 
   output logic [1:0] 	    MemRWMtoLSU,
   output logic [2:0] 	    Funct3MtoLSU,
   output logic [1:0] 	    AtomicMtoLSU,
   output logic [`XLEN-1:0] MemAdrMtoLSU,
   output logic [`XLEN-1:0] WriteDataMtoLSU,
   // from LSU
   input logic 		    CommittedMfromLSU,
   input logic 		    SquashSCWfromLSU,
   input logic 		    DataMisalignedMfromLSU,
   input logic [`XLEN-1:0]  ReadDataWFromLSU,
   input logic 		    DataStall
  
   );
  
  // HPTWTranslate is the request for memory by the page table walker.  When 
  // this is high the page table walker gains priority over the CPU's data
  // input.  Note the ptw only makes a request after an instruction or data
  // tlb miss.  It is entirely possible the dcache is currently processing
  // a data cache miss when an instruction tlb miss occurs.  If an instruction
  // in the E stage causes a d cache miss, the d cache will immediately start
  // processing the request.  Simultaneously the ITLB misses.  By the time
  // the TLB miss causes the page table walker to issue the first request
  // to data memory the d cache is already busy.  We can interlock by 
  // leveraging Stall as a d cache busy.  We will need an FSM to handle this.

  localparam StateReady = 0;
  localparam StatePTWPending = 1;
  localparam StatePTWActive = 1;

  logic [1:0] 		    CurrState, NextState;
  logic 		    SelPTW;
  

  flopr #(2) StateReg(
		      .clk(clk),
		      .reset(reset),
		      .d(NextState),
		      .q(CurrState));

  always_comb begin
    case(CurrState)
      StateReady: 
	      if      (HPTWTranslate & DataStall)  NextState = StatePTWPending;
        else if (HPTWTranslate & ~DataStall) NextState = StatePTWActive;
	      else                                 NextState = StateReady;
      StatePTWPending:
	      if (~DataStall)                      NextState = StatePTWActive;
	      else                                 NextState = StatePTWPending;
      StatePTWActive:
	      if (~DataStall)                      NextState = StateReady;
	      else                                 NextState = StatePTWActive;
      default:                               NextState = StateReady;
    endcase
  end


  // multiplex the outputs to LSU
  assign DisableTranslation = SelPTW;  // change names between SelPTW would be confusing in DTLB.
  assign SelPTW = CurrState == StatePTWActive;
  assign MemRWMtoLSU = SelPTW ? 2'b10 : MemRWM;
  
  generate
    if (`XLEN == 32) begin
      assign Funct3MtoLSU = SelPTW ? 3'b010 : Funct3M;
    end else begin
      assign Funct3MtoLSU = SelPTW ? 3'b011 : Funct3M;
    end
  endgenerate

  assign AtomicMtoLSU = SelPTW ? 2'b00 : AtomicM;
  assign MemAdrMtoLSU = SelPTW ? HPTWPAdr : MemAdrM;
  assign WriteDataMtoLSU = SelPTW ? `XLEN'b0 : WriteDataM;

  // demux the inputs from LSU to walker or cpu's data port.

  assign ReadDataW = SelPTW ? `XLEN'b0 : ReadDataWFromLSU;  // probably can avoid this demux
  assign HPTWReadPTE = SelPTW ? ReadDataWFromLSU : `XLEN'b0 ;  // probably can avoid this demux
  assign CommittedM = SelPTW ? 1'b0 : CommittedMfromLSU;
  assign SquashSCW = SelPTW ? 1'b0 : SquashSCWfromLSU;
  assign DataMisalignedM = SelPTW ? 1'b0 : DataMisalignedMfromLSU;
  assign HPTWReady = ~ DataStall;
  assign DCacheStall = DataStall; // *** this is probably going to change.
  
endmodule
