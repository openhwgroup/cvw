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
   input logic 		    HPTWRead,
   input logic [`XLEN-1:0]  HPTWPAdr,
   // to page table walker.
   output logic [`XLEN-1:0] HPTWReadPTE,
   output logic 	    HPTWStall, 

   // from CPU
   input logic [1:0] 	    MemRWM,
   input logic [2:0] 	    Funct3M,
   input logic [1:0] 	    AtomicM,
   input logic [`XLEN-1:0]  MemAdrM,
   input logic 		    StallW,
   // to CPU
   output logic [`XLEN-1:0] ReadDataW,
   output logic 	    SquashSCW,
   output logic 	    DataMisalignedM,
   output logic 	    LSUStall, 
  
   // to LSU   
   output logic 	    DisableTranslation, 
   output logic [1:0] 	    MemRWMtoDCache,
   output logic [2:0] 	    Funct3MtoDCache,
   output logic [1:0] 	    AtomicMtoDCache,
   output logic [`XLEN-1:0] MemAdrMtoDCache,
   output logic 	    StallWtoDCache,
   // from LSU
   input logic 		    SquashSCWfromDCache,
   input logic 		    DataMisalignedMfromDCache,
   input logic [`XLEN-1:0]  ReadDataWfromDCache,
   input logic 		    DCacheStall
  
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

  typedef enum{StateReady,
	       StatePTWPending,
	       StatePTWActive} statetype;
  

  statetype CurrState, NextState;
  logic 		    SelPTW;
  logic 		    HPTWStallD;
  logic [2:0] PTWSize;
  

  flopenl #(.TYPE(statetype)) StateReg(.clk(clk),
				       .load(reset),
				       .en(1'b1),
				       .d(NextState),
				       .val(StateReady),
				       .q(CurrState));

  always_comb begin
    case(CurrState)
      StateReady: 
        if (HPTWTranslate) NextState = StatePTWActive;
	else NextState = StateReady;
      StatePTWActive:
	if (HPTWTranslate) NextState = StatePTWActive;
	else NextState = StateReady;
      default: NextState = StateReady;
    endcase
  end

/* -----\/----- EXCLUDED -----\/-----

  always_comb begin
    case(CurrState)
      StateReady: 
	/-* -----\/----- EXCLUDED -----\/-----
	 if      (HPTWTranslate & DataStall)  NextState = StatePTWPending;
	 else
	 -----/\----- EXCLUDED -----/\----- *-/
        if (HPTWTranslate) NextState = StatePTWActive;
	else                                 NextState = StateReady;
      StatePTWPending:
	if (HPTWTranslate & ~DataStall)     NextState = StatePTWActive;
	else if (HPTWTranslate & DataStall) NextState = StatePTWPending;
	else                                NextState = StateReady;
      StatePTWActive:
	if (HPTWTranslate)     NextState = StatePTWActive;
	else                                NextState = StateReady;
      default:                               NextState = StateReady;
    endcase
  end

 -----/\----- EXCLUDED -----/\----- */

  // multiplex the outputs to LSU
  assign DisableTranslation = SelPTW;  // change names between SelPTW would be confusing in DTLB.
  assign SelPTW = (CurrState == StatePTWActive && HPTWTranslate) || (CurrState == StateReady && HPTWTranslate);
  assign MemRWMtoDCache = SelPTW ? {HPTWRead, 1'b0} : MemRWM;
  
  generate
    assign PTWSize = (`XLEN==32 ? 3'b010 : 3'b011); // 32 or 64-bit access from htpw
  endgenerate
  mux2 #(3) sizemux(Funct3M, PTWSize, SelPTW, Funct3MtoDCache);

  assign AtomicMtoDCache = SelPTW ? 2'b00 : AtomicM;
  assign MemAdrMtoDCache = SelPTW ? HPTWPAdr : MemAdrM;
  assign StallWtoDCache = SelPTW ? 1'b0 : StallW;

  // demux the inputs from LSU to walker or cpu's data port.

  assign ReadDataW = SelPTW ? `XLEN'b0 : ReadDataWfromDCache;  // probably can avoid this demux
  assign HPTWReadPTE = SelPTW ? ReadDataWfromDCache : `XLEN'b0 ;  // probably can avoid this demux
  assign SquashSCW = SelPTW ? 1'b0 : SquashSCWfromDCache;
  assign DataMisalignedM = SelPTW ? 1'b0 : DataMisalignedMfromDCache;
  // *** need to rename DcacheStall and Datastall.
  // not clear at all.  I think it should be LSUStall from the LSU,
  // which is demuxed to HPTWStall and CPUDataStall? (not sure on this last one).
  assign HPTWStall = SelPTW ? DCacheStall : 1'b1;  
  //assign HPTWStallD = SelPTW ? DataStall : 1'b1;
/* -----\/----- EXCLUDED -----\/-----
  assign HPTWStallD = SelPTW ? DataStall : 1'b1;
  flopr #(1) HPTWStallReg (.clk(clk),
			   .reset(reset),
			   .d(HPTWStallD),
			   .q(HPTWStall));
 -----/\----- EXCLUDED -----/\----- */
  
  assign LSUStall = SelPTW ? 1'b1 : DCacheStall; // *** this is probably going to change.
  
endmodule
