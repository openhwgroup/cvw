make allclean:
	make clean
	make all

make clean:
	make clean -C ../../tests/riscof
	make clean -C ../../tests/wally-riscv-arch-test
#	make allclean -C ../../tests/imperas-riscv-tests

make all:
	make archtests
	make wallytests
	make memfiles
	# *** Build old tests/imperas-riscv-tests for now;
	# Delete this part when the privileged tests transition over to tests/wally-riscv-arch-test
	# DH: 2/27/22 temporarily commented out imperas-riscv-tests because license expired
	#make -C ../../tests/imperas-riscv-tests --jobs
	#make -C ../../tests/imperas-riscv-tests XLEN=64 --jobs



	# Only compile Imperas tests if they are installed locally.  
	# They are usually a symlink to $RISCV/imperas-riscv-tests and only 
	# get compiled there manually during installation
	#make -C ../../addins/imperas-riscv-tests
	#make -C ../../addins/imperas-riscv-tests XLEN=64
	#cd ../../addins/imperas-riscv-tests; elf2hex.sh
	#cd ../../addins/imperas-riscv-tests; extractFunctionRadix.sh work/*/*/*.elf.objdump

	# Link Linux test vectors (fix this later***)
	#cd ../../tests/linux-testgen/linux-testvectors/;./tvLinker.sh

make archtests:
	# Build riscv-arch-test 64 and 32-bit versions
	make -C ../../tests/riscof/ --jobs
	make -C ../../tests/riscof/ XLEN=32 --jobs

make wallytests:
	# Build wally-riscv-arch-test
	make -C ../../tests/wally-riscv-arch-test/ --jobs
	make -C ../../tests/wally-riscv-arch-test/ XLEN=32  --jobs

make memfiles:
	make -f makefile-memfile wally-sim-files --jobs
