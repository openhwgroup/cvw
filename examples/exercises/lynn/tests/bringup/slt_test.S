// slt_test.S
// James Kaden Cassidy
// kacassidy@hmc.edu
// Tests slt, including an overflow case that catches the bug
// where LT = Neg instead of the correct Neg ^ Overflow.

.extern return_slt_test
.extern fail

    .section .text.init
    .globl slt_test
    .type  slt_test, @function

slt_test:
    test1:
        // Basic: 3 < 5, slt should write 1
        li   t0, 3
        li   t1, 5
        slt  t2, t0, t1
        li   t3, 1
        beq  t2, t3, test2
        j    Fail_Slt_1

    test2:
        // Overflow case: -2147483648 < 1, slt should write 1.
        // SrcA=0x80000000, SrcB=1 -> Sum=0x7FFFFFFF (Neg=0, Overflow=1)
        // Correct:  LT = Neg ^ Overflow = 0 ^ 1 = 1
        // Bug D:    LT = Neg             = 0     = 0  (wrong)
        li   t0, 0x80000000
        li   t1, 1
        slt  t2, t0, t1
        li   t3, 1
        beq  t2, t3, pass
        j    Fail_Slt_2

    pass:
        j return_slt_test

Fail_Slt_1:
    li   gp, 601
    j    fail

Fail_Slt_2:
    li   gp, 602
    j    fail
