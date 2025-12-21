`timescale 1ns/1ps

// If DUT_MODULE isn't defined on the vlog command line,
// fall back to a default name.

`define INSTR_BITS 32

`define MaxInstrSizeWords 16384
`define MaxDataSizeWords 4096

`define THR_POINTER (`XLEN'h10000000)
`define LSR_POINTER (`XLEN'h10000005)

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
  logic [`INSTR_BITS-1:0]         Instr, Prev_Instr;

  // Data side interface (byte addresses)
  logic [`XLEN-1:0]               DataAdr;
  logic [`XLEN-1:0]               ReadData, MemReadData, TestbenchRequestReadData;
  logic [`XLEN-1:0]               WriteData;
  logic                           WriteEn;
  logic                           MemEn;
  logic [`XLEN/8-1:0]             WriteByteEn;   // byte enables, one per 8 bits

  logic                           TestbenchRequest;

  always_comb begin
    int unsigned i;
    TestbenchRequest = 1'b0;
    TestbenchRequestReadData = 'x;
    if (DataAdr == `THR_POINTER) begin
      TestbenchRequest = 1'b1;
      $display("Attempting to write char from program");
      if (MemEn & WriteEn) begin
        for (int i = 0; i < `XLEN/8; i++) begin
            if (WriteByteEn[i]) begin
                $write("%c", WriteData[(i+1)*8-1 -: 8]);
                $fflush();
            end
        end
      end
    end else if (DataAdr == `LSR_POINTER) begin
      $display("Reading LSR Pointer");
      TestbenchRequest = 1'b1;
      TestbenchRequestReadData = `XLEN'b100000;
    end
  end

  vectorStorage #(
    .MEMORY_NAME              ("Instruction Memory"),
    .ADDRESS_BITS             (`XLEN),
    .DATA_BITS                (32),
    .MEMORY_SIZE_ENTRIES      (`MaxInstrSizeWords),
    .MEMORY_FILE_BASE_ADDRESS (`XLEN'h8000_0000),
    .MEMORY_ADR_OFFSET        (`XLEN'h8000_0000),
    .MEMFILE_PLUS_ARG         ("MEMFILE")
  ) InstructionMemory (.clk, .reset, .En(1'b1), .WriteEn(1'b0), .WriteByteEn(4'b0), .MemoryAddress(PC), .WriteData(), .ReadData(Instr));

  vectorStorage #(
    .MEMORY_NAME              ("Data Memory"),
    .ADDRESS_BITS             (`XLEN),
    .DATA_BITS                (`XLEN),
    .MEMORY_SIZE_ENTRIES      (`MaxDataSizeWords),
    .MEMORY_FILE_BASE_ADDRESS (`XLEN'h8000_0000),
    .MEMORY_ADR_OFFSET        (`XLEN'h8001_0000),
    .MEMFILE_PLUS_ARG         ("MEMFILE")
  ) DataMemory (.clk, .reset, .En(MemEn & ~TestbenchRequest), .WriteEn, .WriteByteEn, .MemoryAddress(DataAdr), .WriteData, .ReadData(MemReadData));

  assign ReadData = TestbenchRequest ? TestbenchRequestReadData : MemReadData;

  // DEBUG
  always @(negedge clk) begin
    #1;
    $display("PC: %h \tInstruction run: %h", PC, Instr);
    $display("DEBUG: x6: %h, x7: %h DataMemAdrByteOffset_C: %h, MemWriteDataPreShift_C: %h, MemWriteData_C: %h",
      dut.ComputeCore.RegisterFile.register_values[6],
      dut.ComputeCore.RegisterFile.register_values[7],
      dut.ComputeCore.DataMemAdrByteOffset_C,
      dut.ComputeCore.MemWriteDataPreShift_C,
      dut.ComputeCore.MemWriteData_C
      // dut.ComputeCore.RegisterFile.register_values[2],
      // dut.ComputeCore.RegisterFile.register_values[15],
      // dut.ComputeCore.RegisterFile.register_values[6],
      // dut.ComputeCore.DataMemAdr_C,
      // DataMemory.Memory[(TO_HOST_ADR-`XLEN'h8001_0000)>>2],
      // dut.ComputeCore.StoreType_C.name()
      );
    if (Instr === 'x & ~reset) begin

      $finish(-1);
    end
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

logic [`XLEN-1:0] TO_HOST_ADR;
initial begin

    TO_HOST_ADR = '0; // default
    void'($value$plusargs("TOHOST_ADDR=%h", TO_HOST_ADR)); // override if provided
    $display("[TB] TOHOST_ADDR = 0x%h", TO_HOST_ADR);

    // Wait until reset deasserts
    @(negedge reset);
    $display("[%0t] INFO: Starting simulation.", $time);


end

logic[`XLEN-1:0] to_host_result;

always_ff @(posedge clk) begin
  if (reset)  Prev_Instr <= '0;
  else        Prev_Instr <= Instr;
end

always @(negedge clk) begin
  // Jump to self

  if (!reset && Prev_Instr == `XLEN'h06f) begin
      to_host_result = DataMemory.Memory[(TO_HOST_ADR-`XLEN'h8001_0000)>>2];
      $display("To Host local Adr: %h, To Host: %h", (TO_HOST_ADR-`XLEN'h8001_0000)>>2, to_host_result);

      if(to_host_result == 1) begin
        $display("INFO: Test Passed!");
      end else if (to_host_result == 2) begin
        $display("ERROR: Test Failed");
      end
      // if(to_host_result != 0) begin
      $display("[%0t] INFO: Program Finished! Ending simulation.", $time);
      $finish;
      // end
  end
end

endmodule
