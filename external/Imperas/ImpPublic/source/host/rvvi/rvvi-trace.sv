/*
 * Copyright (c) 2005-2023 Imperas Software Ltd., www.imperas.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

`define NUM_REGS 32
`define NUM_CSRS 4096

interface rvviTrace
#(
    parameter int ILEN   = 32,  // Instruction length in bits
    parameter int XLEN   = 32,  // GPR length in bits
    parameter int FLEN   = 32,  // FPR length in bits
    parameter int VLEN   = 256, // Vector register size in bits
    parameter int NHART  = 1,   // Number of harts reported
    parameter int RETIRE = 1    // Number of instructions that can retire during valid event
);
    //
    // RISCV output signals
    //
    wire                      clk;                                      // Interface clock

    wire                      valid      [(NHART-1):0][(RETIRE-1):0];   // Retired instruction
    wire [63:0]               order      [(NHART-1):0][(RETIRE-1):0];   // Unique instruction order count (no gaps or reuse)
    wire [(ILEN-1):0]         insn       [(NHART-1):0][(RETIRE-1):0];   // Instruction bit pattern
    wire                      trap       [(NHART-1):0][(RETIRE-1):0];   // Trapped instruction (External to Core, eg Memory Subsystem)
    wire                      halt       [(NHART-1):0][(RETIRE-1):0];   // Halted  instruction
    wire                      intr       [(NHART-1):0][(RETIRE-1):0];   // (RVFI Legacy) Flag first instruction of trap handler
    wire [1:0]                mode       [(NHART-1):0][(RETIRE-1):0];   // Privilege mode of operation
    wire [1:0]                ixl        [(NHART-1):0][(RETIRE-1):0];   // XLEN mode 32/64 bit

    wire [(XLEN-1):0]         pc_rdata   [(NHART-1):0][(RETIRE-1):0];   // PC of insn
    wire [(XLEN-1):0]         pc_wdata   [(NHART-1):0][(RETIRE-1):0];   // PC of next instruction

    // X Registers
    wire [31:0][(XLEN-1):0]   x_wdata    [(NHART-1):0][(RETIRE-1):0];   // X data value
    wire [31:0]               x_wb       [(NHART-1):0][(RETIRE-1):0];   // X data writeback (change) flag

    // F Registers
    wire [31:0][(FLEN-1):0]   f_wdata    [(NHART-1):0][(RETIRE-1):0];   // F data value
    wire [31:0]               f_wb       [(NHART-1):0][(RETIRE-1):0];   // F data writeback (change) flag

    // V Registers
    wire [31:0][(VLEN-1):0]   v_wdata    [(NHART-1):0][(RETIRE-1):0];   // V data value
    wire [31:0]               v_wb       [(NHART-1):0][(RETIRE-1):0];   // V data writeback (change) flag

    // Control & State Registers
    wire [4095:0][(XLEN-1):0] csr        [(NHART-1):0][(RETIRE-1):0];   // Full CSR Address range
    wire [4095:0]             csr_wb     [(NHART-1):0][(RETIRE-1):0];   // CSR writeback (change) flag

    wire                      lrsc_cancel[(NHART-1):0][(RETIRE-1):0];   // Implementation defined cancel

    //
    // Synchronization of NETs
    //
	wire      clkD;
	assign #1 clkD = clk;

	longint vslot;
	always @(posedge clk) vslot++;
	
    string  name[$];
    int     value[$];
    longint tslot[$];
    int     nets[string];

    function automatic void net_push(input string vname, input int vvalue);
        name.push_front(vname);
        value.push_front(vvalue);
        tslot.push_front(vslot);
    endfunction

    function automatic int net_pop(output string vname, output int vvalue, output longint vslot);
        int  ok;
        string msg;
        if (name.size() > 0) begin
            vname  = name.pop_back();
            vvalue = value.pop_back();
            vslot  = tslot.pop_back();
            nets[vname] = vvalue;
            ok = 1;
        end else begin
            ok = 0;
        end
        return ok;
    endfunction

endinterface
