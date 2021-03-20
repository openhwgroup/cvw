///////////////////////////////////////////
// icache.sv
//
// Written: jaallen@g.hmc.edu 2021-03-02
// Modified: 
//
// Purpose: Cache instructions for the ifu so it can access memory less often
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
  input  logic             clk, reset,
  input  logic             StallF, StallD,
  input  logic             FlushD,
  // Fetch
  input  logic [`XLEN-1:0] PCPF,
  input  logic [`XLEN-1:0] InstrInF,
  output logic [`XLEN-1:0] InstrPAdrF,
  output logic             InstrReadF,
  output logic             CompressedF,
  output logic             ICacheStallF,
  // Decode
  output logic [31:0]     InstrRawD
);

    logic             DelayF, DelaySideF, FlushDLastCycle, DelayD, DelaySideD;
    logic  [1:0]      InstrDMuxChoice;
    logic [15:0]      MisalignedHalfInstrF, MisalignedHalfInstrD;
    logic [31:0]      InstrF, AlignedInstrD;
    logic [31:0]      nop = 32'h00000013; // instruction for NOP
    logic             LastReadDataValidF;
    logic [`XLEN-1:0] LastReadDataF, LastReadAdrF, InDataF;

    flopenr #(1)  flushDLastCycleFlop(clk, reset, ~StallF, FlushD, FlushDLastCycle);
    flopenr #(1)  delayDFlop(clk, reset, ~StallF, DelayF, DelayD);
    flopenr #(1)  delaySideDFlop(clk, reset, ~StallF, DelaySideF, DelaySideD);
    flopenrc#(1)  delayStateFlop(clk, reset, FlushD, ~StallF, DelayF & ~DelaySideF, DelaySideF);
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
            assign InstrPAdrF = PCPF[1] ? ((DelaySideF & ~CompressedF) ? {PCPF[31:2]+1, 2'b00} : {PCPF[31:2], 2'b00}) : PCPF;
        end else begin
            assign InstrPAdrF = PCPF[2] ? (PCPF[1] ? ((DelaySideF & ~CompressedF) ? {PCPF[63:3]+1, 3'b000} : {PCPF[63:3], 3'b000}) : {PCPF[63:3], 3'b000}) : {PCPF[63:3], 3'b000};
        end
    endgenerate
    // For now, we always read since the cache doesn't actually cache

    always_comb if (LastReadDataValidF & (InstrPAdrF == LastReadAdrF)) begin
        assign InstrReadF = 0;
    end else begin
        assign InstrReadF = 1;
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
    assign ICacheStallF = 0; //DelayF & ~DelaySideF;

    // Detect if the instruction is compressed
    assign CompressedF = (DelaySideF & DelayF) ? (MisalignedHalfInstrD[1:0] != 2'b11) : (InstrF[1:0] != 2'b11);

    // Pick the correct output, depending on whether we have to assemble this
    // instruction from two reads or not.
    // Output the requested instruction (we don't need to worry if the read is
    // incomplete, since the pipeline stalls for us when it isn't), or a NOP for
    // the cycle when the first of two reads comes in.
    always_comb if (FlushDLastCycle) begin
        assign InstrDMuxChoice = 2'b10;
    end else if (DelayD & (MisalignedHalfInstrD[1:0] != 2'b11)) begin
        assign InstrDMuxChoice = 2'b11;
    end else begin
        assign InstrDMuxChoice = {1'b0, DelaySideF};
    end
    mux4 #(32) instrDMux (AlignedInstrD, {InstrInF[15:0], MisalignedHalfInstrD}, nop, {16'b0, MisalignedHalfInstrD}, InstrDMuxChoice, InstrRawD);
endmodule
