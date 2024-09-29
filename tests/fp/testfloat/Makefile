# Jordan Carlin, jcarlin@hmc.edu, August 2024
# Makefile to generate RISCV and IEEE varaints of Testfloat for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# Makefile to build testfloat and softfloat executables for IEEE and RISC-V floating point variants

# Disable parallel execution because both versions of softfloat/testfloat use the same build directory
.NOTPARALLEL:
.SECONDEXPANSION:

DIR := $(shell pwd)

# SoftFloat variables
SOFTFLOAT_DIR := ${WALLY}/addins/berkeley-softfloat-3
SOFTFLOAT_INCLUDE_DIR := source/include/
SOFTFLOAT_BUILD_DIR := build/Linux-x86_64-GCC/
SOFTFLOAT_ORIGINAL_BUILD_DIR := ${SOFTFLOAT_DIR}/${SOFTFLOAT_BUILD_DIR}
SOFTFLOAT_ORIGINAL_INCLUDE_DIR := ${SOFTFLOAT_DIR}/${SOFTFLOAT_INCLUDE_DIR}
SOFTFLOAT_LIB := softfloat.a
COPIED_SOFTFLOAT_LIB := softfloat/${SOFTFLOAT_BUILD_DIR}/${SOFTFLOAT_LIB}
ORIGINAL_SOFTFLOAT_LIB := ${SOFTFLOAT_ORIGINAL_BUILD_DIR}/${SOFTFLOAT_LIB}

# TestFloat variables
TESTFLOAT_DIR := ${WALLY}/addins/berkeley-testfloat-3
TESTFLOAT_BUILD_DIR := build/Linux-x86_64-GCC
TESTFLOAT_ORIGINAL_BUILD_DIR := ${TESTFLOAT_DIR}/${TESTFLOAT_BUILD_DIR}
TESTFLOAT_EXECUTABLES := testfloat testfloat_gen testfloat_ver testsoftfloat timesoftfloat
ORIGINAL_TESTFLOAT_EXECUTABLES := $(foreach item,${TESTFLOAT_EXECUTABLES},$(patsubst %,${TESTFLOAT_ORIGINAL_BUILD_DIR}%,/${item}))

.PHONY: all ieee riscv clean

all: ieee riscv

ieee riscv: ieee-testfloat #$$@/testfloat/${TESTFLOAT_BUILD_DIR}/testfloat

ieee-testfloat: ieee/testfloat/${TESTFLOAT_BUILD_DIR}/testfloat
ieee-softfloat: ieee/$(COPIED_SOFTFLOAT_LIB)

# .PRECIOUS: %/testfloat
%/testfloat/${TESTFLOAT_BUILD_DIR}/testfloat: %/$(COPIED_SOFTFLOAT_LIB)
	$(MAKE) -C $(TESTFLOAT_ORIGINAL_BUILD_DIR) clean
	$(MAKE) SOFTFLOAT_DIR=${DIR}/$*/softfloat -C $(TESTFLOAT_ORIGINAL_BUILD_DIR)
	cp -r ${ORIGINAL_TESTFLOAT_EXECUTABLES} $*/testfloat/${TESTFLOAT_BUILD_DIR}/
	$(MAKE) -C $(TESTFLOAT_ORIGINAL_BUILD_DIR) clean

# Build specified version of SoftFloat, either IEEE or RISCV
riscv/$(COPIED_SOFTFLOAT_LIB): SPECIALIZE_TYPE = SPECIALIZE_TYPE=RISCV
%/$(COPIED_SOFTFLOAT_LIB): %/${SOFTFLOAT_INCLUDE_DIR}/softfloat.h
	$(MAKE) -C $(SOFTFLOAT_ORIGINAL_BUILD_DIR) clean
	$(MAKE) $(SPECIALIZE_TYPE) -C $(SOFTFLOAT_ORIGINAL_BUILD_DIR)
	cp ${ORIGINAL_SOFTFLOAT_LIB} $*/${COPIED_SOFTFLOAT_LIB}
	$(MAKE) -C $(SOFTFLOAT_ORIGINAL_BUILD_DIR) clean

# Setup directories and link softfloat headers
%/${SOFTFLOAT_INCLUDE_DIR}/softfloat.h:
	mkdir -p $*/softfloat/source/include
	ln -sf ${SOFTFLOAT_ORIGINAL_INCLUDE_DIR}/* $*/softfloat/${SOFTFLOAT_INCLUDE_DIR}
	mkdir -p $*/softfloat/build/Linux-x86_64-GCC
	mkdir -p $*/testfloat/${TESTFLOAT_BUILD_DIR}

clean:
	$(MAKE) -C $(SOFTFLOAT_ORIGINAL_BUILD_DIR) clean
	$(MAKE) -C $(TESTFLOAT_ORIGINAL_BUILD_DIR) clean
	rm -rf ieee/* riscv/*
