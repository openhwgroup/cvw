///////////////////////////////////////////
// riscvassertions.sv
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

`include "wally-config.vh"

module riscvassertions;
  initial begin
    assert (`PMP_ENTRIES == 0 | `PMP_ENTRIES==16 | `PMP_ENTRIES==64) else $error("Illegal number of PMP entries: PMP_ENTRIES must be 0, 16, or 64");
    assert (`S_SUPPORTED | `VIRTMEM_SUPPORTED == 0) else $error("Virtual memory requires S mode support");
    assert (`IDIV_BITSPERCYCLE == 1 | `IDIV_BITSPERCYCLE==2 | `IDIV_BITSPERCYCLE==4) else $error("Illegal number of divider bits/cycle: IDIV_BITSPERCYCLE must be 1, 2, or 4");
    assert (`F_SUPPORTED | ~`D_SUPPORTED) else $error("Can't support double fp (D) without supporting float (F)");
    assert (`D_SUPPORTED | ~`Q_SUPPORTED) else $error("Can't support quad fp (Q) without supporting double (D)");
    assert (`F_SUPPORTED | ~`ZFH_SUPPORTED) else $error("Can't support half-precision fp (ZFH) without supporting float (F)");
    assert (`DCACHE_SUPPORTED | ~`F_SUPPORTED | `FLEN <= `XLEN) else $error("Data cache required to support FLEN > XLEN because AHB bus width is XLEN");
    assert (`I_SUPPORTED ^ `E_SUPPORTED) else $error("Exactly one of I and E must be supported");
    assert (`FLEN<=`XLEN | `DCACHE_SUPPORTED | `DTIM_SUPPORTED) else $error("Wally does not support FLEN > XLEN unleses data cache or DTIM is supported");
    assert (`DCACHE_WAYSIZEINBYTES <= 4096 | (!`DCACHE_SUPPORTED) | `VIRTMEM_SUPPORTED == 0) else $error("DCACHE_WAYSIZEINBYTES cannot exceed 4 KiB when caches and vitual memory is enabled (to prevent aliasing)");
    assert (`DCACHE_LINELENINBITS >= 128 | (!`DCACHE_SUPPORTED)) else $error("DCACHE_LINELENINBITS must be at least 128 when caches are enabled");
    assert (`DCACHE_LINELENINBITS < `DCACHE_WAYSIZEINBYTES*8) else $error("DCACHE_LINELENINBITS must be smaller than way size");
    assert (`ICACHE_WAYSIZEINBYTES <= 4096 | (!`ICACHE_SUPPORTED) | `VIRTMEM_SUPPORTED == 0) else $error("ICACHE_WAYSIZEINBYTES cannot exceed 4 KiB when caches and vitual memory is enabled (to prevent aliasing)");
    assert (`ICACHE_LINELENINBITS >= 32 | (!`ICACHE_SUPPORTED)) else $error("ICACHE_LINELENINBITS must be at least 32 when caches are enabled");
    assert (`ICACHE_LINELENINBITS < `ICACHE_WAYSIZEINBYTES*8) else $error("ICACHE_LINELENINBITS must be smaller than way size");
    assert (2**$clog2(`DCACHE_LINELENINBITS) == `DCACHE_LINELENINBITS | (!`DCACHE_SUPPORTED)) else $error("DCACHE_LINELENINBITS must be a power of 2");
    assert (2**$clog2(`DCACHE_WAYSIZEINBYTES) == `DCACHE_WAYSIZEINBYTES | (!`DCACHE_SUPPORTED)) else $error("DCACHE_WAYSIZEINBYTES must be a power of 2");
    assert (2**$clog2(`ICACHE_LINELENINBITS) == `ICACHE_LINELENINBITS | (!`ICACHE_SUPPORTED)) else $error("ICACHE_LINELENINBITS must be a power of 2");
    assert (2**$clog2(`ICACHE_WAYSIZEINBYTES) == `ICACHE_WAYSIZEINBYTES | (!`ICACHE_SUPPORTED)) else $error("ICACHE_WAYSIZEINBYTES must be a power of 2");
    assert (2**$clog2(`ITLB_ENTRIES) == `ITLB_ENTRIES | `VIRTMEM_SUPPORTED==0) else $error("ITLB_ENTRIES must be a power of 2");
    assert (2**$clog2(`DTLB_ENTRIES) == `DTLB_ENTRIES | `VIRTMEM_SUPPORTED==0) else $error("DTLB_ENTRIES must be a power of 2");
    assert (`UNCORE_RAM_RANGE >= 56'h07FFFFFF) else $warning("Some regression tests will fail if UNCORE_RAM_RANGE is less than 56'h07FFFFFF");
	  assert (`ZICSR_SUPPORTED == 1 | (`PMP_ENTRIES == 0 & `VIRTMEM_SUPPORTED == 0)) else $error("PMP_ENTRIES and VIRTMEM_SUPPORTED must be zero if ZICSR not supported.");
    assert (`ZICSR_SUPPORTED == 1 | (`S_SUPPORTED == 0 & `U_SUPPORTED == 0)) else $error("S and U modes not supported if ZICSR not supported");
    assert (`U_SUPPORTED | (`S_SUPPORTED == 0)) else $error ("S mode only supported if U also is supported");
    assert (`VIRTMEM_SUPPORTED == 0 | (`DTIM_SUPPORTED == 0 & `IROM_SUPPORTED == 0)) else $error("Can't simultaneously have virtual memory and DTIM_SUPPORTED/IROM_SUPPORTED because local memories don't translate addresses");
    assert (`DCACHE_SUPPORTED | `VIRTMEM_SUPPORTED ==0) else $error("Virtual memory needs dcache");
    assert (`ICACHE_SUPPORTED | `VIRTMEM_SUPPORTED ==0) else $error("Virtual memory needs icache");
    assert ((`DCACHE_SUPPORTED == 0 & `ICACHE_SUPPORTED == 0) | `BUS_SUPPORTED) else $error("Dcache and Icache requires DBUS_SUPPORTED.");
    assert (`DCACHE_LINELENINBITS <= `XLEN*16 | (!`DCACHE_SUPPORTED)) else $error("DCACHE_LINELENINBITS must not exceed 16 words because max AHB burst size is 1");
    assert (`DCACHE_LINELENINBITS % 4 == 0) else $error("DCACHE_LINELENINBITS must hold 4, 8, or 16 words");
    assert (`DCACHE_SUPPORTED | `A_SUPPORTED == 0) else $error("Atomic extension (A) requires cache on Wally.");
    assert (`IDIV_ON_FPU == 0 | `F_SUPPORTED) else $error("IDIV on FPU needs F_SUPPORTED");
    assert (`SSTC_SUPPORTED == 0 | (`S_SUPPORTED)) else $error("SSTC requires S_SUPPORTED");
  end

endmodule


