///////////////////////////////////////////
//
// WALLY-MMU-SV48
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
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;def NO_SAIL=True;",sv48)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

TEST_STACK_AND_DATA

# These tests follow the testing plan in Chapter 12 of the riscv-wally textbook
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
#   The encoding for x30 test type values can be found in the test handler in the framework file
# 
# ---------------------------------------------------------------------------------------------


# =========== test 11.3.1.1 Page Table Translation ===========

# test 11.3.1.1.1 write page tables / entries to physical memory
# sv48 page table (See Figure 12.12***):
# Level 3 page table, situated at 0x8000D000
.8byte 0x000000008000D000, 0x0000000020004C01, write64_test # points to level 2 page table A
.8byte 0x000000008000D008, 0x0000000020005001, write64_test # points to level 2 page table B # Changing DAU bits of each pointer to zero
.8byte 0x000000008000D010, 0x00000000000000C7, write64_test # Vaddr 0x010000000000, Paddr 0x00000000: aligned terapage
.8byte 0x000000008000D018, 0x00004000004000C7, write64_test # Vaddr 0x018000000000, misaligned terapage
.8byte 0x000000008000DFF8, 0x0000000020005401, write64_test # points to level 2 page table C

# Level 2 page table A
.8byte 0x0000000080013010, 0x0000000020006001, write64_test # points to level 1 page table A

# Level 2 page table B
.8byte 0x0000000080014000, 0x00000000200000CB, write64_test # Vaddr 0x008000000000, Paddr 0x80000000: aligned gigapage used for execution tests
.8byte 0x0000000080014008, 0x00000000200000DF, write64_test # Vaddr 0x008040000000, Paddr 0x80000000: aligned gigapage (aliased with data and instr memory) U bit set.
.8byte 0x0000000080014010, 0x00000400080000C3, write64_test # Vaddr 0x008080000000, misaligned gigapage
# Level 2 page table C
.8byte 0x0000000080015FF8, 0x0000000020005801, write64_test # points to level 1 page table B

# Level 1 page table A
.8byte 0x0000000080018000, 0x00000000200000CF, write64_test # Vaddr 0x80000000, Paddr 0x80000000: aligned megapage (data and instr memory)
.8byte 0x0000000080018008, 0x0000000020006401, write64_test # points to level 0 page table A
.8byte 0x0000000080018010, 0x000000C0000400CF, write64_test # Vaddr 0x80400000, misaligned megapage
.8byte 0x0000000080018018, 0x00000000214800C9, write64_test # Vaddr 0x80600000, Paddr 0x85200000: aligned megapage, R=0
# Level 1 page table B
.8byte 0x0000000080016FF8, 0x0000000020006801, write64_test # points to level 0 page table B

# Level 0 page table A
.8byte 0x0000000080019000, 0x00000000200070D1, write64_test # Vaddr 0x80200000, Paddr 0x8001C000: bad PTE points to level -1 table
.8byte 0x0000000080019008, 0x00000000200800DF, write64_test # Vaddr 0x80201000, Paddr 0x80200000: aligned kilopage
.8byte 0x0000000080019010, 0x00000000200810DF, write64_test # Vaddr 0x80202000, Paddr 0x80204000: bad PTE has W but not R
.8byte 0x0000000080019018, 0x0000000020080817, write64_test # Vaddr 0x80203000, Paddr 0x80202000: A=0, should cause read fault
.8byte 0x0000000080019020, 0x0000000020080C57, write64_test # Vaddr 0x80204000, Paddr 0x80203000: D=0, should cause write fault
.8byte 0x0000000080019028, 0x0000000020333000, write64_test # Vaddr 0x80205000, Paddr 0x80CCC000, invalid page.
# Level 0 page table B
.8byte 0x000000008001AFF8, 0x00000000200804CF, write64_test # Vaddr 0xFFFFFFFFF000, Paddr 0x80201000: aligned kilopage

# second page table to check context switches with satp
# Level 3 page table A
.8byte 0x8000F000, 0x2000BC01, write64_test # points to level 2 page table A
# Level 2 page table A
.8byte 0x8002F000, 0x200000CF, write64_test # Vaddr 0x0, Paddr 0x80000000: aligned gigapage
.8byte 0x8002F010, 0x200000CF, write64_test # Vaddr 0x80000000, Paddr 0x80000000: aligned gigapage (data and instr memory)


# test 11.3.1.1.2 write values to Paddrs in each page
# each of these values is used for 11.3.1.1.3 and some other tests, specified in the comments.
# when a test is supposed to fault, nothing is written into where it'll be reading/executing since it should fault before getting there.
.8byte 0x82777778, 0x0EE0DEADBEEF0CC0, write64_test # 11.3.1.1.4 terapage
.8byte 0x85BC0AB0, 0x0000DEADBEEF0000, write64_test # 11.3.1.1.4 gigapage
.8byte 0x800F0AB8, 0x0880DEADBEEF0055, write64_test # 11.3.1.1.4 megapage
.8byte 0x80201888, 0x0220DEADBEEF0099, write64_test # 11.3.1.1.4 kilopage
.8byte 0x80099000, 0x0000806711100393, write64_test # 11.3.1.3.1 write executable code for "li x7, 0x111; ret"
.8byte 0x80200400, 0x0000806711100393, write64_test # 11.3.1.3.2 write same executable code 
.8byte 0x80200AC0, 0x0990DEADBEEF0033, write64_test # 11.3.1.3.2 
.8byte 0x80200130, 0x0110DEADBEEF0077, write64_test # 11.3.1.3.2
.8byte 0x85212348, 0x0330DEADBEEF0440, write64_test # 11.3.1.3.3
.8byte 0x87888000, 0x0000806711100393, write64_test # 11.3.1.3.5 write same executable code
.8byte 0x80203AA0, 0x0440DEADBEEF0BB0, write64_test # 11.3.1.3.7

# test 11.3.1.1.3 read values back from Paddrs without translation (this also verifies the previous test)
.8byte 0x0, 0x0, goto_baremetal # satp.MODE = baremetal / no translation.
.8byte 0x0, 0x0, goto_s_mode # change to S mode, 0xb written to output
.8byte 0x82777778, 0x0EE0DEADBEEF0CC0, read64_test
.8byte 0x85BC0AB0, 0x0000DEADBEEF0000, read64_test
.8byte 0x800F0AB8, 0x0880DEADBEEF0055, read64_test
.8byte 0x80200AC0, 0x0990DEADBEEF0033, read64_test
.8byte 0x80200130, 0x0110DEADBEEF0077, read64_test
.8byte 0x80201888, 0x0220DEADBEEF0099, read64_test
.8byte 0x85212348, 0x0330DEADBEEF0440, read64_test
.8byte 0x80203AA0, 0x0440DEADBEEF0BB0, read64_test

# test 11.3.1.1.4 check translation works in sv48, read the same values from previous tests, this time with Vaddrs
.8byte 0x8000D, 0x0, goto_sv48 # satp.MODE = sv48, with base page table PPN = 0x8000D and ASID = 0. current VPN: megapage at 0x80000000. Nothing written to output
.8byte 0x10082777778, 0x0EE0DEADBEEF0CC0, read64_test      # terapage at Vaddr 0x010000000000, Paddr 0x0
.8byte 0x8005BC0AB0, 0x0000DEADBEEF0000, read64_test       # gigapage at Vaddr 0x008000000000, Paddr 0x80000000
.8byte 0x800F0AB8, 0x0880DEADBEEF0055, read64_test         # megapage at Vaddr 0x80000000, Paddr 0x80000000
.8byte 0xFFFFFFFFFFFFF888, 0x0220DEADBEEF0099, read64_test # kilopage at Vaddr 0xFFFFFFFFFFFFF000, Paddr 0x80201000

# =========== test 11.3.1.2 page fault tests ===========

# test 11.3.1.2.1 page fault if upper bits of Vaddr are not the same
.8byte 0x001000800ABC0AB0, 0x0, read64_test# gigapage at Vaddr 0x008000000000, Paddr 0x80000000, bad 1 in upper bits
.8byte 0xFF0FFFFFFFFFF888, 0x0, read64_test# kilopage at Vaddr 0xFFFFFFFFFFFFF000, Paddr 0x80201000, bad 0000 in upper bits

# test 11.3.1.2.2 read fault when reading an address where the valid flag is zero
.8byte 0x80205000, 0x0, read64_test

# test 11.3.1.2.3 write fault if PTE has W and ~R flags set
.8byte 0x80202000, 0x0, write64_test 

# test 11.3.1.2.4 Fault if last level PTE is a pointer
.8byte 0x80200000, 0x0, read64_test

# test 11.3.1.2.5 read fault on misaligned pages
.8byte 0x18000000000, 0x0, read64_test # misaligned terapage
.8byte 0x8080000000, 0x0, read64_test  # misaligned gigapage
.8byte 0x80400000, 0x0, read64_test    # misaligned megapage

# =========== test 11.3.1.3 PTE Protection flags ===========

# test 11.3.1.3.1 User flag == 0
# reads on pages with U=0 already tested in 11.3.1.1.4
.8byte 0x008000099000, 0x111, executable_test                   # execute success when U=0, priv=S
.8byte 0x008040000000, 0x1, goto_u_mode                     # go to U mode, return to gigapage at 0x008040000000 where PTE.U = 1. 0x9 written to output
.8byte 0xFFFFFFFFFFFFFC80, 0x0880DEADBEEF0550, read64_test # read fault when U=0, priv=U
.8byte 0x008000099000, 0xbad, executable_test                   # execute fault when U=0, priv=U

# test 11.3.1.3.2 User flag == 1
.8byte 0x80201AC0, 0x0990DEADBEEF0033, read64_test # read success when U=1, priv=U
.8byte 0x80000000, 0x2, goto_s_mode 
.8byte 0x0, 0x3, write_mxr_sum                        # set sstatus.[MXR, SUM] = 11
.8byte 0x80201130, 0x0110DEADBEEF0077, read64_test # read success when U=1, priv=S, sstatus.SUM=1
.8byte 0x80201400, 0xbad, executable_test               # execute fault when U=1, priv=S (with any sstatus.SUM) 
.8byte 0x0, 0x2, write_mxr_sum                        # set sstatus.[MXR, SUM] = 10.
.8byte 0x80201AC0, 0x0990DEADBEEF0033, read64_test # read fault when U=1, priv=S, sstatus.SUM=0

# test 11.3.1.3.3 Read flag
# reads on pages with R=1 already tested in 11.3.1.1.4
.8byte 0x0, 0x1, write_mxr_sum                        # set sstatus.[MXR, SUM] = 01.
.8byte 0x80612348, 0x0330DEADBEEF0440, read64_test # read fault when R=0, sstatus.MXR=0
.8byte 0x0, 0x3, write_mxr_sum                        # set sstatus.[MXR, SUM] = 11.
.8byte 0x80612348, 0x0330DEADBEEF0440, read64_test # read success when MXR=1, X=1

# test 11.3.1.3.4 Write flag
.8byte 0x10080BCDED8, 0x0440DEADBEEF0110, write64_test    # write success when W=1 (corresponding Paddr = 0x80BCDED8)
.8byte 0x10080BCDED8, 0x0440DEADBEEF0110, read64_test   # check write success by reading value back
.8byte 0x8000009E88, 0x0220DEADBEEF0BB0, write64_test     # write fault when W=0

# test 11.3.1.3.5 eXecute flag
# executes on pages with X = 1 already tested in 11.3.1.3.1
.8byte 0x010087888000, 0x2, executable_test               # execute fault when X=0 

# In the following two tests, SVADU is not supported, so the software handles the A/D bits
# Since SVADU is 0, Accesses to A/D=0 causes a fault for the trap handler to fix those bits

# test 11.3.1.3.6 Accessed flag == 0
.8byte 0x802036D0, 0x0990DEADBEEF0770, write64_test # write fault when A=0
.8byte 0x80203AB8, 0x0990DEADBEEF0990, read64_test# read fault when A=0

# test 11.3.1.3.7 Dirty flag == 0
.8byte 0x80204658, 0x0440DEADBEEF0AA0, write64_test # write fault when D=0
.8byte 0x80204AA0, 0x0440DEADBEEF0BB0, read64_test# read success when D=0

# =========== test 11.3.1.4 SATP Register ===========

# test 11.3.1.4.1 SATP ASID and PPN fields (test having two page tables with different ASID)
// *** .8byte 0xFFFFFFFFFFFFF888, 0x0220DEADBEEF0099, write64_test # write identical value to global PTE to make sure it's still in the TLB
.8byte 0x8000F, 0x11, goto_sv48 # go to SV39 on a second, very minimal page table
.8byte 0x5BC0AB0, 0x0000DEADBEEF0000, read64_test # Read success of old written value from a new page table mapping 

# test 11.3.1.4.2 Test Global mapping
// ***.8byte 0x7FFFFFF888, 0x0220DEADBEEF0099, read64_test # read success of global PTE undefined in current mapping.


# =========== test 11.3.1.5 STATUS Registers ===========

# test 11.3.1.5.1 mstatus.mprv translation
# *** mstatus.mprv = 0 tested on every one of the translated reads and writes before this.
.8byte 0x8000D, 0x0, goto_sv48 // go back to old, extensive page table
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

