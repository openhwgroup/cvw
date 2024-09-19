# Jordan Carlin, jcarlin@hmc.edu, August 2024
# Testfloat vector Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# Makefile to build testfloat and softfloat executables for IEEE and RISC-V floating point variants

# Disable parallel execution because both versions of softfloat/testfloat use the same build directory
.NOTPARALLEL:
.SECONDEXPANSION:

TESTFLOATS := ieee riscv
SOFTFLOAT_BUILD_DIR := ${WALLY}/addins/berkeley-softfloat-3/build/Linux-x86_64-GCC/
TESTFLOAT_BUILD_DIR := ${WALLY}/addins/berkeley-testfloat-3/build/Linux-x86_64-GCC/
TESTFLOAT_EXECUTABLES := testfloat testfloat_gen testfloat_ver testsoftfloat timesoftfloat
ORIGINAL_TESTFLOAT_EXECUTABLES := $(foreach item,${TESTFLOAT_EXECUTABLES},$(patsubst %,${TESTFLOAT_BUILD_DIR}%,${item}))

.PHONY: all ieee-softfloat riscv-softfloat ${TESTFLOATS} testfloat clean

all: riscv ieee

${TESTFLOATS}: dir_$$@ $$@/testfloat_gen

.PRECIOUS: %/testfloat_gen
%/testfloat_gen:
	$(MAKE) $*-softfloat
	$(MAKE) testfloat
	cp -r ${ORIGINAL_TESTFLOAT_EXECUTABLES} $*/

ieee-softfloat:
	$(MAKE) -C $(SOFTFLOAT_BUILD_DIR) clean
	$(MAKE) -C $(SOFTFLOAT_BUILD_DIR)

riscv-softfloat:
	$(MAKE) -C $(SOFTFLOAT_BUILD_DIR) clean
	$(MAKE) SPECIALIZE_TYPE=RISCV -C $(SOFTFLOAT_BUILD_DIR)

testfloat:
	$(MAKE) -C $(TESTFLOAT_BUILD_DIR) clean
	$(MAKE) -C $(TESTFLOAT_BUILD_DIR)

dir_%:
	mkdir -p $*

clean:
	$(MAKE) -C $(SOFTFLOAT_BUILD_DIR) clean
	$(MAKE) -C $(TESTFLOAT_BUILD_DIR) clean
	rm -f ieee/* riscv/*
