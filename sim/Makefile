all: riscoftests memfiles
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
