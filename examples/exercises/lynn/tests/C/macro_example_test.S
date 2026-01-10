// James Kaden Cassidy
// kacassidy@hmc.edu
// 1/5/2026

//// ------------- Macro Version ------------- ////

/*
Test an instruction (op) with immediate values (a, b) loaded to
registers t0 and t1. The result is written to t2, the expected value
is loaded to t3, if the expected and computed values are different
the test fails and jumps to the FAIL_LABEL macro
*/
    .macro TEST_RR op, a, b, exp, faillabel
        li   t0, \a
        li   t1, \b
        \op  t2, t0, t1
        li   t3, \exp
        bne  t2, t3, \faillabel
    .endm

/*
Fail label saves the ID of the fail test, which is written to tohost
by "fail" (see crt0.S). ToHost is written to the log file by the testbench,
this id number can be used to determine which test failed
*/

    .macro FAIL_LABEL name, id
\name:
        li   gp, \id
        j    fail
    .endm

/*
similar macro to TEST_RR but for instructions with immediates
*/

    .macro TEST_RI op, a, imm, exp, faillabel
        li   t0, \a
        \op  t2, t0, \imm
        li   t3, \exp
        bne  t2, t3, \faillabel
    .endm

/*
function where macros are inserted (tests are actually created) and
code is executed.
*/
    .section .text
    .globl macro_example_test
    .type  macro_example_test, @function
macro_example_test:

    TEST_RR or,   0x0F, 0xF0, 0xFF,        Fail_Or_M1
    TEST_RR xor,  0xAA, 0x0F, 0xA5,        Fail_Xor_M1
    TEST_RR and,  0x55, 0xAA, 0x00,        Fail_And_M1
    TEST_RR add,  7,    5,    12,          Fail_Add_M1
    TEST_RR sub,  9,    4,    5,           Fail_Sub_M1

    TEST_RI  ori,  0x0F, 0xF0, 0xFF,        Fail_Ori_M1
    TEST_RI  xori, 0xAA, 0x0F, 0xA5,        Fail_Xori_M1
    TEST_RI  addi, 100,  -1,   99,          Fail_Addi_M1
    TEST_RI  andi, 0xFF, 0x0F, 0x0F,        Fail_Andi_M1

    j pass

pass:
    li  a0, 1
    ret

fail:
    li  a0, 0
    ret

/* fail macros */

    FAIL_LABEL Fail_Or_M1,    10
    FAIL_LABEL Fail_Xor_M1,   11
    FAIL_LABEL Fail_And_M1,   12
    FAIL_LABEL Fail_Add_M1,   13
    FAIL_LABEL Fail_Sub_M1,   14

    FAIL_LABEL Fail_Ori_M1,   20
    FAIL_LABEL Fail_Xori_M1,  21
    FAIL_LABEL Fail_Addi_M1,  22
    FAIL_LABEL Fail_Andi_M1,  23
