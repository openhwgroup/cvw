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

#include "WALLY-TEST-LIB-32.S" 
// Test library includes and handler for each type of test, a trap handler, imperas compliance instructions
// Ideally this should mean that a test can be written by simply adding .4byte statements as below.

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
# Tests memory load, store, and execute permissions based on table 12.3 in the *** riscv book, copied below

# | Region | Base Address | Read widths | R   | W   | X   | Cacheable | Idempotent | Atomic |
# | ROM    | 0x1000       | Any         | YES | NO  | YES | YES       | NO         | NO     |
# | CLINT  | 0x2000000    | Any         | YES | YES | NO  | NO        | NO         | NO     |
# | PLIC   | 0xC000000    | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |
# | UART0  | 0x10000000   | 8-bit       | YES | YES | NO  | NO        | NO         | NO     |
# | GPIO   | 0x1012000    | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |
# | DRAM   | 0x80000000   | Any         | YES | YES | YES | YES       | YES        | YES    |

# ************** Cacheable, Idempotent, Atomic tests are not implemented yet.

#  ----------------- ROM --------------------- 
# *** the rom is read only and these read tests depend on reading a known value out of memory.
#        Is there some guaranteed value that I can read out of the ROM
#        otherwise the read test can be modified to just check that the read happened, 
#       not necessarily that it got a known value out of memory. This feels hacky and Id be interested in other options.

# .4byte 0x1000, 0xBEEF0001, 0x0 # 32-bit write:  store access fault
# .4byte 0x1000, 0xBEEF0001, 0x1 # 32-bit read:   success
# .4byte 0x1000, 0xBEEF0002, 0x12 # 16-bit write:  store access fault
# .4byte 0x1000, 0xBEEF0002, 0x15 # 16-bit read:   success
# .4byte 0x1000, 0xBEEF0003, 0x13 # 08-bit write:  store access fault
# .4byte 0x1000, 0xBEEF0003, 0x16 # 08-bit read:   success

# # *** similar problem with the execute tests. Impossible to write the needed executable code into rom once the program's running
# .4byte 0x1000, 0x111, 0x2 # execute:    success

#  ----------------- CLINT --------------------- 

.4byte 0x2000000, 0xBEEF00B5, 0x0 # 32-bit write:  success
.4byte 0x2000000, 0xBEEF00B5, 0x1 # 32-bit read:   success
.4byte 0x2000000, 0xBEEF00B6, 0x12 # 16-bit write:  success
.4byte 0x2000000, 0xBEEF00B6, 0x15 # 16-bit read:   success
.4byte 0x2000000, 0xBEEF00B7, 0x13 # 08-bit write:  success
.4byte 0x2000000, 0xBEEF00B7, 0x16 # 08-bit read:   success

.4byte 0x2000000, 0xbad, 0x2 # execute:    instruction access fault

#  ----------------- PLIC --------------------- 

.4byte 0xC000000, 0xBEEF00B9, 0x0 # 32-bit write:  success
.4byte 0xC000000, 0xBEEF00B9, 0x1 # 32-bit read:   success
.4byte 0xC000000, 0xBEEF00BA, 0x12 # 16-bit write:  store access fault
.4byte 0xC000000, 0xBEEF00BA, 0x15 # 16-bit read:   load access fault
.4byte 0xC000000, 0xBEEF00BB, 0x13 # 08-bit write:  store access fault
.4byte 0xC000000, 0xBEEF00BB, 0x16 # 08-bit read:   load access fault

.4byte 0xC000000, 0xbad, 0x2 # execute:    instruction access fault

#  ----------------- UART0 --------------------- 

.4byte 0x10000000, 0xBEEF00BD, 0x0 # 32-bit write:  store access fault
.4byte 0x10000000, 0xBEEF00BD, 0x1 # 32-bit read:   load access fault
.4byte 0x10000000, 0xBEEF00BE, 0x12 # 16-bit write:  store access fault
.4byte 0x10000000, 0xBEEF00BE, 0x15 # 16-bit read:   load access fault
.4byte 0x10000000, 0xBEEF00BF, 0x13 # 08-bit write:  success
.4byte 0x10000000, 0xBEEF00BF, 0x16 # 08-bit read:   success

.4byte 0x10000000, 0xbad, 0x2 # execute:    instruction access fault

#  ----------------- GPIO --------------------- 

.4byte 0x1012000, 0xBEEF00C1, 0x0 # 32-bit write:  success
.4byte 0x1012000, 0xBEEF00C1, 0x1 # 32-bit read:   success
.4byte 0x1012000, 0xBEEF00C2, 0x12 # 16-bit write:  store access fault
.4byte 0x1012000, 0xBEEF00C2, 0x15 # 16-bit read:   load access fault
.4byte 0x1012000, 0xBEEF00C3, 0x13 # 08-bit write:  store access fault
.4byte 0x1012000, 0xBEEF00C3, 0x16 # 08-bit read:   load access fault

.4byte 0x1012000, 0xbad, 0x2 # execute:    instruction access fault

#  ----------------- DRAM --------------------- 

# the following is already tested by the fact that this test runs without error:
#   32 bit reads and writes into DRAM, 
#   Execution in DRAM
# offset by 0xf000 to avoid overwriting the program
.4byte 0x8000F000, 0xBEEF00C5, 0x12 # 16-bit write:  success
.4byte 0x8000F000, 0xBEEF00C5, 0x15 # 16-bit read:   success
.4byte 0x8000F000, 0xBEEF00C6, 0x13 # 08-bit write:  success
.4byte 0x8000F000, 0xBEEF00C6, 0x16 # 08-bit read:   success

#  ----------------- Inaccessible --------------------- 

# show that load, store, and jalr cause faults in a region not defined by PMAs.  
# *** should I go through every possible inaccessible region of memory or is one just fine?

.4byte 0xD000000, 0xBEEF00C7, 0x0  # 32-bit write:  store access fault
.4byte 0xD000000, 0xBEEF00C7, 0x1  # 32-bit read:   load access fault
.4byte 0x1000, 0x111, 0x2 # execute:    instruction access fault

.4byte 0x0, 0x0, 0x3 // terminate tests


















    
