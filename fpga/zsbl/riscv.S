.section .text
.globl read_mcycle
.type read_mcycle, @function
read_mcycle:
    csrr a0, mcycle
    ret

.section .text
.globl get_ra
.type get_ra, @function
get_ra:
    mv a0, ra
    ret

.section .text
.globl set_status_fs
.type set_status_fs, @function    
set_status_fs:
    lui t1, 0x6
    csrs mstatus, t1
    ret

.section .text
.globl clear_status_fs
.type clear_status_fs, @function 
clear_status_fs:
    lui t1, 0x6
    csrc mstatus, t1
    ret
