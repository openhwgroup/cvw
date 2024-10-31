///////////////////////////////////////////
//
// WALLY-cache-management-tests 
// invalidate, clean, and flush
//
// Author: Rose Thompson <rose@rosethompson.net>
//
// Created 18 August 2023
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
# Purpose: Tests the 3 Zicbom cache instructions which all operate on cacheline
#          granularity blocks of memory.  Invalidate: Clears valid and dirty bits
#          and does not write back.  Clean: Writes back dirty cacheline if needed
#          and clears dirty bit.  Does NOT clear valid bit.  Flush:  Cleans and then
#          Invalidates.  These operations apply to all caches in the memory system.
#          The tests are divided into three parts one for the data cache
#          and checks to verify the uncached regions of memory cause exceptions.
# -----------
# Copyright (c) 2020. RISC-V International. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# -----------
#
# This assembly file tests the cbo.inval, cbo.clean, and cbo.flush instructions of the RISC-V Zicbom extension.
# 

#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV64I_Zicbom")
# Test code region
.section .text.init
.globl rvtest_entry_point
	
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;def NO_SAIL=True;",cbo.inval)

RVMODEL_IO_WRITE_STR(x31, "# Test Begin\n")
	
CBOMTest:
        # *** TODO
        # first need to discover the length of the cacheline.
        # for now assume it is 64 bytes

        #addi sp, sp, -16
        #sd s0, 0(sp)
        #sd ra, 8(sp)

	la s0, signature

        ################################################################################
        # INVALIDATE  D$
        ################################################################################

        # theory of operation
        # 1. Read several cachelines of data from memory into the d cache and copy to a second region of memory
        # 2. Then verify the second region has the same data
        # 3. Invalidate the second region
        # 4. Verify the second region has the original invalid data
        # DON'T batch each step.  We want to see the transition between cachelines. The current should be invalidated
        # but the next should have the copied data.

        # step 1
CBOMTest_inval_step1: 
        la a0, SourceData
        la a1, Destination1
        li a2, 64
        jal ra, memcpy8

        # step 2
CBOMTest_inval_step2: 
        la a0, SourceData
        la a1, Destination1
        li a2, 64
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

        # step 3
CBOMTest_inval_step3: 
        la a1, Destination1
        cbo.inval (a1)
        # step 4  (should be Invalid)
        la a0, DeadBeafData1
        la a1, Destination1
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)    # should be -1
        addi s0, s0, 8

        # step 4 next line (should still be valid)
CBOMTest_inval_step4: 
        la a0, SourceData+64
        la a1, Destination1+64
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)    # should be -1
        addi s0, s0, 8

        # step 3 (Invalidate all remaining lines)
CBOMTest_inval_step3_all: 
        la a1, Destination1+64
        cbo.inval (a1)
        cbo.inval (a1)          # verify invalidating an already non present line does not cause an issue.
        la a1, Destination1+128
        cbo.inval (a1)
        la a1, Destination1+192
        cbo.inval (a1)
        la a1, Destination1+256
        cbo.inval (a1)
        la a1, Destination1+320
        cbo.inval (a1)
        la a1, Destination1+384
        cbo.inval (a1)
        la a1, Destination1+448
        cbo.inval (a1)
	
        # step 4 All should be invalid
CBOMTest_inval_step4_all: 
        la a0, DeadBeafData1
        la a1, Destination1
        li a2, 64
        jal ra, memcmp8
        sd a0, 0(s0)    # should be -1
        addi s0, s0, 8

        ################################################################################
        # INVALIDATE  all ways D$
        ################################################################################

        # theory of operation
        # 1. Read several cachelines of data from memory into the d cache and copy to a second region of memory
        # 2. Then verify the second region has the same data
        # 3. Invalidate the second region
        # 4. Verify the second region has the original invalid data
        # DON'T batch each step.  We want to see the transition between cachelines. The current should be invalidated
        # but the next should have the copied data.
	
        # step 0 copy deadbeef to remote regions spaced 4KiB apart
CBOMTest_way_inval_4096_step0: 
        la a0, DeadBeafData1
        la a1, Destination1+4096
        li a2, 8
        jal ra, memcpy8
CBOMTest_way_inval_8192_step0: 
        la a0, DeadBeafData1
        la a1, Destination1+8192
        li a2, 8
        jal ra, memcpy8
CBOMTest_way_inval_12288_step0: 
        la a0, DeadBeafData1
        la a1, Destination1+12288
        li a2, 8
        jal ra, memcpy8
CBOMTest_way_inval_16384_step0:       
        la a0, DeadBeafData1
        la a1, Destination1+16384
        li a2, 8
        jal ra, memcpy8
        # one of the following will force an eviction of each of the previous
CBOMTest_way_inval_20480_step0:       # this one should force eviction of _4096
        la a0, DeadBeafData1
        la a1, Destination1+20480
        li a2, 8
        jal ra, memcpy8
CBOMTest_way_inval_24576_step0:       # this one should force eviction of _4096
        la a0, DeadBeafData1
        la a1, Destination1+24576
        li a2, 8
        jal ra, memcpy8
CBOMTest_way_inval_28672_step0:       # this one should force eviction of _4096
        la a0, DeadBeafData1
        la a1, Destination1+28672
        li a2, 8
        jal ra, memcpy8
CBOMTest_way_inval_32768_step0:       # this one should force eviction of _4096
        la a0, DeadBeafData1
        la a1, Destination1+32768
        li a2, 8
        jal ra, memcpy8
        
        # step 1
CBOMTest_way_inval_4096_step1: 
        la a0, SourceData
        la a1, Destination1+4096
        li a2, 8
        jal ra, memcpy8

CBOMTest_way_inval_8192_step1: 
        la a0, SourceData
        la a1, Destination1+8192
        li a2, 8
        jal ra, memcpy8

CBOMTest_way_inval_12288_step1: 
        la a0, SourceData
        la a1, Destination1+12288
        li a2, 8
        jal ra, memcpy8
        
CBOMTest_way_inval_16384_step1: 
        la a0, SourceData
        la a1, Destination1+16384
        li a2, 8
        jal ra, memcpy8

        # don't want to ca      use a write back for the previous writes since we want to invalidate them
	
        # step 2
CBOMTest_way_inval_4096_step2: 
        la a0, SourceData
        la a1, Destination1+4096
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8
	
CBOMTest_way_inval_8192_step2: 
        la a0, SourceData
        la a1, Destination1+8192
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

CBOMTest_way_inval_12288_step2: 
        la a0, SourceData
        la a1, Destination1+12288
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

CBOMTest_way_inval_16384_step2: 
        la a0, SourceData
        la a1, Destination1+16384
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

CBOMTest_way_inval_step3_all_again: 
        la a1, Destination1+4096
        la a2, Destination1+8192
        la a3, Destination1+12288
        la a4, Destination1+16384
        cbo.inval (a1)
        cbo.inval (a2)          
        cbo.inval (a3)
        cbo.inval (a4)          
        
        # step 4 All should be invalid
CBOMTest_way_inval_4096_step4_all: 
        la a0, DeadBeafData1
        la a1, Destination1+4096
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)    # should be -1
        addi s0, s0, 8

CBOMTest_way_inval_8192_step4_all: 
        la a0, DeadBeafData1
        la a1, Destination1+8192
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)    # should be -1
        addi s0, s0, 8

CBOMTest_way_inval_12288_step4_all: 
        la a0, DeadBeafData1
        la a1, Destination1+12288
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)    # should be -1
        addi s0, s0, 8
	
CBOMTest_way_inval_16384_step4_all: 
        la a0, DeadBeafData1
        la a1, Destination1+16384
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)    # should be -1
        addi s0, s0, 8
	
        ################################################################################
        # Clean D$
        ################################################################################

        # theory of operation
        # 1. Read several cachelines of data from memory into the d cache and copy to a second region of memory
        # 2. Then verify the second region has the same data
        # 3. Invalidate the second region
        # 4. Verify the second region has the original invalid data
        # 5. Repeat step 1
        # 6. Clean cachelines
        # 7. Verify the second region has the same data
        # 8. Invalidate the second region
        # 9. Verify again but this time it should contain the same data
        # DON'T batch each step.  We want to see the transition between cachelines. The current should be invalidated
        # but the next should have the copied data.
        
        # step 1
CBOMTest_clean_step1: 
        la a0, SourceData
        la a1, Destination2
        li a2, 64
        jal ra, memcpy8

        # step 2
CBOMTest_clean_step2:
        la a0, SourceData
        la a1, Destination2
        li a2, 64
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

        # step 3
CBOMTest_clean_step3:
        la a1, Destination2
        cbo.inval (a1)
        la a1, Destination2+64
        cbo.inval (a1)
        la a1, Destination2+128
        cbo.inval (a1)
        la a1, Destination2+192
        cbo.inval (a1)
        la a1, Destination2+256
        cbo.inval (a1)
        la a1, Destination2+320
        cbo.inval (a1)
        la a1, Destination2+384
        cbo.inval (a1)
        la a1, Destination2+448
        cbo.inval (a1)
        cbo.inval (a1)
        cbo.inval (a1)
        cbo.inval (a1)
        cbo.inval (a1)
        cbo.inval (a1)
        cbo.inval (a1)
        cbo.inval (a1)
        cbo.inval (a1)
        cbo.inval (a1)

        # step 4 All should be invalid
CBOMTest_clean_step4:
        la a0, DeadBeafData1
        la a1, Destination2
        li a2, 64
        jal ra, memcmp8
        sd a0, 0(s0)    # should be -1
        addi s0, s0, 8
        
        # step 5
CBOMTest_clean_step5:
        la a0, SourceData
        la a1, Destination2
        li a2, 64
        jal ra, memcpy8

        # step 6  only clean 1 line
CBOMTest_clean_step6:
        la a1, Destination2
        cbo.clean (a1)
	
        # step 7  only check that 1 line
CBOMTest_clean_step7:
        la a0, SourceData
        la a1, Destination2
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

        # step 8  invalidate that 1 line and the next
CBOMTest_clean_step8:
        la a1, Destination2
        cbo.inval (a1)
        la a1, Destination2+64
        cbo.inval (a1)
	
        # step 9  that 1 line should contain the valid data
CBOMTest_clean_step9_line1:
        la a0, SourceData
        la a1, Destination2
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

        # step 9 the next should contain the invalid data
CBOMTest_clean_step9_line2:
        la a0, DeadBeafData1
        la a1, Destination2+64
        li a2, 8
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

        # step 5 # now recopy the one we just corrupted
CBOMTest_clean_step5_recopy_line2:
        la a0, SourceData+64
        la a1, Destination2+64
        li a2, 8
        jal ra, memcpy8

        # step 6 # clean the remaining
CBOMTest_clean_step6_clean_all:
        la a1, Destination2+64
        cbo.clean (a1)
        la a1, Destination2+128
        cbo.clean (a1)
        la a1, Destination2+192
        cbo.clean (a1)
        la a1, Destination2+256
        cbo.clean (a1)
        la a1, Destination2+320
        cbo.clean (a1)
        la a1, Destination2+384
        cbo.clean (a1)
        la a1, Destination2+448
        cbo.clean (a1)
        cbo.clean (a1)
        cbo.clean (a1)
        cbo.clean (a1)
        cbo.clean (a1)
        cbo.clean (a1)
        cbo.clean (a1)
        cbo.clean (a1)
        cbo.clean (a1)
	
        # step 8 # invalidate all remaining
CBOMTest_clean_step7_invalidate_all:
        la a1, Destination2
        cbo.inval (a1)
        la a1, Destination2+64
        cbo.inval (a1)
        la a1, Destination2+128
        cbo.inval (a1)
        la a1, Destination2+192
        cbo.inval (a1)
        la a1, Destination2+256
        cbo.inval (a1)
        la a1, Destination2+320
        cbo.inval (a1)
        la a1, Destination2+384
        cbo.inval (a1)
        la a1, Destination2+448
        cbo.inval (a1)
	
        # step 9 # check all
CBOMTest_clean_step9_check_all:
        la a0, SourceData
        la a1, Destination2
        li a2, 64
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

        ################################################################################
        # Flush D$ line
        ################################################################################

        # theory of operation
        # 1. Read several cachelines of data from memory into the d cache and copy to a second region of memory
        # 2. Then verify the second region has the same data
        # 3. For flush there is no way to create a negative control. We will flush 1 cache line
        # 4. Verify whole region
        # 5. Flush the remaining lines
        # 6. Verify whole region

        # step 1
CBOMTest_flush_step1: 
        la a0, SourceData
        la a1, Destination3
        li a2, 64
        jal ra, memcpy8

        # step 2 All should be valid
CBOMTest_flush_step2_verify:
        la a0, SourceData
        la a1, Destination3
        li a2, 64
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

        # step 3 # flush 1 line
CBOMTest_flush_step3:
        la a1, Destination3
        cbo.flush (a1)

        # step 4 
CBOMTest_flush_step4_verify:
        la a0, SourceData
        la a1, Destination3
        li a2, 64
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8

        # step 5
CBOMTest_flush_step5_flush_all:
        la a1, Destination3
        cbo.flush (a1)
        la a1, Destination3+64
        cbo.flush (a1)
        la a1, Destination3+128
        cbo.flush (a1)
        la a1, Destination3+192
        cbo.flush (a1)
        la a1, Destination3+256
        cbo.flush (a1)
        la a1, Destination3+320
        cbo.flush (a1)
        la a1, Destination3+384
        cbo.flush (a1)
        la a1, Destination3+448
        cbo.flush (a1)
        cbo.flush (a1)
        cbo.flush (a1)
        cbo.flush (a1)
        cbo.flush (a1)
        cbo.flush (a1)
	
        # step 6
CBOMTest_flush_step6_verify:
        la a0, SourceData
        la a1, Destination3
        li a2, 64
        jal ra, memcmp8
        sd a0, 0(s0)     # should be -1
        addi s0, s0, 8
        

        #ld s0, 0(sp)
        #ld ra, 8(sp)
        #addi sp, sp, 16
        #ret
RVMODEL_HALT

	
.type memcpy8, @function
memcpy8:        
        # a0 is the source
        # a1 is the dst
        # a2 is the number of 8 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0
memcpy8_loop:   
        ld t3, 0(t0)
        sd t3, 0(t1)
        addi t0, t0, 8
        addi t1, t1, 8
        addi t2, t2, 1
        blt t2, a2, memcpy8_loop
        ret

.type memcmp8, @function
# returns which index mismatch, -1 if none
memcmp8:        
        # a0 is the source1
        # a1 is the source2
        # a2 is the number of 8 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0
memcmp8_loop:
        ld t3, 0(t0)
        ld t4, 0(t1)
        bne t3, t4, memcmp8_ne
        addi t0, t0, 8
        addi t1, t1, 8
        addi t2, t2, 1
        blt t2, a2, memcmp8_loop
        li a0, -1
        ret
memcmp8_ne:
        mv a0, t2
        ret

RVTEST_CODE_END
        

RVTEST_DATA_BEGIN
# Input data section.
#.data
.align 7

DeadBeafData1:
        .fill 128, 4, 0xdeadbeef
SourceData:
        .int 0, 1, 2, 3, 4, 5, 6, 7
        .int 8, 9, 10, 11, 12, 13, 14, 15
        .int 16, 17, 18, 19, 20, 21, 22, 23
        .int 24, 25, 26, 27, 28, 29, 30, 31
        .int 32, 33, 34, 35, 36, 37, 38, 39
        .int 40, 41, 42, 43, 44, 45, 46, 47
        .int 48, 49, 50, 51, 52, 53, 54, 55
        .int 56, 57, 58, 59, 60, 61, 62, 63
        .int 64, 65, 66, 67, 68, 69, 70, 71
        .int 72, 73, 74, 75, 76, 77, 78, 79
        .int 80, 81, 82, 83, 84, 85, 86, 87
        .int 88, 89, 90, 91, 92, 93, 94, 95
        .int 96, 97, 98, 99, 100, 101, 102, 103
        .int 104, 105, 106, 107, 108, 109, 110, 111
        .int 112, 113, 114, 115, 116, 117, 118, 119
        .int 120, 121, 122, 123, 124, 125, 126, 127

RVTEST_DATA_END

RVMODEL_DATA_BEGIN
        .fill 28, 4, 0xdeadbeef   # this is annoying, but RVMODEL_DATA_END and BEGIN insert
        # 4 bytes.  This needs to be aligned to a cacheline

        .align 6
Destination1:
        .fill 128, 4, 0xdeadbeef
Destination2:   
        .fill 128, 4, 0xdeadbeef
Destination3:
        .fill 128, 4, 0xdeadbeef
signature:
        .fill 44, 4, 0x0bad0bad
sig_end_canary:
.int 0x0
rvtest_sig_end:
	
RVMODEL_DATA_END

