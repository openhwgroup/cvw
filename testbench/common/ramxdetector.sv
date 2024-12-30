///////////////////////////////////////////
// ramxdetector.sv
//
// Written: David_Harris@hmc.edu
// Modified: 2 July 2023
//
// Purpose: Detects if the processor is attempting to read unitialized RAM
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
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

module ramxdetector #(parameter XLEN, LLEN) (
  input  logic            clk,
  input  logic            MemReadM,
  input  logic            LSULoadAccessFaultM,
  input  logic [LLEN-1:0] ReadDataM,
  input  logic [XLEN-1:0] PCM,
  input  logic [31:0]     InstrM,
  input  logic [XLEN-1:0] IEUAdrM,
  input  string           InstrMName
);

  always_ff @(posedge clk)
    /* verilator lint_off WIDTHXZEXPAND */
    if (MemReadM & ~LSULoadAccessFaultM & (ReadDataM === 'bx)) begin
      /* verilator lint_on WIDTHXZEXPAND */
      $display("WARNING: Attempting to read from unitialized RAM.  Processor may go haywire if it uses x value. But this is normal in WALLY-mmu and ExceptionInstr tests.");
      $display("  PCM = %x InstrM = %x (%s), IEUAdrM = %x", PCM, InstrM, InstrMName, IEUAdrM);
      //$stop;
    end
  
endmodule
