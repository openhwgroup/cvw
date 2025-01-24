# Makefile for testbench to create .memfile, .objdump.addr, and .objdump.lab from an ELF
# David_Harris@hmc.edu 3 July 2024
# james.stine@okstate.edu 24 Jan 2025
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# the width is set by the elf's type to allow for individual elf compilation
%.memfile: %
	@if grep -q 'elf32' $*.objdump; then \
		BIT_WIDTH=32; \
	else \
		BIT_WIDTH=64; \
	fi; \
	echo "Processing $< with --bit-width $$BIT_WIDTH"; \
	riscv64-unknown-elf-elf2hex --bit-width $$BIT_WIDTH --input $< --output $@

%.objdump.addr: %.objdump
	extractFunctionRadix.sh $<

%.objdump: %
	riscv64-unknown-elf-objdump -S -D $< > $@
