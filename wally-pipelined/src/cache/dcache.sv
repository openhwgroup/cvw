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
   input logic [6:0] 	       Funct7M,
   input logic [1:0] 	       AtomicM,
   input logic [`XLEN-1:0]     MemAdrE, // virtual address, but we only use the lower 12 bits.
   input logic [`PA_BITS-1:0]  MemPAdrM, // physical address

   input logic [`XLEN-1:0]     WriteDataM,
   output logic [`XLEN-1:0]    ReadDataW,
   output logic 	       DCacheStall,
   output logic CommittedM,

   // inputs from TLB and PMA/P
   input logic 		       FaultM,
   input logic 		       DTLBMissM,
   input logic 		       CacheableM,
   // ahb side
   output logic [`PA_BITS-1:0] AHBPAdr, // to ahb
   output logic 	       AHBRead,
   output logic 	       AHBWrite,
   input logic 		       AHBAck, // from ahb
   input logic [`XLEN-1:0]     HRDATA, // from ahb
   output logic [`XLEN-1:0]    HWDATA // to ahb
   );

  localparam integer	       BLOCKLEN = 256;
  localparam integer	       NUMLINES = 64;
  localparam integer	       NUMWAYS = 4;
  localparam integer	       NUMREPL_BITS = 3;

  localparam integer	       BLOCKBYTELEN = BLOCKLEN/8;
  localparam integer	       OFFSETLEN = $clog2(BLOCKBYTELEN);
  localparam integer	       INDEXLEN = $clog2(NUMLINES);
  localparam integer	       TAGLEN = `PA_BITS - OFFSETLEN - INDEXLEN;
  localparam integer	       WORDSPERLINE = BLOCKLEN/`XLEN;
  localparam integer	       LOGWPL = $clog2(WORDSPERLINE);
  localparam integer 	       LOGXLENBYTES = $clog2(`XLEN/8);


  logic 		       SelAdrM;
  logic [INDEXLEN-1:0]	       SRAMAdr;
  logic [BLOCKLEN-1:0]	       SRAMWriteData;
  logic [BLOCKLEN-1:0] 	       DCacheMemWriteData;
  logic			       SetValidM, ClearValidM;
  logic			       SetDirtyM, ClearDirtyM;
  logic [BLOCKLEN-1:0] 	       ReadDataBlockWayM [NUMWAYS-1:0];
  logic [BLOCKLEN-1:0] 	       ReadDataBlockWayMaskedM [NUMWAYS-1:0];
  logic [BLOCKLEN-1:0] 	       VictimReadDataBLockWayMaskedM [NUMWAYS-1:0];
  logic [TAGLEN-1:0]	       ReadTag [NUMWAYS-1:0];
  logic [NUMWAYS-1:0]	       Valid, Dirty, WayHit;
  logic			       CacheHit;
  logic [NUMREPL_BITS-1:0]     ReplacementBits [NUMLINES-1:0];
  logic [NUMREPL_BITS-1:0]     NewReplacement;
  logic [BLOCKLEN-1:0]	       ReadDataBlockM;
  logic [`XLEN-1:0]	       ReadDataBlockSetsM [(WORDSPERLINE)-1:0];
  logic [`XLEN-1:0]	       VictimReadDataBlockSetsM [(WORDSPERLINE)-1:0];  
  logic [`XLEN-1:0]	       ReadDataWordM, FinalReadDataWordM, ReadDataWordMuxM;
  logic [`XLEN-1:0]	       FinalWriteDataM, FinalAMOWriteDataM;
  logic [BLOCKLEN-1:0]	       FinalWriteDataWordsM;
  logic [LOGWPL:0] 	       FetchCount, NextFetchCount;
  logic [WORDSPERLINE-1:0]     SRAMWordEnable;
  logic 		       SelMemWriteDataM;
  logic [2:0] 		       Funct3W;

  logic 		       SRAMWordWriteEnableM, SRAMWordWriteEnableW;
  logic 		       SRAMBlockWriteEnableM;
  logic 		       SRAMWriteEnable;
  logic [NUMWAYS-1:0] 	       SRAMWayWriteEnable;
  

  logic 		       SaveSRAMRead;
  logic [1:0] 		       AtomicW;
  logic [NUMWAYS-1:0] 	       VictimWay;
  logic [NUMWAYS-1:0] 	       VictimDirtyWay;
  logic [BLOCKLEN-1:0] 	       VictimReadDataBlockM;
  logic 		       VictimDirty;
  logic 		       SelAMOWrite;
  logic 		       SelUncached;
  logic [6:0] 		       Funct7W;
  logic [2**LOGWPL-1:0]	       MemPAdrDecodedW;

  logic [`PA_BITS-1:0] 	       BasePAdrM;
  logic [OFFSETLEN-1:0]        BasePAdrOffsetM;
  logic [`PA_BITS-1:0] 	       BasePAdrMaskedM;  
  logic [TAGLEN-1:0] 	       VictimTagWay [NUMWAYS-1:0];
  logic [TAGLEN-1:0] 	       VictimTag;
    

  flopenr #(7) Funct7WReg(.clk(clk),
			  .reset(reset),
			  .en(~StallW),
			  .d(Funct7M),
			  .q(Funct7W));
  
  

  // data path

  mux2 #(INDEXLEN)
  AdrSelMux(.d0(MemAdrE[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
	    .d1(MemPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
	    .s(SelAdrM),
	    .y(SRAMAdr));


  oneHotDecoder #(LOGWPL)
  oneHotDecoder(.bin(MemPAdrM[LOGWPL+LOGXLENBYTES-1:LOGXLENBYTES]),
		.decoded(MemPAdrDecodedW));
  

  assign SRAMWordEnable = SRAMBlockWriteEnableM ? '1 : MemPAdrDecodedW;
  

  genvar		       way;
  generate
    for(way = 0; way < NUMWAYS; way = way + 1) begin :CacheWays
      DCacheMem #(.NUMLINES(NUMLINES), .BLOCKLEN(BLOCKLEN), .TAGLEN(TAGLEN))
      MemWay(.clk(clk),
	     .reset(reset),
	     .Adr(SRAMAdr),
	     .WAdr(MemPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
	     .WriteEnable(SRAMWayWriteEnable[way]),
	     .WriteWordEnable(SRAMWordEnable),
	     .TagWriteEnable(SRAMBlockWriteEnableM),
	     .WriteData(SRAMWriteData),
	     .WriteTag(MemPAdrM[`PA_BITS-1:OFFSETLEN+INDEXLEN]),
	     .SetValid(SetValidM),
	     .ClearValid(ClearValidM),
	     .SetDirty(SetDirtyM),
	     .ClearDirty(ClearDirtyM),
	     .ReadData(ReadDataBlockWayM[way]),
	     .ReadTag(ReadTag[way]),
	     .Valid(Valid[way]),
	     .Dirty(Dirty[way]));
      assign WayHit[way] = Valid[way] & (ReadTag[way] == MemPAdrM[`PA_BITS-1:OFFSETLEN+INDEXLEN]);
      assign ReadDataBlockWayMaskedM[way] = Valid[way] ? ReadDataBlockWayM[way] : '0;  // first part of AO mux.

      // the cache block candiate for eviction
      // *** this should be sharable with the read data muxing, but for now i'm doing the simple
      // thing and making them separate.
      assign VictimReadDataBLockWayMaskedM[way] = VictimWay[way] ? ReadDataBlockWayM[way] : '0;
      assign VictimDirtyWay[way] = VictimWay[way] & Dirty[way] & Valid[way];
      assign VictimTagWay[way] = Valid[way] ? ReadTag[way] : '0;
    end
  endgenerate

  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      for(int index = 0; index < NUMLINES-1; index++)
	ReplacementBits[index] <= '0;
    end
    else if (SRAMWriteEnable) ReplacementBits[MemPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN]] <= NewReplacement;
  end

  // *** TODO add replacement policy
  assign NewReplacement = '0;
  assign VictimWay = 4'b0001;
  mux2 #(NUMWAYS) WriteEnableMux(.d0(SRAMWordWriteEnableM ? WayHit : '0),
				 .d1(SRAMBlockWriteEnableM ? VictimWay : '0),
				 .s(SRAMBlockWriteEnableM),
				 .y(SRAMWayWriteEnable));
  
  

  assign CacheHit = |WayHit;
  // ReadDataBlockWayMaskedM is a 2d array of cache block len by number of ways.
  // Need to OR together each way in a bitwise manner.
  // Final part of the AO Mux.
  genvar index;
  always_comb begin
    ReadDataBlockM = '0;
    VictimReadDataBlockM = '0;
    VictimTag = '0;
    for(int index = 0; index < NUMWAYS; index++) begin
      ReadDataBlockM = ReadDataBlockM | ReadDataBlockWayMaskedM[index];
      VictimReadDataBlockM = VictimReadDataBlockM | VictimReadDataBLockWayMaskedM[index];
      VictimTag = VictimTag | VictimTagWay[index];      
    end
  end
  assign VictimDirty = | VictimDirtyWay;


  // Convert the Read data bus ReadDataSelectWay into sets of XLEN so we can
  // easily build a variable input mux.
  generate
    for (index = 0; index < WORDSPERLINE; index++) begin
      assign ReadDataBlockSetsM[index] = ReadDataBlockM[((index+1)*`XLEN)-1: (index*`XLEN)];
      assign VictimReadDataBlockSetsM[index] = VictimReadDataBlockM[((index+1)*`XLEN)-1: (index*`XLEN)];      
    end
  endgenerate

  // variable input mux
  assign ReadDataWordM = ReadDataBlockSetsM[MemPAdrM[$clog2(WORDSPERLINE+`XLEN/8) : $clog2(`XLEN/8)]];

  assign HWDATA = CacheableM ? VictimReadDataBlockSetsM[FetchCount] : WriteDataM;

  mux2 #(`XLEN) UnCachedDataMux(.d0(ReadDataWordM),
				.d1(DCacheMemWriteData[`XLEN-1:0]),
				.s(SelUncached),
				.y(ReadDataWordMuxM));
  
  // finally swr
  // *** BUG fix HSIZED? why was it this way?
  subwordread subwordread(.HRDATA(ReadDataWordMuxM),
			  .HADDRD(MemPAdrM[2:0]),
			  .HSIZED({Funct3M[2], 1'b0, Funct3M[1:0]}),
			  .HRDATAMasked(FinalReadDataWordM));
  

  flopen #(`XLEN) ReadDataWReg(.clk(clk),
			      .en(~StallW),
			      .d(FinalReadDataWordM),
			      .q(ReadDataW));

  // write path
  subwordwrite subwordwrite(.HRDATA(ReadDataWordM),
			    .HADDRD(MemPAdrM[2:0]),
			    .HSIZED({Funct3M[2], 1'b0, Funct3M[1:0]}),
			    .HWDATAIN(WriteDataM),
			    .HWDATA(FinalWriteDataM));

  generate
    if (`A_SUPPORTED) begin
      logic [`XLEN-1:0] AMOResult;
      amoalu amoalu(.srca(FinalReadDataWordM), .srcb(WriteDataM), .funct(Funct7M), .width(Funct3M[1:0]), 
                    .result(AMOResult));
      mux2 #(`XLEN) wdmux(FinalWriteDataM, AMOResult, SelAMOWrite & AtomicM[1], FinalAMOWriteDataM);
    end else
      assign FinalAMOWriteDataM = FinalWriteDataM;
  endgenerate
  

  // register the fetch data from the next level of memory.
  generate
    for (index = 0; index < WORDSPERLINE; index++) begin:fetchbuffer
      flopen #(`XLEN) fb(.clk(clk),
			 .en(AHBAck & AHBRead & (index == FetchCount)),
			 .d(HRDATA),
			 .q(DCacheMemWriteData[(index+1)*`XLEN-1:index*`XLEN]));
    end
  endgenerate

  // *** Coding style. this is just awful. The purpose is to align FetchCount to the
  // size of XLEN so we can fetch XLEN bits.  FetchCount needs to be padded to PA_BITS length.
  // *** optimize this
  mux2 #(`PA_BITS) BaseAdrMux(.d0(MemPAdrM),
			      .d1({VictimTag, MemPAdrM[INDEXLEN+OFFSETLEN-1:OFFSETLEN], {{OFFSETLEN}{1'b0}}}),
			      .s(AHBWrite & CacheableM),
			      .y(BasePAdrM));

  assign BasePAdrOffsetM = CacheableM ? {{OFFSETLEN}{1'b0}} : BasePAdrM[OFFSETLEN-1:0];
  assign BasePAdrMaskedM = {BasePAdrM[`PA_BITS-1:OFFSETLEN], BasePAdrOffsetM};
  
  generate
    if (`XLEN == 32) begin
      assign AHBPAdr = ({{`PA_BITS-4{1'b0}}, FetchCount} << 2) + BasePAdrMaskedM;
    end else begin
      assign AHBPAdr = ({{`PA_BITS-3{1'b0}}, FetchCount} << 3) + BasePAdrMaskedM;
    end
  endgenerate
    
  
  // mux between the CPU's write and the cache fetch.
  generate
    for(index = 0; index < WORDSPERLINE; index++) begin
      assign FinalWriteDataWordsM[((index+1)*`XLEN)-1 : (index*`XLEN)] = FinalAMOWriteDataM;
    end
  endgenerate

  mux2 #(BLOCKLEN) WriteDataMux(.d0(FinalWriteDataWordsM),
				.d1(DCacheMemWriteData),
				.s(SRAMBlockWriteEnableM),
				.y(SRAMWriteData));


  // control path *** eventually move to own module.

  logic AnyCPUReqM;
  logic FetchCountFlag;
  logic PreCntEn;
  logic CntEn;
  logic CntReset;
  
  
  typedef enum {STATE_READY,
		STATE_MISS_FETCH_WDV,
		STATE_MISS_FETCH_DONE,
		STATE_MISS_EVICT_DIRTY,
		STATE_MISS_WRITE_BACK_EVICTED_BLOCK,
		STATE_MISS_WRITE_CACHE_BLOCK,
		STATE_MISS_READ_WORD,
		STATE_MISS_READ_WORD_DELAY,
		STATE_MISS_WRITE_WORD,
		STATE_AMO_MISS_FETCH_WDV,
		STATE_AMO_MISS_FETCH_DONE,
		STATE_AMO_MISS_CHECK_EVICTED_DIRTY,
		STATE_AMO_MISS_WRITE_BACK_EVICTED_BLOCK,
		STATE_AMO_MISS_WRITE_CACHE_BLOCK,
		STATE_AMO_MISS_READ_WORD,
		STATE_AMO_MISS_UPDATE_WORD,
		STATE_AMO_MISS_WRITE_WORD,
		STATE_AMO_UPDATE,
		STATE_AMO_WRITE,
		STATE_PTW_READY,
		STATE_PTW_MISS_FETCH_WDV,
		STATE_PTW_MISS_FETCH_DONE,
		STATE_PTW_MISS_CHECK_EVICTED_DIRTY,
		STATE_PTW_MISS_WRITE_BACK_EVICTED_BLOCK,
		STATE_PTW_MISS_WRITE_CACHE_BLOCK,
		STATE_PTW_MISS_READ_SRAM,
		STATE_UNCACHED_WRITE,
		STATE_UNCACHED_WRITE_DONE,
		STATE_UNCACHED_READ,
		STATE_UNCACHED_READ_DONE,
		STATE_CPU_BUSY} statetype;

  statetype CurrState, NextState;

  
  localparam FetchCountThreshold = WORDSPERLINE - 1;
  

  assign AnyCPUReqM = |MemRWM | (|AtomicM);
  assign FetchCountFlag = (FetchCount == FetchCountThreshold[LOGWPL:0]);

  flopenr #(LOGWPL+1) 
  FetchCountReg(.clk(clk),
		.reset(reset | CntReset),
		.en(CntEn),
		.d(NextFetchCount),
		.q(FetchCount));

  assign NextFetchCount = FetchCount + 1'b1;

  assign SRAMWriteEnable = SRAMBlockWriteEnableM | SRAMWordWriteEnableM;

  flopr #(1)
  SRAMWritePipeReg(.clk(clk),
	      .reset(reset),
	      .d({SRAMWordWriteEnableM}),
	      .q({SRAMWordWriteEnableW}));
  

  always_ff @(posedge clk, posedge reset)
    if (reset)    CurrState <= #1 STATE_READY;
    else CurrState <= #1 NextState;


  // next state logic and some state ouputs.
  always_comb begin
    DCacheStall = 1'b0;
    SelAdrM = 1'b0;
    PreCntEn = 1'b0;
    SetValidM = 1'b0;
    ClearValidM = 1'b0;
    SetDirtyM = 1'b0;    
    ClearDirtyM = 1'b0;
    SelMemWriteDataM = 1'b0;
    SRAMWordWriteEnableM = 1'b0;
    SRAMBlockWriteEnableM = 1'b0;
    SaveSRAMRead = 1'b1;
    CntReset = 1'b0;
    AHBRead = 1'b0;
    AHBWrite = 1'b0;
    SelAMOWrite = 1'b0;
    CommittedM = 1'b0;        
    SelUncached = 1'b0;

    case (CurrState)
      STATE_READY: begin
	// TLB Miss	
	if(AnyCPUReqM & DTLBMissM) begin                      
	  NextState = STATE_PTW_MISS_FETCH_WDV;
	end
	// amo hit
	else if(|AtomicM & CacheableM & ~FaultM & CacheHit & ~DTLBMissM) begin
	  NextState = STATE_AMO_UPDATE;
	  DCacheStall = 1'b1;

	  if(StallW) NextState = STATE_CPU_BUSY;
	  else NextState = STATE_READY;
	end
	// read hit valid cached
	else if(MemRWM[1] & CacheableM & ~FaultM & CacheHit & ~DTLBMissM) begin
	  NextState = STATE_READY;
	  DCacheStall = 1'b0;

	  if(StallW) NextState = STATE_CPU_BUSY;
	  else NextState = STATE_READY;
	end
	// write hit valid cached
	else if (MemRWM[0] & CacheableM & ~FaultM & CacheHit & ~DTLBMissM) begin
	  SelAdrM = 1'b1;
	  DCacheStall = 1'b0;
	  SRAMWordWriteEnableM = 1'b1;
	  SetDirtyM = 1'b1;
	  
	  if(StallW) NextState = STATE_CPU_BUSY;
	  else NextState = STATE_READY;
	end
	// read or write miss valid cached
	else if((|MemRWM) & CacheableM & ~FaultM & ~CacheHit & ~DTLBMissM) begin
	  NextState = STATE_MISS_FETCH_WDV;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	end
	// uncached write
	else if(MemRWM[0] & ~CacheableM & ~FaultM & ~DTLBMissM) begin
	  NextState = STATE_UNCACHED_WRITE;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	  AHBWrite = 1'b1;
	end
	// uncached read
	else if(MemRWM[1] & ~CacheableM & ~FaultM & ~DTLBMissM) begin
	  NextState = STATE_UNCACHED_READ;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	  AHBRead = 1'b1;	  
	end
	// fault
	else if(AnyCPUReqM & FaultM & ~DTLBMissM) begin
	  NextState = STATE_READY;
	end
	else NextState = STATE_READY;
      end
      
      STATE_AMO_UPDATE: begin
	NextState = STATE_AMO_WRITE;
	SaveSRAMRead = 1'b1;
	SRAMWordWriteEnableM = 1'b1; // pipelined 1 cycle
      end
      STATE_AMO_WRITE: begin
	NextState = STATE_READY;
	SelAMOWrite = 1'b1;
      end

      STATE_MISS_FETCH_WDV: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
	AHBRead = 1'b1;
	SelAdrM = 1'b1;
	CommittedM = 1'b1;
	
        if (FetchCountFlag & AHBAck) begin
          NextState = STATE_MISS_FETCH_DONE;
        end else begin
          NextState = STATE_MISS_FETCH_WDV;
        end
      end

      STATE_MISS_FETCH_DONE: begin
	DCacheStall = 1'b1;
	SelAdrM = 1'b1;
        CntReset = 1'b1;
	CommittedM = 1'b1;
	if(VictimDirty) begin
	  NextState = STATE_MISS_EVICT_DIRTY;
	end else begin
	  NextState = STATE_MISS_WRITE_CACHE_BLOCK;
	end
      end

      STATE_MISS_WRITE_CACHE_BLOCK: begin
	SRAMBlockWriteEnableM = 1'b1;
	DCacheStall = 1'b1;
	NextState = STATE_MISS_READ_WORD;
	SelAdrM = 1'b1;
	SetValidM = 1'b1;
	ClearDirtyM = 1'b1;
	CommittedM = 1'b1;
      end

      STATE_MISS_READ_WORD: begin
	SelAdrM = 1'b1;
	DCacheStall = 1'b1;
	CommittedM = 1'b1;
	if (MemRWM[1]) begin
	  NextState = STATE_MISS_READ_WORD_DELAY;
	  // delay state is required as the read signal MemRWM[1] is still high when we
	  // return to the ready state because the cache is stalling the cpu.
	end else begin
	  NextState = STATE_MISS_WRITE_WORD;
	end
      end

      STATE_MISS_READ_WORD_DELAY: begin
	SelAdrM = 1'b1;
	NextState = STATE_READY;
	CommittedM = 1'b1;
      end

      STATE_MISS_WRITE_WORD: begin
	SRAMWordWriteEnableM = 1'b1;
	SetDirtyM = 1'b1;
	SelAdrM = 1'b1;
	NextState = STATE_READY;
	DCacheStall = 1'b0;
	CommittedM = 1'b1;
      end

      STATE_MISS_EVICT_DIRTY: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
	AHBWrite = 1'b1;
	SelAdrM = 1'b1;
	CommittedM = 1'b1;
	if( FetchCountFlag & AHBAck) begin
	  NextState = STATE_MISS_WRITE_CACHE_BLOCK;
	end else begin
	  NextState = STATE_MISS_EVICT_DIRTY;
	end	  
      end

      STATE_PTW_MISS_FETCH_WDV: begin
	DCacheStall = 1'b1;
	SelAdrM = 1'b1;
	if (FetchCountFlag & AHBAck) begin
	  NextState = STATE_PTW_MISS_FETCH_DONE;
	end else begin
	  NextState = STATE_PTW_MISS_FETCH_WDV;
	end
      end

      STATE_CPU_BUSY : begin
	if(StallW) NextState = STATE_CPU_BUSY;
	else NextState = STATE_READY;
      end

      STATE_UNCACHED_WRITE : begin
	DCacheStall = 1'b1;	
	AHBWrite = 1'b1;
	CommittedM = 1'b1;
	if(AHBAck) begin
	  NextState = STATE_UNCACHED_WRITE_DONE;
	end else begin
	  NextState = STATE_UNCACHED_WRITE;
	end
      end

      STATE_UNCACHED_READ : begin
	DCacheStall = 1'b1;	
	AHBRead = 1'b1;
	CommittedM = 1'b1;
	if(AHBAck) begin
	  NextState = STATE_UNCACHED_READ_DONE;
	end else begin
	  NextState = STATE_UNCACHED_READ;
	end
      end
      
      STATE_UNCACHED_WRITE_DONE: begin
	CommittedM = 1'b1;
	NextState = STATE_READY;
      end

      STATE_UNCACHED_READ_DONE: begin
	CommittedM = 1'b1;
	SelUncached = 1'b1;
	NextState = STATE_READY;
      end

      default: begin
      end
    endcase
  end

  assign CntEn = PreCntEn & AHBAck;

endmodule // dcache
