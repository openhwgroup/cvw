//lsu.S 
// A set of tests meant to stress the LSU to increase coverage
// Manuel Alejandro Mendoza Manriquez mmendozamanriquez@g.hmc.edu
// Noah Limpert nlimpert@g.hmc.edu
// March 28 2023


// Test 1
// Cache ways 1,2,3 do not have SelFlush = 0
// To make SelFlush = 0 we must evict lines from ways 1,2,3
// Will load 4 words with same tags, filling 4 ways of cache
// edit and store these words so that dirty bit is set ( is this necessary?)
// Will then load 4 more words, evicting the previous 4 words 
// will make SelFlush = 0 for all 4 ways. 

// Load code to initialize stack, handle interrupts, terminate 
#include "WALLY-init-lib.h"

main:
    li t0, 4096 //offset such that set will be same
    li t1, 0 #t1 = i = 0
    li t2, 8 # n = 8
    add t3, sp, 0 // what our offset for loads and stores will be

for1: bge t1, t2, done
    add t3, t3, t0
    lw t4, 0(t3)
    addi t4, t4, 1
    sw t4, 0(t3)
    addi t1, t1, 1
    j for1



