///////////////////////////////////////////
// dmapped.sv
//
// Written: jaallen@g.hmc.edu 2021-03-23
// Modified: 
//
// Purpose: An implementation of a direct-mapped cache memory
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

module rodirectmapped #(parameter LINESIZE = 256, parameter NUMLINES = 512, parameter WORDSIZE = `XLEN) (
    // Pipeline stuff
    input  logic clk,
    input  logic reset,
    // If flush is high, invalidate the entire cache
    input  logic flush,
    // Select which address to read (broken for efficiency's sake)
    input  logic [`XLEN-1:12]   UpperPAdr,
    input  logic [11:0]         LowerAdr,
    // Write new data to the cache
    input  logic                WriteEnable,
    input  logic [LINESIZE-1:0] WriteLine,
    input  logic [`XLEN-1:0]    WritePAdr,
    // Output the word, as well as if it is valid
    output logic [WORDSIZE-1:0] DataWord,
    output logic                DataValid
);

    localparam integer SETWIDTH    = $clog2(NUMLINES);
    localparam integer OFFSETWIDTH = $clog2(LINESIZE/8);
    localparam integer TAGWIDTH    = `XLEN-SETWIDTH-OFFSETWIDTH;

    logic [NUMLINES-1:0][WORDSIZE-1:0]  LineOutputs;
    logic [NUMLINES-1:0]                ValidOutputs;
    logic [NUMLINES-1:0][TAGWIDTH-1:0]  TagOutputs;
    logic [OFFSETWIDTH-1:0]             WordSelect;
    logic [`XLEN-1:0]                   ReadPAdr;
    logic [SETWIDTH-1:0]                ReadSet, WriteSet;
    logic [TAGWIDTH-1:0]                ReadTag, WriteTag;

    // Swizzle bits to get the offset, set, and tag out of the read and write addresses
    always_comb begin
        // Read address
        assign WordSelect = LowerAdr[OFFSETWIDTH-1:0];
        assign ReadPAdr = {UpperPAdr, LowerAdr};
        assign ReadSet = ReadPAdr[SETWIDTH+OFFSETWIDTH-1:OFFSETWIDTH];
        assign ReadTag = ReadPAdr[`XLEN-1:SETWIDTH+OFFSETWIDTH];
        // Write address
        assign WriteSet = WritePAdr[SETWIDTH+OFFSETWIDTH-1:OFFSETWIDTH];
        assign WriteTag = WritePAdr[`XLEN-1:SETWIDTH+OFFSETWIDTH];
    end

    genvar i;
    generate
        for (i=0; i < NUMLINES; i++) begin
            rocacheline #(LINESIZE, TAGWIDTH, WORDSIZE) lines (
                .*,
                .WriteEnable(WriteEnable & (WriteSet == i)),
                .WriteData(WriteLine),
                .WriteTag(WriteTag),
                .DataWord(LineOutputs[i]),
                .DataTag(TagOutputs[i]),
                .DataValid(ValidOutputs[i])
            );
        end
    endgenerate

    // Get the data and valid out of the lines
    always_comb begin
        assign DataWord = LineOutputs[ReadSet];
        assign DataValid = ValidOutputs[ReadSet] & (TagOutputs[ReadSet] == ReadTag);
    end

endmodule
