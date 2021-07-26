///////////////////////////////////////////
// hptw.sv
//
// Written: tfleming@hmc.edu 2 March 2021
// Modified:  david_harris@hmc.edu 18 July 2021 cleanup and simplification
//            kmacsaigoren@hmc.edu 1 June 2021
//            implemented SV48 on top of SV39. This included, adding a level of the FSM for the extra page number segment
//            adding support for terapage encoding, and for setting the TranslationPAdr using the new level,
//            adding the internal SvMode signal
//
// Purpose: Page Table Walker
//          Part of the Memory Management Unit (MMU)
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

module hptw
  (
   input logic 		       clk, reset,
   input logic [`XLEN-1:0]     SATP_REGW, // includes SATP.MODE to determine number of levels in page table
   input logic [`XLEN-1:0]     PCF, MemAdrM, // addresses to translate
   input logic 		       ITLBMissF, DTLBMissM, // TLB Miss
   input logic [1:0] 	       MemRWM, // 10 = read, 01 = write
   input logic [`XLEN-1:0]     HPTWReadPTE, // page table entry from LSU
   input logic 		       HPTWStall, // stall from LSU
   input logic 		       MemAfterIWalkDone,
   input logic 		       AnyCPUReqM,
   output logic [`XLEN-1:0]    PTE, // page table entry to TLBs
   output logic [1:0] 	       PageType, // page type to TLBs
   output logic 	       ITLBWriteF, DTLBWriteM, // write TLB with new entry
   output logic 	       SelPTW, // LSU Arbiter should select signals from the PTW rather than from the IEU
   output logic [`PA_BITS-1:0] TranslationPAdr,
   output logic 	       HPTWRead, // HPTW requesting to read memory
   output logic 	       WalkerInstrPageFaultF, WalkerLoadPageFaultM,WalkerStorePageFaultM // faults
);

  generate
    if (`MEM_VIRTMEM) begin
      logic			    DTLBWalk; // register TLBs translation miss requests
      logic [`PPN_BITS-1:0]	    BasePageTablePPN;
      logic [`PPN_BITS-1:0]	    CurrentPPN;
      logic			    MemWrite;
      logic			    Executable, Writable, Readable, Valid;
	  logic 			Misaligned, MegapageMisaligned;
      logic			    ValidPTE, LeafPTE, ValidLeafPTE, ValidNonLeafPTE;
      logic			    StartWalk;
 	  logic     		TLBMiss;
      logic			    PRegEn;
	  logic [1:0]       NextPageType;
      logic [`SVMODE_BITS-1:0]	    SvMode;
      logic [`XLEN-1:0] 	    TranslationVAdr;
      

      typedef enum  {LEVEL0_SET_ADR, LEVEL0_READ, LEVEL0,
				     LEVEL1_SET_ADR, LEVEL1_READ, LEVEL1,
				     LEVEL2_SET_ADR, LEVEL2_READ, LEVEL2,
				     LEVEL3_SET_ADR, LEVEL3_READ, LEVEL3,
				     LEAF, IDLE, FAULT} statetype;
      statetype WalkerState, NextWalkerState, InitialWalkerState;

	  // Extract bits from CSRs and inputs
      assign SvMode = SATP_REGW[`XLEN-1:`XLEN-`SVMODE_BITS];
      assign BasePageTablePPN = SATP_REGW[`PPN_BITS-1:0];
      assign MemWrite = MemRWM[0];
	  assign TLBMiss = (DTLBMissM | ITLBMissF);

      // Determine which address to translate
 	  assign TranslationVAdr = DTLBWalk ? MemAdrM : PCF;
      assign CurrentPPN = PTE[`PPN_BITS+9:10];

	  // State flops
 	  flopenr #(1) TLBMissMReg(clk, reset, StartWalk, DTLBMissM, DTLBWalk); // when walk begins, record whether it was for DTLB (or record 0 for ITLB)
	  assign PRegEn = HPTWRead & ~HPTWStall;
  	  flopenr #(`XLEN) PTEReg(clk, reset, PRegEn, HPTWReadPTE, PTE); // Capture page table entry from data cache
	
      // Assign PTE descriptors common across all XLEN values
	  // For non-leaf PTEs, D, A, U bits are reserved and ignored.  They do not cause faults while walking the page table
      assign {Executable, Writable, Readable, Valid} = PTE[3:0]; 
      assign LeafPTE = Executable | Writable | Readable; 
      assign ValidPTE = Valid && ~(Writable && ~Readable);
	  assign ValidLeafPTE = ValidPTE & LeafPTE;
	  assign ValidNonLeafPTE = ValidPTE & ~LeafPTE;
	  
	  // Enable and select signals based on states
      assign StartWalk = (WalkerState == IDLE) & TLBMiss;
	  assign HPTWRead = (WalkerState == LEVEL3_READ) | (WalkerState == LEVEL2_READ) | (WalkerState == LEVEL1_READ) | (WalkerState == LEVEL0_READ);
	  assign SelPTW = (WalkerState != IDLE) & (WalkerState != FAULT) & (WalkerState != LEAF);
	  assign DTLBWriteM = (WalkerState == LEAF) & DTLBWalk;
	  assign ITLBWriteF = (WalkerState == LEAF) & ~DTLBWalk;

	  // Raise faults.  DTLBMiss
	  assign WalkerInstrPageFaultF = (WalkerState == FAULT) & ~DTLBWalk;
	  assign WalkerLoadPageFaultM  = (WalkerState == FAULT) & DTLBWalk & ~MemWrite;
	  assign WalkerStorePageFaultM = (WalkerState == FAULT) & DTLBWalk & MemWrite;

	  // FSM to track PageType based on the levels of the page table traversed
	  flopr #(2) PageTypeReg(clk, reset, NextPageType, PageType);
	  always_comb 
		case (WalkerState)
			LEVEL3:  NextPageType = 2'b11; // terapage
			LEVEL2:  NextPageType = 2'b10; // gigapage
			LEVEL1:  NextPageType = 2'b01; // megapage
			LEVEL0:  NextPageType = 2'b00; // kilopage
			default: NextPageType = PageType;
		endcase

	  // TranslationPAdr muxing
	  if (`XLEN==32) begin // RV32
		logic [9:0] VPN;
		logic [`PPN_BITS-1:0] PPN;
		assign VPN = ((WalkerState == LEVEL1_SET_ADR) | (WalkerState == LEVEL1_READ)) ? TranslationVAdr[31:22] : TranslationVAdr[21:12]; // select VPN field based on HPTW state
		assign PPN = ((WalkerState == LEVEL1_SET_ADR) | (WalkerState == LEVEL1_READ)) ? BasePageTablePPN : CurrentPPN; 
		assign TranslationPAdr = {PPN, VPN, 2'b00}; 
	  end else begin // RV64
		logic [8:0] VPN;
		logic [`PPN_BITS-1:0] PPN;
		always_comb
			case (WalkerState) // select VPN field based on HPTW state
				LEVEL3_SET_ADR, LEVEL3_READ:  			VPN = TranslationVAdr[47:39];
				LEVEL3, LEVEL2_SET_ADR, LEVEL2_READ:    VPN = TranslationVAdr[38:30];
				LEVEL2, LEVEL1_SET_ADR, LEVEL1_READ: 	VPN = TranslationVAdr[29:21];
				default:		 						VPN = TranslationVAdr[20:12];
			endcase
		assign PPN = ((WalkerState == LEVEL3_SET_ADR) | (WalkerState == LEVEL3_READ) | 
		              (SvMode != `SV48 & ((WalkerState == LEVEL2_SET_ADR) | (WalkerState == LEVEL2_READ)))) ? BasePageTablePPN : CurrentPPN;
		assign TranslationPAdr = {PPN, VPN, 3'b000}; 
	  end

	  // Initial state and misalignment for RV32/64
	  if (`XLEN == 32) begin
		assign InitialWalkerState = LEVEL1_SET_ADR;
		assign MegapageMisaligned = |(CurrentPPN[9:0]); // must have zero PPN0
		assign Misaligned = ((WalkerState == LEVEL1) & MegapageMisaligned);
	  end else begin
		logic  GigapageMisaligned, TerapageMisaligned;
		assign InitialWalkerState = (SvMode == `SV48) ? LEVEL3_SET_ADR : LEVEL2_SET_ADR;
		assign TerapageMisaligned = |(CurrentPPN[26:0]); // must have zero PPN2, PPN1, PPN0
		assign GigapageMisaligned = |(CurrentPPN[17:0]); // must have zero PPN1 and PPN0
		assign MegapageMisaligned = |(CurrentPPN[8:0]); // must have zero PPN0		  
		assign Misaligned = ((WalkerState == LEVEL3) & TerapageMisaligned) | ((WalkerState == LEVEL2) & GigapageMisaligned) | ((WalkerState == LEVEL1) & MegapageMisaligned);
 	  end

    // Page Table Walker FSM
	// If the setup time on the D$ RAM is short, it should be possible to merge the LEVELx_READ and LEVELx states
	// to decrease the latency of the HPTW.  However, if the D$ is a cycle limiter, it's better to leave the
	// HPTW as shown below to keep the D$ setup time out of the critical path.
	// *** Is this really true.  Talk with Ross.  Seems like it's the next state logic on critical path instead.
	flopenl #(.TYPE(statetype)) WalkerStateReg(clk, reset, 1'b1, NextWalkerState, IDLE, WalkerState); 
	always_comb 
	  case (WalkerState)
	    IDLE: if (TLBMiss)	 		NextWalkerState = InitialWalkerState;
		      else 					NextWalkerState = IDLE;
	    LEVEL3_SET_ADR: 			NextWalkerState = LEVEL3_READ;
	    LEVEL3_READ: if (HPTWStall) NextWalkerState = LEVEL3_READ;
	                else 			NextWalkerState = LEVEL3;
	    LEVEL3: if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF;
		  		else if (ValidNonLeafPTE) NextWalkerState = LEVEL2_SET_ADR;
		 		else 				NextWalkerState = FAULT;
	    LEVEL2_SET_ADR: 			NextWalkerState = LEVEL2_READ;
	    LEVEL2_READ: if (HPTWStall) NextWalkerState = LEVEL2_READ;
	      			else 			NextWalkerState = LEVEL2;
	    LEVEL2: if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF;
				else if (ValidNonLeafPTE) NextWalkerState = LEVEL1_SET_ADR;
				else 				NextWalkerState = FAULT;
	    LEVEL1_SET_ADR: 			NextWalkerState = LEVEL1_READ;
	    LEVEL1_READ: if (HPTWStall) NextWalkerState = LEVEL1_READ;
	      			else 			NextWalkerState = LEVEL1;
	    LEVEL1: if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF;
	      		else if (ValidNonLeafPTE) NextWalkerState = LEVEL0_SET_ADR;
				else 				NextWalkerState = FAULT;
	    LEVEL0_SET_ADR: 			NextWalkerState = LEVEL0_READ;
	    LEVEL0_READ: if (HPTWStall) NextWalkerState = LEVEL0_READ;
	      			else 			NextWalkerState = LEVEL0;
	    LEVEL0: if (ValidLeafPTE) 	NextWalkerState = LEAF;
				else 				NextWalkerState = FAULT;
	    LEAF: 						NextWalkerState = IDLE;
	    FAULT: if (ITLBMissF & AnyCPUReqM & ~MemAfterIWalkDone) NextWalkerState = FAULT;
 	                        else NextWalkerState = IDLE;
	    default: begin
			$error("Default state in HPTW should be unreachable");
									NextWalkerState = IDLE; // should never be reached
		end
	  endcase
    end else begin // No Virtual memory supported; tie HPTW outputs to 0
      assign HPTWRead = 0; assign SelPTW = 0;
      assign WalkerInstrPageFaultF = 0; assign WalkerLoadPageFaultM = 0; assign WalkerStorePageFaultM = 0;
      assign TranslationPAdr = 0; 
    end
  endgenerate
endmodule
