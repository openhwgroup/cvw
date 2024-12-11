shell := /bin/bash

# Breker/Trek paths and variables
TESTDIR          := $(WALLY)/tests/breker/work
TREKFILES        := $(WALLY)/testbench/trek_files
CONSTRAINTS_DIR  := $(WALLY)/tests/breker/constraints
PLATFORM_YAML    := $(TREKFILES)/platform.yaml
CUSTOMER_YAML    := $(TREKFILES)/customer.yaml
TREKSVIP_YAML    := $(BREKER_HOME)/examples/tutorials/svip/treksvip/yaml/treksvip.yaml
CONSTRAINT_FILES := $(shell find $(CONSTRAINTS_DIR) -type f)
TREKEXE_FLAGS    += --seed 0x # free (0x) or lock (0x1) the seed used for test generation
TREKSVIP = source $(TREKFILES)/breker-setup.sh && treksvip -p $(PLATFORM_YAML) -p $(TREKSVIP_YAML) $(TREKEXE_FLAGS)

EXAMPLES_LIB = $(WALLY)/examples/C/common

# -nostdlib -static -lm -fno-tree-loop-distribute-patterns

# Compilation paths and variables
MARCH        :=-march=rv64gc_zcb_zfa_zba_zbb_zbc_zbs_zfh_zicboz_zicbop_zicbom_zbkb_zbkx_zknd_zkne_zknh_svinval 
MABI         :=-mabi=lp64d
LINKER       := $(EXAMPLES_LIB)/test.ld
# $(WALLY)/tests/custom/linker8000-0000.x
LINK_FLAGS   := -nostartfiles
CFLAGS 		   := -Wa,-alhs -Wa,-L -mcmodel=medany -Og -DSINGLE_CPU 
CRT0_DIR     := $(WALLY)/tests/custom/crt0
WIDTH        := 64

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
%.elf: %.c $(CRT0_DIR)/libcrt0.a
	riscv64-unknown-elf-gcc $(MARCH) $(MABI) $(CFLAGS) $(LINK_FLAGS) -g -o $@ $< -T $(LINKER) -I$(EXAMPLES_LIB) $(EXAMPLES_LIB)/crt.S $(EXAMPLES_LIB)/syscalls.c> /dev/null
# riscv64-unknown-elf-gcc $(MARCH) $(MABI) $(CFLAGS) $(LINK_FLAGS) -g -o $@ $< -L$(CRT0_DIR) -lcrt0 -T $(LINKER) > /dev/null

# Convert elf to hex
%.elf.memfile: %.elf
	riscv64-unknown-elf-objdump -D $< > $<.objdump
	riscv64-unknown-elf-elf2hex --bit-width $(WIDTH) --input $< --output $@
	extractFunctionRadix.sh $<.objdump

# View the model graph TODO: What does this do? Move to another makefile?
%.view_graph:%
	$(TREKSVIP) -p ../tests/test_$^.yaml -p $(CUSTOMER_YAML) -t pss_top.entry

# Library needed for C code
$(CRT0_DIR)/libcrt0.a:
	make -C $(CRT0_DIR)

$(TESTDIR):
	mkdir -p $(TESTDIR)

clean:
	rm -rf $(TESTS)
