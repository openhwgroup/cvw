// debug.S
// David_Harris@hmc.edu 4 February 2023
// Small code snippets for the purpose of debugging issues
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# openhwgroup/cvw Issue #55
li x1, 0x7ff0000000000001
fmv.w.x f4, x1
li x1, 7ff8000000000000
fmv.w.x f9, x1
fsgnjx.s f12,f9,f4  # expected f 0xffffffff7fc00000


#########################
# HTIF and signature
#########################

write_tohost:
    la t1, tohost
    li t0, 1            # 1 for success, 3 for failure
    sd t0, 0(t1)        # send success code

self_loop:
    j self_loop         # wait
    
.section .tohost 
tohost:                 # write to HTIF
    .dword 0
fromhost:
    .dword 0

.data

.EQU XLEN,64
begin_signature:
    .fill 2*(XLEN/32),4,0xdeadbeef    # 
end_signature:

# Initialize stack with room for 512 bytes
.bss
    .space 512
topofstack: