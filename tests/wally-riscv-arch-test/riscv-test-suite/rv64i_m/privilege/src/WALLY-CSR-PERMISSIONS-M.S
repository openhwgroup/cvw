///////////////////////////////////////////
// ../../../imperas-riscv-tests/riscv-test-suite/rv64p/src/WALLY-CSR-PERMISSIONS-M.S
// dottolia@hmc.edu
// Created 2021-06-15 11:27:21.723799//
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
          la x1, _m_trap_from_s_mstatus_0
          csrw mtvec, x1

          csrr x23, mstatus

          j _j_test_s_mstatus_0

          _m_trap_from_s_mstatus_0:
          bnez x30, _j_end_s_mstatus_0

          csrr x25, mcause
          csrr x24, mstatus

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mstatus_0:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo0:
    li x25, 0xDEADBEA7

    csrrw x1, mstatus, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo1:
    li x25, 0xDEADBEA7

    csrrw x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo2:
    li x25, 0xDEADBEA7

    csrrwi x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo3:
    li x25, 0xDEADBEA7

    csrrs x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo4:
    li x25, 0xDEADBEA7

    csrrc x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo5:
    li x25, 0xDEADBEA7

    csrrsi x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo6:
    li x25, 0xDEADBEA7

    csrrci x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_s_mstatus_0:
        
          li x30, 0
          la x1, _m_trap_from_u_mstatus_7
          csrw mtvec, x1

          csrr x23, mstatus

          j _j_test_u_mstatus_7

          _m_trap_from_u_mstatus_7:
          bnez x30, _j_end_u_mstatus_7

          csrr x25, mcause
          csrr x24, mstatus

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mstatus_7:
        
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

    csrrw x1, mstatus, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo8:
    li x25, 0xDEADBEA7

    csrrw x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo9:
    li x25, 0xDEADBEA7

    csrrwi x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo10:
    li x25, 0xDEADBEA7

    csrrs x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo11:
    li x25, 0xDEADBEA7

    csrrc x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo12:
    li x25, 0xDEADBEA7

    csrrsi x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo13:
    li x25, 0xDEADBEA7

    csrrci x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_mstatus_7:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mstatus_14
          csrw mtvec, x1

          csrr x23, mstatus

          j _j_test_s_mstatus_14

          _m_trap_from_s_mstatus_14:
          bnez x30, _j_end_s_mstatus_14

          csrr x25, mcause
          csrr x24, mstatus

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mstatus_14:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo14:
    li x25, 0xDEADBEA7

    csrrw x1, mstatus, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo15:
    li x25, 0xDEADBEA7

    csrrw x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo16:
    li x25, 0xDEADBEA7

    csrrwi x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo17:
    li x25, 0xDEADBEA7

    csrrs x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo18:
    li x25, 0xDEADBEA7

    csrrc x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo19:
    li x25, 0xDEADBEA7

    csrrsi x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo20:
    li x25, 0xDEADBEA7

    csrrci x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_s_mstatus_14:
        
          li x30, 0
          la x1, _m_trap_from_u_mstatus_21
          csrw mtvec, x1

          csrr x23, mstatus

          j _j_test_u_mstatus_21

          _m_trap_from_u_mstatus_21:
          bnez x30, _j_end_u_mstatus_21

          csrr x25, mcause
          csrr x24, mstatus

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mstatus_21:
        
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

    csrrw x1, mstatus, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo22:
    li x25, 0xDEADBEA7

    csrrw x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo23:
    li x25, 0xDEADBEA7

    csrrwi x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo24:
    li x25, 0xDEADBEA7

    csrrs x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo25:
    li x25, 0xDEADBEA7

    csrrc x0, mstatus, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo26:
    li x25, 0xDEADBEA7

    csrrsi x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo27:
    li x25, 0xDEADBEA7

    csrrci x0, mstatus, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_mstatus_21:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_medeleg_28
          csrw mtvec, x1

          csrr x23, medeleg

          j _j_test_s_medeleg_28

          _m_trap_from_s_medeleg_28:
          bnez x30, _j_end_s_medeleg_28

          csrr x25, mcause
          csrr x24, medeleg

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_medeleg_28:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo28:
    li x25, 0xDEADBEA7

    csrrw x1, medeleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo30:
    li x25, 0xDEADBEA7

    csrrw x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo32:
    li x25, 0xDEADBEA7

    csrrwi x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo34:
    li x25, 0xDEADBEA7

    csrrs x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo36:
    li x25, 0xDEADBEA7

    csrrc x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo38:
    li x25, 0xDEADBEA7

    csrrsi x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo40:
    li x25, 0xDEADBEA7

    csrrci x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_medeleg_28:
        
          li x30, 0
          la x1, _m_trap_from_u_medeleg_42
          csrw mtvec, x1

          csrr x23, medeleg

          j _j_test_u_medeleg_42

          _m_trap_from_u_medeleg_42:
          bnez x30, _j_end_u_medeleg_42

          csrr x25, mcause
          csrr x24, medeleg

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_medeleg_42:
        
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

    csrrw x1, medeleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo44:
    li x25, 0xDEADBEA7

    csrrw x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo46:
    li x25, 0xDEADBEA7

    csrrwi x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo48:
    li x25, 0xDEADBEA7

    csrrs x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo50:
    li x25, 0xDEADBEA7

    csrrc x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo52:
    li x25, 0xDEADBEA7

    csrrsi x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo54:
    li x25, 0xDEADBEA7

    csrrci x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_medeleg_42:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_medeleg_56
          csrw mtvec, x1

          csrr x23, medeleg

          j _j_test_s_medeleg_56

          _m_trap_from_s_medeleg_56:
          bnez x30, _j_end_s_medeleg_56

          csrr x25, mcause
          csrr x24, medeleg

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_medeleg_56:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo56:
    li x25, 0xDEADBEA7

    csrrw x1, medeleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo58:
    li x25, 0xDEADBEA7

    csrrw x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo60:
    li x25, 0xDEADBEA7

    csrrwi x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo62:
    li x25, 0xDEADBEA7

    csrrs x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo64:
    li x25, 0xDEADBEA7

    csrrc x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo66:
    li x25, 0xDEADBEA7

    csrrsi x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo68:
    li x25, 0xDEADBEA7

    csrrci x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_medeleg_56:
        
          li x30, 0
          la x1, _m_trap_from_u_medeleg_70
          csrw mtvec, x1

          csrr x23, medeleg

          j _j_test_u_medeleg_70

          _m_trap_from_u_medeleg_70:
          bnez x30, _j_end_u_medeleg_70

          csrr x25, mcause
          csrr x24, medeleg

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_medeleg_70:
        
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

    csrrw x1, medeleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo72:
    li x25, 0xDEADBEA7

    csrrw x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo74:
    li x25, 0xDEADBEA7

    csrrwi x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo76:
    li x25, 0xDEADBEA7

    csrrs x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo78:
    li x25, 0xDEADBEA7

    csrrc x0, medeleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo80:
    li x25, 0xDEADBEA7

    csrrsi x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo82:
    li x25, 0xDEADBEA7

    csrrci x0, medeleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_medeleg_70:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mideleg_84
          csrw mtvec, x1

          csrr x23, mideleg

          j _j_test_s_mideleg_84

          _m_trap_from_s_mideleg_84:
          bnez x30, _j_end_s_mideleg_84

          csrr x25, mcause
          csrr x24, mideleg

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mideleg_84:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo84:
    li x25, 0xDEADBEA7

    csrrw x1, mideleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo86:
    li x25, 0xDEADBEA7

    csrrw x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo88:
    li x25, 0xDEADBEA7

    csrrwi x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo90:
    li x25, 0xDEADBEA7

    csrrs x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo92:
    li x25, 0xDEADBEA7

    csrrc x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo94:
    li x25, 0xDEADBEA7

    csrrsi x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo96:
    li x25, 0xDEADBEA7

    csrrci x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mideleg_84:
        
          li x30, 0
          la x1, _m_trap_from_u_mideleg_98
          csrw mtvec, x1

          csrr x23, mideleg

          j _j_test_u_mideleg_98

          _m_trap_from_u_mideleg_98:
          bnez x30, _j_end_u_mideleg_98

          csrr x25, mcause
          csrr x24, mideleg

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mideleg_98:
        
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

    csrrw x1, mideleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo100:
    li x25, 0xDEADBEA7

    csrrw x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo102:
    li x25, 0xDEADBEA7

    csrrwi x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo104:
    li x25, 0xDEADBEA7

    csrrs x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo106:
    li x25, 0xDEADBEA7

    csrrc x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo108:
    li x25, 0xDEADBEA7

    csrrsi x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo110:
    li x25, 0xDEADBEA7

    csrrci x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mideleg_98:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mideleg_112
          csrw mtvec, x1

          csrr x23, mideleg

          j _j_test_s_mideleg_112

          _m_trap_from_s_mideleg_112:
          bnez x30, _j_end_s_mideleg_112

          csrr x25, mcause
          csrr x24, mideleg

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mideleg_112:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo112:
    li x25, 0xDEADBEA7

    csrrw x1, mideleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo114:
    li x25, 0xDEADBEA7

    csrrw x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo116:
    li x25, 0xDEADBEA7

    csrrwi x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo118:
    li x25, 0xDEADBEA7

    csrrs x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo120:
    li x25, 0xDEADBEA7

    csrrc x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo122:
    li x25, 0xDEADBEA7

    csrrsi x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo124:
    li x25, 0xDEADBEA7

    csrrci x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mideleg_112:
        
          li x30, 0
          la x1, _m_trap_from_u_mideleg_126
          csrw mtvec, x1

          csrr x23, mideleg

          j _j_test_u_mideleg_126

          _m_trap_from_u_mideleg_126:
          bnez x30, _j_end_u_mideleg_126

          csrr x25, mcause
          csrr x24, mideleg

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mideleg_126:
        
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

    csrrw x1, mideleg, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo128:
    li x25, 0xDEADBEA7

    csrrw x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo130:
    li x25, 0xDEADBEA7

    csrrwi x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo132:
    li x25, 0xDEADBEA7

    csrrs x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo134:
    li x25, 0xDEADBEA7

    csrrc x0, mideleg, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo136:
    li x25, 0xDEADBEA7

    csrrsi x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo138:
    li x25, 0xDEADBEA7

    csrrci x0, mideleg, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mideleg_126:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mie_140
          csrw mtvec, x1

          csrr x23, mie

          j _j_test_s_mie_140

          _m_trap_from_s_mie_140:
          bnez x30, _j_end_s_mie_140

          csrr x25, mcause
          csrr x24, mie

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mie_140:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo140:
    li x25, 0xDEADBEA7

    csrrw x1, mie, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo142:
    li x25, 0xDEADBEA7

    csrrw x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo144:
    li x25, 0xDEADBEA7

    csrrwi x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo146:
    li x25, 0xDEADBEA7

    csrrs x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo148:
    li x25, 0xDEADBEA7

    csrrc x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo150:
    li x25, 0xDEADBEA7

    csrrsi x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo152:
    li x25, 0xDEADBEA7

    csrrci x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mie_140:
        
          li x30, 0
          la x1, _m_trap_from_u_mie_154
          csrw mtvec, x1

          csrr x23, mie

          j _j_test_u_mie_154

          _m_trap_from_u_mie_154:
          bnez x30, _j_end_u_mie_154

          csrr x25, mcause
          csrr x24, mie

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mie_154:
        
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

    csrrw x1, mie, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo156:
    li x25, 0xDEADBEA7

    csrrw x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo158:
    li x25, 0xDEADBEA7

    csrrwi x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo160:
    li x25, 0xDEADBEA7

    csrrs x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo162:
    li x25, 0xDEADBEA7

    csrrc x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo164:
    li x25, 0xDEADBEA7

    csrrsi x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo166:
    li x25, 0xDEADBEA7

    csrrci x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mie_154:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mie_168
          csrw mtvec, x1

          csrr x23, mie

          j _j_test_s_mie_168

          _m_trap_from_s_mie_168:
          bnez x30, _j_end_s_mie_168

          csrr x25, mcause
          csrr x24, mie

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mie_168:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo168:
    li x25, 0xDEADBEA7

    csrrw x1, mie, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo170:
    li x25, 0xDEADBEA7

    csrrw x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo172:
    li x25, 0xDEADBEA7

    csrrwi x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo174:
    li x25, 0xDEADBEA7

    csrrs x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo176:
    li x25, 0xDEADBEA7

    csrrc x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo178:
    li x25, 0xDEADBEA7

    csrrsi x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo180:
    li x25, 0xDEADBEA7

    csrrci x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mie_168:
        
          li x30, 0
          la x1, _m_trap_from_u_mie_182
          csrw mtvec, x1

          csrr x23, mie

          j _j_test_u_mie_182

          _m_trap_from_u_mie_182:
          bnez x30, _j_end_u_mie_182

          csrr x25, mcause
          csrr x24, mie

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mie_182:
        
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
          
    _jdo182:
    li x25, 0xDEADBEA7

    csrrw x1, mie, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo184:
    li x25, 0xDEADBEA7

    csrrw x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo186:
    li x25, 0xDEADBEA7

    csrrwi x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo188:
    li x25, 0xDEADBEA7

    csrrs x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo190:
    li x25, 0xDEADBEA7

    csrrc x0, mie, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo192:
    li x25, 0xDEADBEA7

    csrrsi x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo194:
    li x25, 0xDEADBEA7

    csrrci x0, mie, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mie_182:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mtvec_196
          csrw mtvec, x1

          csrr x23, mtvec

          j _j_test_s_mtvec_196

          _m_trap_from_s_mtvec_196:
          bnez x30, _j_end_s_mtvec_196

          csrr x25, mcause
          csrr x24, mtvec

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mtvec_196:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo196:
    li x25, 0xDEADBEA7

    csrrw x1, mtvec, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo198:
    li x25, 0xDEADBEA7

    csrrw x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo200:
    li x25, 0xDEADBEA7

    csrrwi x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo202:
    li x25, 0xDEADBEA7

    csrrs x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo204:
    li x25, 0xDEADBEA7

    csrrc x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo206:
    li x25, 0xDEADBEA7

    csrrsi x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo208:
    li x25, 0xDEADBEA7

    csrrci x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mtvec_196:
        
          li x30, 0
          la x1, _m_trap_from_u_mtvec_210
          csrw mtvec, x1

          csrr x23, mtvec

          j _j_test_u_mtvec_210

          _m_trap_from_u_mtvec_210:
          bnez x30, _j_end_u_mtvec_210

          csrr x25, mcause
          csrr x24, mtvec

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mtvec_210:
        
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
          
    _jdo210:
    li x25, 0xDEADBEA7

    csrrw x1, mtvec, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo212:
    li x25, 0xDEADBEA7

    csrrw x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo214:
    li x25, 0xDEADBEA7

    csrrwi x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo216:
    li x25, 0xDEADBEA7

    csrrs x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo218:
    li x25, 0xDEADBEA7

    csrrc x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo220:
    li x25, 0xDEADBEA7

    csrrsi x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo222:
    li x25, 0xDEADBEA7

    csrrci x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mtvec_210:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mtvec_224
          csrw mtvec, x1

          csrr x23, mtvec

          j _j_test_s_mtvec_224

          _m_trap_from_s_mtvec_224:
          bnez x30, _j_end_s_mtvec_224

          csrr x25, mcause
          csrr x24, mtvec

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mtvec_224:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo224:
    li x25, 0xDEADBEA7

    csrrw x1, mtvec, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo226:
    li x25, 0xDEADBEA7

    csrrw x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo228:
    li x25, 0xDEADBEA7

    csrrwi x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo230:
    li x25, 0xDEADBEA7

    csrrs x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo232:
    li x25, 0xDEADBEA7

    csrrc x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo234:
    li x25, 0xDEADBEA7

    csrrsi x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo236:
    li x25, 0xDEADBEA7

    csrrci x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mtvec_224:
        
          li x30, 0
          la x1, _m_trap_from_u_mtvec_238
          csrw mtvec, x1

          csrr x23, mtvec

          j _j_test_u_mtvec_238

          _m_trap_from_u_mtvec_238:
          bnez x30, _j_end_u_mtvec_238

          csrr x25, mcause
          csrr x24, mtvec

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mtvec_238:
        
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
          
    _jdo238:
    li x25, 0xDEADBEA7

    csrrw x1, mtvec, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo240:
    li x25, 0xDEADBEA7

    csrrw x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo242:
    li x25, 0xDEADBEA7

    csrrwi x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo244:
    li x25, 0xDEADBEA7

    csrrs x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo246:
    li x25, 0xDEADBEA7

    csrrc x0, mtvec, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo248:
    li x25, 0xDEADBEA7

    csrrsi x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo250:
    li x25, 0xDEADBEA7

    csrrci x0, mtvec, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mtvec_238:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mcounteren_252
          csrw mtvec, x1

          csrr x23, mcounteren

          j _j_test_s_mcounteren_252

          _m_trap_from_s_mcounteren_252:
          bnez x30, _j_end_s_mcounteren_252

          csrr x25, mcause
          csrr x24, mcounteren

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mcounteren_252:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo252:
    li x25, 0xDEADBEA7

    csrrw x1, mcounteren, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo254:
    li x25, 0xDEADBEA7

    csrrw x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo256:
    li x25, 0xDEADBEA7

    csrrwi x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo258:
    li x25, 0xDEADBEA7

    csrrs x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo260:
    li x25, 0xDEADBEA7

    csrrc x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo262:
    li x25, 0xDEADBEA7

    csrrsi x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo264:
    li x25, 0xDEADBEA7

    csrrci x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mcounteren_252:
        
          li x30, 0
          la x1, _m_trap_from_u_mcounteren_266
          csrw mtvec, x1

          csrr x23, mcounteren

          j _j_test_u_mcounteren_266

          _m_trap_from_u_mcounteren_266:
          bnez x30, _j_end_u_mcounteren_266

          csrr x25, mcause
          csrr x24, mcounteren

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mcounteren_266:
        
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
          
    _jdo266:
    li x25, 0xDEADBEA7

    csrrw x1, mcounteren, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo268:
    li x25, 0xDEADBEA7

    csrrw x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo270:
    li x25, 0xDEADBEA7

    csrrwi x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo272:
    li x25, 0xDEADBEA7

    csrrs x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo274:
    li x25, 0xDEADBEA7

    csrrc x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo276:
    li x25, 0xDEADBEA7

    csrrsi x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo278:
    li x25, 0xDEADBEA7

    csrrci x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mcounteren_266:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mcounteren_280
          csrw mtvec, x1

          csrr x23, mcounteren

          j _j_test_s_mcounteren_280

          _m_trap_from_s_mcounteren_280:
          bnez x30, _j_end_s_mcounteren_280

          csrr x25, mcause
          csrr x24, mcounteren

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mcounteren_280:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo280:
    li x25, 0xDEADBEA7

    csrrw x1, mcounteren, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo282:
    li x25, 0xDEADBEA7

    csrrw x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo284:
    li x25, 0xDEADBEA7

    csrrwi x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo286:
    li x25, 0xDEADBEA7

    csrrs x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo288:
    li x25, 0xDEADBEA7

    csrrc x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo290:
    li x25, 0xDEADBEA7

    csrrsi x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo292:
    li x25, 0xDEADBEA7

    csrrci x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mcounteren_280:
        
          li x30, 0
          la x1, _m_trap_from_u_mcounteren_294
          csrw mtvec, x1

          csrr x23, mcounteren

          j _j_test_u_mcounteren_294

          _m_trap_from_u_mcounteren_294:
          bnez x30, _j_end_u_mcounteren_294

          csrr x25, mcause
          csrr x24, mcounteren

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mcounteren_294:
        
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
          
    _jdo294:
    li x25, 0xDEADBEA7

    csrrw x1, mcounteren, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo296:
    li x25, 0xDEADBEA7

    csrrw x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo298:
    li x25, 0xDEADBEA7

    csrrwi x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo300:
    li x25, 0xDEADBEA7

    csrrs x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo302:
    li x25, 0xDEADBEA7

    csrrc x0, mcounteren, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo304:
    li x25, 0xDEADBEA7

    csrrsi x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo306:
    li x25, 0xDEADBEA7

    csrrci x0, mcounteren, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mcounteren_294:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mscratch_308
          csrw mtvec, x1

          csrr x23, mscratch

          j _j_test_s_mscratch_308

          _m_trap_from_s_mscratch_308:
          bnez x30, _j_end_s_mscratch_308

          csrr x25, mcause
          csrr x24, mscratch

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mscratch_308:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo308:
    li x25, 0xDEADBEA7

    csrrw x1, mscratch, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo310:
    li x25, 0xDEADBEA7

    csrrw x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo312:
    li x25, 0xDEADBEA7

    csrrwi x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo314:
    li x25, 0xDEADBEA7

    csrrs x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo316:
    li x25, 0xDEADBEA7

    csrrc x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo318:
    li x25, 0xDEADBEA7

    csrrsi x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo320:
    li x25, 0xDEADBEA7

    csrrci x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mscratch_308:
        
          li x30, 0
          la x1, _m_trap_from_u_mscratch_322
          csrw mtvec, x1

          csrr x23, mscratch

          j _j_test_u_mscratch_322

          _m_trap_from_u_mscratch_322:
          bnez x30, _j_end_u_mscratch_322

          csrr x25, mcause
          csrr x24, mscratch

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mscratch_322:
        
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
          
    _jdo322:
    li x25, 0xDEADBEA7

    csrrw x1, mscratch, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo324:
    li x25, 0xDEADBEA7

    csrrw x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo326:
    li x25, 0xDEADBEA7

    csrrwi x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo328:
    li x25, 0xDEADBEA7

    csrrs x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo330:
    li x25, 0xDEADBEA7

    csrrc x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo332:
    li x25, 0xDEADBEA7

    csrrsi x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo334:
    li x25, 0xDEADBEA7

    csrrci x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mscratch_322:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mscratch_336
          csrw mtvec, x1

          csrr x23, mscratch

          j _j_test_s_mscratch_336

          _m_trap_from_s_mscratch_336:
          bnez x30, _j_end_s_mscratch_336

          csrr x25, mcause
          csrr x24, mscratch

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mscratch_336:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo336:
    li x25, 0xDEADBEA7

    csrrw x1, mscratch, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo338:
    li x25, 0xDEADBEA7

    csrrw x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo340:
    li x25, 0xDEADBEA7

    csrrwi x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo342:
    li x25, 0xDEADBEA7

    csrrs x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo344:
    li x25, 0xDEADBEA7

    csrrc x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo346:
    li x25, 0xDEADBEA7

    csrrsi x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo348:
    li x25, 0xDEADBEA7

    csrrci x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mscratch_336:
        
          li x30, 0
          la x1, _m_trap_from_u_mscratch_350
          csrw mtvec, x1

          csrr x23, mscratch

          j _j_test_u_mscratch_350

          _m_trap_from_u_mscratch_350:
          bnez x30, _j_end_u_mscratch_350

          csrr x25, mcause
          csrr x24, mscratch

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mscratch_350:
        
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
          
    _jdo350:
    li x25, 0xDEADBEA7

    csrrw x1, mscratch, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo352:
    li x25, 0xDEADBEA7

    csrrw x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo354:
    li x25, 0xDEADBEA7

    csrrwi x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo356:
    li x25, 0xDEADBEA7

    csrrs x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo358:
    li x25, 0xDEADBEA7

    csrrc x0, mscratch, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo360:
    li x25, 0xDEADBEA7

    csrrsi x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo362:
    li x25, 0xDEADBEA7

    csrrci x0, mscratch, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mscratch_350:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mepc_364
          csrw mtvec, x1

          csrr x23, mepc

          j _j_test_s_mepc_364

          _m_trap_from_s_mepc_364:
          bnez x30, _j_end_s_mepc_364

          csrr x25, mcause
          csrr x24, mepc

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mepc_364:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo364:
    li x25, 0xDEADBEA7

    csrrw x1, mepc, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo365:
    li x25, 0xDEADBEA7

    csrrw x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo366:
    li x25, 0xDEADBEA7

    csrrwi x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo367:
    li x25, 0xDEADBEA7

    csrrs x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo368:
    li x25, 0xDEADBEA7

    csrrc x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo369:
    li x25, 0xDEADBEA7

    csrrsi x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo370:
    li x25, 0xDEADBEA7

    csrrci x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_s_mepc_364:
        
          li x30, 0
          la x1, _m_trap_from_u_mepc_371
          csrw mtvec, x1

          csrr x23, mepc

          j _j_test_u_mepc_371

          _m_trap_from_u_mepc_371:
          bnez x30, _j_end_u_mepc_371

          csrr x25, mcause
          csrr x24, mepc

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mepc_371:
        
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
          
    _jdo371:
    li x25, 0xDEADBEA7

    csrrw x1, mepc, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo372:
    li x25, 0xDEADBEA7

    csrrw x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo373:
    li x25, 0xDEADBEA7

    csrrwi x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo374:
    li x25, 0xDEADBEA7

    csrrs x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo375:
    li x25, 0xDEADBEA7

    csrrc x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo376:
    li x25, 0xDEADBEA7

    csrrsi x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo377:
    li x25, 0xDEADBEA7

    csrrci x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_mepc_371:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mepc_378
          csrw mtvec, x1

          csrr x23, mepc

          j _j_test_s_mepc_378

          _m_trap_from_s_mepc_378:
          bnez x30, _j_end_s_mepc_378

          csrr x25, mcause
          csrr x24, mepc

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mepc_378:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo378:
    li x25, 0xDEADBEA7

    csrrw x1, mepc, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo379:
    li x25, 0xDEADBEA7

    csrrw x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo380:
    li x25, 0xDEADBEA7

    csrrwi x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo381:
    li x25, 0xDEADBEA7

    csrrs x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo382:
    li x25, 0xDEADBEA7

    csrrc x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo383:
    li x25, 0xDEADBEA7

    csrrsi x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo384:
    li x25, 0xDEADBEA7

    csrrci x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_s_mepc_378:
        
          li x30, 0
          la x1, _m_trap_from_u_mepc_385
          csrw mtvec, x1

          csrr x23, mepc

          j _j_test_u_mepc_385

          _m_trap_from_u_mepc_385:
          bnez x30, _j_end_u_mepc_385

          csrr x25, mcause
          csrr x24, mepc

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mepc_385:
        
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
          
    _jdo385:
    li x25, 0xDEADBEA7

    csrrw x1, mepc, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo386:
    li x25, 0xDEADBEA7

    csrrw x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo387:
    li x25, 0xDEADBEA7

    csrrwi x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo388:
    li x25, 0xDEADBEA7

    csrrs x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo389:
    li x25, 0xDEADBEA7

    csrrc x0, mepc, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo390:
    li x25, 0xDEADBEA7

    csrrsi x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo391:
    li x25, 0xDEADBEA7

    csrrci x0, mepc, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_mepc_385:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mcause_392
          csrw mtvec, x1

          csrr x23, mcause

          j _j_test_s_mcause_392

          _m_trap_from_s_mcause_392:
          bnez x30, _j_end_s_mcause_392

          csrr x25, mcause
          csrr x24, mcause

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mcause_392:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo392:
    li x25, 0xDEADBEA7

    csrrw x1, mcause, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo393:
    li x25, 0xDEADBEA7

    csrrw x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo394:
    li x25, 0xDEADBEA7

    csrrwi x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo395:
    li x25, 0xDEADBEA7

    csrrs x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo396:
    li x25, 0xDEADBEA7

    csrrc x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo397:
    li x25, 0xDEADBEA7

    csrrsi x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo398:
    li x25, 0xDEADBEA7

    csrrci x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_s_mcause_392:
        
          li x30, 0
          la x1, _m_trap_from_u_mcause_399
          csrw mtvec, x1

          csrr x23, mcause

          j _j_test_u_mcause_399

          _m_trap_from_u_mcause_399:
          bnez x30, _j_end_u_mcause_399

          csrr x25, mcause
          csrr x24, mcause

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mcause_399:
        
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
          
    _jdo399:
    li x25, 0xDEADBEA7

    csrrw x1, mcause, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo400:
    li x25, 0xDEADBEA7

    csrrw x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo401:
    li x25, 0xDEADBEA7

    csrrwi x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo402:
    li x25, 0xDEADBEA7

    csrrs x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo403:
    li x25, 0xDEADBEA7

    csrrc x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo404:
    li x25, 0xDEADBEA7

    csrrsi x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo405:
    li x25, 0xDEADBEA7

    csrrci x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_mcause_399:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mcause_406
          csrw mtvec, x1

          csrr x23, mcause

          j _j_test_s_mcause_406

          _m_trap_from_s_mcause_406:
          bnez x30, _j_end_s_mcause_406

          csrr x25, mcause
          csrr x24, mcause

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mcause_406:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo406:
    li x25, 0xDEADBEA7

    csrrw x1, mcause, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo407:
    li x25, 0xDEADBEA7

    csrrw x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo408:
    li x25, 0xDEADBEA7

    csrrwi x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo409:
    li x25, 0xDEADBEA7

    csrrs x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo410:
    li x25, 0xDEADBEA7

    csrrc x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo411:
    li x25, 0xDEADBEA7

    csrrsi x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo412:
    li x25, 0xDEADBEA7

    csrrci x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_s_mcause_406:
        
          li x30, 0
          la x1, _m_trap_from_u_mcause_413
          csrw mtvec, x1

          csrr x23, mcause

          j _j_test_u_mcause_413

          _m_trap_from_u_mcause_413:
          bnez x30, _j_end_u_mcause_413

          csrr x25, mcause
          csrr x24, mcause

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mcause_413:
        
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
          
    _jdo413:
    li x25, 0xDEADBEA7

    csrrw x1, mcause, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo414:
    li x25, 0xDEADBEA7

    csrrw x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo415:
    li x25, 0xDEADBEA7

    csrrwi x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo416:
    li x25, 0xDEADBEA7

    csrrs x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo417:
    li x25, 0xDEADBEA7

    csrrc x0, mcause, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo418:
    li x25, 0xDEADBEA7

    csrrsi x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo419:
    li x25, 0xDEADBEA7

    csrrci x0, mcause, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_mcause_413:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mtval_420
          csrw mtvec, x1

          csrr x23, mtval

          j _j_test_s_mtval_420

          _m_trap_from_s_mtval_420:
          bnez x30, _j_end_s_mtval_420

          csrr x25, mcause
          csrr x24, mtval

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mtval_420:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo420:
    li x25, 0xDEADBEA7

    csrrw x1, mtval, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo421:
    li x25, 0xDEADBEA7

    csrrw x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo422:
    li x25, 0xDEADBEA7

    csrrwi x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo423:
    li x25, 0xDEADBEA7

    csrrs x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo424:
    li x25, 0xDEADBEA7

    csrrc x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo425:
    li x25, 0xDEADBEA7

    csrrsi x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo426:
    li x25, 0xDEADBEA7

    csrrci x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_s_mtval_420:
        
          li x30, 0
          la x1, _m_trap_from_u_mtval_427
          csrw mtvec, x1

          csrr x23, mtval

          j _j_test_u_mtval_427

          _m_trap_from_u_mtval_427:
          bnez x30, _j_end_u_mtval_427

          csrr x25, mcause
          csrr x24, mtval

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mtval_427:
        
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
          
    _jdo427:
    li x25, 0xDEADBEA7

    csrrw x1, mtval, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo428:
    li x25, 0xDEADBEA7

    csrrw x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo429:
    li x25, 0xDEADBEA7

    csrrwi x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo430:
    li x25, 0xDEADBEA7

    csrrs x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo431:
    li x25, 0xDEADBEA7

    csrrc x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo432:
    li x25, 0xDEADBEA7

    csrrsi x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo433:
    li x25, 0xDEADBEA7

    csrrci x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_mtval_427:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mtval_434
          csrw mtvec, x1

          csrr x23, mtval

          j _j_test_s_mtval_434

          _m_trap_from_s_mtval_434:
          bnez x30, _j_end_s_mtval_434

          csrr x25, mcause
          csrr x24, mtval

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mtval_434:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo434:
    li x25, 0xDEADBEA7

    csrrw x1, mtval, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo435:
    li x25, 0xDEADBEA7

    csrrw x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo436:
    li x25, 0xDEADBEA7

    csrrwi x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo437:
    li x25, 0xDEADBEA7

    csrrs x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo438:
    li x25, 0xDEADBEA7

    csrrc x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo439:
    li x25, 0xDEADBEA7

    csrrsi x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo440:
    li x25, 0xDEADBEA7

    csrrci x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_s_mtval_434:
        
          li x30, 0
          la x1, _m_trap_from_u_mtval_441
          csrw mtvec, x1

          csrr x23, mtval

          j _j_test_u_mtval_441

          _m_trap_from_u_mtval_441:
          bnez x30, _j_end_u_mtval_441

          csrr x25, mcause
          csrr x24, mtval

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mtval_441:
        
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
          
    _jdo441:
    li x25, 0xDEADBEA7

    csrrw x1, mtval, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo442:
    li x25, 0xDEADBEA7

    csrrw x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo443:
    li x25, 0xDEADBEA7

    csrrwi x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo444:
    li x25, 0xDEADBEA7

    csrrs x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo445:
    li x25, 0xDEADBEA7

    csrrc x0, mtval, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo446:
    li x25, 0xDEADBEA7

    csrrsi x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
    _jdo447:
    li x25, 0xDEADBEA7

    csrrci x0, mtval, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
          li x30, 1
          ebreak
          _j_end_u_mtval_441:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mip_448
          csrw mtvec, x1

          csrr x23, mip

          j _j_test_s_mip_448

          _m_trap_from_s_mip_448:
          bnez x30, _j_end_s_mip_448

          csrr x25, mcause
          csrr x24, mip

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mip_448:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo448:
    li x25, 0xDEADBEA7

    csrrw x1, mip, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo450:
    li x25, 0xDEADBEA7

    csrrw x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo452:
    li x25, 0xDEADBEA7

    csrrwi x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo454:
    li x25, 0xDEADBEA7

    csrrs x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo456:
    li x25, 0xDEADBEA7

    csrrc x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo458:
    li x25, 0xDEADBEA7

    csrrsi x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo460:
    li x25, 0xDEADBEA7

    csrrci x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mip_448:
        
          li x30, 0
          la x1, _m_trap_from_u_mip_462
          csrw mtvec, x1

          csrr x23, mip

          j _j_test_u_mip_462

          _m_trap_from_u_mip_462:
          bnez x30, _j_end_u_mip_462

          csrr x25, mcause
          csrr x24, mip

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mip_462:
        
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
          
    _jdo462:
    li x25, 0xDEADBEA7

    csrrw x1, mip, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo464:
    li x25, 0xDEADBEA7

    csrrw x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo466:
    li x25, 0xDEADBEA7

    csrrwi x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo468:
    li x25, 0xDEADBEA7

    csrrs x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo470:
    li x25, 0xDEADBEA7

    csrrc x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo472:
    li x25, 0xDEADBEA7

    csrrsi x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo474:
    li x25, 0xDEADBEA7

    csrrci x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mip_462:
        
        li x13, 1
      
          li x30, 0
          la x1, _m_trap_from_s_mip_476
          csrw mtvec, x1

          csrr x23, mip

          j _j_test_s_mip_476

          _m_trap_from_s_mip_476:
          bnez x30, _j_end_s_mip_476

          csrr x25, mcause
          csrr x24, mip

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_s_mip_476:
        
          li x1, 0b110000000000
          csrrc x0, mstatus, x1
          li x1, 0b0100000000000
          csrrs x0, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the mret instruction
          csrw mepc, x1
          mret

          # We're now in supervisor mode...
        
    _jdo476:
    li x25, 0xDEADBEA7

    csrrw x1, mip, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo478:
    li x25, 0xDEADBEA7

    csrrw x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo480:
    li x25, 0xDEADBEA7

    csrrwi x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo482:
    li x25, 0xDEADBEA7

    csrrs x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo484:
    li x25, 0xDEADBEA7

    csrrc x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo486:
    li x25, 0xDEADBEA7

    csrrsi x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo488:
    li x25, 0xDEADBEA7

    csrrci x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_s_mip_476:
        
          li x30, 0
          la x1, _m_trap_from_u_mip_490
          csrw mtvec, x1

          csrr x23, mip

          j _j_test_u_mip_490

          _m_trap_from_u_mip_490:
          bnez x30, _j_end_u_mip_490

          csrr x25, mcause
          csrr x24, mip

          csrrs x20, mepc, x0
          addi x20, x20, 4
          csrrw x0, mepc, x20
        
          mret

          _j_test_u_mip_490:
        
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
          
    _jdo490:
    li x25, 0xDEADBEA7

    csrrw x1, mip, x0

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo492:
    li x25, 0xDEADBEA7

    csrrw x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo494:
    li x25, 0xDEADBEA7

    csrrwi x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo496:
    li x25, 0xDEADBEA7

    csrrs x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo498:
    li x25, 0xDEADBEA7

    csrrc x0, mip, x13

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo500:
    li x25, 0xDEADBEA7

    csrrsi x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
    _jdo502:
    li x25, 0xDEADBEA7

    csrrci x0, mip, 1

    sd x25, 0(x7)
    addi x7, x7, 8
  
      sub x25, x24, x23
      sd x25, 0(x7)
      addi x7, x7, 8
    
          li x30, 1
          ebreak
          _j_end_u_mip_490:
        
      csrw mtvec, x19
    	# ---------------------------------------------------------------------------------------------
RVMODEL_HALT

RVTEST_DATA_BEGIN
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
# signature output
wally_signature:
.fill 504, 8, -1

#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif
RVMODEL_DATA_END
