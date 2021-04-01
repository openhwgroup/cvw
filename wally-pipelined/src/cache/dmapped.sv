///////////////////////////////////////////
// dmapped.sv
//
// Written: jaallen@g.hmc.edu 2021-03-23
// Modified: 
//
// Purpose: An implementation of a direct-mapped cache memory
// This cache is read-only, so "write"s to the memory are loading new data
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

module rodirectmappedmem #(parameter NUMLINES=512, parameter LINESIZE = 256, parameter WORDSIZE = `XLEN) (
    // Pipeline stuff
    input  logic clk,
    input  logic reset,
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
    localparam integer WORDWIDTH = $clog2(WORDSIZE);
    localparam integer LINEWIDTH = $clog2(LINESIZE/8);
    localparam integer OFFSETWIDTH = $clog2(LINESIZE) - WORDWIDTH;
    localparam integer SETWIDTH = $clog2(NUMLINES);
    localparam integer TAGWIDTH = $clog2(`XLEN) - $clog2(LINESIZE) - SETWIDTH;

    // Machinery to read from and write to the correct addresses in memory
    logic [`XLEN-1:0]       ReadPAdr;
    logic [OFFSETWIDTH-1:0] ReadOffset, WriteOffset;
    logic [SETWIDTH-1:0]    ReadSet, WriteSet;
    logic [TAGWIDTH-1:0]    ReadTag, WriteTag;

    // Machinery to check if a given read is valid and is the desired value
    logic [TAGWIDTH-1:0]    DataTag;
    logic [NUMLINES-1:0]    ValidOut, NextValidOut;

    // Assign the read and write addresses in cache memory
    always_comb begin
        assign ReadOffset = ReadLowerAdr[WORDWIDTH+OFFSETWIDTH-1:WORDWIDTH];
        assign ReadPAdr = {ReadUpperPAdr, ReadLowerAdr};
        assign ReadSet = ReadPAdr[LINEWIDTH+SETWIDTH-1:LINEWIDTH];
        assign ReadTag = ReadPAdr[`XLEN-1:LINEWIDTH+SETWIDTH];

        assign WriteOffset = WritePAdr[WORDWIDTH+OFFSETWIDTH-1:WORDWIDTH];
        assign WriteSet = WritePAdr[LINEWIDTH+SETWIDTH-1:LINEWIDTH];
        assign WriteTag = WritePAdr[`XLEN-1:LINEWIDTH+SETWIDTH];
    end

    SRAM2P1R1W #(.Depth(OFFSETWIDTH), .Width(WORDSIZE)) cachemem (
        .*,
        .RA1(ReadOffset),
        .RD1(DataWord),
        .REN1(1'b1),
        .WA1(WriteOffset),
        .WD1(WriteSet),
        .WEN1(WriteEnable),
        .BitWEN1(0)
    );

    SRAM2P1R1W #(.Depth(OFFSETWIDTH), .Width(TAGWIDTH)) cachetags (
        .*,
        .RA1(ReadOffset),
        .RD1(DataTag),
        .REN1(1'b1),
        .WA1(WriteOffset),
        .WD1(WriteTag),
        .WEN1(WriteEnable),
        .BitWEN1(0)
    );

    // Correctly handle the valid bits
    always_comb begin
        if (WriteEnable) begin
            assign NextValidOut = {NextValidOut[NUMLINES-1:WriteSet+1], 1'b1, NextValidOut[WriteSet-1:0]};
        end else begin
            assign NextValidOut = ValidOut;
        end
    end
    always_ff @(posedge clk, reset, flush) begin
        if (reset || flush) begin
            ValidOut <= {NUMLINES{1'b0}};
        end else begin
            ValidOut <= NextValidOut;
        end
    end

    // Determine if the line coming out is valid and matches the desired data
    always_comb begin
        assign DataValid = ValidOut[ReadSet] && (DataTag == ReadTag);
    end

endmodule
