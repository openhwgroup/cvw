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
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;",csr-permission-u)

INIT_TESTS

TRAP_HANDLER m

# Test 5.2.3.6: Test that all the machine mode CSR's are inaccessible for reads and writes in R mode.

GOTO_U_MODE 0x0, 0x0

# Attempt to write 0xAAA to each of these CSRs and read the value back
# should result in an illegal instruction for the write and read, respectively

# Supervisor Trap Setup
WRITE_READ_CSR sstatus, 0xAAA
WRITE_READ_CSR sie, 0xAAA
WRITE_READ_CSR stvec, 0xAAA
WRITE_READ_CSR scounteren, 0xAAA

# Supervisor Configuration
# WRITE_READ_CSR senvcfg, 0xAAA # *** these appear not to be implemented in the compile step of make???

# Supervisor Trap Handling
WRITE_READ_CSR sscratch, 0xAAA
WRITE_READ_CSR sepc, 0xAAA
WRITE_READ_CSR scause, 0xAAA
WRITE_READ_CSR stval, 0xAAA
WRITE_READ_CSR sip, 0xAAA

# Supervisor Protection and Translation
WRITE_READ_CSR satp, 0xAAA

# Machine information Registers
WRITE_READ_CSR mvendorid, 0xAAA
WRITE_READ_CSR marchid, 0xAAA
WRITE_READ_CSR mimpid, 0xAAA
WRITE_READ_CSR mhartid, 0xAAA
WRITE_READ_CSR mconfigptr, 0xAAA # mconfigptr unimplemented in spike as of 31 Jan 22

# Machine Trap Setup
WRITE_READ_CSR mstatus, 0xAAA
WRITE_READ_CSR mstatush, 0xAAA
WRITE_READ_CSR misa, 0xAAA
WRITE_READ_CSR medeleg, 0xAAA
WRITE_READ_CSR mideleg, 0xAAA
WRITE_READ_CSR mie, 0xAAA
WRITE_READ_CSR mtvec, 0xAAA
WRITE_READ_CSR mcounteren, 0xAAA

# Machine Trap Handling
WRITE_READ_CSR mscratch, 0xAAA
WRITE_READ_CSR mepc, 0xAAA
WRITE_READ_CSR mcause, 0xAAA
WRITE_READ_CSR mtval, 0xAAA
WRITE_READ_CSR mip, 0xAAA

# Machine Configuration
WRITE_READ_CSR menvcfg, 0xAAA
WRITE_READ_CSR menvcfgh, 0xAAA 
WRITE_READ_CSR senvcfg, 0xAAA 
WRITE_READ_CSR mseccfg, 0xAAA

# Machine Memory Protection
WRITE_READ_CSR pmpcfg0, 0xAAA
WRITE_READ_CSR pmpcfg2, 0xAAA # pmpcfg 1 and 3 dont exist in rv64. there's 1 pmpcfg reg per 8 pmpaddr regs 

WRITE_READ_CSR pmpaddr0, 0xAAA
WRITE_READ_CSR pmpaddr1, 0xAAA
WRITE_READ_CSR pmpaddr2, 0xAAA
WRITE_READ_CSR pmpaddr3, 0xAAA
WRITE_READ_CSR pmpaddr4, 0xAAA
WRITE_READ_CSR pmpaddr5, 0xAAA
WRITE_READ_CSR pmpaddr6, 0xAAA
WRITE_READ_CSR pmpaddr7, 0xAAA
WRITE_READ_CSR pmpaddr8, 0xAAA
WRITE_READ_CSR pmpaddr9, 0xAAA
WRITE_READ_CSR pmpaddr10, 0xAAA
WRITE_READ_CSR pmpaddr11, 0xAAA
WRITE_READ_CSR pmpaddr12, 0xAAA
WRITE_READ_CSR pmpaddr13, 0xAAA
WRITE_READ_CSR pmpaddr14, 0xAAA
WRITE_READ_CSR pmpaddr15, 0xAAA # only pmpcfg0...15 are enabled in our config

# Machine Counter/Timers
WRITE_READ_CSR mcycle, 0xAAA
WRITE_READ_CSR minstret, 0xAAA
WRITE_READ_CSR mhpmcounter3, 0xAAA
WRITE_READ_CSR mhpmcounter4, 0xAAA
WRITE_READ_CSR mhpmcounter5, 0xAAA
WRITE_READ_CSR mhpmcounter6, 0xAAA
WRITE_READ_CSR mhpmcounter7, 0xAAA
WRITE_READ_CSR mhpmcounter8, 0xAAA
WRITE_READ_CSR mhpmcounter9, 0xAAA
WRITE_READ_CSR mhpmcounter10, 0xAAA
WRITE_READ_CSR mhpmcounter11, 0xAAA
WRITE_READ_CSR mhpmcounter12, 0xAAA
WRITE_READ_CSR mhpmcounter13, 0xAAA
WRITE_READ_CSR mhpmcounter14, 0xAAA
WRITE_READ_CSR mhpmcounter15, 0xAAA
WRITE_READ_CSR mhpmcounter16, 0xAAA
WRITE_READ_CSR mhpmcounter17, 0xAAA
WRITE_READ_CSR mhpmcounter18, 0xAAA
WRITE_READ_CSR mhpmcounter19, 0xAAA
WRITE_READ_CSR mhpmcounter20, 0xAAA
WRITE_READ_CSR mhpmcounter21, 0xAAA
WRITE_READ_CSR mhpmcounter22, 0xAAA
WRITE_READ_CSR mhpmcounter23, 0xAAA
WRITE_READ_CSR mhpmcounter24, 0xAAA
WRITE_READ_CSR mhpmcounter25, 0xAAA
WRITE_READ_CSR mhpmcounter26, 0xAAA
WRITE_READ_CSR mhpmcounter27, 0xAAA
WRITE_READ_CSR mhpmcounter28, 0xAAA
WRITE_READ_CSR mhpmcounter29, 0xAAA
WRITE_READ_CSR mhpmcounter30, 0xAAA
WRITE_READ_CSR mhpmcounter31, 0xAAA

# Machine Counter Setup
WRITE_READ_CSR mcountinhibit, 0xAAA
WRITE_READ_CSR mhpmevent3, 0xAAA
WRITE_READ_CSR mhpmevent4, 0xAAA
WRITE_READ_CSR mhpmevent5, 0xAAA
WRITE_READ_CSR mhpmevent6, 0xAAA
WRITE_READ_CSR mhpmevent7, 0xAAA
WRITE_READ_CSR mhpmevent8, 0xAAA
WRITE_READ_CSR mhpmevent9, 0xAAA
WRITE_READ_CSR mhpmevent10, 0xAAA
WRITE_READ_CSR mhpmevent11, 0xAAA
WRITE_READ_CSR mhpmevent12, 0xAAA
WRITE_READ_CSR mhpmevent13, 0xAAA
WRITE_READ_CSR mhpmevent14, 0xAAA
WRITE_READ_CSR mhpmevent15, 0xAAA
WRITE_READ_CSR mhpmevent16, 0xAAA
WRITE_READ_CSR mhpmevent17, 0xAAA
WRITE_READ_CSR mhpmevent18, 0xAAA
WRITE_READ_CSR mhpmevent19, 0xAAA
WRITE_READ_CSR mhpmevent20, 0xAAA
WRITE_READ_CSR mhpmevent21, 0xAAA
WRITE_READ_CSR mhpmevent22, 0xAAA
WRITE_READ_CSR mhpmevent23, 0xAAA
WRITE_READ_CSR mhpmevent24, 0xAAA
WRITE_READ_CSR mhpmevent25, 0xAAA
WRITE_READ_CSR mhpmevent26, 0xAAA
WRITE_READ_CSR mhpmevent27, 0xAAA
WRITE_READ_CSR mhpmevent28, 0xAAA
WRITE_READ_CSR mhpmevent29, 0xAAA
WRITE_READ_CSR mhpmevent30, 0xAAA
WRITE_READ_CSR mhpmevent31, 0xAAA

END_TESTS

TEST_STACK_AND_DATA
