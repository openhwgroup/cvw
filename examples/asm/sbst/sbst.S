

	.align 4
	.section .PROGRAM_DATA_PMP, "awx"
	.globl program_pmp_data_start
	program_pmp_data_start:
	li t2,0xd10
	nop
	nop
	nop
	nop
	nop
	jr t6   # jump to ra
	.globl dati_dio
	dati_dio:
	.word 0xd10ca7e
	.globl program_pmp_data_end
	program_pmp_data_end:


.text
.global test1
.type test1, @function

test1:
	# ABI prologue
	addi sp, sp, -112     # allocate 112 bytes on the stack
	sw ra, 104(sp)        # save return address
	sw s0, 96(sp)         # save callee-saved registers
	sw s1, 88(sp)
	sw s2, 80(sp)
	sw s3, 72(sp)
	sw s4, 64(sp)
	sw s5, 56(sp)
	sw s6, 48(sp)
	sw s7, 40(sp)
	sw s8, 32(sp)
	sw s9, 24(sp)
	sw s10, 16(sp)
	sw s11, 8(sp)
	addi s0, sp, 112     # set up s0 to point to start of stack frame


    # You can write your code here 

#############################################################################

            addi t2, x0, 0x0


            la   t0, program_pmp_data_start
            srli t0, t0, 2             # pmpaddr expects address >> 2
            csrw pmpaddr0, t0          # bottom = pmpaddr0

            la   t1, program_pmp_data_end
            srli t1, t1, 2
            csrw pmpaddr1, t1          # top = pmpaddr1
            
            # Configure PMP:
            # [L][0][0][A][A][X][W][R]
            # 7  6  5  4  3  2  1  0
            # - A: 01 (TOR)
            # With TOR mode, no lock:
            # 0x08 = 0b00001000 :  ---
            # 0x09 = 0b00001001 :  R--
            # 0x0A = 0b00001010 :  -W-
            # 0x0B = 0b00001011 :  RW-
            # 0x0C = 0b00001100 :  --X
            # 0x0D = 0b00001101 :  R-X
            # 0x0E = 0b00001110 :  -WX
            # 0x0F = 0b00001111 :  RWX
            li   t3, 0x0a
            slli t3, t3, 8
            csrw pmpcfg0, t3

            csrr t4, pmpcfg0
            csrr t5, pmpaddr0
            csrr t6, pmpaddr1

            # Switch to user mode properly:
            # 1. Clear MPP field in mstatus (bits 12-11) to set it to user mode (0b00)
            # 2. Set MPIE (bit 7) to enable interrupts after mret
            # 3. Set up mepc with the address to continue execution
            # 4. Execute mret to switch modes
            
            # Save the address where execution should continue after mode switch
            la t3, user_mode_code
            csrw mepc, t3
            

            la t0,dati_dio
            lw t2, 0(t0)
            la t0,program_pmp_data_start
            li t2,0xdeb0
            jalr t6,t0,0
            
            # Leggi mstatus, cancella MPP (bits 12:11) 
            csrr t0, mstatus
            li   t5, 0xFFFFE777         # mask = ~(0x1800)
            and  t0, t0, t5             # clear MPP
            #ori  t0, t0, 0x80           # set MPIE
            csrw mstatus, t0

            #j user_mode_code
          
            mret
            j .
           

          user_mode_code:
               li t2,0xdeb1
               li t3,0
               li t4,0
 
   
             ##xor t3,t0,t4
             ##add t2,t2,t3
 
 
               la t0,program_pmp_data_start
               #lw t1,0(t0)
               #li t3,0x2d4
               #sw t3,0(t0)
               #lw t4,0(t0)
 
               li t2,0xdeb2
               jalr t6,t0,0
 
               ecall     
              j .



#############################################################################
.globl restore_section  
restore_section:
    li a0, 0xCAFECAFE    # return value


    # ABI epilogue
	lw s11, 8(sp)        # restore callee-saved registers
	lw s10, 16(sp)
	lw s9, 24(sp)
	lw s8, 32(sp)
	lw s7, 40(sp)
	lw s6, 48(sp)
	lw s5, 56(sp)
	lw s4, 64(sp)
	lw s3, 72(sp)
	lw s2, 80(sp)
	lw s1, 88(sp)
	lw s0, 96(sp)
	lw ra, 104(sp)       # restore return address
	addi sp, sp, 112     # deallocate stack space
	jr ra                # return to caller



# READ/WRITE VARIABLES

.section .data

# READ-ONLY VARIABLES

.section .rodata