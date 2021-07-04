///////////////////////////////////////////
// lsu.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Load/Store Unit 
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

// *** Ross Thompson amo misalignment check?
module lsu (
  input logic 		      clk, reset,
  input logic 		      StallM, FlushM, StallW, FlushW,
  output logic 		      DataStall,
  output logic 		      HPTWReady,
  // Memory Stage

  // connected to cpu (controls)
  input logic [1:0] 	      MemRWM,
  input logic [2:0] 	      Funct3M,
  input logic [1:0] 	      AtomicM,
  output logic 		      CommittedM, 
  output logic 		      SquashSCW,
  output logic 		      DataMisalignedM,

  // address and write data
  input logic [`XLEN-1:0]     MemAdrM,
  input logic [`XLEN-1:0]     WriteDataM, 
  output logic [`XLEN-1:0]    ReadDataW,

  // cpu privilege
  input logic [1:0] 	      PrivilegeModeW,
  input logic 		      DTLBFlushM,
  // faults
  input logic 		      NonBusTrapM, 
  output logic 		      DTLBLoadPageFaultM, DTLBStorePageFaultM,
  output logic 		      LoadMisalignedFaultM, LoadAccessFaultM,
  // cpu hazard unit (trap)
  output logic 		      StoreMisalignedFaultM, StoreAccessFaultM,

  // connect to ahb
  input logic 		      CommitM, // should this be generated in the abh interface?
  output logic [`PA_BITS-1:0] MemPAdrM, // to ahb
  output logic 		      MemReadM, MemWriteM,
  output logic [1:0] 	      AtomicMaskedM,
  input logic 		      MemAckW, // from ahb
  input logic [`XLEN-1:0]     HRDATAW, // from ahb
  output logic [2:0] 	      Funct3MfromLSU,
	    output logic StallWfromLSU,


  // mmu management

  // page table walker
  input logic [`XLEN-1:0]     PageTableEntryM,
  input logic [1:0] 	      PageTypeM,
  input logic [`XLEN-1:0]     SATP_REGW, // from csr
  input logic              STATUS_MXR, STATUS_SUM, STATUS_MPRV,
  input logic  [1:0]       STATUS_MPP,
  input logic 		      DTLBWriteM,
  output logic 		      DTLBMissM,
  input logic 		      DisableTranslation, // used to stop intermediate PTE physical addresses being saved to TLB.



  output logic 		      DTLBHitM, // not connected 
  
  // PMA/PMP (inside mmu) signals
  input  logic [31:0]      HADDR, // *** replace all of these H inputs with physical adress once pma checkers have been edited to use paddr as well.
  input  logic [2:0]       HSIZE, HBURST,
  input  logic             HWRITE,
  input  var logic [7:0]   PMPCFG_ARRAY_REGW[`PMP_ENTRIES-1:0],
  input  var logic [`XLEN-1:0] PMPADDR_ARRAY_REGW[`PMP_ENTRIES-1:0], // *** this one especially has a large note attached to it in pmpchecker.

  output  logic            PMALoadAccessFaultM, PMAStoreAccessFaultM,
  output  logic            PMPLoadAccessFaultM, PMPStoreAccessFaultM, // *** can these be parameterized? we dont need the m stage ones for the immu and vice versa.
  
  output logic 		      DSquashBusAccessM
//  output logic [5:0]       DHSELRegionsM
  
);

  logic SquashSCM;
  logic DTLBPageFaultM;
  logic MemAccessM;

  logic preCommittedM;

  typedef enum {STATE_READY,
		STATE_FETCH,
		STATE_FETCH_AMO_1,
		STATE_FETCH_AMO_2,
		STATE_STALLED,
		STATE_PTW_READY,
		STATE_PTW_FETCH,
		STATE_PTW_DONE} statetype;
  statetype CurrState, NextState;
		

  logic PMPInstrAccessFaultF, PMAInstrAccessFaultF; // *** these are just so that the mmu has somewhere to put these outputs since they aren't used in dmem
  // *** if you're allowed to parameterize outputs/ inputs existence, these are an easy delete.

  // for time being until we have a dcache the AHB Lite read bus HRDATAW will be connected to the
  // CPU's read data input ReadDataW.
  assign ReadDataW = HRDATAW;
    
  mmu #(.ENTRY_BITS(`DTLB_ENTRY_BITS), .IMMU(0))
  dmmu(.TLBAccessType(MemRWM),
       .VirtualAddress(MemAdrM),
       .Size(Funct3M[1:0]),
       .PTEWriteVal(PageTableEntryM),
       .PageTypeWriteVal(PageTypeM),
       .TLBWrite(DTLBWriteM),
       .TLBFlush(DTLBFlushM),
       .PhysicalAddress(MemPAdrM),
       .TLBMiss(DTLBMissM),
       .TLBHit(DTLBHitM),
       .TLBPageFault(DTLBPageFaultM),
       .ExecuteAccessF(1'b0),
       .AtomicAccessM(AtomicMaskedM[1]), 
       .WriteAccessM(MemRWM[0]),
       .ReadAccessM(MemRWM[1]),
       .SquashBusAccess(DSquashBusAccessM),
//       .SelRegions(DHSELRegionsM),
       .*); // *** the pma/pmp instruction acess faults don't really matter here. is it possible to parameterize which outputs exist?

  // Specify which type of page fault is occurring
  assign DTLBLoadPageFaultM = DTLBPageFaultM & MemRWM[1];
  assign DTLBStorePageFaultM = DTLBPageFaultM & MemRWM[0];

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
  // Changed DataMisalignedM to a larger combination of trap sources
  // NonBusTrapM is anything that the bus doesn't contribute to producing 
  // By contrast, using TrapM results in circular logic errors
  assign MemReadM = MemRWM[1] & ~NonBusTrapM & ~DTLBMissM & CurrState != STATE_STALLED;
  assign MemWriteM = MemRWM[0] & ~NonBusTrapM & ~DTLBMissM & ~SquashSCM & CurrState != STATE_STALLED;
  assign AtomicMaskedM = CurrState != STATE_STALLED ? AtomicM : 2'b00 ;
  assign MemAccessM = MemReadM | MemWriteM;

  // Determine if M stage committed
  // Reset whenever unstalled. Set when access successfully occurs
  flopr #(1) committedMreg(clk,reset,(CommittedM | CommitM) & StallM,preCommittedM);
  assign CommittedM = preCommittedM | CommitM;

  // Determine if address is valid
  assign LoadMisalignedFaultM = DataMisalignedM & MemRWM[1];
  assign LoadAccessFaultM = MemRWM[1];
  assign StoreMisalignedFaultM = DataMisalignedM & MemRWM[0];
  assign StoreAccessFaultM = MemRWM[0];

  // Handle atomic load reserved / store conditional
  generate
    if (`A_SUPPORTED) begin // atomic instructions supported
      logic [`PA_BITS-1:2] ReservationPAdrW;
      logic             ReservationValidM, ReservationValidW; 
      logic             lrM, scM, WriteAdrMatchM;

      assign lrM = MemReadM && AtomicM[0];
      assign scM = MemRWM[0] && AtomicM[0]; 
      assign WriteAdrMatchM = MemRWM[0] && (MemPAdrM[`PA_BITS-1:2] == ReservationPAdrW) && ReservationValidW;
      assign SquashSCM = scM && ~WriteAdrMatchM;
      always_comb begin // ReservationValidM (next value of valid reservation)
        if (lrM) ReservationValidM = 1;  // set valid on load reserve
        else if (scM || WriteAdrMatchM) ReservationValidM = 0; // clear valid on store to same address or any sc
        else ReservationValidM = ReservationValidW; // otherwise don't change valid
      end
      flopenrc #(`PA_BITS-2) resadrreg(clk, reset, FlushW, lrM, MemPAdrM[`PA_BITS-1:2], ReservationPAdrW); // could drop clear on this one but not valid
      flopenrc #(1) resvldreg(clk, reset, FlushW, lrM, ReservationValidM, ReservationValidW);
      flopenrc #(1) squashreg(clk, reset, FlushW, ~StallW, SquashSCM, SquashSCW);
    end else begin // Atomic operations not supported
      assign SquashSCM = 0;
      assign SquashSCW = 0; 
    end
  endgenerate

  // Data stall
  //assign DataStall = (NextState == STATE_FETCH) || (NextState == STATE_FETCH_AMO_1) || (NextState == STATE_FETCH_AMO_2);
  assign HPTWReady = (CurrState == STATE_READY);
  

  // Ross Thompson April 22, 2021
  // for now we need to handle the issue where the data memory interface repeately
  // requests data from memory rather than issuing a single request.


  flopenl #(.TYPE(statetype)) stateReg(.clk(clk),
				       .load(reset),
				       .en(1'b1),
				       .d(NextState),
				       .val(STATE_READY),
				       .q(CurrState));

  always_comb begin
    case (CurrState)
      STATE_READY:
	if (DTLBMissM) begin
	  NextState = STATE_PTW_READY;
	  DataStall = 1'b1;
	end else if (AtomicMaskedM[1]) begin 
	  NextState = STATE_FETCH_AMO_1; // *** should be some misalign check
	  DataStall = 1'b1;
	end else if((MemReadM & AtomicM[0]) | (MemWriteM & AtomicM[0])) begin
	  NextState = STATE_FETCH_AMO_2; 
	  DataStall = 1'b1;
	end else if (MemAccessM & ~DataMisalignedM) begin
	  NextState = STATE_FETCH;
	  DataStall = 1'b1;
	end else begin
          NextState = STATE_READY;
	  DataStall = 1'b0;
	end
      STATE_FETCH_AMO_1: begin
	DataStall = 1'b1;
	if (MemAckW) begin
	  NextState = STATE_FETCH_AMO_2;
	end else begin 
	  NextState = STATE_FETCH_AMO_1;
	end
      end
      STATE_FETCH_AMO_2: begin
	DataStall = 1'b1;	
	if (MemAckW & ~StallW) begin
	  NextState = STATE_FETCH_AMO_2;
	end else if (MemAckW & StallW) begin
          NextState = STATE_STALLED;
	end else begin
	  NextState = STATE_FETCH_AMO_2;
	end
      end
      STATE_FETCH: begin
	  DataStall = 1'b1;
	if (MemAckW & ~StallW) begin
	  NextState = STATE_READY;
	end else if (MemAckW & StallW) begin
	  NextState = STATE_STALLED;
	end else begin
	  NextState = STATE_FETCH;
	end
      end
      STATE_STALLED: begin
	DataStall = 1'b0;
	if (~StallW) begin
	  NextState = STATE_READY;
	end else begin
	  NextState = STATE_STALLED;
	end
      end
      STATE_PTW_READY: begin
	DataStall = 1'b0;
	if (DTLBWriteM) begin
	  NextState = STATE_READY;
	end else if (MemReadM & ~DataMisalignedM) begin
	  NextState = STATE_PTW_FETCH;
	end else begin
	  NextState = STATE_PTW_READY;
	end
      end
      STATE_PTW_FETCH : begin
	DataStall = 1'b1;
	if (MemAckW & ~DTLBWriteM) begin
	  NextState = STATE_PTW_READY;
	end else if (MemAckW & DTLBWriteM) begin
	  NextState = STATE_READY;
	end else begin
	  NextState = STATE_PTW_FETCH;
	end
      end
      STATE_PTW_DONE: begin
	NextState = STATE_READY;
      end
      default: begin
	DataStall = 1'b0;
	NextState = STATE_READY;
      end
    endcase
  end // always_comb

  // *** for now just pass through size
  assign Funct3MfromLSU = Funct3M;
  assign StallWfromLSU = StallW;
  

endmodule

