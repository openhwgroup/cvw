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

module lsuArb (
  input  logic clk, reset,

   // signals from page table walker
//  output logic [`XLEN-1:0] MMUReadPTE, // *** it seems like this is the value out of the ahblite that gets sent back to the ptw. I don;t think it needs to get checked until the next paddr has been extracted from it.
  input  logic             MMUTranslate,   // *** rename to HPTWReq
//  output logic             MMUReady, // *** Similar reason to mmuReadPTE
  input  logic [`XLEN-1:0] MMUPAdr,

  // signal from CPU
  input  logic [1:0]       MemRWM,
  input  logic [2:0]       Funct3M,
  input  logic [1:0]       AtomicM,
  input  logic [`XLEN-1:0] MemAdrM, // memory addrress to be checked coming from the CPU. *** this will be used to arbitrate to decide HADDR going into the PM checks, but it also gets sent in its normal form to the lsu because we need the virtual address for the tlb.
  // back to CPU

  /* *** unused for not (23 June 2021)    
  output logic             CommittedM,    
  output logic             SquashSCW,
  output logic             DataMisalignedM,
*/
  // to LSU   
  output logic             DisableTranslation,   
  output logic [1:0]       MemRWMtoLSU,
  output logic [2:0]       Funct3MtoLSU,
  output logic [1:0]       AtomicMtoLSU

  /* *********** KMG: A lot of the rest of the signals that need to be arbitrated are going to be very annoying
                      these are the ones that used to get sent from the ahb to the pma checkers. but our eventual
                      goal is to have many of them sent thru the pmp/pma FIRST before the bus can get to them.

                      deciding how to choose the right Haddr for the PM checkers will be difficult since they currently get
                      HADDR from the ahblite which seems like it could come from any number of sources, while we will eventually be narrowing it down to two possible sources.

                      other problems arise when some signals like HSIZE are used in the PM checks but there's also a differnent size input to the tlb and both of these get to go through the mmu.
                      which one should be chosen for which device? can the be merged somehow?

*/

  /*// pmp/pma specifics sent through lsu
  output logic [`XLEN-1:0] HADDRtoLSU,
  output logic [2:0]       HSIZEtoLSU  // *** May not actually need to be arbitrated, since I'm 
*/
);

/* *** these are all the signals that get sent to the pmp/pma chackers straight from the ahblite. We want to switch it around so the
        checkers get these signals first and then the newly checked values can get sent to the ahblite.
  input  logic [31:0]      HADDR, // *** replace all of these H inputs with physical adress once pma checkers have been edited to use paddr as well.
  input  logic [2:0]       HSIZE,
  input  logic             HWRITE,
  input  logic             AtomicAccessM, WriteAccessM, ReadAccessM, // execute access is hardwired to zero in this mmu because we're only working with data in the M stage.
*/
  
  generate
    if (`XLEN == 32) begin

      assign Funct3MtoLSU = MMUTranslate ? 3'b010 : Funct3M; // *** is this the right thing for the msB?

    end else begin

      assign Funct3MtoLSU = MMUTranslate ? 3'b011 : Funct3M; // *** is this the right thing for the msB?

    end
  endgenerate

  assign AtomicMtoLSU = MMUTranslate ? 2'b00 : AtomicM;
  assign MemRWMtoLSU = MemRWM; // *** along with the rest of the lsu, the mmu uses memrwm in it's pure form so I think we can just forward it through
  assign DisableTranslation = MMUTranslate;
//  assign HADDRtoLSU = MMUTranslate ? MMUPAdr : MemAdrM; // *** Potentially a huge breaking point since the PM checks always get HADDR from ahblite and not necessarily just these two sources. this will need to be looked over when we fix PM to only take physical addresses.
//  assign HSIZEtoLSU = {1'b0, Funct3MtoLSU[1:0]}; // the Hsize is always just the funct3M indicating the size of the data transfer.


	      
endmodule
