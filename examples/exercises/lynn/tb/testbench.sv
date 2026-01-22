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

      // $display("DataAdr: %h, t0: %h",
      //         DataAdr,
      //         dut.ieu.dp.rf.rf[5]
      //         );


      if (Instr === 'x) begin
        $display("Instruction data x (PC: %h)", PC);
        $finish(-1);
    end

    end

  end

  // logic                           TestbenchRequest;

  // assign TestbenchRequest = (DataAdr >= `THR_POINTER) & (DataAdr < `THR_POINTER + `XLEN'hF) | (DataAdr == `MTIME_POINTER);

  // always_ff @ ( posedge clk ) begin
  //   if (reset) cycle_count <= 0;
  //   else       cycle_count <= cycle_count + 1;
  // end

  // always_ff @ ( negedge clk ) begin
  //   byte ch;
  //   int unsigned i;
  //   TestbenchRequestReadData = 'x;

  //   if (TestbenchRequest) begin
  //     if (MemEn) begin
  //       for (int i = 0; i < `XLEN/8; i++) begin
  //         if (DataAdr + i == `LSR_POINTER) begin
  //           TestbenchRequestReadData[(i+1)*8-1 -: 8] = 8'b0010_0000;
  //         end else if (DataAdr + i == `THR_POINTER) begin
  //           if (WriteEn & WriteByteEn[i]) begin
  //             ch = WriteData[(i+1)*8-1 -: 8];
  //             $write("%c", ch);
  //             if (ch == "\n") $fflush(`STDOUT);
  //           end
  //         end
  //       end
  //       if (DataAdr == `MTIME_POINTER) begin
  //         TestbenchRequestReadData = cycle_count;
  //       end
  //     end
  //     // if (TestbenchRequestReadData !== 'x) $display("Request Return Data: %h", TestbenchRequestReadData);
  //   end
  // end

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

logic[3:0]       jump_to_self_count;

always_ff @(posedge clk) begin
  if (reset)                    jump_to_self_count <= '0;
  else if (Instr == `XLEN'h06f) jump_to_self_count <= jump_to_self_count + 1;
end

always @(negedge clk) begin
  if (!reset && ((&jump_to_self_count))) begin
      $display("ERROR: Jump to self count exceeded");
      $finish(-1);
  end
end

assign TestbenchRequest = (DataAdr == `MTIME_POINTER);

always_ff @(posedge clk) begin
  if (reset) cycle_count <= 0;
  else       cycle_count <= cycle_count + 1;
end

// Only respond to mtime reads
always_ff @(negedge clk) begin
  TestbenchRequestReadData = 'x;
  if (TestbenchRequest && MemEn && !WriteEn) begin
    TestbenchRequestReadData = cycle_count;
  end
end

logic[31:0] tohost_lo, tohost_hi, payload;

always @(negedge clk) begin
  byte ch;

  #1;
  `ifdef XLEN32
  tohost_lo = DataMemory.Memory[(TO_HOST_ADR-`DMEM_BASE_ADR)>>2];
  tohost_hi = DataMemory.Memory[((TO_HOST_ADR-`DMEM_BASE_ADR)>>2) + 1];
  `endif
  `ifdef XLEN64
  {tohost_hi, tohost_lo} = DataMemory.Memory[(TO_HOST_ADR-`DMEM_BASE_ADR)>>2];
  `endif

  //$display("TOHOST DATA: %h%h, Addr %h, base %h", tohost_hi, tohost_lo, TO_HOST_ADR, `DMEM_BASE_ADR);

  if (MemEn && WriteEn && DataAdr == TO_HOST_ADR`ifdef XLEN32 + 4`endif) begin
    if (tohost_hi == 32'h0) begin
      payload = tohost_lo;

      if (payload[0]) begin
        $display("INFO: Test Completed!");
      end else begin
        $display("ERROR: Test Failed (code=0x%h)", (payload >> 1));
      end

      $display("[%0t] INFO: Program Finished! Ending simulation.", $time);
      $finish;

    // Otherwise: check for putchar code in top word, then print a character (format you can change)
    end else if (tohost_hi == 32'h01010000) begin
      ch = tohost_lo[7:0]; // adjust payload->char mapping if you want
      $write("%c", ch);
      if (ch == "\n") $fflush(`STDOUT);
    end
    // DataMemory.Memory[(TO_HOST_ADR-`DMEM_BASE_ADR)>>2] = '0;
    // `ifdef XLEN32
    // DataMemory.Memory[((TO_HOST_ADR-`DMEM_BASE_ADR)>>2) + 1] = '0;
    // `endif
  end
end


endmodule
