#cmbase=../../addins/coremark
PORT_DIR = $(CURDIR)/riscv64-baremetal
cmbase=coremark
sources=$(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h  \
        $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c \
		$(PORT_DIR)/core_portme.h $(PORT_DIR)/core_portme.c $(PORT_DIR)/core_portme.mak \
		$(PORT_DIR)/crt.S $(PORT_DIR)/encoding.h $(PORT_DIR)/util.h $(PORT_DIR)/syscalls.c

work/coremark.bare.riscv.memfile: work/coremark.bare.riscv.objdump
	exe2memfile.pl work/coremark.bare.riscv

work/coremark.bare.riscv.objdump: work/coremark.bare.riscv
	riscv64-unknown-elf-objdump -D work/coremark.bare.riscv > work/coremark.bare.riscv.objdump 

work/coremark.bare.riscv: $(sources)
#	make -C $(cmbase) PORT_DIR=/home/harris/riscv-wally/benchmarks/riscv-coremark/riscv64-baremetal compile RISCV=/courses/e190ax/riscvcompiler XCFLAGS="-march=rv64g"
	make -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=/courses/e190ax/riscvcompiler XCFLAGS="-march=rv64im"
	mv $(cmbase)/coremark.bare.riscv work

.PHONY: clean

clean:
	rm -f work/*