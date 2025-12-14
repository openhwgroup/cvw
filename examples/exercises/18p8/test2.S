    .section .data
a:  .word 1, 2, 3, 4, 5, 6, 7, 8
b:  .word 10, 20, 30, 40, 50, 60, 70, 80
result: .space 32       # Reserve 8 words (4 bytes each) = 32 bytes

    .section .text
    .globl _start

_start:
    # Set VL for 32-bit integers
    li t0, 8            # 8 elements
    vsetvli t1, t0, e32, m1

    # Load vectors
    la t2, a
    vle32.v v0, (t2)    # Load vector v0 from array a

    la t3, b
    vle32.v v1, (t3)    # Load vector v1 from array b

    # Vector add
    vadd.vv v2, v0, v1

    # Store result
    la t4, result
    vse32.v v2, (t4)

    # Normally here you would exit, but on bare-metal, just loop forever
hang:
    j hang
