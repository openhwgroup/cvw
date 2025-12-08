`timescale 1ns/1ps

// If DUT_MODULE isn't defined on the vlog command line,
// fall back to a default name.

module coremark_tb;

  // ------------------------------------------------------------
  // Parameters
  // ------------------------------------------------------------
  parameter int MEM_WORDS  = 64000;                      // words in memfile
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

  // ------------------------------------------------------------
  // Unified memory: instructions + data
  // ------------------------------------------------------------
  // 1) Word-level buffer for $readmemh (matches elf2hex output)
  logic [`XLEN-1:0] mem_words [MEM_WORDS-1:0];

  // 2) Actual byte-addressable memory used by the DUT
  logic [7:0] mem [MEM_BYTES-1:0];

  // Instruction side interface (byte addresses)
  logic [`XLEN-1:0] imem_addr;
  logic [`XLEN-1:0] imem_rdata;

  // Data side interface (byte addresses)
  logic [`XLEN-1:0] dmem_addr;
  logic [`XLEN-1:0] dmem_rdata;
  logic [`XLEN-1:0] dmem_wdata;
  logic             dmem_rvalid;
  logic [3:0]       dmem_wstrb;   // byte enables, one per 8 bits

  // ------------------------------------------------------------
  // Helper functions / tasks for memory access
  // ------------------------------------------------------------

  function automatic bit addr_in_range(input logic [`XLEN-1:0] addr);
    addr_in_range = (addr >= MEM_BASE_ADDR) && (addr < MEM_LIMIT_ADDR);
  endfunction

  // Convert byte address -> byte index into mem[]
  function automatic int unsigned addr_to_index(input logic [`XLEN-1:0] addr);
    addr_to_index = int'(addr - MEM_BASE_ADDR);
  endfunction

  // Load a 32-bit word from byte array (little-endian)
  function automatic logic [`XLEN-1:0] load_word(input logic [`XLEN-1:0] addr);
        int unsigned idx;
        logic [`XLEN-1:0] word;

        if (!addr_in_range(addr) && !reset) begin
            $display("[%0t] ERROR: load_word out-of-range addr: %h", $time, addr);
            $finish(-1);
            return '0;
        end

        idx = addr_to_index(addr);
        word = '0;

        // Load XLEN bits = XLEN/8 bytes, little-endian
        for (int i = 1; i <= `XLEN/8; i++) begin
            word[i*8-1 -: 8] = mem[idx + i-1];
        end

        return word;
    endfunction

  // Store using write strobes (byte enables)
  task automatic store_word(
        input logic [`XLEN-1:0] addr,
        input logic [`XLEN-1:0] wdata,
        input logic [$clog2(`XLEN)-1:0] wstrb
    );
        int unsigned idx;
        int i;

        // UART-style console output at 0x10000000
        if (addr == 32'h1000_0000) begin
            int unsigned i;
            for (int i = 0; i < BYTES_PER_WORD; i++) begin
                if (wstrb[i-1]) begin
                    $write("%c", wdata[i*8-1 -: 8]);
                    $fflush();
                end
            end
            return;  // Don't store into memory buffer
        end

        // actually storing words

        if (!addr_in_range(addr) && !reset) begin
            $display("[%0t] ERROR: store_word out-of-range addr %h", $time, addr);
            $finish(-1);
            return;
        end

        idx = addr_to_index(addr);

        // Write BYTES_PER_WORD bytes using strobes
        for (i = 1; i <= BYTES_PER_WORD; i++) begin
            if (wstrb[i]) mem[idx + i-1] = wdata[i*8-1 -: 8];   // each byte lane
        end
    endtask

  // Zero-wait-state memory model:
  // - instruction port: combinational read
  // - data port: combinational read, synchronous write on clk edge
  always_comb begin
    imem_rdata = load_word(imem_addr);
    if (dmem_rvalid) dmem_rdata = load_word(dmem_addr);
  end

  // DEBUG
  always @(negedge clk) begin
    $display("PC: %h \tInstruction run: %h", imem_addr, imem_rdata);
    // $display("PC: %h PC_NEXT: %h", dut.PC, dut.ifu.PCNext);
  end

  always_ff @(posedge clk) begin
    if (!reset) begin
      // Perform writes when not in reset (and any byte enable is set)
      if (dmem_wstrb != 0) begin
        store_word(dmem_addr, dmem_wdata, dmem_wstrb);
      end
    end
  end

  // ------------------------------------------------------------
  // MEMFILE load using plusargs
  // ------------------------------------------------------------
  string memfile;

  initial begin
    int base;
    int i;

    // Try to read +MEMFILE=<path> from vsim command line
    if (!$value$plusargs("MEMFILE=%s", memfile)) begin
      $display("[%0t] ERROR: +MEMFILE not supplied", $time);
      $finish(-1);
    end else begin
      $display("[%0t] INFO: Using MEMFILE = '%s'", $time, memfile);
    end

    // Load program into word buffer
    $display("[%0t] INFO: Loading mem_words from '%s'", $time, memfile);
    $readmemh(memfile, mem_words);
    $display("[%0t] INFO: mem_words load complete, expanding into bytes.", $time);

    // Expand each XLEN-bit word from mem_words[] into byte-addressable mem[]
    for (i = 0; i < MEM_WORDS; i++) begin
        base = i * (`XLEN/8);  // starting byte position for this word

        // For each byte in the XLEN-bit word
        for (int b = 0; b < (`XLEN/8); b++) begin
            // Extract byte b from mem_words[i], little-endian
            mem[base + b] = mem_words[i][(b*8 + 7) -: 8];
        end
    end

    $display("[%0t] INFO: Unified byte-addressable memory initialized.", $time);
  end

  // ------------------------------------------------------------
  // DUT instantiation
  // ------------------------------------------------------------
  // `DUT_MODULE dut (
  //   .clk        (clk),
  //   .reset      (reset),

  //   // Instruction memory interface (byte address)
  //   .imem_a,
  //   .imem_rd,

  //   // Data memory interface (byte address + strobes)
  //   .dmem_a,
  //   .dmem_rd,
  //   .dmem_wd,
  //   .dmem_we
  // );

  `DUT_MODULE dut (
    .clk        (clk),
    .reset      (reset),

    // Instruction memory interface (byte address)
    .imem_addr  (imem_addr),
    .imem_rdata (imem_rdata),

    // Data memory interface (byte address + strobes)
    .dmem_addr  (dmem_addr),
    .dmem_rdata (dmem_rdata),
    .dmem_wdata (dmem_wdata),
    .dmem_rvalid(dmem_rvalid),
    .dmem_wstrb (dmem_wstrb)
  );

  localparam logic [`XLEN-1:0] FINISH_PC = 'x;   // <-- put your PC value here

initial begin
    // Wait until reset deasserts
    @(negedge reset);
    $display("[%0t] INFO: Starting simulation.", $time);
end

always @(negedge clk) begin
  if (!reset && imem_rdata == `XLEN'h06f) begin
      $display("[%0t] INFO: Program Finished! Ending simulation.", $time);
      $finish;
  end
end

endmodule
