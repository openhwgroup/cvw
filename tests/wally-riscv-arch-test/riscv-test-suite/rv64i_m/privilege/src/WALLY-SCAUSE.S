///////////////////////////////////////////
// ../../../imperas-riscv-tests/riscv-test-suite/rv64p/src/WALLY-SCAUSE.S
// dottolia@hmc.edu
// Created 2021-06-16 16:18:36.397499//
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

        slli  a0,a0,0x1f
        slli  a0,a0,0x1e
        slli  a0,a0,0x1d
        slli  a0,a0,0x1c
        slli  a0,a0,0x1b
        slli  a0,a0,0x1a
        slli  a0,a0,0x19
      
        # Reset x30 to 0 so we can run the tests. We'll set this to 1 when tests are completed so we stay in machine mode
        li x30, 0

        # Set up 
        la x1, _j_m_trap_ebreak
        csrw mtvec, x1
        la x1, _j_s_trap_ebreak
        csrw stvec, x1
        la x1, _j_u_trap_ebreak
        # csrw utvec, x1 # user mode traps are not supported

        # Start the tests!
        j _j_t_begin_ebreak

        # Machine mode traps
        _j_m_trap_ebreak:
        li x25, 0xBAD00003

        csrrs x20, mepc, x0
        addi x20, x20, 4
        csrrw x0, mepc, x20
        bnez x30, _j_all_end_ebreak
        mret

        # Supervisor mode traps
        _j_s_trap_ebreak:
        
        auipc x27, 0
        addi x27, x27, 12
        jr x28
      

        csrrs x20, sepc, x0
        addi x20, x20, 4
        csrrw x0, sepc, x20
        bnez x30, _j_goto_machine_mode_ebreak
        sret

        # Unused: user mode traps are no longer supported
        _j_u_trap_ebreak:
        li x25, 0xBAD00000

        csrrs x20, uepc, x0
        addi x20, x20, 4
        csrrw x0, uepc, x20
        bnez x30, _j_goto_supervisor_mode_ebreak
        uret

        # Currently unused. Just jumps to _j_goto_machine_mode. If you actually
        # want to implement this, you'll likely need to reset sedeleg here
        # and then cause an exception with ebreak (based on my intuition. Try that first, but I could be missing something / just wrong)
        _j_goto_supervisor_mode_ebreak:
        j _j_goto_machine_mode_ebreak

        _j_goto_machine_mode_ebreak:
        li x30, 1 # This will cause us to branch to _j_all_end_ebreak in the machine trap handler, which we'll get into by invoking...
        ebreak # ... this instruction!

        # Run the actual tests!
        _j_t_begin_ebreak:
      
        csrr x18, medeleg
        li x9, 0b1111111111110111
        csrw medeleg, x9

        csrr x16, mideleg
        li x9, 0xffffffff
        csrw mideleg, x9
      
            li x1, 0b110000000000
            csrrc x31, mstatus, x1
            li x1, 0b0100000000000
            csrrs x31, mstatus, x1

            auipc x1, 0
            addi x1, x1, 16 # x1 is now right after the mret instruction
            csrw mepc, x1
            mret

            # We're now in supervisor mode...
          
    la x28, _jtest0
    j _jdo0

    _jtest0:
    
    csrr x25, scause
  
    
    jr x27

    _jdo0:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 0(x6)
  
    la x28, _jtest1
    j _jdo1

    _jtest1:
    
    csrr x25, scause
  
    
    jr x27

    _jdo1:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 8(x6)
  
    la x28, _jtest2
    j _jdo2

    _jtest2:
    
    csrr x25, scause
  
    
    jr x27

    _jdo2:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 16(x6)
  
    la x28, _jtest3
    j _jdo3

    _jtest3:
    
    csrr x25, scause
  
    
    jr x27

    _jdo3:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 24(x6)
  
    la x28, _jtest4
    j _jdo4

    _jtest4:
    
    csrr x25, scause
  
    
    jr x27

    _jdo4:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 32(x6)
  
    la x28, _jtest5
    j _jdo5

    _jtest5:
    
    csrr x25, scause
  
    
    jr x27

    _jdo5:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 40(x6)
  
    la x28, _jtest6
    j _jdo6

    _jtest6:
    
    csrr x25, scause
  
    
    jr x27

    _jdo6:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 48(x6)
  
    la x28, _jtest7
    j _jdo7

    _jtest7:
    
    csrr x25, scause
  
    
    jr x27

    _jdo7:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 56(x6)
  
    la x28, _jtest8
    j _jdo8

    _jtest8:
    
    csrr x25, scause
  
    
    jr x27

    _jdo8:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 64(x6)
  
    la x28, _jtest9
    j _jdo9

    _jtest9:
    
    csrr x25, scause
  
    
    jr x27

    _jdo9:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 72(x6)
  
    la x28, _jtest10
    j _jdo10

    _jtest10:
    
    csrr x25, scause
  
    
    jr x27

    _jdo10:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 80(x6)
  
    la x28, _jtest11
    j _jdo11

    _jtest11:
    
    csrr x25, scause
  
    
    jr x27

    _jdo11:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 88(x6)
  
    la x28, _jtest12
    j _jdo12

    _jtest12:
    
    csrr x25, scause
  
    
    jr x27

    _jdo12:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 96(x6)
  
    la x28, _jtest13
    j _jdo13

    _jtest13:
    
    csrr x25, scause
  
    
    jr x27

    _jdo13:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 104(x6)
  
    la x28, _jtest14
    j _jdo14

    _jtest14:
    
    csrr x25, scause
  
    
    jr x27

    _jdo14:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 112(x6)
  
    la x28, _jtest15
    j _jdo15

    _jtest15:
    
    csrr x25, scause
  
    
    jr x27

    _jdo15:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 120(x6)
  
    la x28, _jtest16
    j _jdo16

    _jtest16:
    
    csrr x25, scause
  
    
    jr x27

    _jdo16:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 128(x6)
  
    la x28, _jtest17
    j _jdo17

    _jtest17:
    
    csrr x25, scause
  
    
    jr x27

    _jdo17:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 136(x6)
  
    la x28, _jtest18
    j _jdo18

    _jtest18:
    
    csrr x25, scause
  
    
    jr x27

    _jdo18:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 144(x6)
  
    la x28, _jtest19
    j _jdo19

    _jtest19:
    
    csrr x25, scause
  
    
    jr x27

    _jdo19:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 152(x6)
  
    la x28, _jtest20
    j _jdo20

    _jtest20:
    
    csrr x25, scause
  
    
    jr x27

    _jdo20:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 160(x6)
  
    la x28, _jtest21
    j _jdo21

    _jtest21:
    
    csrr x25, scause
  
    
    jr x27

    _jdo21:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 168(x6)
  
    la x28, _jtest22
    j _jdo22

    _jtest22:
    
    csrr x25, scause
  
    
    jr x27

    _jdo22:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 176(x6)
  
    la x28, _jtest23
    j _jdo23

    _jtest23:
    
    csrr x25, scause
  
    
    jr x27

    _jdo23:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 184(x6)
  
    la x28, _jtest24
    j _jdo24

    _jtest24:
    
    csrr x25, scause
  
    
    jr x27

    _jdo24:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 192(x6)
  
    la x28, _jtest25
    j _jdo25

    _jtest25:
    
    csrr x25, scause
  
    
    jr x27

    _jdo25:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 200(x6)
  
    la x28, _jtest26
    j _jdo26

    _jtest26:
    
    csrr x25, scause
  
    
    jr x27

    _jdo26:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 208(x6)
  
    la x28, _jtest27
    j _jdo27

    _jtest27:
    
    csrr x25, scause
  
    
    jr x27

    _jdo27:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 216(x6)
  
    la x28, _jtest28
    j _jdo28

    _jtest28:
    
    csrr x25, scause
  
    
    jr x27

    _jdo28:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 224(x6)
  
    la x28, _jtest29
    j _jdo29

    _jtest29:
    
    csrr x25, scause
  
    
    jr x27

    _jdo29:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 232(x6)
  
    la x28, _jtest30
    j _jdo30

    _jtest30:
    
    csrr x25, scause
  
    
    jr x27

    _jdo30:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 240(x6)
  
    la x28, _jtest31
    j _jdo31

    _jtest31:
    
    csrr x25, scause
  
    
    jr x27

    _jdo31:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 248(x6)
  
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
          
    la x28, _jtest32
    j _jdo32

    _jtest32:
    
    csrr x25, scause
  
    
    jr x27

    _jdo32:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 256(x6)
  
    la x28, _jtest33
    j _jdo33

    _jtest33:
    
    csrr x25, scause
  
    
    jr x27

    _jdo33:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 264(x6)
  
    la x28, _jtest34
    j _jdo34

    _jtest34:
    
    csrr x25, scause
  
    
    jr x27

    _jdo34:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 272(x6)
  
    la x28, _jtest35
    j _jdo35

    _jtest35:
    
    csrr x25, scause
  
    
    jr x27

    _jdo35:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 280(x6)
  
    la x28, _jtest36
    j _jdo36

    _jtest36:
    
    csrr x25, scause
  
    
    jr x27

    _jdo36:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 288(x6)
  
    la x28, _jtest37
    j _jdo37

    _jtest37:
    
    csrr x25, scause
  
    
    jr x27

    _jdo37:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 296(x6)
  
    la x28, _jtest38
    j _jdo38

    _jtest38:
    
    csrr x25, scause
  
    
    jr x27

    _jdo38:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 304(x6)
  
    la x28, _jtest39
    j _jdo39

    _jtest39:
    
    csrr x25, scause
  
    
    jr x27

    _jdo39:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 312(x6)
  
    la x28, _jtest40
    j _jdo40

    _jtest40:
    
    csrr x25, scause
  
    
    jr x27

    _jdo40:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 320(x6)
  
    la x28, _jtest41
    j _jdo41

    _jtest41:
    
    csrr x25, scause
  
    
    jr x27

    _jdo41:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 328(x6)
  
    la x28, _jtest42
    j _jdo42

    _jtest42:
    
    csrr x25, scause
  
    
    jr x27

    _jdo42:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 336(x6)
  
    la x28, _jtest43
    j _jdo43

    _jtest43:
    
    csrr x25, scause
  
    
    jr x27

    _jdo43:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 344(x6)
  
    la x28, _jtest44
    j _jdo44

    _jtest44:
    
    csrr x25, scause
  
    
    jr x27

    _jdo44:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 352(x6)
  
    la x28, _jtest45
    j _jdo45

    _jtest45:
    
    csrr x25, scause
  
    
    jr x27

    _jdo45:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 360(x6)
  
    la x28, _jtest46
    j _jdo46

    _jtest46:
    
    csrr x25, scause
  
    
    jr x27

    _jdo46:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 368(x6)
  
    la x28, _jtest47
    j _jdo47

    _jtest47:
    
    csrr x25, scause
  
    
    jr x27

    _jdo47:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 376(x6)
  
    la x28, _jtest48
    j _jdo48

    _jtest48:
    
    csrr x25, scause
  
    
    jr x27

    _jdo48:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 384(x6)
  
    la x28, _jtest49
    j _jdo49

    _jtest49:
    
    csrr x25, scause
  
    
    jr x27

    _jdo49:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 392(x6)
  
    la x28, _jtest50
    j _jdo50

    _jtest50:
    
    csrr x25, scause
  
    
    jr x27

    _jdo50:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 400(x6)
  
    la x28, _jtest51
    j _jdo51

    _jtest51:
    
    csrr x25, scause
  
    
    jr x27

    _jdo51:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 408(x6)
  
    la x28, _jtest52
    j _jdo52

    _jtest52:
    
    csrr x25, scause
  
    
    jr x27

    _jdo52:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 416(x6)
  
    la x28, _jtest53
    j _jdo53

    _jtest53:
    
    csrr x25, scause
  
    
    jr x27

    _jdo53:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 424(x6)
  
    la x28, _jtest54
    j _jdo54

    _jtest54:
    
    csrr x25, scause
  
    
    jr x27

    _jdo54:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 432(x6)
  
    la x28, _jtest55
    j _jdo55

    _jtest55:
    
    csrr x25, scause
  
    
    jr x27

    _jdo55:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 440(x6)
  
    la x28, _jtest56
    j _jdo56

    _jtest56:
    
    csrr x25, scause
  
    
    jr x27

    _jdo56:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 448(x6)
  
    la x28, _jtest57
    j _jdo57

    _jtest57:
    
    csrr x25, scause
  
    
    jr x27

    _jdo57:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 456(x6)
  
    la x28, _jtest58
    j _jdo58

    _jtest58:
    
    csrr x25, scause
  
    
    jr x27

    _jdo58:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 464(x6)
  
    la x28, _jtest59
    j _jdo59

    _jtest59:
    
    csrr x25, scause
  
    
    jr x27

    _jdo59:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 472(x6)
  
    la x28, _jtest60
    j _jdo60

    _jtest60:
    
    csrr x25, scause
  
    
    jr x27

    _jdo60:
    li x25, 0xDEADBEA7
    li gp, 0
    
    .fill 1, 4, 0
  
  
    sd x25, 480(x6)
  
    la x28, _jtest61
    j _jdo61

    _jtest61:
    
    csrr x25, scause
  
    
    jr x27

    _jdo61:
    li x25, 0xDEADBEA7
    li gp, 0
    
    lw x0, 11(x0)
  
  
    sd x25, 488(x6)
  
    la x28, _jtest62
    j _jdo62

    _jtest62:
    
    csrr x25, scause
  
    
    jr x27

    _jdo62:
    li x25, 0xDEADBEA7
    li gp, 0
    
    sw x0, 11(x0)
  
  
    sd x25, 496(x6)
  
    la x28, _jtest63
    j _jdo63

    _jtest63:
    
    csrr x25, scause
  
    
    jr x27

    _jdo63:
    li x25, 0xDEADBEA7
    li gp, 0
    
        ecall
      
  
    sd x25, 504(x6)
  
        li x30, 1
        li gp, 0
        ebreak
        _j_all_end_ebreak:

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
.fill 64, 8, -1

#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif
RVMODEL_DATA_END
