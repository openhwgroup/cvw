
            .option nopic
            .option relax

            .include "common.inc"
            .include "csr.inc"


            .attribute stack_align, 16

            .text


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
            atpg_init_hash

            # Save update_hash address
            la a4, update_hash

            # Inizialize a0
            li a0, 0x0
            #init t2 for signature
            addi t2, x0, 0x0
            
            

            
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip

            # Change trap handler
            la t5, csr_trap_handler 
            csrrw a5, mtvec, t5
            csrrw   t1,mcounteren, x0
            la      t3,CNTEN_SAVE
            lw      t1,0(t3)
            li      t1, 0x8
            csrrw   t1,mcounteren, t1
            add     t2, t2, t1
            csrr    t1,mcountinhibit
            la      t3,CNT_INIB_SAVE
            lw      t1,0(t3)
            csrrw   t1,mcountinhibit, x0
            la      t3,MPHCNT3_SAVE
            lw      t1,0(t3)
            csrrw   t1,mhpmevent3, x0
            la      t3,MPHEV3_SAVE
            lw      t1,0(t3)


            csrw    mcountinhibit, x0
            csrwi   mhpmevent3, 0x1
            li      t1,0x80000000
            csrrw   t3,mhpmcounter3, t1
            li      t1,0xffffffff
            csrw    mcountinhibit,t1
            csrr    t1,mepc
            add     t2, t2, t1
            csrwi   mcountinhibit,0x0
            csrr    t3,mhpmcounter3
            add     t2, t2, t3

            #restore 
            la      t3,CNTEN_SAVE
            lw      t1,0(t3)
            csrw    mhpmcounter3, t1
            la      t3,CNT_INIB_SAVE
            lw      t1,0(t3)
            la      t3,MPHCNT3_SAVE
            lw      t1,0(t3)
            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
            
            mv a7, t2
            call update_hash
            
    
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x9a1f6a4
            csrrw   t0, 0x968, t4 #saved in t0
            csrr    t3, 0x968
            add     t2, t2, t3
            csrrwi  t3, 0x968, 0b01101
            add     t2, t2, t3
            csrrw   t1, 0x968, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x9e25ae6
            csrrw   t0, 0xdb2, t4 #saved in t0
            csrr    t3, 0xdb2
            add     t2, t2, t3
            csrrwi  t3, 0xdb2, 0b00101
            add     t2, t2, t3
            csrrw   t1, 0xdb2, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x7126842
            csrrw   t0, 0x102, t4 #saved in t0
            csrr    t3, 0x102
            add     t2, t2, t3
            csrrwi  t3, 0x102, 0b10011
            add     t2, t2, t3
            csrrw   t1, 0x102, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xc24a2de
            csrrw   t0, 0x8d7, t4 #saved in t0
            csrr    t3, 0x8d7
            add     t2, t2, t3
            csrrwi  t3, 0x8d7, 0b10111
            add     t2, t2, t3
            csrrw   t1, 0x8d7, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x8b75c22
            csrrw   t0, 0x4a8, t4 #saved in t0
            csrr    t3, 0x4a8
            add     t2, t2, t3
            csrrwi  t3, 0x4a8, 0b00100
            add     t2, t2, t3
            csrrw   t1, 0x4a8, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x6aaddd6
            csrrw   t0, 0x1a8, t4 #saved in t0
            csrr    t3, 0x1a8
            add     t2, t2, t3
            csrrwi  t3, 0x1a8, 0b11000
            add     t2, t2, t3
            csrrw   t1, 0x1a8, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x7677fcd
            csrrw   t0, 0x2a9, t4 #saved in t0
            csrr    t3, 0x2a9
            add     t2, t2, t3
            csrrwi  t3, 0x2a9, 0b11111
            add     t2, t2, t3
            csrrw   t1, 0x2a9, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x88f813d
            csrrw   t0, 0x0b9, t4 #saved in t0
            csrr    t3, 0x0b9
            add     t2, t2, t3
            csrrwi  t3, 0x0b9, 0b01010
            add     t2, t2, t3
            csrrw   t1, 0x0b9, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xc4bc861
            csrrw   t0, 0xf51, t4 #saved in t0
            csrr    t3, 0xf51
            add     t2, t2, t3
            csrrwi  t3, 0xf51, 0b01110
            add     t2, t2, t3
            csrrw   t1, 0xf51, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x035dd2b
            csrrw   t0, 0xb97, t4 #saved in t0
            csrr    t3, 0xb97
            add     t2, t2, t3
            csrrwi  t3, 0xb97, 0b00011
            add     t2, t2, t3
            csrrw   t1, 0xb97, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xb4b5b88
            csrrw   t0, 0xe95, t4 #saved in t0
            csrr    t3, 0xe95
            add     t2, t2, t3
            csrrwi  t3, 0xe95, 0b10010
            add     t2, t2, t3
            csrrw   t1, 0xe95, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x9bac006
            csrrw   t0, 0xe70, t4 #saved in t0
            csrr    t3, 0xe70
            add     t2, t2, t3
            csrrwi  t3, 0xe70, 0b11011
            add     t2, t2, t3
            csrrw   t1, 0xe70, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x371ee96
            csrrw   t0, 0x230, t4 #saved in t0
            csrr    t3, 0x230
            add     t2, t2, t3
            csrrwi  t3, 0x230, 0b01001
            add     t2, t2, t3
            csrrw   t1, 0x230, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xefab056
            csrrw   t0, 0xd4f, t4 #saved in t0
            csrr    t3, 0xd4f
            add     t2, t2, t3
            csrrwi  t3, 0xd4f, 0b00010
            add     t2, t2, t3
            csrrw   t1, 0xd4f, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x50c7803
            csrrw   t0, 0x018, t4 #saved in t0
            csrr    t3, 0x018
            add     t2, t2, t3
            csrrwi  t3, 0x018, 0b00001
            add     t2, t2, t3
            csrrw   t1, 0x018, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xabbfddd
            csrrw   t0, 0xe7a, t4 #saved in t0
            csrr    t3, 0xe7a
            add     t2, t2, t3
            csrrwi  t3, 0xe7a, 0b01110
            add     t2, t2, t3
            csrrw   t1, 0xe7a, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x2ac5d5f
            csrrw   t0, 0xd11, t4 #saved in t0
            csrr    t3, 0xd11
            add     t2, t2, t3
            csrrwi  t3, 0xd11, 0b00001
            add     t2, t2, t3
            csrrw   t1, 0xd11, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x522e112
            csrrw   t0, 0x7df, t4 #saved in t0
            csrr    t3, 0x7df
            add     t2, t2, t3
            csrrwi  t3, 0x7df, 0b00111
            add     t2, t2, t3
            csrrw   t1, 0x7df, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x6d1f299
            csrrw   t0, 0xc1e, t4 #saved in t0
            csrr    t3, 0xc1e
            add     t2, t2, t3
            csrrwi  t3, 0xc1e, 0b01101
            add     t2, t2, t3
            csrrw   t1, 0xc1e, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x51661cf
            csrrw   t0, 0xc79, t4 #saved in t0
            csrr    t3, 0xc79
            add     t2, t2, t3
            csrrwi  t3, 0xc79, 0b11100
            add     t2, t2, t3
            csrrw   t1, 0xc79, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x2de359b
            csrrw   t0, 0x6e6, t4 #saved in t0
            csrr    t3, 0x6e6
            add     t2, t2, t3
            csrrwi  t3, 0x6e6, 0b00011
            add     t2, t2, t3
            csrrw   t1, 0x6e6, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x95a0269
            csrrw   t0, 0xc9c, t4 #saved in t0
            csrr    t3, 0xc9c
            add     t2, t2, t3
            csrrwi  t3, 0xc9c, 0b10001
            add     t2, t2, t3
            csrrw   t1, 0xc9c, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x94602a4
            csrrw   t0, 0x5da, t4 #saved in t0
            csrr    t3, 0x5da
            add     t2, t2, t3
            csrrwi  t3, 0x5da, 0b11000
            add     t2, t2, t3
            csrrw   t1, 0x5da, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xf47192c
            csrrw   t0, 0xc32, t4 #saved in t0
            csrr    t3, 0xc32
            add     t2, t2, t3
            csrrwi  t3, 0xc32, 0b00101
            add     t2, t2, t3
            csrrw   t1, 0xc32, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xf28bd71
            csrrw   t0, 0x0af, t4 #saved in t0
            csrr    t3, 0x0af
            add     t2, t2, t3
            csrrwi  t3, 0x0af, 0b00011
            add     t2, t2, t3
            csrrw   t1, 0x0af, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xcb00391
            csrrw   t0, 0x805, t4 #saved in t0
            csrr    t3, 0x805
            add     t2, t2, t3
            csrrwi  t3, 0x805, 0b01001
            add     t2, t2, t3
            csrrw   t1, 0x805, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x544cfc9
            csrrw   t0, 0x337, t4 #saved in t0
            csrr    t3, 0x337
            add     t2, t2, t3
            csrrwi  t3, 0x337, 0b10101
            add     t2, t2, t3
            csrrw   t1, 0x337, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x512b403
            csrrw   t0, 0xc0c, t4 #saved in t0
            csrr    t3, 0xc0c
            add     t2, t2, t3
            csrrwi  t3, 0xc0c, 0b11001
            add     t2, t2, t3
            csrrw   t1, 0xc0c, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x6315ef6
            csrrw   t0, 0xc00, t4 #saved in t0
            csrr    t3, 0xc00
            add     t2, t2, t3
            csrrwi  t3, 0xc00, 0b11110
            add     t2, t2, t3
            csrrw   t1, 0xc00, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x96d8432
            csrrw   t0, 0x72f, t4 #saved in t0
            csrr    t3, 0x72f
            add     t2, t2, t3
            csrrwi  t3, 0x72f, 0b10000
            add     t2, t2, t3
            csrrw   t1, 0x72f, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x28d1184
            csrrw   t0, 0x438, t4 #saved in t0
            csrr    t3, 0x438
            add     t2, t2, t3
            csrrwi  t3, 0x438, 0b11100
            add     t2, t2, t3
            csrrw   t1, 0x438, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x9171b2a
            csrrw   t0, 0x507, t4 #saved in t0
            csrr    t3, 0x507
            add     t2, t2, t3
            csrrwi  t3, 0x507, 0b10000
            add     t2, t2, t3
            csrrw   t1, 0x507, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xfbc5acd
            csrrw   t0, 0xbf0, t4 #saved in t0
            csrr    t3, 0xbf0
            add     t2, t2, t3
            csrrwi  t3, 0xbf0, 0b11100
            add     t2, t2, t3
            csrrw   t1, 0xbf0, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x130d756
            csrrw   t0, 0x285, t4 #saved in t0
            csrr    t3, 0x285
            add     t2, t2, t3
            csrrwi  t3, 0x285, 0b11001
            add     t2, t2, t3
            csrrw   t1, 0x285, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xf6be35f
            csrrw   t0, 0xd6d, t4 #saved in t0
            csrr    t3, 0xd6d
            add     t2, t2, t3
            csrrwi  t3, 0xd6d, 0b10000
            add     t2, t2, t3
            csrrw   t1, 0xd6d, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xfc179a0
            csrrw   t0, 0x7f4, t4 #saved in t0
            csrr    t3, 0x7f4
            add     t2, t2, t3
            csrrwi  t3, 0x7f4, 0b01011
            add     t2, t2, t3
            csrrw   t1, 0x7f4, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x537ab99
            csrrw   t0, 0xaea, t4 #saved in t0
            csrr    t3, 0xaea
            add     t2, t2, t3
            csrrwi  t3, 0xaea, 0b01000
            add     t2, t2, t3
            csrrw   t1, 0xaea, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x379d6c7
            csrrw   t0, 0x8ca, t4 #saved in t0
            csrr    t3, 0x8ca
            add     t2, t2, t3
            csrrwi  t3, 0x8ca, 0b10100
            add     t2, t2, t3
            csrrw   t1, 0x8ca, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xd725a1e
            csrrw   t0, 0x565, t4 #saved in t0
            csrr    t3, 0x565
            add     t2, t2, t3
            csrrwi  t3, 0x565, 0b11111
            add     t2, t2, t3
            csrrw   t1, 0x565, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x41cd8dd
            csrrw   t0, 0x4b5, t4 #saved in t0
            csrr    t3, 0x4b5
            add     t2, t2, t3
            csrrwi  t3, 0x4b5, 0b00011
            add     t2, t2, t3
            csrrw   t1, 0x4b5, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x48df554
            csrrw   t0, 0xca8, t4 #saved in t0
            csrr    t3, 0xca8
            add     t2, t2, t3
            csrrwi  t3, 0xca8, 0b11111
            add     t2, t2, t3
            csrrw   t1, 0xca8, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xda1ff5e
            csrrw   t0, 0x328, t4 #saved in t0
            csrr    t3, 0x328
            add     t2, t2, t3
            csrrwi  t3, 0x328, 0b01111
            add     t2, t2, t3
            csrrw   t1, 0x328, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x986848c
            csrrw   t0, 0xcbc, t4 #saved in t0
            csrr    t3, 0xcbc
            add     t2, t2, t3
            csrrwi  t3, 0xcbc, 0b11001
            add     t2, t2, t3
            csrrw   t1, 0xcbc, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xe108be4
            csrrw   t0, 0xdf4, t4 #saved in t0
            csrr    t3, 0xdf4
            add     t2, t2, t3
            csrrwi  t3, 0xdf4, 0b11011
            add     t2, t2, t3
            csrrw   t1, 0xdf4, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x07a83e8
            csrrw   t0, 0x0d6, t4 #saved in t0
            csrr    t3, 0x0d6
            add     t2, t2, t3
            csrrwi  t3, 0x0d6, 0b11110
            add     t2, t2, t3
            csrrw   t1, 0x0d6, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xb922323
            csrrw   t0, 0x65c, t4 #saved in t0
            csrr    t3, 0x65c
            add     t2, t2, t3
            csrrwi  t3, 0x65c, 0b01100
            add     t2, t2, t3
            csrrw   t1, 0x65c, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x7b94177
            csrrw   t0, 0x878, t4 #saved in t0
            csrr    t3, 0x878
            add     t2, t2, t3
            csrrwi  t3, 0x878, 0b10110
            add     t2, t2, t3
            csrrw   t1, 0x878, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x2ffc054
            csrrw   t0, 0xdbe, t4 #saved in t0
            csrr    t3, 0xdbe
            add     t2, t2, t3
            csrrwi  t3, 0xdbe, 0b01000
            add     t2, t2, t3
            csrrw   t1, 0xdbe, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x415d8d3
            csrrw   t0, 0xdcb, t4 #saved in t0
            csrr    t3, 0xdcb
            add     t2, t2, t3
            csrrwi  t3, 0xdcb, 0b00101
            add     t2, t2, t3
            csrrw   t1, 0xdcb, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xe16ea46
            csrrw   t0, 0xc46, t4 #saved in t0
            csrr    t3, 0xc46
            add     t2, t2, t3
            csrrwi  t3, 0xc46, 0b00011
            add     t2, t2, t3
            csrrw   t1, 0xc46, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x3fe21bd
            csrrw   t0, 0x0c3, t4 #saved in t0
            csrr    t3, 0x0c3
            add     t2, t2, t3
            csrrwi  t3, 0x0c3, 0b01100
            add     t2, t2, t3
            csrrw   t1, 0x0c3, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xc1156ab
            csrrw   t0, 0x892, t4 #saved in t0
            csrr    t3, 0x892
            add     t2, t2, t3
            csrrwi  t3, 0x892, 0b00100
            add     t2, t2, t3
            csrrw   t1, 0x892, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x45aa50d
            csrrw   t0, 0x37d, t4 #saved in t0
            csrr    t3, 0x37d
            add     t2, t2, t3
            csrrwi  t3, 0x37d, 0b11000
            add     t2, t2, t3
            csrrw   t1, 0x37d, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xb298762
            csrrw   t0, 0xad5, t4 #saved in t0
            csrr    t3, 0xad5
            add     t2, t2, t3
            csrrwi  t3, 0xad5, 0b11011
            add     t2, t2, t3
            csrrw   t1, 0xad5, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xf4377a3
            csrrw   t0, 0xfd2, t4 #saved in t0
            csrr    t3, 0xfd2
            add     t2, t2, t3
            csrrwi  t3, 0xfd2, 0b10001
            add     t2, t2, t3
            csrrw   t1, 0xfd2, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x3619a5e
            csrrw   t0, 0x2a2, t4 #saved in t0
            csrr    t3, 0x2a2
            add     t2, t2, t3
            csrrwi  t3, 0x2a2, 0b01010
            add     t2, t2, t3
            csrrw   t1, 0x2a2, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xfe757b0
            csrrw   t0, 0xab7, t4 #saved in t0
            csrr    t3, 0xab7
            add     t2, t2, t3
            csrrwi  t3, 0xab7, 0b11100
            add     t2, t2, t3
            csrrw   t1, 0xab7, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x03c063a
            csrrw   t0, 0x19e, t4 #saved in t0
            csrr    t3, 0x19e
            add     t2, t2, t3
            csrrwi  t3, 0x19e, 0b01000
            add     t2, t2, t3
            csrrw   t1, 0x19e, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xa59a16e
            csrrw   t0, 0xcc3, t4 #saved in t0
            csrr    t3, 0xcc3
            add     t2, t2, t3
            csrrwi  t3, 0xcc3, 0b01110
            add     t2, t2, t3
            csrrw   t1, 0xcc3, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x434733b
            csrrw   t0, 0x7e2, t4 #saved in t0
            csrr    t3, 0x7e2
            add     t2, t2, t3
            csrrwi  t3, 0x7e2, 0b11000
            add     t2, t2, t3
            csrrw   t1, 0x7e2, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x3e339cc
            csrrw   t0, 0xb40, t4 #saved in t0
            csrr    t3, 0xb40
            add     t2, t2, t3
            csrrwi  t3, 0xb40, 0b01110
            add     t2, t2, t3
            csrrw   t1, 0xb40, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x5281bd4
            csrrw   t0, 0xe00, t4 #saved in t0
            csrr    t3, 0xe00
            add     t2, t2, t3
            csrrwi  t3, 0xe00, 0b00011
            add     t2, t2, t3
            csrrw   t1, 0xe00, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x52dfb13
            csrrw   t0, 0x12c, t4 #saved in t0
            csrr    t3, 0x12c
            add     t2, t2, t3
            csrrwi  t3, 0x12c, 0b11010
            add     t2, t2, t3
            csrrw   t1, 0x12c, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x75d15bf
            csrrw   t0, 0x84e, t4 #saved in t0
            csrr    t3, 0x84e
            add     t2, t2, t3
            csrrwi  t3, 0x84e, 0b01001
            add     t2, t2, t3
            csrrw   t1, 0x84e, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x1954228
            csrrw   t0, 0x9e5, t4 #saved in t0
            csrr    t3, 0x9e5
            add     t2, t2, t3
            csrrwi  t3, 0x9e5, 0b10000
            add     t2, t2, t3
            csrrw   t1, 0x9e5, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xfb36575
            csrrw   t0, 0x60d, t4 #saved in t0
            csrr    t3, 0x60d
            add     t2, t2, t3
            csrrwi  t3, 0x60d, 0b01000
            add     t2, t2, t3
            csrrw   t1, 0x60d, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x1594a8b
            csrrw   t0, 0xbf4, t4 #saved in t0
            csrr    t3, 0xbf4
            add     t2, t2, t3
            csrrwi  t3, 0xbf4, 0b00011
            add     t2, t2, t3
            csrrw   t1, 0xbf4, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x1a24226
            csrrw   t0, 0x68e, t4 #saved in t0
            csrr    t3, 0x68e
            add     t2, t2, t3
            csrrwi  t3, 0x68e, 0b00010
            add     t2, t2, t3
            csrrw   t1, 0x68e, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x93ad28e
            csrrw   t0, 0x90f, t4 #saved in t0
            csrr    t3, 0x90f
            add     t2, t2, t3
            csrrwi  t3, 0x90f, 0b10100
            add     t2, t2, t3
            csrrw   t1, 0x90f, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xa4d7e17
            csrrw   t0, 0xb89, t4 #saved in t0
            csrr    t3, 0xb89
            add     t2, t2, t3
            csrrwi  t3, 0xb89, 0b01001
            add     t2, t2, t3
            csrrw   t1, 0xb89, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x8863227
            csrrw   t0, 0x170, t4 #saved in t0
            csrr    t3, 0x170
            add     t2, t2, t3
            csrrwi  t3, 0x170, 0b10001
            add     t2, t2, t3
            csrrw   t1, 0x170, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xa292b17
            csrrw   t0, 0xca4, t4 #saved in t0
            csrr    t3, 0xca4
            add     t2, t2, t3
            csrrwi  t3, 0xca4, 0b01100
            add     t2, t2, t3
            csrrw   t1, 0xca4, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x76a48fb
            csrrw   t0, 0x91e, t4 #saved in t0
            csrr    t3, 0x91e
            add     t2, t2, t3
            csrrwi  t3, 0x91e, 0b01100
            add     t2, t2, t3
            csrrw   t1, 0x91e, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xebafbac
            csrrw   t0, 0x508, t4 #saved in t0
            csrr    t3, 0x508
            add     t2, t2, t3
            csrrwi  t3, 0x508, 0b00101
            add     t2, t2, t3
            csrrw   t1, 0x508, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x398e52b
            csrrw   t0, 0x609, t4 #saved in t0
            csrr    t3, 0x609
            add     t2, t2, t3
            csrrwi  t3, 0x609, 0b01110
            add     t2, t2, t3
            csrrw   t1, 0x609, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x65db5a4
            csrrw   t0, 0x7be, t4 #saved in t0
            csrr    t3, 0x7be
            add     t2, t2, t3
            csrrwi  t3, 0x7be, 0b11011
            add     t2, t2, t3
            csrrw   t1, 0x7be, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x12c97b8
            csrrw   t0, 0x905, t4 #saved in t0
            csrr    t3, 0x905
            add     t2, t2, t3
            csrrwi  t3, 0x905, 0b01011
            add     t2, t2, t3
            csrrw   t1, 0x905, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x7e1d90c
            csrrw   t0, 0x249, t4 #saved in t0
            csrr    t3, 0x249
            add     t2, t2, t3
            csrrwi  t3, 0x249, 0b11101
            add     t2, t2, t3
            csrrw   t1, 0x249, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x04d7972
            csrrw   t0, 0xadc, t4 #saved in t0
            csrr    t3, 0xadc
            add     t2, t2, t3
            csrrwi  t3, 0xadc, 0b00000
            add     t2, t2, t3
            csrrw   t1, 0xadc, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x0006813
            csrrw   t0, 0x31b, t4 #saved in t0
            csrr    t3, 0x31b
            add     t2, t2, t3
            csrrwi  t3, 0x31b, 0b10110
            add     t2, t2, t3
            csrrw   t1, 0x31b, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x12daeaa
            csrrw   t0, 0x132, t4 #saved in t0
            csrr    t3, 0x132
            add     t2, t2, t3
            csrrwi  t3, 0x132, 0b10111
            add     t2, t2, t3
            csrrw   t1, 0x132, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xedf4c5a
            csrrw   t0, 0x549, t4 #saved in t0
            csrr    t3, 0x549
            add     t2, t2, t3
            csrrwi  t3, 0x549, 0b11110
            add     t2, t2, t3
            csrrw   t1, 0x549, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xe0b557d
            csrrw   t0, 0xa15, t4 #saved in t0
            csrr    t3, 0xa15
            add     t2, t2, t3
            csrrwi  t3, 0xa15, 0b11000
            add     t2, t2, t3
            csrrw   t1, 0xa15, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x883be7e
            csrrw   t0, 0xfd9, t4 #saved in t0
            csrr    t3, 0xfd9
            add     t2, t2, t3
            csrrwi  t3, 0xfd9, 0b11001
            add     t2, t2, t3
            csrrw   t1, 0xfd9, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x4d2608c
            csrrw   t0, 0x233, t4 #saved in t0
            csrr    t3, 0x233
            add     t2, t2, t3
            csrrwi  t3, 0x233, 0b11011
            add     t2, t2, t3
            csrrw   t1, 0x233, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x2cce091
            csrrw   t0, 0xca9, t4 #saved in t0
            csrr    t3, 0xca9
            add     t2, t2, t3
            csrrwi  t3, 0xca9, 0b10011
            add     t2, t2, t3
            csrrw   t1, 0xca9, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x2be2bf9
            csrrw   t0, 0x1c3, t4 #saved in t0
            csrr    t3, 0x1c3
            add     t2, t2, t3
            csrrwi  t3, 0x1c3, 0b11100
            add     t2, t2, t3
            csrrw   t1, 0x1c3, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xd9de9f4
            csrrw   t0, 0xecc, t4 #saved in t0
            csrr    t3, 0xecc
            add     t2, t2, t3
            csrrwi  t3, 0xecc, 0b10100
            add     t2, t2, t3
            csrrw   t1, 0xecc, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x79cc6b3
            csrrw   t0, 0xc48, t4 #saved in t0
            csrr    t3, 0xc48
            add     t2, t2, t3
            csrrwi  t3, 0xc48, 0b00111
            add     t2, t2, t3
            csrrw   t1, 0xc48, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x1d4f1b4
            csrrw   t0, 0x85c, t4 #saved in t0
            csrr    t3, 0x85c
            add     t2, t2, t3
            csrrwi  t3, 0x85c, 0b11001
            add     t2, t2, t3
            csrrw   t1, 0x85c, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x93b7eed
            csrrw   t0, 0x279, t4 #saved in t0
            csrr    t3, 0x279
            add     t2, t2, t3
            csrrwi  t3, 0x279, 0b01010
            add     t2, t2, t3
            csrrw   t1, 0x279, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xa60107c
            csrrw   t0, 0x433, t4 #saved in t0
            csrr    t3, 0x433
            add     t2, t2, t3
            csrrwi  t3, 0x433, 0b00101
            add     t2, t2, t3
            csrrw   t1, 0x433, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x48f31e4
            csrrw   t0, 0xd00, t4 #saved in t0
            csrr    t3, 0xd00
            add     t2, t2, t3
            csrrwi  t3, 0xd00, 0b11110
            add     t2, t2, t3
            csrrw   t1, 0xd00, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x1f5c095
            csrrw   t0, 0x216, t4 #saved in t0
            csrr    t3, 0x216
            add     t2, t2, t3
            csrrwi  t3, 0x216, 0b11011
            add     t2, t2, t3
            csrrw   t1, 0x216, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x705de69
            csrrw   t0, 0xf3d, t4 #saved in t0
            csrr    t3, 0xf3d
            add     t2, t2, t3
            csrrwi  t3, 0xf3d, 0b10011
            add     t2, t2, t3
            csrrw   t1, 0xf3d, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x01af090
            csrrw   t0, 0x815, t4 #saved in t0
            csrr    t3, 0x815
            add     t2, t2, t3
            csrrwi  t3, 0x815, 0b10111
            add     t2, t2, t3
            csrrw   t1, 0x815, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x3d52eae
            csrrw   t0, 0xe22, t4 #saved in t0
            csrr    t3, 0xe22
            add     t2, t2, t3
            csrrwi  t3, 0xe22, 0b01011
            add     t2, t2, t3
            csrrw   t1, 0xe22, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x22ebcf5
            csrrw   t0, 0xe96, t4 #saved in t0
            csrr    t3, 0xe96
            add     t2, t2, t3
            csrrwi  t3, 0xe96, 0b01111
            add     t2, t2, t3
            csrrw   t1, 0xe96, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xd933920
            csrrw   t0, 0xf2c, t4 #saved in t0
            csrr    t3, 0xf2c
            add     t2, t2, t3
            csrrwi  t3, 0xf2c, 0b10100
            add     t2, t2, t3
            csrrw   t1, 0xf2c, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x1fae0f6
            csrrw   t0, 0xba3, t4 #saved in t0
            csrr    t3, 0xba3
            add     t2, t2, t3
            csrrwi  t3, 0xba3, 0b11001
            add     t2, t2, t3
            csrrw   t1, 0xba3, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x0a3c796
            csrrw   t0, 0xec6, t4 #saved in t0
            csrr    t3, 0xec6
            add     t2, t2, t3
            csrrwi  t3, 0xec6, 0b01010
            add     t2, t2, t3
            csrrw   t1, 0xec6, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xf905652
            csrrw   t0, 0x12c, t4 #saved in t0
            csrr    t3, 0x12c
            add     t2, t2, t3
            csrrwi  t3, 0x12c, 0b10000
            add     t2, t2, t3
            csrrw   t1, 0x12c, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xa977909
            csrrw   t0, 0xcfc, t4 #saved in t0
            csrr    t3, 0xcfc
            add     t2, t2, t3
            csrrwi  t3, 0xcfc, 0b00000
            add     t2, t2, t3
            csrrw   t1, 0xcfc, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x86c0224
            csrrw   t0, 0x99f, t4 #saved in t0
            csrr    t3, 0x99f
            add     t2, t2, t3
            csrrwi  t3, 0x99f, 0b01011
            add     t2, t2, t3
            csrrw   t1, 0x99f, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x7764bc0
            csrrw   t0, 0xc62, t4 #saved in t0
            csrr    t3, 0xc62
            add     t2, t2, t3
            csrrwi  t3, 0xc62, 0b11110
            add     t2, t2, t3
            csrrw   t1, 0xc62, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xeec8d75
            csrrw   t0, 0x8a8, t4 #saved in t0
            csrr    t3, 0x8a8
            add     t2, t2, t3
            csrrwi  t3, 0x8a8, 0b00001
            add     t2, t2, t3
            csrrw   t1, 0x8a8, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x92c9ef8
            csrrw   t0, 0xc80, t4 #saved in t0
            csrr    t3, 0xc80
            add     t2, t2, t3
            csrrwi  t3, 0xc80, 0b01101
            add     t2, t2, t3
            csrrw   t1, 0xc80, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x2ea7cc7
            csrrw   t0, 0x557, t4 #saved in t0
            csrr    t3, 0x557
            add     t2, t2, t3
            csrrwi  t3, 0x557, 0b11101
            add     t2, t2, t3
            csrrw   t1, 0x557, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x9a71664
            csrrw   t0, 0x988, t4 #saved in t0
            csrr    t3, 0x988
            add     t2, t2, t3
            csrrwi  t3, 0x988, 0b01100
            add     t2, t2, t3
            csrrw   t1, 0x988, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x04887d4
            csrrw   t0, 0x8d2, t4 #saved in t0
            csrr    t3, 0x8d2
            add     t2, t2, t3
            csrrwi  t3, 0x8d2, 0b01110
            add     t2, t2, t3
            csrrw   t1, 0x8d2, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xdc05cc4
            csrrw   t0, 0x49d, t4 #saved in t0
            csrr    t3, 0x49d
            add     t2, t2, t3
            csrrwi  t3, 0x49d, 0b00010
            add     t2, t2, t3
            csrrw   t1, 0x49d, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x9d61c42
            csrrw   t0, 0xdb5, t4 #saved in t0
            csrr    t3, 0xdb5
            add     t2, t2, t3
            csrrwi  t3, 0xdb5, 0b00011
            add     t2, t2, t3
            csrrw   t1, 0xdb5, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x41252a7
            csrrw   t0, 0x3a5, t4 #saved in t0
            csrr    t3, 0x3a5
            add     t2, t2, t3
            csrrwi  t3, 0x3a5, 0b11111
            add     t2, t2, t3
            csrrw   t1, 0x3a5, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x3bfecce
            csrrw   t0, 0xddf, t4 #saved in t0
            csrr    t3, 0xddf
            add     t2, t2, t3
            csrrwi  t3, 0xddf, 0b00110
            add     t2, t2, t3
            csrrw   t1, 0xddf, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xd4a0b3e
            csrrw   t0, 0x251, t4 #saved in t0
            csrr    t3, 0x251
            add     t2, t2, t3
            csrrwi  t3, 0x251, 0b01001
            add     t2, t2, t3
            csrrw   t1, 0x251, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x819c0e5
            csrrw   t0, 0x7a9, t4 #saved in t0
            csrr    t3, 0x7a9
            add     t2, t2, t3
            csrrwi  t3, 0x7a9, 0b00100
            add     t2, t2, t3
            csrrw   t1, 0x7a9, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x5ff3119
            csrrw   t0, 0x6db, t4 #saved in t0
            csrr    t3, 0x6db
            add     t2, t2, t3
            csrrwi  t3, 0x6db, 0b10011
            add     t2, t2, t3
            csrrw   t1, 0x6db, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x55719f7
            csrrw   t0, 0xd02, t4 #saved in t0
            csrr    t3, 0xd02
            add     t2, t2, t3
            csrrwi  t3, 0xd02, 0b11010
            add     t2, t2, t3
            csrrw   t1, 0xd02, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x7cdef0b
            csrrw   t0, 0xfaf, t4 #saved in t0
            csrr    t3, 0xfaf
            add     t2, t2, t3
            csrrwi  t3, 0xfaf, 0b10101
            add     t2, t2, t3
            csrrw   t1, 0xfaf, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtval ,t4
            add     t2, t2, t6
            csrrw   t3, mtval,t5
            add     t2, t2, t3
            csrrw   t3, mtval, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xc6b7941
            csrrw   t0, 0xb52, t4 #saved in t0
            csrr    t3, 0xb52
            add     t2, t2, t3
            csrrwi  t3, 0xb52, 0b00110
            add     t2, t2, t3
            csrrw   t1, 0xb52, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xe5f669f
            csrrw   t0, 0xe0c, t4 #saved in t0
            csrr    t3, 0xe0c
            add     t2, t2, t3
            csrrwi  t3, 0xe0c, 0b01010
            add     t2, t2, t3
            csrrw   t1, 0xe0c, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x5762d5c
            csrrw   t0, 0xbaf, t4 #saved in t0
            csrr    t3, 0xbaf
            add     t2, t2, t3
            csrrwi  t3, 0xbaf, 0b00000
            add     t2, t2, t3
            csrrw   t1, 0xbaf, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mtvec ,t4
            add     t2, t2, t6
            csrrw   t3, mtvec,t5
            add     t2, t2, t3
            csrrw   t3, mtvec, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x03a5320
            csrrw   t0, 0xd62, t4 #saved in t0
            csrr    t3, 0xd62
            add     t2, t2, t3
            csrrwi  t3, 0xd62, 0b11000
            add     t2, t2, t3
            csrrw   t1, 0xd62, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xa96e4fc
            csrrw   t0, 0xa39, t4 #saved in t0
            csrr    t3, 0xa39
            add     t2, t2, t3
            csrrwi  t3, 0xa39, 0b10000
            add     t2, t2, t3
            csrrw   t1, 0xa39, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xcb1216e
            csrrw   t0, 0x62a, t4 #saved in t0
            csrr    t3, 0x62a
            add     t2, t2, t3
            csrrwi  t3, 0x62a, 0b11001
            add     t2, t2, t3
            csrrw   t1, 0x62a, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mie ,t4
            add     t2, t2, t6
            csrrw   t3, mie,t5
            add     t2, t2, t3
            csrrw   t3, mie, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mcause ,t4
            add     t2, t2, t6
            csrrw   t3, mcause,t5
            add     t2, t2, t3
            csrrw   t3, mcause, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x58e3f75
            csrrw   t0, 0x2f3, t4 #saved in t0
            csrr    t3, 0x2f3
            add     t2, t2, t3
            csrrwi  t3, 0x2f3, 0b10001
            add     t2, t2, t3
            csrrw   t1, 0x2f3, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x95ced6f
            csrrw   t0, 0xb83, t4 #saved in t0
            csrr    t3, 0xb83
            add     t2, t2, t3
            csrrwi  t3, 0xb83, 0b01000
            add     t2, t2, t3
            csrrw   t1, 0xb83, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xdd2cf10
            csrrw   t0, 0xdac, t4 #saved in t0
            csrr    t3, 0xdac
            add     t2, t2, t3
            csrrwi  t3, 0xdac, 0b01100
            add     t2, t2, t3
            csrrw   t1, 0xdac, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mepc ,t4
            add     t2, t2, t6
            csrrw   t3, mepc,t5
            add     t2, t2, t3
            csrrw   t3, mepc, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, misa ,t4
            add     t2, t2, t6
            csrrw   t3, misa,t5
            add     t2, t2, t3
            csrrw   t3, misa, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x3459c42
            csrrw   t0, 0xc87, t4 #saved in t0
            csrr    t3, 0xc87
            add     t2, t2, t3
            csrrwi  t3, 0xc87, 0b10110
            add     t2, t2, t3
            csrrw   t1, 0xc87, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            #disable all traps mie and mip
            la      t0, MIE_SAVE
            csrrc   t1,mie,x0
            add     t2, t2, t1
            sw      t1,(t0)
            la      t0, MIP_SAVE
            csrrc   t1,mip,x0
            add     t2, t2, t1
            sw      t1,(t0)
            csrrc   t0, mie, x0
            add     t2, t2, t0
            csrrc   t1, mip, x0
            add     t2, t2, t1

            csrrw   t6, mstatus ,t4
            add     t2, t2, t6
            csrrw   t3, mstatus,t5
            add     t2, t2, t3
            csrrw   t3, mstatus, t6  #restore  value
            add     t2, t2, t3

            #load old mie and mip
            la      t0, MIE_SAVE
            lw      t1,(t0)
            csrrw   t0,mie,t1
            la      t0, MIP_SAVE
            lw      t1,(t0)
            csrrw   t0,mip,t1
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x116d139
            csrrw   t0, 0xc4e, t4 #saved in t0
            csrr    t3, 0xc4e
            add     t2, t2, t3
            csrrwi  t3, 0xc4e, 0b00101
            add     t2, t2, t3
            csrrw   t1, 0xc4e, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x567d0f0
            csrrw   t0, 0x935, t4 #saved in t0
            csrr    t3, 0x935
            add     t2, t2, t3
            csrrwi  t3, 0x935, 0b11111
            add     t2, t2, t3
            csrrw   t1, 0x935, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0x6b2592b
            csrrw   t0, 0xb80, t4 #saved in t0
            csrr    t3, 0xb80
            add     t2, t2, t3
            csrrwi  t3, 0xb80, 0b10010
            add     t2, t2, t3
            csrrw   t1, 0xb80, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Update hash 
            mv a7, t2
            call update_hash
                
            # Disable interrupts
            disable_interrupts a3, a6
            # Change trap handler
            la t5, csr_trap_handler
            csrrw a5, mtvec, t5
            
            li      t4,0xfae6857
            csrrw   t0, 0xb6f, t4 #saved in t0
            csrr    t3, 0xb6f
            add     t2, t2, t3
            csrrwi  t3, 0xb6f, 0b11100
            add     t2, t2, t3
            csrrw   t1, 0xb6f, t0 #restore csr value
            add     t2, t2, t1

            # Restore old trap handler
            csrw mtvec, a5
            # Restore interrupts
            restore_interrupts a3, a6
                
            # Exit routine
            call finalize_hash


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
            MIE_SAVE:
            .long 0x0
            .space 8
            MIP_SAVE:
            .long 0x0
            .space 8
            CNTEN_SAVE:
            .long 0x0
            .space 8
            CNT_INIB_SAVE:
            .long 0x0
            .space 8
            MPHCNT3_SAVE:
            .long 0x0
            .space 8
            MPHEV3_SAVE:
            .long 0x0
            .space 8


            .end

    