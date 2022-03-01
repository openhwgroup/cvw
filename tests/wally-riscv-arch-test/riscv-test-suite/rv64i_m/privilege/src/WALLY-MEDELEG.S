///////////////////////////////////////////
// ../../../imperas-riscv-tests/riscv-test-suite/rv64p/src/WALLY-MEDELEG.S
// dottolia@hmc.edu
// Created 2021-06-15 11:27:30.717084//
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
        csrr x18, medeleg
        csrr x17, medeleg
      
        _start_0:

        la x1, _j_m_trap_0
        csrw mtvec, x1
        la x1, _j_s_trap_0
        csrw stvec, x1

        j _j_test_0

        _j_m_trap_0:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_0
        mret

        _j_s_trap_0:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_0
        sret

        _j_goto_machine_mode_0:
        li x30, 1
        ebreak

        _j_test_0:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 4
        csrw medeleg, x1
      
          
          
    .fill 1, 4, 0
  
        
  sd x25, 0(x6)

        _j_finished_0:
        li x30, 0
      
        _start_1:

        la x1, _j_m_trap_1
        csrw mtvec, x1
        la x1, _j_s_trap_1
        csrw stvec, x1

        j _j_test_1

        _j_m_trap_1:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_1
        mret

        _j_s_trap_1:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_1
        sret

        _j_goto_machine_mode_1:
        li x30, 1
        ebreak

        _j_test_1:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          
    .fill 1, 4, 0
  
        
  sd x25, 8(x6)

        _j_finished_1:
        li x30, 0
      
        _start_2:

        la x1, _j_m_trap_2
        csrw mtvec, x1
        la x1, _j_s_trap_2
        csrw stvec, x1

        j _j_test_2

        _j_m_trap_2:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_2
        mret

        _j_s_trap_2:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_2
        sret

        _j_goto_machine_mode_2:
        li x30, 1
        ebreak

        _j_test_2:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 4
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    .fill 1, 4, 0
  
        
  sd x25, 16(x6)

          j _j_goto_machine_mode_2
        
        _j_finished_2:
        li x30, 0
      
        _start_3:

        la x1, _j_m_trap_3
        csrw mtvec, x1
        la x1, _j_s_trap_3
        csrw stvec, x1

        j _j_test_3

        _j_m_trap_3:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_3
        mret

        _j_s_trap_3:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_3
        sret

        _j_goto_machine_mode_3:
        li x30, 1
        ebreak

        _j_test_3:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    .fill 1, 4, 0
  
        
  sd x25, 24(x6)

          j _j_goto_machine_mode_3
        
        _j_finished_3:
        li x30, 0
      
        _start_4:

        la x1, _j_m_trap_4
        csrw mtvec, x1
        la x1, _j_s_trap_4
        csrw stvec, x1

        j _j_test_4

        _j_m_trap_4:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_4
        mret

        _j_s_trap_4:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_4
        sret

        _j_goto_machine_mode_4:
        li x30, 1
        ebreak

        _j_test_4:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 4
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    .fill 1, 4, 0
  
        
  sd x25, 32(x6)

          j _j_goto_machine_mode_4
        
        _j_finished_4:
        li x30, 0
      
        _start_5:

        la x1, _j_m_trap_5
        csrw mtvec, x1
        la x1, _j_s_trap_5
        csrw stvec, x1

        j _j_test_5

        _j_m_trap_5:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_5
        mret

        _j_s_trap_5:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_5
        sret

        _j_goto_machine_mode_5:
        li x30, 1
        ebreak

        _j_test_5:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    .fill 1, 4, 0
  
        
  sd x25, 40(x6)

          j _j_goto_machine_mode_5
        
        _j_finished_5:
        li x30, 0
      
        _start_6:

        la x1, _j_m_trap_6
        csrw mtvec, x1
        la x1, _j_s_trap_6
        csrw stvec, x1

        j _j_test_6

        _j_m_trap_6:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_6
        mret

        _j_s_trap_6:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_6
        sret

        _j_goto_machine_mode_6:
        li x30, 1
        ecall

        _j_test_6:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 8
        csrw medeleg, x1
      
          
          ebreak
        
  sd x25, 48(x6)

        _j_finished_6:
        li x30, 0
      
        _start_7:

        la x1, _j_m_trap_7
        csrw mtvec, x1
        la x1, _j_s_trap_7
        csrw stvec, x1

        j _j_test_7

        _j_m_trap_7:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_7
        mret

        _j_s_trap_7:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_7
        sret

        _j_goto_machine_mode_7:
        li x30, 1
        ecall

        _j_test_7:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          ebreak
        
  sd x25, 56(x6)

        _j_finished_7:
        li x30, 0
      
        _start_8:

        la x1, _j_m_trap_8
        csrw mtvec, x1
        la x1, _j_s_trap_8
        csrw stvec, x1

        j _j_test_8

        _j_m_trap_8:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_8
        mret

        _j_s_trap_8:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_8
        sret

        _j_goto_machine_mode_8:
        li x30, 1
        ecall

        _j_test_8:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 8
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          ebreak
        
  sd x25, 64(x6)

          j _j_goto_machine_mode_8
        
        _j_finished_8:
        li x30, 0
      
        _start_9:

        la x1, _j_m_trap_9
        csrw mtvec, x1
        la x1, _j_s_trap_9
        csrw stvec, x1

        j _j_test_9

        _j_m_trap_9:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_9
        mret

        _j_s_trap_9:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_9
        sret

        _j_goto_machine_mode_9:
        li x30, 1
        ecall

        _j_test_9:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          ebreak
        
  sd x25, 72(x6)

          j _j_goto_machine_mode_9
        
        _j_finished_9:
        li x30, 0
      
        _start_10:

        la x1, _j_m_trap_10
        csrw mtvec, x1
        la x1, _j_s_trap_10
        csrw stvec, x1

        j _j_test_10

        _j_m_trap_10:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_10
        mret

        _j_s_trap_10:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_10
        sret

        _j_goto_machine_mode_10:
        li x30, 1
        ecall

        _j_test_10:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 8
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          ebreak
        
  sd x25, 80(x6)

          j _j_goto_machine_mode_10
        
        _j_finished_10:
        li x30, 0
      
        _start_11:

        la x1, _j_m_trap_11
        csrw mtvec, x1
        la x1, _j_s_trap_11
        csrw stvec, x1

        j _j_test_11

        _j_m_trap_11:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_11
        mret

        _j_s_trap_11:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_11
        sret

        _j_goto_machine_mode_11:
        li x30, 1
        ecall

        _j_test_11:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          ebreak
        
  sd x25, 88(x6)

          j _j_goto_machine_mode_11
        
        _j_finished_11:
        li x30, 0
      
        _start_12:

        la x1, _j_m_trap_12
        csrw mtvec, x1
        la x1, _j_s_trap_12
        csrw stvec, x1

        j _j_test_12

        _j_m_trap_12:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_12
        mret

        _j_s_trap_12:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_12
        sret

        _j_goto_machine_mode_12:
        li x30, 1
        ebreak

        _j_test_12:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 16
        csrw medeleg, x1
      
          
          
    lw x0, 11(x0)
  
        
  sd x25, 96(x6)

        _j_finished_12:
        li x30, 0
      
        _start_13:

        la x1, _j_m_trap_13
        csrw mtvec, x1
        la x1, _j_s_trap_13
        csrw stvec, x1

        j _j_test_13

        _j_m_trap_13:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_13
        mret

        _j_s_trap_13:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_13
        sret

        _j_goto_machine_mode_13:
        li x30, 1
        ebreak

        _j_test_13:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          
    lw x0, 11(x0)
  
        
  sd x25, 104(x6)

        _j_finished_13:
        li x30, 0
      
        _start_14:

        la x1, _j_m_trap_14
        csrw mtvec, x1
        la x1, _j_s_trap_14
        csrw stvec, x1

        j _j_test_14

        _j_m_trap_14:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_14
        mret

        _j_s_trap_14:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_14
        sret

        _j_goto_machine_mode_14:
        li x30, 1
        ebreak

        _j_test_14:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 16
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    lw x0, 11(x0)
  
        
  sd x25, 112(x6)

          j _j_goto_machine_mode_14
        
        _j_finished_14:
        li x30, 0
      
        _start_15:

        la x1, _j_m_trap_15
        csrw mtvec, x1
        la x1, _j_s_trap_15
        csrw stvec, x1

        j _j_test_15

        _j_m_trap_15:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_15
        mret

        _j_s_trap_15:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_15
        sret

        _j_goto_machine_mode_15:
        li x30, 1
        ebreak

        _j_test_15:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    lw x0, 11(x0)
  
        
  sd x25, 120(x6)

          j _j_goto_machine_mode_15
        
        _j_finished_15:
        li x30, 0
      
        _start_16:

        la x1, _j_m_trap_16
        csrw mtvec, x1
        la x1, _j_s_trap_16
        csrw stvec, x1

        j _j_test_16

        _j_m_trap_16:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_16
        mret

        _j_s_trap_16:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_16
        sret

        _j_goto_machine_mode_16:
        li x30, 1
        ebreak

        _j_test_16:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 16
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    lw x0, 11(x0)
  
        
  sd x25, 128(x6)

          j _j_goto_machine_mode_16
        
        _j_finished_16:
        li x30, 0
      
        _start_17:

        la x1, _j_m_trap_17
        csrw mtvec, x1
        la x1, _j_s_trap_17
        csrw stvec, x1

        j _j_test_17

        _j_m_trap_17:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_17
        mret

        _j_s_trap_17:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_17
        sret

        _j_goto_machine_mode_17:
        li x30, 1
        ebreak

        _j_test_17:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    lw x0, 11(x0)
  
        
  sd x25, 136(x6)

          j _j_goto_machine_mode_17
        
        _j_finished_17:
        li x30, 0
      
        _start_18:

        la x1, _j_m_trap_18
        csrw mtvec, x1
        la x1, _j_s_trap_18
        csrw stvec, x1

        j _j_test_18

        _j_m_trap_18:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_18
        mret

        _j_s_trap_18:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_18
        sret

        _j_goto_machine_mode_18:
        li x30, 1
        ebreak

        _j_test_18:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 64
        csrw medeleg, x1
      
          
          
    sw x0, 11(x0)
  
        
  sd x25, 144(x6)

        _j_finished_18:
        li x30, 0
      
        _start_19:

        la x1, _j_m_trap_19
        csrw mtvec, x1
        la x1, _j_s_trap_19
        csrw stvec, x1

        j _j_test_19

        _j_m_trap_19:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_19
        mret

        _j_s_trap_19:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_19
        sret

        _j_goto_machine_mode_19:
        li x30, 1
        ebreak

        _j_test_19:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          
    sw x0, 11(x0)
  
        
  sd x25, 152(x6)

        _j_finished_19:
        li x30, 0
      
        _start_20:

        la x1, _j_m_trap_20
        csrw mtvec, x1
        la x1, _j_s_trap_20
        csrw stvec, x1

        j _j_test_20

        _j_m_trap_20:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_20
        mret

        _j_s_trap_20:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_20
        sret

        _j_goto_machine_mode_20:
        li x30, 1
        ebreak

        _j_test_20:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 64
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    sw x0, 11(x0)
  
        
  sd x25, 160(x6)

          j _j_goto_machine_mode_20
        
        _j_finished_20:
        li x30, 0
      
        _start_21:

        la x1, _j_m_trap_21
        csrw mtvec, x1
        la x1, _j_s_trap_21
        csrw stvec, x1

        j _j_test_21

        _j_m_trap_21:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_21
        mret

        _j_s_trap_21:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_21
        sret

        _j_goto_machine_mode_21:
        li x30, 1
        ebreak

        _j_test_21:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    sw x0, 11(x0)
  
        
  sd x25, 168(x6)

          j _j_goto_machine_mode_21
        
        _j_finished_21:
        li x30, 0
      
        _start_22:

        la x1, _j_m_trap_22
        csrw mtvec, x1
        la x1, _j_s_trap_22
        csrw stvec, x1

        j _j_test_22

        _j_m_trap_22:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_22
        mret

        _j_s_trap_22:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_22
        sret

        _j_goto_machine_mode_22:
        li x30, 1
        ebreak

        _j_test_22:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 64
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    sw x0, 11(x0)
  
        
  sd x25, 176(x6)

          j _j_goto_machine_mode_22
        
        _j_finished_22:
        li x30, 0
      
        _start_23:

        la x1, _j_m_trap_23
        csrw mtvec, x1
        la x1, _j_s_trap_23
        csrw stvec, x1

        j _j_test_23

        _j_m_trap_23:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_23
        mret

        _j_s_trap_23:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_23
        sret

        _j_goto_machine_mode_23:
        li x30, 1
        ebreak

        _j_test_23:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    sw x0, 11(x0)
  
        
  sd x25, 184(x6)

          j _j_goto_machine_mode_23
        
        _j_finished_23:
        li x30, 0
      
        _start_24:

        la x1, _j_m_trap_24
        csrw mtvec, x1
        la x1, _j_s_trap_24
        csrw stvec, x1

        j _j_test_24

        _j_m_trap_24:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_24
        mret

        _j_s_trap_24:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_24
        sret

        _j_goto_machine_mode_24:
        li x30, 1
        ebreak

        _j_test_24:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 2048
        csrw medeleg, x1
      
          
          ecall
        
  sd x25, 192(x6)

        _j_finished_24:
        li x30, 0
      
        _start_25:

        la x1, _j_m_trap_25
        csrw mtvec, x1
        la x1, _j_s_trap_25
        csrw stvec, x1

        j _j_test_25

        _j_m_trap_25:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_25
        mret

        _j_s_trap_25:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_25
        sret

        _j_goto_machine_mode_25:
        li x30, 1
        ebreak

        _j_test_25:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          ecall
        
  sd x25, 200(x6)

        _j_finished_25:
        li x30, 0
      
        _start_26:

        la x1, _j_m_trap_26
        csrw mtvec, x1
        la x1, _j_s_trap_26
        csrw stvec, x1

        j _j_test_26

        _j_m_trap_26:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_26
        mret

        _j_s_trap_26:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_26
        sret

        _j_goto_machine_mode_26:
        li x30, 1
        ebreak

        _j_test_26:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 512
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          ecall
        
  sd x25, 208(x6)

          j _j_goto_machine_mode_26
        
        _j_finished_26:
        li x30, 0
      
        _start_27:

        la x1, _j_m_trap_27
        csrw mtvec, x1
        la x1, _j_s_trap_27
        csrw stvec, x1

        j _j_test_27

        _j_m_trap_27:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_27
        mret

        _j_s_trap_27:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_27
        sret

        _j_goto_machine_mode_27:
        li x30, 1
        ebreak

        _j_test_27:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          ecall
        
  sd x25, 216(x6)

          j _j_goto_machine_mode_27
        
        _j_finished_27:
        li x30, 0
      
        _start_28:

        la x1, _j_m_trap_28
        csrw mtvec, x1
        la x1, _j_s_trap_28
        csrw stvec, x1

        j _j_test_28

        _j_m_trap_28:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_28
        mret

        _j_s_trap_28:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_28
        sret

        _j_goto_machine_mode_28:
        li x30, 1
        ebreak

        _j_test_28:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 256
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          ecall
        
  sd x25, 224(x6)

          j _j_goto_machine_mode_28
        
        _j_finished_28:
        li x30, 0
      
        _start_29:

        la x1, _j_m_trap_29
        csrw mtvec, x1
        la x1, _j_s_trap_29
        csrw stvec, x1

        j _j_test_29

        _j_m_trap_29:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_29
        mret

        _j_s_trap_29:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_29
        sret

        _j_goto_machine_mode_29:
        li x30, 1
        ebreak

        _j_test_29:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          ecall
        
  sd x25, 232(x6)

          j _j_goto_machine_mode_29
        
        _j_finished_29:
        li x30, 0
      
        _start_30:

        la x1, _j_m_trap_30
        csrw mtvec, x1
        la x1, _j_s_trap_30
        csrw stvec, x1

        j _j_test_30

        _j_m_trap_30:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_30
        mret

        _j_s_trap_30:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_30
        sret

        _j_goto_machine_mode_30:
        li x30, 1
        ebreak

        _j_test_30:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 4
        csrw medeleg, x1
      
          
          
    .fill 1, 4, 0
  
        
  sd x25, 240(x6)

        _j_finished_30:
        li x30, 0
      
        _start_31:

        la x1, _j_m_trap_31
        csrw mtvec, x1
        la x1, _j_s_trap_31
        csrw stvec, x1

        j _j_test_31

        _j_m_trap_31:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_31
        mret

        _j_s_trap_31:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_31
        sret

        _j_goto_machine_mode_31:
        li x30, 1
        ebreak

        _j_test_31:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          
    .fill 1, 4, 0
  
        
  sd x25, 248(x6)

        _j_finished_31:
        li x30, 0
      
        _start_32:

        la x1, _j_m_trap_32
        csrw mtvec, x1
        la x1, _j_s_trap_32
        csrw stvec, x1

        j _j_test_32

        _j_m_trap_32:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_32
        mret

        _j_s_trap_32:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_32
        sret

        _j_goto_machine_mode_32:
        li x30, 1
        ebreak

        _j_test_32:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 4
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    .fill 1, 4, 0
  
        
  sd x25, 256(x6)

          j _j_goto_machine_mode_32
        
        _j_finished_32:
        li x30, 0
      
        _start_33:

        la x1, _j_m_trap_33
        csrw mtvec, x1
        la x1, _j_s_trap_33
        csrw stvec, x1

        j _j_test_33

        _j_m_trap_33:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_33
        mret

        _j_s_trap_33:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_33
        sret

        _j_goto_machine_mode_33:
        li x30, 1
        ebreak

        _j_test_33:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    .fill 1, 4, 0
  
        
  sd x25, 264(x6)

          j _j_goto_machine_mode_33
        
        _j_finished_33:
        li x30, 0
      
        _start_34:

        la x1, _j_m_trap_34
        csrw mtvec, x1
        la x1, _j_s_trap_34
        csrw stvec, x1

        j _j_test_34

        _j_m_trap_34:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_34
        mret

        _j_s_trap_34:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_34
        sret

        _j_goto_machine_mode_34:
        li x30, 1
        ebreak

        _j_test_34:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 4
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    .fill 1, 4, 0
  
        
  sd x25, 272(x6)

          j _j_goto_machine_mode_34
        
        _j_finished_34:
        li x30, 0
      
        _start_35:

        la x1, _j_m_trap_35
        csrw mtvec, x1
        la x1, _j_s_trap_35
        csrw stvec, x1

        j _j_test_35

        _j_m_trap_35:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_35
        mret

        _j_s_trap_35:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_35
        sret

        _j_goto_machine_mode_35:
        li x30, 1
        ebreak

        _j_test_35:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    .fill 1, 4, 0
  
        
  sd x25, 280(x6)

          j _j_goto_machine_mode_35
        
        _j_finished_35:
        li x30, 0
      
        _start_36:

        la x1, _j_m_trap_36
        csrw mtvec, x1
        la x1, _j_s_trap_36
        csrw stvec, x1

        j _j_test_36

        _j_m_trap_36:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_36
        mret

        _j_s_trap_36:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_36
        sret

        _j_goto_machine_mode_36:
        li x30, 1
        ecall

        _j_test_36:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 8
        csrw medeleg, x1
      
          
          ebreak
        
  sd x25, 288(x6)

        _j_finished_36:
        li x30, 0
      
        _start_37:

        la x1, _j_m_trap_37
        csrw mtvec, x1
        la x1, _j_s_trap_37
        csrw stvec, x1

        j _j_test_37

        _j_m_trap_37:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_37
        mret

        _j_s_trap_37:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_37
        sret

        _j_goto_machine_mode_37:
        li x30, 1
        ecall

        _j_test_37:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          ebreak
        
  sd x25, 296(x6)

        _j_finished_37:
        li x30, 0
      
        _start_38:

        la x1, _j_m_trap_38
        csrw mtvec, x1
        la x1, _j_s_trap_38
        csrw stvec, x1

        j _j_test_38

        _j_m_trap_38:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_38
        mret

        _j_s_trap_38:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_38
        sret

        _j_goto_machine_mode_38:
        li x30, 1
        ecall

        _j_test_38:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 8
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          ebreak
        
  sd x25, 304(x6)

          j _j_goto_machine_mode_38
        
        _j_finished_38:
        li x30, 0
      
        _start_39:

        la x1, _j_m_trap_39
        csrw mtvec, x1
        la x1, _j_s_trap_39
        csrw stvec, x1

        j _j_test_39

        _j_m_trap_39:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_39
        mret

        _j_s_trap_39:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_39
        sret

        _j_goto_machine_mode_39:
        li x30, 1
        ecall

        _j_test_39:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          ebreak
        
  sd x25, 312(x6)

          j _j_goto_machine_mode_39
        
        _j_finished_39:
        li x30, 0
      
        _start_40:

        la x1, _j_m_trap_40
        csrw mtvec, x1
        la x1, _j_s_trap_40
        csrw stvec, x1

        j _j_test_40

        _j_m_trap_40:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_40
        mret

        _j_s_trap_40:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_40
        sret

        _j_goto_machine_mode_40:
        li x30, 1
        ecall

        _j_test_40:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 8
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          ebreak
        
  sd x25, 320(x6)

          j _j_goto_machine_mode_40
        
        _j_finished_40:
        li x30, 0
      
        _start_41:

        la x1, _j_m_trap_41
        csrw mtvec, x1
        la x1, _j_s_trap_41
        csrw stvec, x1

        j _j_test_41

        _j_m_trap_41:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_41
        mret

        _j_s_trap_41:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_41
        sret

        _j_goto_machine_mode_41:
        li x30, 1
        ecall

        _j_test_41:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          ebreak
        
  sd x25, 328(x6)

          j _j_goto_machine_mode_41
        
        _j_finished_41:
        li x30, 0
      
        _start_42:

        la x1, _j_m_trap_42
        csrw mtvec, x1
        la x1, _j_s_trap_42
        csrw stvec, x1

        j _j_test_42

        _j_m_trap_42:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_42
        mret

        _j_s_trap_42:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_42
        sret

        _j_goto_machine_mode_42:
        li x30, 1
        ebreak

        _j_test_42:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 16
        csrw medeleg, x1
      
          
          
    lw x0, 11(x0)
  
        
  sd x25, 336(x6)

        _j_finished_42:
        li x30, 0
      
        _start_43:

        la x1, _j_m_trap_43
        csrw mtvec, x1
        la x1, _j_s_trap_43
        csrw stvec, x1

        j _j_test_43

        _j_m_trap_43:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_43
        mret

        _j_s_trap_43:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_43
        sret

        _j_goto_machine_mode_43:
        li x30, 1
        ebreak

        _j_test_43:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          
    lw x0, 11(x0)
  
        
  sd x25, 344(x6)

        _j_finished_43:
        li x30, 0
      
        _start_44:

        la x1, _j_m_trap_44
        csrw mtvec, x1
        la x1, _j_s_trap_44
        csrw stvec, x1

        j _j_test_44

        _j_m_trap_44:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_44
        mret

        _j_s_trap_44:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_44
        sret

        _j_goto_machine_mode_44:
        li x30, 1
        ebreak

        _j_test_44:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 16
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    lw x0, 11(x0)
  
        
  sd x25, 352(x6)

          j _j_goto_machine_mode_44
        
        _j_finished_44:
        li x30, 0
      
        _start_45:

        la x1, _j_m_trap_45
        csrw mtvec, x1
        la x1, _j_s_trap_45
        csrw stvec, x1

        j _j_test_45

        _j_m_trap_45:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_45
        mret

        _j_s_trap_45:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_45
        sret

        _j_goto_machine_mode_45:
        li x30, 1
        ebreak

        _j_test_45:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    lw x0, 11(x0)
  
        
  sd x25, 360(x6)

          j _j_goto_machine_mode_45
        
        _j_finished_45:
        li x30, 0
      
        _start_46:

        la x1, _j_m_trap_46
        csrw mtvec, x1
        la x1, _j_s_trap_46
        csrw stvec, x1

        j _j_test_46

        _j_m_trap_46:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_46
        mret

        _j_s_trap_46:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_46
        sret

        _j_goto_machine_mode_46:
        li x30, 1
        ebreak

        _j_test_46:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 16
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    lw x0, 11(x0)
  
        
  sd x25, 368(x6)

          j _j_goto_machine_mode_46
        
        _j_finished_46:
        li x30, 0
      
        _start_47:

        la x1, _j_m_trap_47
        csrw mtvec, x1
        la x1, _j_s_trap_47
        csrw stvec, x1

        j _j_test_47

        _j_m_trap_47:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_47
        mret

        _j_s_trap_47:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_47
        sret

        _j_goto_machine_mode_47:
        li x30, 1
        ebreak

        _j_test_47:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    lw x0, 11(x0)
  
        
  sd x25, 376(x6)

          j _j_goto_machine_mode_47
        
        _j_finished_47:
        li x30, 0
      
        _start_48:

        la x1, _j_m_trap_48
        csrw mtvec, x1
        la x1, _j_s_trap_48
        csrw stvec, x1

        j _j_test_48

        _j_m_trap_48:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_48
        mret

        _j_s_trap_48:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_48
        sret

        _j_goto_machine_mode_48:
        li x30, 1
        ebreak

        _j_test_48:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 64
        csrw medeleg, x1
      
          
          
    sw x0, 11(x0)
  
        
  sd x25, 384(x6)

        _j_finished_48:
        li x30, 0
      
        _start_49:

        la x1, _j_m_trap_49
        csrw mtvec, x1
        la x1, _j_s_trap_49
        csrw stvec, x1

        j _j_test_49

        _j_m_trap_49:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_49
        mret

        _j_s_trap_49:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_49
        sret

        _j_goto_machine_mode_49:
        li x30, 1
        ebreak

        _j_test_49:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          
    sw x0, 11(x0)
  
        
  sd x25, 392(x6)

        _j_finished_49:
        li x30, 0
      
        _start_50:

        la x1, _j_m_trap_50
        csrw mtvec, x1
        la x1, _j_s_trap_50
        csrw stvec, x1

        j _j_test_50

        _j_m_trap_50:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_50
        mret

        _j_s_trap_50:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_50
        sret

        _j_goto_machine_mode_50:
        li x30, 1
        ebreak

        _j_test_50:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 64
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    sw x0, 11(x0)
  
        
  sd x25, 400(x6)

          j _j_goto_machine_mode_50
        
        _j_finished_50:
        li x30, 0
      
        _start_51:

        la x1, _j_m_trap_51
        csrw mtvec, x1
        la x1, _j_s_trap_51
        csrw stvec, x1

        j _j_test_51

        _j_m_trap_51:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_51
        mret

        _j_s_trap_51:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_51
        sret

        _j_goto_machine_mode_51:
        li x30, 1
        ebreak

        _j_test_51:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          
    sw x0, 11(x0)
  
        
  sd x25, 408(x6)

          j _j_goto_machine_mode_51
        
        _j_finished_51:
        li x30, 0
      
        _start_52:

        la x1, _j_m_trap_52
        csrw mtvec, x1
        la x1, _j_s_trap_52
        csrw stvec, x1

        j _j_test_52

        _j_m_trap_52:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_52
        mret

        _j_s_trap_52:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_52
        sret

        _j_goto_machine_mode_52:
        li x30, 1
        ebreak

        _j_test_52:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 64
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    sw x0, 11(x0)
  
        
  sd x25, 416(x6)

          j _j_goto_machine_mode_52
        
        _j_finished_52:
        li x30, 0
      
        _start_53:

        la x1, _j_m_trap_53
        csrw mtvec, x1
        la x1, _j_s_trap_53
        csrw stvec, x1

        j _j_test_53

        _j_m_trap_53:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_53
        mret

        _j_s_trap_53:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_53
        sret

        _j_goto_machine_mode_53:
        li x30, 1
        ebreak

        _j_test_53:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          
    sw x0, 11(x0)
  
        
  sd x25, 424(x6)

          j _j_goto_machine_mode_53
        
        _j_finished_53:
        li x30, 0
      
        _start_54:

        la x1, _j_m_trap_54
        csrw mtvec, x1
        la x1, _j_s_trap_54
        csrw stvec, x1

        j _j_test_54

        _j_m_trap_54:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_54
        mret

        _j_s_trap_54:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_54
        sret

        _j_goto_machine_mode_54:
        li x30, 1
        ebreak

        _j_test_54:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 2048
        csrw medeleg, x1
      
          
          ecall
        
  sd x25, 432(x6)

        _j_finished_54:
        li x30, 0
      
        _start_55:

        la x1, _j_m_trap_55
        csrw mtvec, x1
        la x1, _j_s_trap_55
        csrw stvec, x1

        j _j_test_55

        _j_m_trap_55:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_55
        mret

        _j_s_trap_55:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_55
        sret

        _j_goto_machine_mode_55:
        li x30, 1
        ebreak

        _j_test_55:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      
          
          ecall
        
  sd x25, 440(x6)

        _j_finished_55:
        li x30, 0
      
        _start_56:

        la x1, _j_m_trap_56
        csrw mtvec, x1
        la x1, _j_s_trap_56
        csrw stvec, x1

        j _j_test_56

        _j_m_trap_56:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_56
        mret

        _j_s_trap_56:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_56
        sret

        _j_goto_machine_mode_56:
        li x30, 1
        ebreak

        _j_test_56:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 512
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          ecall
        
  sd x25, 448(x6)

          j _j_goto_machine_mode_56
        
        _j_finished_56:
        li x30, 0
      
        _start_57:

        la x1, _j_m_trap_57
        csrw mtvec, x1
        la x1, _j_s_trap_57
        csrw stvec, x1

        j _j_test_57

        _j_m_trap_57:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_57
        mret

        _j_s_trap_57:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_57
        sret

        _j_goto_machine_mode_57:
        li x30, 1
        ebreak

        _j_test_57:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0100000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in s mode...
          ecall
        
  sd x25, 456(x6)

          j _j_goto_machine_mode_57
        
        _j_finished_57:
        li x30, 0
      
        _start_58:

        la x1, _j_m_trap_58
        csrw mtvec, x1
        la x1, _j_s_trap_58
        csrw stvec, x1

        j _j_test_58

        _j_m_trap_58:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_58
        mret

        _j_s_trap_58:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_58
        sret

        _j_goto_machine_mode_58:
        li x30, 1
        ebreak

        _j_test_58:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 256
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          ecall
        
  sd x25, 464(x6)

          j _j_goto_machine_mode_58
        
        _j_finished_58:
        li x30, 0
      
        _start_59:

        la x1, _j_m_trap_59
        csrw mtvec, x1
        la x1, _j_s_trap_59
        csrw stvec, x1

        j _j_test_59

        _j_m_trap_59:
        
        li x25, 3

        csrr x1, mepc
        addi x1, x1, 4
        csrrw x0, mepc, x1
        bnez x30, _j_finished_59
        mret

        _j_s_trap_59:
        
        li x25, 1

        csrr x1, sepc
        addi x1, x1, 4
        csrrw x0, sepc, x1
        bnez x30, _j_goto_machine_mode_59
        sret

        _j_goto_machine_mode_59:
        li x30, 1
        ebreak

        _j_test_59:
      
    li x25, 0xDEADBEA7
    
          
        li x1, 0
        csrw medeleg, x1
      

          

          li x1, 0b110000000000
          csrrc x31, mstatus, x1
          li x1, 0b0000000000000
          csrrs x31, mstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the ret instruction
          csrrw x27, mepc, x1
          mret

          # From m, we're now in u mode...
          ecall
        
  sd x25, 472(x6)

          j _j_goto_machine_mode_59
        
        _j_finished_59:
        li x30, 0
      
        csrw mtvec, x19
        csrw medeleg, x18
        csrw mideleg, x17
      	# ---------------------------------------------------------------------------------------------
RVMODEL_HALT

RVTEST_DATA_BEGIN
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
# signature output
wally_signature:
.fill 60, 8, -1

#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif
RVMODEL_DATA_END
