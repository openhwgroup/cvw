///////////////////////////////////////////
// abhmulticontroller
//
// Written: Ross Thompson August 29, 2022
// ross1728@gmail.com
// Modified: 
//
// Purpose: AHB multi controller interface to merge LSU and IFU controls.
//          See ARM_HIH0033A_AMBA_AHB-Lite_SPEC 1.0
//          Arbitrates requests from instruction and data streams
//          Connects core to peripherals and I/O pins on SOC
//          Bus width presently matches XLEN
//          Anticipate replacing this with an AXI bus interface to communicate with FPGA DRAM/Flash controllers
// 
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module ebu
  (
   input logic                clk, reset,
   // Signals from IFU
   input logic [`PA_BITS-1:0] IFUHADDR, 
   input logic [2:0]          IFUHSIZE,
   input logic [2:0]          IFUHBURST,
   input logic [1:0]          IFUHTRANS,
   output logic               IFUHREADY, 
   // Signals from LSU
   input logic [`PA_BITS-1:0] LSUHADDR,
   input logic [`XLEN-1:0]    LSUHWDATA, // initially support AHBW = XLEN
   input logic [`XLEN/8-1:0]  LSUHWSTRB,
   input logic [2:0]          LSUHSIZE,
   input logic [2:0]          LSUHBURST,
   input logic [1:0]          LSUHTRANS,
   input logic                LSUHWRITE,
   output logic               LSUHREADY,
   // add LSUHWSTRB ***
  
   // AHB-Lite external signals
   (* mark_debug = "true" *) input logic HREADY, HRESP,
   (* mark_debug = "true" *) output logic HCLK, HRESETn,
   (* mark_debug = "true" *) output logic [`PA_BITS-1:0] HADDR, // *** one day switch to a different bus that supports the full physical address
   (* mark_debug = "true" *) output logic [`AHBW-1:0] HWDATA,
   (* mark_debug = "true" *) output logic [`XLEN/8-1:0] HWSTRB,
   (* mark_debug = "true" *) output logic HWRITE, 
   (* mark_debug = "true" *) output logic [2:0] HSIZE,
   (* mark_debug = "true" *) output logic [2:0] HBURST,
   (* mark_debug = "true" *) output logic [3:0] HPROT,
   (* mark_debug = "true" *) output logic [1:0] HTRANS,
   (* mark_debug = "true" *) output logic HMASTLOCK
   );

  typedef enum                logic [1:0] {IDLE, ARBITRATE} statetype;
  statetype CurrState, NextState;

  logic                       LSUDisable, LSUSelect;
  logic                       IFUSave, IFURestore, IFUDisable, IFUSelect;
  logic                       both;

  logic [`PA_BITS-1:0]        IFUHADDROut;
  logic [1:0]                 IFUHTRANSOut;
  logic [2:0]                 IFUHBURSTOut;
  logic [2:0]                 IFUHSIZEOut;
  logic                       IFUHWRITEOut;
  
  logic [`PA_BITS-1:0]        LSUHADDROut;
  logic [1:0]                 LSUHTRANSOut;
  logic [2:0]                 LSUHBURSTOut;
  logic [2:0]                 LSUHSIZEOut;
  logic                       LSUHWRITEOut;

  logic                       IFUReq, LSUReq;

  logic                       BeatCntEn;
  logic [4-1:0]               NextBeatCount, BeatCount;
  logic                       FinalBeat, FinalBeatD;
  logic                       CntReset;
  logic [3:0]                 Threshold;
  logic                       IFUReqD;
  
  
  assign HCLK = clk;
  assign HRESETn = ~reset;


  // if two requests come in at once pick one to select and save the others Address phase
  // inputs.  Abritration scheme is LSU always goes first.

  // input stage IFU
  controllerinputstage IFUInput(.HCLK, .HRESETn, .Save(IFUSave), .Restore(IFURestore), .Disable(IFUDisable),
    .Request(IFUReq),
    .HWRITEIn(1'b0), .HSIZEIn(IFUHSIZE), .HBURSTIn(IFUHBURST), .HTRANSIn(IFUHTRANS), .HADDRIn(IFUHADDR),
    .HWRITEOut(IFUHWRITEOut), .HSIZEOut(IFUHSIZEOut), .HBURSTOut(IFUHBURSTOut), .HREADYOut(IFUHREADY),
    .HTRANSOut(IFUHTRANSOut), .HADDROut(IFUHADDROut), .HREADYIn(HREADY));

  // input stage LSU
  // LSU always has priority so there should never be a need to save and restore the address phase inputs.
  controllerinputstage #(0) LSUInput(.HCLK, .HRESETn, .Save(1'b0), .Restore(1'b0), .Disable(LSUDisable),
    .Request(LSUReq),
    .HWRITEIn(LSUHWRITE), .HSIZEIn(LSUHSIZE), .HBURSTIn(LSUHBURST), .HTRANSIn(LSUHTRANS), .HADDRIn(LSUHADDR), .HREADYOut(LSUHREADY),
    .HWRITEOut(LSUHWRITEOut), .HSIZEOut(LSUHSIZEOut), .HBURSTOut(LSUHBURSTOut),
    .HTRANSOut(LSUHTRANSOut), .HADDROut(LSUHADDROut), .HREADYIn(HREADY));

  // output mux //*** rewrite for general number of controllers.
  assign HADDR = LSUSelect ? LSUHADDROut : IFUSelect ? IFUHADDROut : '0;
  assign HSIZE = LSUSelect ? LSUHSIZEOut : IFUSelect ? IFUHSIZEOut: '0; 
  assign HBURST = LSUSelect ? LSUHBURSTOut : IFUSelect ? IFUHBURSTOut : '0; // If doing memory accesses, use LSUburst, else use Instruction burst.
  assign HTRANS = LSUSelect ? LSUHTRANSOut : IFUSelect ? IFUHTRANSOut: '0; // SEQ if not first read or write, NONSEQ if first read or write, IDLE otherwise
  assign HWRITE = LSUSelect ? LSUHWRITEOut : IFUSelect ? 1'b0 : '0;
  assign HPROT = 4'b0011; // not used; see Section 3.7
  assign HMASTLOCK = 0; // no locking supported

  // data phase muxing.  This would be a mux if IFU wrote data.
  assign HWDATA = LSUHWDATA;
  assign HWSTRB = LSUHWSTRB;
  // HRDATA is sent to all controllers at the core level.

  // FSM decides if arbitration needed.  Arbitration is held until the last beat of
  // a burst is completed.
  assign both = LSUReq & IFUReq;
  flopenl #(.TYPE(statetype)) busreg(HCLK, ~HRESETn, 1'b1, NextState, IDLE, CurrState);
  always_comb 
    case (CurrState) 
      IDLE: if (both)                    NextState = ARBITRATE; 
      else                               NextState = IDLE;
      ARBITRATE: if (HREADY & FinalBeatD & ~(LSUReq & IFUReq)) NextState = IDLE;
      else                               NextState = ARBITRATE;
      default:                           NextState = IDLE;
    endcase

  // This part is only used when burst mode is supported.
  // Controller needs to count beats.
  flopenr #(4) 
  BeatCountReg(.clk(HCLK),
		.reset(~HRESETn | CntReset | FinalBeat),
		.en(BeatCntEn),
		.d(NextBeatCount),
		.q(BeatCount));  
  assign NextBeatCount = BeatCount + 1'b1;

  assign CntReset = NextState == IDLE;
  assign FinalBeat = (BeatCount == Threshold); // Detect when we are waiting on the final access.
  assign BeatCntEn = (NextState == ARBITRATE & HREADY);

  // Used to store data from data phase of AHB.
  flopenr #(1) 
  FinalBeatReg(.clk(HCLK),
		.reset(~HRESETn | CntReset),
		.en(BeatCntEn),
		.d(FinalBeat),
		.q(FinalBeatD));

  // unlike the bus fsm in lsu/ifu, we need to derive the number of beats from HBURST.
  always_comb begin
    case(HBURST)
      0:        Threshold = 4'b0000;
      3:        Threshold = 4'b0011; // INCR4
      5:        Threshold = 4'b0111; // INCR8
      7:        Threshold = 4'b1111; // INCR16
      default:  Threshold = 4'b0000; // INCR without end.
    endcase
  end
  // end of burst mode.
  
  // basic arb always selects LSU when both
  // replace this block for more sophisticated arbitration as needed.
  // Controller 0 (IFU)
  assign IFUSave = CurrState == IDLE & both;
  assign IFURestore = CurrState == ARBITRATE;
  assign IFUDisable = CurrState == ARBITRATE;
  assign IFUSelect = (NextState == ARBITRATE) ? 1'b0 : IFUReq;
  // Controller 1 (LSU)
  assign LSUDisable = CurrState == ARBITRATE ? 1'b0 : (IFUReqD & ~(HREADY & FinalBeatD));
  assign LSUSelect = NextState == ARBITRATE ? 1'b1: LSUReq;

  flopr #(1) ifureqreg(clk, ~HRESETn, IFUReq, IFUReqD);
  

endmodule
