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

    rodirectmappedmem #(.LINESIZE(ICACHELINESIZE), .NUMLINES(ICACHENUMLINES), .WORDSIZE(`XLEN)) cachemem(
        .*,
        // Stall it if the pipeline is stalled, unless we're stalling it and we're ending our stall
        .stall(StallF && (~ICacheStallF || ~EndFetchState)),
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
    input  logic    clk, reset,
    input  logic    StallF, StallD,
    input  logic    FlushD,

    // Input the address to read
    // The upper bits of the physical pc
    input  logic [`XLEN-1:12]   UpperPCNextPF,
    // The lower bits of the virtual pc
    input  logic [11:0]         LowerPCNextF,

    // Signals to/from cache memory
    // The read coming out of it
    input  logic [`XLEN-1:0]    ICacheMemReadData,
    input  logic                ICacheMemReadValid,
    // The address at which we want to search the cache memory
    output logic [`XLEN-1:12]   ICacheMemReadUpperPAdr,
    output logic [11:0]         ICacheMemReadLowerAdr,
    // Load data into the cache
    output logic                ICacheMemWriteEnable,
    output logic [LINESIZE-1:0] ICacheMemWriteData,
    output logic [`XLEN-1:0]    ICacheMemWritePAdr,

    // Outputs to rest of ifu
    // High if the instruction in the fetch stage is compressed
    output logic CompressedF,
    // The instruction that was requested
    // If this instruction is compressed, upper 16 bits may be the next 16 bits or may be zeros
    output logic [31:0]     InstrRawD,

    // Outputs to pipeline control stuff
    output logic ICacheStallF, EndFetchState,

    // Signals to/from ahblite interface
    // A read containing the requested data
    input  logic [`XLEN-1:0] InstrInF,
    input  logic             InstrAckF,
    // The read we request from main memory
    output logic [`XLEN-1:0] InstrPAdrF,
    output logic             InstrReadF
);

    // Happy path signals
    logic [31:0]    AlignedInstrRawF, AlignedInstrRawD;
    logic           FlushDLastCycleN;
    logic           PCPMisalignedF;
    const logic [31:0] NOP = 32'h13;
    logic [`XLEN-1:0] PCPF;
    // Misaligned signals
    logic [`XLEN:0] MisalignedInstrRawF;
    logic           MisalignedStall;
    // Cache fault signals
    logic           FaultStall;

    // Detect if the instruction is compressed
    assign CompressedF = AlignedInstrRawF[1:0] != 2'b11;


    // Handle happy path (data in cache, reads aligned)

    generate
        if (`XLEN == 32) begin
            assign AlignedInstrRawF = PCPF[1] ? MisalignedInstrRawF : ICacheMemReadData;
            assign PCPMisalignedF = PCPF[1] && ~CompressedF;
        end else begin
            assign AlignedInstrRawF = PCPF[2]
                ? (PCPF[1] ? MisalignedInstrRawF : ICacheMemReadData[63:32])
                : (PCPF[1] ? ICacheMemReadData[47:16] : ICacheMemReadData[31:0]);
            assign PCPMisalignedF = PCPF[2] && PCPF[1] && ~CompressedF;
        end
    endgenerate

    flopenr #(32) AlignedInstrRawDFlop(clk, reset, ~StallD, AlignedInstrRawF, AlignedInstrRawD);
    flopr   #(1)  FlushDLastCycleFlop(clk, reset, ~FlushD & (FlushDLastCycleN | ~StallF), FlushDLastCycleN);
    flopenr #(`XLEN) PCPFFlop(clk, reset, ~StallF, {UpperPCNextPF, LowerPCNextF}, PCPF);
    mux2    #(32) InstrRawDMux(AlignedInstrRawD, NOP, ~FlushDLastCycleN, InstrRawD);

    // Stall for faults or misaligned reads
    always_comb begin
        assign ICacheStallF = FaultStall | MisalignedStall;
    end


    // Handle misaligned, noncompressed reads

    logic           MisalignedState, NextMisalignedState;
    logic [15:0]    MisalignedHalfInstrF;
    logic [15:0]    UpperHalfWord;

    flopenr #(16) MisalignedHalfInstrFlop(clk, reset, ~FaultStall & (PCPMisalignedF & MisalignedState), AlignedInstrRawF[15:0], MisalignedHalfInstrF);
    flopenr #(1)  MisalignedStateFlop(clk, reset, ~FaultStall, NextMisalignedState, MisalignedState);

    // When doing a misaligned read, swizzle the bits correctly
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

    // Manage internal state and stall when necessary
    always_comb begin
        assign MisalignedStall = PCPMisalignedF & MisalignedState;
        assign NextMisalignedState = ~PCPMisalignedF | ~MisalignedState;
    end

    // Pick the correct address to read
    generate
        if (`XLEN == 32) begin
            assign ICacheMemReadLowerAdr = {LowerPCNextF[11:2] + (PCPMisalignedF & ~MisalignedState), 2'b00};
        end else begin
            assign ICacheMemReadLowerAdr = {LowerPCNextF[11:3] + (PCPMisalignedF & ~MisalignedState), 3'b00};
        end
    endgenerate
    // TODO Handle reading instructions that cross page boundaries
    assign ICacheMemReadUpperPAdr = UpperPCNextPF;


    // Handle cache faults

    localparam integer WORDSPERLINE = LINESIZE/`XLEN;
    localparam integer LOGWPL = $clog2(WORDSPERLINE);
    localparam integer OFFSETWIDTH = $clog2(LINESIZE/8);

    logic               FetchState, BeginFetchState;
    logic [LOGWPL:0]    FetchWordNum, NextFetchWordNum;
    logic [`XLEN-1:0]   LineAlignedPCPF;

    flopr #(1) FetchStateFlop(clk, reset, BeginFetchState | (FetchState & ~EndFetchState), FetchState);
    flopr #(LOGWPL+1) FetchWordNumFlop(clk, reset, NextFetchWordNum, FetchWordNum);

    genvar i;
    generate
        for (i=0; i < WORDSPERLINE; i++) begin
            flopenr #(`XLEN) flop(clk, reset, FetchState & (i == FetchWordNum), InstrInF, ICacheMemWriteData[(i+1)*`XLEN-1:i*`XLEN]);
        end
    endgenerate

    // Enter the fetch state when we hit a cache fault
    always_comb begin
        BeginFetchState = ~ICacheMemReadValid & ~FetchState & (FetchWordNum == 0);
    end
    // Exit the fetch state once the cache line has been loaded
    flopr #(1) EndFetchStateFlop(clk, reset, ICacheMemWriteEnable, EndFetchState);

    // Machinery to request the correct addresses from main memory
    always_comb begin
        InstrReadF = FetchState & ~EndFetchState & ~ICacheMemWriteEnable;
        LineAlignedPCPF = {ICacheMemReadUpperPAdr, ICacheMemReadLowerAdr[11:OFFSETWIDTH], {OFFSETWIDTH{1'b0}}};
        InstrPAdrF = LineAlignedPCPF + FetchWordNum*(`XLEN/8);
        NextFetchWordNum = FetchState ? FetchWordNum+InstrAckF : {LOGWPL+1{1'b0}}; 
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
endmodule
