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
  (input logic clk, reset,

   // signals from page table walker
  output  logic [`XLEN-1:0] MMUReadPTE,
  input logic             MMUTranslate,   // *** rename to HPTWReq
  output  logic             MMUReady,
  input logic [`XLEN-1:0] MMUPAdr,

   // signal from CPU
   input  logic [1:0]       MemRWM,
   input  logic [2:0]       Funct3M,
   input  logic [1:0]       AtomicM,
   // back to CPU   
   output logic             CommittedM,    
   output logic             SquashSCW,
   output logic             DataMisalignedM,

   // to LSU   
   output logic             DisableTranslation,   
   output logic [1:0]       MemRWMtoLSU,
   output logic [2:0]       Funct3MtoLSU,
   output logic [1:0]       AtomicMtoLSU,


	      
endmodule
