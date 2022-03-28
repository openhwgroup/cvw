///////////////////////////////////////////
// ../../../imperas-riscv-tests/riscv-test-suite/rv64p/src/WALLY-MARCHID.S
// dottolia@hmc.edu
// Created 2021-06-15 11:27:52.352985//
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
		
    # Testcase 0
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest0

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest0:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(0)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend0:

    csrrw x0, mtvec, x31
  sd x25, 0(x6)
sd x15, 8(x6)

    # Testcase 2
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest2

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest2:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(0)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 0
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend2:

    csrrw x0, mtvec, x31
  sd x25, 16(x6)
sd x15, 24(x6)

    # Testcase 4
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest4

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest4:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend4:

    csrrw x0, mtvec, x31
  sd x25, 32(x6)
sd x15, 40(x6)

    # Testcase 6
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest6

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest6:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 1
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend6:

    csrrw x0, mtvec, x31
  sd x25, 48(x6)
sd x15, 56(x6)

    # Testcase 8
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest8

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest8:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend8:

    csrrw x0, mtvec, x31
  sd x25, 64(x6)
sd x15, 72(x6)

    # Testcase 10
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest10

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest10:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend10:

    csrrw x0, mtvec, x31
  sd x25, 80(x6)
sd x15, 88(x6)

    # Testcase 12
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest12

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest12:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 2
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend12:

    csrrw x0, mtvec, x31
  sd x25, 96(x6)
sd x15, 104(x6)

    # Testcase 14
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest14

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest14:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 2
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend14:

    csrrw x0, mtvec, x31
  sd x25, 112(x6)
sd x15, 120(x6)

    # Testcase 16
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest16

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest16:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(2)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend16:

    csrrw x0, mtvec, x31
  sd x25, 128(x6)
sd x15, 136(x6)

    # Testcase 18
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest18

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest18:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(2)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 2
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend18:

    csrrw x0, mtvec, x31
  sd x25, 144(x6)
sd x15, 152(x6)

    # Testcase 20
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest20

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest20:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(2)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend20:

    csrrw x0, mtvec, x31
  sd x25, 160(x6)
sd x15, 168(x6)

    # Testcase 22
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest22

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest22:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(2)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend22:

    csrrw x0, mtvec, x31
  sd x25, 176(x6)
sd x15, 184(x6)

    # Testcase 24
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest24

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest24:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(2)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 3
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend24:

    csrrw x0, mtvec, x31
  sd x25, 192(x6)
sd x15, 200(x6)

    # Testcase 26
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest26

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest26:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(2)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 3
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend26:

    csrrw x0, mtvec, x31
  sd x25, 208(x6)
sd x15, 216(x6)

    # Testcase 28
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest28

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest28:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(31)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend28:

    csrrw x0, mtvec, x31
  sd x25, 224(x6)
sd x15, 232(x6)

    # Testcase 30
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest30

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest30:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(31)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 31
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend30:

    csrrw x0, mtvec, x31
  sd x25, 240(x6)
sd x15, 248(x6)

    # Testcase 32
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest32

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest32:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(31)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend32:

    csrrw x0, mtvec, x31
  sd x25, 256(x6)
sd x15, 264(x6)

    # Testcase 34
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest34

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest34:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(31)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend34:

    csrrw x0, mtvec, x31
  sd x25, 272(x6)
sd x15, 280(x6)

    # Testcase 36
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest36

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest36:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(31)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 1
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend36:

    csrrw x0, mtvec, x31
  sd x25, 288(x6)
sd x15, 296(x6)

    # Testcase 38
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest38

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest38:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(31)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 1
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend38:

    csrrw x0, mtvec, x31
  sd x25, 304(x6)
sd x15, 312(x6)

    # Testcase 40
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest40

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest40:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(32)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend40:

    csrrw x0, mtvec, x31
  sd x25, 320(x6)
sd x15, 328(x6)

    # Testcase 42
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest42

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest42:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(32)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 0
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend42:

    csrrw x0, mtvec, x31
  sd x25, 336(x6)
sd x15, 344(x6)

    # Testcase 44
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest44

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest44:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(32)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend44:

    csrrw x0, mtvec, x31
  sd x25, 352(x6)
sd x15, 360(x6)

    # Testcase 46
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest46

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest46:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(32)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend46:

    csrrw x0, mtvec, x31
  sd x25, 368(x6)
sd x15, 376(x6)

    # Testcase 48
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest48

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest48:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(32)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 2
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend48:

    csrrw x0, mtvec, x31
  sd x25, 384(x6)
sd x15, 392(x6)

    # Testcase 50
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest50

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest50:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(32)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 2
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend50:

    csrrw x0, mtvec, x31
  sd x25, 400(x6)
sd x15, 408(x6)

    # Testcase 52
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest52

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest52:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(7082823659048590612)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend52:

    csrrw x0, mtvec, x31
  sd x25, 416(x6)
sd x15, 424(x6)

    # Testcase 54
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest54

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest54:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(7082823659048590612)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 20
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend54:

    csrrw x0, mtvec, x31
  sd x25, 432(x6)
sd x15, 440(x6)

    # Testcase 56
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest56

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest56:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(7082823659048590612)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend56:

    csrrw x0, mtvec, x31
  sd x25, 448(x6)
sd x15, 456(x6)

    # Testcase 58
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest58

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest58:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(7082823659048590612)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend58:

    csrrw x0, mtvec, x31
  sd x25, 464(x6)
sd x15, 472(x6)

    # Testcase 60
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest60

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest60:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(7082823659048590612)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 28
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend60:

    csrrw x0, mtvec, x31
  sd x25, 480(x6)
sd x15, 488(x6)

    # Testcase 62
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest62

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest62:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(7082823659048590612)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 28
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend62:

    csrrw x0, mtvec, x31
  sd x25, 496(x6)
sd x15, 504(x6)

    # Testcase 64
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest64

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest64:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775806)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend64:

    csrrw x0, mtvec, x31
  sd x25, 512(x6)
sd x15, 520(x6)

    # Testcase 66
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest66

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest66:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775806)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 30
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend66:

    csrrw x0, mtvec, x31
  sd x25, 528(x6)
sd x15, 536(x6)

    # Testcase 68
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest68

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest68:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775806)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend68:

    csrrw x0, mtvec, x31
  sd x25, 544(x6)
sd x15, 552(x6)

    # Testcase 70
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest70

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest70:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775806)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend70:

    csrrw x0, mtvec, x31
  sd x25, 560(x6)
sd x15, 568(x6)

    # Testcase 72
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest72

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest72:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775806)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 7
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend72:

    csrrw x0, mtvec, x31
  sd x25, 576(x6)
sd x15, 584(x6)

    # Testcase 74
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest74

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest74:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775806)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 7
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend74:

    csrrw x0, mtvec, x31
  sd x25, 592(x6)
sd x15, 600(x6)

    # Testcase 76
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest76

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest76:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775807)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend76:

    csrrw x0, mtvec, x31
  sd x25, 608(x6)
sd x15, 616(x6)

    # Testcase 78
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest78

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest78:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775807)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 31
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend78:

    csrrw x0, mtvec, x31
  sd x25, 624(x6)
sd x15, 632(x6)

    # Testcase 80
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest80

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest80:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775807)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend80:

    csrrw x0, mtvec, x31
  sd x25, 640(x6)
sd x15, 648(x6)

    # Testcase 82
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest82

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest82:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775807)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend82:

    csrrw x0, mtvec, x31
  sd x25, 656(x6)
sd x15, 664(x6)

    # Testcase 84
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest84

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest84:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775807)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 8
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend84:

    csrrw x0, mtvec, x31
  sd x25, 672(x6)
sd x15, 680(x6)

    # Testcase 86
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest86

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest86:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775807)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 8
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend86:

    csrrw x0, mtvec, x31
  sd x25, 688(x6)
sd x15, 696(x6)

    # Testcase 88
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest88

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest88:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775808)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend88:

    csrrw x0, mtvec, x31
  sd x25, 704(x6)
sd x15, 712(x6)

    # Testcase 90
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest90

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest90:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775808)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 0
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend90:

    csrrw x0, mtvec, x31
  sd x25, 720(x6)
sd x15, 728(x6)

    # Testcase 92
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest92

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest92:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775808)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend92:

    csrrw x0, mtvec, x31
  sd x25, 736(x6)
sd x15, 744(x6)

    # Testcase 94
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest94

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest94:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775808)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend94:

    csrrw x0, mtvec, x31
  sd x25, 752(x6)
sd x15, 760(x6)

    # Testcase 96
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest96

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest96:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775808)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 9
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend96:

    csrrw x0, mtvec, x31
  sd x25, 768(x6)
sd x15, 776(x6)

    # Testcase 98
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest98

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest98:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775808)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 9
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend98:

    csrrw x0, mtvec, x31
  sd x25, 784(x6)
sd x15, 792(x6)

    # Testcase 100
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest100

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest100:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775809)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend100:

    csrrw x0, mtvec, x31
  sd x25, 800(x6)
sd x15, 808(x6)

    # Testcase 102
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest102

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest102:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775809)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 1
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend102:

    csrrw x0, mtvec, x31
  sd x25, 816(x6)
sd x15, 824(x6)

    # Testcase 104
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest104

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest104:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775809)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend104:

    csrrw x0, mtvec, x31
  sd x25, 832(x6)
sd x15, 840(x6)

    # Testcase 106
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest106

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest106:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775809)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend106:

    csrrw x0, mtvec, x31
  sd x25, 848(x6)
sd x15, 856(x6)

    # Testcase 108
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest108

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest108:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775809)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 10
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend108:

    csrrw x0, mtvec, x31
  sd x25, 864(x6)
sd x15, 872(x6)

    # Testcase 110
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest110

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest110:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(9223372036854775809)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 10
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend110:

    csrrw x0, mtvec, x31
  sd x25, 880(x6)
sd x15, 888(x6)

    # Testcase 112
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest112

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest112:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(14079903813871053634)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend112:

    csrrw x0, mtvec, x31
  sd x25, 896(x6)
sd x15, 904(x6)

    # Testcase 114
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest114

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest114:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(14079903813871053634)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 2
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend114:

    csrrw x0, mtvec, x31
  sd x25, 912(x6)
sd x15, 920(x6)

    # Testcase 116
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest116

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest116:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(14079903813871053634)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend116:

    csrrw x0, mtvec, x31
  sd x25, 928(x6)
sd x15, 936(x6)

    # Testcase 118
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest118

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest118:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(14079903813871053634)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend118:

    csrrw x0, mtvec, x31
  sd x25, 944(x6)
sd x15, 952(x6)

    # Testcase 120
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest120

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest120:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(14079903813871053634)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 20
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend120:

    csrrw x0, mtvec, x31
  sd x25, 960(x6)
sd x15, 968(x6)

    # Testcase 122
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest122

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest122:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(14079903813871053634)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 20
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend122:

    csrrw x0, mtvec, x31
  sd x25, 976(x6)
sd x15, 984(x6)

    # Testcase 124
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest124

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest124:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551614)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend124:

    csrrw x0, mtvec, x31
  sd x25, 992(x6)
sd x15, 1000(x6)

    # Testcase 126
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest126

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest126:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551614)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 30
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend126:

    csrrw x0, mtvec, x31
  sd x25, 1008(x6)
sd x15, 1016(x6)

    # Testcase 128
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest128

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest128:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551614)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend128:

    csrrw x0, mtvec, x31
  sd x25, 1024(x6)
sd x15, 1032(x6)

    # Testcase 130
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest130

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest130:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551614)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend130:

    csrrw x0, mtvec, x31
  sd x25, 1040(x6)
sd x15, 1048(x6)

    # Testcase 132
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest132

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest132:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551614)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 15
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend132:

    csrrw x0, mtvec, x31
  sd x25, 1056(x6)
sd x15, 1064(x6)

    # Testcase 134
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest134

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest134:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551614)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 15
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend134:

    csrrw x0, mtvec, x31
  sd x25, 1072(x6)
sd x15, 1080(x6)

    # Testcase 136
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest136

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest136:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551615)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend136:

    csrrw x0, mtvec, x31
  sd x25, 1088(x6)
sd x15, 1096(x6)

    # Testcase 138
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest138

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest138:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551615)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 31
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend138:

    csrrw x0, mtvec, x31
  sd x25, 1104(x6)
sd x15, 1112(x6)

    # Testcase 140
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest140

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest140:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551615)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend140:

    csrrw x0, mtvec, x31
  sd x25, 1120(x6)
sd x15, 1128(x6)

    # Testcase 142
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest142

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest142:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551615)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend142:

    csrrw x0, mtvec, x31
  sd x25, 1136(x6)
sd x15, 1144(x6)

    # Testcase 144
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest144

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest144:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551615)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 16
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend144:

    csrrw x0, mtvec, x31
  sd x25, 1152(x6)
sd x15, 1160(x6)

    # Testcase 146
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest146

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest146:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(18446744073709551615)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 16
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend146:

    csrrw x0, mtvec, x31
  sd x25, 1168(x6)
sd x15, 1176(x6)

    # Testcase 148
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest148

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest148:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(10606064097799060981)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend148:

    csrrw x0, mtvec, x31
  sd x25, 1184(x6)
sd x15, 1192(x6)

    # Testcase 150
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest150

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest150:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(10606064097799060981)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 21
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend150:

    csrrw x0, mtvec, x31
  sd x25, 1200(x6)
sd x15, 1208(x6)

    # Testcase 152
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest152

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest152:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(10606064097799060981)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend152:

    csrrw x0, mtvec, x31
  sd x25, 1216(x6)
sd x15, 1224(x6)

    # Testcase 154
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest154

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest154:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(10606064097799060981)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend154:

    csrrw x0, mtvec, x31
  sd x25, 1232(x6)
sd x15, 1240(x6)

    # Testcase 156
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest156

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest156:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(10606064097799060981)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 5
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend156:

    csrrw x0, mtvec, x31
  sd x25, 1248(x6)
sd x15, 1256(x6)

    # Testcase 158
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest158

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest158:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(10606064097799060981)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 5
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend158:

    csrrw x0, mtvec, x31
  sd x25, 1264(x6)
sd x15, 1272(x6)

    # Testcase 160
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest160

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest160:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(4670668554830012946)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend160:

    csrrw x0, mtvec, x31
  sd x25, 1280(x6)
sd x15, 1288(x6)

    # Testcase 162
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest162

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest162:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(4670668554830012946)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 18
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend162:

    csrrw x0, mtvec, x31
  sd x25, 1296(x6)
sd x15, 1304(x6)

    # Testcase 164
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest164

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest164:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(4670668554830012946)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend164:

    csrrw x0, mtvec, x31
  sd x25, 1312(x6)
sd x15, 1320(x6)

    # Testcase 166
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest166

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest166:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(4670668554830012946)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend166:

    csrrw x0, mtvec, x31
  sd x25, 1328(x6)
sd x15, 1336(x6)

    # Testcase 168
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest168

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest168:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(4670668554830012946)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 30
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend168:

    csrrw x0, mtvec, x31
  sd x25, 1344(x6)
sd x15, 1352(x6)

    # Testcase 170
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest170

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest170:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(4670668554830012946)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 30
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend170:

    csrrw x0, mtvec, x31
  sd x25, 1360(x6)
sd x15, 1368(x6)

    # Testcase 172
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest172

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest172:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1967122571526000840)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend172:

    csrrw x0, mtvec, x31
  sd x25, 1376(x6)
sd x15, 1384(x6)

    # Testcase 174
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest174

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest174:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1967122571526000840)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 8
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend174:

    csrrw x0, mtvec, x31
  sd x25, 1392(x6)
sd x15, 1400(x6)

    # Testcase 176
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest176

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest176:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1967122571526000840)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend176:

    csrrw x0, mtvec, x31
  sd x25, 1408(x6)
sd x15, 1416(x6)

    # Testcase 178
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest178

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest178:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1967122571526000840)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend178:

    csrrw x0, mtvec, x31
  sd x25, 1424(x6)
sd x15, 1432(x6)

    # Testcase 180
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest180

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest180:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1967122571526000840)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 30
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend180:

    csrrw x0, mtvec, x31
  sd x25, 1440(x6)
sd x15, 1448(x6)

    # Testcase 182
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest182

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest182:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(1967122571526000840)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 30
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend182:

    csrrw x0, mtvec, x31
  sd x25, 1456(x6)
sd x15, 1464(x6)

    # Testcase 184
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest184

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest184:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(6416613002065245206)
    csrrw x11, marchid, x0
    csrrw x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend184:

    csrrw x0, mtvec, x31
  sd x25, 1472(x6)
sd x15, 1480(x6)

    # Testcase 186
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest186

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest186:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(6416613002065245206)
    csrrw x11, marchid, x0
    csrrwi x0, marchid, 22
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend186:

    csrrw x0, mtvec, x31
  sd x25, 1488(x6)
sd x15, 1496(x6)

    # Testcase 188
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest188

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest188:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(6416613002065245206)
    csrrw x11, marchid, x0
    csrrs x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend188:

    csrrw x0, mtvec, x31
  sd x25, 1504(x6)
sd x15, 1512(x6)

    # Testcase 190
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest190

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest190:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(6416613002065245206)
    csrrw x11, marchid, x0
    csrrc x0, marchid, x13
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend190:

    csrrw x0, mtvec, x31
  sd x25, 1520(x6)
sd x15, 1528(x6)

    # Testcase 192
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest192

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest192:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(6416613002065245206)
    csrrw x11, marchid, x0
    csrrsi x0, marchid, 6
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend192:

    csrrw x0, mtvec, x31
  sd x25, 1536(x6)
sd x15, 1544(x6)

    # Testcase 194
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest194

    # Machine trap vector
    
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    
    mret

    # Actual test
    _jtest194:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    
    
    li x13, MASK_XLEN(6416613002065245206)
    csrrw x11, marchid, x0
    csrrci x0, marchid, 6
    csrrwi x12, marchid, 0
    sub x15, x11, x12
  

    # Finished test. Reset to old mtvec
    _jend194:

    csrrw x0, mtvec, x31
  sd x25, 1552(x6)
sd x15, 1560(x6)
	# ---------------------------------------------------------------------------------------------
RVMODEL_HALT

RVTEST_DATA_BEGIN
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
# signature output
wally_signature:
.fill 196, 8, -1

#ifdef rvtest_mtrap_routine
mtrap_sigptr:
    .fill 64*(XLEN/32),4,0xdeadbeef
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif
RVMODEL_DATA_END
