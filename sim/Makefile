
all: riscoftests memfiles coveragetests
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

coverage:
	#make -C ../tests/coverage --jobs
	#iter-elf.bash --cover --search ../tests/coverage
	vcover merge -out cov/cov.ucdb cov/rv64gc_arch64i.ucdb cov/rv64gc*.ucdb -logfile cov/log
#	vcover merge -out cov/cov.ucdb cov/rv64gc_arch64i.ucdb cov/rv64gc*.ucdb cov/buildroot_buildroot.ucdb riscv.ucdb -logfile cov/log
	vcover report -details cov/cov.ucdb > cov/rv64gc_coverage_details.rpt
	vcover report cov/cov.ucdb -details -instance=/core/ebu. > cov/rv64gc_coverage_ebu.rpt
	vcover report cov/cov.ucdb -details -instance=/core/priv. > cov/rv64gc_coverage_priv.rpt
	vcover report cov/cov.ucdb -details -instance=/core/ifu. > cov/rv64gc_coverage_ifu.rpt
	vcover report cov/cov.ucdb -details -instance=/core/lsu. > cov/rv64gc_coverage_lsu.rpt
	vcover report cov/cov.ucdb -details -instance=/core/fpu. > cov/rv64gc_coverage_fpu.rpt
	vcover report cov/cov.ucdb -details -instance=/core/ieu. > cov/rv64gc_coverage_ieu.rpt
	vcover report cov/cov.ucdb -below 100 -details -instance=/core/ebu. > cov/rv64gc_uncovered_ebu.rpt
	vcover report cov/cov.ucdb -below 100 -details -instance=/core/priv. > cov/rv64gc_uncovered_priv.rpt
	vcover report cov/cov.ucdb -below 100 -details -instance=/core/ifu. > cov/rv64gc_uncovered_ifu.rpt
	vcover report cov/cov.ucdb -below 100 -details -instance=/core/lsu. > cov/rv64gc_uncovered_lsu.rpt
	vcover report cov/cov.ucdb -below 100 -details -instance=/core/fpu. > cov/rv64gc_uncovered_fpu.rpt
	vcover report cov/cov.ucdb -below 100 -details -instance=/core/ieu. > cov/rv64gc_uncovered_ieu.rpt
	vcover report -hierarchical cov/cov.ucdb > cov/rv64gc_coverage_hierarchical.rpt
	vcover report -below 100 -hierarchical cov/cov.ucdb > cov/rv64gc_uncovered_hierarchical.rpt
#	vcover report -below 100 cov/cov.ucdb > cov/rv64gc_coverage.rpt
#	vcover report -recursive cov/cov.ucdb > cov/rv64gc_recursive.rpt
	vcover report -details -threshH 100 -html cov/cov.ucdb

allclean: clean all

clean:
	make clean -C ../tests/riscof
#   make clean -C ../../tests/wally-riscv-arch-test
#	make allclean -C ../../tests/imperas-riscv-tests

riscoftests: 
# 	Builds riscv-arch-test 64 and 32-bit versions and builds wally-riscv-arch-test 64 and 32-bit versions
	make -C ../tests/riscof/ 
	
memfiles:
	make -f makefile-memfile wally-sim-files --jobs

coveragetests:
	make -C ../tests/coverage/
