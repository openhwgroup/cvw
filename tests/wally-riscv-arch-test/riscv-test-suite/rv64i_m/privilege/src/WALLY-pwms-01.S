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

.equ GPIO, 0x10060000
.equ input_val, (GPIO+0x00)
.equ input_en, (GPIO+0x04)
.equ output_en, (GPIO+0x08)
.equ output_val, (GPIO+0x0C)
.equ rise_ie, (GPIO+0x18)
.equ rise_ip, (GPIO+0x1C)
.equ fall_ie, (GPIO+0x20)
.equ fall_ip, (GPIO+0x24)
.equ high_ie, (GPIO+0x28)
.equ high_ip, (GPIO+0x2C)
.equ low_ie, (GPIO+0x30)
.equ low_ip, (GPIO+0x34)
.equ iof_en, (GPIO+0x38)
.equ iof_sel, (GPIO+0x3C)
.equ out_xor, (GPIO+0x40)

# =========== Verify correct registers reset to zero ===========

#.8byte PWMConfig, 0x            PWMConfig [13:12] reset to 0, everything else X
# =========== Setting up GPIO

.8byte iof_en, 0x0000000F, write32_test         # turn on the iof_en for GPIO 0-3, selecting PWM outs
.8byte input_en, 0x0000000F, write32_test       #turn on gpio. input pins
.8byte output_en, 0x0000000F, write32_test      # turn on gpio output pins


#============ Scale 0 ZeroCompare tests ===

.8byte PWMConfig, 0x00000200, write32_test      # initialize config register with ZeroCompare bit set
#.8byte PWMCompare0, 0x00000000, write32_test    # set Compare0 register to 0
#.8byte PWMConfig, 0x00001205, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x0000000, pwm_cycle_wait          # wait 1 PWM cycle
.8byte PWMCompare0, 0x00000001, write32_test    # set Compare0 to 1
.8byte PWMConfig, 0x00001206, write32_test      # set PWMEnAlways to 1 to start cycle
.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x00008888, write32_test    # set Compare0 to 8888, half of 16 bit capacity
#.8byte PWMConfig, 0x00001205, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFE, write32_test    # set Compare0 to max -1
#.8byte PWMConfig, 0x00001204, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFF, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001204, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles

# =========== Scale mid tests ==============

#.8byte PWMConfig, 0x00000207, write32_test      # initialize config register with pwmscale roughly half filled
#.8byte PWMCompare0, 0x00000000, write32_test    # set Compare0 register to 0
#.8byte PWMConfig, 0x00002207, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x0000000, pwm_cycle_wait          # wait 1 PWM cycle
#.8byte PWMCompare0, 0x00000001, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001207, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x00008888, write32_test    # set Compare0 to 8888, half of 16 bit capacity
#.8byte PWMConfig, 0x00001207, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFE, write32_test    # set Compare0 to max -1
#.8byte PWMConfig, 0x00001207, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFF, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001207, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles

# =========== Scale max tests ================

#.8byte PWMConfig, 0x0000020F, write32_test      # initialize config register with pwmscale at max
#.8byte PWMCompare0, 0x00000000, write32_test    # set Compare0 register to 0
#.8byte PWMConfig, 0x0000220F, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x0000000, pwm_cycle_wait          # wait 1 PWM cycle
#.8byte PWMCompare0, 0x00000001, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x0000120F, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x00008888, write32_test    # set Compare0 to 8888, half of 16 bit capacity
#.8byte PWMConfig, 0x0000120F, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFE, write32_test    # set Compare0 to max -1
#.8byte PWMConfig, 0x0000120F, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFF, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x0000120F, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000002, pwm_cycle_wait         # wait 8 PWM cycles



# ========== Right Aligned  tests
.8byte PWMCompare1, 0x0000FFFF, write32_test
.8byte PWMConfig, 0x00000206, write32_test      # initialize config register with ZeroCompare set
#.8byte PWMCompare0, 0x00000006, write32_test    # generating the waveforms in FU540-C000 manual 14.9
#.8byte PWMCompare3, 0x00000000, write32_test    #
#.8byte PWMConfig, 0x00001204, write32_test      # set PWMEnAlways
#.8byte 0x0, 0x00000002, pwm_cycle_wait
.8byte PWMConfig, 0x00000206, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000001, write32_test    #
.8byte PWMConfig, 0x00001206, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000002, pwm_cycle_wait
.8byte PWMConfig, 0x00000206, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000002, write32_test    #
.8byte PWMConfig, 0x00001206, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000002, pwm_cycle_wait
.8byte PWMConfig, 0x00000206, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000003, write32_test    #
.8byte PWMConfig, 0x00001206, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000002, pwm_cycle_wait
.8byte PWMConfig, 0x00000206, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000004, write32_test    #
.8byte PWMConfig, 0x00001206, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000002, pwm_cycle_wait
.8byte PWMConfig, 0x00000206, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000005, write32_test    #
.8byte PWMConfig, 0x00001206, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000002, pwm_cycle_wait
.8byte PWMConfig, 0x00000206, write32_test      # initialize config register with ZeroCompare set
.8byte PWMCompare3, 0x00000006, write32_test    #
.8byte PWMConfig, 0x00001206, write32_test      # set PWMEnalways
.8byte 0x0, 0x00000002, pwm_cycle_wait
#.8byte PWMConfig, 0x00000204, write32_test      # initialize config register with eroCompare set
#.8byte PWMCompare3, 0x00000007, write32_test    #
#.8byte PWMConfig, 0x00001204, write32_test      # set PWMEnalways
#.8byte 0x0, 0x00000002, pwm_cycle_wait

# ========== Arbitrary ganged tests===========
.8byte input_en, 0x00000004, write32_test       #turn on gpio. input pins
.8byte output_en, 0x00000004, write32_test      # turn on gpio output pins
.8byte PWMConfig, 0x04000206, write32_test      # initialize config register w cmp2 gang, zerocmp
.8byte PWMCompare0, 0x00000006, write32_test       # set compare0 (base cycle) to 6
.8byte PWMCompare2, 0x00000001, write32_test
.8byte PWMCompare3, 0x00000002, write32_test
.8byte PWMConfig, 0x04001206, write32_test      # set EnAlways
.8byte 0x0, 0x00000002, pwm_cycle_wait           # wait 3 cycles
.8byte PWMCompare2, 0x00000002, write32_test
.8byte PWMCompare3, 0x00000003, write32_test
.8byte PWMConfig, 0x04001206, write32_test      # set EnAlways
.8byte 0x0, 0x00000002, pwm_cycle_wait           # wait 3 cycles
.8byte PWMCompare2, 0x00000002, write32_test
.8byte PWMCompare3, 0x00000004, write32_test
.8byte PWMConfig, 0x04001206, write32_test      # set EnAlways
.8byte 0x0, 0x00000002, pwm_cycle_wait           # wait 3 cycles

# =========== Center Aligned Tests ============
.8byte input_en, 0x00000001, write32_test       #turn on gpio. input pins
.8byte output_en, 0x00000001, write32_test      # turn on gpio output pins
.8byte PWMConfig, 0x00010000, write32_test      # initialize config register with pwmcmp0center set
.8byte PWMCompare0, 0x000000FF, write32_test    # set Compare0 register to FF (give enough time to check cycle over)
.8byte PWMCompare1, 0x0000FFFF, write32_test
.8byte PWMCompare2, 0x0000FFFF, write32_test
.8byte PWMCompare3, 0x0000FFFF, write32_test
.8byte PWMConfig, 0x00011000, write32_test      # set PWMEnAlways to 1 w ZeroCompare off - necessary for center tests because counter has to keep going after matching Compare
.8byte 0x0, 0x0000000, pwm_cycle_wait_center      # wait 1 PWM cycle
.8byte PWMCompare0, 0x00007FFF, write32_test    #set Compare0 to ((2^16)/2) - 1 for the minimum high time
.8byte PWMConfig, 0x00011000, write32_test      # set PWMEnOneShot to 1 to start cycle
.8byte 0x0, 0x0000000, pwm_cycle_wait_center        # wait 1 PWM cycle
#.8byte PWMCompare0, 0x00008000, write32_test    #set Compare0 to ((2^16)/2) for the always low
#.8byte PWMConfig, 0x00011000, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x0000001, pwm_cycle_wait

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
.8byte PWMConfig, 0x00000600, write32_test      # initialize config register with deglitch, zerocmp
.8byte PWMCompare0, 0x00000001, write32_test    # set PWMCompare0
.8byte PWMConfig, 0x00001600, write32_test      # set PWMEnAlways, ip should insantly be high
.8byte PWMCompare0, 0x0000FFFF, write32_test    # set compare register to max, comparator is 0 but deglitch should prevent ip from falling
.8byte 0x0, 0x00000000, pwm_dumb_wait         # wait for 1 cycle

# =========== Scale 0 tests ==============

#.8byte PWMConfig, 0x00000000, write32_test      # initialize config register
#.8byte PWMCompare0, 0x00000000, write32_test    # set Compare0 register to 0
#.8byte PWMConfig, 0x00002002, write32_test      # set PWMEnOneShot to 1 to start cycle
#.8byte 0x0, 0x0000000, pwm_dumb_wait          # wait 1 PWM cycle
#.8byte PWMCompare0, 0x00000001, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001002, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000000, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x00008888, write32_test    # set Compare0 to 8888, half of 16 bit capacity
#.8byte PWMConfig, 0x00001002, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000000, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFE, write32_test    # set Compare0 to max -1
#.8byte PWMConfig, 0x00001002, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000000, pwm_dumb_wait         # wait 8 PWM cycles
#.8byte PWMCompare0, 0x0000FFFF, write32_test    # set Compare0 to 1
#.8byte PWMConfig, 0x00001002, write32_test      # set PWMEnAlways to 1 to start cycle
#.8byte 0x0, 0x00000000, pwm_dumb_wait         # wait 8 PWM cycles




.8byte 0x0, 0x0, terminate_test
