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

#include "WALLY-TEST-MACROS-64.h"

INIT_TESTS

# Test 5.2.3.6: Test that all the machine mode CSR's are innaccessible for reads and writes in S mode.

# *** several of these appear not to be implemented in the assembler? 
# I get "assembler messages: error: unkown CSR" with many of them.

goto_s_mode 0x0, 0x0

# Attempt to write 0xbad to each of these CSRs and read the value back
# should result in an illegal instruction for the write and read, respectively

# Machine information Registers
write_read_csr mvendorid, 0xbad
write_read_csr marchid, 0xbad
write_read_csr mimpid, 0xbad
write_read_csr mhartid, 0xbad
# write_read_csr mconfigptr, 0xbad # mconfigptr unimplemented in spike as of 31 Jan 22

# Machine Trap Setup
write_read_csr mstatus, 0xbad
write_read_csr misa, 0xbad
write_read_csr medeleg, 0xbad
write_read_csr mideleg, 0xbad
write_read_csr mie, 0xbad
write_read_csr mtvec, 0xbad
write_read_csr mcounteren, 0xbad

# Machine Trap Handling
write_read_csr mscratch, 0xbad
write_read_csr mepc, 0xbad
write_read_csr mcause, 0xbad
write_read_csr mtval, 0xbad
write_read_csr mip, 0xbad
# write_read_csr mtinst, 0xbad # *** these appear not to be implemented in the compile step of make???
# write_read_csr mtval2, 0xbad

# Machine Configuration
# write_read_csr menvcfg, 0xbad # *** these appear not to be implemented in the compile step of make???
# write_read_csr mseccgf, 0xbad

# Machine Memory Protection
write_read_csr pmpcfg0, 0xbad
write_read_csr pmpcfg2, 0xbad # pmpcfg 1 and 3 dont exist in rv64. there's 1 pmpcfg reg per 8 pmpaddr regs 

write_read_csr pmpaddr0, 0xbad
write_read_csr pmpaddr1, 0xbad
write_read_csr pmpaddr2, 0xbad
write_read_csr pmpaddr3, 0xbad
write_read_csr pmpaddr4, 0xbad
write_read_csr pmpaddr5, 0xbad
write_read_csr pmpaddr6, 0xbad
write_read_csr pmpaddr7, 0xbad
write_read_csr pmpaddr8, 0xbad
write_read_csr pmpaddr9, 0xbad
write_read_csr pmpaddr10, 0xbad
write_read_csr pmpaddr11, 0xbad
write_read_csr pmpaddr12, 0xbad
write_read_csr pmpaddr13, 0xbad
write_read_csr pmpaddr14, 0xbad
write_read_csr pmpaddr15, 0xbad # only pmpcfg0...15 are enabled in our config

# Machine Counter/Timers
write_read_csr mcycle, 0xbad
write_read_csr minstret, 0xbad
write_read_csr mhpmcounter3, 0xbad
write_read_csr mhpmcounter4, 0xbad
write_read_csr mhpmcounter5, 0xbad
write_read_csr mhpmcounter6, 0xbad
write_read_csr mhpmcounter7, 0xbad
write_read_csr mhpmcounter8, 0xbad
write_read_csr mhpmcounter9, 0xbad
write_read_csr mhpmcounter10, 0xbad
write_read_csr mhpmcounter11, 0xbad
write_read_csr mhpmcounter12, 0xbad
write_read_csr mhpmcounter13, 0xbad
write_read_csr mhpmcounter14, 0xbad
write_read_csr mhpmcounter15, 0xbad
write_read_csr mhpmcounter16, 0xbad
write_read_csr mhpmcounter17, 0xbad
write_read_csr mhpmcounter18, 0xbad
write_read_csr mhpmcounter19, 0xbad
write_read_csr mhpmcounter20, 0xbad
write_read_csr mhpmcounter21, 0xbad
write_read_csr mhpmcounter22, 0xbad
write_read_csr mhpmcounter23, 0xbad
write_read_csr mhpmcounter24, 0xbad
write_read_csr mhpmcounter25, 0xbad
write_read_csr mhpmcounter26, 0xbad
write_read_csr mhpmcounter27, 0xbad
write_read_csr mhpmcounter28, 0xbad
write_read_csr mhpmcounter29, 0xbad
write_read_csr mhpmcounter30, 0xbad
write_read_csr mhpmcounter31, 0xbad

# Machine Counter Setup
write_read_csr mcountinhibit, 0xbad
write_read_csr mhpmevent3, 0xbad
write_read_csr mhpmevent4, 0xbad
write_read_csr mhpmevent5, 0xbad
write_read_csr mhpmevent6, 0xbad
write_read_csr mhpmevent7, 0xbad
write_read_csr mhpmevent8, 0xbad
write_read_csr mhpmevent9, 0xbad
write_read_csr mhpmevent10, 0xbad
write_read_csr mhpmevent11, 0xbad
write_read_csr mhpmevent12, 0xbad
write_read_csr mhpmevent13, 0xbad
write_read_csr mhpmevent14, 0xbad
write_read_csr mhpmevent15, 0xbad
write_read_csr mhpmevent16, 0xbad
write_read_csr mhpmevent17, 0xbad
write_read_csr mhpmevent18, 0xbad
write_read_csr mhpmevent19, 0xbad
write_read_csr mhpmevent20, 0xbad
write_read_csr mhpmevent21, 0xbad
write_read_csr mhpmevent22, 0xbad
write_read_csr mhpmevent23, 0xbad
write_read_csr mhpmevent24, 0xbad
write_read_csr mhpmevent25, 0xbad
write_read_csr mhpmevent26, 0xbad
write_read_csr mhpmevent27, 0xbad
write_read_csr mhpmevent28, 0xbad
write_read_csr mhpmevent29, 0xbad
write_read_csr mhpmevent30, 0xbad
write_read_csr mhpmevent31, 0xbad

END_TESTS