// riscvsingle.sv
// RISC-V single-cycle processor
// David_Harris@hmc.edu 2020 kacassidy@hmc.edu 2025

module riscvsingle(
    input   logic                       clk,
    input   logic                       reset,

    output  logic [`XLEN-1:0]           PC,  // instruction memory target address
    input   logic [`XLEN-1:0]           Instr, // instruction memory read data

    output  logic [`XLEN-1:0]           IEUAdr,  // data memory target address
    input   logic [`XLEN-1:0]           ReadData, // data memory read data
    output  logic [`XLEN-1:0]           WriteData, // data memory write data

    output  logic                       MemEn,
    output  logic                       WriteEn,
    output  logic [`XLEN/8-1:0]         WriteByteEn  // strobes, 1 hot stating weather a byte should be written on a store
  );
    logic [`XLEN-1:0] PCPlus4;
    logic PCSrc;

    ifu ifu(.clk, .reset, .PCSrc, .IEUAdr(IEUAdr), .PC, .PCPlus4);
    ieu ieu(.clk, .reset, .Instr(Instr), .PC, .PCPlus4, .PCSrc,
            .MemWriteStrb(WriteByteEn), .IEUAdr(IEUAdr),
            .WriteData(WriteData), .ReadData(ReadData), .Load(MemEn),
            .insn_debug(Instr));

    assign WriteEn = |WriteByteEn;
endmodule

module ifu(
        input logic clk, reset,
        input logic PCSrc,
        input logic [31:0] IEUAdr,
        output logic [31:0] PC, PCPlus4
    );
    logic [31:0] PCNext;
    // next PC logic
    flopr #(32, 32'h8000_0000) pcreg(clk, reset, PCNext, PC);
    adder pcadd4(PC, 32'd4, PCPlus4);
    mux2 #(32) pcmux(PCPlus4, IEUAdr, PCSrc, PCNext);
endmodule

module ieu(
        input   logic                       clk, reset,
        input   logic [31:0]                Instr,
        input   logic [31:0]                PC, PCPlus4,
        output  logic                       PCSrc,
        output  logic [$clog2(`XLEN)-1:0]   MemWriteStrb,
        output  logic [31:0]                IEUAdr, WriteData,
        input   logic [31:0]                ReadData,
        output  logic                       Load,

        input   logic [`XLEN-1:0]           insn_debug
    );
    logic RegWrite, Jump, Eq, ALUResultSrc, ResultSrc;
    logic [1:0] ALUSrc, ImmSrc;
    logic [1:0] ALUControl;

    controller c(.Op(Instr[6:0]), .Funct3(Instr[14:12]), .Funct7b5(Instr[30]), .Eq,
        .ALUResultSrc, .ResultSrc, .MemWriteStrb, .PCSrc,
        .ALUSrc, .RegWrite, .ImmSrc, .ALUControl, .Load, .insn_debug);

    datapath dp(.clk, .reset, .Funct3(Instr[14:12]),
        .ALUResultSrc, .ResultSrc, .ALUSrc, .RegWrite, .ImmSrc, .ALUControl, .Eq,
        .PC, .PCPlus4, .Instr, .IEUAdr, .WriteData, .ReadData);
endmodule

module controller(
        input   logic [6:0]                 Op,
        input   logic                       Eq,
        input   logic [2:0]                 Funct3,
        input   logic                       Funct7b5,
        output  logic                       ALUResultSrc,
        output  logic                       ResultSrc,
        output  logic [$clog2(`XLEN)-1:0]   MemWriteStrb,
        output  logic                       PCSrc,
        output  logic                       RegWrite,
        output  logic [1:0]                 ALUSrc, ImmSrc,
        output  logic [1:0]                 ALUControl,
        output  logic                       Load,

        input   logic [`XLEN-1:0]           insn_debug
    );
    logic Branch, Jump;
    logic Sub, ALUOp;
    logic MemWrite;
    logic [10:0] controls;

    // Main decoder
    always_comb
        case(Op)
            // RegWrite_ImmSrc_ALUSrc_ALUOp_ALUResultSrc_MemWrite_ResultSrc_Branch_Jump_Load
            7'b0000011: controls = 11'b1_00_01_0_0_0_1_0_0_1; // lw
            7'b0100011: controls = 11'b0_01_01_0_0_1_0_0_0_0; // sw
            7'b0110011: controls = 11'b1_xx_00_1_0_0_0_0_0_0; // R-type
            7'b0010011: controls = 11'b1_00_01_1_0_0_0_0_0_0; // I-type ALU
            7'b1100011: controls = 11'b0_10_11_0_0_0_0_1_0_0; // beq
            7'b1101111: controls = 11'b1_11_11_0_1_0_0_0_1_0; // jal
            default: begin
                controls = 11'bx_xx_xx_x_x_x_x_x_x_x; // non-implemented instruction

                // if (insn_debug !== 'x) begin
                //     $display("Instruction not implemented: %h", insn_debug);
                //     $finish(-1);
                // end
            end
        endcase

    assign {RegWrite, ImmSrc, ALUSrc, ALUOp, ALUResultSrc, MemWrite,
        ResultSrc, Branch, Jump} = controls;

    // ALU Control Logic
    assign Sub = ALUOp & ((Funct3 == 3'b000) & Funct7b5 & Op[5] | (Funct3 == 3'b010)); // subtract or SLT
    assign ALUControl = {Sub, ALUOp};

    // PCSrc logic
    assign PCSrc = Branch & Eq | Jump;

    // MemWrite logic
    assign MemWriteStrb = {4{MemWrite}};
endmodule

module datapath(
    input logic clk, reset,
    input logic [2:0] Funct3,
    input logic ALUResultSrc, ResultSrc,
    input logic [1:0] ALUSrc,
    input logic RegWrite,
    input logic [1:0] ImmSrc,
    input logic [1:0] ALUControl,
    output logic Eq,
    input logic [31:0] PC, PCPlus4,
    input logic [31:0] Instr,
    output logic [31:0] IEUAdr, WriteData,
    input logic [31:0] ReadData);
    logic [31:0] ImmExt;
    logic [31:0] R1, R2, SrcA, SrcB;
    logic [31:0] ALUResult, IEUResult, Result;
    // register file logic
    regfile rf(.clk, .WE3(RegWrite), .A1(Instr[19:15]), .A2(Instr[24:20]),
        .A3(Instr[11:7]), .WD3(Result), .RD1(R1), .RD2(R2));
    extend ext(.Instr(Instr[31:7]), .ImmSrc, .ImmExt);
    // ALU logic
    cmp cmp(.R1, .R2, .Eq);
    mux2 #(32) srcamux(R1, PC, ALUSrc[1], SrcA);
    mux2 #(32) srcbmux(R2, ImmExt, ALUSrc[0], SrcB);
    alu alu(.SrcA, .SrcB, .ALUControl, .Funct3, .ALUResult, .IEUAdr);
    mux2 #(32) ieuresultmux(ALUResult, PCPlus4, ALUResultSrc, IEUResult);
    mux2 #(32) resultmux(IEUResult, ReadData, ResultSrc, Result);
    assign WriteData = R2;
endmodule

module regfile(
    input logic clk,
    input logic WE3,
    input logic [4:0] A1, A2, A3,
    input logic [31:0] WD3,
    output logic [31:0] RD1, RD2);
    logic [31:0] rf[31:1];
    // three ported register file
    // read two ports combinationally (A1/RD1, A2/RD2)
    // write third port on rising edge of clock (A3/WD3/WE3)
    // register 0 hardwired to 0
    always_ff @(posedge clk)
        if (WE3) rf[A3] <= WD3;
    assign RD1 = (A1 != 0) ? rf[A1] : 0;
    assign RD2 = (A2 != 0) ? rf[A2] : 0;
endmodule

module extend(
    input logic [31:7] Instr,
    input logic [1:0] ImmSrc,
    output logic [31:0] ImmExt);
    always_comb
        case(ImmSrc)
            // I-type
            2'b00: ImmExt = {{20{Instr[31]}}, Instr[31:20]};
            // S-type (stores)
            2'b01: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
            // B-type (branches)
            2'b10: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0};
            // J-type (jal)
            2'b11: ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0};
            default: ImmExt = 32'bx; // undefined
        endcase
endmodule

module cmp(
    input logic [31:0] R1, R2,
    output logic Eq);
    assign Eq = (R1 == R2);
endmodule

module alu(
    input logic [31:0] SrcA, SrcB,
    input logic [1:0] ALUControl,
    input logic [2:0] Funct3,
    output logic [31:0] ALUResult, IEUAdr);
    logic [31:0] CondInvb, Sum, SLT;
    logic ALUOp, Sub, Overflow, Neg, LT;
    logic [2:0] ALUFunct;
    assign {Sub, ALUOp} = ALUControl;
    // Add or subtract
    assign CondInvb = Sub ? ~SrcB : SrcB;
    assign Sum = SrcA + CondInvb + Sub;
    assign IEUAdr = Sum; // Send this out to IFU and LSU
    // Set less than based on subtraction result
    assign Overflow = (SrcA[31] ^ SrcB[31]) & (SrcA[31] ^ Sum[31]);
    assign Neg = Sum[31];
    assign LT = Neg ^ Overflow;
    assign SLT = {31'b0, LT};
    assign ALUFunct = Funct3 & {3{ALUOp}}; // Force ALUFunct to 0 to Add when ALUOp = 0
    always_comb
        case (ALUFunct)
            3'b000: ALUResult = Sum; // add or sub
            3'b010: ALUResult = SLT; // slt
            3'b110: ALUResult = SrcA | SrcB; // or
            3'b111: ALUResult = SrcA & SrcB; // and
            default: ALUResult = 'x;
        endcase
endmodule
