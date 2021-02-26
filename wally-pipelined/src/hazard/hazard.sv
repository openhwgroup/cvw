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

module hazard(
  // Detect hazards
  input  logic       PCSrcE, CSRWritePendingDEM, RetM, TrapM,
  input  logic       LoadStallD, MulDivStallD,
  input  logic       InstrStall, DataStall,
  // Stall & flush outputs
  output logic       StallF, StallD, StallE, StallM, StallW,
  output logic       FlushD, FlushE, FlushM, FlushW
);

  logic BranchFlushDE;
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

  assign BranchFlushDE = PCSrcE | RetM | TrapM;

  assign StallFCause = CSRWritePendingDEM & ~(BranchFlushDE);  
  assign StallDCause = LoadStallD | MulDivStallD;                // stall in decode if instruction is a load/mul dependent on previous
  assign StallECause = 0;
  assign StallMCause = 0; 
  assign StallWCause = DataStall | InstrStall;

  // Each stage stalls if the next stage is stalled or there is a cause to stall this stage.
  assign StallF = StallD | StallFCause;
  assign StallD = StallE | StallDCause;
  assign StallE = StallM | StallECause;
  assign StallM = StallW | StallMCause;
  assign StallW = StallWCause;

  assign FirstUnstalledD = (~StallD & StallF);
  assign FirstUnstalledE = (~StallE & StallD);
  assign FirstUnstalledM = (~StallM & StallE);
  assign FirstUnstalledW = (~StallW & StallM);;
  
  // Each stage flushes if the previous stage is the last one stalled (for cause) or the system has reason to flush
  assign FlushD = FirstUnstalledD || BranchFlushDE;  //  PCSrcE |InstrStall | CSRWritePendingDEM | RetM | TrapM;
  assign FlushE = FirstUnstalledE || BranchFlushDE; //LoadStallD | PCSrcE | RetM | TrapM;
  assign FlushM = FirstUnstalledM || RetM || TrapM;
  assign FlushW = FirstUnstalledW | TrapM;
endmodule
