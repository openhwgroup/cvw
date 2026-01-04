`timescale 1ns/1ps

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

  logic                           TestbenchRequest;

  assign TestbenchRequest = DataAdr >= `THR_POINTER & DataAdr < `THR_POINTER + `XLEN'hF | DataAdr == `MTIME_POINTER;

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

  // DEBUG
  always @(negedge clk) begin
    int i;
    #1;
    // $display("PC: %h, Instruction %h", PC, Instr);
    if (Instr === 'x & ~reset) begin
      $display("Instruction data x (PC: %h)", PC);
      $finish(-1);
    end
    for (i =0; i < 32; i++) begin
      // if (~reset & dut.ComputeCore.RegisterFile.register_values[i] === 'x) begin
      //   $display("Register %d = 'x", i);
      //   $finish(-1);
      // end
      // if (~reset & dut.ComputeCore.RegisterFile.register_values[i] === 'z) begin
      //   $display("Register %d = 'z", i);
      //   $finish(-1);
      // end
    end
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

bit        act3_en;
longint    sig_base_addr, sig_end_addr;
string     testname;

initial begin
  // defaults
  act3_en = 0;
  sig_base_addr = 0;
  sig_end_addr  = 0;

  void'($value$plusargs("TESTNAME=%s", testname));
  $display("[TB] TESTNAME = %s", testname);
  void'($value$plusargs("ACT3=%d", act3_en));
  $display("[TB] ACT3 = %b", act3_en);

  if (act3_en) begin
    if (!$value$plusargs("SIG_BASE_ADDR=%h", sig_base_addr) ||
        !$value$plusargs("SIG_END_ADDR=%h",  sig_end_addr)) begin
      $fatal(1, "[ACT3] ACT3=1 but SIG_BASE_ADDR / SIG_END_ADDR not provided");
    end
    if (sig_end_addr <= sig_base_addr) begin
      $fatal(1, "[ACT3] Bad signature range: base=%h end=%h", sig_base_addr, sig_end_addr);
    end
    $display("[ACT3] Enabled. Signature range: [%h, %h)", sig_base_addr, sig_end_addr);
  end
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

      if(to_host_result == 1) begin
        $display("INFO: Test Passed!");
      end else if (to_host_result == 2) begin
        $display("ERROR: Test Failed");
      end

      // -------------------------------
      // ACT3 signature extraction TODO ONLY WORKS FOR XLEN=32 TODO
      // -------------------------------
      if (act3_en) begin
        string sig_path;
        int unsigned base_idx;
        int unsigned end_idx;

        sig_path = $sformatf("runs/%s.signature", testname);

        base_idx = (sig_base_addr - `DMEM_BASE_ADR) >> 2;
        end_idx  = (sig_end_addr  - `DMEM_BASE_ADR) >> 2;

        sig_fd = $fopen(sig_path, "w");
        if (sig_fd == 0) begin
          $fatal(1, "[ACT3] Could not open signature file %s", sig_path);
        end

        $display("[ACT3] Dumping signature [%h, %h) to %s",
                sig_base_addr, sig_end_addr, sig_path);

        for (sig_idx = base_idx; sig_idx < end_idx; sig_idx++) begin
          sig_word = DataMemory.Memory[sig_idx];
          $fdisplay(sig_fd, "%08x", sig_word);
        end

        $fclose(sig_fd);
        $display("[ACT3] Signature dump complete.");
      end
      // -------------------------------

      // if(to_host_result != 0) begin
      $display("[%0t] INFO: Program Finished! Ending simulation.", $time);
      $finish;
      // end
  end
end

endmodule
