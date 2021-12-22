# ch5.s
# David_Harris@hmc.edu 14 December 2021

.section .text.init

.globl _start
_start:
    lw x1, 4(x0)
    sw x1, 8(x0)
    add x2, x1, x1
    beq x1, x2, done
loop:
    jal x0, loop
done:

.end
