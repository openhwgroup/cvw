///////////////////////////////////////////
// dcache.sv
//
// Written: jaallen@g.hmc.edu 2021-04-15
// Modified: 
//
// Purpose: Cache memory for the dmem so it can access memory less often, saving cycles
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

module dcache(
  // Basic pipeline stuff
  input  logic              clk, reset,
  input  logic              StallW,
  input  logic              FlushW,
  // Upper bits of physical address
  input  logic [`PA_BITS-1:12] UpperPAdrM,
  // Lower 12 bits of virtual address, since it's faster this way
  input  logic [11:0]       LowerVAdrM,
  // Write to the dcache
  input  logic [`XLEN-1:0]  DCacheWriteDataM,
  input  logic              DCacheReadM, DCacheWriteM,
  // Data read in from the ebu unit
  input  logic [`XLEN-1:0]  ReadDataW,
  input  logic              MemAckW,
  // Access requested from the ebu unit
  output logic [`PA_BITS-1:0]  MemPAdrM,
  output logic              MemReadM, MemWriteM,
  // High if the dcache is requesting a stall
  output logic              DCacheStallW,
  // The data that was requested from the cache
  output logic [`XLEN-1:0]  DCacheReadW
);

    // Configuration parameters
    // TODO Move these to a config file
    localparam integer DCACHELINESIZE = 256;
    localparam integer DCACHENUMLINES = 512;

    // Input signals to cache memory
    logic                       FlushMem;
    logic [`PA_BITS-1:12]       DCacheMemUpperPAdr;
    logic [11:0]                DCacheMemLowerAdr;
    logic                       DCacheMemWriteEnable;
    logic [DCACHELINESIZE-1:0]  DCacheMemWriteData;
    logic [`XLEN-1:0]           DCacheMemWritePAdr;
    logic                       EndFetchState;
    // Output signals from cache memory
    logic [`XLEN-1:0]   DCacheMemReadData;
    logic               DCacheMemReadValid;

    wtdirectmappedmem #(.LINESIZE(DCACHELINESIZE), .NUMLINES(DCACHENUMLINES), .WORDSIZE(`XLEN)) cachemem(
        .*,
        // Stall it if the pipeline is stalled, unless we're stalling it and we're ending our stall
        .stall(StallW),
        .flush(FlushMem),
        .ReadUpperPAdr(DCacheMemUpperPAdr),
        .ReadLowerAdr(DCacheMemLowerAdr),
        .LoadEnable(DCacheMemWriteEnable),
        .LoadLine(DCacheMemWriteData),
        .LoadPAdr(DCacheMemWritePAdr),
        .DataWord(DCacheMemReadData),
        .DataValid(DCacheMemReadValid),
        .WriteEnable(0),
        .WriteWord(0),
        .WritePAdr(0),
        .WriteSize(2'b10)
    );

    dcachecontroller #(.LINESIZE(DCACHELINESIZE)) controller(.*);

    // For now, assume no writes to executable memory
    assign FlushMem = 1'b0;
endmodule

module dcachecontroller #(parameter LINESIZE = 256) (
    // Inputs from pipeline
    input  logic    clk, reset,
    input  logic    StallW,
    input  logic    FlushW,

    // Input the address to read
    // The upper bits of the physical pc
    input  logic [`PA_BITS-1:12]   DCacheMemUpperPAdr,
    // The lower bits of the virtual pc
    input  logic [11:0]         DCacheMemLowerAdr,

    // Signals to/from cache memory
    // The read coming out of it
    input  logic [`XLEN-1:0]    DCacheMemReadData,
    input  logic                DCacheMemReadValid,
    // Load data into the cache
    output logic                DCacheMemWriteEnable,
    output logic [LINESIZE-1:0] DCacheMemWriteData,
    output logic [`XLEN-1:0]    DCacheMemWritePAdr,

    // The read that was requested
    output logic [31:0]     DCacheReadW,

    // Outputs to pipeline control stuff
    output logic DCacheStallW, EndFetchState,

    // Signals to/from ahblite interface
    // A read containing the requested data
    input  logic [`XLEN-1:0] ReadDataW,
    input  logic             MemAckW,
    // The read we request from main memory
    output logic [`PA_BITS-1:0] MemPAdrM,
    output logic             MemReadM, MemWriteM
);

    // Cache fault signals
    logic           FaultStall;

    // Handle happy path (data in cache)

    always_comb begin
        DCacheReadW = DCacheMemReadData;
    end


    // Handle cache faults

    localparam integer WORDSPERLINE = LINESIZE/`XLEN;
    localparam integer LOGWPL = $clog2(WORDSPERLINE);
    localparam integer OFFSETWIDTH = $clog2(LINESIZE/8);

    logic               FetchState, BeginFetchState;
    logic [LOGWPL:0]    FetchWordNum, NextFetchWordNum;
    logic [`PA_BITS-1:0]   LineAlignedPCPF;

    flopr #(1) FetchStateFlop(clk, reset, BeginFetchState | (FetchState & ~EndFetchState), FetchState);
    flopr #(LOGWPL+1) FetchWordNumFlop(clk, reset, NextFetchWordNum, FetchWordNum);

    genvar i;
    generate
        for (i=0; i < WORDSPERLINE; i++) begin:sb
            flopenr #(`XLEN) flop(clk, reset, FetchState & (i == FetchWordNum), ReadDataW, DCacheMemWriteData[(i+1)*`XLEN-1:i*`XLEN]);
        end
    endgenerate

    // Enter the fetch state when we hit a cache fault
    always_comb begin
        BeginFetchState = ~DCacheMemReadValid & ~FetchState & (FetchWordNum == 0);
    end
    // Exit the fetch state once the cache line has been loaded
    flopr #(1) EndFetchStateFlop(clk, reset, DCacheMemWriteEnable, EndFetchState);

    // Machinery to request the correct addresses from main memory
    always_comb begin
        MemReadM = FetchState & ~EndFetchState & ~DCacheMemWriteEnable;
        LineAlignedPCPF = {DCacheMemUpperPAdr, DCacheMemLowerAdr[11:OFFSETWIDTH], {OFFSETWIDTH{1'b0}}};
        MemPAdrM = LineAlignedPCPF + FetchWordNum*(`XLEN/8);
        NextFetchWordNum = FetchState ? FetchWordNum+MemAckW : {LOGWPL+1{1'b0}}; 
    end

    // Write to cache memory when we have the line here
    always_comb begin
        DCacheMemWritePAdr = LineAlignedPCPF;
        DCacheMemWriteEnable = FetchWordNum == {1'b1, {LOGWPL{1'b0}}} & FetchState & ~EndFetchState;
    end

    // Stall the pipeline while loading a new line from memory
    always_comb begin
        DCacheStallW = FetchState | ~DCacheMemReadValid;
    end
endmodule
