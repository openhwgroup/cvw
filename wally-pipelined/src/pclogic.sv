///////////////////////////////////////////
// pclogic.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Determine Program Counter considering branches, exceptions, ret, reset
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

`include "wally-macros.sv"

module pclogic #(parameter XLEN=64, MISA=0) (
  input  logic            clk, reset,
  input  logic            StallF, PCSrcE, 
  input  logic [31:0]     InstrF,
  input  logic [XLEN-1:0] ExtImmE, TargetBaseE,
  input  logic            RetM, TrapM, 
  input  logic [XLEN-1:0] PrivilegedNextPCM, 
  output logic [XLEN-1:0] PCF, PCPlus2or4F,
  output logic            InstrMisalignedFaultM,
  output logic [XLEN-1:0] InstrMisalignedAdrM);

  logic [XLEN-1:0] UnalignedPCNextF, PCNextF, PCTargetE;
//  logic [XLEN-1:0] ResetVector = 'h100;
//  logic [XLEN-1:0] ResetVector = 'he4;
  logic [XLEN-1:0] ResetVector = {{(XLEN-32){1'b0}}, 32'h80000000};
  logic misaligned, BranchMisalignedFaultE, BranchMisalignedFaultM, TrapMisalignedFaultM;
  logic StallExceptResolveBranchesF, PrivilegedChangePCM;

  assign PrivilegedChangePCM = RetM | TrapM;

  assign StallExceptResolveBranchesF = StallF & ~(PCSrcE | PrivilegedChangePCM);

  assign PCTargetE = ExtImmE + TargetBaseE;
  mux3    #(XLEN) pcmux(PCPlus2or4F, PCTargetE, PrivilegedNextPCM, {PrivilegedChangePCM, PCSrcE}, UnalignedPCNextF);
  assign  PCNextF = {UnalignedPCNextF[XLEN-1:1], 1'b0}; // hart-SPEC p. 21 about 16-bit alignment
  flopenl #(XLEN) pcreg(clk, reset, ~StallExceptResolveBranchesF, PCNextF, ResetVector, PCF);
  pcadder #(XLEN) pcadd(PCF, InstrF, PCPlus2or4F);   

  // Misaligned PC logic

  generate
    if (`C_SUPPORTED) // C supports compressed instructions on halfword boundaries
      assign misaligned = PCNextF[0];
    else // instructions must be on word boundaries
      assign misaligned = |PCNextF[1:0];
  endgenerate

  // pipeline misaligned faults to M stage
  assign BranchMisalignedFaultE = misaligned & PCSrcE; // E-stage (Branch/Jump) misaligned
  flopr #(1) InstrMisalginedReg(clk, reset, BranchMisalignedFaultE, BranchMisalignedFaultM);
  flopr #(XLEN) InstrMisalignedAdrReg(clk, reset, PCNextF, InstrMisalignedAdrM);
  assign TrapMisalignedFaultM = misaligned & PrivilegedChangePCM;
  assign InstrMisalignedFaultM = BranchMisalignedFaultM; // | TrapMisalignedFaultM; *** put this back in without causing a cyclic path
  
endmodule

