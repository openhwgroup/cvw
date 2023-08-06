RISCV := /opt/riscv
BUILDROOT := ${RISCV}/buildroot
IMAGES := ${BUILDROOT}/output/images
WALLY := $(shell dirname $(shell pwd))
WALLYLINUX := $(shell pwd)
DIS := ${IMAGES}/disassembly
BRPACKAGES := $(WALLYLINUX)/buildroot-packages

# Buildroot Config Stuff
WALLYBOARDSRC := $(WALLYLINUX)/buildroot-config-src/wally
WALLYBOARD := $(BUILDROOT)/board/wally

# Buildroot Package Stuff
PACKAGE_SOURCE := ${WALLYLINUX}/buildroot-packages/package-source
FPGA_AXI_SDC := ${WALLYLINUX}/buildroot-packages/fpga-axi-sdc
DRIVER := ${PACKAGE_SOURCE}/fpga-axi-sdc.c
PATCHFILE := $(BRPACKAGES)/package.patch

# Device tree files 
DTS ?= $(shell find -type f -regex ".*\.dts" | sort)
DTB := $(DTS:%.dts=%.dtb)
DTB := $(foreach name, $(DTB), $(IMAGES)/$(shell basename $(name)))

# Disassembly stuff
BINARIES := fw_jump.elf vmlinux busybox
BINARIES := $(foreach name, $(BINARIES), $(shell find -type f -regex ".*$(name)"))
OBJDUMPS := fw_jump.objdump vmlinux.objdump busybox.objdump
OBJDUMPS := $(foreach name, $(OBJDUMPS), $(DIS)/$(name))

.PHONY: generate cleanDriver patch clean

# Generate all device trees
# TODO: Add configuration for only generating device tree for specified
#       supported FPGA.
test:

generate: $(DTB)

$(DTB): $(DTS) $(IMAGES)
	dtc -I dts -O dtb $< > $@

$(IMAGES):
	@ echo "No output/images directory in buildroot."
	@ echo "Run make --jobs in buildroot directory before generating device tree binaries."; exit 1

disassemble:
	mkdir -p $(DIS)
	make -j $(OBJDUMPS)

$(OBJDUMPS): $(BINARIES) 
	riscv64-unknown-elf-objdump -DS $< >> $@

# Generating new Buildroot directories --------------------------------

# This directive should be run as: make patch BUILDROOT=path/to/buildroot
patch: $(BUILDROOT)/package/fpga-axi-sdc $(WALLYBOARD)/main.config $(WALLYBOARD)/linux.config $(DRIVER)
	cp $(WALLYBOARD)/main.config $(BUILDROOT)/.config

# CONFIG DEPENDENCIES 2021.05 -----------------------------------------
$(WALLYBOARD)/main.config: $(WALLYBOARD) $(BRPACKAGES)/wally.config
	cp $(BRPACKAGES)/wally.config $@

$(WALLYBOARD)/linux.config: $(WALLYBOARD) $(BRPACKAGES)/linux.config
	cp $(BRPACKAGES)/linux.config $@

$(WALLYBOARD): $(BUILDROOT)
	cp -r $(WALLYBOARDSRC) $(BUILDROOT)/board

# Buildroot Package ---------------------------------------------------
$(BUILDROOT)/package/fpga-axi-sdc: $(BUILDROOT) $(PATCHFILE) $(BRPACKAGES)/fpga-axi-sdc
	cp -r $(BRPACKAGES)/fpga-axi-sdc $(BUILDROOT)/package
	sed -i 's|FPGA_AXI_SDC_SITE =|FPGA_AXI_SDC_SITE = $(PACKAGE_SOURCE)|1' $(BUILDROOT)/package/fpga-axi-sdc/fpga-axi-sdc.mk
	cd $(BUILDROOT); if git apply --check $(PATCHFILE) > /dev/null ; then git apply $(PATCHFILE); fi

$(PATCHFILE):
	cd $(BUILDROOT); git apply $(PATCHFILE)

$(BUILDROOT):
	git clone https://github.com/buildroot/buildroot.git $@
	# cd $@; git checkout 2023.05.x
	cd $@; git checkout 2021.05

$(DRIVER):
	@ if [ -d "$(WALLY)/addins/vivado-risc-v" ] ; then git submodule update --init $(WALLY)/addins/vivado-risc-v; fi
	cp ../addins/vivado-risc-v/patches/fpga-axi-sdc.c $@
	# For 2021.05
	sed -i "s|card_hw_reset|hw_reset|1" $@

# ---------------------------------------------------------------------

cleanDriver:
	rm -f $(DRIVER)

clean:
	ls $(IMAGES)
	rm -rf $(IMAGES)/*.dtb
	rm -rf $(DIS)
	ls $(IMAGES)
