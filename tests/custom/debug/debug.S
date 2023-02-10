// debug.S
// David_Harris@hmc.edu 4 February 2023
// Small code snippets for the purpose of debugging issues
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

.global rvtest_entry_point
rvtest_entry_point:
    lui t0, 0x1e            # turn on Floating point and XS
    csrs mstatus, t0                 

    # openhwgroup/cvw Issue #55
    la a6, begin_signature
    la a7, rvtest_data
    fadd.d ft0, ft1, ft2
    fld f4, 0(a7)
    fld f9, 8(a7)
#    li x1, 0x7ff0000000000001
#    sd x1, 0(a6)
#    fmv.w.x f4, x1
#    li x1, 0x7ff8000000000000
 #   fmv.w.x f9, x1
    fsgnjx.s f12,f9,f4  # expected f 0xffffffff7fc00000
    fsd f12, 0(a6)

#########################
# HTIF and signature
#########################

write_tohost:
    la t1, tohost
    li t0, 1            # 1 for success, 3 for failure
    sd t0, 0(t1)        # send success code

self_loop:
    j self_loop         # wait
    
.align 6
.section .tohost 
tohost:                 # write to HTIF
    .dword 0
fromhost:
    .dword 0

.align 6
.data

rvtest_data:
.dword 0x7ff0000000000001
.dword 0x7ff8000000000000

.EQU XLEN,64
begin_signature:
    .fill 2*(XLEN/32),4,0xdeadbeef    # 
end_signature:

# Initialize stack with room for 512 bytes
.bss
    .space 512
topofstack: