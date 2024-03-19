RISCV := $(WALLY)# Changed to test linux build
#BUILDROOT := ${RISCV}/buildroot-test
BUILDROOT := buildroot
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
DTS ?= $(shell find devicetree -type f -regex ".*\.dts" | sort)
DTB := $(DTS:%.dts=%.dtb)
DTB := $(foreach name, $(DTB), $(IMAGES)/$(shell basename $(name)))

# Disassembly stuff
BINARIES := fw_jump.elf vmlinux busybox
OBJDUMPS := $(foreach name, $(BINARIES), $(basename $(name) .elf))
OBJDUMPS := $(foreach name, $(OBJDUMPS), $(DIS)/$(name).objdump)

.PHONY: all generate disassemble install clean cleanDTB cleanDriver test

all: clean download Image disassemble install

Image:
	bash -c "unset LD_LIBRARY_PATH; make -C $(BUILDROOT) --jobs;"
	$(MAKE) generate

install:
	rm -rf $(RISCV)/$(BUILDROOT)
	mv $(BUILDROOT) $(RISCV)/$(BUILDROOT)

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


disassemble:
	rm -rf $(BUILDROOT)/output/images/disassembly
	find  $(BUILDROOT)/output/build/linux-* -maxdepth 1 -name "vmlinux" | xargs  cp -t $(BUILDROOT)/output/images/
	mkdir -p $(DIS)
	make -j $(OBJDUMPS)
	# extract rootfs
	mkdir -p $(BUILDROOT)/output/images/disassembly/rootfs
	echo "Ignore error about dev/console when extracting rootfs from rootfs.cpio"
	-cpio -i -D $(BUILDROOT)/output/images/disassembly/rootfs < $(BUILDROOT)/output/images/rootfs.cpio

$(DIS)/%.objdump: $(IMAGES)/%.elf
	riscv64-unknown-elf-objdump -DS $< >> $@
	extractFunctionRadix.sh $@

$(DIS)/%.objdump: $(IMAGES)/%
	riscv64-unknown-elf-objdump -S $< >> $@
	extractFunctionRadix.sh $@

$(IMAGES)/vmlinux:
	linuxDir=$$(find $(BUILDROOT)/output/build -maxdepth 2 -type d -regex ".*/linux-[0-9]+\.[0-9]+\.[0-9]+$$") ;\
	cp $$linuxDir/vmlinux $@ ;\

$(IMAGES)/busybox:
	busyboxDir=$$(find $(BUILDROOT)/output/build -maxdepth 2 -type d -regex ".*/busybox-[0-9]+\.[0-9]+\.[0-9]+$$") ;\
	cp $$busyboxDir/busybox $@ ;\

# Generating new Buildroot directories --------------------------------

# This directive should be run as: make install BUILDROOT=path/to/buildroot
download: $(BUILDROOT)/package/fpga-axi-sdc $(WALLYBOARD)
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
	rm -rf $(BUILDROOT)
