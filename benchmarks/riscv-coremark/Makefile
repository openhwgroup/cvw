work/coremark.bare.riscv.memfile: work/coremark.bare.riscv.objdump
	exe2memfile.pl work/coremark.bare.riscv

work/coremark.bare.riscv.objdump: work/coremark.bare.riscv
	riscv64-unknown-elf-objdump -D work/coremark.bare.riscv > work/coremark.bare.riscv.objdump 

work/coremark.bare.riscv:
	make -C coremark PORT_DIR=/home/harris/riscv-wally/benchmarks/riscv-coremark/riscv64-baremetal compile RISCV=/courses/e190ax/riscvcompiler XCFLAGS="-march=rv64im"
	mv coremark/coremark.bare.riscv work
	#make -C ../../addins/coremark PORT_DIR=/home/harris/riscv-wally/benchmarks/riscv-coremark/riscv64-baremetal compile RISCV=/courses/e190ax/riscvcompiler XCFLAGS="-march=rv64im"
	#mv ../../addins/coremark/coremark.bare.riscv work

.PHONY: clean

clean:
	rm -f work/*