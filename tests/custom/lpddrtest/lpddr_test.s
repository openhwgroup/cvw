.section .text
.globl lpddr_test
.type lpddr_test, @function
lpddr_test:
	li t1, 0x90000000
        addi t5, t1, 0
	li t2, 0xAABBCCDD00112233

        li t3, 10
        li t4, 0
loop_write:     
        beq t4, t3, done_write
        sd t2, 0(t5)
        addi t5, t5, 8
        addi t4, t4, 1
        j loop_write
done_write:   
	
        li t4, 0
        addi t5, t1, 0
loop_read:     
        beq t4, t3, done_read
        ld t6, 0(t5)
        addi t5, t5, 8
        addi t4, t4, 1
        j loop_read
done_read:      
	ret
	
