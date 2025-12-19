# Wally Coremark Makefile
# Daniel Torres & David Harris 28 July 2022
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# ---- Command line optional parameters ---- #

ELFS ?=

# ---- Processor / Testbench Configuration ---- #
XLEN ?=32
PROCESSOR     ?= $(CURDIR)/my_processor/RISC-V-Pipelined-Processor/src      # Directory containing all processor RTL (will scan for .sv / .svh)
INC_DIR       ?= $(CURDIR)/my_processor/RISC-V-Pipelined-Processor/incdir/  # Optional directory for include files for RTL compilation (parameters)

#DUT_MODULE ?= riscvsingle  # top-level module name
DUT_MODULE ?= testingCore

TEST_DIR        ?= $(CURDIR)/tests/sample_processor

TEST_WORK_DIR	?= $(TEST_DIR)/work
ARCH_WORK_DIR 	?= $(TEST_WORK_DIR)/arch_test
CM_WORK_DIR		?= $(TEST_WORK_DIR)/coremark

# ---- Repo paths ---- #
TESTBENCH_FILES ?= $(CURDIR)/tb/testbench.sv $(CURDIR)/tb/VectorStorage.sv
TB_TOP          ?= testbench
WAVES_DO        ?= $(CURDIR)/waves.do

WORK_DIR        ?= $(CURDIR)/work
RISCV_ARCH_TEST ?= $(WALLY)/addins/riscv-arch-test-cvw

# ----    Simulation Settings    ---- #
VSIM        ?= vsim
VSIM_FLAGS  ?= -voptargs=+acc
VSIM_EXTRA_FLAGS ?= # Extra flags if you want them

GUI ?= 0

# Build the vsim mode flags from GUI
ifeq ($(GUI),1)
  VSIM_MODE_FLAGS :=
  VSIM_DO := if {[file exists $(WAVES_DO)]} {do $(WAVES_DO)}; run -all
else
  VSIM_MODE_FLAGS := -c
  VSIM_DO := run -all; quit -f
endif

# ----    Coremark Configuration ---- #

#ARCH := rv$(XLEN)im_zicsr_zba_zbb_zbs
#ARCH := rv$(XLEN)gc
#ARCH := rv$(XLEN)imc_zicsr
#ARCH := rv$(XLEN)im_zicsr
ARCH := rv$(XLEN)i_zicsr

ABI := $(if $(findstring "64","$(XLEN)"),lp64,ilp32)

PORT_CFLAGS = \
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

# ----    Files and Directories    ---- #

SV_SOURCES := $(shell find $(PROCESSOR) -type f \( -name "*.sv" -o -name "*.svh" \))
TEST_ELFS  := $(sort $(shell find $(TEST_DIR) -type f -name '*.elf'))

PORT_DIR = $(WALLY)/benchmarks/coremark/riscv64-baremetal
cmbase  = $(WALLY)/addins/coremark

cmsources=$(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h  \
    $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c \
    $(PORT_DIR)/core_portme.h $(PORT_DIR)/core_portme.c $(PORT_DIR)/core_portme.mak \
    $(PORT_DIR)/crt.S $(PORT_DIR)/encoding.h $(PORT_DIR)/util.h $(PORT_DIR)/syscalls.c

# ----          Targets            ---- #

# Default target: just build (compile RTL/testbench once)
all: build

# Build = compile RTL once into $(WORK_DIR)/build
.PHONY: build
$(WORK_DIR)/work/_info: $(SV_SOURCES) $(TESTBENCH_FILES) Makefile
	@mkdir -p $(WORK_DIR)
	@cd $(WORK_DIR) && \
	  echo "[BUILD] Creating/using local 'work' library..." && \
	  (vlib work 2>/dev/null || true) && \
	  echo "[BUILD] Compiling SystemVerilog sources..." && \
	  vlog \
	  	+incdir+$(INC_DIR) \
		+define+DUT_MODULE=$(DUT_MODULE) \
      	+define+XLEN=$(XLEN) $(abspath $(SV_SOURCES) $(TESTBENCH_FILES))

build: $(WORK_DIR)/work/_info Makefile

# ----  Generic memfile / run / test flow  ---- #

# Any file -> file.memfile
%.elf.memfile: %.elf
	@echo "[MEM] Generating memfile $@ from $<"
	riscv64-unknown-elf-elf2hex --bit-width 32 --input $< --output $@

#   Use: make run ELFS="path/to/a.elf path/to/b.elf" [-j]
.PHONY: run
run: $(ELFS:%=%.run)

# Generate score for the project based on coremark score and timing
# .PHONY
# score:


# foo.elf.run depends on foo.elf.memfile and build
%.run: %.memfile | build
	@set -e; \
	mkdir -p $(WORK_DIR)/runs; \
	MEMFILE="$(abspath $<)"; \
	ELF="$${MEMFILE%.memfile}"; \
	NAME="$${ELF##*/}"; \
	LOGFILE="${WORK_DIR}/runs/$${NAME}.sim.log"; \
	echo "[RUN] ELF: $$ELF"; \
	echo "[VSIM] Using memfile $$MEMFILE (log: $$LOGFILE)"; \
	cd "$(WORK_DIR)"; \
	if [ "$(GUI)" = "1" ]; then \
	  $(VSIM) $(VSIM_FLAGS) $(VSIM_EXTRA_FLAGS) work.$(TB_TOP) \
	    +MEMFILE="$$MEMFILE" \
	    -do "$(VSIM_DO)" \
	    2>&1 | tee "$$LOGFILE"; \
	else \
	  $(VSIM) $(VSIM_MODE_FLAGS) $(VSIM_FLAGS) $(VSIM_EXTRA_FLAGS) work.$(TB_TOP) \
	    +MEMFILE="$$MEMFILE" \
	    -do "$(VSIM_DO)" \
	    > "$$LOGFILE" 2>&1; \
	fi


# test: run ALL .elf files in TEST_DIR in parallel with -j
.PHONY: test
test:
	$(MAKE) run ELFS="$(TEST_ELFS)"

# Keep the old riscv-arch-test flow
.PHONY: arch-test
arch-test:
	uv run --with $(WALLY)/addins/riscv-arch-test-cvw/framework make -C \
	$(WALLY)/addins/riscv-arch-test-cvw \
	CONFIG_FILE=$(TEST_DIR)/test_config.yaml \
	WORKDIR=$(ARCH_WORK_DIR)
# 	$(MAKE) -C $(RISCV_ARCH_TEST) \
#    CONFIG_FILE=$(TEST_DIR)/test_config.yaml \
#    WORKDIR=$(TEST_DIR)/work

# ----  Coremark flow  ---- #

.PHONY: coremark

coremark: $(CM_WORK_DIR)/coremark.bare.riscv.run

$(CM_WORK_DIR)/coremark.bare.riscv.memfile: $(CM_WORK_DIR)/coremark.bare.riscv Makefile
	riscv64-unknown-elf-size -A $< > $<.elf.size
	riscv64-unknown-elf-readelf -S $< > $<.elf.read
	riscv64-unknown-elf-objdump -D $< > $<.elf.objdump
	riscv64-unknown-elf-elf2hex --bit-width 32 --input $< --output $@
	extractFunctionRadix.sh $<.elf.objdump

$(CM_WORK_DIR)/coremark.bare.riscv: $(cmsources) Makefile
	$(MAKE) -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=$(RISCV) XCFLAGS="$(PORT_CFLAGS)"
	mkdir -p $(CM_WORK_DIR)
	mv $(cmbase)/coremark.bare.riscv $(CM_WORK_DIR)

# ----            Clean             ---- #

.PHONY: clean

clean:
	$(MAKE) -C $(cmbase) clean
	$(MAKE) -C $(RISCV_ARCH_TEST) clean
	rm -rf $(TEST_WORK_DIR)
	rm -rf $(ARCH_WORK_DIR)
	rm -rf $(WORK_DIR)
	rm -rf $(CM_WORK_DIR)
