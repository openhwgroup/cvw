.section .text
.globl lpddr_test
.type lpddr_test, @function

lpddr_test:
bsg_dmc_setup:
        li t1, 0x00030000
        li t2, 0x3ff
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x1
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0xf
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0xa
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x2
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x7
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x1
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x2
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0xa
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x7
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0xa
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x3
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0xb
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0xe
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x2
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x19
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x3
        sd t2, 0(t1)
        addi t1, t1, 8
        li t2, 0x9c4a
        sd t2, 0(t1)
        
        li t1, 0x90000000
        addi t5, t1, 0
        li t2, 0x0ABCDEF000000001
        li t3, 10
        li t4, 0
loop_write:
        beq t4, t3, done_write
        sd t2, 0(t5)
        addi t5, t5, 8
        addi t4, t4, 1
        addi t2, t2, 1
        j loop_write
done_write:
        li t4, 0
        addi t5, t1, 0
loop_read:
        beq t4, t3, done_read
        ld t6, 0(t5)
        addi t5, t5, 8
        addi t4, t4, 1
        # TODO: If t6 does not match t2, error
        j loop_read
done_read:
tohost:
        li t0, 0x80000000
        sw zero, 0(t0) # Terminate the regression test
