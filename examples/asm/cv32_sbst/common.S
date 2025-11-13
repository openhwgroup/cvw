.option nopic
.option relax

.include "common.inc"

.equiv EXIT_REG, 0x20000004
.global SIG



.text
# void* memset(void* s, int c, size_t n);
# Uses t0
PROC evi_memset
    srli t0, a2, 2
    beqz t0, do_last

loop:
    sw a1, (a0)
    addi t0, t0, -1
    addi a0, a0, 4
    bnez t0, loop

do_last:
    andi t0, a2, 3
    beqz t0, fend

last_loop:
    sb a1, (a0)
    addi t0, t0, -1
    addi a0, a0, 1
    bnez t0, last_loop

fend:
    sub a0, a0, a2
    ret
ENDP evi_memset

# void* memcpy(void* dest, const void* src, size_t n);
# Uses t0, t1
PROC evi_memcpy
    srli t0, a2, 2
    beqz t0, cpy_last

cpy_loop:
    lw t1, (a1)
    addi t0, t0, -1
    addi a1, a1, 4
    sw t1, (a0)
    addi a0, a0, 4
    bnez t0, cpy_loop

cpy_last:
    andi t0, a2, 3
    beqz t0, cpy_end

cpy_last_loop:
    lb t1, (a1)
    addi t0, t0, -1
    addi a1, a1, 1
    sb t1, (a0)
    addi a0, a0, 1
    bnez t0, cpy_last_loop

cpy_end:
    sub a0, a0, a2
    sub a1, a1, a2
    ret
ENDP evi_memcpy

PROC exit
    # Write the exit status on the predefined address
    li t0, EXIT_REG
    sw a0, (t0)
1:
    wfi
    j 1b
ENDP exit

PROC csr_sig

    la t0, SIG
    lw t1,(t0)
    addi t1, t1, 1
    sw  t1,(t0)

    ret
ENDP csr_sig

.data

SIG:
.long 0x0
.space 8

.end
