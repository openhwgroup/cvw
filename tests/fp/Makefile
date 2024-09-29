# Jordan Carlin, jcarlin@hmc.edu, August 2024
# Floating Point Tests Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

TESTFLOAT := testfloat/build/Linux-x86_64-GCC/testfloat_gen
TESTFLOATS := berkeley-float/ieee/${TESTFLOAT} berkeley-float/riscv/${TESTFLOAT}

.PHONY: all vectors combined_IF_vectors testfloat clean

all: vectors combined_IF_vectors

vectors: ${TESTFLOATS}
	$(MAKE) -C ${WALLY}/tests/fp/vectors

combined_IF_vectors: ${WALLY}/tests/riscof/work/riscv-arch-test/rv32i_m/M/src vectors
	cd ${WALLY}/tests/fp/combined_IF_vectors \
	&& ./create_IF_vectors.sh

${TESTFLOATS}: testfloat

testfloat:
	$(MAKE) -C berkeley-float

clean:
	$(MAKE) -C vectors clean
	$(MAKE) -C berkeley-float clean
	rm -f ${WALLY}/tests/fp/combined_IF_vectors/IF_vectors/*.tv

${WALLY}/tests/riscof/work/riscv-arch-test/rv32i_m/M/src:
	@$(error "riscv-arch-tests must be generated first. Run make from $$WALLY")
