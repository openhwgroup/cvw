            .option nopic
            .option norelax
            .option norvc

            .include "common.inc"
            .include "csr.inc"

            .align 8
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
            .attribute stack_align, 16
            
            PROC atpg_func
            # allocate 16 bytes on the stack
            addi sp, sp, -16

            # save s11
            sw s11, 4(sp)
            # save s10
            sw s10, 8(sp)

            # inizialize s11 to 0 for trap management
            mv s11, x0

            # Save return address
            la t1,RA
            sw ra, 0(t1)
            #mv t6, ra

            # call init_hash
            #atpg_init_hash

            # Save update_hash address
            #la a4, update_hash

            # Inizialize a0
            li a0, 0x0

            #init t2 for signature
            #addi t2, x0, 0x0

            # Disable interrupts
            disable_interrupts a3, a6
            
            # Change trap handler
            la t5, pmp_handler
            csrrw a5, mtvec, t5
            
            #la   t0, restore_pmp_regs
            #csrr t1, pmpcfg0
            #sw   t1, 0(t0)
            #csrr t2, pmpaddr0
            #sw   t2, 8(t0)
            #csrr t1, pmpaddr1
            #sw   t1, 16(t0)
            #csrr t2, pmpaddr2
            #sw   t2, 24(t0)
            #csrr t1, pmpaddr3
            #sw   t1, 32(t0)

            #init t2 for signature
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
            ##########################################
            ##              restore section         ##
            ##########################################
            # IMPORTANTE: Assicurati che questa etichetta sia allineata correttamente
            .align 2  # Allinea a 4 byte (2^2)
            .globl restore_section      # Esporta l'etichetta per renderla visibile ad altri file
            restore_section:            # Etichetta per tornare qui dopo un'eccezione ecall

            
            # Reset PMP configuration
            #la   t0, restore_pmp_regs
            #lw   t1, 0(t0)
            #csrw pmpcfg0, t1
            #lw   t3, 8(t0)
            #csrw pmpaddr0, t3
            #lw   t1, 16(t0)
            #csrw pmpaddr1, t1
            #lw   t3, 24(t0)
            #csrw pmpaddr2, t3
            #lw   t1, 32(t0)
            #csrw pmpaddr3, t1
            
            mv a0,t2
            mv a7,t2
            #call update_hash

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts - ripristina lo stato originale delle interruzioni
            restore_interrupts a3, a6
                
            # Exit routine
           # call finalize_hash


            lw s11,4(sp)
            lw s10,8(sp)

            addi sp, sp, 16
            # Restore return address
            lw ra, (RA)

            #return to caller
            jr ra 

            ENDP atpg_func


            .data

            RA:
            .long 0x0
            .space 8
            restore_pmp_regs:
            .space 32

            
            .end

################################################################################################################
################################################################################################################

#            .option nopic
#            .option norelax
#            .option norvc
#
#            .include "common.inc"
#            .include "csr.inc"
#
#            .section .PROGRAM_DATA_PMP, "awx"
#            .globl program_pmp_data_start
#            program_pmp_data_start:
#            .word 0xd10ca7e
#            .globl program_pmp_data_end
#            program_pmp_data_end:
#
#            .text
#            .attribute stack_align, 16
#            
#            PROC atpg_func
#            # allocate 16 bytes on the stack
#            addi sp, sp, -16
#
#            # save s11
#            sw s11, 4(sp)
#            # save s10
#            sw s10, 8(sp)
#
#            # inizialize s11 to 0 for trap management
#            mv s11, x0
#
#            # Save return address
#            la t1,RA
#            sw ra, 0(t1)
#            #mv t6, ra
#
#            # call init_hash
#            atpg_init_hash
#
#            # Save update_hash address
#            la a4, update_hash
#
#            # Inizialize a0
#            li a0, 0x0
#
#            #init t2 for signature
#            addi t2, x0, 0x0
#
#            # Disable interrupts
#            disable_interrupts a3, a6
#            
#            # Change trap handler
#            la t5, pmp_handler
#            csrrw a5, mtvec, t5
#            
#            la   t0, restore_pmp_regs
#            csrr t1, pmpcfg0
#            sw   t1, 0(t0)
#            csrr t2, pmpaddr0
#            sw   t2, 8(t0)
#            csrr t1, pmpaddr1
#            sw   t1, 16(t0)
#            csrr t2, pmpaddr2
#            sw   t2, 24(t0)
#            csrr t1, pmpaddr3
#            sw   t1, 32(t0)
#
#            #init t2 for signature
#            addi t2, x0, 0x0
#
#            #set all memory as rw-
#            #csrw pmpaddr0,t2
#            #li t1,-1
#            #csrw pmpaddr1,t1
#
#            la t0, program_pmp_data_start
#            csrw pmpaddr0,t0
#            la t1, program_pmp_data_end
#            csrw pmpaddr1,t1
#
#
#            # Configure PMP:
#            # [L][0][0][A][A][X][W][R]
#            # 7  6  5  4  3  2  1  0
#            # - A: 01 (TOR)
#            # With TOR mode, no lock:
#            # 0x08 = 0b00001000 :  ---
#            # 0x09 = 0b00001001 :  R--
#            # 0x0A = 0b00001010 :  -W-
#            # 0x0B = 0b00001011 :  RW-
#            # 0x0C = 0b00001100 :  --X
#            # 0x0D = 0b00001101 :  R-X
#            # 0x0E = 0b00001110 :  -WX
#            # 0x0F = 0b00001111 :  RWX
#            li t3, 0x0C     
#            csrw pmpcfg0, t3
#
#            # Switch to user mode properly:
#            # 1. Clear MPP field in mstatus (bits 12-11) to set it to user mode (0b00)
#            # 2. Set MPIE (bit 7) to enable interrupts after mret
#            # 3. Set up mepc with the address to continue execution
#            # 4. Execute mret to switch modes
#            
#            # Save the address where execution should continue after mode switch
#            la t3, user_mode_code
#            csrw mepc, t3
#            
#            # Leggi mstatus, cancella MPP (bits 12:11) e setta MPIE (bit7)
#            csrr t0, mstatus
#            li   t5, 0xFFFFE7FF         # mask = ~(0x1800)
#            and  t0, t0, t5             # clear MPP
#            ori  t0, t0, 0x80           # set MPIE
#            csrw mstatus, t0
#          
#            mret
#            .align 4
#
#          user_mode_code:
#        
#              li t3,0
#              li t4,0
#
#              li t0,0x23a8
#              lw t1,0(t0)
#              li t3,0x1e24386b
#              sw t3,0(t0)
#              lw t4,0(t0)
#
#              xor t3,t0,t4
#              add t2,t2,t0
#              add t2,t2,t4
#
#              sw  t1,0(t0)
#
#              #jalr t6,t0,0
#
#            
#
#            ecall     
#
#            ##########################################
#            ##              restore section         ##
#            ##########################################
#            # IMPORTANTE: Assicurati che questa etichetta sia allineata correttamente
#            .align 2  # Allinea a 4 byte (2^2)
#            .globl restore_section      # Esporta l'etichetta per renderla visibile ad altri file
#            restore_section:            # Etichetta per tornare qui dopo un'eccezione ecall
#
#            
#            # Reset PMP configuration
#            la   t0, restore_pmp_regs
#            lw   t1, 0(t0)
#            csrw pmpcfg0, t1
#            lw   t3, 8(t0)
#            csrw pmpaddr0, t3
#            lw   t1, 16(t0)
#            csrw pmpaddr1, t1
#            lw   t3, 24(t0)
#            csrw pmpaddr2, t3
#            lw   t1, 32(t0)
#            csrw pmpaddr3, t1
#            
#            mv a0,t2
#            mv a7,t2
#            call update_hash
#
#            # Restore old trap handler
#            csrw mtvec, a5
#            # Restore interrupts - ripristina lo stato originale delle interruzioni
#            restore_interrupts a3, a6
#                
#            # Exit routine
#            call finalize_hash
#
#
#            lw s11,4(sp)
#            lw s10,8(sp)
#
#            addi sp, sp, 16
#            # Restore return address
#            lw ra, (RA)
#
#            #return to caller
#            jr ra 
#
#            ENDP atpg_func
#
#
#            .data
#
#            RA:
#            .long 0x0
#            .space 8
#            restore_pmp_regs:
#            .space 32
#
#            
#            .end
#        