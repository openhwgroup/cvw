///////////////////////////////////////////
// icache.sv
//
// Written: jaallen@g.hmc.edu 2021-03-02
// Modified: 
//
// Purpose: Cache instructions for the ifu so it can access memory less often, saving cycles
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

module icache
  (
   // Basic pipeline stuff
   input logic 				  clk, reset,
   input logic 				  CPUBusy, 
   input logic [`PA_BITS-1:0] PCNextF,
   input logic [`PA_BITS-1:0] PCPF,
   input logic [`XLEN-1:0] 	  PCF,

   input logic 				  ExceptionM, PendingInterruptM,
  
   // Data read in from the ebu unit
   (* mark_debug = "true" *) input logic [`XLEN-1:0] IfuBusHRDATA,
   (* mark_debug = "true" *) input logic ICacheBusAck,
   // Read requested from the ebu unit
   (* mark_debug = "true" *) output logic [`PA_BITS-1:0] ICacheBusAdr,
   (* mark_debug = "true" *) output logic IfuBusFetch,
   // High if the instruction currently in the fetch stage is compressed
   output logic 			  CompressedF,
   // High if the icache is requesting a stall
   output logic 			  ICacheStallF,
   input logic 				  CacheableF,
   input logic 				  ITLBMissF,
   input logic 				  ITLBWriteF,
   input logic 				  InvalidateICacheM,
  
   // The raw (not decompressed) instruction that was requested
   // If this instruction is compressed, upper 16 bits may be the next 16 bits or may be zeros
   (* mark_debug = "true" *) output logic [31:0] FinalInstrRawF
   );

  // Configuration parameters
  localparam integer 		  BLOCKLEN = `ICACHE_BLOCKLENINBITS;
  localparam integer 		  NUMLINES = `ICACHE_WAYSIZEINBYTES*8/`ICACHE_BLOCKLENINBITS;
  localparam integer 		  BLOCKBYTELEN = BLOCKLEN/8;

  localparam integer 		  OFFSETLEN = $clog2(BLOCKBYTELEN);
  localparam integer 		  INDEXLEN = $clog2(NUMLINES);
  localparam integer 		  TAGLEN = `PA_BITS - OFFSETLEN - INDEXLEN;

  localparam WORDSPERLINE = BLOCKLEN/`XLEN;
  localparam LOGWPL = $clog2(WORDSPERLINE);

  localparam FetchCountThreshold = WORDSPERLINE - 1;

  localparam integer 		  PA_WIDTH = `PA_BITS - 2;
  localparam integer 		  NUMWAYS = `ICACHE_NUMWAYS;
  

  // Input signals to cache memory
  logic 					  ICacheMemWriteEnable;
  logic [BLOCKLEN-1:0] 		  ICacheMemWriteData;
  logic [`PA_BITS-1:0] 		  FinalPCPF;  
  // Output signals from cache memory
  logic [31:0] 				  ICacheMemReadData;
  logic 					  ICacheReadEn;
  logic [BLOCKLEN-1:0] 		  ReadLineF;
  

  logic [15:0] 				  SpillDataBlock0;
  logic 					  spill;
  logic 					  spillSave;

  logic 					  FetchCountFlag;
  logic 					  CntEn;
  
  logic [1:1] 				  SelAdr_q;
  
  
  logic [LOGWPL-1:0] 		  FetchCount, NextFetchCount;
  
  logic [`PA_BITS-1:0] 		  PCPSpillF;

  logic 					  CntReset;
  logic [1:0] 				  SelAdr;
  logic [INDEXLEN-1:0] 		  RAdr;
  logic [NUMWAYS-1:0] 		  VictimWay;
  logic 					  LRUWriteEn;
  logic [NUMWAYS-1:0] 		  WayHit;
  logic 					  hit;
  
  
  logic [BLOCKLEN-1:0] 		  ReadDataLineWayMasked [NUMWAYS-1:0];

  logic [31:0] 				  ReadLineSetsF [`ICACHE_BLOCKLENINBITS/16-1:0];
  
  logic [`PA_BITS-1:0] 		  BasePAdrMaskedF;
  logic [OFFSETLEN-1:0] 	  BasePAdrOffsetF;
  
  
  logic [NUMWAYS-1:0] 		  SRAMWayWriteEnable;


  // on spill we want to get the first 2 bytes of the next cache block.
  // the spill only occurs if the PCPF mod BlockByteLength == -2.  Therefore we can
  // simply add 2 to land on the next cache block.
  assign PCPSpillF = PCPF + {{{PA_WIDTH}{1'b0}}, 2'b10}; 

  mux3 #(INDEXLEN)
  AdrSelMux(.d0(PCNextF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
			.d1(PCF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
			.d2(PCPSpillF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
			.s(SelAdr),
			.y(RAdr));


  cacheway #(.NUMLINES(NUMLINES), .BLOCKLEN(BLOCKLEN), .TAGLEN(TAGLEN), 
			 .OFFSETLEN(OFFSETLEN), .INDEXLEN(INDEXLEN), .DIRTY_BITS(0))
  MemWay[NUMWAYS-1:0](.clk, .reset, .RAdr,
					  .PAdr(FinalPCPF),
					  .WriteEnable(SRAMWayWriteEnable),
					  .VDWriteEnable(1'b0),
					  .WriteWordEnable({{(BLOCKLEN/`XLEN){1'b1}}}),
					  .TagWriteEnable(SRAMWayWriteEnable),
					  .WriteData(ICacheMemWriteData),
					  .SetValid(ICacheMemWriteEnable),
					  .ClearValid(1'b0), .SetDirty(1'b0), .ClearDirty(1'b0), .SelEvict(1'b0),
					  .VictimWay,
					  .FlushWay(1'b0), .SelFlush(1'b0),
					  .ReadDataLineWayMasked, .WayHit,
					  .VictimDirtyWay(), .VictimTagWay(),
					  .InvalidateAll(InvalidateICacheM));
  
  generate
    if(NUMWAYS > 1) begin:vict
      cachereplacementpolicy #(NUMWAYS, INDEXLEN, OFFSETLEN, NUMLINES)
      cachereplacementpolicy(.clk, .reset,
							 .WayHit,
							 .VictimWay,
							 .LsuPAdrM(FinalPCPF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
							 .RAdr,
							 .LRUWriteEn);
    end else begin:vict
      assign VictimWay = 1'b1; // one hot.
    end
  endgenerate

  assign hit = | WayHit;

  // ReadDataLineWayMasked is a 2d array of cache block len by number of ways.
  // Need to OR together each way in a bitwise manner.
  // Final part of the AO Mux.  First is the AND in the cacheway.
  or_rows #(NUMWAYS, BLOCKLEN) ReadDataAOMux(.a(ReadDataLineWayMasked), .y(ReadLineF));

  genvar index;
  generate
	for(index = 0; index < BLOCKLEN / 16 - 1; index++) begin:readlinesetsmux
	  assign ReadLineSetsF[index] = ReadLineF[((index+1)*16)+16-1 : (index*16)];
	end
	assign ReadLineSetsF[BLOCKLEN/16-1] = {16'b0, ReadLineF[BLOCKLEN-1:BLOCKLEN-16]};
  endgenerate

  assign ICacheMemReadData = ReadLineSetsF[FinalPCPF[$clog2(BLOCKLEN / 32) + 1 : 1]];
  
  // spills require storing the first cache block so it can merged
  // with the second
  // can optimize size, for now just make it the size of the data
  // leaving the cache memory. 
  flopenr #(16) SpillInstrReg(.clk(clk),
							  .en(spillSave),
							  .reset(reset),
							  .d(ICacheMemReadData[15:0]),
							  .q(SpillDataBlock0));

  assign FinalInstrRawF = spill ? {ICacheMemReadData[15:0], SpillDataBlock0} : ICacheMemReadData;

  // Detect if the instruction is compressed
  assign CompressedF = FinalInstrRawF[1:0] != 2'b11;
  assign spill = &PCF[$clog2(BLOCKLEN/32)+1:1];


  // to compute the fetch address we need to add the bit shifted
  // counter output to the address.
  assign FetchCountFlag = (FetchCount == FetchCountThreshold[LOGWPL-1:0]);

  flopenr #(LOGWPL) 
  FetchCountReg(.clk(clk),
				.reset(reset | CntReset),
				.en(CntEn),
				.d(NextFetchCount),
				.q(FetchCount));

  assign NextFetchCount = FetchCount + 1'b1;
  

  // store read data from memory interface before writing into SRAM.
  genvar 				i;
  generate
    for (i = 0; i < WORDSPERLINE; i++) begin:storebuffer
      flopenr #(`XLEN) sb(.clk(clk),
						  .reset(reset), 
						  .en(ICacheBusAck & (i == FetchCount)),
						  .d(IfuBusHRDATA),
						  .q(ICacheMemWriteData[(i+1)*`XLEN-1:i*`XLEN]));
    end
  endgenerate


  // this mux needs to be delayed 1 cycle as it occurs 1 pipeline stage later.
  // *** read enable may not be necessary.
  flopenr #(1) SelAdrReg(.clk(clk),
						 .reset(reset),
						 .en(ICacheReadEn),
						 .d(SelAdr[1]),
						 .q(SelAdr_q[1]));
  
  assign FinalPCPF = SelAdr_q[1] ? PCPSpillF : PCPF;

  // if not cacheable the offset bits needs to be sent to the EBU.
  // if cacheable the offset bits are discarded.  $ FSM will fetch the whole block.
  assign BasePAdrOffsetF = CacheableF ? {{OFFSETLEN}{1'b0}} : FinalPCPF[OFFSETLEN-1:0];
  assign BasePAdrMaskedF = {FinalPCPF[`PA_BITS-1:OFFSETLEN], BasePAdrOffsetF};
  
  assign ICacheBusAdr = ({{`PA_BITS-LOGWPL{1'b0}}, FetchCount} << $clog2(`XLEN/8)) + BasePAdrMaskedF;
  
  // truncate the offset from PCPF for memory address generation

  assign SRAMWayWriteEnable = ICacheMemWriteEnable ? VictimWay : '0;

  icachefsm  controller(.clk,
						.reset,
						.CPUBusy,
						.ICacheReadEn,
						.ICacheMemWriteEnable,
						.ICacheStallF,
						.ITLBMissF,
						.ITLBWriteF,
						.ExceptionM,
						.PendingInterruptM,
						.ICacheBusAck,
						.IfuBusFetch,
						.hit,
						.FetchCountFlag,
						.spill,
						.spillSave,
						.CntEn,
						.CntReset,
						.SelAdr,
						.LRUWriteEn);

endmodule

