# Jordan Carlin, jcarlin@hmc.edu, September 20 2024
# Makefile to generate floating point testvectors for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

.PHONY: ieee riscv clean
all: ieee riscv

ieee:
	$(MAKE) -C ieee

riscv:
	$(MAKE) -C riscv

clean:
	$(MAKE) -C ieee clean
	$(MAKE) -C riscv clean
