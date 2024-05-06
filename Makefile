# David_Harris@hmc.edu 2023
# Top-level Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

SIM = ${WALLY}/sim

all:
	make riscof	
	make testfloat
#	make verify
#	make coverage
#	make benchmarks

# riscof builds the riscv-arch-test and wally-riscv-arch-test suites
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
	touch ${SIM}/seed0.txt
	echo "0" > ${SIM}/seed0.txt
#	/opt/riscv/ImperasDV-OpenHW/scripts/cvw/run-elf-cov.bash --verbose --seed 0 --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m
#	/opt/riscv/ImperasDV-OpenHW/scripts/cvw/run-elf-cov.bash --elf ${WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/I/src/add-01.S/dut/my.elf --seed ${SIM}/seed0.txt --coverdb ${SIM}/cov/rv64gc_arch64i.ucdb --verbose
#	/opt/riscv/ImperasDV-OpenHW/scripts/cvw/run-elf-cov.bash --elf ${WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/I/src/add-01.S/dut/my.elf --seed ${SIM}/seed0.txt --coverdb ${SIM}/questa/riscv.ucdb --verbose
	run-elf-cov.bash --elf ${WALLY}/tests/riscvdv/asm_test/riscv_arithmetic_basic_test_0.elf --seed ${SIM}/questa/seed0.txt --coverdb ${SIM}/questa/riscv.ucdb --verbose
	vcover report -details -html ${SIM}/questa/riscv.ucdb

funcovreg:
	#iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m --cover
	#iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m/I --cover
	#iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m/privilege --cover
	#iter-elf.bash --search ${WALLY}/tests/riscof/work/wally-riscv-arch-test/rv64i_m/Q --cover
	rm -f ${WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/*/src/*/dut/my.elf
	iter-elf.bash --search ${WALLY}/tests/riscof/work/riscv-arch-test/rv64i_m/I --cover
	vcover report -details -html ${SIM}/questa/riscv.ucdb



# test_name=riscv_arithmetic_basic_test
riscvdv: 
	python3 ${WALLY}/addins/riscv-dv/run.py --test ${test_name} --target rv64gc --output tests/riscvdv  --iterations 1 -si questa --iss spike --verbose --cov --seed 0 --steps gen,gcc_compile			>> ${SIM}/questa/functcov_logs/${test_name}.log 2>&1
#	python3 ${WALLY}/addins/riscv-dv/run.py --test ${test_name} --target rv64gc --output tests/riscvdv  --iterations 1 -si questa --iss spike --verbose --cov --seed 0 --steps gcc_compile	>> ${SIM}/questa/functcov_logs/${test_name}.log 2>&1
#	python3 ${WALLY}/addins/riscv-dv/run.py --test ${test_name} --target rv64gc --output tests/riscvdv  --iterations 1 -si questa --iss spike --verbose --cov --seed 0 --steps iss_sim		>> ${SIM}/questa/functcov_logs/${test_name}.log 2>&1
#	run-elf.bash --seed ${SIM}/questa/seed0.txt --verbose --elf ${WALLY}/tests/riscvdv/asm_test/${test_name}_0.o													>> ${SIM}/questa/functcov_logs/${test_name}.log 2>&1
	run-elf-cov.bash --seed ${SIM}/questa/seed0.txt --verbose --coverdb ${SIM}/questa/riscv.ucdb --elf ${WALLY}/tests/riscvdv/asm_test/${test_name}_0.o								>> ${SIM}/questa/functcov_logs/${test_name}.log 2>&1
	cp ${SIM}/questa/riscv.ucdb ${SIM}/questa/functcov_ucdbs/${test_name}.ucdb

riscvdv_functcov:
	mkdir -p ${SIM}/questa/functcov_logs
	mkdir -p ${SIM}/questa/functcov_ucdbs
	cd ${SIM}/questa/functcov_logs && rm -rf *
	cd ${SIM}/questa/functcov_ucdbs && rm -rf *
	make riscvdv test_name=riscv_arithmetic_basic_test				>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_amo_test							>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_ebreak_debug_mode_test			>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_ebreak_test						>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_floating_point_arithmetic_test	>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_floating_point_mmu_stress_test	>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_floating_point_rand_test			>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_full_interrupt_test				>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_hint_instr_test					>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_illegal_instr_test				>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_invalid_csr_test					>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_jump_stress_test					>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_loop_test							>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_machine_mode_rand_test			>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_mmu_stress_test					>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_no_fence_test						>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_non_compressed_instr_test			>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_pmp_test							>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_privileged_mode_rand_test			>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_rand_instr_test					>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_rand_jump_test					>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_sfence_exception_test				>> ${SIM}/questa/functcov.log 2>&1
	make riscvdv test_name=riscv_unaligned_load_store_test			>> ${SIM}/questa/functcov.log 2>&1

combine_functcov:
	mkdir -p ${SIM}/questa/functcov
	cd ${SIM}/questa/functcov && rm -rf *
	run-elf-cov.bash --seed ${SIM}/questa/seed0.txt --verbose --coverdb ${SIM}/questa/functcov/add.ucdb --elf ${WALLY}/tests/functcov/rv64/I/WALLY-COV-add.elf								>> ${SIM}/questa/functcov_logs/add.log 2>&1
	run-elf-cov.bash --seed ${SIM}/questa/seed0.txt --verbose --coverdb ${SIM}/questa/functcov/and.ucdb --elf ${WALLY}/tests/functcov/rv64/I/WALLY-COV-and.elf								>> ${SIM}/questa/functcov_logs/add.log 2>&1
	run-elf-cov.bash --seed ${SIM}/questa/seed0.txt --verbose --coverdb ${SIM}/questa/functcov/ori.ucdb --elf ${WALLY}/tests/functcov/rv64/I/WALLY-COV-ori.elf								>> ${SIM}/questa/functcov_logs/add.log 2>&1

	vcover merge ${SIM}/questa/functcov/functcov.ucdb ${SIM}/questa/functcov/*.ucdb ${SIM}/questa/functcov_ucdbs/* -suppress 6854 -64
	# vcover merge ${SIM}/questa/functcov/functcov.ucdb ${SIM}/questa/functcov_ucdbs/* -suppress 6854 -64
	vcover report -details -html ${SIM}/questa/functcov/functcov.ucdb
	vcover report ${SIM}/questa/functcov/functcov.ucdb -details -cvg > ${SIM}/questa/functcov/functcov.log
	vcover report ${SIM}/questa/functcov/functcov.ucdb -testdetails -cvg > ${SIM}/questa/functcov/functcov.testdetails.log
#	vcover report ${SIM}/questa/functcov/functcov.ucdb -details -cvg -below 100 | egrep "Coverpoint|Covergroup|Cross" | grep -v Metric > ${SIM}/questa/functcov/functcov.ucdb.summary.log
	vcover report ${SIM}/questa/functcov/functcov.ucdb -details -cvg | egrep "Coverpoint|Covergroup|Cross|TYPE"  > ${SIM}/questa/functcov/functcov.summary.log
	grep "Total Coverage By Instance" ${SIM}/questa/functcov/functcov.ucdb.log

remove_functcov_artifacts:
	rm ${SIM}/questa/riscv.ucdb ${SIM}/questa/functcov.log covhtmlreport/ ${SIM}/questa/functcov_logs/ ${SIM}/questa/functcov_ucdbs/ ${SIM}/questa/functcov/ -rf

collect_functcov: remove_functcov_artifacts riscvdv_functcov combine_functcov

benchmarks:
	make coremark
	make embench

coremark:
	cd ${WALLY}/benchmarks/coremark; make; make run

embench:
	cd ${WALLY}/benchmarks/embench; make; make run


clean:
	make clean -C sim

