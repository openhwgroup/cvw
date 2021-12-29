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

#include "WALLY-TEST-LIB-64.S" 
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

# These tests follow the testing plan in Chapter 12 of the riscv-wally textbook

# =========== test 12.3.1.1 Page Table Translation ===========

# test 12.3.1.1.1 write page tables / entries to phyiscal memory
# sv48 page table (See Figure 12.12***):
# Level 3 page table, situated at 0x8000D000
.8byte 0x000000008000D000, 0x0000000020004CC1, 0x0 # points to level 2 page table A
.8byte 0x000000008000D008, 0x00000000200050C1, 0x0 # points to level 2 page table B
.8byte 0x000000008000D010, 0x00000000000000C7, 0x0 # Vaddr 0x010000000000, Paddr 0x00000000: aligned terapage
.8byte 0x000000008000D018, 0x00004000004000C7, 0x0 # Vaddr 0x018000000000, misaligned terapage
.8byte 0x000000008000DFF8, 0x00000000200054E1, 0x0 # points to level 2 page table C
# Level 2 page table A
.8byte 0x0000000080013010, 0x00000000200060C1, 0x0 # points to level 1 page table A
# Level 2 page table B
.8byte 0x0000000080014000, 0x00000000200000CB, 0x0 # Vaddr 0x008000000000, Paddr 0x80000000: aligned gigapage used for execution tests
.8byte 0x0000000080014008, 0x00000000200000DF, 0x0 # Vaddr 0x008040000000, Paddr 0x80000000: aligned gigapage (aliased with data and instr memory) U bit set.
.8byte 0x0000000080014010, 0x00000400080000C3, 0x0 # Vaddr 0x008080000000, misaligned gigapage
# Level 2 page table C
.8byte 0x0000000080015FF8, 0x00000000200058C1, 0x0 # points to level 1 page table B
# Level 1 page table A
.8byte 0x0000000080018000, 0x00000000200000CF, 0x0 # Vaddr 0x80000000, Paddr 0x80000000: aligned megapage (data and instr memory)
.8byte 0x0000000080018008, 0x00000000200064C1, 0x0 # points to level 0 page table A
.8byte 0x0000000080018010, 0x000000C0000400CF, 0x0 # Vaddr 0x80400000, misaligned megapage
.8byte 0x0000000080018018, 0x00000000214800C9, 0x0 # Vaddr 0x80600000, Paddr 0x85200000: aligned megapage, R=0
# Level 1 page table B
.8byte 0x0000000080016FF8, 0x00000000200068C1, 0x0 # points to level 0 page table B
# Level 0 page table A
.8byte 0x0000000080019000, 0x00000000200070D1, 0x0 # Vaddr 0x80200000, Paddr 0x8001C000: bad PTE points to level -1 table
.8byte 0x0000000080019008, 0x00000000200800DF, 0x0 # Vaddr 0x80201000, Paddr 0x80200000: aligned kilopage
.8byte 0x0000000080019010, 0x00000000200810DF, 0x0 # Vaddr 0x80202000, Paddr 0x80204000: bad PTE has W but not R
.8byte 0x0000000080019018, 0x0000000020080817, 0x0 # Vaddr 0x80203000, Paddr 0x80202000: A=0, should cause read fault
.8byte 0x0000000080019020, 0x0000000020080C57, 0x0 # Vaddr 0x80204000, Paddr 0x80203000: D=0, should cause write fault
.8byte 0x0000000080019028, 0x0000000020333000, 0x0 # Vaddr 0x80205000, Paddr 0x80CCC000, invalid page.
# Level 0 page table B
.8byte 0x000000008001AFF8, 0x00000000200804CF, 0x0 # Vaddr 0xFFFFFFFFF000, Paddr 0x80201000: aligned kilopage

# test 12.3.1.1.2 write values to Paddrs in each page
# each of these values is used for 12.3.1.1.3 and some other tests, specified in the comments.
# when a test is supposed to fault, nothing is written into where it'll be reading/executing since it should fault before getting there.
.8byte 0x82777778, 0x0EE0DEADBEEF0CC0, 0x0 # 12.3.1.1.4 terapage
.8byte 0x85BC0AB0, 0x0000DEADBEEF0000, 0x0 # 12.3.1.1.4 gigapage
.8byte 0x800F0AB8, 0x0880DEADBEEF0055, 0x0 # 12.3.1.1.4 megapage
.8byte 0x80201888, 0x0220DEADBEEF0099, 0x0 # 12.3.1.1.4 kilopage
.8byte 0x80099000, 0x0000806711100393, 0x0 # 12.3.1.3.1 write executable code for "li x7, 0x111; ret"
.8byte 0x80200400, 0x0000806711100393, 0x0 # 12.3.1.3.2 write same executable code 
.8byte 0x80200AC0, 0x0990DEADBEEF0033, 0x0 # 12.3.1.3.2 
.8byte 0x80200130, 0x0110DEADBEEF0077, 0x0 # 12.3.1.3.2
.8byte 0x85212348, 0x0330DEADBEEF0440, 0x0 # 12.3.1.3.3
.8byte 0x88888000, 0x0000806711100393, 0x0 # 12.3.1.3.5 write same executable code
.8byte 0x80203AA0, 0x0440DEADBEEF0BB0, 0x0 # 12.3.1.3.7

# test 12.3.1.1.3 read values back from Paddrs without translation (this also verifies the previous test)
.8byte 0x0, 0x0, 0x4 # satp.MODE = baremetal / no translation.
.8byte 0x0, 0x0, 0x9 # change to S mode, 0xb written to output
.8byte 0x82777778, 0x0EE0DEADBEEF0CC0, 0x1
.8byte 0x85BC0AB0, 0x0000DEADBEEF0000, 0x1
.8byte 0x800F0AB8, 0x0880DEADBEEF0055, 0x1
.8byte 0x80200AC0, 0x0990DEADBEEF0033, 0x1
.8byte 0x80200130, 0x0110DEADBEEF0077, 0x1
.8byte 0x80201888, 0x0220DEADBEEF0099, 0x1
.8byte 0x85212348, 0x0330DEADBEEF0440, 0x1 
.8byte 0x80203AA0, 0x0440DEADBEEF0BB0, 0x1

# test 12.3.1.1.4 check translation works in sv48, read the same values from previous tests, this time with Vaddrs
.8byte 0x0, 0x0, 0x6 # satp.MODE = sv48, Nothing written to output
.8byte 0x10082777778, 0x0EE0DEADBEEF0CC0, 0x1       # terapage at Vaddr 0x010000000000, Paddr 0x0
.8byte 0x8005BC0AB0, 0x0000DEADBEEF0000, 0x1        # gigapage at Vaddr 0x008000000000, Paddr 0x80000000
.8byte 0x800F0AB8, 0x0880DEADBEEF0055, 0x1          # megapage at Vaddr 0x80000000, Paddr 0x80000000
.8byte 0xFFFFFFFFFFFFF888, 0x0220DEADBEEF0099, 0x1  # kilopage at Vaddr 0xFFFFFFFFFFFFF000, Paddr 0x80201000

# =========== test 12.3.1.2 page fault tests ===========

# test 12.3.1.2.1 page fault if upper bits of Vaddr are not the same
.8byte 0x001000800ABC0AB0, 0x0, 0x1 # gigapage at Vaddr 0x008000000000, Paddr 0x80000000, bad 1 in upper bits
.8byte 0xFF0FFFFFFFFFF888, 0x0, 0x1 # kilopage at Vaddr 0xFFFFFFFFFFFFF000, Paddr 0x80201000, bad 0000 in upper bits

# test 12.3.1.2.2 read fault when reading an address where the valid flag is zero
.8byte 0x80205000, 0x0, 0x1

# test 12.3.1.2.3 write fault if PTE has W and ~R flags set
.8byte 0x80202000, 0x0, 0x0 

# test 12.3.1.2.4 Fault if last level PTE is a pointer
.8byte 0x80200000, 0x0, 0x1

# test 12.3.1.2.5 read fault on misaligned pages
.8byte 0x18000000000, 0x0, 0x1  # misaligned terapage
.8byte 0x8080000000, 0x0, 0x1   # misaligned gigapage
.8byte 0x80400000, 0x0, 0x1     # misaligned megapage

# =========== test 12.3.1.3 PTE Protection flags ===========

# test 12.3.1.3.1 User flag == 0
# reads on pages with U=0 already tested in 12.3.1.1.4
.8byte 0x008000099000, 0x111, 0x2                   # execute success when U=0, priv=S
.8byte 0x201, 0x12, 0xA                    # go to U mode, return to gigapage at 0x008040000000 where PTE.U = 1. 0x9 written to output
.8byte 0xFFFFFFFFFFFFFC80, 0x0880DEADBEEF0550, 0x1  # read fault when U=0, priv=U
.8byte 0x008000099000, 0xbad, 0x2                   # execute fault when U=0, priv=U

# test 12.3.1.3.2 User flag == 1
.8byte 0x80201AC0, 0x0990DEADBEEF0033, 0x1  # read success when U=1, priv=U
.8byte 0x400, 0x21, 0x9                     # go back to S mode, return to megapage at 0x80000000 where PTE.U = 0. 0x8 written to output
.8byte 0x0, 0x3, 0x7                        # set sstatus.[MXR, SUM] = 11
.8byte 0x80201130, 0x0110DEADBEEF0077, 0x1  # read success when U=1, priv=S, sstatus.SUM=1
.8byte 0x80201400, 0xbad, 0x2               # execute fault when U=1, priv=S (with any sstatus.SUM) 
.8byte 0x0, 0x2, 0x7                        # set sstatus.[MXR, SUM] = 10.
.8byte 0x80201AC0, 0x0990DEADBEEF0033, 0x1  # read fault when U=1, priv=S, sstatus.SUM=0

# test 12.3.1.3.3 Read flag
# reads on pages with R=1 already tested in 12.3.1.1.4
.8byte 0x0, 0x1, 0x7                        # set sstatus.[MXR, SUM] = 01.
.8byte 0x80612348, 0x0330DEADBEEF0440, 0x1  # read fault when R=0, sstatus.MXR=0
.8byte 0x0, 0x3, 0x7                        # set sstatus.[MXR, SUM] = 11.
.8byte 0x80612348, 0x0330DEADBEEF0440, 0x1  # read success when MXR=1, X=1

# test 12.3.1.3.4 Write flag
.8byte 0x10080BCDED8, 0x0440DEADBEEF0110, 0x0    # write success when W=1 (corresponding Paddr = 0x80BCDED8)
.8byte 0x10080BCDED8, 0x0440DEADBEEF0110, 0x1    # check write success by reading value back
.8byte 0x80C0009E88, 0x0220DEADBEEF0BB0, 0x0     # write fault when W=0

# test 12.3.1.3.5 eXecute flag
# executes on pages with X = 1 already tested in 12.3.1.3.1
.8byte 0x010088888000, 0x2, 0x2               # execute fault when X=0 

# test 12.3.1.3.6 Accessed flag == 0
.8byte 0x802036D0, 0x0990DEADBEEF0770, 0x0 # write fault when A=0
.8byte 0x80203AB8, 0x0990DEADBEEF0990, 0x1 # read fault when A=0

# test 12.3.1.3.7 Dirty flag == 0
.8byte 0x80204658, 0x0440DEADBEEF0AA0, 0x0 # write fault when D=0
.8byte 0x80204AA0, 0x0440DEADBEEF0BB0, 0x1 # read success when D=0

# terminate tests
.8byte 0x0, 0x0, 0x3 # brings us back into machine mode with a final ecall, writing 0x9 to the output.

