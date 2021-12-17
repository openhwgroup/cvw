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
   (* mark_debug = "true" *) input logic 		       ITLBMissF, DTLBMissM, // TLB Miss
   input logic [1:0] 	       MemRWM, // 10 = read, 01 = write
   input logic [`XLEN-1:0]     HPTWReadPTE, // page table entry from LSU
   input logic 		       DCacheStall, // stall from LSU
   input logic 		       MemAfterIWalkDone,
   input logic 		       AnyCPUReqM,
   output logic [`XLEN-1:0]    PTE, // page table entry to TLBs
   output logic [1:0] 	       PageType, // page type to TLBs
   (* mark_debug = "true" *) output logic 	       ITLBWriteF, DTLBWriteM, // write TLB with new entry
   output logic 	       SelPTW, // LSU Arbiter should select signals from the PTW rather than from the IEU
   output logic            HPTWStall,
   output logic [`PA_BITS-1:0] TranslationPAdr,
   output logic 	       HPTWRead, // HPTW requesting to read memory
   output logic 	       WalkerInstrPageFaultF, WalkerLoadPageFaultM,WalkerStorePageFaultM // faults
);

      typedef enum  {L0_ADR, L0_RD, 
				     L1_ADR, L1_RD, 
				     L2_ADR, L2_RD, 
				     L3_ADR, L3_RD, 
				     LEAF, LEAF_DELAY, IDLE, FAULT} statetype; // *** placed outside generate statement to remove synthesis errors

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
      
	  (* mark_debug = "true" *)      statetype WalkerState, NextWalkerState, InitialWalkerState;

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
	  assign PRegEn = HPTWRead & ~DCacheStall;
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
	  assign HPTWRead = (WalkerState == L3_RD) | (WalkerState == L2_RD) | (WalkerState == L1_RD) | (WalkerState == L0_RD);
	  assign SelPTW = (WalkerState != IDLE) & (WalkerState != FAULT) & (WalkerState != LEAF) & (WalkerState != LEAF_DELAY);
	  assign HPTWStall = (WalkerState != IDLE) & (WalkerState != FAULT);
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
			L3_RD:  NextPageType = 2'b11; // terapage
			L2_RD:  NextPageType = 2'b10; // gigapage
			L1_RD:  NextPageType = 2'b01; // megapage
			L0_RD:  NextPageType = 2'b00; // kilopage
			default: NextPageType = PageType;
		endcase

	  // TranslationPAdr muxing
	  if (`XLEN==32) begin // RV32
		logic [9:0] VPN;
		logic [`PPN_BITS-1:0] PPN;
		assign VPN = ((WalkerState == L1_ADR) | (WalkerState == L1_RD)) ? TranslationVAdr[31:22] : TranslationVAdr[21:12]; // select VPN field based on HPTW state
		assign PPN = ((WalkerState == L1_ADR) | (WalkerState == L1_RD)) ? BasePageTablePPN : CurrentPPN; 
		assign TranslationPAdr = {PPN, VPN, 2'b00}; 
	  end else begin // RV64
		logic [8:0] VPN;
		logic [`PPN_BITS-1:0] PPN;
		always_comb
			case (WalkerState) // select VPN field based on HPTW state
				L3_ADR, L3_RD:  			VPN = TranslationVAdr[47:39];
				L2_ADR, L2_RD:    VPN = TranslationVAdr[38:30];
				L1_ADR, L1_RD: 	VPN = TranslationVAdr[29:21];
				default:		 						VPN = TranslationVAdr[20:12];
			endcase
		assign PPN = ((WalkerState == L3_ADR) | (WalkerState == L3_RD) | 
		              (SvMode != `SV48 & ((WalkerState == L2_ADR) | (WalkerState == L2_RD)))) ? BasePageTablePPN : CurrentPPN;
		assign TranslationPAdr = {PPN, VPN, 3'b000}; 
	  end

	  // Initial state and misalignment for RV32/64
	  if (`XLEN == 32) begin
		assign InitialWalkerState = L1_ADR;
		assign MegapageMisaligned = |(CurrentPPN[9:0]); // must have zero PPN0
	     // *** Possible bug - should be L1_ADR?
		assign Misaligned = ((WalkerState == L0_ADR) & MegapageMisaligned);
	  end else begin
		logic  GigapageMisaligned, TerapageMisaligned;
		assign InitialWalkerState = (SvMode == `SV48) ? L3_ADR : L2_ADR;
		assign TerapageMisaligned = |(CurrentPPN[26:0]); // must have zero PPN2, PPN1, PPN0
		assign GigapageMisaligned = |(CurrentPPN[17:0]); // must have zero PPN1 and PPN0
		assign MegapageMisaligned = |(CurrentPPN[8:0]); // must have zero PPN0		  
		assign Misaligned = ((WalkerState == L2_ADR) & TerapageMisaligned) | ((WalkerState == L1_ADR) & GigapageMisaligned) | ((WalkerState == L0_ADR) & MegapageMisaligned);
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
	    L3_ADR: 			NextWalkerState = L3_RD; // first access in SV48
	    L3_RD: if (DCacheStall) NextWalkerState = L3_RD;
	                else 			NextWalkerState = L2_ADR;
//	    LEVEL3: if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF;
//		  		else if (ValidNonLeafPTE) NextWalkerState = L2_ADR;
//		 		else 				NextWalkerState = FAULT;
	    L2_ADR: if (InitialWalkerState == L2_ADR) NextWalkerState = L2_RD; // first access in SV39
				else if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF; // could shortcut this by a cyle for all Lx_ADR superpages
		  		else if (ValidNonLeafPTE) NextWalkerState = L2_RD;
		 		else 				NextWalkerState = FAULT;			
	    L2_RD: if (DCacheStall) NextWalkerState = L2_RD;
	      			else 			NextWalkerState = L1_ADR;
//	    LEVEL2: if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF;
//				else if (ValidNonLeafPTE) NextWalkerState = L1_ADR;
//				else 				NextWalkerState = FAULT;
	    L1_ADR: if (InitialWalkerState == L1_ADR) NextWalkerState = L1_RD; // first access in SV32
				else if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF; // could shortcut this by a cyle for all Lx_ADR superpages
		  		else if (ValidNonLeafPTE) NextWalkerState = L1_RD;
		 		else 				NextWalkerState = FAULT;	
	    L1_RD: if (DCacheStall) NextWalkerState = L1_RD;
	      			else 			NextWalkerState = L0_ADR;
//	    LEVEL1: if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF;
//	      		else if (ValidNonLeafPTE) NextWalkerState = L0_ADR;
//				else 				NextWalkerState = FAULT;
	    L0_ADR: if (ValidLeafPTE && ~Misaligned) NextWalkerState = LEAF; // could shortcut this by a cyle for all Lx_ADR superpages
		  		else if (ValidNonLeafPTE) NextWalkerState = L0_RD;
		 		else 				NextWalkerState = FAULT;
	    L0_RD: if (DCacheStall) NextWalkerState = L0_RD;
	      			else 			NextWalkerState = LEAF;
//	    LEVEL0: if (ValidLeafPTE) 	NextWalkerState = LEAF;
//				else 				NextWalkerState = FAULT;
	    LEAF: 	if (DTLBWalk)		NextWalkerState = IDLE; // updates TLB
		        else                NextWalkerState = LEAF_DELAY;
	    LEAF_DELAY: 				NextWalkerState = IDLE;		 // give time to allow address translation
	    FAULT: if (ITLBMissF & AnyCPUReqM & ~MemAfterIWalkDone) NextWalkerState = FAULT;
 	                        else NextWalkerState = IDLE;
	    default: begin
	      // synthesis translate_off
	      $error("Default state in HPTW should be unreachable");
	      // synthesis translate_on
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
