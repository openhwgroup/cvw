///////////////////////////////////////////
// ../../../imperas-riscv-tests/riscv-test-suite/rv64p/src/WALLY-UCAUSE.S
// dottolia@hmc.edu
// Created 2021-04-20 15:11:17.438819//
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

      csrr x31, mtvec
      li x30, 0

      la x1, _j_m_trap
      csrw mtvec, x1
      la x1, _j_s_trap
      csrw stvec, x1
      j _j_t_begin

      _j_m_trap:
      csrrs x25, mcause, x0
      csrrs x1, mepc, x0
      addi x1, x1, 4
      csrrw x0, mepc, x1
      bnez x30, _j_all_end
      mret

      _j_s_trap:
      csrrs x25, scause, x0
      csrrs x1, sepc, x0
      addi x1, x1, 4
      csrrw x0, sepc, x1
      sret

      _j_t_begin:
    
      li x1, 0b110000000000
      csrrc x28, mstatus, x1
      li x1, 0b0000000000000
      csrrs x28, mstatus, x1

      auipc x1, 0
      addi x1, x1, 16 # x1 is now right after the mret instruction
      csrw mepc, x1
      mret

      # We're now in u mode...
      
    li x25, 0x7BAD
    
    .fill 1, 4, 0
  

    _jend0:

  sd x25, 0(x6)

    li x25, 0x7BAD
    
    ebreak
  

    _jend1:

  sd x25, 8(x6)

    li x25, 0x7BAD
    
    lw x0, 11(x0)
  

    _jend2:

  sd x25, 16(x6)

    li x25, 0x7BAD
    
    sw x0, 11(x0)
  

    _jend3:

  sd x25, 24(x6)

    li x25, 0x7BAD
    
      ecall
    

    _jend4:

  sd x25, 32(x6)

    li x25, 0x7BAD
    
    .fill 1, 4, 0
  

    _jend5:

  sd x25, 40(x6)

    li x25, 0x7BAD
    
    ebreak
  

    _jend6:

  sd x25, 48(x6)

    li x25, 0x7BAD
    
    lw x0, 11(x0)
  

    _jend7:

  sd x25, 56(x6)

    li x25, 0x7BAD
    
    sw x0, 11(x0)
  

    _jend8:

  sd x25, 64(x6)

    li x25, 0x7BAD
    
      ecall
    

    _jend9:

  sd x25, 72(x6)

    li x25, 0x7BAD
    
    .fill 1, 4, 0
  

    _jend10:

  sd x25, 80(x6)

    li x25, 0x7BAD
    
    ebreak
  

    _jend11:

  sd x25, 88(x6)

    li x25, 0x7BAD
    
    lw x0, 11(x0)
  

    _jend12:

  sd x25, 96(x6)

    li x25, 0x7BAD
    
    sw x0, 11(x0)
  

    _jend13:

  sd x25, 104(x6)

    li x25, 0x7BAD
    
      ecall
    

    _jend14:

  sd x25, 112(x6)

    li x25, 0x7BAD
    
    .fill 1, 4, 0
  

    _jend15:

  sd x25, 120(x6)

    li x25, 0x7BAD
    
    ebreak
  

    _jend16:

  sd x25, 128(x6)

    li x25, 0x7BAD
    
    lw x0, 11(x0)
  

    _jend17:

  sd x25, 136(x6)

    li x25, 0x7BAD
    
    sw x0, 11(x0)
  

    _jend18:

  sd x25, 144(x6)

    li x25, 0x7BAD
    
      ecall
    

    _jend19:

  sd x25, 152(x6)

    li x25, 0x7BAD
    
    .fill 1, 4, 0
  

    _jend20:

  sd x25, 160(x6)

    li x25, 0x7BAD
    
    ebreak
  

    _jend21:

  sd x25, 168(x6)

    li x25, 0x7BAD
    
    lw x0, 11(x0)
  

    _jend22:

  sd x25, 176(x6)

    li x25, 0x7BAD
    
    sw x0, 11(x0)
  

    _jend23:

  sd x25, 184(x6)

    li x25, 0x7BAD
    
      ecall
    

    _jend24:

  sd x25, 192(x6)

    li x25, 0x7BAD
    
    .fill 1, 4, 0
  

    _jend25:

  sd x25, 200(x6)

    li x25, 0x7BAD
    
    ebreak
  

    _jend26:

  sd x25, 208(x6)

    li x25, 0x7BAD
    
    lw x0, 11(x0)
  

    _jend27:

  sd x25, 216(x6)

    li x25, 0x7BAD
    
    sw x0, 11(x0)
  

    _jend28:

  sd x25, 224(x6)

    li x25, 0x7BAD
    
      ecall
    

    _jend29:

  sd x25, 232(x6)

    li x25, 0x7BAD
    
    .fill 1, 4, 0
  

    _jend30:

  sd x25, 240(x6)

    li x25, 0x7BAD
    
    ebreak
  

    _jend31:

  sd x25, 248(x6)

    li x25, 0x7BAD
    
    lw x0, 11(x0)
  

    _jend32:

  sd x25, 256(x6)

    li x25, 0x7BAD
    
    sw x0, 11(x0)
  

    _jend33:

  sd x25, 264(x6)

    li x25, 0x7BAD
    
      ecall
    

    _jend34:

  sd x25, 272(x6)

    li x25, 0x7BAD
    
    .fill 1, 4, 0
  

    _jend35:

  sd x25, 280(x6)

    li x25, 0x7BAD
    
    ebreak
  

    _jend36:

  sd x25, 288(x6)

    li x25, 0x7BAD
    
    lw x0, 11(x0)
  

    _jend37:

  sd x25, 296(x6)

    li x25, 0x7BAD
    
    sw x0, 11(x0)
  

    _jend38:

  sd x25, 304(x6)

    li x25, 0x7BAD
    
      ecall
    

    _jend39:

  sd x25, 312(x6)

      li x30, 1
      ecall
      _j_all_end:

      csrw mtvec, x31
    # ---------------------------------------------------------------------------------------------

RVMODEL_HALT

RVTEST_DATA_BEGIN
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
# signature output
wally_signature:
.fill 40, 8, -1

#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif
RVMODEL_DATA_END
