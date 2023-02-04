///////////////////////////////////////////
// hazard.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Determine stalls and flushes
// 
// Documentation: RISC-V System on Chip Design Chapter 4, Figure 13.54
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module hazard (
  // Detect hazards
  input logic  BPPredWrongE, CSRWriteFenceM, RetM, TrapM,   
  input logic  LoadStallD, StoreStallD, MDUStallD, CSRRdStallD,
  input logic  LSUStallM, IFUStallF,
  input logic  FCvtIntStallD, FPUStallD,
  input logic  DivBusyE, FDivBusyE,
  input logic  EcallFaultM, BreakpointFaultM,
  input logic  WFIStallM,
  // Stall & flush outputs
  output logic StallF, StallD, StallE, StallM, StallW,
  output logic FlushD, FlushE, FlushM, FlushW
);

  logic                                       StallFCause, StallDCause, StallECause, StallMCause, StallWCause;
  logic                                       FirstUnstalledD, FirstUnstalledE, FirstUnstalledM, FirstUnstalledW;
  logic                                       FlushDCause, FlushECause, FlushMCause, FlushWCause;
  
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
  assign FlushDCause = TrapM | RetM | CSRWriteFenceM | BPPredWrongE;
  assign FlushECause = TrapM | RetM | CSRWriteFenceM |(BPPredWrongE & ~(DivBusyE | FDivBusyE));
  assign FlushMCause = TrapM | RetM | CSRWriteFenceM;
  assign FlushWCause = TrapM;

  // Stall causes
  //  Most data depenency stalls are identified in the decode stage
  //  Division stalls in the execute stage
  //  Flushing any stage has priority over the corresponding stage stall.  
  //    Even if the register gave clear priority over enable, various FSMs still need to disable the stall, so it's best to gate the stall here with flush
  //  The IFU and LSU stall the entire pipeline on a cache miss, bus access, or other long operation.  
  //    The IFU stalls the entire pipeline rather than just Fetch to avoid complications with instructions later in the pipeline causing Exceptions
  //    A trap could be asserted at the start of a IFU/LSU stall, and should flush the memory operation
  assign StallFCause = '0;
  assign StallDCause = (LoadStallD | StoreStallD | MDUStallD | CSRRdStallD | FCvtIntStallD | FPUStallD) & ~FlushDCause;
  assign StallECause = (DivBusyE | FDivBusyE) & ~FlushECause; 
  assign StallMCause = WFIStallM & ~FlushMCause; 
  // Need to gate IFUStallF when the equivalent FlushFCause = FlushDCause = 1.
  // assign StallWCause = ((IFUStallF & ~FlushDCause) | LSUStallM) & ~FlushWCause;
  // Because FlushWCause is a strict subset of FlushDCause, FlushWCause is factored out.
  assign StallWCause = (IFUStallF & ~FlushDCause) | (LSUStallM & ~FlushWCause);

  // Stall each stage for cause or if the next stage is stalled
  assign #1 StallF = StallFCause | StallD;
  assign #1 StallD = StallDCause | StallE;
  assign #1 StallE = StallECause | StallM;
  assign #1 StallM = StallMCause | StallW;
  assign #1 StallW = StallWCause;

  // detect the first stage that is not stalled
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
