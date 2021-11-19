coremark.bare.riscv.memfile: coremark.bare.riscv.objdump
	exe2memfile.pl coremark.bare.riscv

coremark.bare.riscv.objdump: coremark.bare.riscv
	riscv64-unknown-elf-objdump -D coremark.bare.riscv > coremark.bare.riscv.objdump 

coremark.bare.riscv:
	BASEDIR=${CUR_DIR}
	RISCV=/courses/e190ax/riscvcompiler
	CMPATH=coremark
	#pushd ../../addins/coremark
	# run the compile
	echo "Start compilation"

	make -C ${CMPATH} PORT_DIR=${BASEDIR}/riscv64-baremetal compile RISCV=/courses/e190ax/riscvcompiler XCFLAGS=-march=rv64im
	mv ${CMPATH}/coremark.bare.riscv .

.PHONY: clean

clean:
	rm coremark.bare.riscv*