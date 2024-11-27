TREKFILES        := $(WALLY)/testbench/trek_files
PLATFORM_YAML    := $(TREKFILES)/platform.yaml
TREKSVIP_YAML    := $(BREKER_HOME)/examples/tutorials/svip/treksvip/yaml/treksvip.yaml
TREKEXE_FLAGS    += --seed 0x # free (0x) or lock (0x1) the seed used for test generation
TREKSVIP = source $(TREKFILES)/breker-setup.sh && treksvip -p $(PLATFORM_YAML) -p $(TREKSVIP_YAML) $(TREKEXE_FLAGS)

uvm_output:
	rm -rf uvm_output
	$(TREKSVIP) -p $(PLATFORM_YAML) -p $(TREKSVIP_YAML) --uvm_output=uvm_output

clean:
	rm -rf uvm_output
