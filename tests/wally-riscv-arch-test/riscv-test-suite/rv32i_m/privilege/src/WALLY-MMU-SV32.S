///////////////////////////////////////////
//
// WALLY-MMU
//
// Author: David_Harris@hmc.edu and Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2021-06-15
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

#include "WALLY-TEST-LIB-32.S" 
// Test library includes and handler for each type of test, a trap handler, imperas compliance instructions
// Ideally this should mean that a test can be written by simply adding .8byte statements as below.

# ---------------------------------------------------------------------------------------------
# Test Contents
#
#   Here is where the actual tests are held, or rather, what the actual tests do.
#   each entry consists of 3 values that will be read in as follows:
#   
#   '.8byte [x28 Value], [x29 Value], [x30 value]'
#                     or
#   '.8byte [address], [value], [test type]'
#
#   The encoding for x30 test type values can be found in the test handler in the framework file
# 
# ---------------------------------------------------------------------------------------------

# =========== test 12.3.1.1 Page Table Translation ===========

# test 12.3.1.1.1 write page tables / entries to phyiscal memory
# sv32 Page table (See Figure 12.12***):
# Level 1 page table, situated at 0x8000D000
.4byte 0x8000D000, 0x20004CC1, 0x0  # points to level 0 page table A
.4byte 0x8000D004, 0x200000CB, 0x0  # Vaddr 0x400000 Paddr 0x80000000: aligned megapage, W=0, used for execute tests
.4byte 0x8000D008, 0x200054E1, 0x0  # points to level 0 page table B 
.4byte 0x8000D00C, 0x000800C7, 0x0  # Vaddr 0xC00000: misaligned megapage
.4byte 0x8000D800, 0x200000CF, 0x0  # Vaddr 0x80000000 Paddr 0x80000000: aligned megapage (program and data memory)
.4byte 0x8000D804, 0x200000DF, 0x0  # Vaddr 0x80400000 Paddr 0x80000000: aligned megapage, U=1 (aliased with program and data memory)
# Level 0 page table A
.4byte 0x80013000, 0x200070D1, 0x0  # Vaddr 0x0000: bad PTE points to level -1 table
.4byte 0x80013004, 0x202000DF, 0x0  # Vaddr 0x1000 Paddr 0x80800000: aligned kilopage, U=1
.4byte 0x80013008, 0x202010D5, 0x0  # Vaddr 0x2000: pad PTE has W but not R
.4byte 0x8001300C, 0x20200817, 0x0  # Vaddr 0x3000: A=0, should cause read fault
.4byte 0x80013010, 0x20200C57, 0x0  # Vaddr 0x4000: D=0, should cause write fault
.4byte 0x80013014, 0x202014C9, 0x0  # Vaddr 0x5000 Paddr 80805000: aligned kilopage, W=R=0
.4byte 0x80013018, 0x0, 0x0         # Vaddr 0x6000: invalid page
# Level 0 page table B
.4byte 0x80015FFC, 0x202004CF, 0x0  # Vaddr 0x00BFF000 Paddr 0x80801000: aligned kilopage

# test 12.3.1.1.2 write values to Paddrs in each page
# each of these values is used for 12.3.1.1.3 and some other tests, specified in the comments.
# when a test is supposed to fault, nothing is written into where it'll be reading/executing since it should fault before getting there.
.4byte 0x800AAAA8, 0xBEEF0055, 0x0 # 12.3.1.1.4 megapage
.4byte 0x800FFAC0, 0xBEEF0033, 0x0 # 12.3.1.3.2 
.4byte 0x800E3130, 0xBEEF0077, 0x0 # 12.3.1.3.2
.4byte 0x808017E0, 0xBEEF0099, 0x0 # 12.3.1.1.4 kilopage
.4byte 0x80805EA0, 0xBEEF0440, 0x0 # 12.3.1.3.3
.4byte 0x80803AA0, 0xBEEF0BB0, 0x0 # 12.3.1.3.7

# test 12.3.1.1.3 read values back from Paddrs without translation (this also verifies the previous test)
.4byte 0x0, 0x0, 0x4 # satp.MODE = baremetal / no translation.
.4byte 0x0, 0x0, 0x9 # change to S mode, 0xb written to output
.4byte 0x800AAAA8, 0xBEEF0055, 0x1
.4byte 0x800FFAC0, 0xBEEF0033, 0x1
.4byte 0x800E3130, 0xBEEF0077, 0x1
.4byte 0x808017E0, 0xBEEF0099, 0x1
.4byte 0x80805EA0, 0xBEEF0440, 0x1
.4byte 0x80803AA0, 0xBEEF0BB0, 0x1

# test 12.3.1.1.4 check translation works in sv48, read the same values from previous tests, this time with Vaddrs
.4byte 0x0, 0x0, 0x5 # satp.MODE = sv48, Nothing written to output
.4byte 0x4AAAA8, 0xBEEF0055, 0x1    # megapage at Vaddr 0x400000, Paddr 0x80000000
.4byte 0xBFF7E0, 0xBEEF0099, 0x1    # kilopage at Vaddr 0xBFF000, Paddr 0x80201000

# =========== test 12.3.1.2 page fault tests ===========

# test 12.3.1.2.1 load page fault if upper bits of Vaddr are not the same
# Not tested in rv32/sv32

# test 12.3.1.2.2 load page fault when reading an address where the valid flag is zero
.4byte 0x6000, 0x0, 0x1

# test 12.3.1.2.3 store page fault if PTE has W and ~R flags set
.4byte 0x2000, 0x0, 0x0

# test 12.3.1.2.4 Fault if last level PTE is a pointer
.4byte 0x0200, 0x0, 0x1

# test 12.3.1.2.5 load page fault on misaligned pages
.4byte 0xC00000, 0x0, 0x1   # misaligned megapage

# =========== test 12.3.1.3 PTE Protection flags ===========

// *** 16 July 2021: Execution tests commented out because they rely on some memory that's written in 12.3.1.1.2. this memory is written but stays in the dcache without being synced into memory
//                      Then the ifu tries to fetch the same address, but it's working with the unsynced memory, NOT the value stored in the dcache
//                      Until we have some fence instructions or another way of modifying the code implemented, these tests are ignored.

# test 12.3.1.3.1 User flag == 0
# *** reads on pages with U=0 already tested in 12.3.1.1.4
.4byte 0x400000, 0x1, 0x2           # fetch success when U=0, priv=S
.4byte 0x201, 0x11, 0xA             # go to U mode, return to megapage VPN at [513] where PTE.U = 1. 0x9 written to output
.4byte 0xBFFC80, 0xBEEF0550, 0x1    # load page fault when U=0, priv=U
.4byte 0x400000, 0x1, 0x2           # instr page fault when U=0, priv=U

# test 12.3.1.3.2 User flag == 1
.4byte 0x804FFAC0, 0xBEEF0033, 0x1  # read success when U=1, priv=U
.4byte 0x200, 0x11, 0x9             # go back to S mode, return to megapage VPN at [512] where PTE.U = 0. 0x8 written to output
.4byte 0x0, 0x3, 0x7                # set sstatus.[MXR, SUM] = 11
.4byte 0x804E3130, 0xBEEF0077, 0x1  # read success when U=1, priv=S, sstatus.SUM=1
.4byte 0x0, 0x400000, 0x10          # push to stack virtual address corresponfding to the PTE about to be changed.
.4byte 0x8000D004, 0x200000DB, 0xF  # Edit execution PTE so U=1
.4byte 0x400000, 0x1, 0x2           # instr page fault when U=1, priv=S (with any sstatus.SUM)
.4byte 0x0, 0x2, 0x7                # set sstatus.[MXR, SUM] = 10.
.4byte 0x804FFAC0, 0xBEEF0033, 0x1  # load page fault when U-1, priv=S, sstatus.SUM=0

# test 12.3.1.3.3 Read flag
# *** reads on pages with R=1 already tested in 12.3.1.1.4
.4byte 0x0, 0x1, 0x7            # set sstatus.[MXR, SUM] = 01.
.4byte 0x5EA0, 0xBEEF0440, 0x1  # load page fault when R=0, sstatus.MXR=0
.4byte 0x0, 0x3, 0x7            # set sstatus.[MXR, SUM] = 11.
.4byte 0x5EA0, 0xBEEF0440, 0x1  # read success when R=0, MXR=1, X=1

# test 12.3.1.3.4 Write flag
.4byte 0xBFF290, 0xBEEF0110, 0x0    # write success when W=1
.4byte 0xBFF290, 0xBEEF0110, 0x1    # check write success by reading
.4byte 0x5B78, 0xBEEF0CC0, 0x0      # store page fault when W=0

# test 12.3.1.3.5 eXecute flag
# *** fetches on pages with X = 1 already tested in 12.3.1.3.1
.4byte 0x0, 0x400000, 0x10            # push to stack virtual address corresponfding to the PTE about to be changed.
.4byte 0x8000D004, 0x200000C7, 0xF    # Edit execution PTE so U=0, X=0
.4byte 0x400000, 0x0, 0x2             # instr page fault when X=0 

# test 12.3.1.3.6 Accessed flag == 0
.4byte 0x3020, 0xBEEF0770, 0x0 # store page fault when A=0
.4byte 0x3808, 0xBEEF0990, 0x1 # load page fault when A=0

# test 12.3.1.3.7 Dirty flag == 0
.4byte 0x4658, 0xBEEF0AA0, 0x0 # store page fault when D=0
.4byte 0x4AA0, 0xBEEF0BB0, 0x1 # read success when D=0

# terminate tests
.4byte 0x0, 0x0, 0x3 # brings us back into machine mode with a final ecall, writing 0x9 to the output.

