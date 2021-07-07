///////////////////////////////////////////
// dcache (data cache)
//
// Written: ross1728@gmail.com July 07, 2021
//          Implements the L1 data cache
//
// Purpose: Storage for data and meta data.
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

module dcache
  (input logic clk, 
   input logic 		       reset,
   input logic 		       StallM,
   input logic 		       StallW,
   input logic 		       FlushM,
   input logic 		       FlushW,

   // cpu side
   input logic [1:0] 	       MemRWM,
   input logic [2:0] 	       Funct3M,
   input logic [1:0] 	       AtomicM,
   input logic [`PA_BITS-1:0]  MemAdrE, // virtual address, but we only use the lower 12 bits.
   input logic [`PA_BITS-1:0]  MemPAdrM, // physical address
  
   input logic [`XLEN-1:0]     WriteDataM, 
   output logic [`XLEN-1:0]    ReadDataW,
   output logic 	       DCacheStall,

   // inputs from TLB and PMA/P
   input logic 		       FaultM,
   input logic 		       DTLBMissM,
   // ahb side
   output logic [`PA_BITS-1:0] AHBPAdr, // to ahb
   output logic 	       AHBRead,
   output logic 	       AHBWrite,
   input logic 		       AHBAck, // from ahb
   input logic [`XLEN-1:0]     HRDATA, // from ahb
   output logic [`XLEN-1:0]    HWDATA, // to ahb   
   output logic [2:0] 	       AHBSize
   );

  localparam integer 	       BLOCKLEN = 256;
  localparam integer 	       NUMLINES = 512;
  localparam integer 	       NUMWAYS = 4;
  localparam integer 	       NUMREPL_BITS = 3;

  localparam integer 	       BLOCKBYTELEN = BLOCKLEN/8;
  localparam integer 	       OFFSETLEN = $clog2(BLOCKBYTELEN);
  localparam integer 	       INDEXLEN = $clog2(NUMLINES);
  localparam integer 	       TAGLEN = `PA_BITS - OFFSETLEN - INDEXLEN;
  localparam integer 	       WORDSPERLINE = BLOCKLEN/`XLEN;


  logic [1:0] 		       AdrSel;
  logic [`PA_BITS-1:0] 	       MemPAdrW;
  logic [INDEXLEN-1:0] 	       SRAMAdr;
  logic [NUMWAYS-1:0] 	       WriteEnable;
  logic [NUMWAYS-1:0] 	       WriteWordEnable;  
  logic [BLOCKLEN-1:0] 	       SRAMWriteData;
  logic [TAGLEN-1:0] 	       WriteTag;
  logic 		       SetValid, ClearValid;
  logic 		       SetDirty, ClearDirty;
  logic [BLOCKLEN-1:0] 	       ReadDataM, ReadDataMaskedM [NUMWAYS-1:0];
  logic [TAGLEN-1:0] 	       TagData [NUMWAYS-1:0];
  logic [NUMWAYS-1:0] 	       Valid, Dirty, WayHit;
  logic 		       Hit;
  logic [NUMREPL_BITS-1:0]     ReplacementBits, NewReplacement;
  logic [BLOCKLEN-1:0] 	       ReadDataSelectWayM;
  logic [`XLEN-1:0] 	       ReadDataSelectWayXLEN [(WORDSPERLINE)-1:0];
  logic [`XLEN-1:0] 	       WordReadDataM, FinalReadDataM;
  logic [`XLEN-1:0] 	       WriteDataW, FinalWriteDataW;
  logic [BLOCKLEN-1:0] 	       FinalWriteDataWordsW;
  
  
  typedef enum 		       {STATE_READY,
				STATE_MISS_FETCH_WDV,
				STATE_MISS_FETCH_DONE,
				STATE_MISS_WRITE_BACK,
				STATE_MISS_READ_SRAM,
				STATE_AMO_MISS_FETCH_WDV,
				STATE_AMO_MISS_FETCH_DONE,
				STATE_AMO_MISS_WRITE_BACK,
				STATE_AMO_MISS_READ_SRAM,
				STATE_AMO_MISS_UPDATE,
				STATE_AMO_MISS_WRITE,
				STATE_AMO_UPDATE,
				STATE_AMO_WRITE,
				STATE_SRAM_BUSY,
				STATE_PTW_READY,
				STATE_PTW_FETCH,
				STATE_UNCACHED} statetype;

  statetype CurrState, NextState;


  flopen #(`PA_BITS) MemPAdrWReg(.clk(clk),
				 .en(~StallW),
				 .d(MemPAdrM),
				 .q(MemPAdrW));

  mux3 #(INDEXLEN)
  AdrSelMux(.d0(MemAdrE[INDEXLEN+OFFSET-1:OFFSET]),
	    .d1(MemPAdrM[INDEXLEN+OFFSET-1:OFFSET]),
	    .d2(MemPAdrW[INDEXLEN+OFFSET-1:OFFSET]),
	    .s(AdrSel),
	    .y(SRAMAdr));

  genvar 		       way;
  generate
    for(way = 0; way < NUMWAYS; way = way + 1) begin
      DCacheMem #(.NUMLINES(NUMLINES), .BLOCKLEN(BLOCKLEN), .TAGLEN(TAGLEN))
      MemWay(.clk(clk),
	     .reset(reset),
	     .Adr(SRAMAdr),
	     .WAdr(MemPAdrW[INDEXLEN+OFFSET-1:OFFSET]),
	     .WriteEnable(SRAMWriteEnable[way]),
	     .WriteWordEnable(SRAMWordEnable[way]),
	     .WriteData(SRAMWriteData),
	     .WriteTag(WriteTag),
	     .SetValid(SetValid),
	     .ClearValid(ClearValid),
	     .SetDirty(SetDirty),
	     .ClearDirty(ClearDirty),
	     .ReadData(ReadDataM[way]),
	     .ReadTag(ReadTag[way]),
	     .Valid(Valid[way]),
	     .Dirty(Dirty[way]));
      assign WayHit = Valid & (ReadTag[way] == MemAdrM);
      assign ReadDataMaskedM = Valid[way] ? ReadDataM[way] : '0;  // first part of AO mux.
    end
  endgenerate

  always_ff @(posedge clk, posedge reset) begin
    if (reset) ReplacementBits <= '0;
    else if (WriteEnable) ReplacementBits[MemPAdrW[INDEXLEN+OFFSET-1:OFFSET]] <= NewReplacement;
  end
  
  assign Hit = |WayHit;
  assign ReadDataSelectWayM = |ReadDataMaskedM; // second part of AO mux.

  // Convert the Read data bus ReadDataSelectWay into sets of XLEN so we can
  // easily build a variable input mux.
  genvar index;
  generate
    for (index = 0; index < WORDSPERLINE; index++) begin
      assign ReadDataSelectWayM[index] = ReadDataSelectM[((index+1)*`XLEN)-1: (index*`XLEN)];
    end
  endgenerate

  // variable input mux
  assign WordReadDataM = ReadDataSelectWayM[MemPAdrM[WORDSPERLINE+$clog2(`XLEN/8) : $clog2(`XLEN/8)]];
  // finally swr
  subwordread subwordread(.HRDATA(WordReadDataM),
			  .HADDRD(MemPAdrM[`XLEN/8-1:0]),
			  .HSIZED(Funct3M),
			  .HRDATAMasked(FinalReadDataM));

  flopen #(XLEN) ReadDataWReg(.clk(clk),
			      .en(~StallW),
			      .d(FinalReadDataM),
			      .q(ReadDataW));

  // write path
  flopen #(XLEN) WriteDataWReg(.clk(clk),
			       .en(~StallW),
			       .d(WriteDataM),
			       .q(WriteDataW));
  
  subwordwrite subwordwrite(.HRDATA(ReadDataW),
			    .HADDRD(MemPAdrM[`XLEN/8-1:0]),
			    .HSIZED(Funct3W),
			    .HWDATAIN(WriteDataW),
			    .HWDATA(FinalWriteDataW));

  // register the fetch data from the next level of memory.
  generate
    for (index = 0; index < WORDSPERLINE; index++) begin:fetchbuffer
      flopen #(`XLEN) fb(.clk(clk),
			 .en(AHBAck & (index == FetchCount)),
			 .d(HRDATA),
			 .q(DCacheMemWriteData[(index+1)*`XLEN-1:index*`XLEN]));
    end
  endgenerate
  
  // mux between the CPU's write and the cache fetch.
  generate
    for(index = 0; index < WORDSPERLINE; index++) begin
      assign FinalWriteDataWordsW[((index+1)*`XLEN)-1 : (index*`XLEN)] = FinalWriteDataW;
    end
  endgenerate

  mux2 #(BLOCKLEN) WriteDataMux(.d0(FinalWriteDataWordsW),
				.d1(DCacheMemWriteData),
				.s(SelMemWriteData),
				.y(SRAMWriteData));

  

  
  
endmodule; // dcache


