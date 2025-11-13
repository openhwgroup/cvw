.file "main.S"
.title "Function main"

.option nopic
.option relax

.include "common.inc"

.globl atpg_values
.bss
atpg_values: .zero 16
checksum: .zero 4



.text
PROC main
    # checksum = 0xCAFECAFE;
    la t0, checksum
    li t1, 0xCAFECAFE
    sw t1, (t0)
    
    # Clear atpg_values array
    la t0, atpg_values
    sw x0, (t0)
    sw x0, 4(t0)
    sw x0, 8(t0)
    sw x0, 12(t0)
    
    # Call atpg_func and store the return value in checksum
    call atpg_func
    la t0, checksum
    sw a0, (t0)
    
    # Return the sum of atpg_values array
    la t0, atpg_values
    lw a0, (t0)
    lw t1, 4(t0)
    add a0, a0, t1
    lw t1, 8(t0)
    add a0, a0, t1
    lw t1, 12(t0)
    add a0, a0, t1
    
    call exit
ENDP main
