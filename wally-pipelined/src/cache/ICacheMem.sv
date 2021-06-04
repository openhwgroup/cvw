`include "wally-config.vh"

module ICacheMem #(parameter NUMLINES=512, parameter BLOCKLEN = 256) 
  (
   // Pipeline stuff
   input logic 		      clk,
   input logic 		      reset,
   // If flush is high, invalidate the entire cache
   input logic 		      flush,

   // Select which address to read (broken for efficiency's sake)
   input logic [`XLEN-1:0]    PCTagF, // physical tag address
   input logic [`XLEN-1:0]    PCNextIndexF,
   // Write new data to the cache
   input logic 		      WriteEnable,
   input logic [BLOCKLEN-1:0] WriteLine,
   // Output the word, as well as if it is valid
   output logic [31:0] 	      DataWord, // *** was `XLEN-1
   output logic 	      DataValid
   );

  // divide the address bus into sections, tag, index, offset
  localparam BLOCKBYTELEN = BLOCKLEN/8;
  localparam OFFSETLEN = $clog2(BLOCKBYTELEN);
  localparam INDEXLEN = $clog2(NUMLINES);
  localparam TAGLEN = `XLEN - OFFSETLEN - INDEXLEN;

  // Machinery to read from and write to the correct addresses in memory
  logic [BLOCKLEN-1:0] 	      ReadLine;

  // Machinery to check if a given read is valid and is the desired value
  logic [TAGLEN-1:0] 	      DataTag;
  logic [NUMLINES-1:0] 	      ValidOut;
  logic 		      DataValidBit;

  // Depth is number of bits in one "word" of the memory, width is number of such words
  sram1rw #(.DEPTH(BLOCKLEN), .WIDTH(NUMLINES)) 
  cachemem (.*,
	    .Addr(PCNextIndexF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
	    .ReadData(ReadLine),
	    .WriteData(WriteLine)
	    );
  sram1rw #(.DEPTH(TAGLEN), .WIDTH(NUMLINES)) 
  cachetags (.*,
	     .Addr(PCNextIndexF[INDEXLEN+OFFSETLEN-1:OFFSETLEN]),
	     .ReadData(DataTag),
	     .WriteData(PCTagF[`XLEN-1:INDEXLEN+OFFSETLEN])
	     );

  // Pick the right bits coming out the read line
  //assign DataWord = ReadLineTransformed[ReadOffset];
  //logic [31:0] tempRD;
  always_comb begin
    case (PCTagF[4:1])
      0: DataWord = ReadLine[31:0];
      1: DataWord = ReadLine[47:16];
      2: DataWord = ReadLine[63:32];
      3: DataWord = ReadLine[79:48];

      4: DataWord = ReadLine[95:64];
      5: DataWord = ReadLine[111:80];
      6: DataWord = ReadLine[127:96];
      7: DataWord = ReadLine[143:112];      

      8: DataWord = ReadLine[159:128];      
      9: DataWord = ReadLine[175:144];      
      10: DataWord = ReadLine[191:160];      
      11: DataWord = ReadLine[207:176];

      12: DataWord = ReadLine[223:192];
      13: DataWord = ReadLine[239:208];
      14: DataWord = ReadLine[255:224];
      15: DataWord = {16'b0, ReadLine[255:240]};
    endcase
  end

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
  assign DataValid = DataValidBit && (DataTag == PCTagF[`XLEN-1:INDEXLEN+OFFSETLEN]);
endmodule
