///////////////////////////////////////////
// ../../../imperas-riscv-tests/riscv-test-suite/rv64p/src/WALLY-MTVEC.S
// dottolia@hmc.edu
// Created 2021-06-15 11:28:06.476830//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
// Adapted from Imperas RISCV-TEST_SUITE
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////

#include "model_test.h"
#include "arch_test.h"

RVTEST_ISA("RV64I")

.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT

    # ---------------------------------------------------------------------------------------------
    # address for test results
    la x6, wally_signature
		
      csrr x19, mtvec
    
    
        li x1, 2
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 0(x6)
  
    
        li x1, 3
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 8(x6)
  
    
        li x1, 2
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 16(x6)
  
    
        li x1, 3
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 24(x6)
  
    
        li x1, 6
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 32(x6)
  
    
        li x1, 7
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 40(x6)
  
    
        li x1, 6
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 48(x6)
  
    
        li x1, 7
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 56(x6)
  
    
        li x1, 10
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 64(x6)
  
    
        li x1, 11
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 72(x6)
  
    
        li x1, 10
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 80(x6)
  
    
        li x1, 11
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 88(x6)
  
    
        li x1, 14
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 96(x6)
  
    
        li x1, 15
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 104(x6)
  
    
        li x1, 14
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 112(x6)
  
    
        li x1, 15
        csrw mtvec, x1
        csrr x25, mtvec
      
    sd x25, 120(x6)
  
      csrw mtvec, x19
    
          # add x7, x6, x0
          csrr x19, mtvec
        
          # Reset x30 to 0 so we can run the tests. We'll set this to 1 when tests are completed so we stay in machine mode
          li x30, 0

          # Set up 
          la x1, _j_m_trap_ebreak_True
          addi x1, x1, 1 # enable/don't enable vectored interrupts
          csrw mtvec, x1
          la x1, _j_s_trap_ebreak_True
          addi x1, x1, 1 # enable/don't enable vectored interrupts
          csrw stvec, x1
          la x1, _j_u_trap_ebreak_True
          addi x1, x1, 1 # enable/don't enable vectored interrupts
          # csrw utvec, x1 # user mode traps are not supported

          # Start the tests!
          j _j_t_begin_ebreak_True

          # Machine mode traps
          _j_m_trap_ebreak_True:
          
              nop
              nop
              li x25, 0
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 1
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 2
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 3
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 4
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 5
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 6
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 7
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 8
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 9
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 10
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 11
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 12
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 13
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 14
              j _j_m_trap_end_ebreak_True
            
              nop
              nop
              li x25, 15
              j _j_m_trap_end_ebreak_True
            

          _j_m_trap_end_ebreak_True:
          
          auipc x27, 0
          addi x27, x27, 12
          jr x28
        

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
          bnez x30, _j_all_end_ebreak_True
          mret

          # Supervisor mode traps
          _j_s_trap_ebreak_True:
          
              nop
              nop
              li x25, 0
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 1
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 2
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 3
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 4
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 5
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 6
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 7
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 8
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 9
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 10
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 11
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 12
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 13
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 14
              j _j_s_trap_end_ebreak_True
            
              nop
              nop
              li x25, 15
              j _j_s_trap_end_ebreak_True
            

          _j_s_trap_end_ebreak_True:
          
          auipc x27, 0
          addi x27, x27, 12
          jr x28
        

          csrrs x20, sepc, x0
          addi x20, x20, 4
          csrrw x0, sepc, x20
          bnez x30, _j_goto_machine_mode_ebreak_True
          sret

          # Unused: user mode traps are no longer supported
          _j_u_trap_ebreak_True:
          li x25, 0xBAD00000

          csrrs x20, uepc, x0
          addi x20, x20, 4
          csrrw x0, uepc, x20
          bnez x30, _j_goto_supervisor_mode_ebreak_True
          uret

          # Currently unused. Just jumps to _j_goto_machine_mode. If you actually
          # want to implement this, you'll likely need to reset sedeleg here
          # and then cause an exception with ebreak (based on my intuition. Try that first, but I could be missing something / just wrong)
          _j_goto_supervisor_mode_ebreak_True:
          j _j_goto_machine_mode_ebreak_True

          _j_goto_machine_mode_ebreak_True:
          li x30, 1 # This will cause us to branch to _j_all_end_ebreak_True in the machine trap handler, which we'll get into by invoking...
          ebreak # ... this instruction!

          # Run the actual tests!
          _j_t_begin_ebreak_True:
        
          csrr x18, medeleg
          li x9, 0
          csrw medeleg, x9

          csrr x16, mideleg
          li x9, 0
          csrw mideleg, x9
        
    
    la x28, _jtest16
    j _jdo16

    _jtest16:
    nop
    
    jr x27

    _jdo16:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 128(x6)
  
    
    la x28, _jtest17
    j _jdo17

    _jtest17:
    nop
    
      li x1, 0x80
      csrrc x0, mie, x1

      li x1, 0x8
      csrrc x0, mstatus, x1

      la x18, 0x2004000
      sd x0, 0(x18)
    
    jr x27

    _jdo17:
    li x25, 0xDEADBEA7
    
      li x1, 0x8
      csrrs x0, mstatus, x1

      la x18, 0x2004000
      # lw x11, 0(x18)
      # li x1, 0x3fffffffffffffff
      # sd x1, 0(x18)

      li x1, 0x80
      csrrs x0, mie, x1

      sd x0, 0(x18)
    
  
    sd x25, 136(x6)
  
    
    la x28, _jtest18
    j _jdo18

    _jtest18:
    nop
    
    jr x27

    _jdo18:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 144(x6)
  
    
    la x28, _jtest19
    j _jdo19

    _jtest19:
    nop
    
      li x1, 0x80
      csrrc x0, mie, x1

      li x1, 0x8
      csrrc x0, mstatus, x1

      la x18, 0x2004000
      sd x0, 0(x18)
    
    jr x27

    _jdo19:
    li x25, 0xDEADBEA7
    
      li x1, 0x8
      csrrs x0, mstatus, x1

      la x18, 0x2004000
      # lw x11, 0(x18)
      # li x1, 0x3fffffffffffffff
      # sd x1, 0(x18)

      li x1, 0x80
      csrrs x0, mie, x1

      sd x0, 0(x18)
    
  
    sd x25, 152(x6)
  
    
    la x28, _jtest20
    j _jdo20

    _jtest20:
    nop
    
    jr x27

    _jdo20:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 160(x6)
  
    
    la x28, _jtest21
    j _jdo21

    _jtest21:
    nop
    
      li x1, 0x80
      csrrc x0, mie, x1

      li x1, 0x8
      csrrc x0, mstatus, x1

      la x18, 0x2004000
      sd x0, 0(x18)
    
    jr x27

    _jdo21:
    li x25, 0xDEADBEA7
    
      li x1, 0x8
      csrrs x0, mstatus, x1

      la x18, 0x2004000
      # lw x11, 0(x18)
      # li x1, 0x3fffffffffffffff
      # sd x1, 0(x18)

      li x1, 0x80
      csrrs x0, mie, x1

      sd x0, 0(x18)
    
  
    sd x25, 168(x6)
  
    
    la x28, _jtest22
    j _jdo22

    _jtest22:
    nop
    
    jr x27

    _jdo22:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 176(x6)
  
    
    la x28, _jtest23
    j _jdo23

    _jtest23:
    nop
    
      li x1, 0x80
      csrrc x0, mie, x1

      li x1, 0x8
      csrrc x0, mstatus, x1

      la x18, 0x2004000
      sd x0, 0(x18)
    
    jr x27

    _jdo23:
    li x25, 0xDEADBEA7
    
      li x1, 0x8
      csrrs x0, mstatus, x1

      la x18, 0x2004000
      # lw x11, 0(x18)
      # li x1, 0x3fffffffffffffff
      # sd x1, 0(x18)

      li x1, 0x80
      csrrs x0, mie, x1

      sd x0, 0(x18)
    
  
    sd x25, 184(x6)
  
              li x1, 0b110000000000
              csrrc x31, mstatus, x1
              li x1, 0b0100000000000
              csrrs x31, mstatus, x1

              auipc x1, 0
              addi x1, x1, 16 # x1 is now right after the mret instruction
              csrw mepc, x1
              mret

              # We're now in supervisor mode...
            
    
    la x28, _jtest24
    j _jdo24

    _jtest24:
    nop
    
    jr x27

    _jdo24:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 192(x6)
  
    
    la x28, _jtest25
    j _jdo25

    _jtest25:
    nop
    
    jr x27

    _jdo25:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 200(x6)
  
    
    la x28, _jtest26
    j _jdo26

    _jtest26:
    nop
    
    jr x27

    _jdo26:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 208(x6)
  
    
    la x28, _jtest27
    j _jdo27

    _jtest27:
    nop
    
    jr x27

    _jdo27:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 216(x6)
  
              li x1, 0b110000000000
              csrrc x31, mstatus, x1
              li x1, 0b0100000000000
              csrrs x31, mstatus, x1

              auipc x1, 0
              addi x1, x1, 16 # x1 is now right after the mret instruction
              csrw mepc, x1
              mret

              # We're now in supervisor mode...
            

            li x1, 0b110000000000
            csrrc x31, sstatus, x1

            auipc x1, 0
            addi x1, x1, 16 # x1 is now right after the sret instruction
            csrw sepc, x1
            sret

            # We're now in user mode...
            
    
    la x28, _jtest28
    j _jdo28

    _jtest28:
    nop
    
    jr x27

    _jdo28:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 224(x6)
  
    
    la x28, _jtest29
    j _jdo29

    _jtest29:
    nop
    
    jr x27

    _jdo29:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 232(x6)
  
    
    la x28, _jtest30
    j _jdo30

    _jtest30:
    nop
    
    jr x27

    _jdo30:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 240(x6)
  
    
    la x28, _jtest31
    j _jdo31

    _jtest31:
    nop
    
    jr x27

    _jdo31:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 248(x6)
  
          li x30, 1
          li gp, 0
          ebreak
          _j_all_end_ebreak_True:

          # Reset trap handling csrs to old values
          csrw mtvec, x19
          csrw medeleg, x18
          csrw mideleg, x16
        
          # add x7, x6, x0
          csrr x19, mtvec
        
          # Reset x30 to 0 so we can run the tests. We'll set this to 1 when tests are completed so we stay in machine mode
          li x30, 0

          # Set up 
          la x1, _j_m_trap_ebreak_False
           # enable/don't enable vectored interrupts
          csrw mtvec, x1
          la x1, _j_s_trap_ebreak_False
           # enable/don't enable vectored interrupts
          csrw stvec, x1
          la x1, _j_u_trap_ebreak_False
           # enable/don't enable vectored interrupts
          # csrw utvec, x1 # user mode traps are not supported

          # Start the tests!
          j _j_t_begin_ebreak_False

          # Machine mode traps
          _j_m_trap_ebreak_False:
          
              nop
              nop
              li x25, 0
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 1
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 2
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 3
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 4
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 5
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 6
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 7
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 8
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 9
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 10
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 11
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 12
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 13
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 14
              j _j_m_trap_end_ebreak_False
            
              nop
              nop
              li x25, 15
              j _j_m_trap_end_ebreak_False
            

          _j_m_trap_end_ebreak_False:
          
          auipc x27, 0
          addi x27, x27, 12
          jr x28
        

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
          bnez x30, _j_all_end_ebreak_False
          mret

          # Supervisor mode traps
          _j_s_trap_ebreak_False:
          
              nop
              nop
              li x25, 0
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 1
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 2
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 3
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 4
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 5
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 6
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 7
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 8
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 9
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 10
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 11
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 12
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 13
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 14
              j _j_s_trap_end_ebreak_False
            
              nop
              nop
              li x25, 15
              j _j_s_trap_end_ebreak_False
            

          _j_s_trap_end_ebreak_False:
          
          auipc x27, 0
          addi x27, x27, 12
          jr x28
        

          csrrs x20, sepc, x0
          addi x20, x20, 4
          csrrw x0, sepc, x20
          bnez x30, _j_goto_machine_mode_ebreak_False
          sret

          # Unused: user mode traps are no longer supported
          _j_u_trap_ebreak_False:
          li x25, 0xBAD00000

          csrrs x20, uepc, x0
          addi x20, x20, 4
          csrrw x0, uepc, x20
          bnez x30, _j_goto_supervisor_mode_ebreak_False
          uret

          # Currently unused. Just jumps to _j_goto_machine_mode. If you actually
          # want to implement this, you'll likely need to reset sedeleg here
          # and then cause an exception with ebreak (based on my intuition. Try that first, but I could be missing something / just wrong)
          _j_goto_supervisor_mode_ebreak_False:
          j _j_goto_machine_mode_ebreak_False

          _j_goto_machine_mode_ebreak_False:
          li x30, 1 # This will cause us to branch to _j_all_end_ebreak_False in the machine trap handler, which we'll get into by invoking...
          ebreak # ... this instruction!

          # Run the actual tests!
          _j_t_begin_ebreak_False:
        
          csrr x18, medeleg
          li x9, 0
          csrw medeleg, x9

          csrr x16, mideleg
          li x9, 0
          csrw mideleg, x9
        
    
    la x28, _jtest32
    j _jdo32

    _jtest32:
    nop
    
    jr x27

    _jdo32:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 256(x6)
  
    
    la x28, _jtest33
    j _jdo33

    _jtest33:
    nop
    
      li x1, 0x80
      csrrc x0, mie, x1

      li x1, 0x8
      csrrc x0, mstatus, x1

      la x18, 0x2004000
      sd x0, 0(x18)
    
    jr x27

    _jdo33:
    li x25, 0xDEADBEA7
    
      li x1, 0x8
      csrrs x0, mstatus, x1

      la x18, 0x2004000
      # lw x11, 0(x18)
      # li x1, 0x3fffffffffffffff
      # sd x1, 0(x18)

      li x1, 0x80
      csrrs x0, mie, x1

      sd x0, 0(x18)
    
  
    sd x25, 264(x6)
  
    
    la x28, _jtest34
    j _jdo34

    _jtest34:
    nop
    
    jr x27

    _jdo34:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 272(x6)
  
    
    la x28, _jtest35
    j _jdo35

    _jtest35:
    nop
    
      li x1, 0x80
      csrrc x0, mie, x1

      li x1, 0x8
      csrrc x0, mstatus, x1

      la x18, 0x2004000
      sd x0, 0(x18)
    
    jr x27

    _jdo35:
    li x25, 0xDEADBEA7
    
      li x1, 0x8
      csrrs x0, mstatus, x1

      la x18, 0x2004000
      # lw x11, 0(x18)
      # li x1, 0x3fffffffffffffff
      # sd x1, 0(x18)

      li x1, 0x80
      csrrs x0, mie, x1

      sd x0, 0(x18)
    
  
    sd x25, 280(x6)
  
    
    la x28, _jtest36
    j _jdo36

    _jtest36:
    nop
    
    jr x27

    _jdo36:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 288(x6)
  
    
    la x28, _jtest37
    j _jdo37

    _jtest37:
    nop
    
      li x1, 0x80
      csrrc x0, mie, x1

      li x1, 0x8
      csrrc x0, mstatus, x1

      la x18, 0x2004000
      sd x0, 0(x18)
    
    jr x27

    _jdo37:
    li x25, 0xDEADBEA7
    
      li x1, 0x8
      csrrs x0, mstatus, x1

      la x18, 0x2004000
      # lw x11, 0(x18)
      # li x1, 0x3fffffffffffffff
      # sd x1, 0(x18)

      li x1, 0x80
      csrrs x0, mie, x1

      sd x0, 0(x18)
    
  
    sd x25, 296(x6)
  
    
    la x28, _jtest38
    j _jdo38

    _jtest38:
    nop
    
    jr x27

    _jdo38:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 304(x6)
  
    
    la x28, _jtest39
    j _jdo39

    _jtest39:
    nop
    
      li x1, 0x80
      csrrc x0, mie, x1

      li x1, 0x8
      csrrc x0, mstatus, x1

      la x18, 0x2004000
      sd x0, 0(x18)
    
    jr x27

    _jdo39:
    li x25, 0xDEADBEA7
    
      li x1, 0x8
      csrrs x0, mstatus, x1

      la x18, 0x2004000
      # lw x11, 0(x18)
      # li x1, 0x3fffffffffffffff
      # sd x1, 0(x18)

      li x1, 0x80
      csrrs x0, mie, x1

      sd x0, 0(x18)
    
  
    sd x25, 312(x6)
  
              li x1, 0b110000000000
              csrrc x31, mstatus, x1
              li x1, 0b0100000000000
              csrrs x31, mstatus, x1

              auipc x1, 0
              addi x1, x1, 16 # x1 is now right after the mret instruction
              csrw mepc, x1
              mret

              # We're now in supervisor mode...
            
    
    la x28, _jtest40
    j _jdo40

    _jtest40:
    nop
    
    jr x27

    _jdo40:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 320(x6)
  
    
    la x28, _jtest41
    j _jdo41

    _jtest41:
    nop
    
    jr x27

    _jdo41:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 328(x6)
  
    
    la x28, _jtest42
    j _jdo42

    _jtest42:
    nop
    
    jr x27

    _jdo42:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 336(x6)
  
    
    la x28, _jtest43
    j _jdo43

    _jtest43:
    nop
    
    jr x27

    _jdo43:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 344(x6)
  
              li x1, 0b110000000000
              csrrc x31, mstatus, x1
              li x1, 0b0100000000000
              csrrs x31, mstatus, x1

              auipc x1, 0
              addi x1, x1, 16 # x1 is now right after the mret instruction
              csrw mepc, x1
              mret

              # We're now in supervisor mode...
            

            li x1, 0b110000000000
            csrrc x31, sstatus, x1

            auipc x1, 0
            addi x1, x1, 16 # x1 is now right after the sret instruction
            csrw sepc, x1
            sret

            # We're now in user mode...
            
    
    la x28, _jtest44
    j _jdo44

    _jtest44:
    nop
    
    jr x27

    _jdo44:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 352(x6)
  
    
    la x28, _jtest45
    j _jdo45

    _jtest45:
    nop
    
    jr x27

    _jdo45:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 360(x6)
  
    
    la x28, _jtest46
    j _jdo46

    _jtest46:
    nop
    
    jr x27

    _jdo46:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 368(x6)
  
    
    la x28, _jtest47
    j _jdo47

    _jtest47:
    nop
    
    jr x27

    _jdo47:
    li x25, 0xDEADBEA7
    
      ecall
    
  
    sd x25, 376(x6)
  
          li x30, 1
          li gp, 0
          ebreak
          _j_all_end_ebreak_False:

          # Reset trap handling csrs to old values
          csrw mtvec, x19
          csrw medeleg, x18
          csrw mideleg, x16
	
	# ---------------------------------------------------------------------------------------------
RVMODEL_HALT

RVTEST_DATA_BEGIN
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
# signature output
wally_signature:
.fill 48, 8, -1

#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif
RVMODEL_DATA_END
