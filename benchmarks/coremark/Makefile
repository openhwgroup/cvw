#cmbase=../../addins/coremark
PORT_DIR = $(CURDIR)/riscv64-baremetal
cmbase=../../addins/coremark
work_dir=$(cmbase)/work
sources=$(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h  \
        $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c \
		$(PORT_DIR)/core_portme.h $(PORT_DIR)/core_portme.c $(PORT_DIR)/core_portme.mak \
		$(PORT_DIR)/crt.S $(PORT_DIR)/encoding.h $(PORT_DIR)/util.h $(PORT_DIR)/syscalls.c

$(work_dir)/coremark.bare.riscv.elf.memfile: $(work_dir)/coremark.bare.riscv
	riscv64-unknown-elf-objdump -D $< > $<.elf.objdump
	riscv64-unknown-elf-elf2hex --bit-width 64 --input $< --output $@
	extractFunctionRadix.sh $<.elf.objdump
	(cd ../../pipelined/regression && (vsim -c -do "do wally-pipelined-batch.do rv64gc coremark" > $(work_dir)/coremark.sim.log))
	cd ../../benchmarks/coremark/

$(work_dir)/coremark.bare.riscv: $(sources) Makefile
    # make -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=/opt/riscv/riscv-gnu-toolchain XCFLAGS="-march=rv64imd -mabi=lp64d -mbranch-cost=1 -DSKIP_DEFAULT_MEMSET -mtune=sifive-7-series -Ofast -funroll-all-loops -fno-delete-null-pointer-checks -fno-rename-registers --param=loop-max-datarefs-for-datadeps=0 -funroll-all-loops --param=uninlined-function-insns=8 -fno-tree-vrp -fwrapv -fno-toplevel-reorder --param=max-inline-insns-size=128 -fipa-pta"
    # These flags were used by WD on CoreMark
	make -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=$(RISCV)/riscv-gnu-toolchain XCFLAGS="-march=rv64imd -mabi=lp64d -mbranch-cost=1 -DSKIP_DEFAULT_MEMSET -mtune=sifive-7-series -Ofast -funroll-all-loops -fno-delete-null-pointer-checks -fno-rename-registers --param=loop-max-datarefs-for-datadeps=0 -funroll-all-loops --param=uninlined-function-insns=8 -fno-tree-vrp -fwrapv -fipa-pta " 
    # -fno-toplevel-reorder --param=max-inline-insns-size=128 " # adding this bit caused a compiler error
	mkdir -p $(work_dir)
	mv $(cmbase)/coremark.bare.riscv $(work_dir)


.PHONY: clean

clean:
	rm -f $(work_dir)/*
