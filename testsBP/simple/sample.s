.section .text	
.global simple_csrbr_test
.type simple_csrbr_test, @function

simple_csrbr_test:	

	# step 1 enable the performance counters
	# by default the hardware enables all performance counters
	# however we will eventually want to manually enable incase
	# some other code disables them

	# br count is counter 5
	# br mp count is counter 4
	li t0, 0x30
	
	csrrc x0, 0x320, t0  # clear bits 4 and 5 of inhibit register.

	# step 2 read performance counters into general purpose registers

	csrrw t2, 0xB05, x0 # t2 = BR COUNT (perf count 5)
	csrrw t3, 0xB04, x0 # t3 = BRMP COUNT (perf count 4)

	# step 3 simple loop to show the counters are updated.
	li t0, 0   # this is the loop counter
	li t1, 100 # this is the loop end condition

	# for(t1 = 0; t1 < t0; t1++);

loop:	
	addi t0, t0, 1
	blt t0, t1, loop

loop_done:	
	
	# step 2 read performance counters into general purpose registers

	csrrw t4, 0xB05, x0 # t4 = BR COUNT (perf count 5)
	csrrw t5, 0xB04, x0 # t5 = BRMP COUNT (perf count 4)

	sub t2, t4, t2 # this is the number of branch instructions committed.
	sub t3, t5, t3 # this is the number of branch mispredictions committed.

	# now check if the branch count equals 100 and if the branch
	bne t4, t2, fail
	li  t5, 3
	bne t3, t5, fail
	
pass:
	li a0, 0
done:
	li t0, 0x30
	csrrs x0, 0x320, t0  # set bits 4 and 5
	ret

fail:
	li a0, -1
	j done

.data 
sample_data:
.int 0	
