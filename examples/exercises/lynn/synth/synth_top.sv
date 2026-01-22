// James Kaden Cassidy
// kacassidy@hmc.edu
// 1/22/26

`define XLEN 32
`define INSTR_BITS 32

`define ELF_BASE_ADR (`XLEN'h0)
`define IMEM_BASE_ADR (`ELF_BASE_ADR)
`define DMEM_BASE_ADR (`ELF_BASE_ADR)

`define MaxInstrSizeWords 1
`define MaxDataSizeWords 1


module synth_top (
        input logic clk,
        input logic reset
    );

    logic [`XLEN-1:0]               PC;
    logic [`INSTR_BITS-1:0]         Instr;

    // Data side interface (byte addresses)
    logic [`XLEN-1:0]               DataAdr;
    logic [`XLEN-1:0]               ReadData, MemReadData;
    logic [`XLEN-1:0]               WriteData;
    logic                           WriteEn;
    logic                           MemEn;
    logic [`XLEN/8-1:0]             WriteByteEn;   // byte enables, one per 8 bits

    /* ------- PROCESSOR Instantiation ------- */

    ram1p1rwb #(
        .MEMORY_NAME              ("Instruction Memory"),
        .ADDRESS_BITS             (`XLEN),
        .DATA_BITS                (32),
        .MEMORY_SIZE_ENTRIES      (`MaxInstrSizeWords),
        .MEMORY_FILE_BASE_ADDRESS (`ELF_BASE_ADR),
        .MEMORY_ADR_OFFSET        (`IMEM_BASE_ADR),
        .MEMFILE_PLUS_ARG         ("MEMFILE")
    ) InstructionMemory (.clk, .reset, .En(1'b1), .WriteEn(1'b0), .WriteByteEn(4'b0), .MemoryAddress(PC), .WriteData(), .ReadData(Instr));

    ram1p1rwb #(
        .MEMORY_NAME              ("Data Memory"),
        .ADDRESS_BITS             (`XLEN),
        .DATA_BITS                (`XLEN),
        .MEMORY_SIZE_ENTRIES      ((`MaxInstrSizeWords + `MaxDataSizeWords)),
        .MEMORY_FILE_BASE_ADDRESS (`ELF_BASE_ADR),
        .MEMORY_ADR_OFFSET        (`DMEM_BASE_ADR),
        .MEMFILE_PLUS_ARG         ("MEMFILE")
    ) DataMemory (.clk, .reset, .En(MemEn), .WriteEn, .WriteByteEn, .MemoryAddress(DataAdr), .WriteData, .ReadData(MemReadData));

    // ------------------------------------------------------------
    // DUT instantiation
    // ------------------------------------------------------------

    `PROCESSORTOP dut (
        .clk            (clk),
        .reset          (reset),

        // Instruction memory interface (byte address)
        .PC             (PC),
        .Instr          (Instr),

        // Data memory interface (byte address + strobes)
        .IEUAdr         (DataAdr),
        .ReadData       (ReadData),
        .WriteData      (WriteData),
        .MemEn          (MemEn),
        .WriteEn        (WriteEn),
        .WriteByteEn    (WriteByteEn)
    );

endmodule
