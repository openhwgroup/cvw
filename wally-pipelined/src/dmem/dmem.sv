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
  input  logic             StallW, FlushW,
  //output logic             DataStall,
  // Memory Stage
  input  logic [1:0]       MemRWM,
  input  logic [`XLEN-1:0] MemAdrM,
  input  logic [2:0]       Funct3M,
  //input  logic [`XLEN-1:0] ReadDataW,
  input  logic [`XLEN-1:0] WriteDataM, 
  input  logic [1:0]       AtomicM,
  output logic [`XLEN-1:0] MemPAdrM,
  output logic             MemReadM, MemWriteM,
  output logic             DataMisalignedM,
  // Writeback Stage
  input  logic             MemAckW,
  input  logic [`XLEN-1:0] ReadDataW,
  output logic             SquashSCW,
  // faults
  input  logic             DataAccessFaultM,
  output logic             LoadMisalignedFaultM, LoadAccessFaultM,
  output logic             StoreMisalignedFaultM, StoreAccessFaultM,
  // TLB management
  input logic  [1:0]       PrivilegeModeW,
  input logic  [`XLEN-1:0] PageTableEntryM,
  input logic  [`XLEN-1:0] SATP_REGW,
  input logic              DTLBWriteM, // DTLBFlushM,
  output logic             DTLBMissM, DTLBHitM
);

  logic             MemAccessM;  // Whether memory needs to be accessed
  logic             SquashSCM;

  // *** temporary hack until walker is hooked up -- Thomas F
  // logic  [`XLEN-1:0] PageTableEntryM = '0;
  logic DTLBFlushM = '0;
  // logic DTLBWriteM = '0;
  tlb #(3) dtlb(clk, reset, SATP_REGW, PrivilegeModeW, MemAccessM, MemAdrM, PageTableEntryM, DTLBWriteM,
    DTLBFlushM, MemPAdrM, DTLBMissM, DTLBHitM);

	// Determine if an Unaligned access is taking place
	always_comb
		case(Funct3M[1:0]) 
		  2'b00:  DataMisalignedM = 0;                       // lb, sb, lbu
		  2'b01:  DataMisalignedM = MemAdrM[0];              // lh, sh, lhu
		  2'b10:  DataMisalignedM = MemAdrM[1] | MemAdrM[0]; // lw, sw, flw, fsw, lwu
		  2'b11:  DataMisalignedM = |MemAdrM[2:0];           // ld, sd, fld, fsd
		endcase 

  // Squash unaligned data accesses and failed store conditionals
  // *** this is also the place to squash if the cache is hit
  assign MemReadM = MemRWM[1] & ~DataMisalignedM;
  assign MemWriteM = MemRWM[0] & ~DataMisalignedM && ~SquashSCM;
  assign MemAccessM = |MemRWM;

  // Determine if address is valid
  assign LoadMisalignedFaultM = DataMisalignedM & MemRWM[1];
  assign LoadAccessFaultM = DataAccessFaultM & MemRWM[1];
  assign StoreMisalignedFaultM = DataMisalignedM & MemRWM[0];
  assign StoreAccessFaultM = DataAccessFaultM & MemRWM[0];

  // Handle atomic load reserved / store conditional
  generate
    if (`A_SUPPORTED) begin // atomic instructions supported
      logic [`XLEN-1:2] ReservationPAdrW;
      logic             ReservationValidM, ReservationValidW; 
      logic             lrM, scM, WriteAdrMatchM;

      assign lrM = MemReadM && AtomicM[0];
      assign scM = MemRWM[0] && AtomicM[0]; 
      assign WriteAdrMatchM = MemRWM[0] && (MemPAdrM[`XLEN-1:2] == ReservationPAdrW) && ReservationValidW;
      assign SquashSCM = scM && ~WriteAdrMatchM;
      always_comb begin // ReservationValidM (next value of valid reservation)
        if (lrM) ReservationValidM = 1;  // set valid on load reserve
        else if (scM || WriteAdrMatchM) ReservationValidM = 0; // clear valid on store to same address or any sc
        else ReservationValidM = ReservationValidW; // otherwise don't change valid
      end
      flopenrc #(`XLEN-2) resadrreg(clk, reset, FlushW, ~StallW && lrM, MemPAdrM[`XLEN-1:2], ReservationPAdrW); // could drop clear on this one but not valid
      flopenrc #(1) resvldreg(clk, reset, FlushW, ~StallW, ReservationValidM, ReservationValidW);
      flopenrc #(1) squashreg(clk, reset, FlushW, ~StallW, SquashSCM, SquashSCW);
    end else begin // Atomic operations not supported
      assign SquashSCM = 0;
      assign SquashSCW = 0; 
    end
  endgenerate

  // Data stall
  //assign DataStall = 0;

endmodule

