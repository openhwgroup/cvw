.globl main 
.equ N, 5

.data
//A: .word 5, 42, −88, 2, −5033, 720, 314 
str1: .string "RISC-V"
.align 2
B: .word 0x32A
.bss
C: .space 
D: .space
.balign 4 

.text 
main:
    li a0, 42
    jr ra

.section .rodata 
str2: .string "Hello"

.end
