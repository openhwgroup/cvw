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

// Misa.F is already 0 in this config, making floating point diabled

li x28, 0x80006000 // mask bits for SD and FS bits of status csr

csrr x29, mstatus
and x29, x29, x28
sw x29, 0(x6) // read disabled FS, SD bits, which should both be 0
addi x6, x6, 4
addi x16, x16, 4

csrs mstatus, x28 // attempt to write 11 and 1 to fs and sd in mstatus (this should not work)
csrr x29, mstatus
and x29, x29, x28
sw x29, 0(x6) // read disabled FS, SD bits, which should both be 0
addi x6, x6, 4
addi x16, x16, 4

END_TESTS

TEST_STACK_AND_DATA