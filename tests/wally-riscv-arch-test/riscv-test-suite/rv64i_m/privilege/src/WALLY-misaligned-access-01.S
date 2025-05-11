///////////////////////////////////////////
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLT.S
// David_Harris@hmc.edu & Katherine Parry
// Created 2022-06-17 22:58:09.916813//
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

#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV64I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*);def TEST_CASE_1=True;",ld)

        # This test checks the misaligned load and stores work correctly and across D$ line spills.
        # The general approach is to
        # 1. load a region of memory using load doubles equal to two cache lines.  And copy to a new
        #    region but using stores of bytes, half, word, or doubles.  Each are repeated for all possible
        #    misaligned access. Bytes are always aligned, halves are 0, and 1, words are 0, 1, 2, and 3, and
        #    doubles are 0 through 7.  Then the new region is compared against the reference region.  Because
        #    of the misalignment the last few bytes will not be written so they will be some portion of deadbeef.
        #    The comparison is done using using same abyte, half, word, and double misaligned approach.

        la a3, signature  # does not get overwritten by any functions

TEST_BYTE:      
        # byte copy region. always naturally aligned
        la a0, SourceData
        la a1, ByteDstData
        li a2, 16
        jal ra, memcpy8_1
	
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, ByteDstData
        li a2, 16
        jal ra, CheckAllWriteSignature
        
TEST_HALF0:
        la a0, SourceData
        la a1, Half0DstData
        li a2, 16
        jal ra, memcpy8_2
	
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Half0DstData
        li a2, 16
        jal ra, CheckAllWriteSignature

TEST_HALF1:
        la a0, SourceData
        la a1, Half1DstData+1
        li a2, 16
        jal ra, memcpy8_2
        
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Half1DstData+1
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_WORD0:
        la a0, SourceData
        la a1, Word0DstData
        li a2, 16
        jal ra, memcpy8_4

        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Word0DstData
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_WORD1:
        la a0, SourceData
        la a1, Word1DstData+1
        li a2, 16
        jal ra, memcpy8_4
	
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Word1DstData+1
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_WORD2:
        la a0, SourceData
        la a1, Word2DstData+2
        li a2, 16
        jal ra, memcpy8_4
	
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Word2DstData+2
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_WORD3:
        la a0, SourceData
        la a1, Word3DstData+3
        li a2, 16
        jal ra, memcpy8_4

        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Word3DstData+3
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_DOUBLE0:
        la a0, SourceData
        la a1, Double0DstData
        li a2, 16
        jal ra, memcpy8_8
        
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Double0DstData
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_DOUBLE1:
        la a0, SourceData
        la a1, Double1DstData+1
        li a2, 16
        jal ra, memcpy8_8
	
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Double1DstData+1
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_DOUBLE2:
        la a0, SourceData
        la a1, Double2DstData+2
        li a2, 16
        jal ra, memcpy8_8

        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Double2DstData+2
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_DOUBLE3:
        la a0, SourceData
        la a1, Double3DstData+3
        li a2, 16
        jal ra, memcpy8_8

        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Double3DstData+3
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_DOUBLE4:
        la a0, SourceData
        la a1, Double4DstData+4
        li a2, 16
        jal ra, memcpy8_8
        
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Double4DstData+4
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_DOUBLE5:
        la a0, SourceData
        la a1, Double5DstData+5
        li a2, 16
        jal ra, memcpy8_8
        
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Double5DstData+5
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_DOUBLE6:
        la a0, SourceData
        la a1, Double6DstData+6
        li a2, 16
        jal ra, memcpy8_8
	
        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Double6DstData+6
        li a2, 16
        jal ra, CheckAllWriteSignature
	
TEST_DOUBLE7:
        la a0, SourceData
        la a1, Double7DstData+7
        li a2, 16
        jal ra, memcpy8_8

        # check if the values are write for all sizes and offsets of misaligned loads.
        la a0, SourceData
        la a1, Double7DstData+7
        li a2, 16
        jal ra, CheckAllWriteSignature
	
RVMODEL_HALT
	
.type CheckAll, @function
# a0 is the SourceData, (golden), a1 is the data to be checked.
# a2 is the number of doubles
# a3 is the signature pointer
# returns a0 as 0 for no mismatch, 1 for mismatch,
# returns a3 as incremented signature pointer
CheckAllWriteSignature:       
        mv s0, a0
        mv s1, a1
        mv s2, a2
        mv s3, a3
        # there is no stack so I'm saving ra into s5
        mv s5, ra

        # check values byte by byte
        mv a0, s0  # SourceData
        mv a1, s1  # ie: ByteDstData
        slli a2, s2, 3  # * 8
        jal ra, memcmp1
        sb a0, 0(s3)
        mv s4, a0

        # check values half by half
        mv a0, s0  # SourceData
        mv a1, s1  # ie: ByteDstData
        slli a2, s2, 2  # * 4
        jal ra, memcmp2
        sb a0, 1(s3)
        or s4, s4, a0

        # check values half by half
        addi a0, s0, 1  # SourceData+1
        addi a1, s1, 1  # ie: ByteDstData+1
        slli a2, s2, 2  # * 4 -1
        addi a2, a2, -1
        jal ra, memcmp2
        sb a0, 2(s3)
        or s4, s4, a0
        
        # check values word by word
        addi a0, s0, 0  # SourceData
        mv a1, s1  # ie: ByteDstData
        slli a2, s2, 1  # * 2
        jal ra, memcmp4
        sb a0, 3(s3)
        or s4, s4, a0

        # check values word by word
        addi a0, s0, 1  # SourceData+1
        addi a1, s1, 1  # ie: ByteDstData+1
        slli a2, s2, 1  # * 2 -1
        addi a2, a2, -1
        jal ra, memcmp4
        sb a0, 4(s3)
        or s4, s4, a0

        # check values word by word
        addi a0, s0, 2  # SourceData+2
        addi a1, s1, 2  # ie: ByteDstData+2
        slli a2, s2, 1  # * 2 -1
        addi a2, a2, -1
        jal ra, memcmp4
        sb a0, 5(s3)
        or s4, s4, a0
        
        # check values word by word
        addi a0, s0, 3  # SourceData+3
        addi a1, s1, 3  # ie: ByteDstData+3
        slli a2, s2, 1  # * 2 -1
        addi a2, a2, -1
        jal ra, memcmp4
        sb a0, 6(s3)
        or s4, s4, a0
	
        # check values double by double
        mv a0, s0  # SourceData
        mv a1, s1  # ie: ByteDstData
        slli a2, s2, 0  # * 1
        jal ra, memcmp8
        sb a0, 7(s3)

        # check values double by double
        addi a0, s0, 1  # SourceData+1
        addi a1, s1, 1  # ie: ByteDstData+1
        slli a2, s2, 0  # * 1 -1
        addi a2, a2, -1
        jal ra, memcmp8
        sb a0, 8(s3)

        # check values double by double
        addi a0, s0, 2  # SourceData+2
        addi a1, s1, 2  # ie: ByteDstData+2
        slli a2, s2, 0  # * 1 -1
        addi a2, a2, -1
        jal ra, memcmp8
        sb a0, 9(s3)
        
        # check values double by double
        addi a0, s0, 3  # SourceData+3
        addi a1, s1, 3  # ie: ByteDstData+3
        slli a2, s2, 0  # * 1 -1
        addi a2, a2, -1
        jal ra, memcmp8
        sb a0, 10(s3)
	
        # check values double by double
        addi a0, s0, 4  # SourceData+4
        addi a1, s1, 4  # ie: ByteDstData+4
        slli a2, s2, 0  # * 1 -1
        addi a2, a2, -1
        jal ra, memcmp8
        sb a0, 11(s3)

        # check values double by double
        addi a0, s0, 5  # SourceData+5
        addi a1, s1, 5  # ie: ByteDstData+5
        slli a2, s2, 0  # * 1 -1
        addi a2, a2, -1
        jal ra, memcmp8
        sb a0, 12(s3)
	
        # check values double by double
        addi a0, s0, 6  # SourceData+6
        addi a1, s1, 6  # ie: ByteDstData+6
        slli a2, s2, 0  # * 1 -1
        addi a2, a2, -1
        jal ra, memcmp8
        sb a0, 13(s3)
	
        # check values double by double
        addi a0, s0, 7  # SourceData+7
        addi a1, s1, 7  # ie: ByteDstData+7
        slli a2, s2, 0  # * 1
        addi a2, a2, -1
        jal ra, memcmp8
        sb a0, 14(s3)
	
        addi s3, s3, 15
        mv a3, s3
        or a0, s4, a0
        mv ra, s5
        ret


.type memcmp1, @function
# returns which index mismatch, -1 if none
memcmp1:        
        # a0 is the source1
        # a1 is the source2
        # a2 is the number of 1 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0
memcmp1_loop:
        lbu t3, 0(t0)
        lbu t4, 0(t1)
        bne t3, t4, memcmp1_ne
        addi t0, t0, 1
        addi t1, t1, 1
        addi t2, t2, 1
        blt t2, a2, memcmp1_loop
        li a0, -1
        ret
memcmp1_ne:
        mv a0, t2
        ret
	
.type memcmp2, @function
# returns which index mismatch, -1 if none
memcmp2:        
        # a0 is the source1
        # a1 is the source2
        # a2 is the number of 2 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0
memcmp2_loop:
        lhu t3, 0(t0)
        lhu t4, 0(t1)
        bne t3, t4, memcmp2_ne
        addi t0, t0, 2
        addi t1, t1, 2
        addi t2, t2, 1
        blt t2, a2, memcmp2_loop
        li a0, -1
        ret
memcmp2_ne:
        mv a0, t2
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
        lwu t3, 0(t0)
        lwu t4, 0(t1)
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

.type memcpy8_1, @function
# load 8 bytes using load double then store using 8 sb
memcpy8_1:        
        # a0 is the source
        # a1 is the dst
        # a2 is the number of 8 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0
memcpy8_1_loop:   
        ld t3, 0(t0)
        andi t4, t3, 0xff
        sb t4, 0(t1)
        srli t4, t3, 8
        andi t4, t4, 0xff
        sb t4, 1(t1)
	
        srli t4, t3, 16
        andi t4, t4, 0xff
        sb t4, 2(t1)

        srli t4, t3, 24
        andi t4, t4, 0xff
        sb t4, 3(t1)
        
        srli t4, t3, 32
        andi t4, t4, 0xff
        sb t4, 4(t1)
	
        srli t4, t3, 40
        andi t4, t4, 0xff
        sb t4, 5(t1)
	
        srli t4, t3, 48
        andi t4, t4, 0xff
        sb t4, 6(t1)
	
        srli t4, t3, 56
        andi t4, t4, 0xff
        sb t4, 7(t1)
	
        addi t0, t0, 8
        addi t1, t1, 8
        addi t2, t2, 1
        blt t2, a2, memcpy8_1_loop
        ret
	
.type memcpy8_2, @function
# load 8 bytes using load double then store using 4 sh
memcpy8_2:
        # a0 is the source
        # a1 is the dst
        # a2 is the number of 8 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0

        # 16 bit mask
        lui t4, 0xf
        li t3, 0xfff
        or t5, t4, t3

memcpy8_2_loop:   
        ld t3, 0(t0)
        and t4, t3, t5
        sh t4, 0(t1)

        srli t4, t3, 16
        and t4, t4, t5
        sh t4, 2(t1)
	
        srli t4, t3, 32
        and t4, t4, t5
        sh t4, 4(t1)

        srli t4, t3, 48
        and t4, t4, t5
        sh t4, 6(t1)
        
	
        addi t0, t0, 8
        addi t1, t1, 8
        addi t2, t2, 1
        blt t2, a2, memcpy8_2_loop
        ret

.type memcpy8_4, @function
# load 8 bytes using load double then store using 2 sw
memcpy8_4:
        # a0 is the source
        # a1 is the dst
        # a2 is the number of 8 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0

        # 32 bit mask
        addi t4, x0, -1
        srli t5, t4, 32

memcpy8_4_loop:   
        ld t3, 0(t0)
        and t4, t3, t5
        sw t4, 0(t1)

        srli t4, t3, 32
        and t4, t4, t5
        sw t4, 4(t1)
	
        addi t0, t0, 8
        addi t1, t1, 8
        addi t2, t2, 1
        blt t2, a2, memcpy8_4_loop
        ret

.type memcpy8_8, @function
# load 8 bytes using load double then store using 1 sd
memcpy8_8:
        # a0 is the source
        # a1 is the dst
        # a2 is the number of 8 byte words
        mv t0, a0
        mv t1, a1
        li t2, 0

memcpy8_8_loop:   
        ld t3, 0(t0)
        sd t3, 0(t1)
	
        addi t0, t0, 8
        addi t1, t1, 8
        addi t2, t2, 1
        blt t2, a2, memcpy8_8_loop
        ret
        

RVTEST_DATA_BEGIN
.align 3
rvtest_data:
SourceData:     
.8byte 0x0706050403020100, 0x0f0e0d0c0b0a0908, 0x1716151413021110, 0x1f1e1d1c1b1a1918
.8byte 0x2726252423222120, 0x2f2e2d2c2b2a2928, 0x3736353433023130, 0x3f3e3d3c3b3a3938
.8byte 0x4746454443424140, 0x4f4e4d4c4b4a4948, 0x5756555453025150, 0x5f5e5d5c5b5a5958
.8byte 0x6766656463626160, 0x6f6e6d6c6b6a6968, 0x7776757473027170, 0x7f7e7d7c7b7a7978
.8byte 0xdeadbeefdeadbeef

Response1ByteOffsetData:     
.8byte 0x0807060504030201, 0x100f0e0d0c0b0a09, 0x1817161514130211, 0x201f1e1d1c1b1a19
.8byte 0x2827262524232221, 0x302f2e2d2c2b2a29, 0x3837363534330231, 0x403f3e3d3c3b3a39
.8byte 0x4847464544434241, 0x504f4e4d4c4b4a49, 0x5857565554530251, 0x605f5e5d5c5b5a59
.8byte 0x6867666564636261, 0x706f6e6d6c6b6a69, 0x7877767574730271, 0xde7f7e7d7c7b7a79

Response2ByteOffsetData:     
.8byte 0x0908070605040302, 0x11100f0e0d0c0b0a, 0x1918171615141302, 0x21201f1e1d1c1b1a
.8byte 0x2928272625242322, 0x31302f2e2d2c2b2a, 0x3938373635343302, 0x41403f3e3d3c3b3a
.8byte 0x4948474645444342, 0x51504f4e4d4c4b4a, 0x5958575655545302, 0x61605f5e5d5c5b5a
.8byte 0x6968676665646362, 0x71706f6e6d6c6b6a, 0x7978777675747302, 0xdead7f7e7d7c7b7a

Response3ByteOffsetData:     
.8byte 0x0a09080706050403, 0x0211100f0e0d0c0b, 0x1a19181716151413, 0x2221201f1e1d1c1b
.8byte 0x2a29282726252423, 0x0231302f2e2d2c2b, 0x3a39383736353433, 0x4241403f3e3d3c3b
.8byte 0x4a49484746454443, 0x0251504f4e4d4c4b, 0x5a59585756555453, 0x6261605f5e5d5c5b
.8byte 0x6a69686766656463, 0x0271706f6e6d6c6b, 0x7a79787776757473, 0xdeadbe7f7e7d7c7b

Response4ByteOffsetData:     
.8byte 0x0b0a090807060504, 0x130211100f0e0d0c, 0x1b1a191817161514, 0x232221201f1e1d1c
.8byte 0x2b2a292827262524, 0x330231302f2e2d2c, 0x3b3a393837363534, 0x434241403f3e3d3c
.8byte 0x4b4a494847464544, 0x530251504f4e4d4c, 0x5b5a595857565554, 0x636261605f5e5d5c
.8byte 0x6b6a696867666564, 0x730271706f6e6d6c, 0x7b7a797877767574, 0xdeadbeef7f7e7d7c
        
Response5ByteOffsetData:     
.8byte 0x0c0b0a0908070605, 0x14130211100f0e0d, 0x1c1b1a1918171615, 0x24232221201f1e1d
.8byte 0x2c2b2a2928272625, 0x34330231302f2e2d, 0x3c3b3a3938373635, 0x44434241403f3e3d
.8byte 0x4c4b4a4948474645, 0x54530251504f4e4d, 0x5c5b5a5958575655, 0x64636261605f5e5d
.8byte 0x6c6b6a6968676665, 0x74730271706f6e6d, 0x7c7b7a7978777675, 0xdeadbeefde7f7e7d

Response6ByteOffsetData:     
.8byte 0x0d0c0b0a09080706, 0x1514130211100f0e, 0x1d1c1b1a19181716, 0x2524232221201f1e
.8byte 0x2d2c2b2a29282726, 0x3534330231302f2e, 0x3d3c3b3a39383736, 0x4544434241403f3e
.8byte 0x4d4c4b4a49484746, 0x5554530251504f4e, 0x5d5c5b5a59585756, 0x6564636261605f5e
.8byte 0x6d6c6b6a69686766, 0x7574730271706f6e, 0x7d7c7b7a79787776, 0xdeadbeefdead7f7e

Response7ByteOffsetData:     
.8byte 0x0e0d0c0b0a090807, 0x161514130211100f, 0x1e1d1c1b1a191817, 0x262524232221201f
.8byte 0x2e2d2c2b2a292827, 0x363534330231302f, 0x3e3d3c3b3a393837, 0x464544434241403f
.8byte 0x4e4d4c4b4a494847, 0x565554530251504f, 0x5e5d5c5b5a595857, 0x666564636261605f
.8byte 0x6e6d6c6b6a696867, 0x767574730271706f, 0x7e7d7c7b7a797877, 0xdeadbeefdeadbe7f
        
RVTEST_DATA_END

RVMODEL_DATA_BEGIN

ByteDstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef

Half0DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
	
Half1DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef
Word0DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef

Word1DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef
Word2DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef	
Word3DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef	
Double0DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef

Double1DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef	
Double2DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef	
Double3DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef	
Double4DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef	
Double5DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef	
Double6DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef	
Double7DstData:    
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef, 0xdeadbeefdeadbeef
.8byte 0xdeadbeefdeadbeef
signature:
        .fill 225, 1, 0x00
	
sig_end_canary:
.int 0x0
rvtest_sig_end:
RVMODEL_DATA_END
// ../wally-riscv-arch-test/riscv-test-suite/rv64i_m/I/src/WALLY-SLT.S
// David_Harris@hmc.edu & Katherine Parry
