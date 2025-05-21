///////////////////////////////////////////
//
// WALLY-cache-management-tests 
// invalidate, clean, and flush
//
// Author: Rose Thompson <rose@rosethompson.net>
//
// Created 22 August 2023
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
# Purpose: Tests the Zicboz cache instruction which all operate on cacheline
#          granularity blocks of memory.  The instruction cbo.zero allocates a cacheline
#          and writes 0 to each byte.  A dirty cacheline is overwritten, any data in main
#          memory is over written.        
# -----------
# Copyright (c) 2020. RISC-V International. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
# -----------
#
# This assembly file tests the cbo.zero instruction of the RISC-V Zicboz extension.
# 

#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV32I_Zicboz_Zicbom")
# Test code region
.section .text.init
.globl rvtest_entry_point
	
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",cbo.zero)

RVMODEL_IO_WRITE_STR(x31, "# Test Begin\n")
	
CBOZTest:
        # *** TODO
        # first need to discover the length of the cacheline.
        # for now assume it is 64 bytes

        #addi sp, sp, -16
        #sd s0, 0(sp)
        #sd ra, 8(sp)

	la s0, signature

        ################################################################################
        # Zero cache line hit overwrites
        ################################################################################

        # theory of operation
        # 1. Read several cachelines of data from memory into the d cache and copy to a second region of memory
        # 2. Then verify the second region has the same data
        # 3. Zero that region of memory
        # 4. Verify the second region is all zero.

        # step 1
CBOZTest_zero_step1: 
        la a0, SourceData
        la a1, Destination1
        li a2, 128
        jal ra, memcpy4

        # step 2
CBOZTest_zero_step2: 
        la a0, SourceData
        la a1, Destination1
        li a2, 128
        jal ra, memcmp4
        sw a0, 0(s0)     # should be -1
        addi s0, s0, 4

        # step 3
CBOZTest_zero_step3: 
        la a1, Destination1
        cbo.zero (a1)
        la a1, Destination1+64
        cbo.zero (a1)
        la a1, Destination1+128
        cbo.zero (a1)
        la a1, Destination1+192
        cbo.zero (a1)
        la a1, Destination1+256
        cbo.zero (a1)
        la a1, Destination1+320
        cbo.zero (a1)
        la a1, Destination1+384
        cbo.zero (a1)
        la a1, Destination1+448
        cbo.zero (a1)

CBOZTest_zero_step4:    
        # step 4  (should be zero)
        la a0, ZeroData
        la a1, Destination1
        li a2, 128
        jal ra, memcmp4
        sw a0, 0(s0)    # should be -1
        addi s0, s0, 4

        ################################################################################
        # Verify cbo.zero miss overwrites
        ################################################################################

        # theory of operation
        # 1. Read 1 cacheline of data from memory into the d cache and copy to a second region of memory
        # 2. Then verify the second region has the same data
        # 3. Flush that one line
        # 4. Zero that one line
        # 5. Verify the second region is zero

        # step 1
CBOZTest_miss_zero_step1: 
        la a0, SourceData
        la a1, Destination1
        li a2, 16
        jal ra, memcpy4

        # step 2
CBOZTest_miss_zero_step2: 
        la a0, SourceData
        la a1, Destination1
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)     # should be -1
        addi s0, s0, 4

        # step 3
CBOZTest_miss_zero_step3: 
        la a1, Destination1
        cbo.flush (a1)
        cbo.zero (a1)

CBOZTest_miss_zero_step4:    
        # step 4  (should be Invalid)
        la a0, ZeroData
        la a1, Destination1
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)    # should be -1
        addi s0, s0, 4
	
        ################################################################################
        # Verify cbo.zero miss with eviction overwrites
        ################################################################################

        # theory of operation
        # 1. Read 1 cacheline of data from memory into the d cache and copy to a second region of memory
        # 2. Repeate 1 four times at 4KiB intervals
        # 2. Then verify the second region has the same data
        # 4. Zero each line
        # 5. Verify the second region is zero

        # step 1
CBOZTest_eviction_zero_step1_0: 
        la a0, SourceData
        la a1, Destination2
        li a2, 16
        jal ra, memcpy4

CBOZTest_eviction_zero_step2_4096: 
        la a0, SourceData+8
        la a1, Destination2+4096
        li a2, 16
        jal ra, memcpy4

CBOZTest_eviction_zero_step2_8192: 
        la a0, SourceData+16
        la a1, Destination2+8192
        li a2, 16
        jal ra, memcpy4

CBOZTest_eviction_zero_step2_12288: 
        la a0, SourceData+24
        la a1, Destination2+12288
        li a2, 16
        jal ra, memcpy4

CBOZTest_eviction_zero_step2_16384: 
        la a0, SourceData+32
        la a1, Destination2+16384
        li a2, 16
        jal ra, memcpy4

        # step 3
CBOZTest_eviction_zero_step3_0: 
        la a0, SourceData
        la a1, Destination2
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)     # should be -1
        addi s0, s0, 4

CBOZTest_eviction_zero_step3_4096: 
        la a0, SourceData+8
        la a1, Destination2+4096
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)     # should be -1
        addi s0, s0, 4

CBOZTest_eviction_zero_step3_8192: 
        la a0, SourceData+16
        la a1, Destination2+8192
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)     # should be -1
        addi s0, s0, 4
        
CBOZTest_eviction_zero_step3_12288: 
        la a0, SourceData+24
        la a1, Destination2+12288
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)     # should be -1
        addi s0, s0, 4
        
CBOZTest_eviction_zero_step3_16384: 
        la a0, SourceData+32
        la a1, Destination2+16384
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)     # should be -1
        addi s0, s0, 4

        # step 4
CBOZTest_eviction_zero_step4: 
        la a1, Destination2
        cbo.zero (a1)
        la a1, Destination2+4096
        cbo.zero (a1)
        la a1, Destination2+8192
        cbo.zero (a1)
        la a1, Destination2+12288
        cbo.zero (a1)
        la a1, Destination2+16384
        cbo.zero (a1)

CBOZTest_eviction_zero_step5_0:
        # step 5  (should be zero)
        la a0, ZeroData
        la a1, Destination2
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)    # should be -1
        addi s0, s0, 4

CBOZTest_eviction_zero_step5_4096:
        # step 5  (should be zero)
        la a0, ZeroData
        la a1, Destination2+4096
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)    # should be -1
        addi s0, s0, 4
        
CBOZTest_eviction_zero_step5_8192:
        # step 5  (should be zero)
        la a0, ZeroData
        la a1, Destination2+8192
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)    # should be -1
        addi s0, s0, 4

CBOZTest_eviction_zero_step5_12288:
        # step 5  (should be zero)
        la a0, ZeroData
        la a1, Destination2+12288
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)    # should be -1
        addi s0, s0, 4
        
CBOZTest_eviction_zero_step5_16384:
        # step 5  (should be zero)
        la a0, ZeroData
        la a1, Destination2+16384
        li a2, 16
        jal ra, memcmp4
        sw a0, 0(s0)    # should be -1
        addi s0, s0, 4
	

        #ld s0, 0(sp)
        #ld ra, 8(sp)
        #addi sp, sp, 16
        #ret
RVMODEL_HALT

	
.type memcpy4, @function
memcpy4:        
        # a0 is the source
        # a1 is the dst
        # a2 is the number of 4 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0
memcpy4_loop:   
        lw t3, 0(t0)
        sw t3, 0(t1)
        addi t0, t0, 4
        addi t1, t1, 4
        addi t2, t2, 1
        blt t2, a2, memcpy4_loop
        ret

.type memcmp4, @function
# returns which index mismatch, -1 if none
memcmp4:
        # a0 is the source1
        # a1 is the source2
        # a2 is the number of 4 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0
memcmp4_loop:
        lw t3, 0(t0)
        lw t4, 0(t1)
        bne t3, t4, memcmp4_ne
        addi t0, t0, 4
        addi t1, t1, 4
        addi t2, t2, 1
        blt t2, a2, memcmp4_loop
        li a0, -1
        ret
memcmp4_ne:
        mv a0, t2
        ret

RVTEST_CODE_END
        

RVTEST_DATA_BEGIN
# Input data section.
#.data
.align 7

ZeroData:
        .fill 128, 4, 0x0
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
        .fill 16, 4, 0xdeadbeef
signature:
        .fill 16, 4, 0x0bad0bad
sig_end_canary:
.int 0x0
rvtest_sig_end:
RVMODEL_DATA_END

