///////////////////////////////////////////
// icache.sv
//
// Written: ross1728@gmail.com June 04, 2021
// Modified: 
//
// Purpose: I Cache controller
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

module ICacheCntrl #(parameter BLOCKLEN = 256) (
    // Inputs from pipeline
    input logic 		clk, reset,
    input logic 		StallF, StallD,
    input logic 		FlushD,

    // Input the address to read
    // The upper bits of the physical pc
    input logic [`PA_BITS-1:0] 	PCNextF,
    input logic [`PA_BITS-1:0] 	PCPF,
    // Signals to/from cache memory
    // The read coming out of it
    input logic [31:0] 		ICacheMemReadData,
    input logic 		ICacheMemReadValid,
    // The address at which we want to search the cache memory
    output logic [`PA_BITS-1:0] 	PCTagF,
    output logic [`PA_BITS-1:0]    PCNextIndexF,						     
    output logic 		ICacheReadEn,
    // Load data into the cache
    output logic 		ICacheMemWriteEnable,
    output logic [BLOCKLEN-1:0] ICacheMemWriteData,

    // Outputs to rest of ifu
    // High if the instruction in the fetch stage is compressed
    output logic 		CompressedF,
    // The instruction that was requested
    // If this instruction is compressed, upper 16 bits may be the next 16 bits or may be zeros
    output logic [31:0] 	InstrRawD,

    // Outputs to pipeline control stuff
    output logic 		ICacheStallF, EndFetchState,

    // Signals to/from ahblite interface
    // A read containing the requested data
    input logic [`XLEN-1:0] 	InstrInF,
    input logic 		InstrAckF,
    // The read we request from main memory
    output logic [`XLEN-1:0] 	InstrPAdrF,
    output logic 		InstrReadF
);

  // FSM states
  localparam STATE_READY = 0;
  localparam STATE_HIT_SPILL = 1; // spill, block 0 hit
  localparam STATE_HIT_SPILL_MISS_FETCH_WDV = 2; // block 1 miss, issue read to AHB and wait data.
  localparam STATE_HIT_SPILL_MISS_FETCH_DONE = 3; // write data into SRAM/LUT
  localparam STATE_HIT_SPILL_MERGE = 4;   // Read block 0 of CPU access, should be able to optimize into STATE_HIT_SPILL.

  // a challenge is the spill signal gets us out of the ready state and moves us to
  // 1 of the 2 spill branches.  However the original fsm design had us return to
  // the ready state when the spill + hits/misses were fully resolved.  The problem
  // is the spill signal is based on PCPF so when we return to READY to check if the
  // cache has a hit it still expresses spill.  We can fix in 1 of two ways.
  // 1. we can add 1 extra state at the end of each spill branch to returns the instruction
  // to the CPU advancing the CPU and icache to the next instruction.
  // 2. We can assert a signal which is delayed 1 cycle to suppress the spill when we get
  // to the READY state.
  // The first first option is more robust and increases the number of states by 2.  The
  // second option is seams like it should work, but I worry there is a hidden interaction 
  // between CPU stalling and that register.
  // Picking option 1.

  localparam STATE_HIT_SPILL_FINAL = 5; // this state replicates STATE_READY's replay of the
  // spill access but does nto consider spill.  It also does not do another operation.
  

  localparam STATE_MISS_FETCH_WDV = 6; // aligned miss, issue read to AHB and wait for data.
  localparam STATE_MISS_FETCH_DONE = 7; // write data into SRAM/LUT
  localparam STATE_MISS_READ = 8; // read block 1 from SRAM/LUT  

  localparam STATE_MISS_SPILL_FETCH_WDV = 9; // spill, miss on block 0, issue read to AHB and wait
  localparam STATE_MISS_SPILL_FETCH_DONE = 10; // write data into SRAM/LUT
  localparam STATE_MISS_SPILL_READ1 = 11; // read block 0 from SRAM/LUT
  localparam STATE_MISS_SPILL_2 = 12; // return to ready if hit or do second block update.
  localparam STATE_MISS_SPILL_2_START = 13; // return to ready if hit or do second block update.  
  localparam STATE_MISS_SPILL_MISS_FETCH_WDV = 14; // miss on block 1, issue read to AHB and wait
  localparam STATE_MISS_SPILL_MISS_FETCH_DONE = 15; // write data to SRAM/LUT
  localparam STATE_MISS_SPILL_MERGE = 16; // read block 0 of CPU access,

  localparam STATE_MISS_SPILL_FINAL = 17; // this state replicates STATE_READY's replay of the
  // spill access but does nto consider spill.  It also does not do another operation.
  

  localparam STATE_INVALIDATE = 18; // *** not sure if invalidate or evict? invalidate by cache block or address?
  
  localparam AHBByteLength = `XLEN / 8;
  localparam AHBOFFETWIDTH = $clog2(AHBByteLength);
  
  
  localparam BlockByteLength = BLOCKLEN / 8;
  localparam OFFSETWIDTH = $clog2(BlockByteLength);
  
  localparam WORDSPERLINE = BLOCKLEN/`XLEN;
  localparam LOGWPL = $clog2(WORDSPERLINE);

  logic [4:0] 		     CurrState, NextState;
  logic 		     hit, spill;
  logic 		     SavePC;
  logic [1:0] 		     PCMux;
  logic 		     CntReset;
  logic 		     PreCntEn, CntEn;
  logic 		     spillSave;
  logic 		     UnalignedSelect;
  logic 		     FetchCountFlag;
  localparam FetchCountThreshold = WORDSPERLINE - 1;
  
  logic [LOGWPL:0] 	     FetchCount, NextFetchCount;

  logic [`PA_BITS-1:0] 	     PCPreFinalF, PCPFinalF, PCSpillF;
  logic [`PA_BITS-1:OFFSETWIDTH] PCPTrunkF;

  
  logic [31:0] 		     FinalInstrRawF;

  logic [15:0] 		     SpillDataBlock0;
  
  localparam [31:0]  	     NOP = 32'h13;

  logic 		     reset_q;
  logic [1:0] 		     PCMux_q;
  
  
    // Misaligned signals
    //logic [`XLEN:0] MisalignedInstrRawF;
    //logic           MisalignedStall;
    // Cache fault signals
    //logic           FaultStall;
  
  // on spill we want to get the first 2 bytes of the next cache block.
  // the spill only occurs if the PCPF mod BlockByteLength == -2.  Therefore we can
  // simply add 2 to land on the next cache block.
  assign PCSpillF = PCPF + `XLEN'b10;

  // now we have to select between these three PCs
  assign PCPreFinalF = PCMux[0] | StallF ? PCPF : PCNextF; // *** don't like the stallf, but it is necessary
  assign PCPFinalF = PCMux[1] ? PCSpillF : PCPreFinalF;

  // this mux needs to be delayed 1 cycle as it occurs 1 pipeline stage later.
  // *** read enable may not be necessary.
  flopenr #(2) PCMuxReg(.clk(clk),
			.reset(reset),
			.en(ICacheReadEn),
			.d(PCMux),
			.q(PCMux_q));
  
  assign PCTagF = PCMux_q[1] ? PCSpillF : PCPF;
  assign PCNextIndexF = PCPFinalF;
  
  // truncate the offset from PCPF for memory address generation
  assign PCPTrunkF = PCTagF[`PA_BITS-1:OFFSETWIDTH];
  
    // Detect if the instruction is compressed
  assign CompressedF = FinalInstrRawF[1:0] != 2'b11;


  // the FSM is always runing, do not stall.
  flopr #(5) stateReg(.clk(clk),
		      .reset(reset),
		      .d(NextState),
		      .q(CurrState));

  assign spill = PCPF[4:1] == 4'b1111 ? 1'b1 : 1'b0;
  assign hit = ICacheMemReadValid; // note ICacheMemReadValid is hit.
  // verilator lint_off WIDTH
  assign FetchCountFlag = (FetchCount == FetchCountThreshold);
  // verilator lint_on WIDTH
  
  // Next state logic
  always_comb begin
    UnalignedSelect = 1'b0;
    CntReset = 1'b0;
    PreCntEn = 1'b0;
    //InstrReadF = 1'b0;
    ICacheMemWriteEnable = 1'b0;
    spillSave = 1'b0;
    PCMux = 2'b00;
    ICacheReadEn = 1'b0;
    SavePC = 1'b0;
    ICacheStallF = 1'b1;
    
    case (CurrState)
      
      STATE_READY: begin
	PCMux = 2'b00;
	ICacheReadEn = 1'b1;
	if (hit & ~spill) begin
	  SavePC = 1'b1;
	  ICacheStallF = 1'b0;
	  NextState = STATE_READY;
	end else if (hit & spill) begin
	  spillSave = 1'b1;
	  PCMux = 2'b10;
	  NextState = STATE_HIT_SPILL;
	end else if (~hit & ~spill) begin
	  CntReset = 1'b1;
	  NextState = STATE_MISS_FETCH_WDV;
	end else if (~hit & spill) begin
	  CntReset = 1'b1;
	  PCMux = 2'b01;
	  NextState = STATE_MISS_SPILL_FETCH_WDV;
	end else begin
          NextState = STATE_READY;
	end
      end

      // branch 1,  hit spill and 2, miss spill hit
      STATE_HIT_SPILL: begin
	PCMux = 2'b10;
	UnalignedSelect = 1'b1;
	ICacheReadEn = 1'b1;
	if (hit) begin
          NextState = STATE_HIT_SPILL_FINAL;
	end else begin
	  CntReset = 1'b1;
          NextState = STATE_HIT_SPILL_MISS_FETCH_WDV;
	end
      end
      STATE_HIT_SPILL_MISS_FETCH_WDV: begin
	PCMux = 2'b10;
	//InstrReadF = 1'b1;
	PreCntEn = 1'b1;
	if (FetchCountFlag & InstrAckF) begin
	  NextState = STATE_HIT_SPILL_MISS_FETCH_DONE;
	end else begin
	  NextState = STATE_HIT_SPILL_MISS_FETCH_WDV;
	end
      end
      STATE_HIT_SPILL_MISS_FETCH_DONE: begin
	PCMux = 2'b10;
	ICacheMemWriteEnable = 1'b1;
        NextState = STATE_HIT_SPILL_MERGE;
      end
      STATE_HIT_SPILL_MERGE: begin
	PCMux = 2'b10;
	UnalignedSelect = 1'b1;
	ICacheReadEn = 1'b1;
        NextState = STATE_HIT_SPILL_FINAL;
      end
      STATE_HIT_SPILL_FINAL: begin
	ICacheReadEn = 1'b1;
	PCMux = 2'b00;
	UnalignedSelect = 1'b1;
	SavePC = 1'b1;
	NextState = STATE_READY;
	ICacheStallF = 1'b0;	
      end

      // branch 3 miss no spill
      STATE_MISS_FETCH_WDV: begin
	PCMux = 2'b01;
	//InstrReadF = 1'b1;
	PreCntEn = 1'b1;
	if (FetchCountFlag & InstrAckF) begin
	  NextState = STATE_MISS_FETCH_DONE;	  
	end else begin
	  NextState = STATE_MISS_FETCH_WDV;
	end
      end
      STATE_MISS_FETCH_DONE: begin
	PCMux = 2'b01;
	ICacheMemWriteEnable = 1'b1;
        NextState = STATE_MISS_READ;
      end
      STATE_MISS_READ: begin
	PCMux = 2'b01;
	ICacheReadEn = 1'b1;
	NextState = STATE_READY;
      end

      // branch 4 miss spill hit, and 5 miss spill miss
      STATE_MISS_SPILL_FETCH_WDV: begin
	PCMux = 2'b01;
	PreCntEn = 1'b1;
	//InstrReadF = 1'b1;	
	if (FetchCountFlag & InstrAckF) begin 
	  NextState = STATE_MISS_SPILL_FETCH_DONE;
	end else begin
	  NextState = STATE_MISS_SPILL_FETCH_WDV;
	end
      end
      STATE_MISS_SPILL_FETCH_DONE: begin
	PCMux = 2'b01;	
	ICacheMemWriteEnable = 1'b1;
	NextState = STATE_MISS_SPILL_READ1;
      end
      STATE_MISS_SPILL_READ1: begin // always be a hit as we just wrote that cache block.
	PCMux = 2'b01;	 // there is a 1 cycle delay after setting the address before the date arrives.
	ICacheReadEn = 1'b1;	
	NextState = STATE_MISS_SPILL_2;
      end
      STATE_MISS_SPILL_2: begin
	PCMux = 2'b10;
	UnalignedSelect = 1'b1;
	spillSave = 1'b1; /// *** Could pipeline these to make it clearer in the fsm.
	ICacheReadEn = 1'b1;
	NextState = STATE_MISS_SPILL_2_START;
      end
      STATE_MISS_SPILL_2_START: begin
	if (~hit) begin
	  CntReset = 1'b1;
	  NextState = STATE_MISS_SPILL_MISS_FETCH_WDV;
	end else begin
	  NextState = STATE_READY;
	  ICacheReadEn = 1'b1;
	  PCMux = 2'b00;
	  UnalignedSelect = 1'b1;
	  SavePC = 1'b1;
	  ICacheStallF = 1'b0;	
	end
      end
      STATE_MISS_SPILL_MISS_FETCH_WDV: begin
	PCMux = 2'b10;
	PreCntEn = 1'b1;
	//InstrReadF = 1'b1;	
	if (FetchCountFlag & InstrAckF) begin
	  NextState = STATE_MISS_SPILL_MISS_FETCH_DONE;	  
	end else begin
	  NextState = STATE_MISS_SPILL_MISS_FETCH_WDV;
	end
      end
      STATE_MISS_SPILL_MISS_FETCH_DONE: begin
	PCMux = 2'b10;
	ICacheMemWriteEnable = 1'b1;
	NextState = STATE_MISS_SPILL_MERGE;
      end
      STATE_MISS_SPILL_MERGE: begin
	PCMux = 2'b10;
	UnalignedSelect = 1'b1;
	ICacheReadEn = 1'b1;	
        NextState = STATE_MISS_SPILL_FINAL;
      end
      STATE_MISS_SPILL_FINAL: begin
	ICacheReadEn = 1'b1;
	PCMux = 2'b00;
	UnalignedSelect = 1'b1;
	SavePC = 1'b1;
	ICacheStallF = 1'b0;	
	NextState = STATE_READY;
      end
      default: begin
	PCMux = 2'b01;
	NextState = STATE_READY;
      end
      // *** add in error handling and invalidate/evict
    endcase
  end

  assign CntEn = PreCntEn & InstrAckF;
  assign InstrReadF = (CurrState == STATE_HIT_SPILL_MISS_FETCH_WDV) ||
		      (CurrState == STATE_MISS_FETCH_WDV) ||
		      (CurrState == STATE_MISS_SPILL_FETCH_WDV) ||
		      (CurrState == STATE_MISS_SPILL_MISS_FETCH_WDV);

  // to compute the fetch address we need to add the bit shifted
  // counter output to the address.

  flopenr #(LOGWPL+1) 
  FetchCountReg(.clk(clk),
		.reset(reset | CntReset),
		.en(CntEn),
		.d(NextFetchCount),
		.q(FetchCount));

  assign NextFetchCount = FetchCount + 1'b1;
  
  // This part is confusing.
  // we need to remove the offset bits (PCPTrunkF).  Because the AHB interface is XLEN wide
  // we need to address on that number of bits so the PC is extended to the right by AHBByteLength with zeros.
  // fetch count is already aligned to AHBByteLength, but we need to extend back to the full address width with
  // more zeros after the addition.  This will be the number of offset bits less the AHBByteLength.
  logic [`XLEN-1:OFFSETWIDTH-LOGWPL] PCPTrunkExtF, InstrPAdrTrunkF ;

  assign PCPTrunkExtF = {PCPTrunkF, {{LOGWPL}{1'b0}}};
  // verilator lint_off WIDTH
  assign InstrPAdrTrunkF = PCPTrunkExtF + FetchCount;
  // verilator lint_on WIDTH
  
  //assign InstrPAdrF = {{PCPTrunkF, {{LOGWPL}{1'b0}}} + FetchCount, {{OFFSETWIDTH-LOGWPL}{1'b0}}};
  assign InstrPAdrF = {InstrPAdrTrunkF, {{OFFSETWIDTH-LOGWPL}{1'b0}}};
  


  // store read data from memory interface before writing into SRAM.
  genvar i;
  generate
    for (i = 0; i < WORDSPERLINE; i++) begin
      flopenr #(`XLEN) flop(.clk(clk),
			    .reset(reset), 
			    .en(InstrAckF & (i == FetchCount)),
			    .d(InstrInF),
			    .q(ICacheMemWriteData[(i+1)*`XLEN-1:i*`XLEN]));
    end
  endgenerate

  // what address is used to write the SRAM?
  

  // spills require storing the first cache block so it can merged
  // with the second
  // can optimize size, for now just make it the size of the data
  // leaving the cache memory. 
  flopenr #(16) SpillInstrReg(.clk(clk),
			      .en(spillSave),
			      .reset(reset),
			      .d(ICacheMemReadData[15:0]),
			      .q(SpillDataBlock0));

  // use the not quite final PC to do the final selection.
  logic [1:1] PCPreFinalF_q;
  flopenr #(1) PCFReg(.clk(clk),
		      .reset(reset),
		      .en(~StallF),
		      .d(PCPreFinalF[1]),
		      .q(PCPreFinalF_q[1]));
  assign FinalInstrRawF = spill ? {ICacheMemReadData[15:0], SpillDataBlock0} : ICacheMemReadData;

  // There is a frustrating issue on the first access.
  // The cache will not contain any valid data but will contain x's on
  // reset. This makes FinalInstrRawF invalid.  On the first cycle out of
  // reset this register will pickup this x and it will propagate throughout
  // the cpu causing simulation failure, most likely a trap for invalid instruction.
  // Reset must be held 1 cycle longer to prevent this issue. additionally the
  // reset should be to a NOP rather than 0.

  // register reset
  flop #(1) resetReg (.clk(clk),
		      .d(reset),
		      .q(reset_q));
  
  flopenl #(32) AlignedInstrRawDFlop(clk, reset | reset_q, ~StallD, FlushD ? NOP : FinalInstrRawF, NOP, InstrRawD);
  
endmodule
