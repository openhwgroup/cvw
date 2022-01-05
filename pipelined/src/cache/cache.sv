///////////////////////////////////////////
// cache (data cache)
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

module cache #(parameter integer LINELEN, 
				parameter integer NUMLINES, 
				parameter integer NUMWAYS,
			   parameter integer DCACHE = 1)
  (input logic clk,
   input logic 				   reset,
   input logic 				   CPUBusy,

   // cpu side
   input logic [1:0] 		   RW,
   input logic [1:0] 		   Atomic,
   input logic 				   FlushCache,
   input logic [11:0] 		   LsuAdrE, // virtual address, but we only use the lower 12 bits.
   input logic [`PA_BITS-1:0]  LsuPAdrM, // physical address
   input logic [11:0] 		   PreLsuPAdrM, // physical or virtual address   
   input logic [`XLEN-1:0] 	   FinalWriteData,
   output logic [`XLEN-1:0]    ReadDataWord,
   output logic 			   CacheCommitted, 

   // Bus fsm interface
   input logic 				   IgnoreRequest,
   output logic 			   CacheFetchLine,
   output logic 			   CacheWriteLine,

   input logic 				   CacheBusAck,
   output logic [`PA_BITS-1:0] CacheBusAdr,


   input logic [LINELEN-1:0]   CacheMemWriteData,
   output logic [`XLEN-1:0]    ReadDataLineSets [(LINELEN/`XLEN)-1:0],

   output logic 			   CacheStall,

   // to performance counters
   output logic 			   CacheMiss,
   output logic 			   CacheAccess,
   input logic 				   InvalidateCacheM
   );


  localparam integer 						LINEBYTELEN = LINELEN/8;
  localparam integer 						OFFSETLEN = $clog2(LINEBYTELEN);
  localparam integer 						INDEXLEN = $clog2(NUMLINES);
  localparam integer 						TAGLEN = `PA_BITS - OFFSETLEN - INDEXLEN;
  localparam integer 						WORDSPERLINE = LINELEN/`XLEN;
  localparam integer 						LOGWPL = $clog2(WORDSPERLINE);
  localparam integer 						LOGXLENBYTES = $clog2(`XLEN/8);

  localparam integer 						FlushAdrThreshold   = NUMLINES;

  logic [1:0] 								SelAdrM;
  logic [INDEXLEN-1:0] 						RAdr;
  logic [LINELEN-1:0] 						SRAMWriteData;
  logic 									SetValid, ClearValid;
  logic 									SetDirty, ClearDirty;
  logic [LINELEN-1:0] 						ReadDataLineWayMasked [NUMWAYS-1:0];
  logic [NUMWAYS-1:0] 						WayHit;
  logic 									CacheHit;
  logic [LINELEN-1:0] 						ReadDataLineM;
  logic [WORDSPERLINE-1:0] 					SRAMWordEnable;

  logic 									SRAMWordWriteEnableM;
  logic 									SRAMLineWriteEnableM;
  logic [NUMWAYS-1:0] 						SRAMLineWayWriteEnableM;
  logic [NUMWAYS-1:0] 						SRAMWayWriteEnable;
  

  logic [NUMWAYS-1:0] 						VictimWay;
  logic [NUMWAYS-1:0] 						VictimDirtyWay;
  logic 									VictimDirty;

  logic [2**LOGWPL-1:0] 					MemPAdrDecodedW;

  logic [TAGLEN-1:0] 						VictimTagWay [NUMWAYS-1:0];
  logic [TAGLEN-1:0] 						VictimTag;

  logic [INDEXLEN-1:0] 						FlushAdr;
  logic [INDEXLEN-1:0] 						FlushAdrP1;
  logic [INDEXLEN-1:0] 						FlushAdrQ;
  logic 									FlushAdrCntEn;
  logic 									FlushAdrCntRst;
  logic 									FlushAdrFlag;
  
  logic [NUMWAYS-1:0] 						FlushWay;
  logic [NUMWAYS-1:0] 						NextFlushWay;
  logic 									FlushWayCntEn;
  logic 									FlushWayCntRst;  

  logic 									VDWriteEnable;
  logic 									SelEvict;
  logic 									LRUWriteEn;
  logic [NUMWAYS-1:0] 						VDWriteEnableWay;
  logic 									SelFlush;

  // Read Path CPU (IEU) side

  mux3 #(INDEXLEN)
  AdrSelMux(.d0(LsuAdrE[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
			.d1(PreLsuPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
			.d2(FlushAdr),
			.s(SelAdrM),
			.y(RAdr));
  
  cacheway #(.NUMLINES(NUMLINES), .LINELEN(LINELEN), .TAGLEN(TAGLEN), 
			 .OFFSETLEN(OFFSETLEN), .INDEXLEN(INDEXLEN))
  MemWay[NUMWAYS-1:0](.clk, .reset, .RAdr,
					  .PAdr(LsuPAdrM),
					  .WriteEnable(SRAMWayWriteEnable),
					  .VDWriteEnable(VDWriteEnableWay),
					  .WriteWordEnable(SRAMWordEnable),
					  .TagWriteEnable(SRAMLineWayWriteEnableM), 
					  .WriteData(SRAMWriteData),
					  .SetValid, .ClearValid, .SetDirty, .ClearDirty, .SelEvict,
					  .VictimWay, .FlushWay, .SelFlush,
					  .ReadDataLineWayMasked,
					  .WayHit, .VictimDirtyWay, .VictimTagWay,
					  .InvalidateAll(InvalidateCacheM));

  generate
    if(NUMWAYS > 1) begin:vict
      cachereplacementpolicy #(NUMWAYS, INDEXLEN, OFFSETLEN, NUMLINES)
      cachereplacementpolicy(.clk, .reset,
							 .WayHit,
							 .VictimWay,
							 .LsuPAdrM(LsuPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
							 .RAdr,
							 .LRUWriteEn);
    end else begin:vict
      assign VictimWay = 1'b1; // one hot.
    end
  endgenerate

  assign CacheHit = | WayHit;
  assign VictimDirty = | VictimDirtyWay;

  
  // ReadDataLineWayMaskedM is a 2d array of cache line len by number of ways.
  // Need to OR together each way in a bitwise manner.
  // Final part of the AO Mux.  First is the AND in the cacheway.
  or_rows #(NUMWAYS, LINELEN) ReadDataAOMux(.a(ReadDataLineWayMasked), .y(ReadDataLineM));
  or_rows #(NUMWAYS, TAGLEN) VictimTagAOMux(.a(VictimTagWay), .y(VictimTag));  


  // Convert the Read data bus ReadDataSelectWay into sets of XLEN so we can
  // easily build a variable input mux.
  // *** consider using a limited range shift to do this final muxing.
  genvar index;
  generate
	if(DCACHE == 1) begin
      for (index = 0; index < WORDSPERLINE; index++) begin:readdatalinesetsmux
		assign ReadDataLineSets[index] = ReadDataLineM[((index+1)*`XLEN)-1: (index*`XLEN)];
      end
	  // variable input mux
	  assign ReadDataWord = ReadDataLineSets[LsuPAdrM[LOGWPL + LOGXLENBYTES - 1 : LOGXLENBYTES]];

	end else begin
	  logic [31:0] 				  ReadLineSetsF [LINELEN/16-1:0];
	  logic [31:0] 				  FinalInstrRawF;
	  for(index = 0; index < LINELEN / 16 - 1; index++) begin:readlinesetsmux
		assign ReadLineSetsF[index] = ReadDataLineM[((index+1)*16)+16-1 : (index*16)];
	  end
	  assign ReadLineSetsF[LINELEN/16-1] = {16'b0, ReadDataLineM[LINELEN-1:LINELEN-16]};

	  assign FinalInstrRawF = ReadLineSetsF[LsuPAdrM[$clog2(LINELEN / 32) + 1 : 1]];
	  if (`XLEN == 64) begin
		assign ReadDataWord = {32'b0, FinalInstrRawF};		
	  end else begin
	  assign ReadDataWord = FinalInstrRawF;				
	  end

	end
  endgenerate


  // Write Path CPU (IEU) side

  onehotdecoder #(LOGWPL)
  adrdec(.bin(LsuPAdrM[LOGWPL+LOGXLENBYTES-1:LOGXLENBYTES]),
		 .decoded(MemPAdrDecodedW));

  assign SRAMWordEnable = SRAMLineWriteEnableM ? '1 : MemPAdrDecodedW;
  
  assign SRAMLineWayWriteEnableM = SRAMLineWriteEnableM ? VictimWay : '0;
  
  mux2 #(NUMWAYS) WriteEnableMux(.d0(SRAMWordWriteEnableM ? WayHit : '0),
								 .d1(SRAMLineWayWriteEnableM),
								 .s(SRAMLineWriteEnableM),
								 .y(SRAMWayWriteEnable));



  mux2 #(LINELEN) WriteDataMux(.d0({WORDSPERLINE{FinalWriteData}}),
								.d1(CacheMemWriteData),
								.s(SRAMLineWriteEnableM),
								.y(SRAMWriteData));

  
  mux3 #(`PA_BITS) BaseAdrMux(.d0({LsuPAdrM[`PA_BITS-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
							  .d1({VictimTag, LsuPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
							  .d2({VictimTag, FlushAdrQ, {{OFFSETLEN}{1'b0}}}),
							  .s({SelFlush, SelEvict}),
							  .y(CacheBusAdr));


  // flush address and way generation.
  // increment on 2nd to last way
  flopenr #(INDEXLEN)
  FlushAdrReg(.clk,
			  .reset(reset | FlushAdrCntRst),
			  .en(FlushAdrCntEn & FlushWay[NUMWAYS-2]),
			  .d(FlushAdrP1),
			  .q(FlushAdr));
  assign FlushAdrP1 = FlushAdr + 1'b1;

  flopenr #(INDEXLEN)
  FlushAdrQReg(.clk,
			  .reset(reset | FlushAdrCntRst),
			  .en(FlushAdrCntEn),
			  .d(FlushAdr),
			  .q(FlushAdrQ));

  flopenl #(NUMWAYS)
  FlushWayReg(.clk,
			  .load(reset | FlushWayCntRst),
			  .en(FlushWayCntEn),
			  .val({{NUMWAYS-1{1'b0}}, 1'b1}),
			  .d(NextFlushWay),
			  .q(FlushWay));

  assign VDWriteEnableWay = FlushWay & {NUMWAYS{VDWriteEnable}};

  assign NextFlushWay = {FlushWay[NUMWAYS-2:0], FlushWay[NUMWAYS-1]};

  assign FlushAdrFlag = FlushAdr == FlushAdrThreshold[INDEXLEN-1:0] & FlushWay[NUMWAYS-1];

  // controller
  // *** fixme
  logic CacheableM;
  
  assign CacheableM = 1;


  cachefsm cachefsm(.clk, .reset, .CacheFetchLine, .CacheWriteLine, .CacheBusAck, 
					.RW, .Atomic, .CPUBusy, .CacheableM, .IgnoreRequest,
 					.CacheHit, .VictimDirty, .CacheStall, .CacheCommitted, 
					.CacheMiss, .CacheAccess, .SelAdrM, .SetValid, 
					.ClearValid, .SetDirty, .ClearDirty, .SRAMWordWriteEnableM,
					.SRAMLineWriteEnableM, .SelEvict, .SelFlush,
					.FlushAdrCntEn, .FlushWayCntEn, .FlushAdrCntRst,
					.FlushWayCntRst, .FlushAdrFlag, .FlushCache, 
					.VDWriteEnable, .LRUWriteEn);
  

endmodule // dcache
