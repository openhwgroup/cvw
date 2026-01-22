# coremark/Makefile

XLEN       ?= 32
ARCH       ?= rv$(XLEN)i_zicsr
ABI        ?= $(if $(findstring 64,$(XLEN)),lp64,ilp32)

TOOLPREFIX ?= riscv64-unknown-elf-
WALLY      ?= $(WALLY)

LINKER     ?= $(CURDIR)/../sample_processor/config/link.ld

WORK_DIR   ?= $(CURDIR)/work

WALLY_PORT_DIR := $(WALLY)/benchmarks/coremark/riscv64-baremetal
cmbase         := $(WALLY)/addins/coremark

PORT_CFLAGS ?= \
    -g \
    -mabi=$(ABI) \
    -march=$(ARCH) \
    -static \
    -falign-functions=16 \
    -mbranch-cost=1 \
    -DSKIP_DEFAULT_MEMSET \
    -mtune=sifive-3-series \
    -O3 \
    -finline-functions \
    -falign-jumps=4 \
    -fno-delete-null-pointer-checks \
    -fno-rename-registers \
    --param=loop-max-datarefs-for-datadeps=0 \
    -funroll-all-loops \
    --param=uninlined-function-insns=8 \
    -fno-tree-vrp \
    -fwrapv \
    -fipa-pta \
    -nostdlib \
    -nostartfiles \
    -ffreestanding \
    -mstrict-align \
    -DTOTAL_DATA_SIZE=2000 \
    -DMAIN_HAS_NOARGC=1 \
    -DPERFORMANCE_RUN=1 \
    -DITERATIONS=10 \
    -DXLEN=$(XLEN)

cmscript_files := \
  $(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h \
  $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c

cmconfig_files := \
  $(WALLY_PORT_DIR)/core_portme.h $(WALLY_PORT_DIR)/core_portme.c $(WALLY_PORT_DIR)/core_portme.mak \
  $(CURDIR)/crt.S $(WALLY_PORT_DIR)/encoding.h $(WALLY_PORT_DIR)/util.h $(CURDIR)/syscalls.c \
  $(LINKER)

.PHONY: all
all: $(WORK_DIR)/coremark.bare.riscv.elf

$(WORK_DIR)/coremark.bare.riscv.elf: $(cmscript_files) $(cmconfig_files) Makefile
	@mkdir -p $(WORK_DIR)/portdir
	@cp -f $(cmconfig_files) $(WORK_DIR)/portdir
	@$(MAKE) -C $(cmbase) PORT_DIR=$(WORK_DIR)/portdir compile XCFLAGS="$(PORT_CFLAGS)"
	@mkdir -p $(WORK_DIR)
	@mv $(cmbase)/coremark.bare.riscv $(WORK_DIR)/coremark.bare.riscv.elf

.PHONY: clean
clean:
	-@$(MAKE) -C $(cmbase) clean
	rm -rf $(WORK_DIR)
