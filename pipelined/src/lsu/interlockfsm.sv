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

  logic             AnyCPUReqM;
  logic             PendingTLBMiss;
  logic             EitherTLBMiss;
  logic             EitherTLBWrite;

  typedef enum      logic[2:0]  {STATE_T0_READY,
				                 STATE_T3_TLB_MISS} statetype;

  (* mark_debug = "true" *)	  statetype InterlockCurrState, InterlockNextState;

  assign AnyCPUReqM = (|MemRWM) | (|AtomicM);
  assign PendingTLBMiss = (ITLBMissOrDAFaultF & ~ITLBWriteF) | (DTLBMissOrDAFaultM & ~DTLBWriteM);
  assign EitherTLBMiss = ITLBMissOrDAFaultF | DTLBMissOrDAFaultM;
  assign EitherTLBWrite = ITLBWriteF | DTLBWriteM;

  always_ff @(posedge clk)
	if (reset)    InterlockCurrState <= #1 STATE_T0_READY;
	else InterlockCurrState <= #1 InterlockNextState;

  always_comb begin
	case(InterlockCurrState)
	  STATE_T0_READY:     if(EitherTLBMiss & ~TrapM)     InterlockNextState = STATE_T3_TLB_MISS;
	                      else                           InterlockNextState = STATE_T0_READY;
	  STATE_T3_TLB_MISS:  if(~(EitherTLBWrite)) InterlockNextState = STATE_T3_TLB_MISS;
                    	  else if(PendingTLBMiss)        InterlockNextState = STATE_T3_TLB_MISS;
                          else if(AnyCPUReqM)            InterlockNextState = STATE_T0_READY;
                          else                           InterlockNextState = STATE_T0_READY;
	  default:                                           InterlockNextState = STATE_T0_READY;
	endcase
  end // always_comb
	  
   assign InterlockStall = (InterlockCurrState == STATE_T0_READY & EitherTLBMiss & ~TrapM) | 
                           (InterlockCurrState == STATE_T3_TLB_MISS);
  assign SelReplayMemE = (InterlockCurrState == STATE_T3_TLB_MISS & EitherTLBWrite & ~PendingTLBMiss);
  assign SelHPTW = (InterlockCurrState == STATE_T3_TLB_MISS);
  assign IgnoreRequestTLB = (InterlockCurrState == STATE_T0_READY & EitherTLBMiss);
endmodule
