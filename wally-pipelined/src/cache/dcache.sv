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
   input logic		       reset,
   input logic		       StallM,
   input logic		       StallW,
   input logic		       FlushM,
   input logic		       FlushW,

   // cpu side
   input logic [1:0]	       MemRWM,
   input logic [2:0]	       Funct3M,
   input logic [1:0]	       AtomicM,
   input logic [`PA_BITS-1:0]  MemAdrE, // virtual address, but we only use the lower 12 bits.
   input logic [`PA_BITS-1:0]  MemPAdrM, // physical address

   input logic [`XLEN-1:0]     WriteDataM,
   output logic [`XLEN-1:0]    ReadDataW,
   output logic		       DCacheStall,

   // inputs from TLB and PMA/P
   input logic		       FaultM,
   input logic		       DTLBMissM,
   input logic		       UncachedM,
   // ahb side
   output logic [`PA_BITS-1:0] AHBPAdr, // to ahb
   output logic		       AHBRead,
   output logic		       AHBWrite,
   input logic		       AHBAck, // from ahb
   input logic [`XLEN-1:0]     HRDATA, // from ahb
   output logic [`XLEN-1:0]    HWDATA, // to ahb
   output logic [2:0]	       AHBSize
   );

  localparam integer	       BLOCKLEN = 256;
  localparam integer	       NUMLINES = 512;
  localparam integer	       NUMWAYS = 4;
  localparam integer	       NUMREPL_BITS = 3;

  localparam integer	       BLOCKBYTELEN = BLOCKLEN/8;
  localparam integer	       OFFSETLEN = $clog2(BLOCKBYTELEN);
  localparam integer	       INDEXLEN = $clog2(NUMLINES);
  localparam integer	       TAGLEN = `PA_BITS - OFFSETLEN - INDEXLEN;
  localparam integer	       WORDSPERLINE = BLOCKLEN/`XLEN;
  localparam integer	       LOGWPL = $clog2(WORDSPERLINE);
  


  logic 		       SelAdrM;
  logic [`PA_BITS-1:0]	       MemPAdrW;
  logic [INDEXLEN-1:0]	       SRAMAdr;
  logic [NUMWAYS-1:0]	       WriteEnable;
  logic [NUMWAYS-1:0]	       WriteWordEnable;
  logic [BLOCKLEN-1:0]	       SRAMWriteData;
  logic			       SetValidM, ClearValidM, SetValidW, ClearValidW;
  logic			       SetDirtyM, ClearDirtyM, SetDirtyW, ClearDirtyW;
  logic [BLOCKLEN-1:0]	       ReadDataM, ReadDataMaskedM [NUMWAYS-1:0];
  logic [TAGLEN-1:0]	       TagData [NUMWAYS-1:0];
  logic [NUMWAYS-1:0]	       Valid, Dirty, WayHit;
  logic			       CacheHit;
  logic [NUMREPL_BITS-1:0]     ReplacementBits, NewReplacement;
  logic [BLOCKLEN-1:0]	       ReadDataSelectWayM;
  logic [`XLEN-1:0]	       ReadDataSelectWayXLEN [(WORDSPERLINE)-1:0];
  logic [`XLEN-1:0]	       WordReadDataM, FinalReadDataM;
  logic [`XLEN-1:0]	       WriteDataW, FinalWriteDataW, FinalAMOWriteDataW;
  logic [BLOCKLEN-1:0]	       FinalWriteDataWordsW;
  logic [LOGWPL:0] 	       FetchCount, NextFetchCount;
  logic [NUMWAYS-1:0] 	       SRAMWordWriteEnableM, SRAMWordWriteEnableW;
  logic [WORDSPERLINE-1:0]     SRAMWordEnable [NUMWAYS-1:0];
  logic 		       SelMemWriteDataM, SelMemWriteDataW;
  logic [2:0] 		       Funct3W;

  logic 		       SRAMWordWriteEnableM, SRAMWordWriteEnableW;
  logic 		       SRAMBlockWriteEnableM;
  logic 		       SRAMWriteEnable;

  logic 		       SaveSRAMRead;
  logic [1:0] 		       AtomicW;
  
  
  
  

  // data path

  flopen #(`PA_BITS) MemPAdrWReg(.clk(clk),
				 .en(~StallW),
				 .d(MemPAdrM),
				 .q(MemPAdrW));

  mux2 #(INDEXLEN)
  AdrSelMux(.d0(MemAdrE[INDEXLEN+OFFSET-1:OFFSET]),
	    .d1(MemPAdrM[INDEXLEN+OFFSET-1:OFFSET]),
	    .s(SelAdrM),
	    .y(AdrMuxOut));


  mux2 #(INDEXLEN)
  SelAdrlMux2(.d0(AdrMuxOut),
	      .d1(MemPAdrW[INDEXLEN+OFFSET-1:OFFSET]),
	      .s(SRAMWordWriteEnableW),
	      .y(SRAMAdr));
  

  genvar		       way;
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
	     .WriteTag(MemPAdrW[`PA_BITS-1:OFFSET+INDEXLEN]),
	     .SetValid(SetValidW),
	     .ClearValid(ClearValidW),
	     .SetDirty(SetDirtyW),
	     .ClearDirty(ClearDirtyW),
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
    else if (SRAMWriteEnable) ReplacementBits[MemPAdrW[INDEXLEN+OFFSET-1:OFFSET]] <= NewReplacement;
  end

  // *** TODO add replacement policy
  assign NewReplacement = '0;

  assign CacheHit = |WayHit;
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

  flopr #(3) Funct3WReg(.clk(clk),
			.reset(reset),
			.d(Funct3M),
			.q(Funct3W));

  subwordwrite subwordwrite(.HRDATA(ReadDataW),
			    .HADDRD(MemPAdrM[`XLEN/8-1:0]),
			    .HSIZED(Funct3W),
			    .HWDATAIN(WriteDataW),
			    .HWDATA(FinalWriteDataW));

  generate
    if (`A_SUPPORTED) begin
      logic [`XLEN-1:0] AMOResult;
      amoalu amoalu(.srca(ReadDataW), .srcb(WriteDataW), .funct(Funct7W), .width(Funct3W), 
                    .result(AMOResult));
      mux2 #(`XLEN) wdmux(FinalWriteDataW, AMOResult, SelAMOWrite & AtomicW[1], FinalAMOWriteDataW);
    end else
      assign FinalAMOWriteDataW = FinalWriteDataW;
  endgenerate
  

  // register the fetch data from the next level of memory.
  generate
    for (index = 0; index < WORDSPERLINE; index++) begin:fetchbuffer
      flopen #(`XLEN) fb(.clk(clk),
			 .en(AHBAck & (index == FetchCount)),
			 .d(HRDATA),
			 .q(DCacheMemWriteData[(index+1)*`XLEN-1:index*`XLEN]));
    end
  endgenerate

  flopenr #(LOGWPL+1) 
  FetchCountReg(.clk(clk),
		.reset(reset | CntReset),
		.en(CntEn),
		.d(NextFetchCount),
		.q(FetchCount));

  assign NextFetchCount = FetchCount + 1'b1;

  assign AHBPAdr = (FetchCount << (`XLEN/8)) + MemPAdrM;
  // remove later
  assign AHBSize = 3'b000;
  
  
  // mux between the CPU's write and the cache fetch.
  generate
    for(index = 0; index < WORDSPERLINE; index++) begin
      assign FinalWriteDataWordsW[((index+1)*`XLEN)-1 : (index*`XLEN)] = FinalAMOWriteDataW;
    end
  endgenerate

  mux2 #(BLOCKLEN) WriteDataMux(.d0(FinalWriteDataWordsW),
				.d1(DCacheMemWriteData),
				.s(SRAMBlockWriteEnableM),
				.y(SRAMWriteData));


  // control path *** eventually move to own module.

  logic AnyCPUReqM;
  logic FetchCountFlag;
  logic PreCntEn;
  logic CntEn;
  logic CntReset;
  
  
  typedef enum		       {STATE_READY,
				STATE_READ_MISS_FETCH_WDV,
				STATE_READ_MISS_FETCH_DONE,
				STATE_READ_MISS_CHECK_EVICTED_DIRTY,
				STATE_READ_MISS_WRITE_BACK_EVICTED_BLOCK,
				STATE_READ_MISS_WRITE_CACHE_BLOCK,
				STATE_READ_MISS_READ_WORD,
				STATE_WRITE_MISS_FETCH_WDV,
				STATE_WRITE_MISS_FETCH_DONE,
				STATE_WRITE_MISS_CHECK_EVICTED_DIRTY,
				STATE_WRITE_MISS_WRITE_BACK_EVICTED_BLOCK,
				STATE_WRITE_MISS_WRITE_CACHE_BLOCK,
				STATE_WRITE_MISS_WRITE_WORD,
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
				STATE_SRAM_BUSY,
				STATE_PTW_READY,
				STATE_PTW_MISS_FETCH_WDV,
				STATE_PTW_MISS_FETCH_DONE,
				STATE_PTW_MISS_CHECK_EVICTED_DIRTY,
				STATE_PTW_MISS_WRITE_BACK_EVICTED_BLOCK,
				STATE_PTW_MISS_WRITE_CACHE_BLOCK,
				STATE_PTW_MISS_READ_SRAM,
				STATE_UNCACHED_WDV,
				STATE_UNCACHED_DONE} statetype;

  statetype CurrState, NextState;

  
  localparam FetchCountThreshold = WORDSPERLINE - 1;
  

  assign AnyCPUReqM = |MemRWM | (|AtomicM);
  assign FetchCountFlag = (FetchCount == FetchCountThreshold);

  flopenr #(LOGWPL+1) 
  FetchCountReg(.clk(clk),
		.reset(reset | CntReset),
		.en(CntEn),
		.d(NextFetchCount),
		.q(FetchCount));

  assign NextFetchCount = FetchCount + 1'b1;

  assign SRAMWriteEnable = SRAMBlockWriteEnableM | SRAMWordWriteEnableW;

  flopr #(1+4+2)
  SRAMWritePipeReg(.clk(clk),
	      .reset(reset),
	      .d({SRAMWordWriteEnableM, SetValidM, ClearValidM, SetDiryM, ClearDirtyM, AtomicM}),
	      .q({SRAMWordWriteEnableW, SetValidW, ClearValidM, SetDiryM, ClearDirtyM, AtomicW}));
  

  // fsm state regs
  flopenl #(.TYPE(statetype))
  FSMReg(.clk(clk),
	 .load(reset),
	 .en(1'b1),
	 .val(STATE_READY),
	 .d(NextState),
	 .q(CurrState));

  // next state logic and some state ouputs.
  always_comb begin
    DCacheStall = 1'b0;
    SelAdrM = 2'b00;
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

    case (CurrState)
      STATE_READY: begin
	// sram busy
	if (AnyCPUReqM & SRAMWordWriteEnableW) begin
	  NextState = STATE_BUSY;
	  DCacheStall = 1'b1;
	end
	// TLB Miss	
	else if(AnyCPUReqM & DTLBMissM) begin                      
	  NextState = STATE_PTW_MISS_FETCH_WDV;
	end
	// amo hit
	else if(|AtomicM & ~UncachedM & ~FSMReg & CacheHit & ~DTLBMissM) begin
	  NextState = STATE_AMO_UPDATE;
	  DCacheStall = 1'b1;
	end
	// read hit valid cached
	else if(MemRWM[1] & ~UncachedM & ~FaultM & CacheHit & ~DTLBMissM) begin
	  NextState = STATE_READY;
	  DCacheStall = 1'b0;
	end
	// write hit valid cached
	else if (MemRWM[0] & ~UncachedM & ~FaultM & CacheHit & ~DTLBMissM) begin
	  NextState = STATE_READY;
	  DCacheStall = 1'b0;
	  SRAMWordWriteEnableM = 1'b1;
	  SetDirtyM = 1'b1;
	end
	// read miss valid cached
	else if(MemRWM[1] & ~UncachedM & ~FaultM & ~CacheHit & ~DTLBMissM) begin
	  NextState = STATE_READ_MISS_FETCH_WDV;
	  CntReset = 1'b1;
	  DCacheStall = 1'b1;
	end
	// fault
	else if(|MemRWM & FaultM & ~DTLBMissM) begin
	  NextState = STATE_READY;
	end
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

      STATE_READ_MISS_FETCH_WDV: begin
	DCacheStall = 1'b1;
        PreCntEn = 1'b1;
        if (FetchCountFlag & AHBAck) begin
          NextState = STATE_READ_MISS_FETCH_DONE;
        end else begin
          NextState = STATE_READ_MISS_FETCH_WDV;
        end
      end

      STATE_READ_MISS_FETCH_DONE: begin
	DCacheStall = 1'b1;
	NextState = STATE_READ_MISS_CHECK_EVICTED_DIRTY;
      end

      STATE_PTW_MISS_FETCH_WDV: begin
	DCacheStall = 1'b1;
	AdrSel = 2'b01;
	if (FetchCountFlag & AHBAck) begin
	  NextState = STATE_PTW_MISS_FETCH_DONE;
	end else begin
	  NextState = STATE_PTW_MISS_FETCH_WDV;
	end
      end
      default: begin
      end
    endcase
  end

  assign CntEn = PreCntEn & AHBAck;

endmodule; // dcache
