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
  input logic                 DataDAPageFaultM,
  input logic                 TrapM,
  input logic                 DCacheStallM,
  input logic [`XLEN-1:0]     SATP_REGW, // from csr
  input logic                 STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input logic [1:0]           STATUS_MPP,
  input logic [1:0]           PrivilegeModeW,
  input logic [`XLEN-1:0]     PCF,
  input logic [`XLEN-1:0]     ReadDataM,
  input logic [2:0]           Funct3M,
  output logic [2:0]          LSUFunct3M,
  input logic [6:0]           Funct7M,
  output logic [6:0]          LSUFunct7M,
  input logic [`XLEN-1:0]     IEUAdrE,
  input logic [`XLEN-1:0]     IEUAdrM,
  output logic [`XLEN-1:0]    PTE,
  output logic [1:0]          PageType,
  output logic [1:0]          PreLSURWM,
  output logic [1:0]          LSUAtomicM,
  output logic [11:0]         LSUAdrE,
  output logic [`PA_BITS-1:0] PreLSUPAdrM,
  input logic [`XLEN+1:0]     IEUAdrExtM,
                  
  output logic                InterlockStall,
  output logic                CPUBusy,
  output logic                SelHPTW,
  output logic                IgnoreRequestTLB, 
  output logic                IgnoreRequestTrapM);


  logic                       AnyCPUReqM;
  logic [`PA_BITS-1:0]        HPTWAdr;
  logic                       HPTWRead;
  logic [2:0]                 HPTWSize;
  logic                       SelReplayCPURequest;
  logic [11:0]                PreLSUAdrE;  
  logic                       ITLBMissOrDAFaultF;
  logic                       DTLBMissOrDAFaultM;  
  logic                       HPTWWrite;

  assign AnyCPUReqM = (|MemRWM) | (|AtomicM);
  assign ITLBMissOrDAFaultF = ITLBMissF | InstrDAPageFaultF;
  assign DTLBMissOrDAFaultM = DTLBMissM | DataDAPageFaultM;  
  interlockfsm interlockfsm (
    .clk, .reset, .AnyCPUReqM, .ITLBMissOrDAFaultF, .ITLBWriteF,
    .DTLBMissOrDAFaultM, .DTLBWriteM, .TrapM, .DCacheStallM,
    .InterlockStall, .SelReplayCPURequest, .SelHPTW, .IgnoreRequestTLB, .IgnoreRequestTrapM);
  hptw hptw( // *** remove logic from (), mention this in style guide CH3
    .clk, .reset, .SATP_REGW, .PCF, .IEUAdrM, .MemRWM, .AtomicM,
    .STATUS_MXR, .STATUS_SUM, .STATUS_MPRV, .STATUS_MPP, .PrivilegeModeW,
    .ITLBMissF(ITLBMissOrDAFaultF & ~TrapM), .DTLBMissM(DTLBMissOrDAFaultM & ~TrapM), // *** Fix me.
    .PTE, .PageType, .ITLBWriteF, .DTLBWriteM, .HPTWReadPTE(ReadDataM),
    .DCacheStallM, .HPTWAdr, .HPTWRead, .HPTWWrite, .HPTWSize);

  // multiplex the outputs to LSU
  mux2 #(2) rwmux(MemRWM, {HPTWRead, HPTWWrite}, SelHPTW, PreLSURWM);
  mux2 #(3) sizemux(Funct3M, HPTWSize, SelHPTW, LSUFunct3M);
  mux2 #(7) funct7mux(Funct7M, 7'b0, SelHPTW, LSUFunct7M);    
  mux2 #(2) atomicmux(AtomicM, 2'b00, SelHPTW, LSUAtomicM);
  mux2 #(12) adremux(IEUAdrE[11:0], HPTWAdr[11:0], SelHPTW, PreLSUAdrE);
  mux2 #(12) replaymux(PreLSUAdrE, IEUAdrM[11:0], SelReplayCPURequest, LSUAdrE); // replay cpu request after hptw.
  mux2 #(`PA_BITS) lsupadrmux(IEUAdrExtM[`PA_BITS-1:0], HPTWAdr, SelHPTW, PreLSUPAdrM);

  // always block interrupts when using the hardware page table walker.
  assign CPUBusy = StallW & ~SelHPTW;
endmodule
