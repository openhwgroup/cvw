# David_Harris@hmc.edu 2023
# Top-level Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

all:
	make install
	make riscof	
	make testfloat
#	make verify
	make coverage
	make benchmarks

# install copies over the Makefile.include from riscv-isa-sim
# And corrects the TARGETDIR path and the RISCV_PREFIX

install:
	# *** 1/15/23 dh: check if any of this is still needed
	#cp ${RISCV}/riscv-isa-sim/arch_test_target/spike/Makefile.include addins/riscv-arch-test/
	#sed -i '/export TARGETDIR ?=/c\export TARGETDIR ?= ${RISCV}/riscv-isa-sim/arch_test_target' addins/riscv-arch-test/Makefile.include
	#echo export RISCV_PREFIX = riscv64-unknown-elf- >> addins/riscv-arch-test/Makefile.include
	##cd tests/linux-testgen/linux-testvectors; source ./tvLinker.sh # needs to be run in local directory
	##rm tests/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64/riscvOVPsimPlus.exe
	##ln -s ${RISCV}/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64/riscvOVPsimPlus.exe tests/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64/riscvOVPsimPlus.exe

riscof:
	make -C sim

testfloat:
	cd ${WALLY}/addins/SoftFloat-3e/build/Linux-x86_64-GCC; make
	cd ${WALLY}/addins/TestFloat-3e/build/Linux-x86_64-GCC; make
	cd ${WALLY}/tests/fp; ./create_all_vectors.sh

verify:
	cd ${WALLY}/sim; ./regression-wally
	cd ${WALLY}/sim; ./sim-testfloat-batch all
	make imperasdv

imperasdv:
	iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m
	iter-elf.bash --search ${WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m

coverage:
	cd ${WALLY}/sim; ./regression-wally -coverage -fp

benchmarks:
	make coremark
	make embench

coremark:
	cd ${WALLY}/benchmarks/coremark; make; make run

embench:
	cd ${WALLY}/benchmarks/embench; make; make run


clean:
	make clean -C sim

