# David_Harris@hmc.edu 15 July 2024
# Simulation  Makefile for CORE-V-Wally
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

SIM = ${WALLY}/sim
TESTS = ${WALLY}/tests

all: riscoftests coveragetests deriv

wally-riscv-arch-test: wallyriscoftests

QuestaCodeCoverage: questa/ucdb/rv64gc_arch64i.ucdb
	vcover merge -out questa/ucdb/cov.ucdb questa/ucdb/rv64gc_arch64i.ucdb questa/ucdb/rv64gc*.ucdb -logfile questa/cov/log
#	vcover merge -out questa/ucdb/cov.ucdb questa/ucdb/rv64gc_arch64i.ucdb questa/ucdb/rv64gc*.ucdb questa/ucdb/buildroot_buildroot.ucdb riscv.ucdb -logfile questa/cov/log
	vcover report -details questa/ucdb/cov.ucdb > questa/cov/rv64gc_coverage_details.rpt
	vcover report questa/ucdb/cov.ucdb -details -instance=/core/ebu. > questa/cov/rv64gc_coverage_ebu.rpt
	vcover report questa/ucdb/cov.ucdb -details -instance=/core/priv. > questa/cov/rv64gc_coverage_priv.rpt
	vcover report questa/ucdb/cov.ucdb -details -instance=/core/ifu. > questa/cov/rv64gc_coverage_ifu.rpt
	vcover report questa/ucdb/cov.ucdb -details -instance=/core/lsu. > questa/cov/rv64gc_coverage_lsu.rpt
	vcover report questa/ucdb/cov.ucdb -details -instance=/core/fpu. > questa/cov/rv64gc_coverage_fpu.rpt
	vcover report questa/ucdb/cov.ucdb -details -instance=/core/ieu. > questa/cov/rv64gc_coverage_ieu.rpt
	vcover report questa/ucdb/cov.ucdb -below 100 -details -instance=/core/ebu. > questa/cov/rv64gc_uncovered_ebu.rpt
	vcover report questa/ucdb/cov.ucdb -below 100 -details -instance=/core/priv. > questa/cov/rv64gc_uncovered_priv.rpt
	vcover report questa/ucdb/cov.ucdb -below 100 -details -instance=/core/ifu. > questa/cov/rv64gc_uncovered_ifu.rpt
	vcover report questa/ucdb/cov.ucdb -below 100 -details -instance=/core/lsu. > questa/cov/rv64gc_uncovered_lsu.rpt
	vcover report questa/ucdb/cov.ucdb -below 100 -details -instance=/core/fpu. > questa/cov/rv64gc_uncovered_fpu.rpt
	vcover report questa/ucdb/cov.ucdb -below 100 -details -instance=/core/ieu. > questa/cov/rv64gc_uncovered_ieu.rpt
	vcover report -hierarchical questa/ucdb/cov.ucdb > questa/cov/rv64gc_coverage_hierarchical.rpt
	vcover report -below 100 -hierarchical questa/ucdb/cov.ucdb > questa/cov/rv64gc_uncovered_hierarchical.rpt
#	vcover report -below 100 questa/ucdb/cov.ucdb > questa/cov/rv64gc_coverage.rpt
#	vcover report -recursive questa/ucdb/cov.ucdb > questa/cov/rv64gc_recursive.rpt
	vcover report -details -threshH 100 -html questa/ucdb/cov.ucdb

QuestaFunctCoverageRvvi: ${WALLY}/addins/cvw-arch-verif/work/rv64gc_arch64i.ucdb 
	vcover merge -out ${SIM}/questa/fcovrvvi_ucdb/fcovrvvi.ucdb ${WALLY}/addins/cvw-arch-verif/work/rv64gc_arch64i.ucdb ${WALLY}/addins/cvw-arch-verif/work/rv64gc_*.ucdb -logfile ${SIM}/questa/fcovrvvi/log
	vcover report -details -html ${SIM}/questa/fcovrvvi_ucdb/fcovrvvi.ucdb
	vcover report ${SIM}/questa/fcovrvvi_ucdb/fcovrvvi.ucdb -details -cvg > ${SIM}/questa/fcovrvvi/fcovrvvi.log
	vcover report ${SIM}/questa/fcovrvvi_ucdb/fcovrvvi.ucdb -testdetails -cvg > ${SIM}/questa/fcovrvvi/fcovrvvi.testdetails.log
	vcover report ${SIM}/questa/fcovrvvi_ucdb/fcovrvvi.ucdb -details -cvg | egrep "Coverpoint|Covergroup|Cross|TYPE"  > ${SIM}/questa/fcovrvvi/fcovrvvi.summary.log
	grep "TOTAL COVERGROUP COVERAGE" ${SIM}/questa/fcovrvvi/fcovrvvi.log

riscvdv:
	python3 ${WALLY}/addins/riscv-dv/run.py --test ${test_name} --target rv64gc --output tests/riscvdv  --iterations 1 -si questa --iss spike --verbose --cov --seed 0 --steps gen,gcc_compile			>> ${SIM}/questa/fcov_logs/${test_name}.log 2>&1
#	python3 ${WALLY}/addins/riscv-dv/run.py --test ${test_name} --target rv64gc --output tests/riscvdv  --iterations 1 -si questa --iss spike --verbose --cov --seed 0 --steps gcc_compile	>> ${SIM}/questa/fcov_logs/${test_name}.log 2>&1
#	python3 ${WALLY}/addins/riscv-dv/run.py --test ${test_name} --target rv64gc --output tests/riscvdv  --iterations 1 -si questa --iss spike --verbose --cov --seed 0 --steps iss_sim		>> ${SIM}/questa/fcov_logs/${test_name}.log 2>&1
#	run-elf.bash --seed ${SIM}/questa/seed0.txt --verbose --elf ${WALLY}/tests/riscvdv/asm_test/${test_name}_0.o													>> ${SIM}/questa/fcov_logs/${test_name}.log 2>&1

riscoftests:
# 	Builds riscv-arch-test 64 and 32-bit versions and builds wally-riscv-arch-test 64 and 32-bit versions
	$(MAKE) -C ${TESTS}/riscof

wallyriscoftests:
# 	Builds wally-riscv-arch-test 64 and 32-bit versions
	$(MAKE) -C ${TESTS}/riscof wally-riscv-arch-test

coveragetests:
	$(MAKE) -C ${TESTS}/coverage

deriv:
	derivgen.pl

benchmarks:
	$(MAKE) -C ${WALLY}benchmarks/embench build
	$(MAKE) -C ${WALLY}/benchmarks/embench size
	$(MAKE) -C ${WALLY}/benchmarks/embench modelsim_build_memfile
	$(MAKE) -C ${WALLY}/benchmarks/coremark

clean:
	$(MAKE) clean -C ${TESTS}/riscof
#   $(MAKE) clean -C ${TESTS}/wally-riscv-arch-test
