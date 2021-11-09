make all:
	make ../../tests/imperas-riscv-tests/
	make ../../tests/wally-riscv-arch-test/
	make XLEN=32 ../../tests/wally-riscv-arch-test/
	exe2memfile.pl ../../tests/wally-riscv-arch-test/work/*/*/*.elf
	cd ../../tests/linux-testgen/linux-testvectors/;./tvLinker.sh
