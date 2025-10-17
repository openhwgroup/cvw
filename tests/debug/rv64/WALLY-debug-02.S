//////////////////////////////////////////////////////////////////////
// WALLY-debug-01.S
//////////////////////////////////////////////////////////////////////
.text
.globl rvtest_entry_point
rvtest_entry_point:
	li x1, 0x00000000deadbeef
	li x2, 0x00000000babeface
	li x3, 0x00000000baddecaf
	li x4, 0x00000000feedcafe
	li x5, 0x00000000deadbeef
	li x6, 0x00000000babeface
	li x7, 0x00000000baddecaf
	li x8, 0x00000000feedcafe
	li x9, 0x00000000deadbeef
	li x10, 0x00000000babeface
	li x11, 0x00000000baddecaf
	li x12, 0x00000000feedcafe
	li x13, 0x00000000deadbeef
	li x14, 0x00000000babeface
	li x15, 0x00000000baddecaf
	li x16, 0x00000000feedcafe
	li x17, 0x00000000deadbeef
	li x18, 0x00000000babeface
	li x19, 0x00000000baddecaf
	li x20, 0x00000000feedcafe
	li x21, 0x00000000deadbeef
	li x22, 0x00000000babeface
	li x23, 0x00000000baddecaf
	li x24, 0x00000000feedcafe
	li x25, 0x00000000deadbeef
	li x26, 0x00000000babeface
	li x27, 0x00000000baddecaf
	li x28, 0x00000000feedcafe
	li x29, 0x00000000deadbeef
	li x30, 0x00000000babeface
	li x31, 0x00000000baddecaf	
1:	j 1b
	
test_end:
	li a0, 0
	j tohost_exit

.globl tohost_exit
tohost_exit:
	slli a0, a0, 1
	ori a0, a0, 1
	la t0, tohost
	sw a0, 0(t0)
1: j 1b
	
.section .tohost, "aw", @progbits
.align 6
.globl tohost
tohost: .dword 0
	
.align 6
.globl fromhost
fromhost: .dword 0
	
# a syscall buffer?
.align 6
magic_mem: .word 0, 0, 0, 0, 0, 0, 0, 0
