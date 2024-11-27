///////////////////////////////////////////
//
// WALLY-CSR-permissions
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-02-05
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

#include "WALLY-TEST-LIB-32.h" 

RVTEST_ISA("RV32I_Zicsr")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",csr-permission-s)

INIT_TESTS

TRAP_HANDLER m

# Test 5.2.3.6: Test that all the machine mode CSR's are innaccessible for reads and writes in S mode.

GOTO_S_MODE 0x0, 0x0

# Attempt to write 0x111 to each of these CSRs and read the value back
# should result in an illegal instruction for the write and read, respectively

# High-bit versions storing the upper 32 bits of some CSRs for RV32
WRITE_READ_CSR mstatush 0x111
WRITE_READ_CSR menvcfgh 0x111
WRITE_READ_CSR mseccfgh 0x111
WRITE_READ_CSR pmpcfg1 0x111
WRITE_READ_CSR pmpcfg3 0x111
WRITE_READ_CSR mcycleh 0x111
WRITE_READ_CSR minstreth 0x111
WRITE_READ_CSR mhpmcounter3h 0x111
WRITE_READ_CSR mhpmcounter4h 0x111
WRITE_READ_CSR mhpmcounter5h 0x111
WRITE_READ_CSR mhpmcounter6h 0x111
WRITE_READ_CSR mhpmcounter7h 0x111
WRITE_READ_CSR mhpmcounter8h 0x111
WRITE_READ_CSR mhpmcounter9h 0x111
WRITE_READ_CSR mhpmcounter10h 0x111
WRITE_READ_CSR mhpmcounter11h 0x111
WRITE_READ_CSR mhpmcounter12h 0x111
WRITE_READ_CSR mhpmcounter13h 0x111
WRITE_READ_CSR mhpmcounter14h 0x111
WRITE_READ_CSR mhpmcounter15h 0x111
WRITE_READ_CSR mhpmcounter16h 0x111
WRITE_READ_CSR mhpmcounter17h 0x111
WRITE_READ_CSR mhpmcounter18h 0x111
WRITE_READ_CSR mhpmcounter19h 0x111
WRITE_READ_CSR mhpmcounter20h 0x111
WRITE_READ_CSR mhpmcounter21h 0x111
WRITE_READ_CSR mhpmcounter22h 0x111
WRITE_READ_CSR mhpmcounter23h 0x111
WRITE_READ_CSR mhpmcounter24h 0x111
WRITE_READ_CSR mhpmcounter25h 0x111
WRITE_READ_CSR mhpmcounter26h 0x111
WRITE_READ_CSR mhpmcounter27h 0x111
WRITE_READ_CSR mhpmcounter28h 0x111
WRITE_READ_CSR mhpmcounter29h 0x111
WRITE_READ_CSR mhpmcounter30h 0x111
WRITE_READ_CSR mhpmcounter31h 0x111

# Machine information Registers
WRITE_READ_CSR mvendorid, 0x111
WRITE_READ_CSR marchid, 0x111
WRITE_READ_CSR mimpid, 0x111
WRITE_READ_CSR mhartid, 0x111
WRITE_READ_CSR mconfigptr, 0x111

# Machine Trap Setup
WRITE_READ_CSR mstatus, 0x111
WRITE_READ_CSR mstatush, 0x111
WRITE_READ_CSR misa, 0x111
WRITE_READ_CSR medeleg, 0x111
WRITE_READ_CSR mideleg, 0x111
WRITE_READ_CSR mie, 0x111
WRITE_READ_CSR mtvec, 0x111
WRITE_READ_CSR mcounteren, 0x111

# Machine Trap Handling
WRITE_READ_CSR mscratch, 0x111
WRITE_READ_CSR mepc, 0x111
WRITE_READ_CSR mcause, 0x111
WRITE_READ_CSR mtval, 0x111
WRITE_READ_CSR mip, 0x111

# Machine Configuration
WRITE_READ_CSR menvcfg, 0x111
WRITE_READ_CSR menvcfgh, 0x111
WRITE_READ_CSR mseccfg, 0x111

# Machine Memory Protection
WRITE_READ_CSR pmpcfg0, 0x111
WRITE_READ_CSR pmpcfg2, 0x111 # there's 1 pmpcfg reg per 8 pmpaddr regs 

WRITE_READ_CSR pmpaddr0, 0x111
WRITE_READ_CSR pmpaddr1, 0x111
WRITE_READ_CSR pmpaddr2, 0x111
WRITE_READ_CSR pmpaddr3, 0x111
WRITE_READ_CSR pmpaddr4, 0x111
WRITE_READ_CSR pmpaddr5, 0x111
WRITE_READ_CSR pmpaddr6, 0x111
WRITE_READ_CSR pmpaddr7, 0x111
WRITE_READ_CSR pmpaddr8, 0x111
WRITE_READ_CSR pmpaddr9, 0x111
WRITE_READ_CSR pmpaddr10, 0x111
WRITE_READ_CSR pmpaddr11, 0x111
WRITE_READ_CSR pmpaddr12, 0x111
WRITE_READ_CSR pmpaddr13, 0x111
WRITE_READ_CSR pmpaddr14, 0x111
WRITE_READ_CSR pmpaddr15, 0x111 # only pmpcfg0...15 are enabled in our config

# Machine Counter/Timers
WRITE_READ_CSR mcycle, 0x111
WRITE_READ_CSR minstret, 0x111
WRITE_READ_CSR mhpmcounter3, 0x111
WRITE_READ_CSR mhpmcounter4, 0x111
WRITE_READ_CSR mhpmcounter5, 0x111
WRITE_READ_CSR mhpmcounter6, 0x111
WRITE_READ_CSR mhpmcounter7, 0x111
WRITE_READ_CSR mhpmcounter8, 0x111
WRITE_READ_CSR mhpmcounter9, 0x111
WRITE_READ_CSR mhpmcounter10, 0x111
WRITE_READ_CSR mhpmcounter11, 0x111
WRITE_READ_CSR mhpmcounter12, 0x111
WRITE_READ_CSR mhpmcounter13, 0x111
WRITE_READ_CSR mhpmcounter14, 0x111
WRITE_READ_CSR mhpmcounter15, 0x111
WRITE_READ_CSR mhpmcounter16, 0x111
WRITE_READ_CSR mhpmcounter17, 0x111
WRITE_READ_CSR mhpmcounter18, 0x111
WRITE_READ_CSR mhpmcounter19, 0x111
WRITE_READ_CSR mhpmcounter20, 0x111
WRITE_READ_CSR mhpmcounter21, 0x111
WRITE_READ_CSR mhpmcounter22, 0x111
WRITE_READ_CSR mhpmcounter23, 0x111
WRITE_READ_CSR mhpmcounter24, 0x111
WRITE_READ_CSR mhpmcounter25, 0x111
WRITE_READ_CSR mhpmcounter26, 0x111
WRITE_READ_CSR mhpmcounter27, 0x111
WRITE_READ_CSR mhpmcounter28, 0x111
WRITE_READ_CSR mhpmcounter29, 0x111
WRITE_READ_CSR mhpmcounter30, 0x111
WRITE_READ_CSR mhpmcounter31, 0x111

# Machine Counter Setup
WRITE_READ_CSR mcountinhibit, 0x111
WRITE_READ_CSR mhpmevent3, 0x111
WRITE_READ_CSR mhpmevent4, 0x111
WRITE_READ_CSR mhpmevent5, 0x111
WRITE_READ_CSR mhpmevent6, 0x111
WRITE_READ_CSR mhpmevent7, 0x111
WRITE_READ_CSR mhpmevent8, 0x111
WRITE_READ_CSR mhpmevent9, 0x111
WRITE_READ_CSR mhpmevent10, 0x111
WRITE_READ_CSR mhpmevent11, 0x111
WRITE_READ_CSR mhpmevent12, 0x111
WRITE_READ_CSR mhpmevent13, 0x111
WRITE_READ_CSR mhpmevent14, 0x111
WRITE_READ_CSR mhpmevent15, 0x111
WRITE_READ_CSR mhpmevent16, 0x111
WRITE_READ_CSR mhpmevent17, 0x111
WRITE_READ_CSR mhpmevent18, 0x111
WRITE_READ_CSR mhpmevent19, 0x111
WRITE_READ_CSR mhpmevent20, 0x111
WRITE_READ_CSR mhpmevent21, 0x111
WRITE_READ_CSR mhpmevent22, 0x111
WRITE_READ_CSR mhpmevent23, 0x111
WRITE_READ_CSR mhpmevent24, 0x111
WRITE_READ_CSR mhpmevent25, 0x111
WRITE_READ_CSR mhpmevent26, 0x111
WRITE_READ_CSR mhpmevent27, 0x111
WRITE_READ_CSR mhpmevent28, 0x111
WRITE_READ_CSR mhpmevent29, 0x111
WRITE_READ_CSR mhpmevent30, 0x111
WRITE_READ_CSR mhpmevent31, 0x111

END_TESTS

TEST_STACK_AND_DATA
