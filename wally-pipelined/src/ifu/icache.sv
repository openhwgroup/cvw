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

module icache(
  // Basic pipeline stuff
  input  logic              clk, reset,
  input  logic              StallF, StallD,
  input  logic              FlushD,
  // Upper bits of physical address for PC
  input  logic [`XLEN-1:12] UpperPCNextPF,
  // Lower 12 bits of virtual PC address, since it's faster this way
  input  logic [11:0]       LowerPCNextF,
  // Data read in from the ebu unit
  input  logic [`XLEN-1:0]  InstrInF,
  input  logic              InstrAckF,
  // Read requested from the ebu unit
  output logic [`XLEN-1:0]  InstrPAdrF,
  output logic              InstrReadF,
  // High if the instruction currently in the fetch stage is compressed
  output logic              CompressedF,
  // High if the icache is requesting a stall
  output logic              ICacheStallF,
  // The raw (not decompressed) instruction that was requested
  // If this instruction is compressed, upper 16 bits may be the next 16 bits or may be zeros
  output logic [31:0]       InstrRawD
);

    // Configuration parameters
    // TODO Move these to a config file
    localparam integer ICACHELINESIZE = 256;
    localparam integer ICACHENUMLINES = 512;

    // Input signals to cache memory
    logic                       FlushMem;
    logic [`XLEN-1:12]          ICacheMemReadUpperPAdr;
    logic [11:0]                ICacheMemReadLowerAdr;
    logic                       ICacheMemWriteEnable;
    logic [ICACHELINESIZE-1:0]  ICacheMemWriteData;
    logic [`XLEN-1:0]           ICacheMemWritePAdr;
    logic                       EndFetchState;
    // Output signals from cache memory
    logic [`XLEN-1:0]   ICacheMemReadData;
    logic               ICacheMemReadValid;
  logic 		ICacheReadEn;
  

  rodirectmappedmemre #(.LINESIZE(ICACHELINESIZE), .NUMLINES(ICACHENUMLINES), .WORDSIZE(`XLEN)) 
  cachemem(
        .*,
        // Stall it if the pipeline is stalled, unless we're stalling it and we're ending our stall
        .re(ICacheReadEn),
        .flush(FlushMem),
        .ReadUpperPAdr(ICacheMemReadUpperPAdr),
        .ReadLowerAdr(ICacheMemReadLowerAdr),
        .WriteEnable(ICacheMemWriteEnable),
        .WriteLine(ICacheMemWriteData),
        .WritePAdr(ICacheMemWritePAdr),
        .DataWord(ICacheMemReadData),
        .DataValid(ICacheMemReadValid)
    );

    icachecontroller #(.LINESIZE(ICACHELINESIZE)) controller(.*);

    // For now, assume no writes to executable memory
    assign FlushMem = 1'b0;
endmodule

module icachecontroller #(parameter LINESIZE = 256) (
    // Inputs from pipeline
    input logic 		clk, reset,
    input logic 		StallF, StallD,
    input logic 		FlushD,

    // Input the address to read
    // The upper bits of the physical pc
    input logic [`XLEN-1:12] 	UpperPCNextPF,
    // The lower bits of the virtual pc
    input logic [11:0] 		LowerPCNextF,

    // Signals to/from cache memory
    // The read coming out of it
    input logic [`XLEN-1:0] 	ICacheMemReadData,
    input logic 		ICacheMemReadValid,
    // The address at which we want to search the cache memory
    output logic [`XLEN-1:12] 	ICacheMemReadUpperPAdr,
    output logic [11:0] 	ICacheMemReadLowerAdr,
    output logic                ICacheReadEn,
    // Load data into the cache
    output logic 		ICacheMemWriteEnable,
    output logic [LINESIZE-1:0] ICacheMemWriteData,
    output logic [`XLEN-1:0] 	ICacheMemWritePAdr,

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

  localparam STATE_MISS_FETCH_WDV = 5; // aligned miss, issue read to AHB and wait for data.
  localparam STATE_MISS_FETCH_DONE = 6; // write data into SRAM/LUT
  localparam STATE_MISS_READ = 7; // read block 1 from SRAM/LUT  

  localparam STATE_MISS_SPILL_FETCH_WDV = 8; // spill, miss on block 0, issue read to AHB and wait
  localparam STATE_MISS_SPILL_FETCH_DONE = 9; // write data into SRAM/LUT
  localparam STATE_MISS_SPILL_READ1 = 10; // read block 0 from SRAM/LUT
  localparam STATE_MISS_SPILL_2 = 11; // return to ready if hit or do second block update.
  localparam STATE_MISS_SPILL_MISS_FETCH_WDV = 12; // miss on block 1, issue read to AHB and wait
  localparam STATE_MISS_SPILL_MISS_FETCH_DONE = 13; // write data to SRAM/LUT
  localparam STATE_MISS_SPILL_MERGE = 14; // read block 0 of CPU access,

  localparam STATE_INVALIDATE = 15; // *** not sure if invalidate or evict? invalidate by cache block or address?
  
  localparam AHBByteLength = `XLEN / 8;
  localparam AHBOFFETWIDTH = $clog2(AHBByteLength);
  
  
  localparam BlockByteLength = LINESIZE / 8;
  localparam OFFSETWIDTH = $clog2(BlockByteLength);
  
  localparam WORDSPERLINE = LINESIZE/`XLEN;
  localparam LOGWPL = $clog2(WORDSPERLINE);

  logic [3:0] 		     CurrState, NextState;
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

  logic [`XLEN-1:0] 	     PCPreFinalF, PCPFinalF, PCSpillF, PCNextPF;
  logic [`XLEN-1:OFFSETWIDTH] PCPTrunkF;

  
  logic [31:0] 		     FinalInstrRawF;

  logic [15:0] 		     SpillDataBlock0;



    // Happy path signals
  logic [31:0] 		     AlignedInstrRawD;
  
    //logic [31:0]    AlignedInstrRawF, AlignedInstrRawD;
    //logic           FlushDLastCycleN;
    //logic           PCPMisalignedF;
  const logic [31:0] 	     NOP = 32'h13;
  logic [`XLEN-1:0] 	     PCPF;

  logic 		     reset_q;
  
    // Misaligned signals
    //logic [`XLEN:0] MisalignedInstrRawF;
    //logic           MisalignedStall;
    // Cache fault signals
    //logic           FaultStall;

  assign PCNextPF = {UpperPCNextPF, LowerPCNextF};
  
  flopenl #(`XLEN) PCPFFlop(clk, reset, SavePC & ~StallF, PCPFinalF, `RESET_VECTOR, PCPF);
  // on spill we want to get the first 2 bytes of the next cache block.
  // the spill only occurs if the PCPF mod BlockByteLength == -2.  Therefore we can
  // simply add 2 to land on the next cache block.
  assign PCSpillF = PCPF + 2'b10;

  // now we have to select between these three PCs
  assign PCPreFinalF = PCMux[0] | StallF ? PCPF : PCNextPF; // *** don't like the stallf 
  assign PCPFinalF = PCMux[1] ? PCSpillF : PCPreFinalF;
  
  
  
  // truncate the offset from PCPF for memory address generation
  assign PCPTrunkF = PCPFinalF[`XLEN-1:OFFSETWIDTH];
  
    // Detect if the instruction is compressed
  assign CompressedF = FinalInstrRawF[1:0] != 2'b11;


    // Handle happy path (data in cache, reads aligned)
/* -----\/----- EXCLUDED -----\/-----

    generate
        if (`XLEN == 32) begin
            assign AlignedInstrRawF = PCPF[1] ? MisalignedInstrRawF : ICacheMemReadData;
            //assign PCPMisalignedF = PCPF[1] && ~CompressedF;
        end else begin
            assign AlignedInstrRawF = PCPF[2]
                ? (PCPF[1] ? MisalignedInstrRawF : ICacheMemReadData[63:32])
                : (PCPF[1] ? ICacheMemReadData[47:16] : ICacheMemReadData[31:0]);
            //assign PCPMisalignedF = PCPF[2] && PCPF[1] && ~CompressedF;
        end
    endgenerate
 -----/\----- EXCLUDED -----/\----- */

    //flopenr #(32) AlignedInstrRawDFlop(clk, reset, ~StallD, AlignedInstrRawF, AlignedInstrRawD);
    //flopr   #(1)  FlushDLastCycleFlop(clk, reset, ~FlushD & (FlushDLastCycleN | ~StallF), FlushDLastCycleN);

    //mux2    #(32) InstrRawDMux(AlignedInstrRawD, NOP, ~FlushDLastCycleN, InstrRawD);

    // Stall for faults or misaligned reads
/* -----\/----- EXCLUDED -----\/-----
    always_comb begin
        assign ICacheStallF = FaultStall | MisalignedStall;
    end
 -----/\----- EXCLUDED -----/\----- */


    // Handle misaligned, noncompressed reads

/* -----\/----- EXCLUDED -----\/-----
    logic           MisalignedState, NextMisalignedState;
    logic [15:0]    MisalignedHalfInstrF;
    logic [15:0]    UpperHalfWord;
 -----/\----- EXCLUDED -----/\----- */

/* -----\/----- EXCLUDED -----\/-----
    flopenr #(16) MisalignedHalfInstrFlop(clk, reset, ~FaultStall & (PCPMisalignedF & MisalignedState), AlignedInstrRawF[15:0], MisalignedHalfInstrF);
    flopenr #(1)  MisalignedStateFlop(clk, reset, ~FaultStall, NextMisalignedState, MisalignedState);
 -----/\----- EXCLUDED -----/\----- */

    // When doing a misaligned read, swizzle the bits correctly
/* -----\/----- EXCLUDED -----\/-----
    generate
        if (`XLEN == 32) begin
            assign UpperHalfWord = ICacheMemReadData[31:16];
        end else begin
            assign UpperHalfWord = ICacheMemReadData[63:48];
        end
    endgenerate
    always_comb begin
        if (MisalignedState) begin
            assign MisalignedInstrRawF = {16'b0, UpperHalfWord};
        end else begin
            assign MisalignedInstrRawF = {ICacheMemReadData[15:0], MisalignedHalfInstrF};
        end
    end
 -----/\----- EXCLUDED -----/\----- */

    // Manage internal state and stall when necessary
/* -----\/----- EXCLUDED -----\/-----
    always_comb begin
        assign MisalignedStall = PCPMisalignedF & MisalignedState;
        assign NextMisalignedState = ~PCPMisalignedF | ~MisalignedState;
    end
 -----/\----- EXCLUDED -----/\----- */

    // Pick the correct address to read
/* -----\/----- EXCLUDED -----\/-----
    generate
        if (`XLEN == 32) begin
            assign ICacheMemReadLowerAdr = {LowerPCNextF[11:2] + (PCPMisalignedF & ~MisalignedState), 2'b00};
        end else begin
            assign ICacheMemReadLowerAdr = {LowerPCNextF[11:3] + (PCPMisalignedF & ~MisalignedState), 3'b00};
        end
    endgenerate
 -----/\----- EXCLUDED -----/\----- */
    // TODO Handle reading instructions that cross page boundaries
    //assign ICacheMemReadUpperPAdr = UpperPCNextPF;


    // Handle cache faults


/* -----\/----- EXCLUDED -----\/-----
    logic               FetchState, BeginFetchState;
    logic [LOGWPL:0]    FetchWordNum, NextFetchWordNum;
    logic [`XLEN-1:0]   LineAlignedPCPF;

    flopr #(1) FetchStateFlop(clk, reset, BeginFetchState | (FetchState & ~EndFetchState), FetchState);
    flopr #(LOGWPL+1) FetchWordNumFlop(clk, reset, NextFetchWordNum, FetchWordNum);


    // Enter the fetch state when we hit a cache fault
    always_comb begin
        BeginFetchState = ~ICacheMemReadValid & ~FetchState & (FetchWordNum == 0);
    end
    // Exit the fetch state once the cache line has been loaded
    flopr #(1) EndFetchStateFlop(clk, reset, ICacheMemWriteEnable, EndFetchState);

    // Machinery to request the correct addresses from main memory
    always_comb begin
        InstrReadF = FetchState & ~EndFetchState & ~ICacheMemWriteEnable; // next stage logic
        LineAlignedPCPF = {ICacheMemReadUpperPAdr, ICacheMemReadLowerAdr[11:OFFSETWIDTH], {OFFSETWIDTH{1'b0}}}; // the fetch address for abh?
        InstrPAdrF = LineAlignedPCPF + FetchWordNum*(`XLEN/8); // ?
        NextFetchWordNum = FetchState ? FetchWordNum+InstrAckF : {LOGWPL+1{1'b0}}; // convert to enable
    end

    // Write to cache memory when we have the line here
    always_comb begin
        ICacheMemWritePAdr = LineAlignedPCPF;
        ICacheMemWriteEnable = FetchWordNum == {1'b1, {LOGWPL{1'b0}}} & FetchState & ~EndFetchState;
    end

    // Stall the pipeline while loading a new line from memory
    always_comb begin
        FaultStall = FetchState | ~ICacheMemReadValid;
    end
 -----/\----- EXCLUDED -----/\----- */

  // the FSM is always runing, do not stall.
  flopr #(4) stateReg(.clk(clk),
		      .reset(reset),
		      .d(NextState),
		      .q(CurrState));

  assign spill = PCPF[5:1] == 5'b1_1111 ? 1'b1 : 1'b0;
  assign hit = ICacheMemReadValid; // note ICacheMemReadValid is hit.
  assign FetchCountFlag = FetchCount == FetchCountThreshold;
  
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
    
    case (CurrState)
      
      STATE_READY: begin
	PCMux = 2'b00;
	ICacheReadEn = 1'b1;
	if (hit & ~spill) begin
	  NextState = STATE_READY;
	end else if (hit & spill) begin
	  spillSave = 1'b1;
	  NextState = STATE_HIT_SPILL;
	end else if (~hit & ~spill) begin
	  CntReset = 1'b1;
	  NextState = STATE_MISS_FETCH_WDV;
	end else if (~hit & spill)	begin
	  CntReset = 1'b1;
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
          NextState = STATE_READY;
	end else
	  CntReset = 1'b1;
          NextState = STATE_HIT_SPILL_MISS_FETCH_WDV;
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
        NextState = STATE_READY;
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
	PCMux = 2'b10;	 // there is a 1 cycle delay after setting the address before the date arrives.
	spillSave = 1'b1; /// *** Could pipeline these to make it clearer in the fsm.
	ICacheReadEn = 1'b1;	
	NextState = STATE_MISS_SPILL_2;
      end
      STATE_MISS_SPILL_2: begin
	PCMux = 2'b10;
	UnalignedSelect = 1'b1;	
	if (~hit) begin
	  CntReset = 1'b1;
	  NextState = STATE_MISS_SPILL_MISS_FETCH_WDV;
	end else begin
	  NextState = STATE_READY;
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
        NextState = STATE_READY;
      end
      default: begin
	PCMux = 2'b01;
	NextState = STATE_READY;
      end
      // *** add in error handling and invalidate/evict
    endcase
  end

  // fsm outputs
  // stall CPU any time we are not in the ready state.  any other state means the
  // cache is either requesting data from the memory interface or handling a
  // spill over two cycles.
  assign ICacheStallF = ((CurrState != STATE_READY) | ~hit) | reset_q ? 1'b1 : 1'b0;
  // save the PC anytime we are in the ready state. The saved value will be used as the PC may not be stable.
  assign SavePC = (CurrState == STATE_READY) & hit ? 1'b1 : 1'b0;
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
  // *** now a bug need to mux between PCPF and PCPF+2
  assign InstrPAdrF = {{PCPTrunkF, {{LOGWPL}{1'b0}}} + FetchCount, {{OFFSETWIDTH-LOGWPL}{1'b0}}};


  // store read data from memory interface before writing into SRAM.
  genvar i;
  generate
    for (i = 0; i < AHBByteLength; i++) begin
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
  generate
    if( `XLEN == 32) begin
      logic [1:1] PCPreFinalF_q;
      flopenr #(1) PCFReg(.clk(clk),
			  .reset(reset),
			  .en(~StallF),
			  .d(PCPreFinalF[1]),
			  .q(PCPreFinalF_q[1]));
      assign FinalInstrRawF = PCPreFinalF_q[1] ? {SpillDataBlock0, ICacheMemReadData[31:16]} : ICacheMemReadData;
    end else begin
      logic [2:1] PCPreFinalF_q;
      flopenr #(2) PCFReg(.clk(clk),
			  .reset(reset),
			  .en(~StallF),
			  .d(PCPreFinalF[2:1]),
			  .q(PCPreFinalF_q[2:1]));
      mux4 #(32) AlignmentMux(.d0(ICacheMemReadData[31:0]),
			      .d1(ICacheMemReadData[47:16]),
			      .d2(ICacheMemReadData[63:32]),
			      .d3({SpillDataBlock0, ICacheMemReadData[63:48]}),
			      .s(PCPreFinalF_q[2:1]),
			      .y(FinalInstrRawF));
    end
  endgenerate

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
  
  flopenl #(32) AlignedInstrRawDFlop(clk, reset | reset_q, ~StallD, FinalInstrRawF, NOP, AlignedInstrRawD);
  // cannot have this mux as it creates a combo loop. 
    // This flop doesn't stall if StallF is high because we should output a nop
    // when FlushD happens, even if the pipeline is also stalled.
    flopr   #(1)  flushDLastCycleFlop(clk, reset, ~FlushD & (FlushDLastCyclen | ~StallF), FlushDLastCyclen);
  mux2    #(32) InstrRawDMux(AlignedInstrRawD, NOP, ~FlushDLastCyclen, InstrRawD);
  //assign InstrRawD = AlignedInstrRawD;
  
  
  assign {ICacheMemReadUpperPAdr, ICacheMemReadLowerAdr} = PCPFinalF;

  assign ICacheMemWritePAdr = PCPFinalF;

  
  
endmodule
