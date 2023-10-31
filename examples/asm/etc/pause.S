.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:


la a0, lock

spinlock:				# address of lock is in a0
	lr.w t0, (a0)		# read the lock
	bnez t0, retry	    # spin until free
	li   t1, 1          
	sc.w t0, t1, (a0)	# try to write a 1 to take lock
	bnez t0, retry	    # spin until successful
	ret				    # got the lock!
retry:				    # no lock yet
	pause				# pause hint to reduce spin power
	j spinlock			# try again


self_loop:
    j self_loop

.data
lock:   
    .word 1