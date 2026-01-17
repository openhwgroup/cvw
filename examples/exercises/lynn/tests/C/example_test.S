// James Kaden Cassidy
// kacassidy@hmc.edu
// 1/5/2026

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

finish:
    /* write gp to tohost and hang */
    /* la   t0, tohost */
        li  t0, 0x400        # 1024, safe imm12
    li  t1, 0x001        # 1, safe imm12

    # t0 = 0x400 << 21 = 0x80000000
    add t0, t0, t0       # 1
    add t0, t0, t0       # 2
    add t0, t0, t0       # 3
    add t0, t0, t0       # 4
    add t0, t0, t0       # 5
    add t0, t0, t0       # 6
    add t0, t0, t0       # 7
    add t0, t0, t0       # 8
    add t0, t0, t0       # 9
    add t0, t0, t0       # 10
    add t0, t0, t0       # 11
    add t0, t0, t0       # 12
    add t0, t0, t0       # 13
    add t0, t0, t0       # 14
    add t0, t0, t0       # 15
    add t0, t0, t0       # 16
    add t0, t0, t0       # 17
    add t0, t0, t0       # 18
    add t0, t0, t0       # 19
    add t0, t0, t0       # 20
    add t0, t0, t0       # 21   -> t0 = 0x8000_0000

    # t1 = 1 << 12 = 0x1000
    add t1, t1, t1       # 1
    add t1, t1, t1       # 2
    add t1, t1, t1       # 3
    add t1, t1, t1       # 4
    add t1, t1, t1       # 5
    add t1, t1, t1       # 6
    add t1, t1, t1       # 7
    add t1, t1, t1       # 8
    add t1, t1, t1       # 9
    add t1, t1, t1       # 10
    add t1, t1, t1       # 11
    add t1, t1, t1       # 12   -> t1 = 0x0000_1000

    add t0, t0, t1       # t0 = 0x8000_1000

    sw   gp, 0(t0)
1:  j    1b
