///////////////////////////////////////////
// lsuvirtmem.sv
//
// Written: Ross Thompson ross1728@gmail.com January 30, 2022
// Modified: 
//
// Purpose: Encapsulates the hptw and muxes required to support virtual memory.
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module lsuvirtmem(
  input logic                 clk, reset, StallW,
  input logic [1:0]           MemRWM,
  input logic [1:0]           AtomicM,
  input logic                 ITLBMissF,
  output logic                ITLBWriteF,
  input logic                 DTLBMissM,
  output logic                DTLBWriteM,
  input logic                 InstrDAPageFaultF,
  output logic                SelReplay,
  input logic                 DataDAPageFaultM,
  input logic                 TrapM,
  input logic                 DCacheStallM,
  input logic [`XLEN-1:0]     SATP_REGW, // from csr
  input logic                 STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input logic [1:0]           STATUS_MPP,
  input logic [1:0]           PrivilegeModeW,
  input logic [`XLEN-1:0]     PCF,
  input logic [`XLEN-1:0]     ReadDataM,
  input logic [`XLEN-1:0]     WriteDataM,
  input logic [2:0]           Funct3M,
  output logic [2:0]          LSUFunct3M,
  input logic [6:0]           Funct7M,
  output logic [6:0]          LSUFunct7M,
  output logic [`XLEN-1:0]    PTE,
  output logic [`XLEN-1:0]    IMWriteDataM,
  output logic [1:0]          PageType,
  output logic [1:0]          PreLSURWM,
  output logic [1:0]          LSUAtomicM,
  output logic [`XLEN+1:0] IHAdrM,
  input logic [`XLEN+1:0]     IEUAdrExtM, // *** can move internally.
                  
  output logic                InterlockStall,
  output logic                CPUBusy,
  output logic                SelHPTW,
  output logic                IgnoreRequestTLB);


  logic                       AnyCPUReqM;
  logic [`PA_BITS-1:0]        HPTWAdr;
  logic [`XLEN+1:0]           HPTWAdrExt;
  logic [1:0]                 HPTWRW;
  logic [2:0]                 HPTWSize;
  logic                       SelReplayMemE;
  logic                       ITLBMissOrDAFaultF, ITLBMissOrDAFaultNoTrapF;
  logic                       DTLBMissOrDAFaultM, DTLBMissOrDAFaultNoTrapM;
  logic                       SelHPTWAdr;
  
  assign ITLBMissOrDAFaultF = ITLBMissF | (`HPTW_WRITES_SUPPORTED & InstrDAPageFaultF);
  assign DTLBMissOrDAFaultM = DTLBMissM | (`HPTW_WRITES_SUPPORTED & DataDAPageFaultM);  
  assign ITLBMissOrDAFaultNoTrapF = ITLBMissOrDAFaultF & ~TrapM;
  assign DTLBMissOrDAFaultNoTrapM = DTLBMissOrDAFaultM & ~TrapM;
  interlockfsm interlockfsm (
    .clk, .reset, .MemRWM, .AtomicM, .ITLBMissOrDAFaultF, .ITLBWriteF,
    .DTLBMissOrDAFaultM, .DTLBWriteM, .TrapM, .DCacheStallM,
    .InterlockStall, .SelReplayMemE, .SelHPTW, .IgnoreRequestTLB);
  hptw hptw( 
    .clk, .reset, .SATP_REGW, .PCF, .IEUAdrExtM, .MemRWM, .AtomicM,
    .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP, .PrivilegeModeW,
    .ITLBMissOrDAFaultNoTrapF, .DTLBMissOrDAFaultNoTrapM,
    .PTE, .PageType, .ITLBWriteF, .DTLBWriteM, .HPTWReadPTE(ReadDataM),  // *** should it be HPTWReadDataM
    .DCacheStallM, .HPTWAdr, .HPTWRW, .HPTWSize);
  // *** possible future optimization of simplifying page table entry with precomputed misalignment (Ross) low priority

  // Once the walk is done and it is time to update the DTLB we need to switch back 
  // to the orignal data virtual address.
  assign SelHPTWAdr = SelHPTW & ~(DTLBWriteM | ITLBWriteF);

  assign SelReplay = SelHPTWAdr | SelReplayMemE;

  // multiplex the outputs to LSU
  if(`XLEN+2-`PA_BITS > 0) begin
    logic [(`XLEN+2-`PA_BITS)-1:0] zeros;
    assign zeros = '0;
    assign HPTWAdrExt = {zeros, HPTWAdr};
  end else assign HPTWAdrExt = HPTWAdr;
  mux2 #(2) rwmux(MemRWM, HPTWRW, SelHPTW, PreLSURWM);
  mux2 #(3) sizemux(Funct3M, HPTWSize, SelHPTW, LSUFunct3M);
  mux2 #(7) funct7mux(Funct7M, 7'b0, SelHPTW, LSUFunct7M);    
  mux2 #(2) atomicmux(AtomicM, 2'b00, SelHPTW, LSUAtomicM);
  mux2 #(`XLEN+2) lsupadrmux(IEUAdrExtM, HPTWAdrExt, SelHPTWAdr, IHAdrM);
  if(`HPTW_WRITES_SUPPORTED)
    mux2 #(`XLEN) lsuwritedatamux(WriteDataM, PTE, SelHPTW, IMWriteDataM);
  else assign IMWriteDataM = WriteDataM;

  // always block interrupts when using the hardware page table walker.
  assign CPUBusy = StallW & ~SelHPTW;
endmodule
