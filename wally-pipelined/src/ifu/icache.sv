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

    logic        DelayF, DelaySideF, FlushDLastCycle;
    logic  [1:0] InstrDMuxChoice;
    logic [15:0] MisalignedHalfInstrF, MisalignedHalfInstrD;
    logic [31:0] InstrF, AlignedInstrD;
    logic [31:0] nop = 32'h00000013; // instruction for NOP

    flopr   #(1)  flushDLastCycleFlop(clk, reset, FlushD | (FlushDLastCycle & StallF), FlushDLastCycle);
    flopenr #(1)  delayStateFlop(clk, reset, ~StallF, (DelayF & ~DelaySideF) ? 1'b1 : 1'b0 , DelaySideF);
    flopenr #(16) halfInstrFlop(clk, reset, DelayF & ~StallF, MisalignedHalfInstrF, MisalignedHalfInstrD);

    flopenr #(32) instrFlop(clk, reset, ~StallF, InstrF, AlignedInstrD);

    // Decide which address needs to be fetched and sent out over InstrPAdrF
    // If the requested address fits inside one read from memory, we fetch that
    // address, adjusted to the bit width. Otherwise, we request the lower word
    // and then the upper word, in that order.
    generate
        if (`XLEN == 32) begin
            assign InstrPAdrF = PCPF[1] ? (DelaySideF ? {PCPF[31:2]+1, 2'b00} : {PCPF[31:2], 2'b00}) : PCPF;
        end else begin
            assign InstrPAdrF = PCPF[2] ? (PCPF[1] ? (DelaySideF ? {PCPF[63:3]+1, 3'b000} : {PCPF[63:3], 3'b000}) : {PCPF[63:3], 3'b000}) : {PCPF[63:3], 3'b000};
        end
    endgenerate
    // For now, we always read since the cache doesn't actually cache
    assign InstrReadF = 1;

    // If the instruction fits in one memory read, then we put the right bits
    // into InstrF. Otherwise, we activate DelayF to signal the rest of the
    // machinery to swizzle bits.
    generate
        if (`XLEN == 32) begin
            assign InstrF = PCPF[1] ? {16'b0, InstrInF[31:16]} : InstrInF;
            assign DelayF = PCPF[1];
            assign MisalignedHalfInstrF = InstrInF[31:16];
        end else begin
            assign InstrF = PCPF[2] ? (PCPF[1] ? {16'b0, InstrInF[63:48]}  : InstrInF[63:32]) : (PCPF[1] ? InstrInF[47:16] : InstrInF[31:0]);
            assign DelayF = PCPF[1] && PCPF[2];
            assign MisalignedHalfInstrF = InstrInF[63:48];
        end
    endgenerate
    assign ICacheStallF = DelayF & ~DelaySideF;

    // Detect if the instruction is compressed
    // TODO Low-hanging optimization, don't delay if compressed
    assign CompressedF = DelaySideF ? (MisalignedHalfInstrD[1:0] != 2'b11) : (InstrF[1:0] != 2'b11);

    // Pick the correct output, depending on whether we have to assemble this
    // instruction from two reads or not.
    // Output the requested instruction (we don't need to worry if the read is
    // incomplete, since the pipeline stalls for us when it isn't), or a NOP for
    // the cycle when the first of two reads comes in.
    always_comb
        assign InstrDMuxChoice = FlushDLastCycle ? 2'b10 : (DelayF ? (DelaySideF ? 2'b01 : 2'b10) : 2'b00);
    mux3 #(32) instrDMux (AlignedInstrD, {InstrInF[15:0], MisalignedHalfInstrD}, nop, InstrDMuxChoice, InstrRawD);
endmodule
