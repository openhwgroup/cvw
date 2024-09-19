# Jordan Carlin, jcarlin@hmc.edu, August 2024
# Testfloat vector Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# Makefile to build testfloat and softfloat executables for IEEE and RISC-V floating point variants

# Disable parallel execution because both versions of softfloat/testfloat use the same build directory
.NOTPARALLEL:

TESTFLOATS := ieee-testfloat riscv-testfloat
SOFTFLOAT_BUILD_DIR := ${WALLY}/addins/berkeley-softfloat-3/build/Linux-x86_64-GCC
TESTFLOAT_BUILD_DIR := ${WALLY}/addins/berkeley-testfloat-3/build/Linux-x86_64-GCC
TESTFLOAT_EXECUTABLES := ${TESTFLOAT_BUILD_DIR}/testfloat ${TESTFLOAT_BUILD_DIR}/testfloat_gen \
                         ${TESTFLOAT_BUILD_DIR}/testfloat_ver ${TESTFLOAT_BUILD_DIR}/testsoftfloat \
												 ${TESTFLOAT_BUILD_DIR}/timesoftfloat

.PHONY: all ieee-softfloat riscv-softfloat testfloat clean

all: $(TESTFLOATS)

%-testfloat:
	$(MAKE) -C $(TESTFLOAT_BUILD_DIR) clean
	$(MAKE) $*-softfloat
	$(MAKE) -C ${TESTFLOAT_BUILD_DIR}
	mkdir -p $*
	cp -r ${TESTFLOAT_EXECUTABLES} $*/

ieee-softfloat:
	$(MAKE) -C $(SOFTFLOAT_BUILD_DIR) clean
	$(MAKE) -C $(SOFTFLOAT_BUILD_DIR)

riscv-softfloat:
	$(MAKE) -C $(SOFTFLOAT_BUILD_DIR) clean
	$(MAKE) SPECIALIZE_TYPE=riscv -C $(SOFTFLOAT_BUILD_DIR)

clean:
	$(MAKE) -C $(SOFTFLOAT_BUILD_DIR) clean
	$(MAKE) -C $(TESTFLOAT_BUILD_DIR) clean
	rm -f ieee/* riscv/*
