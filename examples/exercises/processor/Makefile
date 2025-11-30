# Wally Coremark Makefile
# Daniel Torres & David Harris 28 July 2022
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# ---- Processor / Testbench Configuration ---- #
XLEN ?=32

# Directory containing all processor RTL (will scan for .sv / .svh)
PROCESSOR     ?= $(CURDIR)/sample_processor

# Name of the DUT module
DUT_MODULE ?= riscvsingle  # or whatever your top-level is called

# Path to your testbench file
TESTBENCH_FILE ?= $(CURDIR)/tb/coremark_tb.sv

# Name of the testbench top module/entity
TB_TOP        ?= coremark_tb

# ----    Simulation Settings    ---- #

VSIM        ?= vsim
VSIM_FLAGS  ?= -voptargs=+acc

# Optional DO file to preload waves in GUI mode
WAVES_DO    ?= $(CURDIR)/coremark_waves.do

# ----    Coremark Configuration ---- #

ARCH := rv$(XLEN)im_zicsr_zba_zbb_zbs
#ARCH := rv$(XLEN)gc
#ARCH := rv$(XLEN)imc_zicsr
#ARCH := rv$(XLEN)im_zicsr
#ARCH := rv$(XLEN)i_zicsr

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

PORT_DIR = $(CURDIR)/riscv64-baremetal
cmbase  = $(WALLY)/addins/coremark
work_dir= $(CURDIR)/work

sources=$(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h  \
    $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c \
    $(PORT_DIR)/core_portme.h $(PORT_DIR)/core_portme.c $(PORT_DIR)/core_portme.mak \
    $(PORT_DIR)/crt.S $(PORT_DIR)/encoding.h $(PORT_DIR)/util.h $(PORT_DIR)/syscalls.c

# All RTL sources under PROCESSOR, plus the testbench file
SV_SOURCES_RAW := $(shell find $(PROCESSOR) -type f \( -name "*.sv" -o -name "*.svh" \))
SV_SOURCES     := $(abspath $(SV_SOURCES_RAW) $(TESTBENCH_FILE))

# Path to the generated memfile
MEMFILE_PATH      := $(work_dir)/coremark.bare.riscv.elf.memfile
MEMFILE_PLUSARG   ?= +MEMFILE=$(MEMFILE_PATH)

# ----          Targets            ---- #

# Default target: just build (memfile + compiled RTL)
all: build

# Build = generate memfile + compile RTL + testbench into $(work_dir)/work
build: $(MEMFILE_PATH)
	@mkdir -p $(work_dir)
	@cd $(work_dir) && \
	  echo "[BUILD] Creating/using local 'work' library..." && \
	  (vlib work 2>/dev/null || true) && \
	  echo "[BUILD] Compiling SystemVerilog sources..." && \
	  vlog +define+DUT_MODULE=$(DUT_MODULE) +define+XLEN=$(XLEN) $(SV_SOURCES)

# Run = build first, then simulate
# Use:  make run          -> batch mode
#       make run GUI=1    -> GUI mode with waves
run: build
	@cd $(work_dir) && \
	if [ "$(GUI)" = "1" ]; then \
	  echo "[RUN] Starting vsim in GUI mode..."; \
	  time $(VSIM) $(VSIM_FLAGS) work.$(TB_TOP) \
	    $(MEMFILE_PLUSARG) \
	    -do "if {[file exists $(WAVES_DO)]} {do $(WAVES_DO)}; run -all" \
	    2>&1 | tee coremark.sim.log; \
	else \
	  echo "[RUN] Starting vsim in batch mode..."; \
	  time $(VSIM) -c $(VSIM_FLAGS) work.$(TB_TOP) \
	    $(MEMFILE_PLUSARG) \
	    -do "run -all; quit -f" \
	    2>&1 | tee coremark.sim.log; \
	fi

# ----  Coremark binary + memfile  ---- #

$(MEMFILE_PATH): $(work_dir)/coremark.bare.riscv
	riscv64-unknown-elf-objdump -D $< > $<.elf.objdump
	riscv64-unknown-elf-elf2hex --bit-width $(XLEN) --input $< --output $@
	extractFunctionRadix.sh $<.elf.objdump

$(work_dir)/coremark.bare.riscv: $(sources) Makefile
	$(MAKE) -C $(cmbase) PORT_DIR=$(PORT_DIR) compile RISCV=$(RISCV) XCFLAGS="$(PORT_CFLAGS)"
	mkdir -p $(work_dir)
	mv $(cmbase)/coremark.bare.riscv $(work_dir)

# ----            Clean             ---- #

.PHONY: clean

clean:
	$(MAKE) -C $(cmbase) clean
	rm -rf $(work_dir)
