// trace2riscvISACOV.sv
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// Load which extensions are supported in this configuration (from $WALLY/config/<config>/coverage.svh)
`include "coverage.svh"
`include "disassemble.svh"

// Load the coverage classes
`include "RISCV_coverage.svh"

module trace2riscvISACOV(rvviTrace rvvi);
  string disass;
  // Connect coverage class to RVVI trace interface
  coverage #(rvvi.ILEN, rvvi.XLEN, rvvi.FLEN, rvvi.VLEN, rvvi.NHART, rvvi.RETIRE) riscvISACOV;
  initial begin
    riscvISACOV = new(rvvi);
    $display("trace2riscvISACOV: coverage initialized");
  end

  // Invoke the riscvISACOV sample function on each clock edge for the current Instruction
  // If RVVI accepts more than one instruction or hart, iterate over all of them in the
  // correct order of retirement (TODO: multiple instructions/harts not implemented)
  always_ff @(posedge rvvi.clk) begin
    if (rvvi.valid[0][0] == 1) begin
      disass = disassemble(rvvi.insn[0][0]);
      riscvISACOV.sample(rvvi.trap[0][0], 0, 0, {$sformatf("%h ", rvvi.insn[0][0]), disass});
      // $display("trace2riscvISACOV: sample taken for instruction %h: %s", rvvi.insn[0][0], disass);
      $display("0x%h: %s", rvvi.insn[0][0], disass);
    end
  end
endmodule
