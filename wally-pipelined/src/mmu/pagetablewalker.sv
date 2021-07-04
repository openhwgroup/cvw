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

/* ***
 TO-DO:
 - Implement faults on accessed/dirty behavior
 */

module pagetablewalker
  (
   // Control signals
   input logic 		    clk, reset,
   input logic [`XLEN-1:0]  SATP_REGW,

   // Signals from TLBs (addresses to translate)
   input logic [`XLEN-1:0]  PCF, MemAdrM,
   input logic 		    ITLBMissF, DTLBMissM,
   input logic [1:0] 	    MemRWM,

   // Outputs to the TLBs (PTEs to write)
   output logic [`XLEN-1:0] PageTableEntryF, PageTableEntryM,
   output logic [1:0] 	    PageTypeF, PageTypeM,
   output logic 	    ITLBWriteF, DTLBWriteM,




   // *** modify to send to LSU // *** KMG: These are inputs/results from the ahblite whose addresses should have already been checked, so I don't think they need to be sent through the LSU
   input logic [`XLEN-1:0]  MMUReadPTE,
   input logic 		    MMUReady,
   input logic 		    HPTWStall,

   // *** modify to send to LSU
   output logic [`XLEN-1:0] MMUPAdr, // this probalby should be `PA_BITS wide
   output logic 	    MMUTranslate, // *** rename to HPTWReq
   output logic 	    HPTWRead,


   // Faults
   output logic 	    WalkerInstrPageFaultF,
   output logic 	    WalkerLoadPageFaultM, 
   output logic 	    WalkerStorePageFaultM
   );

  // Internal signals
  // register TLBs translation miss requests
  logic [`XLEN-1:0] 	    TranslationVAdrQ;
  logic 		    ITLBMissFQ, DTLBMissMQ;
  
  logic [`PPN_BITS-1:0]     BasePageTablePPN;
  logic [`XLEN-1:0] 	    TranslationVAdr;
  logic [`XLEN-1:0] 	    SavedPTE, CurrentPTE;
  logic [`PA_BITS-1:0] 	    TranslationPAdr;
  logic [`PPN_BITS-1:0]     CurrentPPN;
  logic [`SVMODE_BITS-1:0]  SvMode;
  logic 		    MemStore;

  // PTE Control Bits
  logic 		    Dirty, Accessed, Global, User,
			    Executable, Writable, Readable, Valid;
  // PTE descriptions
  logic 		    ValidPTE, AccessAlert, MegapageMisaligned, BadMegapage, LeafPTE;

  // Outputs of walker
  logic [`XLEN-1:0] 	    PageTableEntry;
  logic [1:0] 		    PageType;
  logic 		    StartWalk;
  logic 		    EndWalk;
  
  typedef enum 		    {LEVEL0_WDV,
			     LEVEL0,
			     LEVEL1_WDV,
			     LEVEL1,
			     LEVEL2_WDV,
			     LEVEL2,
			     LEVEL3_WDV,
			     LEVEL3,
			     LEAF,
			     IDLE,
			     FAULT} statetype;

  statetype WalkerState, NextWalkerState;

  logic 		    PRegEn;
  
  assign SvMode = SATP_REGW[`XLEN-1:`XLEN-`SVMODE_BITS];

  assign BasePageTablePPN = SATP_REGW[`PPN_BITS-1:0];

  assign MemStore = MemRWM[0];

  // Prefer data address translations over instruction address translations
  assign TranslationVAdr = (DTLBMissM) ? MemAdrM : PCF; // *** need to register TranslationVAdr
  flopenr #(`XLEN) 
  TranslationVAdrReg(.clk(clk),
		     .reset(reset),
		     .en(StartWalk), // *** use enable later to save power
		     .d(TranslationVAdr),
		     .q(TranslationVAdrQ));

  flopenrc #(1)
  DTLBMissMReg(.clk(clk),
	       .reset(reset),
	       .en(StartWalk | EndWalk),
	       .clear(EndWalk),
	       .d(DTLBMissM),
	       .q(DTLBMissMQ));
  
  flopenrc #(1)
  ITLBMissMReg(.clk(clk),
	       .reset(reset),
	       .en(StartWalk | EndWalk),
	       .clear(EndWalk),
	       .d(ITLBMissF),
	       .q(ITLBMissFQ));
  

  assign StartWalk = WalkerState == IDLE && (DTLBMissM | ITLBMissF);
  assign EndWalk = WalkerState == LEAF || 
		   //(WalkerState == LEVEL0 && ValidPTE && LeafPTE && ~AccessAlert) ||
		   (WalkerState == LEVEL1 && ValidPTE && LeafPTE && ~AccessAlert) ||
		   (WalkerState == LEVEL2 && ValidPTE && LeafPTE && ~AccessAlert) ||
		   (WalkerState == LEVEL3 && ValidPTE && LeafPTE && ~AccessAlert) ||		   
		   (WalkerState == FAULT);
  
  assign MMUTranslate = (DTLBMissMQ | ITLBMissFQ) & ~EndWalk;
  //assign MMUTranslate = DTLBMissM | ITLBMissF;

  // unswizzle PTE bits
  assign {Dirty, Accessed, Global, User,
          Executable, Writable, Readable, Valid} = CurrentPTE[7:0];

  // Assign PTE descriptors common across all XLEN values
  assign LeafPTE = Executable | Writable | Readable;
  assign ValidPTE = Valid && ~(Writable && ~Readable);
  assign AccessAlert = ~Accessed | (MemStore & ~Dirty);

  // Assign specific outputs to general outputs
  assign PageTableEntryF = PageTableEntry;
  assign PageTableEntryM = PageTableEntry;
  assign PageTypeF = PageType;
  assign PageTypeM = PageType;


  generate
    if (`XLEN == 32) begin
      logic [9:0] VPN1, VPN0;

      flopenl #(.TYPE(statetype)) mmureg(clk, reset, 1'b1, NextWalkerState, IDLE, WalkerState);

/* -----\/----- EXCLUDED -----\/-----
      assign PRegEn = (WalkerState == LEVEL1_WDV || WalkerState == LEVEL0_WDV) && ~HPTWStall;
 -----/\----- EXCLUDED -----/\----- */

      // State transition logic
      always_comb begin
	PRegEn = 1'b0;
	TranslationPAdr = '0;
	HPTWRead = 1'b0;
        PageTableEntry = '0;
        PageType = '0;
        DTLBWriteM = '0;
        ITLBWriteF = '0;
	
        WalkerInstrPageFaultF = 1'b0;
        WalkerLoadPageFaultM = 1'b0;
        WalkerStorePageFaultM = 1'b0;

        case (WalkerState)
          IDLE: begin
	    if (MMUTranslate && SvMode == `SV32) begin // *** Added SvMode
	      NextWalkerState = LEVEL1_WDV;
              TranslationPAdr = {BasePageTablePPN, VPN1, 2'b00};
	      HPTWRead = 1'b1;
	    end else begin
              NextWalkerState = IDLE;
	      TranslationPAdr = '0;
	    end
	  end
	  
          LEVEL1_WDV: begin
            TranslationPAdr = {BasePageTablePPN, VPN1, 2'b00};
	    if (HPTWStall) begin
              NextWalkerState = LEVEL1_WDV;
	    end else begin
              NextWalkerState = LEVEL1;
	      PRegEn = 1'b1;
	    end
	  end
	  
	  LEVEL1: begin
            // *** <FUTURE WORK> According to the architecture, we should
            // fault upon finding a superpage that is misaligned or has 0
            // access bit. The following commented line of code is
            // supposed to perform that check. However, it is untested.
            if (ValidPTE && LeafPTE && ~BadMegapage) begin
	      NextWalkerState = LEAF;
              PageTableEntry = CurrentPTE;
              PageType = (WalkerState == LEVEL1) ? 2'b01 : 2'b00;  // *** not sure about this mux?
              DTLBWriteM = DTLBMissMQ;
              ITLBWriteF = ~DTLBMissMQ;  // Prefer data over instructions
              TranslationPAdr = {2'b00, TranslationVAdrQ[31:0]};
	    end
            // else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;  // *** Once the above line is properly tested, delete this line.
            else if (ValidPTE && ~LeafPTE) begin
	      NextWalkerState = LEVEL0_WDV;
              TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
	      HPTWRead = 1'b1;
	    end else begin
              NextWalkerState = FAULT;
	    end
	  end
	  
          LEVEL0_WDV: begin
            TranslationPAdr = {CurrentPPN, VPN0, 2'b00};
	    if (HPTWStall) begin 
	      NextWalkerState = LEVEL0_WDV;
	    end else begin 
	      NextWalkerState = LEVEL0;
	      PRegEn = 1'b1;
	    end
	  end

	  LEVEL0: begin
	    if (ValidPTE & LeafPTE & ~AccessAlert) begin
              NextWalkerState = LEAF;
              PageTableEntry = CurrentPTE;
              PageType = (WalkerState == LEVEL1) ? 2'b01 : 2'b00;
              DTLBWriteM = DTLBMissMQ;
              ITLBWriteF = ~DTLBMissMQ;  // Prefer data over instructions
              TranslationPAdr = {2'b00, TranslationVAdrQ[31:0]};
	    end else begin
              NextWalkerState = FAULT;
	    end
	  end
	  
          LEAF: begin
            NextWalkerState = IDLE;
	  end
          FAULT: begin
            NextWalkerState = IDLE;
            WalkerInstrPageFaultF = ~DTLBMissMQ;
            WalkerLoadPageFaultM = DTLBMissMQ && ~MemStore;
            WalkerStorePageFaultM = DTLBMissMQ && MemStore;
	  end
	  
          // Default case should never happen, but is included for linter.
          default:                                 NextWalkerState = IDLE;
        endcase
      end

      // A megapage is a Level 1 leaf page. This page must have zero PPN[0].
      assign MegapageMisaligned = |(CurrentPPN[9:0]);
      assign BadMegapage = MegapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme

      assign VPN1 = TranslationVAdrQ[31:22];
      assign VPN0 = TranslationVAdrQ[21:12];

      

      // Capture page table entry from data cache
      // *** may need to delay reading this value until the next clock cycle.
      // The clk to q latency of the SRAM in the data cache will be long.
      // I cannot see directly using this value.  This is no different than
      // a load delay hazard.  This will require rewriting the walker fsm.
      // also need a new signal to save.  Should be a mealy output of the fsm
      // request followed by ~stall.
      flopenr #(32) ptereg(clk, reset, PRegEn, MMUReadPTE, SavedPTE);
      //mux2 #(32) ptemux(SavedPTE, MMUReadPTE, PRegEn, CurrentPTE);
      assign CurrentPTE = SavedPTE;
      assign CurrentPPN = CurrentPTE[`PPN_BITS+9:10];

      // Assign outputs to ahblite
      // *** Currently truncate address to 32 bits. This must be changed if
      // we support larger physical address spaces
      assign MMUPAdr = TranslationPAdr[31:0];

    end else begin
      
      logic [8:0] VPN3, VPN2, VPN1, VPN0;

      logic 	  TerapageMisaligned, GigapageMisaligned, BadTerapage, BadGigapage;

      flopenl #(.TYPE(statetype)) mmureg(clk, reset, 1'b1, NextWalkerState, IDLE, WalkerState);

      /* -----\/----- EXCLUDED -----\/-----
       assign PRegEn = (WalkerState == LEVEL1_WDV || WalkerState == LEVEL0_WDV ||
       WalkerState == LEVEL2_WDV || WalkerState == LEVEL3_WDV) && ~HPTWStall;
       -----/\----- EXCLUDED -----/\----- */

      //assign HPTWRead = (WalkerState == IDLE && MMUTranslate) || WalkerState == LEVEL3 ||
      //			WalkerState == LEVEL2 || WalkerState == LEVEL1;
      

      always_comb begin
	PRegEn = 1'b0;
	TranslationPAdr = '0;
	HPTWRead = 1'b0;
        PageTableEntry = '0;
        PageType = '0;
        DTLBWriteM = '0;
        ITLBWriteF = '0;
	
        WalkerInstrPageFaultF = 1'b0;
        WalkerLoadPageFaultM = 1'b0;
        WalkerStorePageFaultM = 1'b0;

        case (WalkerState)
          IDLE: begin
	    if (MMUTranslate && SvMode == `SV48) begin
	      NextWalkerState = LEVEL3_WDV;
              TranslationPAdr = {BasePageTablePPN, VPN3, 3'b000};
	      HPTWRead = 1'b1;
	    end else if (MMUTranslate && SvMode == `SV39) begin
	      NextWalkerState = LEVEL2_WDV;
              TranslationPAdr = {BasePageTablePPN, VPN2, 3'b000};
	      HPTWRead = 1'b1;
	    end else begin
              NextWalkerState = IDLE;
	      TranslationPAdr = '0;
	    end
	  end

          LEVEL3_WDV: begin
            TranslationPAdr = {BasePageTablePPN, VPN3, 3'b000};
	    if (HPTWStall) begin
	      NextWalkerState = LEVEL3_WDV;
	    end else begin
	      NextWalkerState = LEVEL3;
	      PRegEn = 1'b1;
	    end
	  end
	  
	  LEVEL3: begin
            // *** <FUTURE WORK> According to the architecture, we should
            // fault upon finding a superpage that is misaligned or has 0
            // access bit. The following commented line of code is
            // supposed to perform that check. However, it is untested.
            if (ValidPTE && LeafPTE && ~BadTerapage) begin 
              NextWalkerState = LEAF;
              PageTableEntry = CurrentPTE;
              PageType = (WalkerState == LEVEL3) ? 2'b11 :  // *** not sure about this mux?
                         ((WalkerState == LEVEL2) ? 2'b10 : 
                          ((WalkerState == LEVEL1) ? 2'b01 : 2'b00));
              DTLBWriteM = DTLBMissMQ;
              ITLBWriteF = ~DTLBMissMQ;  // Prefer data over instructions
              TranslationPAdr = TranslationVAdrQ[`PA_BITS-1:0];
            end 
            // else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;  // *** Once the above line is properly tested, delete this line.
            else if (ValidPTE && ~LeafPTE) begin
              NextWalkerState = LEVEL2_WDV;
              TranslationPAdr = {(SvMode == `SV48) ? CurrentPPN : BasePageTablePPN, VPN2, 3'b000};
              HPTWRead = 1'b1;
            end else begin
              NextWalkerState = FAULT;
            end

          end

          LEVEL2_WDV:  begin
            TranslationPAdr = {(SvMode == `SV48) ? CurrentPPN : BasePageTablePPN, VPN2, 3'b000};
            //HPTWRead = 1'b1;
            if (HPTWStall) begin
              NextWalkerState = LEVEL2_WDV;
            end else begin
              NextWalkerState = LEVEL2;
              PRegEn = 1'b1;
            end
          end
          
          LEVEL2: begin
            // *** <FUTURE WORK> According to the architecture, we should
            // fault upon finding a superpage that is misaligned or has 0
            // access bit. The following commented line of code is
            // supposed to perform that check. However, it is untested.
            if (ValidPTE && LeafPTE && ~BadGigapage) begin 
              NextWalkerState = LEAF;
              PageTableEntry = CurrentPTE;
              PageType = (WalkerState == LEVEL3) ? 2'b11 :
                         ((WalkerState == LEVEL2) ? 2'b10 : 
                          ((WalkerState == LEVEL1) ? 2'b01 : 2'b00));
              DTLBWriteM = DTLBMissMQ;
              ITLBWriteF = ~DTLBMissMQ;  // Prefer data over instructions
              TranslationPAdr = TranslationVAdrQ[`PA_BITS-1:0];
            end
            // else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;  // *** Once the above line is properly tested, delete this line.
            else if (ValidPTE && ~LeafPTE) begin
              NextWalkerState = LEVEL1_WDV;
              TranslationPAdr = {CurrentPPN, VPN1, 3'b000};
              HPTWRead = 1'b1;
            end else begin
              NextWalkerState = FAULT;
            end

          end

          LEVEL1_WDV: begin
            TranslationPAdr = {CurrentPPN, VPN1, 3'b000};
            //HPTWRead = 1'b1;
            if (HPTWStall) begin 
              NextWalkerState = LEVEL1_WDV;
            end else begin
              NextWalkerState = LEVEL1;
              PRegEn = 1'b1;
            end
          end

          LEVEL1: begin
            // *** <FUTURE WORK> According to the architecture, we should
            // fault upon finding a superpage that is misaligned or has 0
            // access bit. The following commented line of code is
            // supposed to perform that check. However, it is untested.
            if (ValidPTE && LeafPTE && ~BadMegapage) begin 
              NextWalkerState = LEAF;
              PageTableEntry = CurrentPTE;
              PageType = (WalkerState == LEVEL3) ? 2'b11 :
                         ((WalkerState == LEVEL2) ? 2'b10 : 
                          ((WalkerState == LEVEL1) ? 2'b01 : 2'b00));
              DTLBWriteM = DTLBMissMQ;
              ITLBWriteF = ~DTLBMissMQ;  // Prefer data over instructions
              TranslationPAdr = TranslationVAdrQ[`PA_BITS-1:0];
              
            end
            // else if (ValidPTE && LeafPTE)    NextWalkerState = LEAF;  // *** Once the above line is properly tested, delete this line.
            else if (ValidPTE && ~LeafPTE) begin
              NextWalkerState = LEVEL0_WDV;
              TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
              HPTWRead = 1'b1;
            end else begin 
              NextWalkerState = FAULT;
            end
          end

          LEVEL0_WDV: begin
            TranslationPAdr = {CurrentPPN, VPN0, 3'b000};
            if (HPTWStall) begin 
              NextWalkerState = LEVEL0_WDV;
            end else begin
              NextWalkerState = LEVEL0;
              PRegEn = 1'b1;
            end
          end

          LEVEL0: begin
            if (ValidPTE && LeafPTE && ~AccessAlert) begin 
              NextWalkerState = LEAF;
              PageTableEntry = CurrentPTE;
              PageType = (WalkerState == LEVEL3) ? 2'b11 :
                         ((WalkerState == LEVEL2) ? 2'b10 : 
                          ((WalkerState == LEVEL1) ? 2'b01 : 2'b00));
              DTLBWriteM = DTLBMissMQ;
              ITLBWriteF = ~DTLBMissMQ;  // Prefer data over instructions
              TranslationPAdr = TranslationVAdrQ[`PA_BITS-1:0];
            end else begin 
              NextWalkerState = FAULT;
            end
          end
          
          LEAF: begin 
            NextWalkerState = IDLE;
          end

          FAULT: begin
            NextWalkerState = IDLE;
            WalkerInstrPageFaultF = ~DTLBMissMQ;
            WalkerLoadPageFaultM = DTLBMissMQ && ~MemStore;
            WalkerStorePageFaultM = DTLBMissMQ && MemStore;
          end

          // Default case should never happen
          default: begin
            NextWalkerState = IDLE;
          end

        endcase
      end

      // A terapage is a level 3 leaf page. This page must have zero PPN[2],
      // zero PPN[1], and zero PPN[0]
      assign TerapageMisaligned = |(CurrentPPN[26:0]);
      // A gigapage is a Level 2 leaf page. This page must have zero PPN[1] and
      // zero PPN[0]
      assign GigapageMisaligned = |(CurrentPPN[17:0]);
      // A megapage is a Level 1 leaf page. This page must have zero PPN[0].
      assign MegapageMisaligned = |(CurrentPPN[8:0]);

      assign BadTerapage = TerapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme
      assign BadGigapage = GigapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme
      assign BadMegapage = MegapageMisaligned || AccessAlert;  // *** Implement better access/dirty scheme

      assign VPN3 = TranslationVAdrQ[47:39];
      assign VPN2 = TranslationVAdrQ[38:30];
      assign VPN1 = TranslationVAdrQ[29:21];
      assign VPN0 = TranslationVAdrQ[20:12];


      // Capture page table entry from ahblite
      flopenr #(`XLEN) ptereg(clk, reset, PRegEn, MMUReadPTE, SavedPTE);
      //mux2 #(`XLEN) ptemux(SavedPTE, MMUReadPTE, PRegEn, CurrentPTE);
      assign CurrentPTE = SavedPTE;
      assign CurrentPPN = CurrentPTE[`PPN_BITS+9:10];

      // Assign outputs to ahblite
      // *** Currently truncate address to 32 bits. This must be changed if
      // we support larger physical address spaces
      assign MMUPAdr = {{(`XLEN-`PA_BITS){1'b0}}, TranslationPAdr[`PA_BITS-1:0]};
    end
  endgenerate

endmodule
