# Jordan Carlin, jcarlin@hmc.edu, August 2024
# Floating Point Tests Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

MAKEFLAGS += --output-sync --no-print-directory

SOFTFLOAT_DIR := ${WALLY}/addins/berkeley-softfloat-3/build/Linux-x86_64-GCC
TESTFLOAT_DIR := ${WALLY}/addins/berkeley-testfloat-3/build/Linux-x86_64-GCC

.PHONY: all softfloat testfloat vectors combined_IF_vectors clean

all: vectors combined_IF_vectors

softfloat: ${SOFTFLOAT_DIR}/softfloat.a

testfloat: ${TESTFLOAT_DIR}/testfloat_gen

vectors: testfloat
	$(MAKE) -C ${WALLY}/tests/fp/vectors

combined_IF_vectors: ${WALLY}/tests/riscof/work/riscv-arch-test/rv32i_m/M/src vectors
	cd ${WALLY}/tests/fp/combined_IF_vectors \
	&& ./create_IF_vectors.sh

clean:
	$(MAKE) -C ${WALLY}/tests/fp/vectors clean
	$(MAKE) -C ${SOFTFLOAT_DIR} clean
	$(MAKE) -C ${TESTFLOAT_DIR} clean
	rm -f ${WALLY}/tests/fp/combined_IF_vectors/IF_vectors/*.tv

${SOFTFLOAT_DIR}/softfloat.a:
	$(MAKE) SPECIALIZE_TYPE=RISCV -C ${SOFTFLOAT_DIR}

${TESTFLOAT_DIR}/testfloat_gen: ${SOFTFLOAT_DIR}/softfloat.a
	$(MAKE) -C ${TESTFLOAT_DIR}

${WALLY}/tests/riscof/work/riscv-arch-test/rv32i_m/M/src:
	@$(error "riscv-arch-tests must be generated first. Run make from $$WALLY")
