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
  input  logic [`XLEN-1:12] UpperPCPF,
  // Lower 12 bits of virtual PC address, since it's faster this way
  input  logic [11:0]       LowerPCF,
  // Data read in from the ebu unit
  input  logic [`XLEN-1:0]  InstrInF,
  // Read requested from the ebu unit
  output logic [`XLEN-1:0]  InstrPAdrF,
  output logic              InstrReadF,
  // High if the instruction currently in the fetch stage is compressed
  output logic              CompressedF,
  // High if the icache is requesting a stall
  output logic              ICacheStallF,
  // The raw (not decompressed) instruction that was requested
  // If the next instruction is compressed, the upper 16 bits may be anything
  output logic [31:0]       InstrRawD
);

    logic             DelayF, DelaySideF, FlushDLastCyclen, DelayD;
    logic  [1:0]      InstrDMuxChoice;
    logic [15:0]      MisalignedHalfInstrF, MisalignedHalfInstrD;
    logic [31:0]      InstrF, AlignedInstrD;
    // Buffer the last read, for ease of accessing it again
    logic             LastReadDataValidF;
    logic [`XLEN-1:0] LastReadDataF, LastReadAdrF, InDataF;

    // instruction for NOP
    logic [31:0]      nop = 32'h00000013;

    // Temporary change to bridge the new interface to old behaviors
    logic [`XLEN-1:0] PCPF;
    assign PCPF = {UpperPCPF, LowerPCF};

    // This flop doesn't stall if StallF is high because we should output a nop
    // when FlushD happens, even if the pipeline is also stalled.
    flopr   #(1)  flushDLastCycleFlop(clk, reset, ~FlushD & (FlushDLastCyclen | ~StallF), FlushDLastCyclen);

    flopenr #(1)  delayDFlop(clk, reset, ~StallF, DelayF & ~CompressedF, DelayD);
    flopenrc#(1)  delayStateFlop(clk, reset, FlushD, ~StallF, DelayF & ~DelaySideF, DelaySideF);
    // This flop stores the first half of a misaligned instruction while waiting for the other half
    flopenr #(16) halfInstrFlop(clk, reset, DelayF & ~StallF, MisalignedHalfInstrF, MisalignedHalfInstrD);

    // This flop is here to simulate pulling data out of the cache, which is edge-triggered
    flopenr #(32) instrFlop(clk, reset, ~StallF, InstrF, AlignedInstrD);

    // These flops cache the previous read, to accelerate things
    flopenr #(`XLEN) lastReadDataFlop(clk, reset, InstrReadF & ~StallF, InstrInF, LastReadDataF);
    flopenr #(1)     lastReadDataVFlop(clk, reset, InstrReadF & ~StallF, 1'b1, LastReadDataValidF);
    flopenr #(`XLEN) lastReadAdrFlop(clk, reset, InstrReadF & ~StallF, InstrPAdrF, LastReadAdrF);

    // Decide which address needs to be fetched and sent out over InstrPAdrF
    // If the requested address fits inside one read from memory, we fetch that
    // address, adjusted to the bit width. Otherwise, we request the lower word
    // and then the upper word, in that order.
    generate
        if (`XLEN == 32) begin
            assign InstrPAdrF = PCPF[1] ? ((DelaySideF & ~CompressedF) ? {PCPF[31:2], 2'b00} : {PCPF[31:2], 2'b00}) : PCPF;
        end else begin
            assign InstrPAdrF = PCPF[2] ? (PCPF[1] ? ((DelaySideF & ~CompressedF) ? {PCPF[63:3]+1, 3'b000} : {PCPF[63:3], 3'b000}) : {PCPF[63:3], 3'b000}) : {PCPF[63:3], 3'b000};
        end
    endgenerate

    // Read from memory if we don't have the address we want
    always_comb if (LastReadDataValidF & (InstrPAdrF == LastReadAdrF)) begin
        InstrReadF = 0;
    end else begin
        InstrReadF = 1;
    end

    // Pick from the memory input or from the previous read, as appropriate
    mux2 #(`XLEN) inDataMux(LastReadDataF, InstrInF, InstrReadF, InDataF);

    // If the instruction fits in one memory read, then we put the right bits
    // into InstrF. Otherwise, we activate DelayF to signal the rest of the
    // machinery to swizzle bits.
    generate
        if (`XLEN == 32) begin
            assign InstrF = PCPF[1] ? {16'b0, InDataF[31:16]} : InDataF;
            assign DelayF = PCPF[1];
            assign MisalignedHalfInstrF = InDataF[31:16];
        end else begin
            assign InstrF = PCPF[2] ? (PCPF[1] ? {16'b0, InDataF[63:48]}  : InDataF[63:32]) : (PCPF[1] ? InDataF[47:16] : InDataF[31:0]);
            assign DelayF = PCPF[1] && PCPF[2];
            assign MisalignedHalfInstrF = InDataF[63:48];
        end
    endgenerate
    // We will likely need to stall later, but stalls are handled by the rest of the pipeline for now
    assign ICacheStallF = 0;

    // Detect if the instruction is compressed
    assign CompressedF = InstrF[1:0] != 2'b11;

    // Pick the correct output, depending on whether we have to assemble this
    // instruction from two reads or not.
    // Output the requested instruction (we don't need to worry if the read is
    // incomplete, since the pipeline stalls for us when it isn't), or a NOP for
    // the cycle when the first of two reads comes in.
    always_comb if (~FlushDLastCyclen) begin
        InstrDMuxChoice = 2'b10;
    end else if (DelayD & (MisalignedHalfInstrD[1:0] != 2'b11)) begin
        InstrDMuxChoice = 2'b11;
    end else begin
        InstrDMuxChoice = {1'b0, DelayD};
    end
    mux4 #(32) instrDMux (AlignedInstrD, {InstrInF[15:0], MisalignedHalfInstrD}, nop, {16'b0, MisalignedHalfInstrD}, InstrDMuxChoice, InstrRawD);
endmodule
