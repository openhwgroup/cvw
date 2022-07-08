PORT_DIR = $(CURDIR)/riscv64-baremetal
cmbase=../../addins/coremark
# cmbase= ../riscv-coremark/coremark
work_dir= ../../benchmarks/coremark/work
XLEN ?=64
sources=$(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h  \
        $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c \
		$(PORT_DIR)/core_portme.h $(PORT_DIR)/core_portme.c $(PORT_DIR)/core_portme.mak \
		$(PORT_DIR)/crt.S $(PORT_DIR)/encoding.h $(PORT_DIR)/util.h $(PORT_DIR)/syscalls.c
ABI = lp64
#$(if $(findstring 64, $(XLEN)), lp64, ilp32)
PORT_CFLAGS = -g -march=$(XLEN)im -mabi=$(ABI) -static -mcmodel=medlow -mtune=sifive-3-series \
  -O3 -falign-functions=16 -funroll-all-loops \
	-finline-functions -falign-jumps=4 \
  -nostdlib -nostartfiles -ffreestanding -mstrict-align \
	-DTOTAL_DATA_SIZE=2000 -DMAIN_HAS_NOARGC=1 \
	-DPERFORMANCE_RUN=1


$(work_dir)/coremark.bare.riscv.elf.memfile: $(work_dir)/coremark.bare.riscv
	riscv64-unknown-elf-objdump -D $< > $<.elf.objdump
	riscv64-unknown-elf-elf2hex --bit-width $(XLEN) --input $< --output $@
	extractFunctionRadix.sh $<.elf.objdump
	(cd ../../pipelined/regression && (vsim -c -do "do wally-pipelined-batch.do rv$(XLEN)gc coremark" 2>&1 | tee $(work_dir)/coremark.sim.log))
	cd ../../benchmarks/coremark/

$(work_dir)/coremark.bare.riscv: $(sources) Makefile
    # make -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=/opt/riscv/riscv-gnu-toolchain XCFLAGS="-march=rv64imd -mabi=lp64d -mbranch-cost=1 -DSKIP_DEFAULT_MEMSET -mtune=sifive-7-series -Ofast -funroll-all-loops -fno-delete-null-pointer-checks -fno-rename-registers --param=loop-max-datarefs-for-datadeps=0 -funroll-all-loops --param=uninlined-function-insns=8 -fno-tree-vrp -fwrapv -fno-toplevel-reorder --param=max-inline-insns-size=128 -fipa-pta"
    # These flags were used by WD on CoreMark
    # make -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=$(RISCV)/riscv-gnu-toolchain XCFLAGS="-march=rv64imd -mabi=lp64d -mbranch-cost=1 -DSKIP_DEFAULT_MEMSET -mtune=sifive-7-series -Ofast -funroll-all-loops -fno-delete-null-pointer-checks -fno-rename-registers --param=loop-max-datarefs-for-datadeps=0 -funroll-all-loops --param=uninlined-function-insns=8 -fno-tree-vrp -fwrapv -fipa-pta " 
	make -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=$(RISCV)/riscv-gnu-toolchain XCFLAGS="-march=rv$(XLEN)im -mabi=$(ABI) -mbranch-cost=1 -DSKIP_DEFAULT_MEMSET -mtune=sifive-7-series -Ofast -funroll-all-loops -fno-delete-null-pointer-checks -fno-rename-registers --param=loop-max-datarefs-for-datadeps=0 -funroll-all-loops --param=uninlined-function-insns=8 -fno-tree-vrp -fwrapv -fipa-pta " 
    # -fno-toplevel-reorder --param=max-inline-insns-size=128 " # adding this bit caused a compiler error
	mkdir -p $(work_dir)
	mv $(cmbase)/coremark.bare.riscv $(work_dir)


.PHONY: clean

clean:
	rm -f $(work_dir)/*
