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

module interlockfsm(
  input logic       clk,
  input logic       reset,
  input logic [1:0] MemRWM,
  input logic [1:0] AtomicM,
  input logic       ITLBMissOrDAFaultF,
  input logic       ITLBWriteF,
  input logic       DTLBMissOrDAFaultM,
  input logic       DTLBWriteM,
  input logic       TrapM,
  input logic       DCacheStallM,

  output logic      InterlockStall,
  output logic      SelReplayMemE,
  output logic      SelHPTW,
  output logic      IgnoreRequestTLB);

  logic             ToITLBMiss;
  logic             ToITLBMissNoReplay;
  logic             ToDTLBMiss;
  logic             ToBoth;
  logic             AnyCPUReqM;

  typedef enum      logic[2:0]  {STATE_T0_READY,
				                 STATE_T1_REPLAY,
				                 STATE_T3_DTLB_MISS,
				                 STATE_T4_ITLB_MISS,
				                 STATE_T5_ITLB_MISS,
				                 STATE_T7_DITLB_MISS} statetype;

  (* mark_debug = "true" *)	  statetype InterlockCurrState, InterlockNextState;

  assign AnyCPUReqM = (|MemRWM) | (|AtomicM);
  assign ToITLBMiss = ITLBMissOrDAFaultF & ~DTLBMissOrDAFaultM & AnyCPUReqM;
  assign ToITLBMissNoReplay = ITLBMissOrDAFaultF & ~DTLBMissOrDAFaultM & ~AnyCPUReqM;
  assign ToDTLBMiss = ~ITLBMissOrDAFaultF & DTLBMissOrDAFaultM & AnyCPUReqM;
  assign ToBoth = ITLBMissOrDAFaultF & DTLBMissOrDAFaultM & AnyCPUReqM;

  always_ff @(posedge clk)
	if (reset)    InterlockCurrState <= #1 STATE_T0_READY;
	else InterlockCurrState <= #1 InterlockNextState;

  always_comb begin
	case(InterlockCurrState)
	  STATE_T0_READY: if (TrapM)                  InterlockNextState = STATE_T0_READY;
	                  else if(ToDTLBMiss)         InterlockNextState = STATE_T3_DTLB_MISS;
	                  else if(ToITLBMissNoReplay) InterlockNextState = STATE_T4_ITLB_MISS;
                      else if(ToITLBMiss)         InterlockNextState = STATE_T5_ITLB_MISS;
	                  else if(ToBoth)             InterlockNextState = STATE_T7_DITLB_MISS;
	                  else                        InterlockNextState = STATE_T0_READY;
	  STATE_T1_REPLAY:     if(DCacheStallM)       InterlockNextState = STATE_T1_REPLAY;
	                       else                   InterlockNextState = STATE_T0_READY;
	  STATE_T3_DTLB_MISS:  if(DTLBWriteM)         InterlockNextState = STATE_T1_REPLAY;
	                       else                   InterlockNextState = STATE_T3_DTLB_MISS;
	  STATE_T4_ITLB_MISS:  if(ITLBWriteF)         InterlockNextState = STATE_T0_READY;
	                       else                   InterlockNextState = STATE_T4_ITLB_MISS;
	  STATE_T5_ITLB_MISS:  if(ITLBWriteF)         InterlockNextState = STATE_T1_REPLAY;
	                       else                   InterlockNextState = STATE_T5_ITLB_MISS;
	  STATE_T7_DITLB_MISS: if(DTLBWriteM)         InterlockNextState = STATE_T5_ITLB_MISS;
	                       else                   InterlockNextState = STATE_T7_DITLB_MISS;
	  default:                                    InterlockNextState = STATE_T0_READY;
	endcase
  end // always_comb
	  
   assign InterlockStall = (InterlockCurrState == STATE_T0_READY & (DTLBMissOrDAFaultM | ITLBMissOrDAFaultF) & ~TrapM) | 
                           (InterlockCurrState == STATE_T3_DTLB_MISS) | (InterlockCurrState == STATE_T4_ITLB_MISS) |
                           (InterlockCurrState == STATE_T5_ITLB_MISS) | (InterlockCurrState == STATE_T7_DITLB_MISS);
  assign SelReplayMemE = (InterlockCurrState == STATE_T1_REPLAY & DCacheStallM) |
                         (InterlockCurrState == STATE_T3_DTLB_MISS & DTLBWriteM) | 
                         (InterlockCurrState == STATE_T5_ITLB_MISS & ITLBWriteF);
  assign SelHPTW = (InterlockCurrState == STATE_T3_DTLB_MISS) | (InterlockCurrState == STATE_T4_ITLB_MISS) |
				   (InterlockCurrState == STATE_T5_ITLB_MISS) | (InterlockCurrState == STATE_T7_DITLB_MISS);
  assign IgnoreRequestTLB = (InterlockCurrState == STATE_T0_READY & (ITLBMissOrDAFaultF | DTLBMissOrDAFaultM));
endmodule
