///////////////////////////////////////////
//
// WALLY-MMU-SV39-SVADU
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

#include "WALLY-TEST-LIB-64.h" 
RVTEST_ISA("RV64I_Zicsr_Zifencei")
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;def NO_SAIL=True;",mmu-sv39)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

TEST_STACK_AND_DATA

.align 3
test_cases:

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
#   The encoding for x30 test type values can be found in the test handler
# 
# ---------------------------------------------------------------------------------------------

# =========== test 11.3.1.1 Page Table Translation ===========

# test 11.3.1.1.1 write page tables / entries to physical memory
# sv39 page table (See Figure 12.12***):
# Level 2 page table, situated at 0x8000D000
.8byte 0x000000008000D000, 0x0000000020004C01, write64_test# points to level 1 page table A
.8byte 0x000000008000D008, 0x0000000020005001, write64_test# points to level 1 page table B #*** replacing all the pointers DAU bits with 0.
.8byte 0x000000008000D010, 0x00000000200000CF, write64_test# Vaddr 0x8000_0000, Paddr 0x80000000: aligned gigapage (program and data memory)
.8byte 0x000000008000D018, 0x00004000004000C7, write64_test# Vaddr 0xC000_0000: misaligned gigapage
.8byte 0x000000008000DFF8, 0x0000000020005401, write64_test # points to level 1 page table C

# Level 1 page table A
.8byte 0x0000000080013000, 0x0000000020006001, write64_test# points to level 0 page table A

# Level 1 page table B
.8byte 0x0000000080014000, 0x00000000200000CB, write64_test# Vaddr 0x4000_0000, Paddr 0x80000000: aligned megapage, W=0, used for execution tests
.8byte 0x0000000080014008, 0x00000400000080C3, write64_test# Vaddr 0x4020_0000: misaligned megapage
.8byte 0x0000000080014010, 0x00000000200000DF, write64_test# Vaddr 0x4040_0000, Paddr 0x80000000: aligned megapage, aliased with program, U=1
.8byte 0x0000000080014018, 0x00000000210800C9, write64_test# Vaddr 0x4060_0000, Paddr 0x84200000: R=0, reads should fault
# Level 1 page table C
.8byte 0x0000000080015FF8, 0x0000000020005801, write64_test# points to level 0 page table B

# Level 0 page table A
.8byte 0x0000000080018000, 0x00000000200070D1, write64_test# Vaddr 0x0000: bad PTE points to level -1 table
.8byte 0x0000000080018008, 0x00000000200800DF, write64_test# Vaddr 0x1000, Paddr = 0x80200000: aligned kilopage
.8byte 0x0000000080018010, 0x00000000200810D5, write64_test# Vaddr 0x2000: bad PTE has W but not R
.8byte 0x0000000080018018, 0x0000000020080817, write64_test# Vaddr 0x3000 Paddr 0x80202000: A=0, should cause read fault
.8byte 0x0000000080018020, 0x0000000020080C57, write64_test# Vaddr 0x4000 Paddr 0x80203000: D=0, should cause write fault
.8byte 0x0000000080018028, 0x00000000200814C7, write64_test# Vaddr 0x5000 Paddr 0x80205000: X=0, fetches should fault
.8byte 0x0000000080018030, 0x00000000200814C0, write64_test# Vaddr 0x6000: invalid page
.8byte 0x0000000080018038, 0x01000000200800DF, write64_test# Vaddr 0x7000, Paddr = 0x80200000, bad reserved bit
.8byte 0x0000000080018040, 0x20000000200800DF, write64_test# Vaddr 0x8000, Paddr = 0x80200000, PBMT = 1
.8byte 0x0000000080018048, 0x40000000200800DF, write64_test# Vaddr 0x9000, Paddr = 0x80200000, PMBT = 2
.8byte 0x0000000080018050, 0x60000000200800DF, write64_test# Vaddr 0xA000, Paddr = 0x80200000, PMBT = 3
.8byte 0x0000000080018080, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x0000000080018088, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x0000000080018090, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x0000000080018098, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180A0, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180A8, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180B0, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180B8, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180C0, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180C8, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180D0, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180D8, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180E0, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180E8, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180F0, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x00000000800180F8, 0x80000000200820DF, write64_test# Vaddr 0x10000, Paddr = 0x80200000, NAPOT
.8byte 0x0000000080018150, 0x80000000200800DF, write64_test# Vaddr 0x20000, Paddr = 0x80200000, NAPOT malformed with ppn[3] =0

# Level 0 page table B
.8byte 0x0000000080016FF8, 0x00000000200804CF, write64_test# Vaddr 0xFFFFFFFFFFFFF000, Paddr 0x80201000 aligned kilopage

# second page table to check context switches with satp
.8byte 0x87FFF000, 0x200000CF, write64_test# Vaddr 0x0, Paddr 0x80000000 aligned gigapage
.8byte 0x87FFF010, 0x200000CF, write64_test# Vaddr 0x8000_0000, Paddr 0x80000000: aligned gigapage (program and data memory so we can execute without jumping around)

# test 11.3.1.1.2 write values to Paddrs in each page
# each of these values is used for 11.3.1.1.3 and some other tests, specified in the comments.
# when a test is supposed to fault, nothing is written into where it'll be reading/executing since it should fault before getting there.
.8byte 0x80200AB0, 0x0000DEADBEEF0000, write64_test # 11.3.1.1.4 and 11.3.1.4.1
.8byte 0x800FFAB8, 0x0880DEADBEEF0055, write64_test # 11.3.1.1.4
.8byte 0x80200AC0, 0x0990DEADBEEF0033, write64_test # 11.3.1.3.2
.8byte 0x80203130, 0x0110DEADBEEF0077, write64_test # 11.3.1.3.2
.8byte 0x80099000, 0x0000806711100393, write64_test # 11.3.1.3.1 and 11.3.1.3.2 write executable code for "li x7, 0x111; ret"
.8byte 0x80205AA0, 0x0000806711100393, write64_test # 11.3.1.3.5 write same executable code
.8byte 0x80201888, 0x0220DEADBEEF0099, write64_test # 11.3.1.1.4
.8byte 0x84212348, 0x0330DEADBEEF0440, write64_test # 11.3.1.3.3
.8byte 0x8020A400, 0x0550DEADBEEF0660, write64_test # 11.3.1.3.9 
.8byte 0x80205000, 0x0770DEADBEEF0880, write64_test # 11.3.1.2.2 junk in memory location corresponding to invalid page
	
#.8byte 0x800ffab8, 0x0880deadbeef0990, write64_test # 11.3.1.1.4 
.8byte 0x80203aa0, 0x0880deadbeef0991, write64_test # 11.3.1.3.7(a)
#.8byte 0x80205000, 0x0770DEADBEEF0880, write64_test # 11.3.1.2.2 junk in memory location corresponding to invalid page

# test 11.3.1.1.3 read values back from Paddrs without translation (this also verifies the previous test)
.8byte 0x0, 0x0, goto_baremetal# satp.MODE = baremetal / no translation.
.8byte 0x0, 0x0, goto_s_mode # change to S mode, 0xb written to output
.8byte 0x80200AB0, 0x0000DEADBEEF0000, read64_test
.8byte 0x800FFAB8, 0x0880DEADBEEF0055, read64_test
.8byte 0x80200AC0, 0x0990DEADBEEF0033, read64_test
.8byte 0x80203130, 0x0110DEADBEEF0077, read64_test
.8byte 0x80201888, 0x0220DEADBEEF0099, read64_test
.8byte 0x84212348, 0x0330DEADBEEF0440, read64_test

# test 11.3.1.1.4 check translation works in sv39, read the same values from previous tests, this time with Vaddrs
.8byte 0x8000D, 0x0, goto_sv39 # satp.MODE = sv39, with base page table PPN = 0x8000D and ASID = 0. current VPN: gigapage at 0x80000000.
.8byte 0x80200AB0, 0x0000DEADBEEF0000, read64_test         # gigapage at Vaddr 0x80000000, Paddr 0x80000000
.8byte 0x400FFAB8, 0x0880DEADBEEF0055, read64_test         # megapage at Vaddr 0x40400000, Paddr 0x80000000
.8byte 0xFFFFFFFFFFFFF888, 0x0220DEADBEEF0099, read64_test # kilopage at Vaddr 0xFFFFFFFFFFFFF000, Paddr 0x80201000

# =========== test 11.3.1.2 page fault tests ===========

# test 11.3.1.2.1 load page fault if upper bits of Vaddr are not the same
.8byte 0x0010000080000AB0, 0x0, read64_test# gigapage at Vaddr 0x80000000, Paddr 0x80000000, bad 1 in upper bits
.8byte 0xFF0FFFFFFFFFF888, 0x0, read64_test# kilopage at Vaddr 0xFFFFFFFFFFFFF000, Paddr 0x80201000, bad 0000 in upper bits

# test 11.3.1.2.2 load page fault when reading an address where the valid flag is zero
.8byte 0x6000, 0x0, read64_test

# test 11.3.1.2.3 store page fault if PTE has W and ~R flags set
.8byte 0x2000, 0x0, write64_test

# test 11.3.1.2.4 Fault if last level PTE is a pointer
.8byte 0x0020, 0x0, read64_test

# test 11.3.1.2.5 load page fault on misaligned pages
.8byte 0xC0000000, 0x0, read64_test# misaligned gigapage
.8byte 0x40200000, 0x0, read64_test# misaligned megapage

# =========== test 11.3.1.3 PTE Protection flags ===========


# test 11.3.1.3.1 User flag == 0
# *** reads on pages with U=0 already tested in 11.3.1.1.4
.8byte 0x40099000, 0x111, executable_test                       # execute success when U=0, priv=S
.8byte 0x40400000, 0x2, goto_u_mode                         # go to U mode, return to megapage at 0x40400000 where U = 1. 0x9 written to output
.8byte 0xFFFFFFFFFFFFFC80, 0x0880DEADBEEF0550, read64_test # load page fault when U=0, priv=U
.8byte 0x40099000, 0xbad, executable_test                       # execute fault when U=0, priv=U

# test 11.3.1.3.2 User flag == 1
.8byte 0x1AC0, 0x0990DEADBEEF0033, read64_test # read success when U=1, priv=U
.8byte 0x80000000, 0x1, goto_s_mode                   # go back to S mode, return to gigapage at 0x80000000 where U = 0. 0x8 written to output
.8byte 0x0, 0x3, write_mxr_sum                    # set sstatus.[MXR, SUM] = 11
.8byte 0x4130, 0x0110DEADBEEF0077, read64_test # read success when U=1, priv=S, sstatus.SUM=1
.8byte 0x40499000, 0xbad, executable_test           # instr page fault when U=1, priv=S (with any sstatus.SUM)
.8byte 0x0, 0x2, write_mxr_sum                    # set sstatus.[MXR, SUM] = 10.
.8byte 0x1AC0, 0x0990DEADBEEF0033, read64_test # load page fault when U-1, priv=S, sstatus.SUM=0

# test 11.3.1.3.3 Read flag
# *** reads on pages with R=1 already tested in 11.3.1.1.4
.8byte 0x0, 0x1, write_mxr_sum                        # set sstatus.[MXR, SUM] = 01.
.8byte 0x40612348, 0x0330DEADBEEF0440, read64_test # load page fault when R=0, sstatus.MXR=0
.8byte 0x0, 0x3, write_mxr_sum                        # set sstatus.[MXR, SUM] = 11.
.8byte 0x40612348, 0x0330DEADBEEF0440, read64_test # read success when MXR=1, X=1

# test 11.3.1.3.4 Write flag
.8byte 0x80AAAAA0, 0x0440DEADBEEF0110, write64_test# write success when W=1
.8byte 0x80AAAAA0, 0x0440DEADBEEF0110, read64_test# check write success by reading the same address
.8byte 0x40000000, 0x0220DEADBEEF0BB0, write64_test# store page fault when W=0

# test 11.3.1.3.5 eXecute flag
# *** fetches on pages with X = 1 already tested in 11.3.1.3.1
.8byte 0x5AA0, 0x1, executable_test                 # instr page fault when X=0


# In the following two tests, SVADU is supported, so the hardware handles the A/D bits
# Initially test with ADUE = 0, so needing to set A/D bits triggers page fault

# test 11.3.1.3.6(a) Accessed flag == 0
.8byte 0x36D0, 0x0990DEADBEEF0770, write64_test# store page fault when A=0
.8byte 0x3AB8, 0x0990DEADBEEF0990, read64_test# load page fault when A=0

# test 11.3.1.3.7(a) Dirty flag == 0
.8byte 0x4658, 0x0440DEADBEEF0AA0, write64_test# store page fault when D=0
.8byte 0x4AA0, 0xDEADBEEFDEADBEEF, read64_test# read success when D=0

# Now set ADUE bit
.8byte 0x0, 0x0, goto_m_mode # change to M mode, 0x9 written to output
.8byte 0x0, 0x2000000000000000, write_menvcfg  # set menvcfg.HADE = 1
.8byte 0x0, 0x0, goto_s_mode # change to S mode, 0xb written to output

# Since SVADU is 1, there are no faults when A/D=0
# test 11.3.1.3.6(b) Accessed flag == 0
.8byte 0x36D0, 0x0990DEADBEEF0770, write64_test # Write success when A=0 and SVADU is enabled
.8byte 0x36D0, 0x0990DEADBEEF0770, read64_test # Read success when A=0 and SVADU is enabled

# test 11.3.1.3.7(b) Dirty flag == 0
.8byte 0x4658, 0x0440DEADBEEF0AA0, write64_test # Write success when D=0 and SVADU is enabled
.8byte 0x4658, 0x0440DEADBEEF0AA0, read64_test # read success when D=0

# test 11.3.1.3.8 Reserved bits nonzero
.8byte 0x7AA0, 0x123456789ABCDEF, read64_test # load page fault because reserved is nonzero

# test 11.3.1.3.9 NAPOT read
.8byte 0x1A400, 0x0550DEADBEEF0660, read64_test # read from NAPOT 64 KiB page

# test 11.3.1.3.9 NAPOT read
.8byte 0x2A400, 0x0550DEADBEEF0660, read64_test # read from NAPOT 64 KiB page with malformed PTE should page fault

# test 11.3.1.3.10 PBMT checks
.8byte 0x8040, 0x1212343456567878, write64_test # Write fault with PBMT when menvcfg.PBMTE = 0
.8byte 0x0, 0x0, goto_m_mode # change to M mode, 0x9 written to output
.8byte 0x0, 0x4000000000000000, write_menvcfg  # set menvcfg.PBMTE = 1
.8byte 0x0, 0x0, goto_s_mode # change to S mode, 0xb written to output
.8byte 0x8040, 0x1212343456567878, write64_test # Write success with PBMT = 1
.8byte 0x8040, 0x1212343456567878, read64_test # Read back success with PBMT = 1
.8byte 0x9050, 0x2312343456567878, write64_test # Write success with PBMT = 2
.8byte 0x9050, 0x2312343456567878, read64_test # Read back success with PBMT = 2
.8byte 0xA060, 0x3412343456567878, write64_test # Write faults with PBMT = 3

# =========== test 11.3.1.4 SATP Register ===========

# test 11.3.1.4.1 SATP ASID and PPN fields (test having two page tables with different ASID)
// *** .8byte 0xFFFFFFFFFFFFF888, 0x0220DEADBEEF0099, write64_test # write identical value to global PTE to make sure it's still in the TLB
.8byte 0x87FFF, 0x11, goto_sv39 # go to SV39 on a second, very minimal page table
.8byte 0x200AB0, 0x0000DEADBEEF0000, read64_test # Read success of old written value from a new page table mapping 

# test 11.3.1.4.2 Test Global mapping
// ***.8byte 0x7FFFFFF888, 0x0220DEADBEEF0099, read64_test # read success of global PTE undefined in current mapping.


# =========== test 11.3.1.5 STATUS Registers ===========

# test 11.3.1.5.1 mstatus.mprv translation
# *** mstatus.mprv = 0 tested on every one of the translated reads and writes before this.
.8byte 0x8000D, 0x0, goto_sv39 // go back to old, extensive page table
.8byte 0x80000000, 0x1, goto_m_mode // go to m mode to be able to write mstatus
.8byte 0x1, 0x1, read_write_mprv // write 1 to mstatus.mprv and set mstatus.mpp to be 01=S
.8byte 0xFFFFFFFFFFFFF888, 0x0220DEADBEEF0099, read64_test // read test succeeds with translation even though we're in M mode since MPP=S and MPRV=1

# test 11.3.1.5.2 mstatus.mprv clearing
# mstatus.mprv is already 1 from the last test so going to S mode should clear it with the mret
.8byte 0x80000000, 0x1, goto_s_mode // This should zero out the mprv bit but now to read and write mstatus, we have to 
.8byte 0x80000000, 0x1, goto_m_mode // go back to m mode to allow us to reread mstatus.
.8byte 0x0, 0x0, read_write_mprv // read what should be a zeroed out mprv value and then force it back to zero.

# test 11.3.1.5.3 sstatus.mxr read
# this bitfield already tested in 11.3.1.3.3

# terminate tests
.8byte 0x0, 0x0, terminate_test # brings us back into machine mode with a final ecall, writing 0x9 to the output.

