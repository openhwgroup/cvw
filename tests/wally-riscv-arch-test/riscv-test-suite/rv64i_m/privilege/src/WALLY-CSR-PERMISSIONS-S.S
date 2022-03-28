///////////////////////////////////////////
// ../../../imperas-riscv-tests/riscv-test-suite/rv64p/src/WALLY-CSR-PERMISSIONS-S.S
// dottolia@hmc.edu
// Created 2021-06-15 11:27:21.731076//
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
		
      add x7, x6, x0
      csrr x19, mtvec
    
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sstatus_0
          csrw mtvec, x1

          csrr x23, sstatus

          j _j_test_u_sstatus_0

          _m_trap_from_u_sstatus_0:
          bnez x30, _j_end_u_sstatus_0

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sstatus_0:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo0:
    li x25, 0xDEADBEA7

    csrrw x1, sstatus, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo1:
    li x25, 0xDEADBEA7

    csrrw x0, sstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo2:
    li x25, 0xDEADBEA7

    csrrwi x0, sstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo3:
    li x25, 0xDEADBEA7

    csrrs x0, sstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo4:
    li x25, 0xDEADBEA7

    csrrc x0, sstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo5:
    li x25, 0xDEADBEA7

    csrrsi x0, sstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo6:
    li x25, 0xDEADBEA7

    csrrci x0, sstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sstatus_0:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sstatus_7
          csrw mtvec, x1

          csrr x23, sstatus

          j _j_test_u_sstatus_7

          _m_trap_from_u_sstatus_7:
          bnez x30, _j_end_u_sstatus_7

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sstatus_7:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo7:
    li x25, 0xDEADBEA7

    csrrw x1, sstatus, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo8:
    li x25, 0xDEADBEA7

    csrrw x0, sstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo9:
    li x25, 0xDEADBEA7

    csrrwi x0, sstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo10:
    li x25, 0xDEADBEA7

    csrrs x0, sstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo11:
    li x25, 0xDEADBEA7

    csrrc x0, sstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo12:
    li x25, 0xDEADBEA7

    csrrsi x0, sstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo13:
    li x25, 0xDEADBEA7

    csrrci x0, sstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sstatus_7:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sedeleg_14
          csrw mtvec, x1

          csrr x23, sedeleg

          j _j_test_u_sedeleg_14

          _m_trap_from_u_sedeleg_14:
          bnez x30, _j_end_u_sedeleg_14

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sedeleg_14:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo14:
    li x25, 0xDEADBEA7

    csrrw x1, sedeleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo15:
    li x25, 0xDEADBEA7

    csrrw x0, sedeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo16:
    li x25, 0xDEADBEA7

    csrrwi x0, sedeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo17:
    li x25, 0xDEADBEA7

    csrrs x0, sedeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo18:
    li x25, 0xDEADBEA7

    csrrc x0, sedeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo19:
    li x25, 0xDEADBEA7

    csrrsi x0, sedeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo20:
    li x25, 0xDEADBEA7

    csrrci x0, sedeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sedeleg_14:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sedeleg_21
          csrw mtvec, x1

          csrr x23, sedeleg

          j _j_test_u_sedeleg_21

          _m_trap_from_u_sedeleg_21:
          bnez x30, _j_end_u_sedeleg_21

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sedeleg_21:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo21:
    li x25, 0xDEADBEA7

    csrrw x1, sedeleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo22:
    li x25, 0xDEADBEA7

    csrrw x0, sedeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo23:
    li x25, 0xDEADBEA7

    csrrwi x0, sedeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo24:
    li x25, 0xDEADBEA7

    csrrs x0, sedeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo25:
    li x25, 0xDEADBEA7

    csrrc x0, sedeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo26:
    li x25, 0xDEADBEA7

    csrrsi x0, sedeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo27:
    li x25, 0xDEADBEA7

    csrrci x0, sedeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sedeleg_21:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sideleg_28
          csrw mtvec, x1

          csrr x23, sideleg

          j _j_test_u_sideleg_28

          _m_trap_from_u_sideleg_28:
          bnez x30, _j_end_u_sideleg_28

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sideleg_28:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo28:
    li x25, 0xDEADBEA7

    csrrw x1, sideleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo29:
    li x25, 0xDEADBEA7

    csrrw x0, sideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo30:
    li x25, 0xDEADBEA7

    csrrwi x0, sideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo31:
    li x25, 0xDEADBEA7

    csrrs x0, sideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo32:
    li x25, 0xDEADBEA7

    csrrc x0, sideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo33:
    li x25, 0xDEADBEA7

    csrrsi x0, sideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo34:
    li x25, 0xDEADBEA7

    csrrci x0, sideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sideleg_28:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sideleg_35
          csrw mtvec, x1

          csrr x23, sideleg

          j _j_test_u_sideleg_35

          _m_trap_from_u_sideleg_35:
          bnez x30, _j_end_u_sideleg_35

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sideleg_35:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo35:
    li x25, 0xDEADBEA7

    csrrw x1, sideleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo36:
    li x25, 0xDEADBEA7

    csrrw x0, sideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo37:
    li x25, 0xDEADBEA7

    csrrwi x0, sideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo38:
    li x25, 0xDEADBEA7

    csrrs x0, sideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo39:
    li x25, 0xDEADBEA7

    csrrc x0, sideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo40:
    li x25, 0xDEADBEA7

    csrrsi x0, sideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo41:
    li x25, 0xDEADBEA7

    csrrci x0, sideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sideleg_35:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sie_42
          csrw mtvec, x1

          csrr x23, sie

          j _j_test_u_sie_42

          _m_trap_from_u_sie_42:
          bnez x30, _j_end_u_sie_42

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sie_42:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo42:
    li x25, 0xDEADBEA7

    csrrw x1, sie, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo43:
    li x25, 0xDEADBEA7

    csrrw x0, sie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo44:
    li x25, 0xDEADBEA7

    csrrwi x0, sie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo45:
    li x25, 0xDEADBEA7

    csrrs x0, sie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo46:
    li x25, 0xDEADBEA7

    csrrc x0, sie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo47:
    li x25, 0xDEADBEA7

    csrrsi x0, sie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo48:
    li x25, 0xDEADBEA7

    csrrci x0, sie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sie_42:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sie_49
          csrw mtvec, x1

          csrr x23, sie

          j _j_test_u_sie_49

          _m_trap_from_u_sie_49:
          bnez x30, _j_end_u_sie_49

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sie_49:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo49:
    li x25, 0xDEADBEA7

    csrrw x1, sie, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo50:
    li x25, 0xDEADBEA7

    csrrw x0, sie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo51:
    li x25, 0xDEADBEA7

    csrrwi x0, sie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo52:
    li x25, 0xDEADBEA7

    csrrs x0, sie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo53:
    li x25, 0xDEADBEA7

    csrrc x0, sie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo54:
    li x25, 0xDEADBEA7

    csrrsi x0, sie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo55:
    li x25, 0xDEADBEA7

    csrrci x0, sie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sie_49:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_stvec_56
          csrw mtvec, x1

          csrr x23, stvec

          j _j_test_u_stvec_56

          _m_trap_from_u_stvec_56:
          bnez x30, _j_end_u_stvec_56

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_stvec_56:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo56:
    li x25, 0xDEADBEA7

    csrrw x1, stvec, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo57:
    li x25, 0xDEADBEA7

    csrrw x0, stvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo58:
    li x25, 0xDEADBEA7

    csrrwi x0, stvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo59:
    li x25, 0xDEADBEA7

    csrrs x0, stvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo60:
    li x25, 0xDEADBEA7

    csrrc x0, stvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo61:
    li x25, 0xDEADBEA7

    csrrsi x0, stvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo62:
    li x25, 0xDEADBEA7

    csrrci x0, stvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_stvec_56:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_stvec_63
          csrw mtvec, x1

          csrr x23, stvec

          j _j_test_u_stvec_63

          _m_trap_from_u_stvec_63:
          bnez x30, _j_end_u_stvec_63

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_stvec_63:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo63:
    li x25, 0xDEADBEA7

    csrrw x1, stvec, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo64:
    li x25, 0xDEADBEA7

    csrrw x0, stvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo65:
    li x25, 0xDEADBEA7

    csrrwi x0, stvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo66:
    li x25, 0xDEADBEA7

    csrrs x0, stvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo67:
    li x25, 0xDEADBEA7

    csrrc x0, stvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo68:
    li x25, 0xDEADBEA7

    csrrsi x0, stvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo69:
    li x25, 0xDEADBEA7

    csrrci x0, stvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_stvec_63:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_scounteren_70
          csrw mtvec, x1

          csrr x23, scounteren

          j _j_test_u_scounteren_70

          _m_trap_from_u_scounteren_70:
          bnez x30, _j_end_u_scounteren_70

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_scounteren_70:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo70:
    li x25, 0xDEADBEA7

    csrrw x1, scounteren, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo71:
    li x25, 0xDEADBEA7

    csrrw x0, scounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo72:
    li x25, 0xDEADBEA7

    csrrwi x0, scounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo73:
    li x25, 0xDEADBEA7

    csrrs x0, scounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo74:
    li x25, 0xDEADBEA7

    csrrc x0, scounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo75:
    li x25, 0xDEADBEA7

    csrrsi x0, scounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo76:
    li x25, 0xDEADBEA7

    csrrci x0, scounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_scounteren_70:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_scounteren_77
          csrw mtvec, x1

          csrr x23, scounteren

          j _j_test_u_scounteren_77

          _m_trap_from_u_scounteren_77:
          bnez x30, _j_end_u_scounteren_77

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_scounteren_77:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo77:
    li x25, 0xDEADBEA7

    csrrw x1, scounteren, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo78:
    li x25, 0xDEADBEA7

    csrrw x0, scounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo79:
    li x25, 0xDEADBEA7

    csrrwi x0, scounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo80:
    li x25, 0xDEADBEA7

    csrrs x0, scounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo81:
    li x25, 0xDEADBEA7

    csrrc x0, scounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo82:
    li x25, 0xDEADBEA7

    csrrsi x0, scounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo83:
    li x25, 0xDEADBEA7

    csrrci x0, scounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_scounteren_77:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sscratch_84
          csrw mtvec, x1

          csrr x23, sscratch

          j _j_test_u_sscratch_84

          _m_trap_from_u_sscratch_84:
          bnez x30, _j_end_u_sscratch_84

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sscratch_84:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo84:
    li x25, 0xDEADBEA7

    csrrw x1, sscratch, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo85:
    li x25, 0xDEADBEA7

    csrrw x0, sscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo86:
    li x25, 0xDEADBEA7

    csrrwi x0, sscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo87:
    li x25, 0xDEADBEA7

    csrrs x0, sscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo88:
    li x25, 0xDEADBEA7

    csrrc x0, sscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo89:
    li x25, 0xDEADBEA7

    csrrsi x0, sscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo90:
    li x25, 0xDEADBEA7

    csrrci x0, sscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sscratch_84:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sscratch_91
          csrw mtvec, x1

          csrr x23, sscratch

          j _j_test_u_sscratch_91

          _m_trap_from_u_sscratch_91:
          bnez x30, _j_end_u_sscratch_91

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sscratch_91:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo91:
    li x25, 0xDEADBEA7

    csrrw x1, sscratch, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo92:
    li x25, 0xDEADBEA7

    csrrw x0, sscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo93:
    li x25, 0xDEADBEA7

    csrrwi x0, sscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo94:
    li x25, 0xDEADBEA7

    csrrs x0, sscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo95:
    li x25, 0xDEADBEA7

    csrrc x0, sscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo96:
    li x25, 0xDEADBEA7

    csrrsi x0, sscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo97:
    li x25, 0xDEADBEA7

    csrrci x0, sscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sscratch_91:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sepc_98
          csrw mtvec, x1

          csrr x23, sepc

          j _j_test_u_sepc_98

          _m_trap_from_u_sepc_98:
          bnez x30, _j_end_u_sepc_98

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sepc_98:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo98:
    li x25, 0xDEADBEA7

    csrrw x1, sepc, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo99:
    li x25, 0xDEADBEA7

    csrrw x0, sepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo100:
    li x25, 0xDEADBEA7

    csrrwi x0, sepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo101:
    li x25, 0xDEADBEA7

    csrrs x0, sepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo102:
    li x25, 0xDEADBEA7

    csrrc x0, sepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo103:
    li x25, 0xDEADBEA7

    csrrsi x0, sepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo104:
    li x25, 0xDEADBEA7

    csrrci x0, sepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sepc_98:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sepc_105
          csrw mtvec, x1

          csrr x23, sepc

          j _j_test_u_sepc_105

          _m_trap_from_u_sepc_105:
          bnez x30, _j_end_u_sepc_105

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sepc_105:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo105:
    li x25, 0xDEADBEA7

    csrrw x1, sepc, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo106:
    li x25, 0xDEADBEA7

    csrrw x0, sepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo107:
    li x25, 0xDEADBEA7

    csrrwi x0, sepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo108:
    li x25, 0xDEADBEA7

    csrrs x0, sepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo109:
    li x25, 0xDEADBEA7

    csrrc x0, sepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo110:
    li x25, 0xDEADBEA7

    csrrsi x0, sepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo111:
    li x25, 0xDEADBEA7

    csrrci x0, sepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sepc_105:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_scause_112
          csrw mtvec, x1

          csrr x23, scause

          j _j_test_u_scause_112

          _m_trap_from_u_scause_112:
          bnez x30, _j_end_u_scause_112

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_scause_112:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo112:
    li x25, 0xDEADBEA7

    csrrw x1, scause, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo113:
    li x25, 0xDEADBEA7

    csrrw x0, scause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo114:
    li x25, 0xDEADBEA7

    csrrwi x0, scause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo115:
    li x25, 0xDEADBEA7

    csrrs x0, scause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo116:
    li x25, 0xDEADBEA7

    csrrc x0, scause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo117:
    li x25, 0xDEADBEA7

    csrrsi x0, scause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo118:
    li x25, 0xDEADBEA7

    csrrci x0, scause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_scause_112:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_scause_119
          csrw mtvec, x1

          csrr x23, scause

          j _j_test_u_scause_119

          _m_trap_from_u_scause_119:
          bnez x30, _j_end_u_scause_119

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_scause_119:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo119:
    li x25, 0xDEADBEA7

    csrrw x1, scause, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo120:
    li x25, 0xDEADBEA7

    csrrw x0, scause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo121:
    li x25, 0xDEADBEA7

    csrrwi x0, scause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo122:
    li x25, 0xDEADBEA7

    csrrs x0, scause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo123:
    li x25, 0xDEADBEA7

    csrrc x0, scause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo124:
    li x25, 0xDEADBEA7

    csrrsi x0, scause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo125:
    li x25, 0xDEADBEA7

    csrrci x0, scause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_scause_119:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_stval_126
          csrw mtvec, x1

          csrr x23, stval

          j _j_test_u_stval_126

          _m_trap_from_u_stval_126:
          bnez x30, _j_end_u_stval_126

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_stval_126:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo126:
    li x25, 0xDEADBEA7

    csrrw x1, stval, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo127:
    li x25, 0xDEADBEA7

    csrrw x0, stval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo128:
    li x25, 0xDEADBEA7

    csrrwi x0, stval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo129:
    li x25, 0xDEADBEA7

    csrrs x0, stval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo130:
    li x25, 0xDEADBEA7

    csrrc x0, stval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo131:
    li x25, 0xDEADBEA7

    csrrsi x0, stval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo132:
    li x25, 0xDEADBEA7

    csrrci x0, stval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_stval_126:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_stval_133
          csrw mtvec, x1

          csrr x23, stval

          j _j_test_u_stval_133

          _m_trap_from_u_stval_133:
          bnez x30, _j_end_u_stval_133

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_stval_133:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo133:
    li x25, 0xDEADBEA7

    csrrw x1, stval, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo134:
    li x25, 0xDEADBEA7

    csrrw x0, stval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo135:
    li x25, 0xDEADBEA7

    csrrwi x0, stval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo136:
    li x25, 0xDEADBEA7

    csrrs x0, stval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo137:
    li x25, 0xDEADBEA7

    csrrc x0, stval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo138:
    li x25, 0xDEADBEA7

    csrrsi x0, stval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo139:
    li x25, 0xDEADBEA7

    csrrci x0, stval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_stval_133:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sip_140
          csrw mtvec, x1

          csrr x23, sip

          j _j_test_u_sip_140

          _m_trap_from_u_sip_140:
          bnez x30, _j_end_u_sip_140

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sip_140:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo140:
    li x25, 0xDEADBEA7

    csrrw x1, sip, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo141:
    li x25, 0xDEADBEA7

    csrrw x0, sip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo142:
    li x25, 0xDEADBEA7

    csrrwi x0, sip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo143:
    li x25, 0xDEADBEA7

    csrrs x0, sip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo144:
    li x25, 0xDEADBEA7

    csrrc x0, sip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo145:
    li x25, 0xDEADBEA7

    csrrsi x0, sip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo146:
    li x25, 0xDEADBEA7

    csrrci x0, sip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sip_140:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_sip_147
          csrw mtvec, x1

          csrr x23, sip

          j _j_test_u_sip_147

          _m_trap_from_u_sip_147:
          bnez x30, _j_end_u_sip_147

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_sip_147:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo147:
    li x25, 0xDEADBEA7

    csrrw x1, sip, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo148:
    li x25, 0xDEADBEA7

    csrrw x0, sip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo149:
    li x25, 0xDEADBEA7

    csrrwi x0, sip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo150:
    li x25, 0xDEADBEA7

    csrrs x0, sip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo151:
    li x25, 0xDEADBEA7

    csrrc x0, sip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo152:
    li x25, 0xDEADBEA7

    csrrsi x0, sip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo153:
    li x25, 0xDEADBEA7

    csrrci x0, sip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_sip_147:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_satp_154
          csrw mtvec, x1

          csrr x23, satp

          j _j_test_u_satp_154

          _m_trap_from_u_satp_154:
          bnez x30, _j_end_u_satp_154

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_satp_154:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo154:
    li x25, 0xDEADBEA7

    csrrw x1, satp, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo155:
    li x25, 0xDEADBEA7

    csrrw x0, satp, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo156:
    li x25, 0xDEADBEA7

    csrrwi x0, satp, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo157:
    li x25, 0xDEADBEA7

    csrrs x0, satp, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo158:
    li x25, 0xDEADBEA7

    csrrc x0, satp, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo159:
    li x25, 0xDEADBEA7

    csrrsi x0, satp, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo160:
    li x25, 0xDEADBEA7

    csrrci x0, satp, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_satp_154:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_u_satp_161
          csrw mtvec, x1

          csrr x23, satp

          j _j_test_u_satp_161

          _m_trap_from_u_satp_161:
          bnez x30, _j_end_u_satp_161

          csrr x25, mcause
          

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_satp_161:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        

          li x1, 0b110000000000
          csrrc x0, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          
    _jdo161:
    li x25, 0xDEADBEA7

    csrrw x1, satp, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo162:
    li x25, 0xDEADBEA7

    csrrw x0, satp, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo163:
    li x25, 0xDEADBEA7

    csrrwi x0, satp, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo164:
    li x25, 0xDEADBEA7

    csrrs x0, satp, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo165:
    li x25, 0xDEADBEA7

    csrrc x0, satp, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo166:
    li x25, 0xDEADBEA7

    csrrsi x0, satp, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo167:
    li x25, 0xDEADBEA7

    csrrci x0, satp, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_satp_161:
        
      csrw mtvec, x19
    	# ---------------------------------------------------------------------------------------------
RVMODEL_HALT

RVTEST_DATA_BEGIN
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
# signature output
wally_signature:
.fill 168, 8, -1

#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif
RVMODEL_DATA_END
