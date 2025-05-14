# David_Harris@hmc.edu 2023
# Top-level Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

MAKEFLAGS += --output-sync --no-print-directory

SIM = ${WALLY}/sim

.PHONY: all riscof testfloat combined_IF_vectors zsbl coverage cvw-arch-verif sim_bp deriv clean

all: riscof	testfloat combined_IF_vectors zsbl coverage sim_bp cvw-arch-verif deriv

# riscof builds the riscv-arch-test and wally-riscv-arch-test suites
riscof:
	$(MAKE) -C tests/riscof

testfloat:
	$(MAKE) -C ${WALLY}/tests/fp vectors

combined_IF_vectors: testfloat riscof
	$(MAKE) -C ${WALLY}/tests/fp combined_IF_vectors

zsbl:
	$(MAKE) -C ${WALLY}/fpga/zsbl

coverage:
	$(MAKE) -C tests/coverage

deriv:
	derivgen.pl

cvw-arch-verif:
	$(MAKE) -C ${WALLY}/addins/cvw-arch-verif

sim_bp: ${WALLY}/addins/branch-predictor-simulator/src/sim_bp

${WALLY}/addins/branch-predictor-simulator/src/sim_bp:
	$(MAKE) -C ${WALLY}/addins/branch-predictor-simulator/src

# Requires a license for the Breker tool. See tests/breker/README.md for details
breker:
	$(MAKE) -C ${WALLY}/testbench/trek_files
	$(MAKE) -C ${WALLY}/tests/breker

clean:
	$(MAKE) clean -C ${WALLY}/tests/riscof
	$(MAKE) clean -C ${WALLY}/tests/fp
	$(MAKE) clean -C ${WALLY}/fpga/zsbl
	$(MAKE) clean -C ${WALLY}/tests/coverage
	$(MAKE) clean -C ${WALLY}/addins/cvw-arch-verif
