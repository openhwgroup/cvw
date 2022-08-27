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
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"
  // verilator lint_off UNOPTFLAT 

module adrdecs (
  input  logic [`PA_BITS-1:0] PhysicalAddress,
  input  logic                AccessRW, AccessRX, AccessRWX,
  input  logic [1:0]          Size,
  output logic [10:0]          SelRegions
);

  localparam logic [3:0]          SUPPORTED_SIZE = (`LLEN == 32 ? 4'b0111 : 4'b1111);
 // Determine which region of physical memory (if any) is being accessed
  adrdec ddr4dec(PhysicalAddress, `EXT_MEM_BASE, `EXT_MEM_RANGE, `EXT_MEM_SUPPORTED, AccessRWX, Size, SUPPORTED_SIZE, SelRegions[9]);  
  adrdec bootromdec(PhysicalAddress, `BOOTROM_BASE, `BOOTROM_RANGE, `BOOTROM_SUPPORTED, AccessRX, Size, SUPPORTED_SIZE, SelRegions[8]);
  adrdec uncoreramdec(PhysicalAddress, `UNCORE_RAM_BASE, `UNCORE_RAM_RANGE, `UNCORE_RAM_SUPPORTED, AccessRWX, Size, SUPPORTED_SIZE, SelRegions[7]);
  adrdec clintdec(PhysicalAddress, `CLINT_BASE, `CLINT_RANGE, `CLINT_SUPPORTED, AccessRW, Size, SUPPORTED_SIZE, SelRegions[6]);
  adrdec gpiodec(PhysicalAddress, `GPIO_BASE, `GPIO_RANGE, `GPIO_SUPPORTED, AccessRW, Size, 4'b0100, SelRegions[5]);
  adrdec uartdec(PhysicalAddress, `UART_BASE, `UART_RANGE, `UART_SUPPORTED, AccessRW, Size, 4'b0001, SelRegions[4]);
  adrdec plicdec(PhysicalAddress, `PLIC_BASE, `PLIC_RANGE, `PLIC_SUPPORTED, AccessRW, Size, 4'b0100, SelRegions[3]);
  adrdec sdcdec(PhysicalAddress, `SDC_BASE, `SDC_RANGE, `SDC_SUPPORTED, AccessRW, Size, SUPPORTED_SIZE & 4'b1100, SelRegions[2]); 

  adrdec iromdec(PhysicalAddress, `IROM_BASE, `IROM_RANGE, `IROM_SUPPORTED, AccessRX, Size, SUPPORTED_SIZE, SelRegions[1]);
  adrdec dtimdec(PhysicalAddress, `DTIM_BASE, `DTIM_RANGE, `DTIM_SUPPORTED, AccessRWX, Size, SUPPORTED_SIZE, SelRegions[0]);

  assign SelRegions[10] = ~|(SelRegions[7:0]); // none of the regions are selected

endmodule

  // verilator lint_on UNOPTFLAT 
