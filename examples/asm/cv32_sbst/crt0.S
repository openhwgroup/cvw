.section .vectors, "ax"
1:
    wfi
    j 1b


.section .text.start
.global _start
_start:

    # Initialize registers for simulation
	mv x1, x0
	mv x2, x0
	mv x3, x0
	mv x4, x0
	mv x5, x0
	mv x6, x0
	mv x7, x0
	mv x8, x0
	mv x9, x0
	mv x10, x0
	mv x11, x0
	mv x12, x0
	mv x13, x0
	mv x14, x0
	mv x15, x0
	mv x16, x0
	mv x17, x0
	mv x18, x0
	mv x19, x0
	mv x20, x0
	mv x21, x0
	mv x22, x0
	mv x23, x0
	mv x24, x0
	mv x25, x0
	mv x26, x0
	mv x27, x0
	mv x28, x0
	mv x29, x0
	mv x30, x0
	mv x31, x0

    # Load global pointer
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    # Initialize stack pointer
	la sp, _sp

	# Imposta i bit necessari:
    # - MPP[12:11] = 11 (M-mode) 
    # - MPIE[7] = 1 (abilita interrupt dopo mret, se necessario)
    # - MIE[3] = 0 (disabilita interrupt per ora)
    
    li   t0, 0x00001800       # MPP=11 (bit 12-11), MPIE=1 (bit 7)
    csrw mstatus, t0

	csrw mcause, 0x3

    # Set handler address (see direct mode in mtvec)
	la t0, pmp_handler
	csrw mtvec, t0

    # Enable fpu registers
	li t0, 0x2000
	csrs mstatus, t0

.macro init_section dst:req dst_end:req src:req
    la a0, \dst
	la a2, \dst_end
	la a1, \src
    sub a2, a2, a0
	call evi_memcpy
.endm 

.macro clear_section dst:req dst_end:req fill=0x0
    la a0, \dst
	la a2, \dst_end
	sub a2, a2, a0
	li a1, \fill
	call evi_memset
.endm 

    # # Copy initialized sections to RAM
    # init_section __TEST_DATA_START, __TEST_DATA_END, __ROM_TEST_DATA_START
    # init_section __DATA_BEGIN__, __DATA_END__, __ROM_DATA_BEGIN__
    # init_section __SDATA_BEGIN__, __SDATA_END__, __ROM_SDATA_BEGIN__

    # Clear bss segment
	clear_section __bss_start, __bss_end

    # Call main
	mv a0, x0
	mv a1, x0
	mv a2, x0
	call main
	tail exit

.end
