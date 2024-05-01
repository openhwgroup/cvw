# David_Harris@hmc.edu 2023
# Top-level Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

include ${WALLY}/sim/riscvdv/riscvdv.testslists
SIM = ${WALLY}/sim

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
	cd ${SIM}; ./regression-wally
	cd ${SIM}/sim; ./sim-testfloat-batch all
	make imperasdv

imperasdv:
	iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m
	iter-elf.bash --search ${WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m

imperasdv_cov:
	run-elf-cov.bash --elf ${WALLY}/tests/riscvdv/asm_test/riscv_arithmetic_basic_test_0.elf --coverdb ${SIM}/questa/riscv.ucdb --verbose
	vcover report -details -html ${SIM}/questa/riscv.ucdb

funcovreg:
#	iter-elf.bash --search ${path_to_tests_dir} --cover
#	iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m/I --cover
#	iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m/privilege --cover
#	iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m/Q --cover
	rm -f ${WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/*/src/*/dut/my.elf
	iter-elf.bash --search ${WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/I --cover
	vcover report -details -html ${SIM}/questa/riscv.ucdb

rvdv_gen_com_questa_run_cov:
	python3 ${WALLY}/addins/riscv-dv/run.py --test ${test_name} --target rv64gc --output tests/riscvdv  --iterations 1 -si questa --verbose --cov --seed ${seed_value} --steps gen,gcc_compile
	${SIM}/riscvdv/riscvdv-coverage.bash --seed ${SEED_VALUE} --test_name ${test_name} --verbose --coverdb ${SIM}/questa/${SEED_VALUE}/${test_name}/riscv.ucdb --elf ${WALLY}/tests/riscvdv/asm_test/${test_name}_0.o
	vcover merge -suppress 6854 -64 ${SIM}/multiple_regressions/merged.ucdb ${SIM}/multiple_regressions/merged.ucdb ${SIM}/questa/${SEED_VALUE}/${test_name}/riscv.ucdb

rvdv_regression:
	echo ${SEED_VALUE}
	mkdir -p ${SIM}/questa/${SEED_VALUE}
	for test in $(riscvdv_rv64gc_testlist); \
	do \
	mkdir -p ${SIM}/questa/${SEED_VALUE}/$$test; \
	make rvdv_gen_com_questa_run_cov test_name=$$test seed_value=${SEED_VALUE} >> ${SIM}/questa/${SEED_VALUE}/$$test/${SEED_VALUE}_$$test.log 2>&1 ; \
	done
#	vcover merge -suppress 6854 -64 ${SIM}/multiple_regressions/merged.ucdb ${SIM}/multiple_regressions/merged.ucdb ${SIM}/questa/${SEED_VALUE}/*/riscv.ucdb;

rvdv_regression_loop:
	mkdir -p ${SIM}/multiple_regressions
	for i in {1..1}; \
	do make -j4 rvdv_regression SEED_VALUE=$$RANDOM; \
	done
	vcover report -details -html ${SIM}/multiple_regressions/merged.ucdb
	vcover report ${SIM}/multiple_regressions/merged.ucdb -details -cvg > ${SIM}/multiple_regressions/merged.log
	vcover report ${SIM}/multiple_regressions/merged.ucdb -testdetails -cvg > ${SIM}/multiple_regressions/merged.testdetails.log
	vcover report ${SIM}/multiple_regressions/merged.ucdb -details -cvg -below 100 | egrep "Coverpoint|Covergroup|Cross" | grep -v Metric > ${SIM}/multiple_regressions/merged.summary.log
	grep "Total Coverage By Instance" ${SIM}/multiple_regressions/merged.log
#	vcover report ${WALLY}/sim/multiple_regressions/merged.ucdb -details -cvg | 	grep "Total Coverage By Instance"

coverage:
	regression-wally -coverage -fp

benchmarks:
	make coremark
	make embench

coremark:
	cd ${WALLY}/benchmarks/coremark; make; make run

embench:
	cd ${WALLY}/benchmarks/embench; make; make run


clean:
	make clean -C sim

