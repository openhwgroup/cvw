.section .text
.global __trap_handler
.type __trap_handler, @function

__trap_handler:
	# save the context of the cpu to the top of the current stack
	addi sp, sp, -124
	sw x1, 0x0(sp)
	sw x2, 0x4(sp)
	sw x3, 0x8(sp)
	sw x4, 0xC(sp)
	sw x5, 0x10(sp)
	sw x6, 0x14(sp)	
	sw x7, 0x18(sp)
	sw x8, 0x1C(sp)
	sw x9, 0x20(sp)
	sw x10, 0x24(sp)
	sw x11, 0x28(sp)
	sw x12, 0x2C(sp)
	sw x13, 0x30(sp)
	sw x14, 0x34(sp)
	sw x15, 0x38(sp)
	sw x16, 0x3C(sp)
	sw x17, 0x40(sp)
	sw x18, 0x44(sp)
	sw x19, 0x48(sp)
	sw x20, 0x4C(sp)
	sw x21, 0x50(sp)
	sw x22, 0x54(sp)
	sw x23, 0x58(sp)
	sw x24, 0x5C(sp)
	sw x25, 0x60(sp)
	sw x26, 0x64(sp)
	sw x27, 0x68(sp)
	sw x28, 0x6C(sp)
	sw x29, 0x70(sp)
	sw x30, 0x74(sp)
	sw x31, 0x78(sp)

	# figure out what caused the trap.
	csrrw t0, mcause, x0
	# mcause is {int, 31 bit exception code}
	# for this implementation only the lowest 4 bits are used
	srli	t1, t0, 31 		# interrupt flag
	andi	t2, t0, 0xF 		# 4 bit cause

	slli	t1, t1, 5 		# shift int flag
	or	t1, t1, t2 		# combine
	slli	t1, t1, 2		# multiply by 4
	la	t3, exception_table
	add	t4, t3, t1
	lw	t5, 0(t4)
	jr	t5, 0 		# jump to specific ISR
	# specific ISR is expected to set epc

restore_st:
	# restore register from stack on exit.

	lw x1, 0x0(sp)
	lw x2, 0x4(sp)
	lw x3, 0x8(sp)
	lw x4, 0xC(sp)
	lw x5, 0x10(sp)
	lw x6, 0x14(sp)	
	lw x7, 0x18(sp)
	lw x8, 0x1C(sp)
	lw x9, 0x20(sp)
	lw x10, 0x24(sp)
	lw x11, 0x28(sp)
	lw x12, 0x2C(sp)
	lw x13, 0x30(sp)
	lw x14, 0x34(sp)
	lw x15, 0x38(sp)
	lw x16, 0x3C(sp)
	lw x17, 0x40(sp)
	lw x18, 0x44(sp)
	lw x19, 0x48(sp)
	lw x20, 0x4C(sp)
	lw x21, 0x50(sp)
	lw x22, 0x54(sp)
	lw x23, 0x58(sp)
	lw x24, 0x5C(sp)
	lw x25, 0x60(sp)
	lw x26, 0x64(sp)
	lw x27, 0x68(sp)
	lw x28, 0x6C(sp)
	lw x29, 0x70(sp)
	lw x30, 0x74(sp)
	lw x31, 0x78(sp)

	addi sp, sp, 124

	mret

.section .text
.type trap_instr_addr_misalign, @function
trap_instr_addr_misalign:
	# fatal error, report error and halt
	addi	sp, sp, 4
	sw	ra, 0(sp)
	jal	fail
	lw	ra, 0(sp)
	la	t0, restore_st
	jr	t0, 0

.section .text
.type trap_m_ecall, @function
trap_m_ecall:
	addi	sp, sp, -4
	sw	ra, 0(sp)
	# select which system call based on a7.
	# for this example we will just define the following.
	# not standard with linux or anything.
	# 0: execute a call back function
	# 1: decrease privilege by 1 (m=>s, s=>u, u=>u)
	# 2: increase privilege by 1 (m=>m, s=>m, u=>s)

	# check a7
	li	t0, 1
	beq	a7, t0, trap_m_decrease_privilege
	li	t0, 2
	beq	a7, t0, trap_m_increase_privilege
	
	# call call back function if not zero
	la	t1, isr_m_ecall_cb_fp
	lw	t0, 0(t1)
	beq	t0, x0, trap_m_ecall_skip_cb
	jalr	ra, t0, 0
trap_m_ecall_skip_cb:	
	# modify the mepc
	csrrw	t0, mepc, x0
	addi	t0, t0, 4
	csrrw	x0, mepc, t0
	lw	ra, 0(sp)
	addi	sp, sp, 4
	la	t0, restore_st
	jr	t0, 0

trap_m_decrease_privilege:
	# read the mstatus register
	csrrw	t0, mstatus, x0
	# 11 => 01, and 01 => 00.
	# this is accomplished by clearing bit 12 and taking the old
	# bit 12 as the new bit 11.
	li	t3, 0x00001800
	and	t1, t0, t3 # isolates the bits 12 and 11.
	# shift right by 1.
	srli	t2, t1, 1
	and	t2, t2, t3 # this will clear bit 10.
	li	t3, ~0x00001800
	and	t4, t0, t3
	or	t0, t2, t4
	csrrw	x0, mstatus, t0
	j	trap_m_ecall_skip_cb

trap_m_increase_privilege:
	# read the mstatus register
	csrrw	t0, mstatus, x0
	# 11 => 01, and 01 => 00.
	# this is accomplished by setting bit 11 and taking the old
	# bit 11 as the new bit 12.
	li	t3, 0x00000800
	li	t4, ~0x00000800
	and	t1, t0, t3
	slli	t2, t1, 1 		# shift left by 1.
	or	t2, t2, t3		# bit 11 is always set.
	and	t1, t0, t5
	or	t0, t1, t2
	csrrw	x0, mstatus, t0
	j 	trap_m_ecall_skip_cb
	
.data
exception_table:
	.int trap_instr_addr_misalign
	.int trap_instr_addr_misalign #trap_instr_access_fault
	.int trap_instr_addr_misalign #trap_illegal_instr
	.int trap_instr_addr_misalign #trap_breakpoint
	.int trap_instr_addr_misalign #trap_load_addr_misalign
	.int trap_instr_addr_misalign #trap_load_access_fault
	.int trap_instr_addr_misalign #trap_store_addr_misalign
	.int trap_instr_addr_misalign #trap_store_access_fault
	.int trap_m_ecall
	.int trap_m_ecall
	.int restore_st
	.int trap_m_ecall
	.int trap_instr_addr_misalign #trap_instr_page_fault
	.int trap_instr_addr_misalign #trap_load_page_fault
	.int restore_st
	.int trap_instr_addr_misalign #trap_store_page_fault
#.data
#interrupt_table:
	.int trap_instr_addr_misalign #trap_u_software
	.int trap_instr_addr_misalign #trap_s_software
	.int restore_st
	.int trap_instr_addr_misalign #trap_m_software
	.int trap_instr_addr_misalign #trap_u_timer
	.int trap_instr_addr_misalign #trap_s_timer
	.int restore_st
	.int trap_instr_addr_misalign #trap_m_timer
	.int trap_instr_addr_misalign #trap_u_external
	.int trap_instr_addr_misalign #trap_s_external
	.int restore_st
	.int trap_instr_addr_misalign #trap_m_external
	.int restore_st
	.int restore_st
	.int restore_st
	.int restore_st

	
.section .data
.global isr_m_ecall_cb_fp
isr_m_ecall_cb_fp:
	.int 0
