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
   input logic 								reset,
   input logic 								CPUBusy,

   // mmu
   input logic 								CacheableM,
   // cpu side
   input logic [1:0] 						LsuRWM,
   input logic [1:0] 						LsuAtomicM,
   input logic 								FlushDCacheM,
   input logic [11:0] 						LsuAdrE, // virtual address, but we only use the lower 12 bits.
   input logic [`PA_BITS-1:0] 				LsuPAdrM, // physical address
   input logic [11:0] 						PreLsuPAdrM, // physical or virtual address   
   input logic [`XLEN-1:0] 					FinalWriteDataM,
   output logic [`XLEN-1:0] 				ReadDataWordM,
   output logic 							DCacheCommittedM, 

   // Bus fsm interface
   input logic 								IgnoreRequest,
   output logic 							DCacheFetchLine,
   output logic 							DCacheWriteLine,

   input logic 								DCacheBusAck,
   output logic [`PA_BITS-1:0] 				DCacheBusAdr,


   input logic [`DCACHE_BLOCKLENINBITS-1:0] DCacheMemWriteData,
   output logic [`XLEN-1:0] 				ReadDataBlockSetsM [(`DCACHE_BLOCKLENINBITS/`XLEN)-1:0],

   output logic 							DCacheStall,

   // to performance counters
   output logic 							DCacheMiss,
   output logic 							DCacheAccess
   );

  localparam integer 						BLOCKLEN = `DCACHE_BLOCKLENINBITS;
  localparam integer 						NUMLINES = `DCACHE_WAYSIZEINBYTES*8/BLOCKLEN;
  localparam integer 						NUMWAYS = `DCACHE_NUMWAYS;

  localparam integer 						BLOCKBYTELEN = BLOCKLEN/8;
  localparam integer 						OFFSETLEN = $clog2(BLOCKBYTELEN);
  localparam integer 						INDEXLEN = $clog2(NUMLINES);
  localparam integer 						TAGLEN = `PA_BITS - OFFSETLEN - INDEXLEN;
  localparam integer 						WORDSPERLINE = BLOCKLEN/`XLEN;
  localparam integer 						LOGWPL = $clog2(WORDSPERLINE);
  localparam integer 						LOGXLENBYTES = $clog2(`XLEN/8);

  localparam integer 						FlushAdrThreshold   = NUMLINES - 1;

  logic [1:0] 								SelAdrM;
  logic [INDEXLEN-1:0] 						RAdr;
  logic [BLOCKLEN-1:0] 						SRAMWriteData;
  logic 									SetValid, ClearValid;
  logic 									SetDirty, ClearDirty;
  logic [BLOCKLEN-1:0] 						ReadDataLineWayMasked [NUMWAYS-1:0];
  logic [NUMWAYS-1:0] 						WayHit;
  logic 									CacheHit;
  logic [BLOCKLEN-1:0] 						ReadDataLineM;
  logic [WORDSPERLINE-1:0] 					SRAMWordEnable;

  logic 									SRAMWordWriteEnableM;
  logic 									SRAMBlockWriteEnableM;
  logic [NUMWAYS-1:0] 						SRAMBlockWayWriteEnableM;
  logic [NUMWAYS-1:0] 						SRAMWayWriteEnable;
  

  logic [NUMWAYS-1:0] 						VictimWay;
  logic [NUMWAYS-1:0] 						VictimDirtyWay;
  logic 									VictimDirty;

  logic [2**LOGWPL-1:0] 					MemPAdrDecodedW;

  logic [TAGLEN-1:0] 						VictimTagWay [NUMWAYS-1:0];
  logic [TAGLEN-1:0] 						VictimTag;

  logic [INDEXLEN-1:0] 						FlushAdr;
  logic [INDEXLEN-1:0] 						FlushAdrP1;
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
			.d1(PreLsuPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN]), // *** optimize change to virtual address.
			.d2(FlushAdr),
			.s(SelAdrM),
			.y(RAdr));

  cacheway #(.NUMLINES(NUMLINES), .BLOCKLEN(BLOCKLEN), .TAGLEN(TAGLEN), 
			 .OFFSETLEN(OFFSETLEN), .INDEXLEN(INDEXLEN))
  MemWay[NUMWAYS-1:0](.clk, .reset, .RAdr,
					  .PAdr(LsuPAdrM),
					  .WriteEnable(SRAMWayWriteEnable),
					  .VDWriteEnable(VDWriteEnableWay),
					  .WriteWordEnable(SRAMWordEnable),
					  .TagWriteEnable(SRAMBlockWayWriteEnableM), 
					  .WriteData(SRAMWriteData),
					  .SetValid, .ClearValid, .SetDirty, .ClearDirty, .SelEvict,
					  .VictimWay, .FlushWay, .SelFlush,
					  .ReadDataLineWayMasked,
					  .WayHit, .VictimDirtyWay, .VictimTagWay,
					  .InvalidateAll(1'b0));

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

  
  // ReadDataLineWayMaskedM is a 2d array of cache block len by number of ways.
  // Need to OR together each way in a bitwise manner.
  // Final part of the AO Mux.  First is the AND in the cacheway.
  or_rows #(NUMWAYS, BLOCKLEN) ReadDataAOMux(.a(ReadDataLineWayMasked), .y(ReadDataLineM));
  or_rows #(NUMWAYS, TAGLEN) VictimTagAOMux(.a(VictimTagWay), .y(VictimTag));  


  // Convert the Read data bus ReadDataSelectWay into sets of XLEN so we can
  // easily build a variable input mux.
  // *** consider using a limited range shift to do this final muxing.
  genvar index;
  generate
    for (index = 0; index < WORDSPERLINE; index++) begin:readdatablocksetsmux
      assign ReadDataBlockSetsM[index] = ReadDataLineM[((index+1)*`XLEN)-1: (index*`XLEN)];
    end
  endgenerate

  // variable input mux
  
  assign ReadDataWordM = ReadDataBlockSetsM[LsuPAdrM[LOGWPL + LOGXLENBYTES - 1 : LOGXLENBYTES]];

  // Write Path CPU (IEU) side

  onehotdecoder #(LOGWPL)
  adrdec(.bin(LsuPAdrM[LOGWPL+LOGXLENBYTES-1:LOGXLENBYTES]),
		 .decoded(MemPAdrDecodedW));

  assign SRAMWordEnable = SRAMBlockWriteEnableM ? '1 : MemPAdrDecodedW;
  
  assign SRAMBlockWayWriteEnableM = SRAMBlockWriteEnableM ? VictimWay : '0;
  
  mux2 #(NUMWAYS) WriteEnableMux(.d0(SRAMWordWriteEnableM ? WayHit : '0),
								 .d1(SRAMBlockWayWriteEnableM),
								 .s(SRAMBlockWriteEnableM),
								 .y(SRAMWayWriteEnable));



  mux2 #(BLOCKLEN) WriteDataMux(.d0({WORDSPERLINE{FinalWriteDataM}}),
								.d1(DCacheMemWriteData),
								.s(SRAMBlockWriteEnableM),
								.y(SRAMWriteData));

  
  mux3 #(`PA_BITS) BaseAdrMux(.d0({LsuPAdrM[`PA_BITS-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
							  .d1({VictimTag, LsuPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
							  .d2({VictimTag, FlushAdr, {{OFFSETLEN}{1'b0}}}),
							  .s({SelFlush, SelEvict}),
							  .y(DCacheBusAdr));


  // flush address and way generation.
  flopenr #(INDEXLEN)
  FlushAdrReg(.clk,
			  .reset(reset | FlushAdrCntRst),
			  .en(FlushAdrCntEn & FlushWay[NUMWAYS-1]),
			  .d(FlushAdrP1),
			  .q(FlushAdr));
  assign FlushAdrP1 = FlushAdr + 1'b1;


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

  dcachefsm dcachefsm(.clk, .reset, .DCacheFetchLine, .DCacheWriteLine, .DCacheBusAck, 
					  .LsuRWM, .LsuAtomicM, .CPUBusy, .CacheableM, .IgnoreRequest,
 					  .CacheHit, .VictimDirty, .DCacheStall, .DCacheCommittedM, 
					  .DCacheMiss, .DCacheAccess, .SelAdrM, .SetValid, 
					  .ClearValid, .SetDirty, .ClearDirty, .SRAMWordWriteEnableM,
					  .SRAMBlockWriteEnableM, .SelEvict, .SelFlush,
					  .FlushAdrCntEn, .FlushWayCntEn, .FlushAdrCntRst,
					  .FlushWayCntRst, .FlushAdrFlag, .FlushDCacheM, 
					  .VDWriteEnable, .LRUWriteEn);
  

endmodule // dcache
