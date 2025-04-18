
    addi    a3, a2, 16*10                       // kp = rk + 4*nr

    AES_LOAD_STATE a4,a5,a6,a7,a1,t0,t1,t2,t3   // Columns in T*

    lw      t0,  0(a2)                          // Load Round Key
    lw      t1,  4(a2)
    lw      t2,  8(a2)
    lw      t3, 12(a2)

    xor     a4, a4, t0                          // Add Round Key
    xor     a5, a5, t1
    xor     a6, a6, t2
    xor     a7, a7, t3

.aes_enc_block_l0:
    
        lw      t0, 16(a2)                      // Load Round Key
        lw      t1, 20(a2)
        lw      t2, 24(a2)
        lw      t3, 28(a2)

        aes32esmi   t0, t0, a4, 0                   // Even Round
        aes32esmi   t0, t0, a5, 1
        aes32esmi   t0, t0, a6, 2
        aes32esmi   t0, t0, a7, 3
                                 
        aes32esmi   t1, t1, a5, 0
        aes32esmi   t1, t1, a6, 1
        aes32esmi   t1, t1, a7, 2
        aes32esmi   t1, t1, a4, 3
                                 
        aes32esmi   t2, t2, a6, 0
        aes32esmi   t2, t2, a7, 1
        aes32esmi   t2, t2, a4, 2
        aes32esmi   t2, t2, a5, 3
                                 
        aes32esmi   t3, t3, a7, 0
        aes32esmi   t3, t3, a4, 1
        aes32esmi   t3, t3, a5, 2
        aes32esmi   t3, t3, a6, 3                   // U* contains new state

        lw      a4, 32(a2)                      // Load Round Key
        lw      a5, 36(a2)
        lw      a6, 40(a2)
        lw      a7, 44(a2)

        addi    a2, a2, 32                      // Step Key pointer
        beq     a2, a3, .aes_enc_block_l_finish // Break from loop
        
        aes32esmi   a4, a4, t0, 0                   // Odd Round
        aes32esmi   a4, a4, t1, 1
        aes32esmi   a4, a4, t2, 2
        aes32esmi   a4, a4, t3, 3
                                 
        aes32esmi   a5, a5, t1, 0
        aes32esmi   a5, a5, t2, 1
        aes32esmi   a5, a5, t3, 2
        aes32esmi   a5, a5, t0, 3
                                 
        aes32esmi   a6, a6, t2, 0
        aes32esmi   a6, a6, t3, 1
        aes32esmi   a6, a6, t0, 2
        aes32esmi   a6, a6, t1, 3
                                 
        aes32esmi   a7, a7, t3, 0
        aes32esmi   a7, a7, t0, 1
        aes32esmi   a7, a7, t1, 2
        aes32esmi   a7, a7, t2, 3                   // T* contains new state

    j .aes_enc_block_l0                         // repeat loop

.aes_enc_block_l_finish:
    
    aes32esi    a4, a4, t0, 0                       // Final round. No MixColumn.
    aes32esi    a4, a4, t1, 1
    aes32esi    a4, a4, t2, 2
    aes32esi    a4, a4, t3, 3
                             
    aes32esi    a5, a5, t1, 0
    aes32esi    a5, a5, t2, 1
    aes32esi    a5, a5, t3, 2
    aes32esi    a5, a5, t0, 3
                             
    aes32esi    a6, a6, t2, 0
    aes32esi    a6, a6, t3, 1
    aes32esi    a6, a6, t0, 2
    aes32esi    a6, a6, t1, 3
                             
    aes32esi    a7, a7, t3, 0
    aes32esi    a7, a7, t0, 1
    aes32esi    a7, a7, t1, 2
    aes32esi    a7, a7, t2, 3                       // T* contains new state

    AES_DUMP_STATE  a4, a5, a6, a7, a0
