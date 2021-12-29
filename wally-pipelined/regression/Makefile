make all:
	# Build riscv-arch-test 64 and 32-bit versions
	make -C ../../addins/riscv-arch-test
	make -C ../../addins/riscv-arch-test XLEN=32
	exe2memfile.pl ../../addins/riscv-arch-test/work/*/*/*.elf

	# Build wally-riscv-arch-test
	make -C ../../tests/wally-riscv-arch-test/
	make -C ../../tests/wally-riscv-arch-test/ XLEN=32 
	exe2memfile.pl ../../tests/wally-riscv-arch-test/work/*/*/*.elf

	# Link Linux test vectors (fix this later***)
	#cd ../../tests/linux-testgen/linux-testvectors/;./tvLinker.sh
