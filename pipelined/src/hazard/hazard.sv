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
(* mark_debug = "true" *)	      input logic  BPPredWrongE, CSRWritePendingDEM, RetM, TrapM,
(* mark_debug = "true" *)	      input logic  LoadStallD, StoreStallD, MDUStallD, CSRRdStallD,
(* mark_debug = "true" *)	      input logic  LSUStall, IFUStallF,
(* mark_debug = "true" *)              input logic  FPUStallD, FStallD,
(* mark_debug = "true" *)	      input logic  DivBusyE,FDivBusyE,
(* mark_debug = "true" *)	      input logic  EcallFaultM, BreakpointFaultM,
(* mark_debug = "true" *)        input logic  InvalidateICacheM,
  // Stall & flush outputs
(* mark_debug = "true" *)	      output logic StallF, StallD, StallE, StallM, StallW,
(* mark_debug = "true" *)	      output logic FlushF, FlushD, FlushE, FlushM, FlushW
);

  logic StallFCause, StallDCause, StallECause, StallMCause, StallWCause;
  logic FirstUnstalledD, FirstUnstalledE, FirstUnstalledM, FirstUnstalledW;


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

  assign StallFCause = CSRWritePendingDEM & ~(TrapM | RetM | BPPredWrongE);
  assign StallDCause = (LoadStallD | StoreStallD | MDUStallD | CSRRdStallD | FPUStallD | FStallD) & ~(TrapM | RetM | BPPredWrongE);    // stall in decode if instruction is a load/mul/csr dependent on previous
  assign StallECause = (DivBusyE | FDivBusyE) & ~(TrapM);
  assign StallMCause = 0; 
  assign StallWCause = LSUStall | IFUStallF;

  assign StallF = StallFCause | StallD;
  assign StallD = StallDCause | StallE;
  assign StallE = StallECause | StallM;
  assign StallM = StallMCause | StallW;
  assign StallW = StallWCause;

  assign FirstUnstalledD = ~StallD & StallF;
  assign FirstUnstalledE = ~StallE & StallD;
  assign FirstUnstalledM = ~StallM & StallE;
  assign FirstUnstalledW = ~StallW & StallM;
  
  // Each stage flushes if the previous stage is the last one stalled (for cause) or the system has reason to flush
  assign FlushF = BPPredWrongE | InvalidateICacheM;
  assign FlushD = FirstUnstalledD | TrapM | RetM | BPPredWrongE | InvalidateICacheM;
  assign FlushE = FirstUnstalledE | TrapM | RetM | BPPredWrongE | InvalidateICacheM;
  assign FlushM = FirstUnstalledM | TrapM | RetM | InvalidateICacheM;
  // on Trap the memory stage should be flushed going into the W stage,
  // except if the instruction causing the Trap is an ecall or ebreak.
  assign FlushW = FirstUnstalledW | (TrapM & ~(BreakpointFaultM | EcallFaultM));
endmodule
