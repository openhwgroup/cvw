# Jordan Carlin, jcarlin@hmc.edu, August 2024
# Floating Point Tests Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

TESTFLOATS := testfloat/ieee/testfloat_gen testfloat/riscv/testfloat_gen

.PHONY: all vectors combined_IF_vectors testfloat clean

all: vectors combined_IF_vectors

vectors: ${TESTFLOATS}
	$(MAKE) -C ${WALLY}/tests/fp/vectors

combined_IF_vectors: ${WALLY}/tests/riscof/work/riscv-arch-test/rv32i_m/M/src vectors
	cd ${WALLY}/tests/fp/combined_IF_vectors \
	&& ./create_IF_vectors.sh

${TESTFLOATS}: testfloat

testfloat:
	$(MAKE) -C testfloat

clean:
	$(MAKE) -C vectors clean
	$(MAKE) -C testfloat clean
	rm -f ${WALLY}/tests/fp/combined_IF_vectors/IF_vectors/*.tv

${WALLY}/tests/riscof/work/riscv-arch-test/rv32i_m/M/src:
	@$(error "riscv-arch-tests must be generated first. Run make from $$WALLY")
