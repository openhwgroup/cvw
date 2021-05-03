`include "wally-config.vh"

module rodirectmappedmemre #(parameter NUMLINES=512, parameter LINESIZE = 256, parameter WORDSIZE = `XLEN) (
    // Pipeline stuff
    input  logic clk,
    input  logic reset,
    input  logic re,
    // If flush is high, invalidate the entire cache
    input  logic flush,
    // Select which address to read (broken for efficiency's sake)
    input  logic [`XLEN-1:12]   ReadUpperPAdr, // physical address Must come one cycle later
    input  logic [11:0]         ReadLowerAdr, // virtual address
    // Write new data to the cache
    input  logic                WriteEnable,
    input  logic [LINESIZE-1:0] WriteLine,
    input  logic [`XLEN-1:0]    WritePAdr,
    // Output the word, as well as if it is valid
    output logic [31:0] DataWord, // *** was WORDSIZE-1
    output logic                DataValid
);

    // Various compile-time constants
    localparam integer WORDWIDTH = $clog2(WORDSIZE/8);
    localparam integer OFFSETWIDTH = $clog2(LINESIZE/WORDSIZE);
    localparam integer SETWIDTH = $clog2(NUMLINES);
    localparam integer TAGWIDTH = `XLEN - OFFSETWIDTH - SETWIDTH - WORDWIDTH;

    localparam integer OFFSETBEGIN = WORDWIDTH;
    localparam integer OFFSETEND = OFFSETBEGIN+OFFSETWIDTH-1;
    localparam integer SETBEGIN = OFFSETEND+1;
    localparam integer SETEND = SETBEGIN + SETWIDTH - 1;
    localparam integer TAGBEGIN = SETEND + 1;
    localparam integer TAGEND = TAGBEGIN + TAGWIDTH - 1;

    // Machinery to read from and write to the correct addresses in memory
    logic [`XLEN-1:0]       ReadPAdr;
    logic [`XLEN-1:0]       OldReadPAdr;
    logic [OFFSETWIDTH-1:0] ReadOffset, WriteOffset;
    logic [SETWIDTH-1:0]    ReadSet, WriteSet;
    logic [TAGWIDTH-1:0]    ReadTag, WriteTag;
    logic [LINESIZE-1:0]    ReadLine;
    logic [LINESIZE/WORDSIZE-1:0][WORDSIZE-1:0] ReadLineTransformed;

    // Machinery to check if a given read is valid and is the desired value
    logic [TAGWIDTH-1:0]    DataTag;
    logic [NUMLINES-1:0]    ValidOut;
    logic                   DataValidBit;

    flopenr #(`XLEN) ReadPAdrFlop(clk, reset, re, ReadPAdr, OldReadPAdr);

    // Assign the read and write addresses in cache memory
    always_comb begin
        ReadOffset = OldReadPAdr[OFFSETEND:OFFSETBEGIN];
        ReadPAdr = {ReadUpperPAdr, ReadLowerAdr};
        ReadSet = ReadPAdr[SETEND:SETBEGIN];
        ReadTag = OldReadPAdr[TAGEND:TAGBEGIN];

        WriteOffset = WritePAdr[OFFSETEND:OFFSETBEGIN];
        WriteSet = WritePAdr[SETEND:SETBEGIN];
        WriteTag = WritePAdr[TAGEND:TAGBEGIN];
    end

    // Depth is number of bits in one "word" of the memory, width is number of such words
    Sram1Read1Write #(.DEPTH(LINESIZE), .WIDTH(NUMLINES)) cachemem (
        .*,
        .ReadAddr(ReadSet),
        .ReadData(ReadLine),
        .WriteAddr(WriteSet),
        .WriteData(WriteLine)
    );
    Sram1Read1Write #(.DEPTH(TAGWIDTH), .WIDTH(NUMLINES)) cachetags (
        .*,
        .ReadAddr(ReadSet),
        .ReadData(DataTag),
        .WriteAddr(WriteSet),
        .WriteData(WriteTag)
    );

    // Pick the right bits coming out the read line
    //assign DataWord = ReadLineTransformed[ReadOffset];
  //logic [31:0] tempRD;
  always_comb begin
    case (OldReadPAdr[4:1])
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
    genvar i;
    generate
        for (i=0; i < LINESIZE/WORDSIZE; i++) begin
            assign ReadLineTransformed[i] = ReadLine[(i+1)*WORDSIZE-1:i*WORDSIZE];
        end
    endgenerate

    // Correctly handle the valid bits
    always_ff @(posedge clk, posedge reset) begin
        if (reset || flush) begin
            ValidOut <= {NUMLINES{1'b0}};
        end else begin
            if (WriteEnable) begin
                ValidOut[WriteSet] <= 1;
            end
        end
        DataValidBit <= ValidOut[ReadSet];
    end
    assign DataValid = DataValidBit && (DataTag == ReadTag);
endmodule
