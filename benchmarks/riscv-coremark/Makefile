#cmbase=../../addins/coremark
PORT_DIR = $(CURDIR)/riscv64-baremetal
cmbase=coremark
sources=$(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h  \
        $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c \
		$(PORT_DIR)/core_portme.h $(PORT_DIR)/core_portme.c $(PORT_DIR)/core_portme.mak \
		$(PORT_DIR)/crt.S $(PORT_DIR)/encoding.h $(PORT_DIR)/util.h $(PORT_DIR)/syscalls.c

work/coremark.bare.riscv.memfile: work/coremark.bare.riscv
	riscv64-unknown-elf-elf2hex --bit-width 64 --input $< --output $@

work/coremark.bare.riscv.objdump: work/coremark.bare.riscv
	riscv64-unknown-elf-objdump -D work/coremark.bare.riscv > work/coremark.bare.riscv.objdump 

work/coremark.bare.riscv: $(sources) Makefile
#	make -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=/opt/riscv/riscv-gnu-toolchain XCFLAGS="-march=rv64imd -mabi=lp64d -mbranch-cost=1 -DSKIP_DEFAULT_MEMSET -mtune=sifive-7-series -Ofast -funroll-all-loops -fno-delete-null-pointer-checks -fno-rename-registers --param=loop-max-datarefs-for-datadeps=0 -funroll-all-loops --param=uninlined-function-insns=8 -fno-tree-vrp -fwrapv -fno-toplevel-reorder --param=max-inline-insns-size=128 -fipa-pta"
 # These flags were used by WD on CoreMark
	make -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=$(RISCV)/riscv-gnu-toolchain XCFLAGS="-march=rv64imd -mabi=lp64d -mbranch-cost=1 -DSKIP_DEFAULT_MEMSET -mtune=sifive-7-series -Ofast -funroll-all-loops -fno-delete-null-pointer-checks -fno-rename-registers --param=loop-max-datarefs-for-datadeps=0 -funroll-all-loops --param=uninlined-function-insns=8 -fno-tree-vrp -fwrapv -fipa-pta " 
# -fno-toplevel-reorder --param=max-inline-insns-size=128 " # adding this bit caused a compiler error
	mkdir -p work/
	mv $(cmbase)/coremark.bare.riscv work/

.PHONY: clean

clean:
	rm -f work/*
