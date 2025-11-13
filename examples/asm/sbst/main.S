.file "main.S"
.title "Function main"

.option nopic
.option relax

.extern test1
.bss
checksum: .zero 4



.text
.globl main
main:
    # checksum = 0xCAFECAFE;
    #la t0, checksum
    li t1, 0xCAFECAFE
    #sw t1, (t0)
    

    
    # Call atpg_func and store the return value in checksum
    call test1
    la t0, checksum
    sw a0, (t0)
    
    
    call exit
.end
