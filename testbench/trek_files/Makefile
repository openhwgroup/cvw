SHELL               := /bin/bash
TREKFILES           := $(WALLY)/testbench/trek_files
RV32_PLATFORM_YAML  := $(TREKFILES)/platform-rv32.yaml
RV64_PLATFORM_YAML  := $(TREKFILES)/platform-rv64.yaml
TREKSVIP_YAML       := $(BREKER_HOME)/examples/tutorials/svip/treksvip/yaml/treksvip.yaml
TREKEXE_FLAGS       += --seed 0x # free (0x) or lock (0x1) the seed used for test generation
TREKSVIP            = source $(TREKFILES)/breker-setup.sh && treksvip -p $(TREKSVIP_YAML) $(TREKEXE_FLAGS)

all: rv32 rv64

rv32: rv32/uvm_output/trek_uvm.sv
rv64: rv64/uvm_output/trek_uvm.sv

rv32/uvm_output/trek_uvm.sv: $(RV32_PLATFORM_YAML) $(TREKSVIP_YAML)
	$(TREKSVIP) -p $(RV32_PLATFORM_YAML) --uvm_output=rv32/uvm_output

rv64/uvm_output/trek_uvm.sv: $(RV64_PLATFORM_YAML) $(TREKSVIP_YAML)
	$(TREKSVIP) -p $(RV64_PLATFORM_YAML) --uvm_output=rv64/uvm_output

clean:
	rm -rf rv32 rv64
