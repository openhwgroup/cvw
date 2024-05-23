
all: riscoftests memfiles coveragetests deriv 
	# *** Build old tests/imperas-riscv-tests for now;
	# Delete this part when the privileged tests transition over to tests/wally-riscv-arch-test
	# DH: 2/27/22 temporarily commented out imperas-riscv-tests because license expired
	#make -C ../tests/imperas-riscv-tests --jobs
	#make -C ../tests/imperas-riscv-tests XLEN=64 --jobs
	# Only compile Imperas tests if they are installed locally.  
	# They are usually a symlink to $RISCV/imperas-riscv-tests and only 
	# get compiled there manually during installation
	#make -C ../addins/imperas-riscv-tests
	#make -C ../addins/imperas-riscv-tests XLEN=64
	#cd ../addins/imperas-riscv-tests; elf2hex.sh
	#cd ../addins/imperas-riscv-tests; extractFunctionRadix.sh work/*/*/*.elf.objdump
	# Link Linux test vectors 
	#cd ../tests/linux-testgen/linux-testvectors/;./tvLinker.sh

wally-riscv-arch-test: wallyriscoftests memfiles

QuestaCoverage: questa/cov/rv64gc_arch64i.ucdb 
	#iter-elf.bash --cover --search ../tests/coverage
	vcover merge -out questa/cov/cov.ucdb questa/cov/rv64gc_arch64i.ucdb questa/cov/rv64gc*.ucdb -logfile questa/cov/log
#	vcover merge -out questa/cov/cov.ucdb questa/cov/rv64gc_arch64i.ucdb questa/cov/rv64gc*.ucdb questa/cov/buildroot_buildroot.ucdb riscv.ucdb -logfile questa/cov/log
	vcover report -details questa/cov/cov.ucdb > questa/cov/rv64gc_coverage_details.rpt
	vcover report questa/cov/cov.ucdb -details -instance=/core/ebu. > questa/cov/rv64gc_coverage_ebu.rpt
	vcover report questa/cov/cov.ucdb -details -instance=/core/priv. > questa/cov/rv64gc_coverage_priv.rpt
	vcover report questa/cov/cov.ucdb -details -instance=/core/ifu. > questa/cov/rv64gc_coverage_ifu.rpt
	vcover report questa/cov/cov.ucdb -details -instance=/core/lsu. > questa/cov/rv64gc_coverage_lsu.rpt
	vcover report questa/cov/cov.ucdb -details -instance=/core/fpu. > questa/cov/rv64gc_coverage_fpu.rpt
	vcover report questa/cov/cov.ucdb -details -instance=/core/ieu. > questa/cov/rv64gc_coverage_ieu.rpt
	vcover report questa/cov/cov.ucdb -below 100 -details -instance=/core/ebu. > questa/cov/rv64gc_uncovered_ebu.rpt
	vcover report questa/cov/cov.ucdb -below 100 -details -instance=/core/priv. > questa/cov/rv64gc_uncovered_priv.rpt
	vcover report questa/cov/cov.ucdb -below 100 -details -instance=/core/ifu. > questa/cov/rv64gc_uncovered_ifu.rpt
	vcover report questa/cov/cov.ucdb -below 100 -details -instance=/core/lsu. > questa/cov/rv64gc_uncovered_lsu.rpt
	vcover report questa/cov/cov.ucdb -below 100 -details -instance=/core/fpu. > questa/cov/rv64gc_uncovered_fpu.rpt
	vcover report questa/cov/cov.ucdb -below 100 -details -instance=/core/ieu. > questa/cov/rv64gc_uncovered_ieu.rpt
	vcover report -hierarchical questa/cov/cov.ucdb > questa/cov/rv64gc_coverage_hierarchical.rpt
	vcover report -below 100 -hierarchical questa/cov/cov.ucdb > questa/cov/rv64gc_uncovered_hierarchical.rpt
#	vcover report -below 100 questa/cov/cov.ucdb > questa/cov/rv64gc_coverage.rpt
#	vcover report -recursive questa/cov/cov.ucdb > questa/cov/rv64gc_recursive.rpt
	vcover report -details -threshH 100 -html questa/cov/cov.ucdb

allclean: clean all

clean:
	make clean -C ../tests/riscof
#   make clean -C ../../tests/wally-riscv-arch-test
#	make allclean -C ../../tests/imperas-riscv-tests

riscoftests: 
# 	Builds riscv-arch-test 64 and 32-bit versions and builds wally-riscv-arch-test 64 and 32-bit versions
	make -C ../tests/riscof/ 

wallyriscoftests: 
# 	Builds riscv-arch-test 64 and 32-bit versions and builds wally-riscv-arch-test 64 and 32-bit versions
	make -C ../tests/riscof/ wally-riscv-arch-test

memfiles:
	make -f makefile-memfile wally-sim-files --jobs

coveragetests:
	make -C ../tests/coverage/ --jobs

deriv:
	derivgen.pl

benchmarks:
	$(MAKE) -C ../benchmarks/embench build
	$(MAKE) -C ../benchmarks/embench size
	$(MAKE) -C ../benchmarks/embench modelsim_build_memfile
	$(MAKE) -C ../benchmarks/coremark 

