.section .text
.globl global_hist_3_space_test
.type global_hist_3_space_test, @function
global_hist_3_space_test:
	li t1, 1
	li t2, 200
	li t3, 0
	li t4, 1

loop_3:
	# instruction
	addi t3, t3, 1
	addi t3, t3, 1
	addi t3, t3, 1		
	beqz t4, zero_3     # this branch toggles between taken and not taken.
	li t4, 0
	j one_3
zero_3:
	li t4, 1
	add t1, t1, t4
	
one_3:
	addi t3, t3, 1		
	addi t2, t2, -1
	bnez t2, loop_3

	ret

.section .text
.globl global_hist_2_space_test
.type global_hist_2_space_test, @function
global_hist_2_space_test:
	li t1, 1
	li t2, 200
	li t3, 0
	li t4, 1

loop_2:
	# instruction
	addi t3, t3, 1
	addi t3, t3, 1
	beqz t4, zero_2     # this branch toggles between taken and not taken.
	li t4, 0
	j one_2
zero_2:
	li t4, 1
	add t1, t1, t4
	
one_2:
	addi t2, t2, -1
	bnez t2, loop_2

	ret

.section .text
.globl global_hist_1_space_test
.type global_hist_1_space_test, @function
global_hist_1_space_test:
	li t1, 1
	li t2, 200
	li t3, 0
	li t4, 1

loop_1:
	# instruction
	addi t3, t3, 1
	beqz t4, zero_1     # this branch toggles between taken and not taken.
	li t4, 0
	j one_1
zero_1:
	li t4, 1
	add t1, t1, t4
	
one_1:
	addi t2, t2, -1
	bnez t2, loop_1

	ret
	
.section .text
.globl global_hist_0_space_test
.type global_hist_0_space_test, @function
global_hist_0_space_test:
	li t1, 1
	li t2, 200
	li t3, 0
	li t4, 1

loop_0:
	# instruction
	beqz t4, zero_0     # this branch toggles between taken and not taken.
	li t4, 0
	j one_0
zero_0:
	li t4, 1
	add t1, t1, t4
	
one_0:
	addi t2, t2, -1
	bnez t2, loop_0

	ret
	
