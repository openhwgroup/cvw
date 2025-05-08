///////////////////////////////////////////
//
// WALLY-MMU-SV32
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

#include "WALLY-TEST-LIB-32.h" 

RVTEST_ISA("RV32I_Zicsr_Zifencei")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",mmu)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

TEST_STACK_AND_DATA

.align 2
test_cases:
# ---------------------------------------------------------------------------------------------
# Test Contents
#
#   Here is where the actual tests are held, or rather, what the actual tests do.
#   each entry consists of 3 values that will be read in as follows:
#   
#   '.4byte [x28 Value], [x29 Value], [x30 value]'
#                     or
#   '.4byte [address], [value], [test type]'
#
#   The encoding for x30 test type values can be found in the test handler in the framework file
# 
# ---------------------------------------------------------------------------------------------

# =========== test 11.3.1.1 Page Table Translation ===========

# test 11.3.1.1.1 write page tables / entries to physical memory
# sv32 Page table (See Figure 12.12***):
# Level 1 page table, situated at 0x8000D000
.4byte 0x8000D000, 0x20004C01, write32_test  # points to level 0 page table A
.4byte 0x8000D004, 0x200000CB, write32_test  # Vaddr 0x400000 Paddr 0x80000000: aligned megapage, W=0, used for execute tests
.4byte 0x8000D008, 0x20005401, write32_test  # points to level 0 page table B 
.4byte 0x8000D00C, 0x000800C7, write32_test  # Vaddr 0xC00000: misaligned megapage
.4byte 0x8000D800, 0x200000CF, write32_test  # Vaddr 0x80000000 Paddr 0x80000000: aligned megapage (program and data memory)
.4byte 0x8000D804, 0x200000DF, write32_test  # Vaddr 0x80400000 Paddr 0x80000000: aligned megapage, U=1 (aliased with program and data memory)
# Level 0 page table A
.4byte 0x80013000, 0x20007001, write32_test  # Vaddr 0x0000: bad PTE points to level -1 table
.4byte 0x80013004, 0x202000DF, write32_test  # Vaddr 0x1000 Paddr 0x80800000: aligned kilopage, U=1
.4byte 0x80013008, 0x202010D5, write32_test  # Vaddr 0x2000: pad PTE has W but not R
.4byte 0x8001300C, 0x20200817, write32_test  # Vaddr 0x3000: A=0, should cause read fault
.4byte 0x80013010, 0x20200C57, write32_test  # Vaddr 0x4000: D=0, should cause write fault
.4byte 0x80013014, 0x202014C9, write32_test  # Vaddr 0x5000 Paddr 80805000: aligned kilopage, W=R=0
.4byte 0x80013018, 0x0, write32_test         # Vaddr 0x6000: invalid page
# Level 0 page table B
.4byte 0x80015FFC, 0x202004C7, write32_test  # Vaddr 0xBFF000 Paddr 0x80801000: aligned kilopage with X=0, U=0

# second page table to check context switches with satp
.4byte 0x8000F000, 0x200000CF, write32_test # Vaddr 0x0 Paddr 0x80000000: aligned megapage
.4byte 0x8000F800, 0x200000CF, write32_test # Vaddr 0x80000000 Paddr 0x80000000: aligned megapage (program and data memory)

# test 11.3.1.1.2 write values to Paddrs in each page
# each of these values is used for 11.3.1.1.3 and some other tests, specified in the comments.
# when a test is supposed to fault, nothing is written into where it'll be reading/executing since it should fault before getting there.
.4byte 0x800AAAA8, 0xBEEF0055, write32_test # 11.3.1.1.4 megapage
.4byte 0x800FFAC0, 0xBEEF0033, write32_test # 11.3.1.3.2 
.4byte 0x800E3130, 0xBEEF0077, write32_test # 11.3.1.3.2
.4byte 0x808017E0, 0xBEEF0099, write32_test # 11.3.1.1.4 kilopage
.4byte 0x80805EA0, 0xBEEF0440, write32_test # 11.3.1.3.3
.4byte 0x80803AA0, 0xBEEF0BB0, write32_test # 11.3.1.3.7
.4byte 0x8000FFA0, 0x11100393, write32_test # write executable code for "li x7, 0x111; ret" to executable region.
.4byte 0x8000FFA4, 0x00008067, write32_test # Used for 11.3.1.3.1, 11.3.1.3.2

# test 11.3.1.1.3 read values back from Paddrs without translation (this also verifies the previous test)
.4byte 0x0, 0x0, goto_baremetal # satp.MODE = baremetal / no translation.
.4byte 0x0, 0x0, goto_s_mode # change to S mode, 0xb written to output
.4byte 0x800AAAA8, 0xBEEF0055, read32_test
.4byte 0x800FFAC0, 0xBEEF0033, read32_test
.4byte 0x800E3130, 0xBEEF0077, read32_test
.4byte 0x808017E0, 0xBEEF0099, read32_test
.4byte 0x80805EA0, 0xBEEF0440, read32_test
.4byte 0x80803AA0, 0xBEEF0BB0, read32_test
.4byte 0x8000FFA0, 0x11100393, read32_test
.4byte 0x8000FFA4, 0x00008067, read32_test

# test 11.3.1.1.4 check translation works in sv48, read the same values from previous tests, this time with Vaddrs
.4byte 0x8000D, 0x0, goto_sv32 # satp.MODE = sv32, Nothing written to output
.4byte 0x4AAAA8, 0xBEEF0055, read32_test    # megapage at Vaddr 0x400000, Paddr 0x80000000
.4byte 0xBFF7E0, 0xBEEF0099, read32_test    # kilopage at Vaddr 0xBFF000, Paddr 0x80201000

# =========== test 11.3.1.2 page fault tests ===========

# test 11.3.1.2.1 load page fault if upper bits of Vaddr are not the same
# Not tested in rv32/sv32

# test 11.3.1.2.2 load page fault when reading an address where the valid flag is zero
.4byte 0x6000, 0x0, read32_test

# test 11.3.1.2.3 store page fault if PTE has W and ~R flags set
.4byte 0x2000, 0x0, write32_test

# test 11.3.1.2.4 Fault if last level PTE is a pointer
.4byte 0x0200, 0x0, read32_test

# test 11.3.1.2.5 load page fault on misaligned pages
.4byte 0xC00000, 0x0, read32_test   # misaligned megapage

# =========== test 11.3.1.3 PTE Protection flags ===========

# test 11.3.1.3.1 User flag == 0
# *** reads on pages with U=0 already tested in 11.3.1.1.4
.4byte 0x40FFA0, 0x111, executable_test           # fetch success when U=0, priv=S
.4byte 0x80400000, 0x1, goto_u_mode             # go to U mode, return to VPN 0x80400000 where PTE.U = 1. 0x9 written to output
.4byte 0xBFFC80, 0xBEEF0550, read32_test    # load page fault when U=0, priv=U
.4byte 0x40FFA0, 0xbad, executable_test           # instr page fault when U=0, priv=U

# test 11.3.1.3.2 User flag == 1
.4byte 0x804FFAC0, 0xBEEF0033, read32_test  # read success when U=1, priv=U
.4byte 0x80000000, 0x1, goto_s_mode             # go back to S mode, return to VPN 0x80000000 where PTE.U = 0. 0x8 written to output
.4byte 0x0, 0x3, write_mxr_sum                # set sstatus.[MXR, SUM] = 11
.4byte 0x804E3130, 0xBEEF0077, read32_test  # read success when U=1, priv=S, sstatus.SUM=1
.4byte 0x8040FFA0, 0xbad, executable_test           # instr page fault when U=1, priv=S (with any sstatus.SUM)
.4byte 0x0, 0x2, write_mxr_sum                # set sstatus.[MXR, SUM] = 10.
.4byte 0x804FFAC0, 0xBEEF0033, read32_test  # load page fault when U-1, priv=S, sstatus.SUM=0

# test 11.3.1.3.3 Read flag
# *** reads on pages with R=1 already tested in 11.3.1.1.4
.4byte 0x0, 0x1, write_mxr_sum            # set sstatus.[MXR, SUM] = 01.
.4byte 0x5EA0, 0xBEEF0440, read32_test  # load page fault when R=0, sstatus.MXR=0
.4byte 0x0, 0x3, write_mxr_sum            # set sstatus.[MXR, SUM] = 11.
.4byte 0x5EA0, 0xBEEF0440, read32_test  # read success when R=0, MXR=1, X=1

# test 11.3.1.3.4 Write flag
.4byte 0xBFF290, 0xBEEF0110, write32_test    # write success when W=1
.4byte 0xBFF290, 0xBEEF0110, read32_test    # check write success by reading
.4byte 0x5B78, 0xBEEF0CC0, write32_test      # store page fault when W=0

# test 11.3.1.3.5 eXecute flag
# *** fetches on pages with X = 1 already tested in 11.3.1.3.1
.4byte 0xBFFDE0, 0xbad, executable_test             # instr page fault when X=0 

# In the following two tests, SVADU is not supported, so the software handles the A/D bits
# Since SVADU is 0, Accesses to A/D=0 causes a fault for the trap handler to fix those bits

# test 11.3.1.3.6 Accessed flag == 0
.4byte 0x3020, 0xBEEF0770, write32_test # store page fault when A=0
.4byte 0x3808, 0xBEEF0990, read32_test # load page fault when A=0

# test 11.3.1.3.7 Dirty flag == 0
.4byte 0x4658, 0xBEEF0AA0, write32_test # store page fault when D=0
.4byte 0x4AA0, 0xBEEF0BB0, read32_test # read success when D=0

# =========== test 11.3.1.4 SATP Register ===========

# test 11.3.1.4.1 SATP ASID and PPN fields (test having two page tables with different ASID)
// *** .4byte 0xFFFFFFFFFFFFF888, 0x0220DEADBEEF0099, write32_test # write identical value to global PTE to make sure it's still in the TLB
.4byte 0x8000F, 0x11, goto_sv32 # go to SV39 on a second, very minimal page table
.4byte 0xE3130, 0xBEEF0077, read32_test # Read success of old written value from a new page table mapping 

# test 11.3.1.4.2 Test Global mapping
// ***.4byte 0x7FFFFFF888, 0x0220DEADBEEF0099, read32_test # read success of global PTE undefined in current mapping.


# =========== test 11.3.1.5 STATUS Registers ===========

# test 11.3.1.5.1 mstatus.mprv translation
# *** mstatus.mprv = 0 tested on every one of the translated reads and writes before this.
.4byte 0x8000D, 0x0, goto_sv32 // go back to old, extensive page table
.4byte 0x80000000, 0x1, goto_m_mode // go to m mode to be able to write mstatus
.4byte 0x1, 0x1, read_write_mprv // write 1 to mstatus.mprv and set mstatus.mpp to be 01=S
.4byte 0xBFF7E0, 0xBEEF0099, read32_test // read test succeeds with translation even though we're in M mode since MPP=S and MPRV=1

# test 11.3.1.5.2 mstatus.mprv clearing
# mstatus.mprv is already 1 from the last test so going to S mode should clear it with the mret
.4byte 0x80000000, 0x1, goto_s_mode // This should zero out the mprv bit but now to read and write mstatus, we have to 
.4byte 0x80000000, 0x1, goto_m_mode // go back to m mode to allow us to reread mstatus.
.4byte 0x0, 0x0, read_write_mprv // read what should be a zeroed out mprv value and then force it back to zero.

# test 11.3.1.5.3 sstatus.mxr read
# this bitfield already tested in 11.3.1.3.3

# terminate tests
.4byte 0x0, 0x0, terminate_test # brings us back into machine mode with a final ecall, writing 0x9 to the output.

