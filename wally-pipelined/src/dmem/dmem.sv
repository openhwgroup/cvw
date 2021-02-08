///////////////////////////////////////////
// dmem.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Data memory
//          Top level of the memory-stage hart logic
//          Contains data cache, DTLB, subword read/write datapath, interface to external bus
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

module dmem (
  input  logic             clk, reset,
  input  logic             FlushW,
  //output logic             DataStall,
  // Memory Stage
  input  logic [1:0]       MemRWM,
  input  logic [`XLEN-1:0] MemAdrM,
  input  logic [2:0]       Funct3M,
  //input  logic [`XLEN-1:0] ReadDataW,
  input  logic [`XLEN-1:0] WriteDataM, 
  output logic [`XLEN-1:0] MemPAdrM,
  output logic             MemReadM, MemWriteM,
  output logic             DataMisalignedM,
  // Writeback Stage
  input  logic             MemAckW,
  input  logic [`XLEN-1:0] ReadDataW,
  // faults
  input  logic             DataAccessFaultM,
  output logic             LoadMisalignedFaultM, LoadAccessFaultM,
  output logic             StoreMisalignedFaultM, StoreAccessFaultM
);

  // Initially no MMU
  assign MemPAdrM = MemAdrM;

	// Determine if an Unaligned access is taking place
	always_comb
		case(Funct3M[1:0]) 
		  2'b00:  DataMisalignedM = 0;                 // lb, sb, lbu
		  2'b01:  DataMisalignedM = MemAdrM[0];           // lh, sh, lhu
		  2'b10:  DataMisalignedM = MemAdrM[1] | MemAdrM[0]; // lw, sw, flw, fsw, lwu
		  2'b11:  DataMisalignedM = |MemAdrM[2:0];        // ld, sd, fld, fsd
		endcase 

  // Squash unaligned data accesses
  // *** this is also the place to squash if the cache is hit
  assign MemReadM = MemRWM[1] & ~DataMisalignedM;
  assign MemWriteM = MemRWM[0] & ~DataMisalignedM;
//  assign MemRWAlignedM = MemRWM & {2{~DataMisalignedM}};

  // Determine if address is valid
  assign LoadMisalignedFaultM = DataMisalignedM & MemRWM[1];
  assign LoadAccessFaultM = DataAccessFaultM & MemRWM[0];
  assign StoreMisalignedFaultM = DataMisalignedM & MemRWM[0];
  assign StoreAccessFaultM = DataAccessFaultM & MemRWM[0];

  // Data stall
  //assign DataStall = 0;

endmodule

