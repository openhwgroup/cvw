///////////////////////////////////////////
//
// WALLY-pwm
//
// Author: Naiche Whyte-Aguayo naichewa@gmail.com>
//
// Created 2026-05-06
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

#include "WALLY-TEST-LIB-64.h"

RVTEST_ISA("RV64I_Zicsr_Zifencei")
RVTEST_CASE(0,"//check ISA:=regex(.*64.*);check ISA:=regex(.*I.*); def Drvtest_mtrap_routine=True;def TEST_CASE_1=True;def NO_SAIL=True;",pwm)

INIT_TESTS

TRAP_HANDLER m

j run_test_loop // begin test loop/table tests instead of executing inline code.

INIT_TEST_TABLE

END_TESTS

TEST_STACK_AND_DATA

.align 3
test_cases:
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
#   The encoding for x30 test type values can be found in the test handler in the framework file
#
# ---------------------------------------------------------------------------------------------

.equ PWM, 0x10020000
.equ PWMConfig,  (PWM+0x00)
.equ PWMCount,   (PWM+0x08)
.equ PWMScaled,  (PWM+0x10)
.equ PWMCompare0, (PWM+0x020)
.equ PWMCompare1, (PWM+0x024)
.equ PWMCompare2, (PWM+0x028)
.equ PWMCompare3, (PWM+0x02C)

# =========== Verify correct registers reset to zero ===========

#.8byte PWMConfig, 0x            PWMConfig [13:12] reset to 0, everything else X



#============ Scale 0 ZeroCompare tests ===

.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare bit set
#.8byte PWMCompare0, 0x00000000, write32_test    # set Compare0 register to 0
#.8byte PWMConfig, 0x00001204, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x0000003, pwm_dumb_wait          # wait 1 PWM cycle
.8byte PWMCompare0, 0x00000001, write32_test    # set Compare0 to 1
.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnAlways to 1 to start cycle
.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x00008888, write32_test    # set Compare0 to 8888, half of 16 bit capacity
#.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFE, write32_test    # set Compare0 to max -1
#.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFF, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles

# =========== Scale mid tests ==============

.8byte PWMConfig, 0x00000207, write32_test      # initialize config register with pwmscale roughly half filled
#.8byte PWMCompare0, 0x00000000, write32_test    # set Compare0 register to 0
#.8byte PWMConfig, 0x00002207, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait          # wait 1 PWM cycle
.8byte PWMCompare0, 0x00000001, write32_test    # set Compare0 to 1
.8byte PWMConfig, 0x00001207, write32_test      # set PWMEnAlways to 1 to start cycle
.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x00008888, write32_test    # set Compare0 to 8888, half of 16 bit capacity
#.8byte PWMConfig, 0x00001207, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFE, write32_test    # set Compare0 to max -1
#.8byte PWMConfig, 0x00001207, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFF, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001207, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles

# =========== Scale max tests ================

.8byte PWMConfig, 0x0000020F, write32_test      # initialize config register with pwmscale at max
#.8byte PWMCompare0, 0x00000000, write32_test    # set Compare0 register to 0
#.8byte PWMConfig, 0x0000220F, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x0000000, pwm_dumb_wait          # wait 1 PWM cycle
#.8byte PWMCompare0, 0x00000001, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x0000120F, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x00008888, write32_test    # set Compare0 to 8888, half of 16 bit capacity
#.8byte PWMConfig, 0x0000120F, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFE, write32_test    # set Compare0 to max -1
#.8byte PWMConfig, 0x0000120F, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFF, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x0000120F, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles

# =========== Center Aligned Tests ============
#.8byte PWMConfig, 0x00010000, write32_test      # initialize config register with pwmcmp0center set
#.8byte PWMCompare0, 0x00000008, write32_test    # set Compare0 register to half
#.8byte PWMConfig, 0x00011000, write32_test      # set PWMEnAlways to 1 w ZeroCompare off - necessary for center tests because counter has to keep going after matching Compare
#.8byte 0x0, 0x0000003, pwm_dumb_wait_center          # wait 1 PWM cycle
#.8byte PWMCompare0, 0x00007FFF, write32_test    #set Compare0 to ((2^16)/2) - 1 for the minimum high time
#.8byte PWMConfig, 0x00011000, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x0000001, pwm_dumb_wait_center          # wait 1 PWM cycle
#.8byte PWMCompare0, 0x00008000, write32_test    #set Compare0 to ((2^16)/2) for the always low
#.8byte PWMConfig, 0x00011000, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x0000001, pwm_dumb_wait_center          # wait 1 PWM cycle

# ========== Right Aligned ganged tests
.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare0, 0x00000006, write32_test    # generating the waveforms in FU540-C000 manual 14.9
.8byte PWMCompare3, 0x00000000, write32_test    #
.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnOneShot
.8byte 0x0, 0x00000000, pwm_dumb_wait
.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000001, write32_test    #
.8byte PWMConfig, 0x08001200, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000003, pwm_dumb_wait
.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000002, write32_test    #
.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000003, pwm_dumb_wait
.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000003, write32_test    #
.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000003, pwm_dumb_wait
.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000004, write32_test    #
.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000003, pwm_dumb_wait
.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000005, write32_test    #
.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000003, pwm_dumb_wait
.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000006, write32_test    #
.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000003, pwm_dumb_wait
.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with eroCompare set
.8byte PWMCompare3, 0x00000007, write32_test    #
.8byte PWMConfig, 0x00001200, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000003, pwm_dumb_wait

# ========== Arbitrary ganged tests===========
.8byte PWMConfig, 0x02000200, write32_test      # initialize config register w cmp1 gang, zerocmp
.8byte PWMCompare0, 0x00000006, write32_test       # set compare0 (base cycle) to 6
.8byte PWMCompare1, 0x00000001, write32_test
.8byte PWMCompare2, 0x00000002, write32_test
.8byte PWMConfig, 0x02001200, write32_test      # set EnAlways
.8byte 0x0, 0x00000003, pwm_dumb_wait           # wait 3 cycles
.8byte PWMCompare1, 0x00000002, write32_test
.8byte PWMCompare2, 0x00000003, write32_test
.8byte PWMConfig, 0x02001200, write32_test      # set EnAlways
.8byte 0x0, 0x00000003, pwm_dumb_wait           # wait 3 cycles
.8byte PWMCompare1, 0x00000002, write32_test
.8byte PWMCompare2, 0x00000004, write32_test
.8byte PWMConfig, 0x02001200, write32_test      # set EnAlways
.8byte 0x0, 0x00000003, pwm_dumb_wait           # wait 3 cycles

SETUP_PLIC
# ========== Sticky/Deglitch circuit test ====
.8byte PWMConfig, 0x00000100, write32_test      # initialize config register with sticky bit set
.8byte PWMCompare0, 0x00000001, write32_test    # set PWMCompare0
.8byte PWMConfig, 0x00001100, write32_test      # set PWMEnAlways, ip should insantly be high
.8byte PWMCompare0, 0x0000FFFF, write32_test    # set compare register to max, comparator is 0 but sticky should prevent ip from falling
.8byte 0x0, 0x00000800, readmip_test            # check that mip is high
.8byte 0x0, 0x00000000, pwm_dumb_wait         # wait for 1 cycle
.8byte 0x0, 0x00000000, claim_m_plic_interrupts # clear mip interrupt
.8byte PWMConfig, 0x00000400, write32_test      # initialize config register for same tests but with deglitch
.8byte PWMCompare0, 0x00000001, write32_test    # set PWMCompare0
.8byte PWMConfig, 0x00001400, write32_test      # set PWMEnAlways, ip should insantly be high
.8byte PWMCompare0, 0x0000FFFF, write32_test    # set compare register to max, comparator is 0 but deglitch should prevent ip from falling
.8byte 0x0, 0x00000800, readmip_test            # check that mip is high
.8byte 0x0, 0x00000000, pwm_dumb_wait         # wait for 1 cycle
.8byte 0x0, 0x00000000, claim_m_plic_interrupts # clear mip interrupt
.8byte PWMConfig, 0x0000060F, write32_test      # initialize config register with deglitch, zerocmp
.8byte PWMCompare0, 0x00000001, write32_test    # set PWMCompare0
.8byte PWMConfig, 0x00001600, write32_test      # set PWMEnAlways, ip should insantly be high
.8byte PWMCompare0, 0x0000FFFF, write32_test    # set compare register to max, comparator is 0 but deglitch should prevent ip from falling
.8byte 0x0, 0x00000000, pwm_dumb_wait         # wait for 1 cycle

# =========== Scale 0 tests ==============

#.8byte PWMConfig, 0x00000000, write32_test      # initialize config register
#.8byte PWMCompare0, 0x00000000, write32_test    # set Compare0 register to 0
#.8byte PWMConfig, 0x00002000, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x0000000, pwm_dumb_wait          # wait 1 PWM cycle
#.8byte PWMCompare0, 0x00000001, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001000, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x00008888, write32_test    # set Compare0 to 8888, half of 16 bit capacity
#.8byte PWMConfig, 0x00001000, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFE, write32_test    # set Compare0 to max -1
#.8byte PWMConfig, 0x00001000, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFF, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001000, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000003, pwm_dumb_wait         # wait 8 PWM cycles

.8byte 0x0, 0x0, terminate_test
