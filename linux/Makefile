RISCV := /opt/riscv
BUILDROOT := ${RISCV}/buildroot
IMAGES := ${BUILDROOT}/output/images
WALLYLINUX := $(shell pwd)

.PHONY: all clean patch

all: 

patch: $(BUILDROOT)
	@ echo "${WALLYLINUX}"
	cp -r $(WALLYLINUX)/buildroot-config-src/wally $</board
	cp -r $(WALLYLINUX)/buildroot-packages/fpga-axi-sdc $</package
	cp $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1/linux.config $</board/wally/linux.config
	cp $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1/main.config $</board/wally/main.config
	cd $<; git apply $(WALLYLINUX)/buildroot-packages/package-2023.05.1.patch
	cd $<; cp ./board/wally/main.config .config

$(BUILDROOT):
	git clone https://github.com/buildroot/buildroot.git $@
	cd $@; git checkout 2023.05.x

clean:
