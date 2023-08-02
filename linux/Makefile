RISCV := /opt/riscv
BUILDROOT := ${RISCV}/buildroot
IMAGES := ${BUILDROOT}/output/images
WALLY := $(shell dirname $(shell pwd))
WALLYLINUX := $(shell pwd)
PACKAGE_SOURCE := ${WALLYLINUX}/buildroot-packages/package-source
FPGA_AXI_SDC := ${WALLYLINUX}/buildroot-packages/fpga-axi-sdc
DRIVER := ${PACKAGE_SOURCE}/fpga-axi-sdc.c

.PHONY: all clean patch

all: $(IMAGES)

patch: $(BUILDROOT) $(DRIVER)
	@ echo "${WALLYLINUX}"
	cp ../addins/vivado-risc-v/patches/fpga-axi-sdc.c $(DRIVER)
	cp -r $(WALLYLINUX)/buildroot-config-src/wally $</board
	cp -r $(WALLYLINUX)/buildroot-packages/fpga-axi-sdc $</package
	sed -i 's|FPGA_AXI_SDC_SITE =|FPGA_AXI_SDC_SITE = $(PACKAGE_SOURCE)|1' $(BUILDROOT)/package/fpga-axi-sdc/fpga-axi-sdc.mk
	cp $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1/linux.config $</board/wally/linux.config
	cp $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1/main.config $</board/wally/main.config
	cd $<; git apply $(WALLYLINUX)/buildroot-packages/package-2023.05.1.patch
	cd $<; cp $(BUILDROOT)/board/wally/main.config $(BUILDROOT)/.config

$(BUILDROOT):
	git clone https://github.com/buildroot/buildroot.git $@
	cd $@; git checkout 2023.05.x

$(DRIVER):
	@ if [ -d "$(WALLY)/addins/vivado-risc-v" ] ; then git submodule update --init $(WALLY)/addins/vivado-risc-v; fi

clean:
