RISCV := /opt/riscv
BUILDROOT := ${RISCV}/buildroot
IMAGES := ${BUILDROOT}/output/images
WALLY := $(shell dirname $(shell pwd))
WALLYLINUX := $(shell pwd)
PACKAGE_SOURCE := ${WALLYLINUX}/buildroot-packages/package-source
FPGA_AXI_SDC := ${WALLYLINUX}/buildroot-packages/fpga-axi-sdc
DRIVER := ${PACKAGE_SOURCE}/fpga-axi-sdc.c

# Device tree file 
DTS ?= $(shell find -type f -regex ".*\.dts" | sort)
DTB := $(DTS:%.dts=%.dtb)
DTB := $(foreach name, $(DTB), $(IMAGES)/$(shell basename $(name)))

.PHONY: generate cleanDriver patch clean

# Generate all device trees
# TODO: Add configuration for only generating device tree for specified
#       supported FPGA.
generate: $(DTB)

$(DTB): $(DTS)
	dtc -I dts -O dtb $< > $@ 

disassemble:

# Generating new Buildroot directories --------------------------------

# This directive should be run as: make patch BUILDROOT=path/to/buildroot
patch: $(BUILDROOT) $(DRIVER)
	@ echo "Patching buildroot directory at: $<"
	@ echo "Copying wally configuration files and rootfs_overlay to buildroot."
	cp -r $(WALLYLINUX)/buildroot-config-src/wally $</board

	@ echo "Moving fpga-axi-sdc driver package to buildroot"
	cp -r $(WALLYLINUX)/buildroot-packages/fpga-axi-sdc $</package

	@ echo "Package variable FPGA_AXI_SDC_SITE set to: $(PACKAGE_SOURCE)"
	sed -i 's|FPGA_AXI_SDC_SITE =|FPGA_AXI_SDC_SITE = $(PACKAGE_SOURCE)|1' $(BUILDROOT)/package/fpga-axi-sdc/fpga-axi-sdc.mk

	@ echo "Copying configurations to buildroot."
	cp $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1/linux.config $</board/wally/linux.config
	cp $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1/main.config $</board/wally/main.config

	@ echo "Patching buildroot directory."
	cd $<; git apply $(WALLYLINUX)/buildroot-packages/package-2023.05.1.patch

	@ echo "Copying main buildroot configuration as .config"
	cd $<; cp $(BUILDROOT)/board/wally/main.config $(BUILDROOT)/.config

$(BUILDROOT):
	git clone https://github.com/buildroot/buildroot.git $@
	cd $@; git checkout 2023.05.x

$(DRIVER):
	@ if [ -d "$(WALLY)/addins/vivado-risc-v" ] ; then git submodule update --init $(WALLY)/addins/vivado-risc-v; fi
	cp ../addins/vivado-risc-v/patches/fpga-axi-sdc.c $@

$(IMAGES):
	@ echo "No output/images directory in buildroot."
	@ echo "Run make --jobs in buildroot directory before generating device tree binaries."; exit 1

# ---------------------------------------------------------------------

cleanDriver:
	rm -f $(DRIVER)

clean:
	ls $(IMAGES)
	rm -rf $(IMAGES)/*.dtb
	ls $(IMAGES)
