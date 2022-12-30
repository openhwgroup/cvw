///////////////////////////////////////////
// spillsupport.sv
//
// Written: Ross Thompson ross1728@gmail.com January 28, 2022
// Modified:
//
// Purpose: allows the IFU to make extra memory request if instruction address crosses
//          cache line boundaries or if instruction address without a cache crosses
//          XLEN/8 boundary.
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

module spillsupport #(parameter CACHE_ENABLED)
  (input logic              clk,
   input logic              reset,
   input logic              StallF, Flush,
   input logic [`XLEN-1:0]  PCF,
   input logic [`XLEN-1:2]  PCPlus4F,
   input logic [`XLEN-1:0]  PCNextF,
   input logic [31:0]       InstrRawF,
   input logic              IFUCacheBusStallD,
   input logic              ITLBMissF, 
   output logic [`XLEN-1:0] PCNextFSpill,
   output logic [`XLEN-1:0] PCFSpill,
   output logic             SelNextSpillF,
   output logic [31:0]      PostSpillInstrRawF,
   output logic             CompressedF);


  localparam integer   SPILLTHRESHOLD = CACHE_ENABLED ? `ICACHE_LINELENINBITS/32 : 1;
  logic [`XLEN-1:0]    PCPlus2F;
  logic                TakeSpillF;
  logic                SpillF, PossibleSpillF, FirstHalfCompressedF;
  logic                SelSpillF, SpillSaveF;
  logic [15:0]         InstrFirstHalfF;
  typedef enum logic [1:0]     {STATE_READY, STATE_SPILL} statetype;
  (* mark_debug = "true" *)  statetype CurrState, NextState;

  // compute PCF+2
  mux2 #(`XLEN) pcplus2mux(.d0({PCF[`XLEN-1:2], 2'b10}), .d1({PCPlus4F, 2'b00}), .s(PCF[1]), .y(PCPlus2F));
  // select between PCNextF and PCF+2
  mux2 #(`XLEN) pcnextspillmux(.d0(PCNextF), .d1(PCPlus2F), .s(SelNextSpillF & ~Flush), .y(PCNextFSpill));
  // select between PCF and PCF+2
  mux2 #(`XLEN) pcspillmux(.d0(PCF), .d1(PCPlus2F), .s(SelSpillF), .y(PCFSpill));
  
  assign PossibleSpillF = &PCF[$clog2(SPILLTHRESHOLD)+1:1];
  assign SpillF = PossibleSpillF & ~FirstHalfCompressedF & ~IFUCacheBusStallD;
  assign TakeSpillF = SpillF & ~ITLBMissF;
  
  always_ff @(posedge clk)
    if (reset | Flush)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;

  always_comb begin
    case (CurrState)
      STATE_READY: if (TakeSpillF)                NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      STATE_SPILL: if(IFUCacheBusStallD | StallF) NextState = STATE_SPILL;
                   else                           NextState = STATE_READY;
      default:                                    NextState = STATE_READY;
    endcase
  end

  assign SelSpillF = (CurrState == STATE_SPILL);
  assign SelNextSpillF = (CurrState == STATE_READY & TakeSpillF) |
                         (CurrState == STATE_SPILL & IFUCacheBusStallD);
  assign SpillSaveF = (CurrState == STATE_READY) & TakeSpillF;
  
  flopenr #(16) SpillInstrReg(.clk(clk),
                              .en(SpillSaveF  & ~Flush),
                              .reset(reset),
                              .d(InstrRawF[15:0]),
                              .q(InstrFirstHalfF));

  mux2 #(32) postspillmux(.d0(InstrRawF), .d1({InstrRawF[15:0], InstrFirstHalfF}), .s(SelSpillF),
    .y(PostSpillInstrRawF));
  assign CompressedF = PostSpillInstrRawF[1:0] != 2'b11;
  assign FirstHalfCompressedF = InstrRawF[1:0] != 2'b11;

endmodule
