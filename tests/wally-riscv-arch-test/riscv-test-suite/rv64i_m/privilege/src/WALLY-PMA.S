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
#define GPIO_BASE      0x10012000
#define GPIO_RANGE     0x000000FF
#define UART_BASE      0x10000000
#define UART_RANGE     0x00000007
#define PLIC_BASE      0x0C000000
#define PLIC_RANGE     0x03FFFFFF

#include "WALLY-TEST-LIB-64.S" 
// Test library includes and handler for each type of test, a trap handler, imperas compliance instructions
// Ideally this should mean that a test can be written by simply adding .8byte statements as below.

# ---------------------------------------------------------------------------------------------
# Test Contents
#
#   Here is where the actual tests are held, or rather, what the actual tests do.
#   each entry consists of 3 values that will be read in as follows:
#   
#   '.8byte [x28 Value], [x29 Value], [x30 value]'
#                     or
#   '.8byte [address], [value], [test type]'
#
#   The encoding for x30 test type values can be found in the test handler
#   
# ---------------------------------------------------------------------------------------------

# =========== test 12.3.2.1 PMAs: Memory Access Size, Type protection test ===========
# Tests memory load, store, and execute permissions based on table 12.3 in the *** riscv book, copied below

# | Region | Base Address | Read widths | R   | W   | X   | Cacheable | Idempotent | Atomic |
# | ROM    | 0x1000       | Any         | YES | NO  | YES | YES       | NO         | NO     |
# | CLINT  | 0x2000000    | Any         | YES | YES | NO  | NO        | NO         | NO     |
# | PLIC   | 0xC000000    | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |
# | UART0  | 0x10000000   | 8-bit       | YES | YES | NO  | NO        | NO         | NO     |
# | GPIO   | 0x1012000    | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |

# *** Cacheable, Idempotent, Atomic tests are not implemented yet.

#  ----------------- ROM --------------------- 
# ROM goes untested because it isn't writeable and these tests rely on writing a known value to memory. 


#  ----------------- CLINT --------------------- 

# Use timecmp register as readable and writable section of the CLINT
.8byte CLINT_BASE + 0x4000, 0x0000DEADBEEF00B4, 0x0  # 64-bit write:  success
.8byte CLINT_BASE + 0x4000, 0x0000DEADBEEF00B4, 0x1  # 64-bit read:   success
.8byte CLINT_BASE + 0x4000, 0x0000DEADBEEF00B5, 0x11 # 32-bit write:  success
.8byte CLINT_BASE + 0x4000, 0x0000DEADBEEF00B5, 0x14 # 32-bit read:   success
.8byte CLINT_BASE + 0x4000, 0x0000DEADBEEF00B6, 0x12 # 16-bit write:  success
.8byte CLINT_BASE + 0x4000, 0x0000DEADBEEF00B6, 0x15 # 16-bit read:   success
.8byte CLINT_BASE + 0x4000, 0x0000DEADBEEF00B7, 0x13 # 08-bit write:  success
.8byte CLINT_BASE + 0x4000, 0x0000DEADBEEF00B7, 0x16 # 08-bit read:   success

.8byte CLINT_BASE, 0xbad, 0x2 # execute: instruction access fault

#  ----------------- PLIC --------------------- 

.8byte PLIC_BASE, 0x0000DEADBEEF00B8, 0x0   # 64-bit write:  store access fault
.8byte PLIC_BASE, 0x0000DEADBEEF00B8, 0x1   # 64-bit read:   load access fault
# Write 0x2 instead of wider value to plic address because the register width might change.
.8byte PLIC_BASE + 0x2000, 0x2, 0x11        # 32-bit write:  success
.8byte PLIC_BASE + 0x2000, 0x2, 0x14        # 32-bit read:   success
.8byte PLIC_BASE, 0x0000DEADBEEF00BA, 0x12  # 16-bit write:  store access fault
.8byte PLIC_BASE, 0x0000DEADBEEF00BA, 0x15  # 16-bit read:   load access fault
.8byte PLIC_BASE, 0x0000DEADBEEF00BB, 0x13  # 08-bit write:  store access fault
.8byte PLIC_BASE, 0x0000DEADBEEF00BB, 0x16  # 08-bit read:   load access fault

.8byte PLIC_BASE, 0xbad, 0x2 # execute: instruction access fault

#  ----------------- UART0 --------------------- 

.8byte UART_BASE, 0x0000DEADBEEF00BC, 0x0       # 64-bit write:  store access fault
.8byte UART_BASE, 0x0000DEADBEEF00BC, 0x1       # 64-bit read:   load access fault
.8byte UART_BASE, 0x0000DEADBEEF00BD, 0x11      # 32-bit write:  store access fault
.8byte UART_BASE, 0x0000DEADBEEF00BD, 0x14      # 32-bit read:   load access fault
.8byte UART_BASE, 0x0000DEADBEEF00BE, 0x12      # 16-bit write:  store access fault
.8byte UART_BASE, 0x0000DEADBEEF00BE, 0x15      # 16-bit read:   load access fault
# Different address for this test so that we write into a writable register in the uart.
.8byte UART_BASE + 0x3, 0x0000DEADBEEF00BF, 0x13  # 08-bit write:  success
.8byte UART_BASE + 0x3, 0x0000DEADBEEF00BF, 0x16  # 08-bit read:   success

.8byte UART_BASE, 0xbad, 0x2 # execute: instruction access fault

#  ----------------- GPIO --------------------- 

.8byte GPIO_BASE, 0x0000DEADBEEF00C0, 0x0           # 64-bit write:  store access fault
.8byte GPIO_BASE, 0x0000DEADBEEF00C0, 0x1           # 64-bit read:   load access fault
.8byte GPIO_BASE + 0x8, 0x0000DEADBEEF00C1, 0x11    # 32-bit write:  success
.8byte GPIO_BASE + 0x8, 0x0000DEADBEEF00C1, 0x14    # 32-bit read:   success
.8byte GPIO_BASE, 0x0000DEADBEEF00C2, 0x12          # 16-bit write:  store access fault
.8byte GPIO_BASE, 0x0000DEADBEEF00C2, 0x15          # 16-bit read:   load access fault
.8byte GPIO_BASE, 0x0000DEADBEEF00C3, 0x13          # 08-bit write:  store access fault
.8byte GPIO_BASE, 0x0000DEADBEEF00C3, 0x16          # 08-bit read:   load access fault

.8byte GPIO_BASE, 0xbad, 0x2 # execute: instruction access fault

#  ----------------- Inaccessible --------------------- 

# show that load, store, and jalr cause faults in regions not defined by PMAs.  

# Tests 'random' place in unimplemented memory
.8byte 0x40000000, 0x0000DEADBEEF00C7, 0x0  # 64-bit write:  store access fault
.8byte 0x40000000, 0x0000DEADBEEF00C7, 0x1  # 64-bit read:   load access fault
.8byte 0x40000000, 0x111, 0x2               # execute:       instruction access fault

# Tests just past the end of each peripheral
.8byte (BOOTROM_BASE+BOOTROM_RANGE+1), 0x0000DEADBEEF00C8, 0x0  # 64-bit write:  store access fault
.8byte (BOOTROM_BASE+BOOTROM_RANGE+1), 0x0000DEADBEEF00C8, 0x1  # 64-bit read:   load access fault
.8byte (BOOTROM_BASE+BOOTROM_RANGE+1), 0x111, 0x2               # execute:       instruction access fault

.8byte (CLINT_BASE+CLINT_RANGE+1), 0x0000DEADBEEF00C9, 0x0  # 64-bit write:  store access fault
.8byte (CLINT_BASE+CLINT_RANGE+1), 0x0000DEADBEEF00C9, 0x1  # 64-bit read:   load access fault
.8byte (CLINT_BASE+CLINT_RANGE+1), 0x111, 0x2               # execute:       instruction access fault

.8byte (PLIC_BASE+PLIC_RANGE+1), 0x0000DEADBEEF00CA, 0x11  # 32-bit write:  store access fault
.8byte (PLIC_BASE+PLIC_RANGE+1), 0x0000DEADBEEF00CA, 0x14  # 32-bit read:   load access fault
.8byte (PLIC_BASE+PLIC_RANGE+1), 0x111, 0x2                # execute:       instruction access fault

.8byte (UART_BASE+UART_RANGE+1), 0x0000DEADBEEF00CB, 0x13  # 08-bit write:  store access fault
.8byte (UART_BASE+UART_RANGE+1), 0x0000DEADBEEF00CB, 0x16  # 08-bit read:   load access fault
.8byte (UART_BASE+UART_RANGE+1), 0x111, 0x2                # execute:       instruction access fault

.8byte (GPIO_BASE+GPIO_RANGE+1), 0x0000DEADBEEF00CC, 0x11  # 32-bit write:  store access fault
.8byte (GPIO_BASE+GPIO_RANGE+1), 0x0000DEADBEEF00CC, 0x14  # 32-bit read:   load access fault
.8byte (GPIO_BASE+GPIO_RANGE+1), 0x111, 0x2                # execute:       instruction access fault

.8byte 0x0, 0x0, 0x3 # terminate tests


















    
