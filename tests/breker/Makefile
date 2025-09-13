NUM_TESTS ?= 1 # Number of tests to generate for each constraint file
XLEN ?= 64

# General Makefile settings
SHELL := /bin/bash

# Breker/Trek paths and variables
TESTDIR          := $(WALLY)/tests/breker/work
TREKFILES        := $(WALLY)/testbench/trek_files
CONSTRAINTS_DIR  := $(WALLY)/tests/breker/constraints
PLATFORM_YAML    := $(TREKFILES)/platform-rv${XLEN}.yaml
CUSTOMER_YAML    := $(TREKFILES)/customer.yaml
TREKSVIP_YAML    := $(BREKER_HOME)/examples/tutorials/svip/treksvip/yaml/treksvip.yaml
CONSTRAINT_FILES := $(wildcard $(CONSTRAINTS_DIR)/*.yaml)
TREKEXE_FLAGS    += --seed 0x # free (0x) or lock (0x1) the seed used for test generation

TREKSVIP         := source $(TREKFILES)/breker-setup.sh && treksvip -p $(PLATFORM_YAML) -p $(TREKSVIP_YAML) $(TREKEXE_FLAGS)

# Compilation paths and variables
START_LIB_DIR := $(WALLY)/examples/C/common
START_LIB     := $(START_LIB_DIR)/crt.S $(START_LIB_DIR)/syscalls.c
MARCH          = -march=rv${XLEN}gc_zcb_zfa_zba_zbb_zbc_zbs_zfh_zicboz_zicbop_zicbom_zicond_zbkb_zbkx_zknd_zkne_zknh_svinval
MABI           = -mabi=$(if $(findstring 32,$(XLEN)),i,)lp$(XLEN)
LINKER        := $(START_LIB_DIR)/test.ld
LINK_FLAGS    := -nostartfiles
CFLAGS        := -Wa,-alhs -Wa,-L -mcmodel=medany -Og -DSINGLE_CPU

# Find all constraint files and generate NUM_TESTS tests for each one
TESTS = $(foreach yaml,$(CONSTRAINT_FILES),$(foreach n,$(shell seq 1 $(NUM_TESTS)),$(patsubst $(CONSTRAINTS_DIR)/%.yaml,$(TESTDIR)/%_$(n),$(yaml))))

.PHONY: all clean
all: $(TESTS)

# Generate c tests
$(TESTDIR)/%: | $(TESTDIR)
	$(eval CONSTRAINT_FILE := $(shell echo $* | sed 's/_[0-9]*$$//'))
	$(TREKSVIP) -p $(CONSTRAINTS_DIR)/$(CONSTRAINT_FILE).yaml -p $(CUSTOMER_YAML) -o $@/$* -e pss_top.entry
	$(MAKE) $@/$*.elf

# Compile c code
.PRECIOUS: $(TESTDIR)/%.elf
$(TESTDIR)/%.elf: $(TESTDIR)/%.c 
	riscv64-unknown-elf-gcc $(MARCH) $(MABI) $(CFLAGS) $(LINK_FLAGS) -T$(LINKER) -I$(START_LIB_DIR) $(START_LIB) -g -o $@ $< > /dev/null
	$(MAKE) $@.objdump

# Disassemble the elf file
$(TESTDIR)/%.elf.objdump: $(TESTDIR)/%.elf
	riscv64-unknown-elf-objdump -S $< > $@

# View the model graph
%.view_graph: $(CONSTRAINTS_DIR)/%.yaml
	$(TREKSVIP) -p $(CONSTRAINTS_DIR)/$^.yaml -p $(CUSTOMER_YAML) -t pss_top.entry

$(TESTDIR):
	mkdir -p $(TESTDIR)

clean:
	rm -rf $(TESTDIR)/*
