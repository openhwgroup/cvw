# Makefile for testbench to create .memfile, .objdump.addr, and .objdump.lab from an ELF
# David_Harris@hmc.edu 3 July 2024
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

%.memfile: %
	riscv64-unknown-elf-elf2hex  --bit-width $(if $(findstring rv32,$*),32,64) --input $< --output $@

%.objdump.addr: %.objdump
	extractFunctionRadix.sh $<

%.objdump: %
	riscv64-unknown-elf-objdump -S -D $< > $@
