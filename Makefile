# David_Harris@hmc.edu 2023
# Top-level Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

SIM = ${WALLY}/sim

.PHONY: all riscof testfloat zsbl benchmarks coremark embench coverage clean

all: riscof	testfloat zsbl coverage # benchmarks

# riscof builds the riscv-arch-test and wally-riscv-arch-test suites
riscof:
	$(MAKE) -C sim

testfloat:
	$(MAKE) -C ${WALLY}/addins/SoftFloat-3e/build/Linux-x86_64-GCC
	$(MAKE) -C ${WALLY}/addins/TestFloat-3e/build/Linux-x86_64-GCC
	cd ${WALLY}/tests/fp && ./create_all_vectors.sh

zsbl:
	$(MAKE) -C ${WALLY}/fpga/zsbl

benchmarks:
	$(MAKE) coremark
	$(MAKE) embench

coremark:
	cd ${WALLY}/benchmarks/coremark; $(MAKE); #$(MAKE) run

embench:
	cd ${WALLY}/benchmarks/embench; $(MAKE); #$(MAKE) run

coverage:
	$(MAKE) -C tests/coverage

clean:
	$(MAKE) clean -C sim
