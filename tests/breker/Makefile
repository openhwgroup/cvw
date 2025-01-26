SHELL := /bin/bash

# Breker/Trek paths and variables
TESTDIR          := $(WALLY)/tests/breker/work
TREKFILES        := $(WALLY)/testbench/trek_files
CONSTRAINTS_DIR  := $(WALLY)/tests/breker/constraints
PLATFORM_YAML    := $(TREKFILES)/platform.yaml
CUSTOMER_YAML    := $(TREKFILES)/customer.yaml
TREKSVIP_YAML    := $(BREKER_HOME)/examples/tutorials/svip/treksvip/yaml/treksvip.yaml
CONSTRAINT_FILES := $(shell find $(CONSTRAINTS_DIR) -type f)
TREKEXE_FLAGS    += --seed 0x # free (0x) or lock (0x1) the seed used for test generation
TREKSVIP         := source $(TREKFILES)/breker-setup.sh && treksvip -p $(PLATFORM_YAML) -p $(TREKSVIP_YAML) $(TREKEXE_FLAGS)

# Compilation paths and variables
START_LIB_DIR := $(WALLY)/examples/C/common
START_LIB     := $(START_LIB_DIR)/crt.S $(START_LIB_DIR)/syscalls.c
MARCH         :=-march=rv64gc_zcb_zfa_zba_zbb_zbc_zbs_zfh_zicboz_zicbop_zicbom_zbkb_zbkx_zknd_zkne_zknh_svinval 
MABI          :=-mabi=lp64d
LINKER        := $(START_LIB_DIR)/test.ld
LINK_FLAGS    := -nostartfiles
CFLAGS        := -Wa,-alhs -Wa,-L -mcmodel=medany -Og -DSINGLE_CPU
WIDTH         := 64

# Find all constraint files and generate tests for each one
TESTS = $(patsubst $(CONSTRAINTS_DIR)/%.yaml,$(TESTDIR)/%,$(CONSTRAINT_FILES))
.PHONY: all clean
all: $(TESTS)

# Generate c tests
$(TESTDIR)/%: $(CONSTRAINTS_DIR)/%.yaml | $(TESTDIR)
	$(TREKSVIP) -p $< -p $(CUSTOMER_YAML) -o $@/$* -e pss_top.entry
	$(MAKE) $@/$*.elf.memfile

# Compile c code
.PRECIOUS: %.elf
%.elf: %.c 
	riscv64-unknown-elf-gcc $(MARCH) $(MABI) $(CFLAGS) $(LINK_FLAGS) -T$(LINKER) -I$(START_LIB_DIR) $(START_LIB) -g -o $@ $< > /dev/null

# Convert elf to hex
%.elf.memfile: %.elf
	riscv64-unknown-elf-objdump -D $< > $<.objdump
	riscv64-unknown-elf-elf2hex --bit-width $(WIDTH) --input $< --output $@
	extractFunctionRadix.sh $<.objdump

# View the model graph TODO: What does this do? Move to another makefile?
%.view_graph: $(CONSTRAINTS_DIR)/%.yaml
	$(TREKSVIP) -p $(CONSTRAINTS_DIR)/$^.yaml -p $(CUSTOMER_YAML) -t pss_top.entry

$(TESTDIR):
	mkdir -p $(TESTDIR)

clean:
	rm -rf $(TESTS)
