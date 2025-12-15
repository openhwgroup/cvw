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
DUT_MODULE ?= CoremarkCore

TEST_DIR        ?= $(CURDIR)/tests/sample_processor

# ---- Repo paths ---- #
TESTBENCH_FILE  ?= $(CURDIR)/tb/coremark_tb.sv
TB_TOP          ?= coremark_tb
WAVES_DO        ?= $(CURDIR)/coremark_waves.do

WORK_DIR        ?= $(CURDIR)/work
RISCV_ARCH_TEST ?= $(WALLY)/addins/riscv-arch-test-cvw

# ----    Simulation Settings    ---- #
VSIM        ?= vsim
VSIM_FLAGS  ?= -voptargs=+acc
VSIM_EXTRA_FLAGS ?= # Extra flags if you want them

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

SV_SOURCES  := $(shell find $(PROCESSOR) -type f \( -name "*.sv" -o -name "*.svh" \)) # All RTL sources under PROCESSOR, plus the testbench file
TEST_ELFS := $(sort $(shell find $(TEST_DIR) -type f -name '*.elf'))

PORT_DIR = $(CURDIR)/riscv64-baremetal
cmbase  = $(WALLY)/addins/coremark

sources=$(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h  \
    $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c \
    $(PORT_DIR)/core_portme.h $(PORT_DIR)/core_portme.c $(PORT_DIR)/core_portme.mak \
    $(PORT_DIR)/crt.S $(PORT_DIR)/encoding.h $(PORT_DIR)/util.h $(PORT_DIR)/syscalls.c

# Coremark memfile (optional artifact)
MEMFILE_PATH      := $(WORK_DIR)/coremark.bare.riscv.memfile

# ----          Targets            ---- #

# Default target: just build (compile RTL/testbench once)
all: build

# Build = compile RTL once into $(WORK_DIR)/work
.PHONY: build
build: Makefile
	@mkdir -p $(WORK_DIR)
	@cd $(WORK_DIR) && \
	  echo "[BUILD] Creating/using local 'work' library..." && \
	  (vlib work 2>/dev/null || true) && \
	  echo "[BUILD] Compiling SystemVerilog sources..." && \
	  vlog +incdir+$(INC_DIR) +define+DUT_MODULE=$(DUT_MODULE) \
      +define+XLEN=$(XLEN) $(abspath $(SV_SOURCES) $(TESTBENCH_FILE))

# ----  Generic memfile / run / test flow  ---- #

# Any file -> file.memfile
%.memfile: %
	@echo "[MEM] Generating memfile $@ from $<"
	riscv64-unknown-elf-elf2hex --bit-width 8 --input $< --output $@

# run:
#   Use: make run ELFS="path/to/a.elf path/to/b.elf" [-j]
.PHONY: run
run: $(ELFS:%=%.run)

# foo.elf.run depends on foo.elf.memfile and build
%.run: %.memfile | build
	@set -e; \
	MEMFILE="$(abspath $<)"; \
	ELF="$${MEMFILE%.memfile}"; \
	NAME="$${ELF##*/}"; \
	LOGFILE="$(WORK_DIR)/$${NAME}.sim.log"; \
	echo "[RUN] ELF: $$ELF"; \
	echo "[VSIM] Using memfile $$MEMFILE (log: $$LOGFILE)"; \
	cd "$(WORK_DIR)"; \
	if [ "$(GUI)" = "1" ]; then \
	  $(VSIM) $(VSIM_FLAGS) $(VSIM_EXTRA_FLAGS) work.$(TB_TOP) \
	    +MEMFILE="$$MEMFILE" \
	    -do "if {[file exists $(WAVES_DO)]} {do $(WAVES_DO)}; run -all" \
	    2>&1 | tee "$$LOGFILE"; \
	else \
	  $(VSIM) -c $(VSIM_FLAGS) $(VSIM_EXTRA_FLAGS) work.$(TB_TOP) \
	    +MEMFILE="$$MEMFILE" \
	    -do "run -all; quit -f" \
	    2>&1 | tee "$$LOGFILE"; \
	fi

# test: run ALL .elf files in TEST_DIR in parallel with -j
.PHONY: test
test:
	$(MAKE) run ELFS="$(TEST_ELFS)"

# Keep the old riscv-arch-test flow
.PHONY: arch-test
arch-test:
	$(MAKE) -C $(RISCV_ARCH_TEST) \
   CONFIG_FILE=$(TEST_DIR)/test_config.yaml \
   WORKDIR=$(TEST_DIR)/work

# ----  Coremark flow  ---- #

.PHONY: coremark

coremark: $(WORK_DIR)/coremark.bare.riscv
	$(MAKE) run ELFS="$<"

$(MEMFILE_PATH): $(WORK_DIR)/coremark.bare.riscv Makefile
	riscv64-unknown-elf-objdump -D $< > $<.elf.objdump
	riscv64-unknown-elf-elf2hex --bit-width 8 --input $< --output $@
	extractFunctionRadix.sh $<.elf.objdump

$(WORK_DIR)/coremark.bare.riscv: $(sources) Makefile
	$(MAKE) -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=$(RISCV) XCFLAGS="$(PORT_CFLAGS)"
	mkdir -p $(WORK_DIR)
	mv $(cmbase)/coremark.bare.riscv $(WORK_DIR)

# ----            Clean             ---- #

.PHONY: clean

clean:
	$(MAKE) -C $(cmbase) clean
	rm -rf $(WORK_DIR)
