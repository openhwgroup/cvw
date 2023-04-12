///////////////////////////////////////////
// pmpcfg.S
//
// Written: Kevin Wan and Liam Chalk (kewan@hmc.edu and lchalk@hmc.edu)
//
// Purpose: Test coverage for pmpcfg
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

#include "WALLY-init-lib.h"

main:

    li a0, 3
    ecall
    # pmp tests

    li t0, 128
    csrw 0x3A0, t0
    li t0, 0
    csrw 0x3A0, t0
    li t0, 136
    csrw 0x3A0, t0
    li t0, 8
    csrw 0x3A0, t0
    li t0, 144
    csrw 0x3A0, t0
    li t0, 16
    csrw 0x3A0, t0
    li t0, 152
    csrw 0x3A0, t0
    li t0, 24
    csrw 0x3A0, t0
    li t0, 32768
    csrw 0x3A0, t0
    li t0, 0
    csrw 0x3A0, t0
    li t0, 34816
    csrw 0x3A0, t0
    li t0, 2048
    csrw 0x3A0, t0
    li t0, 36864
    csrw 0x3A0, t0
    li t0, 4096
    csrw 0x3A0, t0
    li t0, 38912
    csrw 0x3A0, t0
    li t0, 6144
    csrw 0x3A0, t0
    li t0, 8388608
    csrw 0x3A0, t0
    li t0, 0
    csrw 0x3A0, t0
    li t0, 8912896
    csrw 0x3A0, t0
    li t0, 524288
    csrw 0x3A0, t0
    li t0, 9437184
    csrw 0x3A0, t0
    li t0, 1048576
    csrw 0x3A0, t0
    li t0, 9961472
    csrw 0x3A0, t0
    li t0, 1572864
    csrw 0x3A0, t0
    li t0, 2147483648
    csrw 0x3A0, t0
    li t0, 0
    csrw 0x3A0, t0
    li t0, 2281701376
    csrw 0x3A0, t0
    li t0, 134217728
    csrw 0x3A0, t0
    li t0, 2415919104
    csrw 0x3A0, t0
    li t0, 268435456
    csrw 0x3A0, t0
    li t0, 2550136832
    csrw 0x3A0, t0
    li t0, 402653184
    csrw 0x3A0, t0
    li t0, 549755813888
    csrw 0x3A0, t0
    li t0, 0
    csrw 0x3A0, t0
    li t0, 584115552256
    csrw 0x3A0, t0
    li t0, 34359738368
    csrw 0x3A0, t0
    li t0, 618475290624
    csrw 0x3A0, t0
    li t0, 68719476736
    csrw 0x3A0, t0
    li t0, 652835028992
    csrw 0x3A0, t0
    li t0, 103079215104
    csrw 0x3A0, t0
    li t0, 140737488355328
    csrw 0x3A0, t0
    li t0, 0
    csrw 0x3A0, t0
    li t0, 149533581377536
    csrw 0x3A0, t0
    li t0, 8796093022208
    csrw 0x3A0, t0
    li t0, 158329674399744
    csrw 0x3A0, t0
    li t0, 17592186044416
    csrw 0x3A0, t0
    li t0, 167125767421952
    csrw 0x3A0, t0
    li t0, 26388279066624
    csrw 0x3A0, t0
    li t0, 36028797018963968
    csrw 0x3A0, t0
    li t0, 0
    csrw 0x3A0, t0
    li t0, 38280596832649216
    csrw 0x3A0, t0
    li t0, 2251799813685248
    csrw 0x3A0, t0
    li t0, 40532396646334464
    csrw 0x3A0, t0
    li t0, 4503599627370496
    csrw 0x3A0, t0
    li t0, 42784196460019712
    csrw 0x3A0, t0
    li t0, 6755399441055744
    csrw 0x3A0, t0
    li t0, 9223372036854775808
    csrw 0x3A0, t0
    li t0, 0
    csrw 0x3A0, t0
    li t0, 9799832789158199296
    csrw 0x3A0, t0
    li t0, 576460752303423488
    csrw 0x3A0, t0
    li t0, 10376293541461622784
    csrw 0x3A0, t0
    li t0, 1152921504606846976
    csrw 0x3A0, t0
    li t0, 10952754293765046272
    csrw 0x3A0, t0
    li t0, 1729382256910270464
    csrw 0x3A0, t0

    li t0, 128
    csrw 0x3A2, t0
    li t0, 0
    csrw 0x3A2, t0
    li t0, 136
    csrw 0x3A2, t0
    li t0, 8
    csrw 0x3A2, t0
    li t0, 144
    csrw 0x3A2, t0
    li t0, 16
    csrw 0x3A2, t0
    li t0, 152
    csrw 0x3A2, t0
    li t0, 24
    csrw 0x3A2, t0
    li t0, 32768
    csrw 0x3A2, t0
    li t0, 0
    csrw 0x3A2, t0
    li t0, 34816
    csrw 0x3A2, t0
    li t0, 2048
    csrw 0x3A2, t0
    li t0, 36864
    csrw 0x3A2, t0
    li t0, 4096
    csrw 0x3A2, t0
    li t0, 38912
    csrw 0x3A2, t0
    li t0, 6144
    csrw 0x3A2, t0
    li t0, 8388608
    csrw 0x3A2, t0
    li t0, 0
    csrw 0x3A2, t0
    li t0, 8912896
    csrw 0x3A2, t0
    li t0, 524288
    csrw 0x3A2, t0
    li t0, 9437184
    csrw 0x3A2, t0
    li t0, 1048576
    csrw 0x3A2, t0
    li t0, 9961472
    csrw 0x3A2, t0
    li t0, 1572864
    csrw 0x3A2, t0
    li t0, 2147483648
    csrw 0x3A2, t0
    li t0, 0
    csrw 0x3A2, t0
    li t0, 2281701376
    csrw 0x3A2, t0
    li t0, 134217728
    csrw 0x3A2, t0
    li t0, 2415919104
    csrw 0x3A2, t0
    li t0, 268435456
    csrw 0x3A2, t0
    li t0, 2550136832
    csrw 0x3A2, t0
    li t0, 402653184
    csrw 0x3A2, t0
    li t0, 549755813888
    csrw 0x3A2, t0
    li t0, 0
    csrw 0x3A2, t0
    li t0, 584115552256
    csrw 0x3A2, t0
    li t0, 34359738368
    csrw 0x3A2, t0
    li t0, 618475290624
    csrw 0x3A2, t0
    li t0, 68719476736
    csrw 0x3A2, t0
    li t0, 652835028992
    csrw 0x3A2, t0
    li t0, 103079215104
    csrw 0x3A2, t0
    li t0, 140737488355328
    csrw 0x3A2, t0
    li t0, 0
    csrw 0x3A2, t0
    li t0, 149533581377536
    csrw 0x3A2, t0
    li t0, 8796093022208
    csrw 0x3A2, t0
    li t0, 158329674399744
    csrw 0x3A2, t0
    li t0, 17592186044416
    csrw 0x3A2, t0
    li t0, 167125767421952
    csrw 0x3A2, t0
    li t0, 26388279066624
    csrw 0x3A2, t0
    li t0, 36028797018963968
    csrw 0x3A2, t0
    li t0, 0
    csrw 0x3A2, t0
    li t0, 38280596832649216
    csrw 0x3A2, t0
    li t0, 2251799813685248
    csrw 0x3A2, t0
    li t0, 40532396646334464
    csrw 0x3A2, t0
    li t0, 4503599627370496
    csrw 0x3A2, t0
    li t0, 42784196460019712
    csrw 0x3A2, t0
    li t0, 6755399441055744
    csrw 0x3A2, t0
    li t0, 9223372036854775808
    csrw 0x3A2, t0
    li t0, 0
    csrw 0x3A2, t0
    li t0, 9799832789158199296
    csrw 0x3A2, t0
    li t0, 576460752303423488
    csrw 0x3A2, t0
    li t0, 10376293541461622784
    csrw 0x3A2, t0
    li t0, 1152921504606846976
    csrw 0x3A2, t0
    li t0, 10952754293765046272
    csrw 0x3A2, t0
    li t0, 1729382256910270464
    csrw 0x3A2, t0

    j done