make allclean:
	make clean
	make all

make clean:
	make clean -C ../../addins/riscv-arch-test
	make clean -C ../../tests/wally-riscv-arch-test

make all:
	# Build riscv-arch-test 64 and 32-bit versions
	make -C ../../addins/riscv-arch-test
	make -C ../../addins/riscv-arch-test XLEN=32
	cd ../../addins/riscv-arch-test; elf2hex.sh
	# extractFunctionRadix. ***

	# Build wally-riscv-arch-test
	make -C ../../tests/wally-riscv-arch-test/
	make -C ../../tests/wally-riscv-arch-test/ XLEN=32 
	cd ../../tests/wally-riscv-arch-test; elf2hex.sh
	# ***extractFunctionRadix

	# Only compile Imperas tests if they are installed locally.  
	# They are usually a symlink to $RISCV/imperas-riscv-tests and only 
	# get compiled there manually during installation
	# make -C ../../addins/imperas-riscv-tests
	# make -C ../../addins/imperas-riscv-tests XLEN=64
	# cd ../../addins/imperas-riscv-tests; elf2hex.sh
	
	# Link Linux test vectors (fix this later***)
	#cd ../../tests/linux-testgen/linux-testvectors/;./tvLinker.sh

	