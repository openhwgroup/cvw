///////////////////////////////////////////
// lsuArb.sv
//
// Written: Ross THompson and Kip Macsai-Goren
// Modified: kmacsaigoren@hmc.edu June 23, 2021
//
// Purpose: LSU arbiter between the CPU's demand request for data memory and
//          the page table walker
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

module lsuArb 
  (input  logic clk,

   // from page table walker
   input logic 		       SelPTW,
   input logic 		       HPTWRead,
   input logic [`PA_BITS-1:0]  TranslationPAdrE,

   // from CPU
   input logic [1:0] 	       MemRWM,
   input logic [2:0] 	       Funct3M,
   input logic [1:0] 	       AtomicM,
   input logic [`XLEN-1:0]     IEUAdrM,
   input logic [11:0] 	       IEUAdrE,
   input logic 		       StallW,
   input logic 		       PendingInterruptM,
   // to CPU
   output logic 	       DataMisalignedM,
   output logic 	       CommittedM,
   //output logic 	       LSUStall, 
  
   // to D Cache
   output logic 	       DisableTranslation, 
   output logic [1:0] 	       MemRWMtoLRSC,
   output logic [2:0] 	       Funct3MtoDCache,
   output logic [1:0] 	       AtomicMtoDCache,
   output logic [`PA_BITS-1:0] MemPAdrNoTranslate,   // THis name is very bad. need a better name. This is the raw address from either the ieu or the hptw.
   output logic [11:0] 	       MemAdrE, 
   output logic 	       StallWtoDCache,
   output logic 	       PendingInterruptMtoDCache,
   

   // from D Cache
   input logic 		       CommittedMfromDCache,
   input logic 		       DataMisalignedMfromDCache,
   input logic 		       DCacheStall
  
   );

  logic [2:0] PTWSize;
  logic [`PA_BITS-1:0]  TranslationPAdrM;
  logic [`XLEN+1:0]  IEUAdrMExt;
  
  // multiplex the outputs to LSU
  assign DisableTranslation = SelPTW;  // change names between SelPTW would be confusing in DTLB.
  assign MemRWMtoLRSC = SelPTW ? {HPTWRead, 1'b0} : MemRWM;
  
  generate
    assign PTWSize = (`XLEN==32 ? 3'b010 : 3'b011); // 32 or 64-bit access from htpw
  endgenerate
  mux2 #(3) sizemux(Funct3M, PTWSize, SelPTW, Funct3MtoDCache);

  // this is for the d cache SRAM.
  flop #(`PA_BITS) TranslationPAdrMReg(clk, TranslationPAdrE, TranslationPAdrM);   // delay TranslationPAdrM by a cycle

  assign AtomicMtoDCache = SelPTW ? 2'b00 : AtomicM;
  assign IEUAdrMExt = {2'b00, IEUAdrM};
  assign MemPAdrNoTranslate = SelPTW ? TranslationPAdrM : IEUAdrMExt[`PA_BITS-1:0]; 
  assign MemAdrE = SelPTW ? TranslationPAdrE[11:0] : IEUAdrE[11:0];  
  assign StallWtoDCache = SelPTW ? 1'b0 : StallW;
  // always block interrupts when using the hardware page table walker.
  assign CommittedM = SelPTW ? 1'b1 : CommittedMfromDCache;

  // demux the inputs from LSU to walker or cpu's data port.

  // works without the demux 7/18/21 dh.  Suggest deleting these and removing fromDCache suffix
  assign DataMisalignedM = /*SelPTW ? 1'b0 : */DataMisalignedMfromDCache;
  // *** need to rename DcacheStall and Datastall.
  // not clear at all.  I think it should be LSUStall from the LSU,
  // which is demuxed to HPTWStall and CPUDataStall? (not sure on this last one).
  //assign HPTWStall = SelPTW ? DCacheStall : 1'b1;  

  assign PendingInterruptMtoDCache = SelPTW ? 1'b0 : PendingInterruptM;

  //assign LSUStall = SelPTW ? 1'b1 : DCacheStall; // *** this is probably going to change.
  
endmodule
