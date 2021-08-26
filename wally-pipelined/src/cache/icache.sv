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
   input logic 		       clk, reset,
   input logic 		       StallF, StallD,
   input logic 		       FlushD,
   input logic [`PA_BITS-1:0]  PCNextF,
   input logic [`PA_BITS-1:0]  PCPF, 
   // Data read in from the ebu unit
   input logic [`XLEN-1:0]     InstrInF,
   input logic 		       InstrAckF,
   // Read requested from the ebu unit
   output logic [`PA_BITS-1:0] InstrPAdrF,
   output logic 	       InstrReadF,
   // High if the instruction currently in the fetch stage is compressed
   output logic 	       CompressedF,
   // High if the icache is requesting a stall
   output logic 	       ICacheStallF,
   input logic 		       ITLBMissF,
   input logic 		       ITLBWriteF,
   input logic 		       WalkerInstrPageFaultF,
   
   // The raw (not decompressed) instruction that was requested
   // If this instruction is compressed, upper 16 bits may be the next 16 bits or may be zeros
   output logic [31:0] 	       FinalInstrRawF
   );

  // Configuration parameters
  localparam integer 	    BLOCKLEN = `ICACHE_BLOCKLENINBITS;
  localparam integer 	    NUMLINES = `ICACHE_WAYSIZEINBYTES*8/`ICACHE_BLOCKLENINBITS;
  localparam integer 	    BLOCKBYTELEN = BLOCKLEN/8;

  localparam integer 	    OFFSETLEN = $clog2(BLOCKBYTELEN);
  localparam integer 	    INDEXLEN = $clog2(NUMLINES);
  localparam integer 	    TAGLEN = `PA_BITS - OFFSETLEN - INDEXLEN;

  localparam WORDSPERLINE = BLOCKLEN/`XLEN;
  localparam LOGWPL = $clog2(WORDSPERLINE);

  localparam FetchCountThreshold = WORDSPERLINE - 1;
  localparam BlockByteLength = BLOCKLEN / 8;

  localparam OFFSETWIDTH = $clog2(BlockByteLength);

  localparam integer 	       PA_WIDTH = `PA_BITS - 2;

  // Input signals to cache memory
  logic 		    FlushMem;
  logic 		    ICacheMemWriteEnable;
  logic [BLOCKLEN-1:0] 	    ICacheMemWriteData;
  logic [`PA_BITS-1:0] 	    PCTagF, PCNextIndexF;  
  // Output signals from cache memory
  logic [31:0] 		    ICacheMemReadData;
  logic 		    ICacheMemReadValid;
  logic 		    ICacheReadEn;
  logic [BLOCKLEN-1:0] 	    ReadLineF;
  

  logic [15:0] 			 SpillDataBlock0;
  logic 			 spill;
  logic 			 spillSave;

  logic 			 FetchCountFlag;
  logic 			 CntEn;
  
  logic [1:0] 			 PCMux_q;
  
  
  logic [LOGWPL-1:0] 	       FetchCount, NextFetchCount;
 
  logic [`PA_BITS-1:0] 	       PCPreFinalF, PCPSpillF;
  logic [`PA_BITS-1:OFFSETWIDTH] PCPTrunkF;

  logic 		       CntReset;
  logic [1:0] 		       PCMux;
  logic 		       SavePC;
  

  // on spill we want to get the first 2 bytes of the next cache block.
  // the spill only occurs if the PCPF mod BlockByteLength == -2.  Therefore we can
  // simply add 2 to land on the next cache block.
  assign PCPSpillF = PCPF + {{{PA_WIDTH}{1'b0}}, 2'b10}; // *** modelsim does not allow the use of PA_BITS for literal width.

  // now we have to select between these three PCs
  assign PCPreFinalF = PCMux[0] | StallF ? PCPF : PCNextF; // *** don't like the stallf, but it is necessary
  // for the data cache i used a cpu busy state which is triggered by StallW.  In the case of the icache I
  // modified the select on this address mux. Both are not ideal; however the cpu_busy state is required for the
  // dcache as a write would repeatedly update the sram or worse for an uncached write multiple times.
  // I like reducing some complexity of the fsm; however I weight commonality between the i/d cache more.
  assign PCNextIndexF = PCMux[1] ? PCPSpillF : PCPreFinalF;

  cacheway #(.NUMLINES(NUMLINES), .BLOCKLEN(BLOCKLEN), .TAGLEN(TAGLEN), .OFFSETLEN(OFFSETLEN), .INDEXLEN(INDEXLEN),
	     .DIRTY_BITS(0))
  icachemem(.clk,
	    .reset,
	    .RAdr(PCNextIndexF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
	    .PAdr(PCTagF),
	    .WriteEnable(ICacheMemWriteEnable),
	    .WriteWordEnable('1),
	    .TagWriteEnable(ICacheMemWriteEnable),
	    .WriteData(ICacheMemWriteData),
	    .SetValid(ICacheMemWriteEnable),
	    .ClearValid(1'b0),
	    .SetDirty(1'b0),
	    .ClearDirty(1'b0),
	    .SelEvict(1'b0),
	    .VictimWay(1'b0),
	    .ReadDataBlockWayMasked(ReadLineF),
	    .WayHit(ICacheMemReadValid),
	    .VictimDirtyWay(),
	    .VictimTagWay()
	    );
  

  always_comb begin
    case (PCTagF[4:1])
      0: ICacheMemReadData = ReadLineF[31:0];
      1: ICacheMemReadData = ReadLineF[47:16];
      2: ICacheMemReadData = ReadLineF[63:32];
      3: ICacheMemReadData = ReadLineF[79:48];

      4: ICacheMemReadData = ReadLineF[95:64];
      5: ICacheMemReadData = ReadLineF[111:80];
      6: ICacheMemReadData = ReadLineF[127:96];
      7: ICacheMemReadData = ReadLineF[143:112];      

      8: ICacheMemReadData = ReadLineF[159:128];      
      9: ICacheMemReadData = ReadLineF[175:144];      
      10: ICacheMemReadData = ReadLineF[191:160];      
      11: ICacheMemReadData = ReadLineF[207:176];

      12: ICacheMemReadData = ReadLineF[223:192];
      13: ICacheMemReadData = ReadLineF[239:208];
      14: ICacheMemReadData = ReadLineF[255:224];
      15: ICacheMemReadData = {16'b0, ReadLineF[255:240]};
    endcase
  end

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
  

  assign spill = PCPF[4:1] == 4'b1111 ? 1'b1 : 1'b0;
  assign hit = ICacheMemReadValid; // note ICacheMemReadValid is hit.
  assign FetchCountFlag = (FetchCount == FetchCountThreshold[LOGWPL-1:0]);

  // to compute the fetch address we need to add the bit shifted
  // counter output to the address.

  flopenr #(LOGWPL) 
  FetchCountReg(.clk(clk),
		.reset(reset | CntReset),
		.en(CntEn),
		.d(NextFetchCount),
		.q(FetchCount));

  assign NextFetchCount = FetchCount + 1'b1;

  // This part is confusing.
  // *** Ross Thompson reduce the complexity. This is just dumb.
  // we need to remove the offset bits (PCPTrunkF).  Because the AHB interface is XLEN wide
  // we need to address on that number of bits so the PC is extended to the right by AHBByteLength with zeros.
  // fetch count is already aligned to AHBByteLength, but we need to extend back to the full address width with
  // more zeros after the addition.  This will be the number of offset bits less the AHBByteLength.
  logic [`PA_BITS-1:OFFSETWIDTH-LOGWPL] PCPTrunkExtF, InstrPAdrTrunkF ;

  assign PCPTrunkExtF = {PCPTrunkF, {{LOGWPL}{1'b0}}};
  // verilator lint_off WIDTH
  assign InstrPAdrTrunkF = PCPTrunkExtF + FetchCount;
  // verilator lint_on WIDTH
  
  //assign InstrPAdrF = {{PCPTrunkF, {{LOGWPL}{1'b0}}} + FetchCount, {{OFFSETWIDTH-LOGWPL}{1'b0}}};
  assign InstrPAdrF = {InstrPAdrTrunkF, {{OFFSETWIDTH-LOGWPL}{1'b0}}};
  


  // store read data from memory interface before writing into SRAM.
  genvar 				i;
  generate
    for (i = 0; i < WORDSPERLINE; i++) begin:storebuffer
      flopenr #(`XLEN) sb(.clk(clk),
			    .reset(reset), 
			    .en(InstrAckF & (i == FetchCount)),
			    .d(InstrInF),
			    .q(ICacheMemWriteData[(i+1)*`XLEN-1:i*`XLEN]));
    end
  endgenerate


  // this mux needs to be delayed 1 cycle as it occurs 1 pipeline stage later.
  // *** read enable may not be necessary.
  flopenr #(2) PCMuxReg(.clk(clk),
			.reset(reset),
			.en(ICacheReadEn),
			.d(PCMux),
			.q(PCMux_q));
  
  assign PCTagF = PCMux_q[1] ? PCPSpillF : PCPF;
  
  // truncate the offset from PCPF for memory address generation
  assign PCPTrunkF = PCTagF[`PA_BITS-1:OFFSETWIDTH];
  

  icachefsm #(.BLOCKLEN(BLOCKLEN)) 
  controller(.clk,
	     .reset,
	     .ICacheReadEn,
	     .ICacheMemWriteEnable,
	     .ICacheStallF,
	     .ITLBMissF,
	     .ITLBWriteF,
	     .WalkerInstrPageFaultF,
	     .InstrAckF,
	     .InstrReadF,
	     .hit(ICacheMemReadValid),
	     .FetchCountFlag,
	     .spill,
	     .spillSave,
	     .CntEn,
	     .CntReset,
	     .PCMux,
    	     .SavePC
	     );

  // For now, assume no writes to executable memory
  assign FlushMem = 1'b0;
endmodule

