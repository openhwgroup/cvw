`timescale 1ns/1ps

// If DUT_MODULE isn't defined on the vlog command line,
// fall back to a default name.

`define INSTR_BITS 32

`define MaxInstrSizeWords 16384
`define MaxDataSizeWords 4096

module testbench;

  // ------------------------------------------------------------
  // Parameters
  // ------------------------------------------------------------
  parameter int MEM_WORDS  = 64000;                      // words in instr_memfile
  localparam int BYTES_PER_WORD = `XLEN / 8;
  localparam int MEM_BYTES  = MEM_WORDS * BYTES_PER_WORD;

  // Base address of memory (first byte)
  localparam logic [`XLEN-1:0] MEM_BASE_ADDR = `XLEN'(1 << `XLEN-1); // 80000000 base pc
  localparam logic [`XLEN-1:0] MEM_LIMIT_ADDR = MEM_BASE_ADDR + MEM_BYTES;

  // ------------------------------------------------------------
  // Clock / Reset
  // ------------------------------------------------------------
  logic clk;
  logic reset;  // active-high reset

  // 100 MHz clock: 10 ns period (change as needed)
  initial clk = 0;
  always #5 clk = ~clk;

  // Simple reset sequence
  initial begin
    reset = 1;
    #10;         // hold reset for a bit
    reset = 0;   // release reset
  end

  logic [`XLEN-1:0]               prev_write_adr, prev_write_data;

  // Instruction side interface (byte addresses)
  logic [`XLEN-1:0]               PC;
  logic [`INSTR_BITS-1:0]         Instr;

  // Data side interface (byte addresses)
  logic [`XLEN-1:0]               DataAdr;
  logic [`XLEN-1:0]               ReadData;
  logic [`XLEN-1:0]               WriteData;
  logic                           WriteEn;
  logic                           MemEn;
  logic [`XLEN/8-1:0]             WriteByteEn;   // byte enables, one per 8 bits


        // // UART-style console output at 0x10000000
        // if (addr == `XLEN'h1000_0000) begin
        //     int unsigned i;
        //     for (int i = 0; i < BYTES_PER_WORD; i++) begin
        //         if (wstrb[i-1]) begin
        //             $write("%c", wdata[i*8-1 -: 8]);
        //             $fflush();
        //         end
        //     end
        //     return;  // Don't store into memory buffer
        // end

  vectorStorage #(
    .ADDRESS_BITS             (`XLEN),
    .DATA_BITS                (`XLEN),
    .MEMORY_SIZE_ENTRIES      (`MaxInstrSizeWords),
    .MEMORY_FILE_BASE_ADDRESS (`XLEN'h8000_0000),
    .MEMORY_ADR_OFFSET        (`XLEN'h8000_0000),
    .MEMFILE_PLUS_ARG         ("MEMFILE")
  ) InstructionMemory (.clk, .reset, .En(1'b1), .WriteEn(1'b0), .WriteByteEn(4'b0), .MemoryAddress(PC), .WriteData(), .ReadData(Instr));

  vectorStorage #(
    .ADDRESS_BITS             (`XLEN),
    .DATA_BITS                (`XLEN),
    .MEMORY_SIZE_ENTRIES      (`MaxDataSizeWords),
    .MEMORY_FILE_BASE_ADDRESS (`XLEN'h8000_0000),
    .MEMORY_ADR_OFFSET        (`XLEN'h8001_0000),
    .MEMFILE_PLUS_ARG         ("MEMFILE")
  ) DataMemory (.clk, .reset, .En(MemEn), .WriteEn, .WriteByteEn, .MemoryAddress(DataAdr), .WriteData, .ReadData);

  // DEBUG
  always @(negedge clk) begin
    $display("PC: %h \tInstruction run: %h", PC, Instr);
    // $display("PC: %h PC_NEXT: %h", dut.PC, dut.ifu.PCNext);
  end

  // ------------------------------------------------------------
  // DUT instantiation
  // ------------------------------------------------------------

  `DUT_MODULE dut (
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

initial begin
    // Wait until reset deasserts
    @(negedge reset);
    $display("[%0t] INFO: Starting simulation.", $time);
end

always @(negedge clk) begin
  // Jump to self
  if (!reset && Instr == `XLEN'h06f) begin
      $display("[%0t] INFO: Program Finished! Ending simulation.", $time);
      $finish;
  end
end

endmodule
