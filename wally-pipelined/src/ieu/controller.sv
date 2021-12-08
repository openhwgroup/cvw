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
  input  logic       StallD, FlushD,
  input  logic [31:0] InstrD,
  output logic [2:0] ImmSrcD,
  input  logic       IllegalIEUInstrFaultD, 
  output logic       IllegalBaseInstrFaultD,
  // Execute stage control signals
  input logic 	     StallE, FlushE,  
  input logic  [2:0] FlagsE, 
  output logic       PCSrcE,        // for datapath and Hazard Unit
  output logic [2:0] ALUControlE, 
  output logic 	     ALUSrcAE, ALUSrcBE,
  output logic       ALUResultSrcE,
  output logic       MemReadE, CSRReadE, // for Hazard Unit
  output logic [2:0] Funct3E,
  output logic       MulDivE, W64E,
  output logic       JumpE,	
  // Memory stage control signals
  input  logic       StallM, FlushM,
  output logic [1:0] MemRWM,
  output logic       CSRReadM, CSRWriteM, PrivilegedM,
  output logic       SCE,
  output logic [1:0] AtomicE,
  output logic [1:0] AtomicM,
  output logic [2:0] Funct3M,
  output logic       RegWriteM,     // for Hazard Unit
  output logic       InvalidateICacheM, FlushDCacheM,
  output logic       InstrValidM, 
  // Writeback stage control signals
  input  logic       StallW, FlushW,
  output logic 	     RegWriteW,     // for datapath and Hazard Unit
  output logic [2:0] ResultSrcW,
  // Stall during CSRs
  output logic       CSRWritePendingDEM,
  output logic       StoreStallD
);

  logic [6:0] OpD;
  logic [2:0] Funct3D;
  logic [6:0] Funct7D;
  logic [4:0] Rs1D;

  `define CTRLW 23

  // pipelined control signals
  logic 	    RegWriteD, RegWriteE;
  logic [2:0] ResultSrcD, ResultSrcE, ResultSrcM;
  logic [1:0] MemRWD, MemRWE;
  logic		    JumpD;
  logic		    BranchD, BranchE;
  logic	      ALUOpD;
  logic [2:0] ALUControlD;
  logic 	    ALUSrcAD, ALUSrcBD;
  logic       ALUResultSrcD, W64D, MulDivD;
  logic       CSRZeroSrcD;
  logic       CSRReadD;
  logic [1:0] AtomicD;
  logic       FenceD;
  logic       InvalidateICacheD, FlushDCacheD;
  logic       CSRWriteD, CSRWriteE;
  logic       InstrValidD, InstrValidE;
  logic       PrivilegedD, PrivilegedE;
  logic       InvalidateICacheE, FlushDCacheE;
  logic [`CTRLW-1:0] ControlsD;
  logic        SubArithD;
  logic        subD, sraD, sltD, sltuD;
  logic        BranchTakenE;
  logic        zeroE, ltE, ltuE;
  logic        unused;
	logic        BranchFlagE;

  // Extract fields
  assign OpD = InstrD[6:0];
  assign Funct3D = InstrD[14:12];
  assign Funct7D = InstrD[31:25];
  assign Rs1D = InstrD[19:15];

  // Main Instruction Decoder
  generate
    always_comb
      case(OpD)
      // RegWrite_ImmSrc_ALUSrc_MemRW_ResultSrc_Branch_ALUOp_Jump_ALUResultSrc_W64_CSRRead_Privileged_Fence_MulDiv_Atomic_Illegal
        7'b0000000:   ControlsD = `CTRLW'b0_000_00_00_000_0_0_0_0_0_0_0_0_0_00_1; // illegal instruction
        7'b0000011:   ControlsD = `CTRLW'b1_000_01_10_001_0_0_0_0_0_0_0_0_0_00_0; // lw
        7'b0000111:   ControlsD = `CTRLW'b0_000_01_10_001_0_0_0_0_0_0_0_0_0_00_0; // flw
        7'b0001111:   ControlsD = `CTRLW'b0_000_00_00_000_0_0_0_0_0_0_0_1_0_00_0; // fence
        7'b0010011:   ControlsD = `CTRLW'b1_000_01_00_000_0_1_0_0_0_0_0_0_0_00_0; // I-type ALU
        7'b0010111:   ControlsD = `CTRLW'b1_100_11_00_000_0_0_0_0_0_0_0_0_0_00_0; // auipc
        7'b0011011: if (`XLEN == 64)
                      ControlsD = `CTRLW'b1_000_01_00_000_0_1_0_0_1_0_0_0_0_00_0; // IW-type ALU for RV64i
                    else
                      ControlsD = `CTRLW'b0_000_00_00_000_0_0_0_0_0_0_0_0_0_00_1; // non-implemented instruction
        7'b0100011:   ControlsD = `CTRLW'b0_001_01_01_000_0_0_0_0_0_0_0_0_0_00_0; // sw
        7'b0100111:   ControlsD = `CTRLW'b0_001_01_01_000_0_0_0_0_0_0_0_0_0_00_0; // fsw
        7'b0101111: if (`A_SUPPORTED) begin
                      if (InstrD[31:27] == 5'b00010)
                        ControlsD = `CTRLW'b1_000_00_10_001_0_0_0_0_0_0_0_0_0_01_0; // lr
                      else if (InstrD[31:27] == 5'b00011)
                        ControlsD = `CTRLW'b1_101_01_01_100_0_0_0_0_0_0_0_0_0_01_0; // sc
                      else 
                        ControlsD = `CTRLW'b1_101_01_11_001_0_0_0_0_0_0_0_0_0_10_0;; // amo
                    end else
                      ControlsD = `CTRLW'b0_000_00_00_000_0_0_0_0_0_0_0_0_0_00_1; // non-implemented instruction
        7'b0110011: if (Funct7D == 7'b0000000 || Funct7D == 7'b0100000)
                      ControlsD = `CTRLW'b1_000_00_00_000_0_1_0_0_0_0_0_0_0_00_0; // R-type 
                    else if (Funct7D == 7'b0000001 && `M_SUPPORTED)
                      ControlsD = `CTRLW'b1_000_00_00_011_0_0_0_0_0_0_0_0_1_00_0; // Multiply/Divide
                    else
                      ControlsD = `CTRLW'b0_000_00_00_000_0_0_0_0_0_0_0_0_0_00_1; // non-implemented instruction
        7'b0110111:   ControlsD = `CTRLW'b1_100_01_00_000_0_0_0_1_0_0_0_0_0_00_0; // lui
        7'b0111011: if ((Funct7D == 7'b0000000 || Funct7D == 7'b0100000) && `XLEN == 64)
                      ControlsD = `CTRLW'b1_000_00_00_000_0_1_0_0_1_0_0_0_0_00_0; // R-type W instructions for RV64i
                    else if (Funct7D == 7'b0000001 && `M_SUPPORTED && `XLEN == 64)
                      ControlsD = `CTRLW'b1_000_00_00_011_0_0_0_0_1_0_0_0_1_00_0; // W-type Multiply/Divide
                    else
                      ControlsD = `CTRLW'b0_000_00_00_000_0_0_0_0_0_0_0_0_0_00_1; // non-implemented instruction
        //7'b1010011:   ControlsD = `CTRLW'b0_000_00_00_101_0_00_0_0_0_0_0_0_0_00_1; // FP
        7'b1100011:   ControlsD = `CTRLW'b0_010_00_00_000_1_0_0_0_0_0_0_0_0_00_0; // beq
        7'b1100111:   ControlsD = `CTRLW'b1_000_00_00_000_0_0_1_1_0_0_0_0_0_00_0; // jalr
        7'b1101111:   ControlsD = `CTRLW'b1_011_00_00_000_0_0_1_1_0_0_0_0_0_00_0; // jal
        7'b1110011: if (Funct3D == 3'b000)
                      ControlsD = `CTRLW'b0_000_00_00_000_0_0_0_0_0_0_1_0_0_00_0; // privileged; decoded further in priveleged modules
                    else
                      ControlsD = `CTRLW'b1_000_00_00_010_0_0_0_0_0_1_0_0_0_00_0; // csrs
        default:      ControlsD = `CTRLW'b0_000_00_00_000_0_0_0_0_0_0_0_0_0_00_1; // non-implemented instruction
      endcase
  endgenerate

  // unswizzle control bits
  // squash control signals if coming from an illegal compressed instruction
  assign IllegalBaseInstrFaultD = ControlsD[0];
  assign {RegWriteD, ImmSrcD, ALUSrcAD, ALUSrcBD, MemRWD,
          ResultSrcD, BranchD, ALUOpD, JumpD, ALUResultSrcD, W64D, CSRReadD, 
          PrivilegedD, FenceD, MulDivD, AtomicD, unused} = IllegalIEUInstrFaultD ? `CTRLW'b0 : ControlsD;
          // *** move Privileged, CSRwrite??  Or move controller out of IEU into datapath and handle all instructions

  assign CSRZeroSrcD = InstrD[14] ? (InstrD[19:15] == 0) : (Rs1D == 0); // Is a CSR instruction using zero as the source?
  assign CSRWriteD = CSRReadD & !(CSRZeroSrcD && InstrD[13]); // Don't write if setting or clearing zeros

  // ALU Decoding *** should move to ALU for better modularity
  assign sltD = (Funct3D == 3'b010);
  assign sltuD = (Funct3D == 3'b011);
  assign subD = (Funct3D == 3'b000 & Funct7D[5] & OpD[5]);
  assign sraD = (Funct3D == 3'b101 & Funct7D[5]);

  assign SubArithD = subD | sraD | sltD | sltuD; // TRUE for R-type subtracts and sra, slt, sltu
//  assign SubArithD = aluc3D; // ***cleanup

  // *** replace all of this
  assign ALUControlD = {W64D, SubArithD, ALUOpD};
/*  always_comb
    case(ALUOpD)
      2'b00:                ALUControlD = 5'b00000; // addition
      2'b01:                ALUControlD = 5'b00000;  // add for branch offset
//      2'b01:                ALUControlD = 5'b01000;  // subtraction
//      2'b11:                ALUControlD = 5'b01110;  // pass B through for lui ***no longer used
      default:              ALUControlD = {W64D, aluc3D, Funct3D}; // R-type instructions
    endcase*/

  // Fences
  // Ordinary fence is presently a nop
  // FENCE.I flushes the D$ and invalidates the I$ if Zifencei is supported and I$ is implemented
  generate
    if (`ZIFENCEI_SUPPORTED & `MEM_ICACHE) begin
      logic FenceID;
      assign FenceID = FenceD & (Funct3D == 3'b001); // is it a FENCE.I instruction?
      assign InvalidateICacheD = FenceID;
      assign FlushDCacheD = FenceID;
    end else begin
      assign InvalidateICacheD = 0;
      assign FlushDCacheD = 0;
    end
  endgenerate
 
  // Decocde stage pipeline control register
  flopenrc #(1)  controlregD(clk, reset, FlushD, ~StallD, 1'b1, InstrValidD);

  // Execute stage pipeline control register and logic
  flopenrc #(27) controlregE(clk, reset, FlushE, ~StallE,
                           {RegWriteD, ResultSrcD, MemRWD, JumpD, BranchD, ALUControlD, ALUSrcAD, ALUSrcBD, ALUResultSrcD, CSRReadD, CSRWriteD, PrivilegedD, Funct3D, W64D, MulDivD, AtomicD, InvalidateICacheD, FlushDCacheD, InstrValidD},
                           {RegWriteE, ResultSrcE, MemRWE, JumpE, BranchE, ALUControlE, ALUSrcAE, ALUSrcBE, ALUResultSrcE, CSRReadE, CSRWriteE, PrivilegedE, Funct3E, W64E, MulDivE, AtomicE, InvalidateICacheE, FlushDCacheE, InstrValidE});

  // Branch Logic
  assign {zeroE, ltE, ltuE} = FlagsE;
  mux4 #(1) branchflagmux(zeroE, 1'b0, ltE, ltuE, Funct3E[2:1], BranchFlagE);
  assign BranchTakenE = BranchFlagE ^ Funct3E[0];
/*  always_comb
    case(Funct3E)
      3'b000:  BranchTakenE = zeroE;  // beq
      3'b001:  BranchTakenE = ~zeroE; // bne
      3'b100:  BranchTakenE = ltE;    // blt
      3'b101:  BranchTakenE = ~ltE;   // bge
      3'b110:  BranchTakenE = ltuE;   // bltu
      3'b111:  BranchTakenE = ~ltuE;  // bgeu
      default: BranchTakenE = 1'b0; // undefined mode
    endcase*/
    
  assign PCSrcE = JumpE | BranchE & BranchTakenE;

  assign MemReadE = MemRWE[1];
  assign SCE = (ResultSrcE == 3'b100);
  
  // Memory stage pipeline control register
  flopenrc #(17) controlregM(clk, reset, FlushM, ~StallM,
                         {RegWriteE, ResultSrcE, MemRWE, CSRReadE, CSRWriteE, PrivilegedE, Funct3E, AtomicE, InvalidateICacheE, FlushDCacheE, InstrValidE},
                         {RegWriteM, ResultSrcM, MemRWM, CSRReadM, CSRWriteM, PrivilegedM, Funct3M, AtomicM, InvalidateICacheM, FlushDCacheM, InstrValidM});
  
  // Writeback stage pipeline control register
  flopenrc #(4) controlregW(clk, reset, FlushW, ~StallW,
                         {RegWriteM, ResultSrcM},
                         {RegWriteW, ResultSrcW});  

  assign CSRWritePendingDEM = CSRWriteD | CSRWriteE | CSRWriteM;

  assign StoreStallD = MemRWE[0] & (|MemRWD | |AtomicD);
endmodule
