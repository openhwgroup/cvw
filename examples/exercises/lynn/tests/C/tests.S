// C Runtime entry point
// James Kaden Cassidy
// kacassidy@hmc.edu
// 12/21/2025

    .extern pass
    .extern fail

    .section .text
    .globl partial_load_test
    .type  partial_load_test, @function

partial_load_test:
    la t0, test_word

    lb   t1, 0(t0)
    li   t2, 0x01
    bne  t1, t2, fail

    lb   t1, 1(t0)
    li   t2, 0x7F
    bne  t1, t2, fail

    lb   t1, 2(t0)
    li   t2, -1          # 0xFFFFFFFF
    bne  t1, t2, fail

    lb   t1, 3(t0)
    li   t2, -128        # 0xFFFFFF80
    bne  t1, t2, fail

    j pass

    .section .data
    .balign 4              # 4-byte aligned for .word
    .globl test_word
test_word:
    .word 0x80FF7F01      # one word of data


/* RV32I partial load + partial store test (all sizes, all byte offsets)
 *
 * Idea referenced from your snippet: load from a known word pattern at each offset,
 * compare against the expected sign/zero-extended value, and branch to end on failure.
 *
 * Notes on “all alignments”:
 * - Bytes (LB/LBU/SB): offsets 0..7 are tested (covers every byte lane).
 * - Halfwords (LH/LHU/SH): *aligned* offsets 0,2,4,6 are tested by default.
 * - Words (LW/SW): *aligned* offsets 0,4 are tested by default.
 * - Misaligned half/word accesses are OPTIONAL (many RV32I cores trap). Enable by
 *   defining DO_MISALIGNED (see `.ifdef DO_MISALIGNED` blocks).
 */
/* Drop-in replacement: “numbered” checks that are obvious in objdump.
 *
 * Goal: when you only have the PC of the failing instruction, you can:
 *   1) look up the address in objdump,
 *   2) see a label like `fail_at_0042:` right above the branch/jump,
 *   3) immediately know which test ID failed.
 *
 * How it works:
 * - Each CHECK_* macro expands into a little block with a unique local label
 *   `fail_at_<id>:` that is only reached on failure.
 * - On failure, it loads gp with the ID (so tohost also tells you), then jumps to fail.
 *
 * Usage: replace your helper macros + main test body with this.
 * Requires: your `fail:` label exists and writes `gp` (or at least preserves it).
 */

    .section .text.init

/* ----------------- helper macros ----------------- */
    .macro FAIL_AT id
fail_at_\id:
        li   gp, \id
        j    fail
    .endm

    .macro CHECK_LB id, base, off, imm
        lb   t1, \off(\base)
        li   t2, \imm
        bne  t1, t2, fail_at_\id
    .endm

    .macro CHECK_LBU id, base, off, imm
        lbu  t1, \off(\base)
        li   t2, \imm
        bne  t1, t2, fail_at_\id
    .endm

    .macro CHECK_LH id, base, off, imm
        lh   t1, \off(\base)
        li   t2, \imm
        bne  t1, t2, fail_at_\id
    .endm

    .macro CHECK_LHU id, base, off, imm
        lhu  t1, \off(\base)
        li   t2, \imm
        bne  t1, t2, fail_at_\id
    .endm

    .macro CHECK_LW id, base, off, imm
        lw   t1, \off(\base)
        li   t2, \imm
        bne  t1, t2, fail_at_\id
    .endm

    .macro RESET_STORE_BUF
        la   t0, store_buf
        li   t1, 0xDEADBEEF
        sw   t1, 0(t0)
        li   t1, 0xCAFEBABE
        sw   t1, 4(t0)
    .endm

    /* Checks 8 bytes of store_buf; on mismatch, branches to fail_at_<id>. */
    .macro CHECK_STORE_BYTES id, b0,b1,b2,b3,b4,b5,b6,b7
        la   t0, store_buf
        lbu  t1, 0(t0); li t2, \b0; bne t1, t2, fail_at_\id
        lbu  t1, 1(t0); li t2, \b1; bne t1, t2, fail_at_\id
        lbu  t1, 2(t0); li t2, \b2; bne t1, t2, fail_at_\id
        lbu  t1, 3(t0); li t2, \b3; bne t1, t2, fail_at_\id
        lbu  t1, 4(t0); li t2, \b4; bne t1, t2, fail_at_\id
        lbu  t1, 5(t0); li t2, \b5; bne t1, t2, fail_at_\id
        lbu  t1, 6(t0); li t2, \b6; bne t1, t2, fail_at_\id
        lbu  t1, 7(t0); li t2, \b7; bne t1, t2, fail_at_\id
    .endm

    .section .text
    .globl partial_load_store_test

/* ----------------- main test ----------------- */
partial_load_store_test:
    la   t0, test_bytes

    /* ---- LB (sign extend), every byte offset 0..7 ---- */
    CHECK_LB   100, t0, 0,  1
    CHECK_LB   101, t0, 1,  127
    CHECK_LB   102, t0, 2, -1
    CHECK_LB   103, t0, 3, -128
    CHECK_LB   104, t0, 4,  18
    CHECK_LB   105, t0, 5,  52
    CHECK_LB   106, t0, 6,  86
    CHECK_LB   107, t0, 7,  120

    /* ---- LBU (zero extend), every byte offset 0..7 ---- */
    CHECK_LBU  110, t0, 0,  1
    CHECK_LBU  111, t0, 1,  127
    CHECK_LBU  112, t0, 2,  255
    CHECK_LBU  113, t0, 3,  128
    CHECK_LBU  114, t0, 4,  18
    CHECK_LBU  115, t0, 5,  52
    CHECK_LBU  116, t0, 6,  86
    CHECK_LBU  117, t0, 7,  120

    /* ---- LH/LHU aligned halfwords (0,2,4,6) ---- */
    CHECK_LH   120, t0, 0,  0x00007F01
    CHECK_LH   121, t0, 2,  0xFFFF80FF
    CHECK_LH   122, t0, 4,  0x00003412
    CHECK_LH   123, t0, 6,  0x00007856

    CHECK_LHU  130, t0, 0,  0x00007F01
    CHECK_LHU  131, t0, 2,  0x000080FF
    CHECK_LHU  132, t0, 4,  0x00003412
    CHECK_LHU  133, t0, 6,  0x00007856

    .ifdef DO_MISALIGNED
        CHECK_LH   124, t0, 1,  0xFFFFFF7F
        CHECK_LH   125, t0, 3,  0x00001280
        CHECK_LH   126, t0, 5,  0x00005634

        CHECK_LHU  134, t0, 1,  0x0000FF7F
        CHECK_LHU  135, t0, 3,  0x00001280
        CHECK_LHU  136, t0, 5,  0x00005634
    .endif

    /* ---- LW aligned words (0,4) ---- */
    CHECK_LW   140, t0, 0,  0x80FF7F01
    CHECK_LW   141, t0, 4,  0x78563412

    .ifdef DO_MISALIGNED
        CHECK_LW   142, t0, 1,  0x1280FF7F
        CHECK_LW   143, t0, 2,  0x341280FF
        CHECK_LW   144, t0, 3,  0x56341280
    .endif


    /* =========================
     * STORE TESTS (SB/SH/SW) with read-back via LBU
     * ========================= */

    /* ---- SB: offsets 0..7 ---- */
    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x01
    sb   t1, 0(t0)
    CHECK_STORE_BYTES 200, 0x01,0xBE,0xAD,0xDE,0xBE,0xBA,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x23
    sb   t1, 1(t0)
    CHECK_STORE_BYTES 201, 0xEF,0x23,0xAD,0xDE,0xBE,0xBA,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x45
    sb   t1, 2(t0)
    CHECK_STORE_BYTES 202, 0xEF,0xBE,0x45,0xDE,0xBE,0xBA,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x67
    sb   t1, 3(t0)
    CHECK_STORE_BYTES 203, 0xEF,0xBE,0xAD,0x67,0xBE,0xBA,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x89
    sb   t1, 4(t0)
    CHECK_STORE_BYTES 204, 0xEF,0xBE,0xAD,0xDE,0x89,0xBA,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x10
    sb   t1, 5(t0)
    CHECK_STORE_BYTES 205, 0xEF,0xBE,0xAD,0xDE,0xBE,0x10,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0xCD
    sb   t1, 6(t0)
    CHECK_STORE_BYTES 206, 0xEF,0xBE,0xAD,0xDE,0xBE,0xBA,0xCD,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x5A
    sb   t1, 7(t0)
    CHECK_STORE_BYTES 207, 0xEF,0xBE,0xAD,0xDE,0xBE,0xBA,0xFE,0x5A

    /* ---- SH aligned offsets 0,2,4,6 ---- */
    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x1122
    sh   t1, 0(t0)
    CHECK_STORE_BYTES 210, 0x22,0x11,0xAD,0xDE,0xBE,0xBA,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x3344
    sh   t1, 2(t0)
    CHECK_STORE_BYTES 211, 0xEF,0xBE,0x44,0x33,0xBE,0xBA,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x5566
    sh   t1, 4(t0)
    CHECK_STORE_BYTES 212, 0xEF,0xBE,0xAD,0xDE,0x66,0x55,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x7788
    sh   t1, 6(t0)
    CHECK_STORE_BYTES 213, 0xEF,0xBE,0xAD,0xDE,0xBE,0xBA,0x88,0x77

    .ifdef DO_MISALIGNED
        RESET_STORE_BUF
        la   t0, store_buf
        li   t1, 0xA1B2
        sh   t1, 1(t0)
        CHECK_STORE_BYTES 214, 0xEF,0xB2,0xA1,0xDE,0xBE,0xBA,0xFE,0xCA

        RESET_STORE_BUF
        la   t0, store_buf
        li   t1, 0xC3D4
        sh   t1, 3(t0)
        CHECK_STORE_BYTES 215, 0xEF,0xBE,0xAD,0xD4,0xC3,0xBA,0xFE,0xCA

        RESET_STORE_BUF
        la   t0, store_buf
        li   t1, 0xE5F6
        sh   t1, 5(t0)
        CHECK_STORE_BYTES 216, 0xEF,0xBE,0xAD,0xDE,0xBE,0xF6,0xE5,0xCA
    .endif

    /* ---- SW aligned offsets 0,4 ---- */
    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0x11223344
    sw   t1, 0(t0)
    CHECK_STORE_BYTES 220, 0x44,0x33,0x22,0x11,0xBE,0xBA,0xFE,0xCA

    RESET_STORE_BUF
    la   t0, store_buf
    li   t1, 0xAABBCCDD
    sw   t1, 4(t0)
    CHECK_STORE_BYTES 221, 0xEF,0xBE,0xAD,0xDE,0xDD,0xCC,0xBB,0xAA

    .ifdef DO_MISALIGNED
        RESET_STORE_BUF
        la   t0, store_buf
        li   t1, 0x01020304
        sw   t1, 1(t0)
        CHECK_STORE_BYTES 222, 0xEF,0x04,0x03,0x02,0x01,0xBA,0xFE,0xCA

        RESET_STORE_BUF
        la   t0, store_buf
        li   t1, 0x05060708
        sw   t1, 2(t0)
        CHECK_STORE_BYTES 223, 0xEF,0xBE,0x08,0x07,0x06,0x05,0xFE,0xCA

        RESET_STORE_BUF
        la   t0, store_buf
        li   t1, 0x090A0B0C
        sw   t1, 3(t0)
        CHECK_STORE_BYTES 224, 0xEF,0xBE,0xAD,0x0C,0x0B,0x0A,0x09,0xCA
    .endif

    j pass


/* ----------------- failure labels emitted here -----------------
 * These are placed *after* the test so objdump shows a clean
 * “bne ... fail_at_XXX” and the label is nearby.
 */
    /* Loads */
    FAIL_AT 100
    FAIL_AT 101
    FAIL_AT 102
    FAIL_AT 103
    FAIL_AT 104
    FAIL_AT 105
    FAIL_AT 106
    FAIL_AT 107

    FAIL_AT 110
    FAIL_AT 111
    FAIL_AT 112
    FAIL_AT 113
    FAIL_AT 114
    FAIL_AT 115
    FAIL_AT 116
    FAIL_AT 117

    FAIL_AT 120
    FAIL_AT 121
    FAIL_AT 122
    FAIL_AT 123
    .ifdef DO_MISALIGNED
        FAIL_AT 124
        FAIL_AT 125
        FAIL_AT 126
    .endif

    FAIL_AT 130
    FAIL_AT 131
    FAIL_AT 132
    FAIL_AT 133
    .ifdef DO_MISALIGNED
        FAIL_AT 134
        FAIL_AT 135
        FAIL_AT 136
    .endif

    FAIL_AT 140
    FAIL_AT 141
    .ifdef DO_MISALIGNED
        FAIL_AT 142
        FAIL_AT 143
        FAIL_AT 144
    .endif

    /* Stores */
    FAIL_AT 200
    FAIL_AT 201
    FAIL_AT 202
    FAIL_AT 203
    FAIL_AT 204
    FAIL_AT 205
    FAIL_AT 206
    FAIL_AT 207

    FAIL_AT 210
    FAIL_AT 211
    FAIL_AT 212
    FAIL_AT 213
    .ifdef DO_MISALIGNED
        FAIL_AT 214
        FAIL_AT 215
        FAIL_AT 216
    .endif

    FAIL_AT 220
    FAIL_AT 221
    .ifdef DO_MISALIGNED
        FAIL_AT 222
        FAIL_AT 223
        FAIL_AT 224
    .endif



/* ----------------- data ----------------- */
    .section .data
    .balign 4

    .globl test_bytes
test_bytes:
    .word 0x80FF7F01
    .word 0x78563412

    .balign 4
    .globl store_buf
store_buf:
    .word 0xDEADBEEF
    .word 0xCAFEBABE
