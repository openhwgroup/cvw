///////////////////////////////////////////
// pagetablewalker.sv
//
// Written: tfleming@hmc.edu 2 March 2021
// Modified: kmacsaigoren@hmc.edu 1 June 2021
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

module pagetablewalker
  (
   // Control signals
   input logic		    clk, reset,
   input logic [`XLEN-1:0]  SATP_REGW,

   // Signals from TLBs (addresses to translate)
   input logic [`XLEN-1:0]  PCF, MemAdrM,
   input logic		    ITLBMissF, DTLBMissM,
   input logic [1:0]	    MemRWM,

   // Outputs to the TLBs (PTEs to write)
   output logic [`XLEN-1:0] PageTableEntryF, PageTableEntryM,
   output logic [1:0]	    PageType,
   output logic		    ITLBWriteF, DTLBWriteM,
   output logic 	    SelPTW,


   // *** modify to send to LSU // *** KMG: These are inputs/results from the ahblite whose addresses should have already been checked, so I don't think they need to be sent through the LSU
   input logic [`XLEN-1:0]  HPTWReadPTE,
   input logic		    MMUReady,
   input logic		    HPTWStall,

   // *** modify to send to LSU
   output logic [`XLEN-1:0] HPTWPAdrE, // this probalby should be `PA_BITS wide
   output logic [`XLEN-1:0] HPTWPAdrM, // this probalby should be `PA_BITS wide
   output logic		    HPTWRead,


   // Faults
   output logic		    WalkerInstrPageFaultF,
   output logic		    WalkerLoadPageFaultM,
   output logic		    WalkerStorePageFaultM
   );


  generate
    if (`MEM_VIRTMEM) begin
      // Internal signals
      // register TLBs translation miss requests
      logic			    ITLBMissFQ, DTLBMissMQ;

      logic [`PPN_BITS-1:0]	    BasePageTablePPN;
      logic [`XLEN-1:0]		    TranslationVAdr;
      logic [`XLEN-1:0]		    CurrentPTE;
      logic [`PA_BITS-1:0]	    TranslationPAdr;
      logic [`PPN_BITS-1:0]	    CurrentPPN;
      logic [`SVMODE_BITS-1:0]	    SvMode;
      logic			    MemStore;
      logic			    Dirty, Accessed, Global, User, Executable, Writable, Readable, Valid;
      logic			    ValidPTE, ADPageFault, MegapageMisaligned, TerapageMisaligned, GigapageMisaligned, BadMegapage, LeafPTE;
      logic			    StartWalk;
      logic			    EndWalk;

      typedef enum  {LEVEL0_SET_ADRE, LEVEL0_WDV, LEVEL0,
				     LEVEL1_SET_ADRE, LEVEL1_WDV, LEVEL1,
				     LEVEL2_SET_ADRE, LEVEL2_WDV, LEVEL2,
				     LEVEL3_SET_ADRE, LEVEL3_WDV, LEVEL3,
				     LEAF, IDLE, FAULT} statetype;

      statetype WalkerState, NextWalkerState, PreviousWalkerState;

      logic			    PRegEn;
      logic			    SelDataTranslation;
      logic			    AnyTLBMissM;

      assign SvMode = SATP_REGW[`XLEN-1:`XLEN-`SVMODE_BITS];
      assign BasePageTablePPN = SATP_REGW[`PPN_BITS-1:0];
      assign MemStore = MemRWM[0];

      // Prefer data address translations over instruction address translations
      assign TranslationVAdr = (SelDataTranslation) ? MemAdrM : PCF;
      assign SelDataTranslation = DTLBMissMQ | DTLBMissM;

      flop #(`XLEN) HPTWPAdrMReg(clk, HPTWPAdrE, HPTWPAdrM);
	  flopenrc #(2) TLBMissMReg(clk, reset, EndWalk, StartWalk | EndWalk, {DTLBMissM, ITLBMissF}, {DTLBMissMQ, ITLBMissFQ});
	  flopenl #(.TYPE(statetype)) WalkerStateReg(clk, reset, 1'b1, NextWalkerState, IDLE, WalkerState);
	  flopenl #(.TYPE(statetype)) PreviousWalkerStateReg(clk, reset, 1'b1, WalkerState, IDLE, PreviousWalkerState);
	  flopenr #(`XLEN) PTEReg(clk, reset, PRegEn, HPTWReadPTE, CurrentPTE); // Capture page table entry from data cache
	  assign CurrentPPN = CurrentPTE[`PPN_BITS+9:10];

      assign AnyTLBMissM = DTLBMissM | ITLBMissF;

      assign StartWalk = (WalkerState == IDLE) & AnyTLBMissM;
      assign EndWalk = (WalkerState == LEAF) || (WalkerState == FAULT);

      // unswizzle PTE bits
      assign {Dirty, Accessed, Global, User,
	      Executable, Writable, Readable, Valid} = CurrentPTE[7:0];

      // Assign PTE descriptors common across all XLEN values
      assign LeafPTE = Executable | Writable | Readable;
      assign ValidPTE = Valid && ~(Writable && ~Readable);
      assign ADPageFault = ~Accessed | (MemStore & ~Dirty);

      // Assign specific outputs to general outputs
	  // *** try to eliminate this duplication, but attempts caused MMU to hang
      assign PageTableEntryF = CurrentPTE;
      assign PageTableEntryM = CurrentPTE;

	  assign SelPTW = (WalkerState != IDLE) & (WalkerState != FAULT);
	  assign DTLBWriteM = (WalkerState == LEAF) & DTLBMissMQ;
	  assign ITLBWriteF = (WalkerState == LEAF) & ~DTLBMissMQ;

	  assign WalkerInstrPageFaultF = (WalkerState == FAULT) & ~DTLBMissMQ; //*** why do these only get raised on TLB misses?  Should they always fault even for ADpagefaults, invalid addresses,etc??
	  assign WalkerLoadPageFaultM  = (WalkerState == FAULT) & DTLBMissMQ & ~MemStore;
	  assign WalkerStorePageFaultM = (WalkerState == FAULT) & DTLBMissMQ & MemStore;

	  always_comb // determine type of page being walked:
		  case (PreviousWalkerState)
			LEVEL3:  PageType = 2'b11; // terapage
			LEVEL2:  PageType = 2'b10; // gigapage
			LEVEL1:  PageType = 2'b01; // megapage
			default: PageType = 2'b00; // kilopage
		  endcase
/*	  assign PageType = (PreviousWalkerState == LEVEL3) ? 2'b11 :  // is
			 ((PreviousWalkerState == LEVEL2) ? 2'b10 :
			  ((PreviousWalkerState == LEVEL1) ? 2'b01 : 2'b00));*/
	  assign PRegEn = (NextWalkerState == LEVEL3) | (NextWalkerState == LEVEL2) | (NextWalkerState == LEVEL1) | (NextWalkerState == LEVEL0);
	  assign HPTWRead = (WalkerState == LEVEL3_WDV) | (WalkerState == LEVEL2_WDV) | (WalkerState == LEVEL1_WDV) | (WalkerState == LEVEL0_WDV); // is this really necessary?

	  // *** is there a way to speed up HPTW?

	  // TranslationPAdr mux
	  if (`XLEN==32) begin
		logic [9:0] VPN1, VPN0;
		assign VPN1 = TranslationVAdr[31:22];
		assign VPN0 = TranslationVAdr[21:12];
		always_comb
		  case (WalkerState)
	    	LEVEL1_SET_ADRE: TranslationPAdr = {BasePageTablePPN, VPN1, 2'b00};
	    	LEVEL1_WDV:      TranslationPAdr = {BasePageTablePPN, VPN1, 2'b00};
			LEVEL1:          if (NextWalkerState == LEAF) TranslationPAdr = {2'b00, TranslationVAdr[31:0]}; // ***check this and similar
			                 else 		TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
			LEVEL0_SET_ADRE: TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
			LEVEL0_WDV: 	 TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
			LEVEL0: 		 TranslationPAdr = {2'b00, TranslationVAdr[31:0]};
			LEAF:			 TranslationPAdr = {2'b00, TranslationVAdr[31:0]};
			default:		 TranslationPAdr = 0; // cause seg fault if this is improperly used
		  endcase
	  end else begin
		logic [8:0] VPN3, VPN2, VPN1, VPN0;
		assign VPN3 = TranslationVAdr[47:39];
		assign VPN2 = TranslationVAdr[38:30];
		assign VPN1 = TranslationVAdr[29:21];
		assign VPN0 = TranslationVAdr[20:12];
		always_comb
		  case (WalkerState)
			LEVEL3_SET_ADRE: TranslationPAdr = {BasePageTablePPN, VPN3, 3'b000};
	    	LEVEL3_WDV:  	 TranslationPAdr = {BasePageTablePPN, VPN3, 3'b000};
	    	LEVEL3:          if (NextWalkerState == LEAF) TranslationPAdr = TranslationVAdr[`PA_BITS-1:0];
			                 else TranslationPAdr = {(SvMode == `SV48) ? CurrentPPN : BasePageTablePPN, VPN2, 3'b000};
			LEVEL2_SET_ADRE: TranslationPAdr = {(SvMode == `SV48) ? CurrentPPN : BasePageTablePPN, VPN2, 3'b000};
			LEVEL2_WDV:  	 TranslationPAdr = {(SvMode == `SV48) ? CurrentPPN : BasePageTablePPN, VPN2, 3'b000};
	   		LEVEL2: 		 if (NextWalkerState == LEAF) TranslationPAdr = TranslationVAdr[`PA_BITS-1:0];
			                 else TranslationPAdr = {CurrentPPN, VPN1, 3'b000};
	      	LEVEL1_SET_ADRE: TranslationPAdr = {CurrentPPN, VPN1, 3'b000};
			LEVEL1_WDV: 	 TranslationPAdr = {CurrentPPN, VPN1, 3'b000};
	     	LEVEL1: 		 if (NextWalkerState == LEAF) TranslationPAdr = TranslationVAdr[`PA_BITS-1:0];
			                 else TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
	    	LEVEL0_SET_ADRE: TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
			LEVEL0_WDV: 	 TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
	  		LEVEL0: 		 TranslationPAdr = TranslationVAdr[`PA_BITS-1:0];
			LEAF:			 TranslationPAdr = TranslationVAdr[`PA_BITS-1:0];
			default: 		 TranslationPAdr = 0; // cause seg fault if this is improperly used
		  endcase 
	  end

	  if (`XLEN == 32) begin
		assign TerapageMisaligned = 0; // not applicable
		assign GigapageMisaligned = 0; // not applicable
		assign MegapageMisaligned = |(CurrentPPN[9:0]); // must have zero PPN0
	  end else begin
		assign TerapageMisaligned = |(CurrentPPN[26:0]); // must have zero PPN2, PPN1, PPN0
		assign GigapageMisaligned = |(CurrentPPN[17:0]); // must have zero PPN1 and PPN0
		assign MegapageMisaligned = |(CurrentPPN[8:0]); // must have zero PPN0		  
	  end
      //      generate
      if (`XLEN == 32) begin

	// A megapage is a Level 1 leaf page. This page must have zero PPN[0].

	// State transition logic
	always_comb begin
	  case (WalkerState)
	    IDLE: if (AnyTLBMissM & SvMode == `SV32) NextWalkerState = LEVEL1_SET_ADRE;
	      	  else NextWalkerState = IDLE;
	    LEVEL1_SET_ADRE: NextWalkerState = LEVEL1_WDV;
	    LEVEL1_WDV: if (HPTWStall) NextWalkerState = LEVEL1_WDV;
	      else NextWalkerState = LEVEL1;
	    LEVEL1: begin
	      if (ValidPTE && LeafPTE && ~(MegapageMisaligned | ADPageFault)) NextWalkerState = LEAF;
	      else if (ValidPTE && ~LeafPTE) begin
			NextWalkerState = LEVEL0_SET_ADRE;
	      end else NextWalkerState = FAULT;
	    end
	    LEVEL0_SET_ADRE: NextWalkerState = LEVEL0_WDV;
	    LEVEL0_WDV: if (HPTWStall) NextWalkerState = LEVEL0_WDV;
	      else NextWalkerState = LEVEL0;
	    LEVEL0: if (ValidPTE & LeafPTE & ~ADPageFault) NextWalkerState = LEAF;
				else NextWalkerState = FAULT;
	    LEAF:  NextWalkerState = IDLE;
	    FAULT: NextWalkerState = IDLE;
	    // Default case should never happen, but is included for linter.
	    default: NextWalkerState = IDLE;
	  endcase
	end

	// Assign outputs to ahblite
	// *** Currently truncate address to 32 bits. This must be changed if
	// we support larger physical address spaces
	assign HPTWPAdrE = TranslationPAdr[31:0];

      end else begin

	always_comb begin
	  case (WalkerState)
	    IDLE: if (AnyTLBMissM) NextWalkerState = (SvMode == `SV48) ? LEVEL3_SET_ADRE : LEVEL2_SET_ADRE;
		      else NextWalkerState = IDLE;
	    LEVEL3_SET_ADRE: NextWalkerState = LEVEL3_WDV;
	    LEVEL3_WDV: if (HPTWStall) NextWalkerState = LEVEL3_WDV;
	      else NextWalkerState = LEVEL3;
	    LEVEL3: 
	      if (ValidPTE && LeafPTE && ~(TerapageMisaligned || ADPageFault)) NextWalkerState = LEAF;
		  else if (ValidPTE && ~LeafPTE) NextWalkerState = LEVEL2_SET_ADRE;
		  else NextWalkerState = FAULT;
	    LEVEL2_SET_ADRE: NextWalkerState = LEVEL2_WDV;
	    LEVEL2_WDV:  if (HPTWStall) NextWalkerState = LEVEL2_WDV;
	      else NextWalkerState = LEVEL2;
	    LEVEL2: 
			if (ValidPTE && LeafPTE && ~(GigapageMisaligned || ADPageFault)) NextWalkerState = LEAF;
			else if (ValidPTE && ~LeafPTE) NextWalkerState = LEVEL1_SET_ADRE;
			else NextWalkerState = FAULT;
	    LEVEL1_SET_ADRE: NextWalkerState = LEVEL1_WDV;
	    LEVEL1_WDV: if (HPTWStall) NextWalkerState = LEVEL1_WDV;
	      else NextWalkerState = LEVEL1;
	    LEVEL1: 
			if (ValidPTE && LeafPTE && ~(MegapageMisaligned || ADPageFault)) NextWalkerState = LEAF;
	      	else if (ValidPTE && ~LeafPTE) NextWalkerState = LEVEL0_SET_ADRE;
			else NextWalkerState = FAULT;
	    LEVEL0_SET_ADRE: NextWalkerState = LEVEL0_WDV;
	    LEVEL0_WDV: 
			if (HPTWStall) NextWalkerState = LEVEL0_WDV;
	      	else NextWalkerState = LEVEL0;
	    LEVEL0: 
			if (ValidPTE && LeafPTE && ~ADPageFault) NextWalkerState = LEAF;
			else NextWalkerState = FAULT;
	    LEAF: NextWalkerState = IDLE;
	    FAULT:  NextWalkerState = IDLE;
	    default: NextWalkerState = IDLE; // should never be reached

	  endcase
	end
	assign HPTWPAdrE = {{(`XLEN-`PA_BITS){1'b0}}, TranslationPAdr[`PA_BITS-1:0]};
      end
    end else begin
      assign HPTWPAdrE = 0;
      assign HPTWRead = 0;
      assign WalkerInstrPageFaultF = 0;
      assign WalkerLoadPageFaultM = 0;
      assign WalkerStorePageFaultM = 0;
      assign SelPTW = 0;
    end
  endgenerate

endmodule
