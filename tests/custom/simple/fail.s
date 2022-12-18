# Ross Thompson
# March 17, 2021
# Oklahoma State University

.section .text	
.global fail
.type fail, @function
fail:
	li gp, 1
	li a0, -1
	ecall
