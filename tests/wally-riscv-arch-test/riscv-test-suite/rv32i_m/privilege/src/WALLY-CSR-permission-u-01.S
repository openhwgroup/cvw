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

INIT_TESTS

s_file_begin:

# Test 5.2.3.6: Test that all the machine mode CSR's are innaccessible for reads and writes in R mode.

GOTO_U_MODE 0x0, 0x0

# Attempt to write 0xbad to each of these CSRs and read the value back
# should result in an illegal instruction for the write and read, respectively

# Supervisor Trap Setup
WRITE_READ_CSR sstatus, 0xbad
WRITE_READ_CSR sie, 0xbad
WRITE_READ_CSR stvec, 0xbad
WRITE_READ_CSR scounteren, 0xbad

# Supervisor Configuration
# WRITE_READ_CSR senvcfg, 0xbad # *** these appear not to be implemented in the compile step of make???

# Supervisor Trap Handling
WRITE_READ_CSR sscratch, 0xbad
WRITE_READ_CSR sepc, 0xbad
WRITE_READ_CSR scause, 0xbad
WRITE_READ_CSR stval, 0xbad
WRITE_READ_CSR sip, 0xbad

# Supervisor Protection and Translation
WRITE_READ_CSR satp, 0xbad

# Machine information Registers
WRITE_READ_CSR mvendorid, 0xbad
WRITE_READ_CSR marchid, 0xbad
WRITE_READ_CSR mimpid, 0xbad
WRITE_READ_CSR mhartid, 0xbad
# WRITE_READ_CSR mconfigptr, 0xbad # mconfigptr unimplemented in spike as of 31 Jan 22

# Machine Trap Setup
WRITE_READ_CSR mstatus, 0xbad
WRITE_READ_CSR misa, 0xbad
WRITE_READ_CSR medeleg, 0xbad
WRITE_READ_CSR mideleg, 0xbad
WRITE_READ_CSR mie, 0xbad
WRITE_READ_CSR mtvec, 0xbad
WRITE_READ_CSR mcounteren, 0xbad

# Machine Trap Handling
WRITE_READ_CSR mscratch, 0xbad
WRITE_READ_CSR mepc, 0xbad
WRITE_READ_CSR mcause, 0xbad
WRITE_READ_CSR mtval, 0xbad
WRITE_READ_CSR mip, 0xbad
# WRITE_READ_CSR mtinst, 0xbad # *** these appear not to be implemented in the compile step of make???
# WRITE_READ_CSR mtval2, 0xbad

# Machine Configuration
# WRITE_READ_CSR menvcfg, 0xbad # *** these appear not to be implemented in the compile step of make???
# WRITE_READ_CSR mseccgf, 0xbad

# Machine Memory Protection
WRITE_READ_CSR pmpcfg0, 0xbad
WRITE_READ_CSR pmpcfg2, 0xbad # pmpcfg 1 and 3 dont exist in rv64. there's 1 pmpcfg reg per 8 pmpaddr regs 

WRITE_READ_CSR pmpaddr0, 0xbad
WRITE_READ_CSR pmpaddr1, 0xbad
WRITE_READ_CSR pmpaddr2, 0xbad
WRITE_READ_CSR pmpaddr3, 0xbad
WRITE_READ_CSR pmpaddr4, 0xbad
WRITE_READ_CSR pmpaddr5, 0xbad
WRITE_READ_CSR pmpaddr6, 0xbad
WRITE_READ_CSR pmpaddr7, 0xbad
WRITE_READ_CSR pmpaddr8, 0xbad
WRITE_READ_CSR pmpaddr9, 0xbad
WRITE_READ_CSR pmpaddr10, 0xbad
WRITE_READ_CSR pmpaddr11, 0xbad
WRITE_READ_CSR pmpaddr12, 0xbad
WRITE_READ_CSR pmpaddr13, 0xbad
WRITE_READ_CSR pmpaddr14, 0xbad
WRITE_READ_CSR pmpaddr15, 0xbad # only pmpcfg0...15 are enabled in our config

# Machine Counter/Timers
WRITE_READ_CSR mcycle, 0xbad
WRITE_READ_CSR minstret, 0xbad
WRITE_READ_CSR mhpmcounter3, 0xbad
WRITE_READ_CSR mhpmcounter4, 0xbad
WRITE_READ_CSR mhpmcounter5, 0xbad
WRITE_READ_CSR mhpmcounter6, 0xbad
WRITE_READ_CSR mhpmcounter7, 0xbad
WRITE_READ_CSR mhpmcounter8, 0xbad
WRITE_READ_CSR mhpmcounter9, 0xbad
WRITE_READ_CSR mhpmcounter10, 0xbad
WRITE_READ_CSR mhpmcounter11, 0xbad
WRITE_READ_CSR mhpmcounter12, 0xbad
WRITE_READ_CSR mhpmcounter13, 0xbad
WRITE_READ_CSR mhpmcounter14, 0xbad
WRITE_READ_CSR mhpmcounter15, 0xbad
WRITE_READ_CSR mhpmcounter16, 0xbad
WRITE_READ_CSR mhpmcounter17, 0xbad
WRITE_READ_CSR mhpmcounter18, 0xbad
WRITE_READ_CSR mhpmcounter19, 0xbad
WRITE_READ_CSR mhpmcounter20, 0xbad
WRITE_READ_CSR mhpmcounter21, 0xbad
WRITE_READ_CSR mhpmcounter22, 0xbad
WRITE_READ_CSR mhpmcounter23, 0xbad
WRITE_READ_CSR mhpmcounter24, 0xbad
WRITE_READ_CSR mhpmcounter25, 0xbad
WRITE_READ_CSR mhpmcounter26, 0xbad
WRITE_READ_CSR mhpmcounter27, 0xbad
WRITE_READ_CSR mhpmcounter28, 0xbad
WRITE_READ_CSR mhpmcounter29, 0xbad
WRITE_READ_CSR mhpmcounter30, 0xbad
WRITE_READ_CSR mhpmcounter31, 0xbad

# Machine Counter Setup
WRITE_READ_CSR mcountinhibit, 0xbad
WRITE_READ_CSR mhpmevent3, 0xbad
WRITE_READ_CSR mhpmevent4, 0xbad
WRITE_READ_CSR mhpmevent5, 0xbad
WRITE_READ_CSR mhpmevent6, 0xbad
WRITE_READ_CSR mhpmevent7, 0xbad
WRITE_READ_CSR mhpmevent8, 0xbad
WRITE_READ_CSR mhpmevent9, 0xbad
WRITE_READ_CSR mhpmevent10, 0xbad
WRITE_READ_CSR mhpmevent11, 0xbad
WRITE_READ_CSR mhpmevent12, 0xbad
WRITE_READ_CSR mhpmevent13, 0xbad
WRITE_READ_CSR mhpmevent14, 0xbad
WRITE_READ_CSR mhpmevent15, 0xbad
WRITE_READ_CSR mhpmevent16, 0xbad
WRITE_READ_CSR mhpmevent17, 0xbad
WRITE_READ_CSR mhpmevent18, 0xbad
WRITE_READ_CSR mhpmevent19, 0xbad
WRITE_READ_CSR mhpmevent20, 0xbad
WRITE_READ_CSR mhpmevent21, 0xbad
WRITE_READ_CSR mhpmevent22, 0xbad
WRITE_READ_CSR mhpmevent23, 0xbad
WRITE_READ_CSR mhpmevent24, 0xbad
WRITE_READ_CSR mhpmevent25, 0xbad
WRITE_READ_CSR mhpmevent26, 0xbad
WRITE_READ_CSR mhpmevent27, 0xbad
WRITE_READ_CSR mhpmevent28, 0xbad
WRITE_READ_CSR mhpmevent29, 0xbad
WRITE_READ_CSR mhpmevent30, 0xbad
WRITE_READ_CSR mhpmevent31, 0xbad

END_TESTS

TEST_STACK_AND_DATA