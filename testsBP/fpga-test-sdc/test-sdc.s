PERIOD = 22000000
#PERIOD = 100

.section .init
.global _start
.type _start, @function

		
_start:
	  # Initialize global pointer
	.option push
	.option norelax
	1:auipc gp, %pcrel_hi(__global_pointer$)
	addi  gp, gp, %pcrel_lo(1b)
	.option pop
	
	li x1, 0
	li x2, 0
	li x4, 0
	li x5, 0
	li x6, 0
	li x7, 0
	li x8, 0
	li x9, 0
	li x10, 0
	li x11, 0
	li x12, 0
	li x13, 0
	li x14, 0
	li x15, 0
	li x16, 0
	li x17, 0
	li x18, 0
	li x19, 0
	li x20, 0
	li x21, 0
	li x22, 0
	li x23, 0
	li x24, 0
	li x25, 0
	li x26, 0
	li x27, 0
	li x28, 0
	li x29, 0
	li x30, 0
	li x31, 0


	# start by writting the clock divider to 4 setting SDC to 25MHz
	la	x3, 0x12100
	li	x4, -4
	sw	x4, 0x0(x3)

	# start by writting the clock divider to 1 setting SDC to 100MHZ
	la	x3, 0x12100
	li	x4, 1
	sw	x4, 0x0(x3)


	# wait until the SDC is done with initialization
	li	x4, 0x1
wait_sdc_done_init:	
	lw	x5, 4(x3)
	and	x5, x5, x4
	bne	x5, x4, wait_sdc_done_init

	# now that it is done lets setup for a read
	li	x6, 0x20000000
	sd	x6, 0x10(x3)    # write address register

	# send read by writting to command register
	li	x7, 0x4
	sw	x7, 0x8(x3)

	li 	x4, 0x2
wait_sdc_done_read:	
	lw	x5, 4(x3)
	and	x5, x5, x4
	beq	x5, x4, wait_sdc_done_read

	# copy data from mailbox
	li	x11, 0x80000000
	li	x9, 0
copy_sdc:	
	li 	x8, 512/8
	ld	x10, 0x18(x3)  # read the mailbox
	sd	x10, 0x0(x11)  # write to dram
	addi	x9, x9, 1
	addi	x11, x11, 8
	blt	x9, x8, copy_sdc

	# second read of sdc
	# now that it is done lets setup for a read
	li	x6, 0x20000200
	sd	x6, 0x10(x3)    # write address register

	# send read by writting to command register
	li	x7, 0x4
	sw	x7, 0x8(x3)

	li 	x4, 0x2
wait_sdc_done_read2:	
	lw	x5, 4(x3)
	and	x5, x5, x4
	beq	x5, x4, wait_sdc_done_read2

	# copy data from mailbox
	li	x11, 0x80000200
	li	x9, 0
copy_sdc2:	
	li 	x8, 512/8
	ld	x10, 0x18(x3)  # read the mailbox
	sd	x10, 0x0(x11)  # write to dram
	addi	x9, x9, 1
	addi	x11, x11, 8
	blt	x9, x8, copy_sdc2
	


	# write to gpio
	li	x2, 0xFF
	la	x3, 0x10012000

	# +8 is output enable
	# +C is output value

	addi	x4, x3, 8
	addi	x5, x3, 0xC

	# write initial value of 0xFF to GPO
	sw	x2, 0x0(x5)
	# enable output
	sw	x2, 0x0(x4)

	# before jumping to led loop
	# lets try writting to dram.

	li	x21, 0
	li	x23, 4096*16    # 64KB of data

	li	x22, 0x80000000
	li	x24, 0

write_loop:
	add	x25, x22, x24
	sw	x24, 0(x25)
	addi	x24, x24, 4
	blt	x24, x23, write_loop

	li	x24, 0
read_loop:
	add	x25, x22, x24
	lw	x21, 0(x25)

	# check value
	bne	x21, x24, fail_loop

	addi	x24, x24, 4
	
	#
	blt	x24, x23, read_loop

	

loop:

	# delay
	li	x20, PERIOD
delay1:	
	addi	x20, x20, -1
	bge	x20, x0, delay1

	# new GPO
	addi	x2, x2, 1
	sw	x2, 0x0(x5)

	j	loop


fail_loop:

	# delay
	li	x20, PERIOD/20
fail_delay1:	
	addi	x20, x20, -1
	bge	x20, x0, fail_delay1

	# clear GPO
	sw	x0, 0x0(x5)

	# delay
	li	x20, PERIOD/20
fail_delay2:	
	addi	x20, x20, -1
	bge	x20, x0, fail_delay2

	# write GPO
	sw	x2, 0x0(x5)

	j	fail_loop


