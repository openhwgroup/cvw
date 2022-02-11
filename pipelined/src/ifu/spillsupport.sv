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

module spillsupport (
  input logic              clk,
  input logic              reset,
  input logic              StallF,
  input logic [`XLEN-1:0]  PCF,
  input logic [`XLEN-3:0]  PCPlusUpperF,
  input logic [`XLEN-1:0]  PCNextF,
  input logic [31:0]       InstrRawF,
  input logic              IFUCacheBusStallF,
  output logic [`XLEN-1:0] PCNextFSpill,
  output logic [`XLEN-1:0] PCFSpill,
  output logic             SelNextSpillF,
  output logic [31:0]      PostSpillInstrRawF,
  output logic             CompressedF);


  localparam integer   SPILLTHRESHOLD = (`IMEM == `MEM_CACHE) ? `ICACHE_LINELENINBITS/32 : 1;
  logic [`XLEN-1:0] PCPlus2F;
  logic             TakeSpillF;
  logic             SpillF;
  logic             SelSpillF, SpillSaveF;
  logic [15:0]      SpillDataLine0;

  // *** PLACE ALL THIS IN A MODULE
  // this exists only if there are compressed instructions.
  // reuse PC+2/4 circuitry to avoid needing a second CPA to add 2
  mux2 #(`XLEN) pcplus2mux(.d0({PCF[`XLEN-1:2], 2'b10}), .d1({PCPlusUpperF, 2'b00}), .s(PCF[1]), .y(PCPlus2F));
  mux2 #(`XLEN) pcnextspillmux(.d0(PCNextF), .d1(PCPlus2F), .s(SelNextSpillF), .y(PCNextFSpill));
  mux2 #(`XLEN) pcspillmux(.d0(PCF), .d1(PCPlus2F), .s(SelSpillF), .y(PCFSpill));
  
  assign SpillF = &PCF[$clog2(SPILLTHRESHOLD)+1:1];

  typedef enum      {STATE_SPILL_READY, STATE_SPILL_SPILL} statetype;
  (* mark_debug = "true" *)  statetype CurrState, NextState;

  always_ff @(posedge clk)
    if (reset)    CurrState <= #1 STATE_SPILL_READY;
    else CurrState <= #1 NextState;

  assign TakeSpillF = SpillF & ~IFUCacheBusStallF;
  
  always_comb begin
    case (CurrState)
      STATE_SPILL_READY: if (TakeSpillF) NextState = STATE_SPILL_SPILL;
      else                                    NextState = STATE_SPILL_READY;
      STATE_SPILL_SPILL: if(IFUCacheBusStallF | StallF)    NextState = STATE_SPILL_SPILL;
      else                                    NextState = STATE_SPILL_READY;
      default:                                                   NextState = STATE_SPILL_READY;
    endcase
  end

  assign SelSpillF = (CurrState == STATE_SPILL_SPILL);
  assign SelNextSpillF = (CurrState == STATE_SPILL_READY & TakeSpillF) |
                         (CurrState == STATE_SPILL_SPILL & IFUCacheBusStallF);
  assign SpillSaveF = (CurrState == STATE_SPILL_READY) & TakeSpillF;

  flopenr #(16) SpillInstrReg(.clk(clk),
                              .en(SpillSaveF),
                              .reset(reset),
                              .d((`IMEM == `MEM_CACHE) ? InstrRawF[15:0] : InstrRawF[31:16]),
                              .q(SpillDataLine0));

  assign PostSpillInstrRawF = SpillF ? {InstrRawF[15:0], SpillDataLine0} : InstrRawF;
  assign CompressedF = PostSpillInstrRawF[1:0] != 2'b11;

endmodule
