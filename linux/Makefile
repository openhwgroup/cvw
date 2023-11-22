RISCV := /opt/riscv
BUILDROOT := ${RISCV}/buildroot
IMAGES := ${BUILDROOT}/output/images
WALLY := $(shell dirname $(shell pwd))
WALLYLINUX := $(shell pwd)
DIS := ${IMAGES}/disassembly
BRPACKAGES := $(WALLYLINUX)/buildroot-packages
BR2023 := $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1

# Buildroot Config Stuff
WALLYBOARDSRC := $(WALLYLINUX)/buildroot-config-src/wally
WALLYBOARD := $(BUILDROOT)/board/wally

# Buildroot Package Stuff
PACKAGE_SOURCE := ${WALLYLINUX}/buildroot-packages/package-source
FPGA_AXI_SDC := ${WALLYLINUX}/buildroot-packages/fpga-axi-sdc
DRIVER := ${PACKAGE_SOURCE}/fpga-axi-sdc.c
PATCHFILE := $(BRPACKAGES)/package-2023.05.1.patch

# Device tree files 
DTS ?= $(shell find -type f -regex ".*\.dts" | sort)
DTB := $(DTS:%.dts=%.dtb)
DTB := $(foreach name, $(DTB), $(IMAGES)/$(shell basename $(name)))

# Disassembly stuff
BINARIES := fw_jump.elf vmlinux busybox
OBJDUMPS := $(foreach name, $(BINARIES), $(basename $(name) .elf))
OBJDUMPS := $(foreach name, $(OBJDUMPS), $(DIS)/$(name).objdump)

.PHONY: all generate disassemble install clean cleanDTB cleanDriver test

all:
	$(MAKE) install
	make -C $(BUILDROOT) --jobs
	$(MAKE) generate
	# TODO: Need to find a way to set the PATH for child processes.
	# source ../setup.sh; $(MAKE) disassemble

# Temp rule for debugging
test:
	echo $(shell find $(BUILDROOT)/output/build -maxdepth 2 -type d -regex ".*/linux-[0-9]+\.[0-9]+\.[0-9]+$$")

generate: $(DTB) $(IMAGES)

$(IMAGES)/%.dtb: ./devicetree/%.dts
	dtc -I dts -O dtb $< > $@

$(IMAGES):
	@ echo "No output/images directory in buildroot."
	@ echo "Run make --jobs in buildroot directory before generating device tree binaries."; exit 1

$(RISCV):
	@ echo "ERROR: No $(RISCV) directory. Make sure you have installed the Wally Toolchain."
	@ echo "this can be done with <WALLY>/bin/wally-tool-chain-install.sh"

# Disassembly rules ---------------------------------------------------

vmlinux:
	sed 's/BR2_LINUX_KERNEL_IMAGE=y/\# BR2_LINUX_KERNEL_IMAGE is not set/g' ${BR2023}/main.config > ${BR2023}/main-vmlinux.config
	sed -i 's/\# BR2_LINUX_KERNEL_VMLINUX is not set/BR2_LINUX_KERNEL_VMLINUX=y/g' ${BR2023}/main-vmlinux.config
	sed -i 's/\# BR2_TARGET_OPENSBI_LINUX_PAYLOAD is not set//g' ${BR2023}/main-vmlinux.config
	cp $(BR2023)/main-vmlinux.config $(WALLYBOARD)/main.config
	cp $(BR2023)/main-vmlinux.config $(BUILDROOT)/.config
	make -C $(BUILDROOT) --jobs

disassemble:
	mkdir -p $(DIS)
	make -j $(OBJDUMPS)

Image:
	cp $(BR2023)/main.config $(WALLYBOARD)/main.config
	cp $(BR2023)/main.config $(BUILDROOT)/.config
	make -C $(BUILDROOT) --jobs

$(DIS)/%.objdump: $(IMAGES)/%.elf
	riscv64-unknown-elf-objdump -DS $< >> $@

$(DIS)/%.objdump: $(IMAGES)/%
	riscv64-unknown-elf-objdump -S $< >> $@

$(IMAGES)/vmlinux:
	linuxDir=$$(find $(BUILDROOT)/output/build -maxdepth 2 -type d -regex ".*/linux-[0-9]+\.[0-9]+\.[0-9]+$$") ;\
	cp $$linuxDir/vmlinux $@ ;\

$(IMAGES)/busybox:
	busyboxDir=$$(find $(BUILDROOT)/output/build -maxdepth 2 -type d -regex ".*/busybox-[0-9]+\.[0-9]+\.[0-9]+$$") ;\
	cp $$busyboxDir/busybox $@ ;\

# Generating new Buildroot directories --------------------------------

# This directive should be run as: make install BUILDROOT=path/to/buildroot
install: $(BUILDROOT)/package/fpga-axi-sdc $(WALLYBOARD)
	cp $(WALLYBOARD)/main.config $(BUILDROOT)/.config

# CONFIG DEPENDENCIES 2023.05.1 ---------------------------------------
$(WALLYBOARD): $(BUILDROOT)
	cp -r $(WALLYBOARDSRC) $(BUILDROOT)/board
	cp $(BR2023)/main.config $(WALLYBOARD)/main.config
	cp $(BR2023)/linux.config $(WALLYBOARD)/linux.config

# Buildroot Package ---------------------------------------------------
$(BUILDROOT)/package/fpga-axi-sdc: $(BUILDROOT) $(PATCHFILE) $(BRPACKAGES)/fpga-axi-sdc
	cp -r $(BRPACKAGES)/fpga-axi-sdc $(BUILDROOT)/package
	sed -i 's|FPGA_AXI_SDC_SITE =|FPGA_AXI_SDC_SITE = $(PACKAGE_SOURCE)|1' $(BUILDROOT)/package/fpga-axi-sdc/fpga-axi-sdc.mk
	cd $(BUILDROOT); if git apply --check $(PATCHFILE) > /dev/null ; then git apply $(PATCHFILE); fi

$(PATCHFILE):
	cd $(BUILDROOT); git apply $(PATCHFILE)

$(BUILDROOT):
	git clone https://github.com/buildroot/buildroot.git $@
	cd $@; git checkout 2023.05.x

# ---------------------------------------------------------------------

cleanDriver:
	rm -f $(DRIVER)

cleanDTB:
	rm -f $(IMAGES)/*.dtb

clean:
	rm -rf $(DIS)
