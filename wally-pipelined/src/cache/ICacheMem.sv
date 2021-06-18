`include "wally-config.vh"

module ICacheMem #(parameter NUMLINES=512, parameter BLOCKLEN = 256) 
  (
   // Pipeline stuff
   input logic 		       clk,
   input logic 		       reset,
   // If flush is high, invalidate the entire cache
   input logic 		       flush,

   input logic [`PA_BITS-1:0]     PCTagF,        // physical address
   input logic [`PA_BITS-1:0]     PCNextIndexF,  // virtual address
   input logic 		       WriteEnable,
   input logic [BLOCKLEN-1:0]  WriteLine,
   output logic [BLOCKLEN-1:0] ReadLineF,
   output logic 	       HitF
   );

  // divide the address bus into sections; tag, index, and offset
  localparam BLOCKBYTELEN = BLOCKLEN/8;
  localparam OFFSETLEN = $clog2(BLOCKBYTELEN);
  localparam INDEXLEN = $clog2(NUMLINES);
  // *** BUG. `XLEN needs to be replaced with the virtual address width, S32, S39, or S48
  localparam TAGLEN = `PA_BITS - OFFSETLEN - INDEXLEN;

  logic [TAGLEN-1:0] 	       LookupTag;
  logic [NUMLINES-1:0] 	       ValidOut;
  logic 		       DataValidBit;

  // Depth is number of bits in one "word" of the memory, width is number of such words
  sram1rw #(.DEPTH(BLOCKLEN), .WIDTH(NUMLINES)) 
  cachemem (.*,
	    .Addr(PCNextIndexF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
	    .ReadData(ReadLineF),
	    .WriteData(WriteLine)
	    );
  
  sram1rw #(.DEPTH(TAGLEN), .WIDTH(NUMLINES)) 
  cachetags (.*,
	     .Addr(PCNextIndexF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
	     .ReadData(LookupTag),
	     .WriteData(PCTagF[`PA_BITS-1:INDEXLEN+OFFSETLEN])
	     );

  // Correctly handle the valid bits
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      ValidOut <= {NUMLINES{1'b0}};
  end else if (flush) begin
    ValidOut <= {NUMLINES{1'b0}};
         end else begin
           if (WriteEnable) begin
             ValidOut[PCNextIndexF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]] <= 1;
           end
         end
    DataValidBit <= ValidOut[PCNextIndexF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]];
  end
  assign HitF = DataValidBit && (LookupTag == PCTagF[`PA_BITS-1:INDEXLEN+OFFSETLEN]);
endmodule
