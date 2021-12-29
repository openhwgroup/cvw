///////////////////////////////////////////
//
// WALLY-PMA
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu> (Copied heavily from SV48 test).
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
# Tests memory load, store, and /* *** execute? */ permissions based on table 12.3 in the *** riscv book, copied below

# Test 12.3.2.1.1 check enabled devices
#                               | Region | Read widths | R   | W   | X   | Cacheable | Idempotent | Atomic |
.8byte 0x1000, 0x0, 0xB #       | ROM    | Any         | YES | NO  | YES | YES       | NO         | NO     | # *** Impossible to write? how am I supposed to put a known value in ROM to read out?
.8byte 0x2000000, 0x0, 0xB #    | CLINT  | Any         | YES | YES | NO  | NO        | NO         | NO     |
.8byte 0xC000000, 0x0, 0xB #    | PLIC   | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |
.8byte 0x10000000, 0x0, 0xB #   | UART0  | 8-bit       | YES | YES | NO  | NO        | NO         | NO     |
.8byte 0x20000000, 0x0, 0xB #   | GPIO   | 32-bit      | YES | YES | NO  | NO        | NO         | NO     |
.8byte 0x800F0000, 0x0, 0xB #   | DRAM   | Any         | YES | YES | YES | YES       | YES        | YES    |
# *** the dram one has a little offset so we don't accidentally write over the code of this test.

# Test 12.3.2.1.2 Check Regions with no enabled device fail all                            
.8byte 0x0000, 0x0, 0xC
.8byte 0x3000, 0x0, 0xC
.8byte 0x4000000, 0x0, 0xC
.8byte 0xE0000000, 0x0, 0xC
.8byte 0x12000000, 0x0, 0xC
.8byte 0xA0000000, 0x0, 0xC

.8byte 0x0, 0x0, 0x3 // terminate tests


















    
