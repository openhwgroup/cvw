# Makefile for testbench to create .memfile, .objdump.addr, and .objdump.lab from an ELF
# David_Harris@hmc.edu 3 July 2024
# james.stine@okstate.edu 24 Jan 2025
# jcarlin@hmc.edu 7 Jul 2025
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# the width is set by the elf's type to allow for individual elf compilation

BITWIDTH = $(if $(findstring ELF32, $(shell riscv64-unknown-elf-readelf -h $<)),32, \
	         $(if $(findstring ELF64, $(shell riscv64-unknown-elf-readelf -h $<)),64, \
					 $(error "Unknown bit width (XLEN) for $<")))

%.memfile: %
	echo "Processing $< with --bit-width ${BITWIDTH}"; \
	riscv64-unknown-elf-elf2hex --bit-width ${BITWIDTH} --input $< --output $@

%.objdump.addr: %.objdump
	extractFunctionRadix.sh $<

%.objdump: %
	riscv64-unknown-elf-objdump -S -D $< > $@
