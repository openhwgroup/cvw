coremark.bare.riscv.memfile: coremark.bare.riscv.objdump
	exe2memfile.pl coremark.bare.riscv

coremark.bare.riscv.objdump: coremark.bare.riscv
	riscv64-unknown-elf-objdump -D coremark.bare.riscv > coremark.bare.riscv.objdump 

coremark.bare.riscv:
	make -C coremark PORT_DIR=/home/harris/riscv-wally/benchmarks/riscv-coremark/riscv64-baremetal compile RISCV=/courses/e190ax/riscvcompiler XCFLAGS="-march=rv64im"
	mv coremark/coremark.bare.riscv .

.PHONY: clean

clean:
	rm -f coremark.bare.riscv*