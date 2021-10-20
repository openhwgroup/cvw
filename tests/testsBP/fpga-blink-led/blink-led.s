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

loop:

	# delay
	li	x20, PERIOD/2
delay1:	
	addi	x20, x20, -1
	bge	x20, x0, delay1

	# clear GPO
	sw	x0, 0x0(x5)

	# delay
	li	x20, PERIOD/2
delay2:	
	addi	x20, x20, -1
	bge	x20, x0, delay2

	# write GPO
	sw	x2, 0x0(x5)

	j	loop



