///////////////////////////////////////////
// controller.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Top level controller module
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


module controller(
  input  logic		 clk, reset,
  // Decode stage control signals
  input  logic [31:0] InstrD,
  output logic [2:0] ImmSrcD,
  input  logic       IllegalIEUInstrFaultD, 
  output logic       IllegalBaseInstrFaultD,
  // Execute stage control signals
  input logic 	     StallE, FlushE, 
  input logic  [2:0] FlagsE, 
  output logic       PCSrcE,        // for datapath and Hazard Unit
  output logic [4:0] ALUControlE, 
  output logic 	     ALUSrcAE, ALUSrcBE,
  output logic       TargetSrcE,
  output logic       MemReadE, CSRReadE, // for Hazard Unit
  output logic [2:0] Funct3E,
  output logic       MulDivE, W64E,
  output logic       JumpE,		  
  // Memory stage control signals
  input  logic       StallM, FlushM,
  output logic [1:0] MemRWM,
  output logic       CSRReadM, CSRWriteM, PrivilegedM, 
  output logic       AtomicM,
  output logic [2:0] Funct3M,
  output logic       RegWriteM,     // for Hazard Unit	
  // Writeback stage control signals
  input  logic       StallW, FlushW,
  output logic 	     RegWriteW,     // for datapath and Hazard Unit
  output logic [2:0] ResultSrcW,
  output logic       InstrValidW,
  // Stall during CSRs
  output logic       CSRWritePendingDEM
);

  logic [6:0] OpD;
  logic [2:0] Funct3D;
  logic [6:0] Funct7D;
  logic [4:0] Rs1D;

  // pipelined control signals
  logic 	    RegWriteD, RegWriteE;
  logic [2:0] ResultSrcD, ResultSrcE, ResultSrcM;
  logic [1:0] MemRWD, MemRWE;
  logic		    JumpD;
  logic		    BranchD, BranchE;
  logic	[1:0] ALUOpD;
  logic [4:0] ALUControlD;
  logic 	    ALUSrcAD, ALUSrcBD;
  logic       TargetSrcD, W64D, MulDivD;
  logic       CSRZeroSrcD;
  logic       CSRReadD;
  logic       AtomicD, AtomicE;
  logic       CSRWriteD, CSRWriteE;
  logic       InstrValidE, InstrValidM;
  logic       PrivilegedD, PrivilegedE;
  logic [21:0] ControlsD;
  logic        aluc3D;
  logic        subD, sraD, sltD, sltuD;
  logic        BranchTakenE;
  logic        zeroE, ltE, ltuE;
  logic        unused;
	
  // Extract fields
  assign OpD = InstrD[6:0];
  assign Funct3D = InstrD[14:12];
  assign Funct7D = InstrD[31:25];
  assign Rs1D = InstrD[19:15];

  // Main Instruction Decoder
  // *** perhaps decoding of non-IEU instructions should also go here, and should be gated by MISA bits in a generate so
  // they don't get generated if that mode is disabled
  generate
    always_comb
      case(OpD)
      // *** Atomic p. 132 assembly encodings, defs 48
      // RegWrite_ImmSrc_ALUSrc_MemRW_ResultSrc_Branch_ALUOp_Jump_TargetSrc_W64_CSRRead_Privileged_MulDiv_Atomic_Illegal
        7'b0000000:   ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_0_0_0_1; // illegal instruction
        7'b0000011:   ControlsD = 22'b1_000_01_10_001_0_00_0_0_0_0_0_0_0_0; // lw
        7'b0001111:   ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_0_0_0_0; // fence = nop
        7'b0010011:   ControlsD = 22'b1_000_01_00_000_0_10_0_0_0_0_0_0_0_0; // I-type ALU
        7'b0010111:   ControlsD = 22'b1_100_11_00_000_0_00_0_0_0_0_0_0_0_0; // auipc
        7'b0011011: if (`XLEN == 64)
                      ControlsD = 22'b1_000_01_00_000_0_10_0_0_1_0_0_0_0_0; // IW-type ALU for RV64i
                    else
                      ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_0_0_0_1; // non-implemented instruction
        7'b0100011:   ControlsD = 22'b0_001_01_01_000_0_00_0_0_0_0_0_0_0_0; // sw
        7'b0101111: if (`A_SUPPORTED) begin
                      if (InstrD[31:27] == 5'b00010)
                        ControlsD = 22'b1_000_00_10_001_0_00_0_0_0_0_0_0_1_0; // lr
                      else if (InstrD[31:27] == 5'b00011)
                        ControlsD = 22'b1_101_01_01_101_0_00_0_0_0_0_0_0_1_0; // sc
                      else 
                        ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_0_0_1_0; // other atomic; decode later
                    end else
                      ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_0_0_0_1; // non-implemented instruction
        7'b0110011: if (Funct7D == 7'b0000000 || Funct7D == 7'b0100000)
                      ControlsD = 22'b1_000_00_00_000_0_10_0_0_0_0_0_0_0_0; // R-type 
                    else if (Funct7D == 7'b0000001 && `M_SUPPORTED)
                      ControlsD = 22'b1_000_00_00_100_0_00_0_0_0_0_0_1_0_0; // Multiply/Divide
                    else
                      ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_0_0_0_1; // non-implemented instruction
        7'b0110111:   ControlsD = 22'b1_100_01_00_000_0_11_0_0_0_0_0_0_0_0; // lui
        7'b0111011: if ((Funct7D == 7'b0000000 || Funct7D == 7'b0100000) && `XLEN == 64)
                      ControlsD = 22'b1_000_00_00_000_0_10_0_0_1_0_0_0_0_0; // R-type W instructions for RV64i
                    else if (Funct7D == 7'b0000001 && `M_SUPPORTED && `XLEN == 64)
                      ControlsD = 22'b1_000_00_00_100_0_00_0_0_1_0_0_1_0_0; // W-type Multiply/Divide
                    else
                      ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_0_0_0_1; // non-implemented instruction
        7'b1100011:   ControlsD = 22'b0_010_00_00_000_1_01_0_0_0_0_0_0_0_0; // beq
        7'b1100111:   ControlsD = 22'b1_000_00_00_010_0_00_1_1_0_0_0_0_0_0; // jalr
        7'b1101111:   ControlsD = 22'b1_011_00_00_010_0_00_1_0_0_0_0_0_0_0; // jal
        7'b1110011: if (Funct3D == 3'b000)
                      ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_1_0_0_0; // privileged; decoded further in priveleged modules
                    else
                      ControlsD = 22'b1_000_00_00_011_0_00_0_0_0_1_0_0_0_0; // csrs
        default:      ControlsD = 22'b0_000_00_00_000_0_00_0_0_0_0_0_0_0_1; // non-implemented instruction
      endcase
  endgenerate

  // unswizzle control bits
  // squash control signals if coming from an illegal compressed instruction
  assign IllegalBaseInstrFaultD = ControlsD[0];
  assign {RegWriteD, ImmSrcD, ALUSrcAD, ALUSrcBD, MemRWD,
          ResultSrcD, BranchD, ALUOpD, JumpD, TargetSrcD, W64D, CSRReadD, 
          PrivilegedD, MulDivD, AtomicD, unused} = ControlsD & ~IllegalIEUInstrFaultD;
          // *** move Privileged, CSRwrite??  Or move controller out of IEU into datapath and handle all instructions

  assign CSRZeroSrcD = InstrD[14] ? (InstrD[19:15] == 0) : (Rs1D == 0); // Is a CSR instruction using zero as the source?
  assign CSRWriteD = CSRReadD & !(CSRZeroSrcD && InstrD[13]); // Don't write if setting or clearing zeros

  // ALU Decoding *** should move to ALU for better modularity
  assign sltD = (Funct3D == 3'b010);
  assign sltuD = (Funct3D == 3'b011);
  assign subD = (Funct3D == 3'b000 & Funct7D[5] & OpD[5]);
  assign sraD = (Funct3D == 3'b101 & Funct7D[5]);

  assign aluc3D = subD | sraD | sltD | sltuD; // TRUE for R-type subtracts and sra, slt, sltu

  always_comb
    case(ALUOpD)
      2'b00:                ALUControlD = 5'b00000; // addition
      2'b01:                ALUControlD = 5'b01000;  // subtraction
      2'b11:                ALUControlD = 5'b01110;  // pass B through for lui
      default:              ALUControlD = {W64D, aluc3D, Funct3D}; // R-type instructions
    endcase
  
  // Execute stage pipeline control register and logic
  flopenrc #(26) controlregE(clk, reset, FlushE, ~StallE,
                           {RegWriteD, ResultSrcD, MemRWD, JumpD, BranchD, ALUControlD, ALUSrcAD, ALUSrcBD, TargetSrcD, CSRReadD, CSRWriteD, PrivilegedD, Funct3D, W64D, MulDivD, AtomicD, 1'b1},
                           {RegWriteE, ResultSrcE, MemRWE, JumpE, BranchE, ALUControlE, ALUSrcAE, ALUSrcBE, TargetSrcE, CSRReadE, CSRWriteE, PrivilegedE, Funct3E, W64E, MulDivE, AtomicE, InstrValidE});

  // Branch Logic
  assign {zeroE, ltE, ltuE} = FlagsE;
  
  always_comb
    case(Funct3E)
      3'b000:  BranchTakenE = zeroE;  // beq
      3'b001:  BranchTakenE = ~zeroE; // bne
      3'b100:  BranchTakenE = ltE;    // blt
      3'b101:  BranchTakenE = ~ltE;   // bge
      3'b110:  BranchTakenE = ltuE;   // bltu
      3'b111:  BranchTakenE = ~ltuE;  // bgeu
      default: BranchTakenE = 1'b0; // undefined mode
    endcase
    
  assign PCSrcE = JumpE | BranchE & BranchTakenE;

  assign MemReadE = MemRWE[1]; 
  
  // Memory stage pipeline control register
  flopenrc #(14) controlregM(clk, reset, FlushM, ~StallM,
                         {RegWriteE, ResultSrcE, MemRWE, CSRReadE, CSRWriteE, PrivilegedE, Funct3E, AtomicE, InstrValidE},
                         {RegWriteM, ResultSrcM, MemRWM, CSRReadM, CSRWriteM, PrivilegedM, Funct3M, AtomicM, InstrValidM});
  
  // Writeback stage pipeline control register
  flopenrc #(5) controlregW(clk, reset, FlushW, ~StallW,
                         {RegWriteM, ResultSrcM, InstrValidM},
                         {RegWriteW, ResultSrcW, InstrValidW});  

  assign CSRWritePendingDEM = CSRWriteD | CSRWriteE | CSRWriteM;   
endmodule
