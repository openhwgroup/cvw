# Wally Coremark Makefile
# James Kaden Cassidy 1/1/2026
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# ---- Processor / Testbench Configuration ---- #
XLEN 			?= 32
PROCESSOR     	?= $(CURDIR)/sample_processor/src      # Directory containing all processor RTL (will scan for .sv / .svh)

SYNTH_SRC 		?= $(PROCESSOR) 					   # Directory used to copy hdl for synthesis
INC_DIR       	?= $(CURDIR)/sample_processor/incdir/  # Optional directory for include files for RTL compilation (parameters)

DUT_MODULE 			?= riscvsingle # top-level module name
SYNTH_TOP 			?= $(DUT_MODULE) # useful for analyzing timing of specific modules (pipelining)
PROCESSOR_TEST_DIR	?= $(CURDIR)/tests/act4_sample_processor

# ----    Coremark Configuration ---- #

#ARCH := rv$(XLEN)im_zicsr_zba_zbb_zbs
#ARCH := rv$(XLEN)gc
#ARCH := rv$(XLEN)imc_zicsr
#ARCH := rv$(XLEN)im_zicsr
ARCH := rv$(XLEN)i_zicsr

# ---- Command line optional parameters ---- #

ELFS 				?=
GUI  				?= 0
SAIL  				?= 0
VSIM_EXTRA_FLAGS 	?= # Extra flags if you want them

# ---- Repo paths ---- #
LINKER			?= $(PROCESSOR_TEST_DIR)/link.ld

TB_TOP          ?= testbench
TESTBENCH_FILES ?= $(TESTBENCH_DIR)/testbench.sv $(TESTBENCH_DIR)/VectorStorage.sv
WAVES_DO        ?= $(CURDIR)/waves.do

# ---- Repo paths cont ---- #
COREMARK_DIR 	?= $(CURDIR)/coremark
C_TEST_DIR		?= $(CURDIR)/tests/C
TESTBENCH_DIR 	?= $(CURDIR)/tb
SYNTH_DIR 		?= $(CURDIR)/synth

WORK_DIR        ?= $(CURDIR)/work
RISCV_ARCH_TEST ?= $(WALLY)/addins/riscv-arch-test-cvw

TEST_WORK_DIR	?= $(PROCESSOR_TEST_DIR)/work
ARCH_WORK_DIR 	?= $(TEST_WORK_DIR)/arch_test
C_TEST_WORK_DIR ?= $(C_TEST_DIR)/work
CM_WORK_DIR		?= $(COREMARK_DIR)/work

# ----    Simulation Settings    ---- #
VSIM        		?= vsim
VSIM_FLAGS  		?= -voptargs=+acc

SYNTH_TECH 			?= sky130 #tsmc28 #tsmc28psyn

# ----    Tools    ---- #

PYTHON 		:= python3
SAIL_RUN   	:= sail_riscv_sim
TOOLPREFIX 	:= riscv64-unknown-elf-

# Derive tools from the prefix
CC      := $(TOOLPREFIX)gcc
OBJDUMP := $(TOOLPREFIX)objdump
READELF := $(TOOLPREFIX)readelf
SIZE    := $(TOOLPREFIX)size
ELF2HEX := $(TOOLPREFIX)elf2hex

# ----    Coremark Parameters ---- #

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

SV_PACKAGES := $(sort $(shell find $(PROCESSOR) -type f -name '*.pkg'))
SV_SOURCES 	:= $(sort $(shell find $(PROCESSOR) -type f \( -name "*.sv" -o -name "*.svh" \)) $(shell find $(INC_DIR) -type f \( -name "*.sv" -o -name "*.svh" \)))
TEST_ELFS  	= $(sort $(shell find -L $(PROCESSOR_TEST_DIR) -type f -name '*.elf'))

# ----          Targets            ---- #

# Default target: just build (compile RTL/testbench once)
all: build

.PHONY: lint
lint:
	@verilator --lint-only --quiet \
		--top-module $(DUT_MODULE) \
		-DDUT_MODULE=$(DUT_MODULE) \
		-I$(abspath $(INC_DIR)) \
		$(abspath $(SV_PACKAGES) $(SV_SOURCES) $(TESTBENCH_FILES)) \
		-Wall -Wno-UNUSEDSIGNAL -Wno-VARHIDDEN -Wno-GENUNNAMED -Wno-PINCONNECTEMPTY -Wno-DECLFILENAME -Wno-TIMESCALEMOD -Wno-CASEX


# Build = compile RTL once into $(WORK_DIR)/build
.PHONY: build
$(WORK_DIR)/_info: $(SV_PACKAGES) $(SV_SOURCES) $(TESTBENCH_FILES) Makefile
	echo "[BUILD] Creating/using local 'work' library..." && \
	(vlib work 2>/dev/null || true) && \
	echo "[BUILD] Compiling SystemVerilog sources..." && \
	vlog -sv \
		+incdir+$(INC_DIR) \
		+define+DUT_MODULE=$(DUT_MODULE) \
		+define+XLEN=$(XLEN) $(abspath $(SV_PACKAGES) $(SV_SOURCES) $(TESTBENCH_FILES))

build: $(WORK_DIR)/_info Makefile

# ----  Generic memfile / run / test flow  ---- #

# Any file -> file.memfile
.PRECIOUS: %.memfile
%.memfile: %.elf
	@echo "[MEM] Generating memfile $@ from $< along with debug files"
	$(SIZE) -A $< > $<.elf.size
	$(READELF) -S $< > $<.elf.read
	$(OBJDUMP) -D $< > $<.elf.objdump
	$(ELF2HEX) --bit-width 32 --input $< --output $@
	extractFunctionRadix.sh $<.elf.objdump

#   Use: make run ELFS="path/to/a.elf path/to/b.elf" [-j]
.PHONY: run
run: $(addsuffix .run,$(basename $(ELFS)))

.PHONY: synth
synth:
	@$(MAKE) -C $(WALLY)/synthDC \
		OUTPUTBASEDIR=$(SYNTH_DIR) \
		NAME=lynn \
		DESIGN=$(SYNTH_TOP) \
		INCDIR=$(INC_DIR) \
		CONFIG=- \
		MOD=- \
		HDLDIR=$(PROCESSOR) \
		LYNN=1 \
		TECH=$(SYNTH_TECH) \
		synth

# Generate score for the project based on coremark score and timing
# .PHONY
# score:

ifeq ($(SAIL),1)
RUNNER := sail
else
RUNNER := processor
endif

# foo.elf.run depends on foo.elf.memfile and build
%.run: %.$(RUNNER) Makefile
	@:

%.sail: %.elf Makefile
	$(SAIL_RUN) $< > $@.log 2>&1

# Build the vsim mode flags from GUI
ifeq ($(GUI),1)
  VSIM_MODE_FLAGS :=
  VSIM_DO := if {[file exists $(WAVES_DO)]} {do $(WAVES_DO)}; run -all
else
  VSIM_MODE_FLAGS := -c
  VSIM_DO := run -all; quit -f
endif

%.processor: %.memfile $(WORK_DIR)/_info Makefile
	@set -e; \
	MEMFILE="$(abspath $<)"; \
	ELF="$${MEMFILE%.memfile}.elf"; \
	ENTRY_ADDR="$$(riscv64-unknown-elf-readelf -h "$$ELF" | awk '/Entry point address:/ {print $$NF}')"; \
	TOHOST_ADDR="$$(riscv64-unknown-elf-readelf --syms --wide "$$ELF" | awk '$$NF=="tohost" {print "0x"$$2; exit}')" \
	DMEM_BASE_ADDR="$$(riscv64-unknown-elf-readelf --syms --wide "$$ELF" | awk '$$NF=="dmem_base" {print "0x"$$2; exit}')" \
	NAME="$${ELF##*/}"; \
	LOGFILE="$${ELF}.sim.log"; \
	SIG_BASE_ADDR=""; \
	SIG_END_ADDR=""; \
	echo "[RUN] ELF: $$ELF"; \
	echo "[VSIM] Using memfile $$MEMFILE (log: $$LOGFILE)"; \
	if [ "$(GUI)" = "1" ]; then \
	  $(VSIM) $(VSIM_FLAGS) $(VSIM_EXTRA_FLAGS) work.$(TB_TOP) \
	  	+TESTNAME="$$NAME" \
	    +MEMFILE="$$MEMFILE" \
	    +ENTRY_ADDR="$$ENTRY_ADDR" \
		+TOHOST_ADDR="$$TOHOST_ADDR" \
		+DMEM_BASE_ADDR="$$DMEM_BASE_ADDR" \
	    -do "$(VSIM_DO)" \
	    2>&1 | tee "$$LOGFILE"; \
	else \
	  $(VSIM) $(VSIM_MODE_FLAGS) $(VSIM_FLAGS) $(VSIM_EXTRA_FLAGS) work.$(TB_TOP) \
	  	+TESTNAME="$$NAME" \
	    +MEMFILE="$$MEMFILE" \
	    +ENTRY_ADDR="$$ENTRY_ADDR" \
		+TOHOST_ADDR="$$TOHOST_ADDR" \
		+DMEM_BASE_ADDR="$$DMEM_BASE_ADDR" \
	    -do "$(VSIM_DO)" \
	    > "$$LOGFILE" 2>&1; \
	fi


CFLAGS 				:= -march=$(ARCH) -mabi=$(ABI) -O0 -g -ffreestanding -ffunction-sections -fdata-sections -Wall -Wextra
LDFLAGS 			:= -march=$(ARCH) -mabi=$(ABI) -nostdlib -Wl,--gc-sections -T $(LINKER)

C_TEST_SOURCEFILES 	?= $(sort $(shell find $(C_TEST_DIR) -type f \( -name "*.S" -o -name "*.c" \)))

$(C_TEST_WORK_DIR)/c_test.elf: $(C_TEST_SOURCEFILES) $(LINKER) Makefile
	@mkdir -p $(C_TEST_WORK_DIR)
	$(CC) $(CFLAGS) $(C_TEST_SOURCEFILES) $(LDFLAGS) -o $@;

.PHONY: C_test
C_test: $(C_TEST_WORK_DIR)/c_test.elf
	$(MAKE) run ELFS="$(C_TEST_WORK_DIR)/c_test.elf"

COPY_ACT4_FILES := $(TEST_WORK_DIR)/copy_stamp

$(COPY_ACT4_FILES):
	@mkdir -p $(TEST_WORK_DIR)
	$(MAKE) -C $(RISCV_ARCH_TEST)
	cp -r $(RISCV_ARCH_TEST)/work/common/elfs/rv32i/I/* $(TEST_WORK_DIR)/
	touch $(COPY_ACT4_FILES)


# test: run ALL .elf files in PROCESSOR_TEST_DIR in parallel with -j
.PHONY: test
test: | $(COPY_ACT4_FILES)
	$(info CURDIR=$(CURDIR))
	$(info PROCESSOR_TEST_DIR=$(PROCESSOR_TEST_DIR))
	$(info TEST_ELFS=$(TEST_ELFS))
	$(MAKE) run ELFS="$(TEST_ELFS)"
	cd tests/act4_sample_processor && $(PYTHON) ../../bin/scan_test_logs.py

.PHONY: disassemble

%.bin: %.hex
	@sed -E 's/^[[:space:]]*#[[:space:]]*//; s/^[[:space:]]+//; /^[[:space:]]*$$/d' $< | \
	$(PYTHON) -c 'import sys,struct; \
	[sys.stdout.buffer.write(struct.pack("<I", int(l.strip(),16))) for l in sys.stdin if l.strip()]' \
	> $@

%.dis: %.bin
	@riscv64-unknown-elf-objdump -D -b binary -m riscv:rv32 $< > $@
	@echo "Wrote $@"

.PHONY: arch-test
arch-test: Makefile $(PROCESSOR_TEST_DIR)/test_config.yaml
	uv run --with $(WALLY)/addins/riscv-arch-test-cvw/framework make -C \
	$(WALLY)/addins/riscv-arch-test-cvw \
	CONFIG_FILES=$(PROCESSOR_TEST_DIR)/test_config.yaml \
	WORKDIR=$(ARCH_WORK_DIR)
# Target flow below but using substitute above while act4 broken
# 	$(MAKE) -C $(RISCV_ARCH_TEST) \
#    CONFIG_FILE=$(PROCESSOR_TEST_DIR)/test_config.yaml \
#    WORKDIR=$(PROCESSOR_TEST_DIR)/work

# ----  Coremark flow  ---- #

.PHONY: coremark

coremark: $(CM_WORK_DIR)/coremark.bare.riscv.run

WALLY_PORT_DIR = $(WALLY)/benchmarks/coremark/riscv64-baremetal
cmbase  = $(WALLY)/addins/coremark

cmscript_files=$(cmbase)/core_main.c $(cmbase)/core_list_join.c $(cmbase)/coremark.h  \
    $(cmbase)/core_matrix.c $(cmbase)/core_state.c $(cmbase)/core_util.c

cmconfig_files=$(WALLY_PORT_DIR)/core_portme.h $(WALLY_PORT_DIR)/core_portme.c $(WALLY_PORT_DIR)/core_portme.mak \
    $(COREMARK_DIR)/crt.S $(WALLY_PORT_DIR)/encoding.h $(WALLY_PORT_DIR)/util.h $(COREMARK_DIR)/syscalls.c \
	$(LINKER)

$(CM_WORK_DIR)/coremark.bare.riscv.elf: $(cmscript_file) $(cmconfig_files) Makefile
	@mkdir -p $(CM_WORK_DIR)/portdir
	cp -f $(cmconfig_files) $(CM_WORK_DIR)/portdir
	$(MAKE) -C $(cmbase) PORT_DIR=$(CM_WORK_DIR)/portdir compile RISCV=$(RISCV) XCFLAGS="$(PORT_CFLAGS)"
	mkdir -p $(CM_WORK_DIR)
	mv $(cmbase)/coremark.bare.riscv $(CM_WORK_DIR)/coremark.bare.riscv.elf

# ----            Clean             ---- #

.PHONY: clean

clean:
	$(MAKE) -C $(cmbase) clean
	$(MAKE) -C $(RISCV_ARCH_TEST) clean
	rm -rf $(TEST_WORK_DIR)
	rm -rf $(ARCH_WORK_DIR)
	rm -rf $(WORK_DIR)
	rm -rf $(CM_WORK_DIR)
	rm -rf $(C_TEST_WORK_DIR)
#rm -rf $(SYNTH_DIR)
