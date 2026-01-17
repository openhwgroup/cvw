// James Kaden Cassidy
// kacassidy@hmc.edu
// 1/5/2026

    .extern finish

    .section .text
    .globl example_test
    .type  example_test, @function

example_test:

    test1:
        li   t0, 0x0F
        li   t1, 0xF0
        or   t2, t0, t1
        li   t3, 0xFF
        beq  t2, t3, test2
        j Fail_Or_1

    test2:
        li   t0, 0x55
        li   t1, 0xAA
        and  t2, t0, t1
        li   t3, 0x00
        beq  t2, t3, test3
        j Fail_And_1

    test3:
        li   t0, 7
        li   t1, 5
        add  t2, t0, t1
        li   t3, 12
        beq  t2, t3, test4
        j Fail_Add_1

    test4:
        li   t0, 9
        li   t1, 4
        sub  t2, t0, t1
        li   t3, 5
        beq  t2, t3, end
        j Fail_Sub_1

    end:
        j    pass

// gp is displayed in the log file when not 1 or 2 (1 means test passed, 2 means no output)
Fail_Or_1:
    li   gp, 10
    j    fail

Fail_And_1:
    li   gp, 20
    j    fail

Fail_Add_1:
    li   gp, 30
    j    fail

Fail_Sub_1:
    li   gp, 40
    j    fail

fail:
    // gp stores a number identifying which test failed and will be printed to logfile under "TO_HOST"
    j    finish

pass:
    /* encode a non-1 fail code (gp already holds something else if you want) */
    li   gp, 1
    j    finish
