///////////////////////////////////////////
// dmapped.sv
//
// Written: jaallen@g.hmc.edu 2021-03-23
// Modified: 
//
// Purpose: An implementation of a direct-mapped cache memory, with read-only and write-through versions
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

// Read-only direct-mapped memory
module rodirectmappedmem #(parameter NUMLINES=512, parameter LINESIZE = 256, parameter WORDSIZE = `XLEN) (
    // Pipeline stuff
    input  logic clk,
    input  logic reset,
    input  logic stall,
    // If flush is high, invalidate the entire cache
    input  logic flush,
    // Select which address to read (broken for efficiency's sake)
    input  logic [`XLEN-1:12]   ReadUpperPAdr,
    input  logic [11:0]         ReadLowerAdr,
    // Write new data to the cache
    input  logic                WriteEnable,
    input  logic [LINESIZE-1:0] WriteLine,
    input  logic [`XLEN-1:0]    WritePAdr,
    // Output the word, as well as if it is valid
    output logic [WORDSIZE-1:0] DataWord,
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

    flopenr #(`XLEN) ReadPAdrFlop(clk, reset, ~stall, ReadPAdr, OldReadPAdr);

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
    assign DataWord = ReadLineTransformed[ReadOffset];
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

module rodirectmappedmemre #(parameter NUMLINES=512, parameter LINESIZE = 256, parameter WORDSIZE = `XLEN) (
    // Pipeline stuff
    input  logic clk,
    input  logic reset,
    input  logic re,
    // If flush is high, invalidate the entire cache
    input  logic flush,
    // Select which address to read (broken for efficiency's sake)
    input  logic [`XLEN-1:12]   ReadUpperPAdr,
    input  logic [11:0]         ReadLowerAdr,
    // Write new data to the cache
    input  logic                WriteEnable,
    input  logic [LINESIZE-1:0] WriteLine,
    input  logic [`XLEN-1:0]    WritePAdr,
    // Output the word, as well as if it is valid
    output logic [WORDSIZE-1:0] DataWord,
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
    assign DataWord = ReadLineTransformed[ReadOffset];
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

// Write-through direct-mapped memory
module wtdirectmappedmem #(parameter NUMLINES=512, parameter LINESIZE = 256, parameter WORDSIZE = `XLEN) (
    // Pipeline stuff
    input  logic clk,
    input  logic reset,
    input  logic stall,
    // If flush is high, invalidate the entire cache
    input  logic flush,
    // Select which address to read (broken for efficiency's sake)
    input  logic [`XLEN-1:12]   ReadUpperPAdr,
    input  logic [11:0]         ReadLowerAdr,
    // Load new data into the cache (from main memory)
    input  logic                LoadEnable,
    input  logic [LINESIZE-1:0] LoadLine,
    input  logic [`XLEN-1:0]    LoadPAdr,
    // Write data to the cache (like from a store instruction)
    input  logic                WriteEnable,
    input  logic [WORDSIZE-1:0] WriteWord,
    input  logic [`XLEN-1:0]    WritePAdr,
    input  logic [1:0]          WriteSize, // Specify size of the write (non-written bits should be preserved)
    // Output the word, as well as if it is valid
    output logic [WORDSIZE-1:0] DataWord,
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
    logic [OFFSETWIDTH-1:0] ReadOffset, LoadOffset;
    logic [SETWIDTH-1:0]    ReadSet, LoadSet;
    logic [TAGWIDTH-1:0]    ReadTag, LoadTag;
    logic [LINESIZE-1:0]    ReadLine;
    logic [LINESIZE/WORDSIZE-1:0][WORDSIZE-1:0] ReadLineTransformed;

    // Machinery to check if a given read is valid and is the desired value
    logic [TAGWIDTH-1:0]    DataTag;
    logic [NUMLINES-1:0]    ValidOut;
    logic                   DataValidBit;

    flopenr #(`XLEN) ReadPAdrFlop(clk, reset, ~stall, ReadPAdr, OldReadPAdr);

    // Assign the read and write addresses in cache memory
    always_comb begin
        ReadOffset = OldReadPAdr[OFFSETEND:OFFSETBEGIN];
        ReadPAdr = {ReadUpperPAdr, ReadLowerAdr};
        ReadSet = ReadPAdr[SETEND:SETBEGIN];
        ReadTag = OldReadPAdr[TAGEND:TAGBEGIN];

        LoadOffset = LoadPAdr[OFFSETEND:OFFSETBEGIN];
        LoadSet = LoadPAdr[SETEND:SETBEGIN];
        LoadTag = LoadPAdr[TAGEND:TAGBEGIN];
    end

    // Depth is number of bits in one "word" of the memory, width is number of such words
    Sram1Read1Write #(.DEPTH(LINESIZE), .WIDTH(NUMLINES)) cachemem (
        .*,
        .ReadAddr(ReadSet),
        .ReadData(ReadLine),
        .WriteAddr(LoadSet),
        .WriteData(LoadLine),
        .WriteEnable(LoadEnable)
    );
    Sram1Read1Write #(.DEPTH(TAGWIDTH), .WIDTH(NUMLINES)) cachetags (
        .*,
        .ReadAddr(ReadSet),
        .ReadData(DataTag),
        .WriteAddr(LoadSet),
        .WriteData(LoadTag),
        .WriteEnable(LoadEnable)
    );

    // Pick the right bits coming out the read line
    assign DataWord = ReadLineTransformed[ReadOffset];
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
            if (LoadEnable) begin
                ValidOut[LoadSet] <= 1;
            end
        end
        DataValidBit <= ValidOut[ReadSet];
    end
    assign DataValid = DataValidBit && (DataTag == ReadTag);
endmodule
