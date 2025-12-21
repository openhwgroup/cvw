`timescale 1ns/1ps

// If DUT_MODULE isn't defined on the vlog command line,
// fall back to a default name.

`define INSTR_BITS 32

`define MaxInstrSizeWords 16384
`define MaxDataSizeWords 1048576

`define THR_POINTER (`XLEN'h1000_0000)
`define LSR_POINTER (`THR_POINTER + `XLEN'h5)
`define MTIME_POINTER (`XLEN'h0200bff8)

module testbench;

  // ------------------------------------------------------------
  // Parameters
  // ------------------------------------------------------------
  int unsigned STDOUT= 32'h8000_0001;

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
  logic [`XLEN-1:0]               ReadData, MemReadData, TestbenchRequestReadData;
  logic [`XLEN-1:0]               WriteData;
  logic                           WriteEn;
  logic                           MemEn;
  logic [`XLEN/8-1:0]             WriteByteEn;   // byte enables, one per 8 bits

  logic                           TestbenchRequest;

  assign TestbenchRequest = DataAdr >= `THR_POINTER & DataAdr < `THR_POINTER + `XLEN'hF | DataAdr == `MTIME_POINTER;

  always_ff @(negedge clk) begin
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
              if (ch == "\n") $fflush(STDOUT);
            end
          end
        end
        if (DataAdr == `MTIME_POINTER) begin
          TestbenchRequestReadData = $time;
        end
      end
      // if (TestbenchRequestReadData !== 'x) $display("Request Return Data: %h", TestbenchRequestReadData);
    end


    // if (DataAdr == `THR_POINTER) begin
    //   $display("Attempting to write char from program");
    //   $display("Writing %h to addr: %h, byte en: %b", WriteData, DataAdr, WriteByteEn);
    //   if (MemEn & WriteEn) begin
    //     for (int i = 0; i < `XLEN/8; i++) begin
    //         if (WriteByteEn[i]) begin
    //             $write("%c", WriteData[(i+1)*8-1 -: 8]);
    //             $fflush();
    //         end
    //     end
    //   end
    // end else if (DataAdr == `LSR_POINTER) begin
    //   $display("Writing %h to addr: %h, byte en: %b", WriteData, DataAdr, WriteByteEn);
    //   $display("Reading LSR Pointer");
    //   TestbenchRequestReadData = `XLEN'b100000;
    // end
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
    //$display("DEBUG: Data Adr: %h", DataAdr);
   // $display("DEBUG: a0: %h, a5: %h",
      // dut.ComputeCore.RegisterFile.register_values[10],
      // dut.ComputeCore.RegisterFile.register_values[15],

      // dut.ComputeCore.DataMemAdrByteOffset_C,
      // dut.ComputeCore.MemWriteDataPreShift_C,
      // dut.ComputeCore.MemWriteData_C
      // dut.ComputeCore.RegisterFile.register_values[2],
      // dut.ComputeCore.RegisterFile.register_values[15],
      // dut.ComputeCore.RegisterFile.register_values[6],
      // dut.ComputeCore.DataMemAdr_C,
      // DataMemory.Memory[(TO_HOST_ADR-`XLEN'h8001_0000)>>2],
      // dut.ComputeCore.StoreType_C.name()

      //);
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
logic[3:0]       jump_to_self_count;

always_ff @(posedge clk) begin
  if (reset)                    jump_to_self_count <= '0;
  else if (Instr == `XLEN'h06f) jump_to_self_count <= jump_to_self_count + 1;
end

always @(negedge clk) begin
  // Jump to self

  if (!reset && (&jump_to_self_count)) begin
      to_host_result = DataMemory.Memory[(TO_HOST_ADR-`XLEN'h8001_0000)>>2];
      //$display("To Host local Adr: %h, To Host: %h", (TO_HOST_ADR-`XLEN'h8001_0000)>>2, to_host_result);

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
