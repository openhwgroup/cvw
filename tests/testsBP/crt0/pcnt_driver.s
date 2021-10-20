.section .text
.global enablePerfCnt
.type enablePerfCnt, @function
enablePerfCnt:
	# a0 is the mask
	csrrc x0, 0x320, a0 # clear bits to disable inhibit register
	ret

.section .text
.global disablePerfCnt
.type disablePerfCnt, @function
disablePerfCnt:
	# a0 is the mask
	csrrs x0, 0x320, a0 # set bits to disable inhibit register
	ret
	

.section .text
.global readPerfCnt
.type readPerfCnt, @function
readPerfCnt:
	# a0 is the counter to read
	# a1 is the flag to clear the register 
	# return the value of the counter in a0

	li t0, 0xB
	# if the counter number is greater than the number
	# of counters return a -1
	bge a0, t0, readPerfCntError

	# pointers are 8 bytes so shift a0 by 8
	slli a0, a0, 3
	li t1, 1
	beq a1, t1, readPerfCntClear

	la t0, csrTable
	j skip

readPerfCntClear:	
	la t0, csrTable_clear	

skip:	
	add t0, t0, a0
	ld t0, 0(t0)
	jr t0

csrCycle:
	csrrs a0, 0xB00, x0
	ret
csrNull:
	li a0, -1
	ret
csrInstrCount:
	csrrs a0, 0xB02, x0
	ret
csrLoadStallCount:
	csrrs a0, 0xB03, x0
	ret
csrBPWrongCount:
	csrrs a0, 0xB04, x0
	ret
csrBPCount:
	csrrs a0, 0xB05, x0
	ret
csrBTBWrongCount:
	csrrs a0, 0xB06, x0
	ret
csrNonBRCFICount:
	csrrs a0, 0xB07, x0
	ret
csrRasWrongCount:
	csrrs a0, 0xB08, x0
	ret
csrReturnCount:
	csrrs a0, 0xB09, x0
	ret
csrBTBClassWrongCount:
	csrrs a0, 0xB0A, x0
	ret
	
csrCycle_clear:
	csrrw a0, 0xB00, x0
	ret
csrNull_clear:
	li a0, -1
	ret
csrInstrCount_clear:
	csrrw a0, 0xB02, x0
	ret
csrLoadStallCount_clear:
	csrrw a0, 0xB03, x0
	ret
csrBPWrongCount_clear:
	csrrw a0, 0xB04, x0
	ret
csrBPCount_clear:
	csrrw a0, 0xB05, x0
	ret
csrBTBWrongCount_clear:
	csrrw a0, 0xB06, x0
	ret
csrNonBRCFICount_clear:
	csrrw a0, 0xB07, x0
	ret
csrRasWrongCount_clear:
	csrrw a0, 0xB08, x0
	ret
csrReturnCount_clear:
	csrrw a0, 0xB09, x0
	ret
csrBTBClassWrongCount_clear:
	csrrw a0, 0xB0A, x0
	ret

readPerfCntError:
	li a0, -1
	ret
	
	
.section .data
.align 3
csrTable:	
.8byte csrCycle			#0
.8byte csrNull			#1
.8byte csrInstrCount		#2
.8byte csrLoadStallCount	#3
.8byte csrBPWrongCount		#4
.8byte csrBPCount		#5
.8byte csrBTBWrongCount		#6
.8byte csrNonBRCFICount		#7
.8byte csrRasWrongCount		#8
.8byte csrReturnCount		#9
.8byte csrBTBClassWrongCount	#A

csrTable_clear:	
.8byte csrCycle_clear			#0
.8byte csrNull_clear			#1
.8byte csrInstrCount_clear		#2
.8byte csrLoadStallCount_clear		#3
.8byte csrBPWrongCount_clear		#4
.8byte csrBPCount_clear			#5
.8byte csrBTBWrongCount_clear		#6
.8byte csrNonBRCFICount_clear		#7
.8byte csrRasWrongCount_clear		#8
.8byte csrReturnCount_clear		#9
.8byte csrBTBClassWrongCount_clear	#A

