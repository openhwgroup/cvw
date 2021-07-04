///////////////////////////////////////////
// adrdecs.sv
//
// Written: David_Harris@hmc.edu 22 June 2021
// Modified: 
//
// Purpose: All the address decoders for peripherals
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

`include "wally-config.vh"
  // verilator lint_off UNOPTFLAT 

module adrdecs (
  input  logic [`PA_BITS-1:0] PhysicalAddress,
  input  logic                AccessRW, AccessRX, AccessRWX,
  input  logic [1:0]          Size,
  output logic [6:0]          SelRegions
);

 // Determine which region of physical memory (if any) is being accessed
 // *** eventually uncomment Access signals
  adrdec boottimdec(PhysicalAddress, `BOOTTIM_BASE, `BOOTTIM_RANGE, `BOOTTIM_SUPPORTED, 1'b1/*AccessRX*/, Size, 4'b1111, SelRegions[5]);
  adrdec timdec(PhysicalAddress, `TIM_BASE, `TIM_RANGE, `TIM_SUPPORTED, 1'b1/*AccessRWX*/, Size, 4'b1111, SelRegions[4]);
  adrdec clintdec(PhysicalAddress, `CLINT_BASE, `CLINT_RANGE, `CLINT_SUPPORTED, AccessRW, Size, 4'b1111, SelRegions[3]);
  adrdec gpiodec(PhysicalAddress, `GPIO_BASE, `GPIO_RANGE, `GPIO_SUPPORTED, AccessRW, Size, 4'b0100, SelRegions[2]);
  adrdec uartdec(PhysicalAddress, `UART_BASE, `UART_RANGE, `UART_SUPPORTED, AccessRW, Size, 4'b0001, SelRegions[1]);
  adrdec plicdec(PhysicalAddress, `PLIC_BASE, `PLIC_RANGE, `PLIC_SUPPORTED, AccessRW, Size, 4'b0100, SelRegions[0]);

  assign SelRegions[6] = ~|(SelRegions[5:0]);

endmodule

  // verilator lint_on UNOPTFLAT 
