///////////////////////////////////////////
// hazard.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Determine forwarding, stalls and flushes
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module hazard(
  // Detect hazards
(* mark_debug = "true" *)	      input logic  BPPredWrongE, CSRWriteFenceM, RetM, TrapM,
(* mark_debug = "true" *)	      input logic  LoadStallD, StoreStallD, MDUStallD, CSRRdStallD,
(* mark_debug = "true" *)	      input logic  LSUStallW, IFUStallD,
(* mark_debug = "true" *)         input logic  FCvtIntStallD, FPUStallD,
(* mark_debug = "true" *)	      input logic  DivBusyE,FDivBusyE,
(* mark_debug = "true" *)	      input logic  EcallFaultM, BreakpointFaultM,
(* mark_debug = "true" *)         input logic  wfiM, IntPendingM,
  // Stall & flush outputs
(* mark_debug = "true" *)	      output logic StallF, StallD, StallE, StallM, StallW,
(* mark_debug = "true" *)	      output logic FlushD, FlushE, FlushM, FlushW
);

  logic StallFCause, StallDCause, StallECause, StallMCause, StallWCause;
  logic FirstUnstalledD, FirstUnstalledE, FirstUnstalledM, FirstUnstalledW;
  logic FlushDCause, FlushECause, FlushMCause, FlushWCause;
  
  // stalls and flushes
  // loads: stall for one cycle if the subsequent instruction depends on the load
  // branches and jumps: flush the next two instructions if the branch is taken in EXE
  // CSR Writes: stall all instructions after the CSR until it completes, except that PC must change when branch is resolved
  //             this also applies to other privileged instructions such as M/S/URET, ECALL/EBREAK
  // Exceptions: flush entire pipeline
  // Ret instructions: occur in M stage.  Might be possible to move earlier, but be careful about hazards

  // General stall and flush rules:
  // A stage must stall if the next stage is stalled
  // If any stages are stalled, the first stage that isn't stalled must flush.

  // Flush causes
  // Traps (TrapM) flush the entire pipeline.  
  //   However, breakpoint and ecall traps must finish the writeback stage (commit their results) because these instructions complete before trapping.
  // Trap returns (RetM) also flush the entire pipeline after the RetM (all stages except W) because all the subsequent instructions must be discarded.
  // Similarly, CSR writes and fences flush all subsequent instructions and refetch them in light of the new operating modes and cache/TLB contents
  // Branch misprediction is found in the Execute stage and must flush the next two instructions.
  //   However, an active division operation resides in the Execute stage, and when the BP incorrectly mispredicts the divide as a taken branch, the divde must still complete
  assign FlushDCause = TrapM | RetM | BPPredWrongE | CSRWriteFenceM;
  assign FlushECause = TrapM | RetM | (BPPredWrongE & ~(DivBusyE | FDivBusyE)) | CSRWriteFenceM;
  assign FlushMCause = TrapM | RetM | CSRWriteFenceM;
  assign FlushWCause = TrapM & ~(BreakpointFaultM | EcallFaultM);

  // Stall causes
  //  Most data depenency stalls are identified in the decode stage
  //  Division stalls in the execute stage
  //  Flushing the decode or execute stage has priority over stalls.  
  //    Even if the register gave clear priority over enable, various FSMs still need to disable the stall, so it's best to gate the stall here with flush
  //  WFI is an odd case.  It stalls in the Memory stage until a pending interrupt or timeout trap
  //  The IFU and LSU stall the entire pipeline on a cache miss, bus access, or other long operation.  
  //    The IFU stalls the entire pipeline rather than just Fetch to avoid complications with instructions later in the pipeline causing Exceptions
  //    A trap could be asserted at the start of a IFU/LSU stall, and should flush the memory operation
  assign StallFCause = '0;
  assign StallDCause = (LoadStallD | StoreStallD | MDUStallD | CSRRdStallD | FCvtIntStallD | FPUStallD) & ~FlushDCause;
  assign StallECause = (DivBusyE | FDivBusyE) & ~FlushECause; 
  // WFI terminates if any enabled interrupt is pending, even if global interrupts are disabled.  It could also terminate with TW trap
  assign StallMCause = ((wfiM) & (~TrapM & ~IntPendingM)); 
  //assign StallWCause = (IFUStallD | LSUStallW) & ~TrapM;
  assign StallWCause = (IFUStallD & ~FlushDCause) | (LSUStallW & ~FlushWCause); 

  // Stall each stage for cause or if the next stage is stalled
  assign #1 StallF = StallFCause | StallD;
  assign #1 StallD = StallDCause | StallE;
  assign #1 StallE = StallECause | StallM;
  assign #1 StallM = StallMCause | StallW;
  assign #1 StallW = StallWCause;

  assign FirstUnstalledD = ~StallD & StallF;
  assign FirstUnstalledE = ~StallE & StallD;
  assign FirstUnstalledM = ~StallM & StallE;
  assign FirstUnstalledW = ~StallW & StallM;
  
  // Each stage flushes if the previous stage is the last one stalled (for cause) or the system has reason to flush
  assign #1 FlushD = FirstUnstalledD | FlushDCause; 
  assign #1 FlushE = FirstUnstalledE | FlushECause;
  assign #1 FlushM = FirstUnstalledM | FlushMCause;
  assign #1 FlushW = FirstUnstalledW | FlushWCause;
endmodule
