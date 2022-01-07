///////////////////////////////////////////
// interlockfsm.sv
//
// Written: Ross Thompson ross1728@gmail.com December 29, 2021
// Modified: 
//
// Purpose: Allows the HPTW to take control of the dcache to walk page table  and then replay the memory operation if
//          there was on.
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

module interlockfsm
  (input logic clk,
   input logic  reset,
   input logic  AnyCPUReqM,
   input logic  ITLBMissF,
   input logic  ITLBWriteF,
   input logic  DTLBMissM,
   input logic  DTLBWriteM,
   input logic  TrapM,
   input logic  DCacheStall,

   output logic InterlockStall,
   output logic SelReplayCPURequest,
   output logic SelHPTW,
   output logic IgnoreRequest);


  	  typedef enum 				   {STATE_T0_READY,
									STATE_T0_REPLAY,
									STATE_T3_DTLB_MISS,
									STATE_T4_ITLB_MISS,
									STATE_T5_ITLB_MISS,
									STATE_T7_DITLB_MISS} statetype;

	  statetype InterlockCurrState, InterlockNextState;


	  always_ff @(posedge clk)
		if (reset)    InterlockCurrState <= #1 STATE_T0_READY;
		else InterlockCurrState <= #1 InterlockNextState;

	  always_comb begin
		case(InterlockCurrState)
		  STATE_T0_READY:        if(~ITLBMissF & DTLBMissM & AnyCPUReqM)          InterlockNextState = STATE_T3_DTLB_MISS;
	      else if(ITLBMissF & ~DTLBMissM & ~AnyCPUReqM)    InterlockNextState = STATE_T4_ITLB_MISS;
          else if(ITLBMissF & ~DTLBMissM & AnyCPUReqM)     InterlockNextState = STATE_T5_ITLB_MISS;
		  else if(ITLBMissF & DTLBMissM & AnyCPUReqM)      InterlockNextState = STATE_T7_DITLB_MISS;
		  else                                             InterlockNextState = STATE_T0_READY;
		  STATE_T0_REPLAY:       if(DCacheStall)                                  InterlockNextState = STATE_T0_REPLAY;
	      else                                             InterlockNextState = STATE_T0_READY;
		  STATE_T3_DTLB_MISS:    if(DTLBWriteM)                                   InterlockNextState = STATE_T0_REPLAY;
		  else                                             InterlockNextState = STATE_T3_DTLB_MISS;
		  STATE_T4_ITLB_MISS:    if(ITLBWriteF)                                   InterlockNextState = STATE_T0_READY;
	      else                                             InterlockNextState = STATE_T4_ITLB_MISS;
		  STATE_T5_ITLB_MISS:    if(ITLBWriteF)                                   InterlockNextState = STATE_T0_REPLAY;
		  else                                             InterlockNextState = STATE_T5_ITLB_MISS;
		  STATE_T7_DITLB_MISS:   if(DTLBWriteM)                                   InterlockNextState = STATE_T5_ITLB_MISS;
		  else                                             InterlockNextState = STATE_T7_DITLB_MISS;
		  default: InterlockNextState = STATE_T0_READY;
		endcase
	  end // always_comb
	  
	  // signal to CPU it needs to wait on HPTW.
	  /* -----\/----- EXCLUDED -----\/-----
	   // this code has a problem with imperas64mmu as it reads in an invalid uninitalized instruction.  InterlockStall becomes x and it propagates
	   // everywhere.  The case statement below implements the same logic but any x on the inputs will resolve to 0.
	   // Note this will cause a problem for post synthesis gate simulation.
	   assign InterlockStall = (InterlockCurrState == STATE_T0_READY & (DTLBMissM | ITLBMissF)) | 
	   (InterlockCurrState == STATE_T3_DTLB_MISS) | (InterlockCurrState == STATE_T4_ITLB_MISS) |
	   (InterlockCurrState == STATE_T5_ITLB_MISS) | (InterlockCurrState == STATE_T7_DITLB_MISS);

	   -----/\----- EXCLUDED -----/\----- */

	  always_comb begin
		InterlockStall = 1'b0;
		case(InterlockCurrState) 
		  STATE_T0_READY: if(DTLBMissM | ITLBMissF) InterlockStall = 1'b1;
		  STATE_T3_DTLB_MISS: InterlockStall = 1'b1;
		  STATE_T4_ITLB_MISS: InterlockStall = 1'b1;
		  STATE_T5_ITLB_MISS: InterlockStall = 1'b1;
		  STATE_T7_DITLB_MISS: InterlockStall = 1'b1;
		  default: InterlockStall = 1'b0;
		endcase
	  end
  
  
	  assign SelReplayCPURequest = (InterlockNextState == STATE_T0_REPLAY);
	  assign SelHPTW = (InterlockCurrState == STATE_T3_DTLB_MISS) | (InterlockCurrState == STATE_T4_ITLB_MISS) |
					   (InterlockCurrState == STATE_T5_ITLB_MISS) | (InterlockCurrState == STATE_T7_DITLB_MISS);
	  assign IgnoreRequest = (InterlockCurrState == STATE_T0_READY & (ITLBMissF | DTLBMissM | TrapM)) |
							 ((InterlockCurrState == STATE_T0_REPLAY)
							  & (TrapM));

endmodule
