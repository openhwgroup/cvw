///////////////////////////////////////////
//
// WALLY-PMA
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2021-06-15
//
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
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

#define BOOTROM_BASE   0x00001000
#define BOOTROM_RANGE  0x00000FFF
#define RAM_BASE       0x80000000
#define RAM_RANGE      0x7FFFFFFF
#define CLINT_BASE     0x02000000
#define CLINT_RANGE    0x0000FFFF
#define GPIO_BASE      0x10060000
#define GPIO_RANGE     0x000000FF
#define UART_BASE      0x10000000
#define UART_RANGE     0x00000007
#define PLIC_BASE      0x0C000000
#define PLIC_RANGE     0x03FFFFFF

#include "WALLY-TEST-LIB-32.h" 

RVTEST_ISA("RV32I_Zicsr_Zifencei")
RVTEST_CASE(0,"//check ISA:=regex(.*32.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",pma)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

TEST_STACK_AND_DATA

.align 2
test_cases:
# ---------------------------------------------------------------------------------------------
# Test Contents
#
#   Here is where the actual tests are held, or rather, what the actual tests do.
#   each entry consists of 3 values that will be read in as follows:
#   
#   '.4byte [x28 Value], [x29 Value], [x30 value]'
#                     or
#   '.4byte [address], [value], [test type]'
#
#   The encoding for x30 test type values can be found in the test handler
#   
# ---------------------------------------------------------------------------------------------

# =========== test 12.3.2.1 PMAs: Memory Access Size, Type protection test ===========
# Tests memory load, store, and execute permissions

# | Region | Base Address | Read widths | R   | W   | X   | Cacheable | Idempotent | Atomic |
# | ROM    | 0x1000       | Any         | YES | NO  | YES | YES       | NO         | NO     |
# | CLINT  | 0x2000000    | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |
# | PLIC   | 0xC000000    | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |
# | UART0  | 0x10000000   | 8-bit       | YES | YES | NO  | NO        | NO         | NO     |
# | GPIO   | 0x1012000    | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |

# ************** Cacheable, Idempotent, Atomic tests are not implemented yet.

#  ----------------- ROM --------------------- 
# ROM goes untested because it isn't writeable and these tests rely on writing a known value to memory. 


#  ----------------- CLINT --------------------- 

# Use timecmp register as readable and writable section of the CLINT
.4byte CLINT_BASE + 0x4000, 0xBEEF00B5, write32_test    # 32-bit write:  success
.4byte CLINT_BASE + 0x4000, 0xBEEF00B5, read32_test     # 32-bit read:   success
.4byte CLINT_BASE + 0x4000, 0xBEEF00B6, write16_test    # 16-bit write: success
.4byte CLINT_BASE + 0x4000, 0xBEEF00B6, read16_test     # 16-bit read:   success
.4byte CLINT_BASE + 0x4000, 0xBEEF00B7, write08_test    # 08-bit write: success
.4byte CLINT_BASE + 0x4000, 0xBEEF00B7, read08_test     # 08-bit read:   success

.4byte CLINT_BASE, 0xbad, executable_test # execute: instruction access fault

#  ----------------- PLIC --------------------- 

# Write 0x2 instead of wider value to plic address because the register width might change.
.4byte PLIC_BASE + 0x2000, 0x2, write32_test # 32-bit write:  success
.4byte PLIC_BASE + 0x2000, 0x2, read32_test # 32-bit read:   success
.4byte PLIC_BASE, 0xBEEF00BA, write16_test # 16-bit write:  store access fault
.4byte PLIC_BASE, 0xBEEF00BA, read16_test # 16-bit read:   load access fault
.4byte PLIC_BASE, 0xBEEF00BB, write08_test # 08-bit write:  store access fault
.4byte PLIC_BASE, 0xBEEF00BB, read08_test # 08-bit read:   load access fault

.4byte PLIC_BASE, 0xbad, executable_test# execute:    instruction access fault

#  ----------------- UART0 --------------------- 

.4byte UART_BASE, 0xBEEF00BD, write32_test # 32-bit write:  store access fault
.4byte UART_BASE, 0xBEEF00BD, read32_test # 32-bit read:   load access fault
.4byte UART_BASE, 0xBEEF00BE, write16_test# 16-bit write:  store access fault
.4byte UART_BASE, 0xBEEF00BE, read16_test# 16-bit read:   load access fault
# Different address for this test so that we write into a writable register in the uart.
.4byte UART_BASE + 0x3, 0xBEEF00BF, write08_test# 08-bit write:  success
.4byte UART_BASE + 0x3, 0xBEEF00BF, read08_test# 08-bit read:   success

.4byte UART_BASE, 0xbad, executable_test# execute:    instruction access fault

#  ----------------- GPIO --------------------- 

.4byte GPIO_BASE + 0x8, 0xBEEF00C1, write32_test # 32-bit write:  success
.4byte GPIO_BASE + 0x8, 0xBEEF00C1, read32_test# 32-bit read:   success
.4byte GPIO_BASE, 0xBEEF00C2, write16_test     # 16-bit write:  store access fault
.4byte GPIO_BASE, 0xBEEF00C2, read16_test     # 16-bit read:   load access fault
.4byte GPIO_BASE, 0xBEEF00C3, write08_test     # 08-bit write:  store access fault
.4byte GPIO_BASE, 0xBEEF00C3, read08_test     # 08-bit read:   load access fault

.4byte GPIO_BASE, 0xbad, executable_test# execute:    instruction access fault


#  ----------------- Inaccessible --------------------- 

# show that load, store, and jalr cause faults in a region not defined by PMAs.  

# Tests 'random' place in unimplemented memory
.4byte 0x40000000, 0xBEEF00C7, write32_test  # 32-bit write:  store access fault
.4byte 0x40000000, 0xBEEF00C7, read32_test # 32-bit read:   load access fault
.4byte 0x40000000, 0x111, executable_test              # execute:       instruction access fault

# Tests just past the end of each peripheral
.4byte (BOOTROM_BASE+BOOTROM_RANGE+1), 0xBEEF00C8, write32_test  # 32-bit write:  store access fault
.4byte (BOOTROM_BASE+BOOTROM_RANGE+1), 0xBEEF00C8, read32_test # 32-bit read:   load access fault
.4byte (BOOTROM_BASE+BOOTROM_RANGE+1), 0x111, executable_test              # execute:       instruction access fault

.4byte (CLINT_BASE+CLINT_RANGE+1), 0xBEEF00C9, write32_test  # 32-bit write:  store access fault
.4byte (CLINT_BASE+CLINT_RANGE+1), 0xBEEF00C9, read32_test # 32-bit read:   load access fault
.4byte (CLINT_BASE+CLINT_RANGE+1), 0x111, executable_test              # execute:       instruction access fault

.4byte (PLIC_BASE+PLIC_RANGE+1), 0xBEEF00CA, write32_test   # 32-bit write:  store access fault
.4byte (PLIC_BASE+PLIC_RANGE+1), 0xBEEF00CA, read32_test  # 32-bit read:   load access fault
.4byte (PLIC_BASE+PLIC_RANGE+1), 0x111, executable_test               # execute:       instruction access fault

.4byte (UART_BASE+UART_RANGE+1), 0xBEEF00CB, write08_test # 08-bit write:  store access fault
.4byte (UART_BASE+UART_RANGE+1), 0xBEEF00CB, read08_test # 08-bit read:   load access fault
.4byte (UART_BASE+UART_RANGE+1), 0x111, executable_test               # execute:       instruction access fault

.4byte (GPIO_BASE+GPIO_RANGE+1), 0xBEEF00CC, write32_test   # 32-bit write:  store access fault
.4byte (GPIO_BASE+GPIO_RANGE+1), 0xBEEF00CC, read32_test  # 32-bit read:   load access fault
.4byte (GPIO_BASE+GPIO_RANGE+1), 0x111, executable_test               # execute:       instruction access fault

.4byte 0x0, 0x0, terminate_test # terminate tests

















    
