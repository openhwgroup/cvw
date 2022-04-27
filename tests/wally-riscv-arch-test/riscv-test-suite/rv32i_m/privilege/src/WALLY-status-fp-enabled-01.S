///////////////////////////////////////////
//
// WALLY-status-floating-point
//
// Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
//
// Created 2022-04-24
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

#include "WALLY-TEST-LIB-32.h"

INIT_TESTS

TRAP_HANDLER m

// Misa.F is already 1 in this config, making floating point enabled

li x28, 0x80006000 // mask bits for SD and FS bits of status csr

csrr x29, mstatus
and x29, x29, x28
sw x29, 0(x6) // read initial FS, SD bits, which should be 01 and 0 respectively
addi x6, x6, 4
addi x16, x16, 4

flw f1, 0(x6) // make FS dirty by loading random value in

csrr x29, mstatus
and x29, x29, x28
sw x29, 0(x6) // read dirty FS, SD bits, which should be 11 and 1 respectively
addi x6, x6, 4
addi x16, x16, 4

li x29, 0x4000
csrs mstatus, x29
li x29, 0x80002000
csrc mstatus, x29 // set SD to 0 and FS to 10 by writing mstatus

csrr x29, mstatus
and x29, x29, x28
sw x29, 0(x6) // read written FS, SD bits to confirm previous write
addi x6, x6, 4
addi x16, x16, 4

flw f1, 0(x6) // make FS dirty by loading random value in

csrr x29, mstatus
and x29, x29, x28
sw x29, 0(x6) // read dirty FS, SD bits, which should be 11 and 1 respectively
addi x6, x6, 4
addi x16, x16, 4

END_TESTS

TEST_STACK_AND_DATA