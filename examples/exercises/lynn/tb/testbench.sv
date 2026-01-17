`timescale 1ns/1ps

`include "parameters.svh"

// If DUT_MODULE isn't defined on the vlog command line,
// fall back to a default name.
`define INSTR_BITS 32

`define ELF_BASE_ADR (`XLEN'h8000_0000)
`define IMEM_BASE_ADR (`ELF_BASE_ADR)
`define DMEM_BASE_ADR (`ELF_BASE_ADR)

`define MaxInstrSizeWords 1048576
// 16384
`define MaxDataSizeWords 1048576

`define THR_POINTER (`XLEN'h1000_0000)
`define LSR_POINTER (`THR_POINTER + `XLEN'h5)
`define MTIME_POINTER (`XLEN'h0200bff8)

`define STDOUT (`XLEN'h8000_0001)


module testbench;

  logic clk;
  logic reset;
  logic [`XLEN-1:0] cycle_count;

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
  logic [`XLEN-1:0]               ReadData, MemReadData, TestbenchRequestReadData;
  logic [`XLEN-1:0]               WriteData;
  logic                           WriteEn;
  logic                           MemEn;
  logic [`XLEN/8-1:0]             WriteByteEn;   // byte enables, one per 8 bits


  // DEBUG
  always @(negedge clk) begin
    int i;
    #1;

    if (~reset) begin

      //$display("PC: %h \t Instr: %h", PC, Instr);

      // $display("MemEn: %b",
      //         MemEn
      //         );

      if (Instr === 'x) begin
        $display("Instruction data x (PC: %h)", PC);
        $finish(-1);
    end

    end

  end

  logic                           TestbenchRequest;

  assign TestbenchRequest = (DataAdr >= `THR_POINTER) & (DataAdr < `THR_POINTER + `XLEN'hF) | (DataAdr == `MTIME_POINTER);

  always_ff @ ( posedge clk ) begin
    if (reset) cycle_count <= 0;
    else       cycle_count <= cycle_count + 1;
  end

  always_ff @ ( negedge clk ) begin
    byte ch;
    int unsigned i;
    TestbenchRequestReadData = 'x;

    if (TestbenchRequest) begin
      if (MemEn) begin
        for (int i = 0; i < `XLEN/8; i++) begin
          if (DataAdr + i == `LSR_POINTER) begin
            TestbenchRequestReadData[(i+1)*8-1 -: 8] = 8'b0010_0000;
          end else if (DataAdr + i == `THR_POINTER) begin
            if (WriteEn & WriteByteEn[i]) begin
              ch = WriteData[(i+1)*8-1 -: 8];
              $write("%c", ch);
              if (ch == "\n") $fflush(`STDOUT);
            end
          end
        end
        if (DataAdr == `MTIME_POINTER) begin
          TestbenchRequestReadData = cycle_count;
        end
      end
      // if (TestbenchRequestReadData !== 'x) $display("Request Return Data: %h", TestbenchRequestReadData);
    end
  end

  vectorStorage #(
    .MEMORY_NAME              ("Instruction Memory"),
    .ADDRESS_BITS             (`XLEN),
    .DATA_BITS                (32),
    .MEMORY_SIZE_ENTRIES      (`MaxInstrSizeWords),
    .MEMORY_FILE_BASE_ADDRESS (`ELF_BASE_ADR),
    .MEMORY_ADR_OFFSET        (`IMEM_BASE_ADR),
    .MEMFILE_PLUS_ARG         ("MEMFILE")
  ) InstructionMemory (.clk, .reset, .En(1'b1), .WriteEn(1'b0), .WriteByteEn(4'b0), .MemoryAddress(PC), .WriteData(), .ReadData(Instr));

  vectorStorage #(
    .MEMORY_NAME              ("Data Memory"),
    .ADDRESS_BITS             (`XLEN),
    .DATA_BITS                (`XLEN),
    .MEMORY_SIZE_ENTRIES      ((`MaxInstrSizeWords + `MaxDataSizeWords)),
    .MEMORY_FILE_BASE_ADDRESS (`ELF_BASE_ADR),
    .MEMORY_ADR_OFFSET        (`DMEM_BASE_ADR),
    .MEMFILE_PLUS_ARG         ("MEMFILE")
  ) DataMemory (.clk, .reset, .En(MemEn & ~TestbenchRequest), .WriteEn, .WriteByteEn, .MemoryAddress(DataAdr), .WriteData, .ReadData(MemReadData));

  assign ReadData = TestbenchRequest ? TestbenchRequestReadData : MemReadData;

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
logic[3:0]       jump_to_self_count;

always_ff @(posedge clk) begin
  if (reset)                    jump_to_self_count <= '0;
  else if (Instr == `XLEN'h06f) jump_to_self_count <= jump_to_self_count + 1;
end

integer sig_fd;
integer sig_idx;
logic [31:0] sig_word;

always @(negedge clk) begin
  // Jump to self
  to_host_result = DataMemory.Memory[(TO_HOST_ADR-`DMEM_BASE_ADR)>>2];

  if (!reset && ((&jump_to_self_count) | (|to_host_result))) begin
      //$display("To Host local Adr: %h, To Host: %h", (TO_HOST_ADR-`XLEN'h8001_0000)>>2, to_host_result);

      if (to_host_result == 1) begin
        $display("INFO: Test Passed!");
      end else begin
        $display("ERROR: Test Failed");
        if (to_host_result != 2) $display("TO_HOST_DATA: %h", to_host_result);
      end

      // if(to_host_result != 0) begin
      $display("[%0t] INFO: Program Finished! Ending simulation.", $time);
      $finish;
      // end
  end
end

endmodule
