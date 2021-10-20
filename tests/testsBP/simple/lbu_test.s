.section .text	
.global lbu_test
.type lbu_test, @function

lbu_test:

	li t0, 0x80000
	lbu t1, 0(t0)


pass:
	li a0, 0
done:
	ret

fail:
	li a0, -1
	j done
	
