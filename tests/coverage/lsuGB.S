//lsuGB.S 
// A set of tests meant to stress the LSU to increase coverage
// Manuel Alejandro Mendoza Manriquez mmendozamanriquez@g.hmc.edu
// Noah Limpert nlimpert@g.hmc.edu
// March 28 2023


// Test 2
//Try to thrash ! used godbolt!
// Cache ways 1,2,3 do not have SelFlush = 0
// To make SelFlush = 0 we must evict lines from ways 1,2,3
// Will load 4 words with same tags, filling 4 ways of cache
// edit and store these words so that dirty bit is set ( is this necessary?)
// Will then load 4 more words, evicting the previous 4 words 
// will make SelFlush = 0 for all 4 ways. 

// Load code to initialize stack, handle interrupts, terminate 
#include "WALLY-init-lib.h"

main:
        addi    sp,sp,-32
        sd      s0,24(sp)
        addi    s0,sp,32
        li      t1,-20480
        add     sp,sp,t1
        sw      zero,-20(s0)
        j       .L2
.L3:
        li      a5,-4096
        addi    a4,s0,-16
        add     a4,a4,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a4,a5
        lw      a4,-8(a5)
        li      a5,-8192
        addi    a3,s0,-16
        add     a3,a3,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a3,a5
        sw      a4,-8(a5)
        li      a5,-8192
        addi    a4,s0,-16
        add     a4,a4,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a4,a5
        lw      a4,-8(a5)
        li      a5,-12288
        addi    a3,s0,-16
        add     a3,a3,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a3,a5
        sw      a4,-8(a5)
        li      a5,-12288
        addi    a4,s0,-16
        add     a4,a4,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a4,a5
        lw      a4,-8(a5)
        li      a5,-16384
        addi    a3,s0,-16
        add     a3,a3,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a3,a5
        sw      a4,-8(a5)
        li      a5,-16384
        addi    a4,s0,-16
        add     a4,a4,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a4,a5
        lw      a4,-8(a5)
        li      a5,-20480
        addi    a3,s0,-16
        add     a3,a3,a5
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a3,a5
        sw      a4,-8(a5)
        lw      a5,-20(s0)
        addiw   a5,a5,1
        sw      a5,-20(s0)
.L2:
        lw      a5,-20(s0)
        sext.w  a4,a5
        li      a5,1023
        ble     a4,a5,.L3
        nop
        nop
        li      t1,20480
        add     sp,sp,t1
        ld      s0,24(sp)
        addi    sp,sp,32
        j       done