RISCV := /opt/riscv
BUILDROOT := ${RISCV}/buildroot
IMAGES := ${BUILDROOT}/output/images
WALLYLINUX := $(shell pwd)
PACKAGE_SOURCE := ${WALLYLINUX}/buildroot-packages/package-source
FPGA_AXI_SDC := ${WALLYLINUX}/buildroot-packages/fpga-axi-sdc

.PHONY: all clean patch

all:
	sed -i 's|FPGA_AXI_SDC_SITE = __site__|FPGA_AXI_SDC_SITE = $(PACKAGE_SOURCE)|1' $(FPGA_AXI_SDC)/fpga-axi-sdc.mk

patch: $(BUILDROOT) 
	@ echo "${WALLYLINUX}"
	cp -r $(WALLYLINUX)/buildroot-config-src/wally $</board
	cp -r $(WALLYLINUX)/buildroot-packages/fpga-axi-sdc $</package
	sed -i 's|FPGA_AXI_SDC_SITE =|FPGA_AXI_SDC_SITE = $(PACKAGE_SOURCE)|1' $(BUILDROOT)/package/fpga-axi-sdc/fpga-axi-sdc.mk
	cp $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1/linux.config $</board/wally/linux.config
	cp $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1/main.config $</board/wally/main.config
	cd $<; git apply $(WALLYLINUX)/buildroot-packages/package-2023.05.1.patch
	cd $<; cp ./board/wally/main.config .config

$(BUILDROOT):
	git clone https://github.com/buildroot/buildroot.git $@
	cd $@; git checkout 2023.05.x

clean:
