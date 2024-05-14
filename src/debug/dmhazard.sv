///////////////////////////////////////////
// dmhazard.sv
//
// Written: matthew.n.otto@okstate.edu 10 May 2024
// Modified: 
//
// Purpose: Determine stalls during DM initiated Halt, Step and Resume
// 
// Documentation: RISC-V System on Chip Design 
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module dmhazard(
  input  logic clk, rst,

  input  logic HaltReq,       // Initiate core halt
  output logic Halted,        // Signals completion of halt
  input  logic ResumeReq,     // Initiates core resume
  output logic ResumeConfirm, // Signals completion of Resume (step or unhalt)
  input  logic HaltOnReset,   // Halts core immediately on reset

  output logic DebugHalt, DebugResume, // Transistions hazard unit to/from debug (single stage) mode
  output logic DebugStallF, DebugStallD, DebugStallE, DebugStallM, DebugStallW
);

// On Debug Halt, The IFU is stalled and the pipe is allowed to empty natually

// During Debug Step, only one stage is unstalled at a time. No stages are ever flushed
// Effectively turns pipeline into a single stage

(* mark_debug = "true" *)enum bit [3:0] {
  RUNNING, // Core is running normally
  IDLE,    // Core is halted and idle (no instruction in flight)
  HALT_F,
  HALT_D,
  HALT_E,
  HALT_M,
  HALT_W,
  STEP_F,
  STEP_D,
  STEP_E,
  STEP_M,
  STEP_W
} State;

assign DebugHalt = (State != RUNNING);

always_ff @(posedge clk) begin
  if (rst) begin
    State <= HaltOnReset ? IDLE : RUNNING;
    Halted <= 0;
    DebugResume <= 0;
    DebugStallF <= HaltOnReset;
    DebugStallD <= HaltOnReset;
    DebugStallE <= HaltOnReset;
    DebugStallM <= HaltOnReset;
    DebugStallW <= HaltOnReset;
  end else begin
    case (State)
      RUNNING : begin
        ResumeConfirm <= 0;
        DebugResume <= 0;
        State <= HaltReq ? HALT_F : RUNNING;
      end

      IDLE : begin
        ResumeConfirm <= 0;
        if (ResumeReq) begin
          Halted <= 0;
          ResumeConfirm <= 1;
          DebugStallF <= 0;
          DebugStallD <= 0;
          DebugStallE <= 0;
          DebugStallM <= 0;
          DebugStallW <= 0;
          DebugResume <= 1;
          State <= RUNNING;
        end else if (HaltReq && ResumeReq) begin
          DebugStallF <= 0;
          State <= STEP_F;
        end
      end

      STEP_F : begin
        DebugStallF <= 1;
        DebugStallD <= 0;
        State <= STEP_D;
      end
      STEP_D : begin
        DebugStallD <= 1;
        DebugStallE <= 0;
        State <= STEP_E;
      end
      STEP_E : begin
        DebugStallE <= 1;
        DebugStallM <= 0;
        State <= STEP_M;
      end
      STEP_M : begin
        DebugStallM <= 1;
        DebugStallW <= 0;
        State <= STEP_W;
      end
      STEP_W : begin
        DebugStallW <= 1;
        ResumeConfirm <= 1;
        State <= IDLE;
      end

      HALT_F : begin
        DebugStallF <= 1;
        State <= HALT_D;
      end
      HALT_D : begin
        DebugStallD <= 1;
        State <= HALT_E;
      end
      HALT_E : begin
        DebugStallE <= 1;
        State <= HALT_M;
      end
      HALT_M : begin
        DebugStallM <= 1;
        State <= HALT_W;
      end
      HALT_W : begin
        DebugStallW <= 1;
        Halted <= 1;
        State <= IDLE;
      end
    endcase
  end
end

endmodule

/*
[  343.129629] CPU: 0 PID: 0 Comm: swapper Not tainted 6.6.0 #2
[  343.136509] Hardware name: wally-virt,qemu (DT)
[  343.141794] Unable to handle kernel NULL pointer dereference at virtual address 0000000000000100
[  343.151478] Oops [#1]
[  343.154347] Modules linked in:
[  343.158184] CPU: 0 PID: 0 Comm: swapper Not tainted 6.6.0 #2
[  343.164699] Hardware name: wally-virt,qemu (DT)
[  343.169846] epc : __show_regs+0x1c/0x160
[  343.174840]  ra : __show_regs+0x1c/0x160
[  343.179684] epc : ffffffff80003418 ra : ffffffff80003418 sp : ffffffff81e03e00
[  343.187754]  gp : ffffffff81ea8300 tp : ffffffff81e0c580 t0 : 2000000000000000
[  343.195802]  t1 : 0000000000000048 t2 : 2065726177647261 s0 : ffffffff81e03e20
[  343.203839]  s1 : 0000000000000000 a0 : ffffffff81a8bd10 a1 : ffffffff81e0c580
[  343.211868]  a2 : 0000000000000010 a3 : 0000000000000001 a4 : 0000000000000000
[  343.219868]  a5 : 0000000000000000 a6 : 0000000000000033 a7 : 0000000000000038
[  343.227865]  s2 : ffffffff81aa9180 s3 : ffffaf800fc78500 s4 : 0000000000000000
[  343.235895]  s5 : ffffffff81ea8018 s6 : ffffffff80600008 s7 : 0000000080020040
[  343.243936]  s8 : 0000000000002000 s9 : 00000000800226e0 s10: 0000000000000000
[  343.251949]  s11: 0000000000000000 t3 : ffffffff81eb73df t4 : ffffffff81eb73df
[  343.259978]  t5 : ffffffff81eb73e0 t6 : ffffffff81e03bd8
[  343.266003] status: 0000000200000100 badaddr: 0000000000000100 cause: 000000000000000d
[  343.274764] [<ffffffff80003418>] __show_regs+0x1c/0x160
[  343.281065] [<ffffffff80273d46>] default_idle_call+0x1a/0x2c
[  343.287958] [<ffffffff80031870>] do_idle+0x6a/0x86
[  343.293917] [<ffffffff800319a4>] cpu_startup_entry+0x1c/0x1e
[  343.300720] [<ffffffff80273e22>] kernel_init+0x0/0x10a
[  343.307022] [<ffffffff8040066e>] arch_post_acpi_subsys_init+0x0/0xc
[  343.314432] [<ffffffff80400cb0>] console_on_rootfs+0x0/0x68
[  343.321597] Code: 1000 84aa 9517 01a8 0513 9085 a097 0024 80e7 37a0 (b783) 1004 
[  343.329753] ---[ end trace 0000000000000000 ]---
[  343.335050] Kernel panic - not syncing: Attempted to kill the idle task!
[  343.342485] ---[ end Kernel panic - not syncing: Attempted to kill the idle task! ]---
*/