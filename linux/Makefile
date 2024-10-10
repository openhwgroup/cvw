BUILDROOT := buildroot
IMAGES := ${BUILDROOT}/output/images
WALLY := $(shell dirname $(shell pwd))
WALLYLINUX := $(shell pwd)
DIS := ${IMAGES}/disassembly
BRPACKAGES := $(WALLYLINUX)/buildroot-packages
BR2023 := $(WALLYLINUX)/buildroot-config-src/buildroot-2023.05.1

# set sudo if needed depending on $RISCV
ifeq ($(shell mkdir -p $(RISCV)/.test > /dev/null 2>&1 ; echo $$?), 0)
	SUDO :=
else
	SUDO := sudo
endif

# Buildroot Config Stuff
WALLYBOARDSRC := $(WALLYLINUX)/buildroot-config-src/wally
WALLYBOARD := $(BUILDROOT)/board/wally

# Device tree files
DTS ?= $(shell find devicetree -type f -regex ".*\.dts" | sort)
DTB := $(DTS:%.dts=%.dtb)
DTB := $(foreach name, $(DTB), $(IMAGES)/$(shell basename $(name)))

# Disassembly stuff
BINARIES := fw_jump.elf vmlinux busybox
OBJDUMPS := $(foreach name, $(BINARIES), $(basename $(name) .elf))
OBJDUMPS := $(foreach name, $(OBJDUMPS), $(DIS)/$(name).objdump)

.PHONY: all generate disassemble install clean cleanDTB cleanDriver check_write_permissions

all: check_write_permissions clean download Image disassemble install dumptvs

check_write_permissions:
ifeq ($(SUDO), sudo)
	@echo "Cannot write to '$(RISCV)'." \
		"Using sudo (you may be prompted for your password several times throughout the install)"
endif
	@$(SUDO) mkdir -p $(RISCV)/.test || \
		(echo "ERROR: Still unable to write to '$(RISCV)'." >&2 \
		&& exit 1)
	@$(SUDO) rm -r $(RISCV)/.test

Image:
	bash -c "unset LD_LIBRARY_PATH; $(MAKE) -C $(BUILDROOT)"
	$(MAKE) generate
	@echo "Buildroot Image successfully generated."

install: check_write_permissions
	$(SUDO) rm -rf $(RISCV)/$(BUILDROOT)
	$(SUDO) mv $(BUILDROOT) $(RISCV)/$(BUILDROOT)
	@echo "Buildroot successfully installed."

dumptvs: check_write_permissions
	$(SUDO) mkdir -p $(RISCV)/linux-testvectors
	cd testvector-generation; ./genInitMem.sh
	@echo "Testvectors successfully generated."

generate: $(DTB) $(IMAGES)

$(IMAGES)/%.dtb: ./devicetree/%.dts
	dtc -I dts -O dtb $< > $@

$(IMAGES):
	@ echo "No output/images directory in buildroot."
	@ echo "Run make --jobs in buildroot directory before generating device tree binaries."; exit 1

$(RISCV):
	@ echo "ERROR: No $(RISCV) directory. Make sure you have installed the Wally Toolchain."
	@ echo "and sourced setup.sh"

# Disassembly rules ---------------------------------------------------
disassemble:
	rm -rf $(BUILDROOT)/output/images/disassembly
	find  $(BUILDROOT)/output/build/linux-* -maxdepth 1 -name "vmlinux" | xargs  cp -t $(BUILDROOT)/output/images/
	mkdir -p $(DIS)
	$(MAKE) $(OBJDUMPS)
	# extract rootfs
	mkdir -p $(BUILDROOT)/output/images/disassembly/rootfs
	@echo "Ignore error about dev/console when extracting rootfs from rootfs.cpio"
	-cpio -i -D $(BUILDROOT)/output/images/disassembly/rootfs < $(BUILDROOT)/output/images/rootfs.cpio
	@echo "Disassembly successfully completed."

$(DIS)/%.objdump: $(IMAGES)/%.elf
	riscv64-unknown-elf-objdump -DS $< >> $@
	$(WALLY)/bin/extractFunctionRadix.sh $@

$(DIS)/%.objdump: $(IMAGES)/%
	riscv64-unknown-elf-objdump -S $< >> $@
	$(WALLY)/bin/extractFunctionRadix.sh $@

$(IMAGES)/vmlinux:
	linuxDir=$$(find $(BUILDROOT)/output/build -maxdepth 2 -type d -regex ".*/linux-[0-9]+\.[0-9]+\.[0-9]+$$") ;\
	cp $$linuxDir/vmlinux $@ ;\

$(IMAGES)/busybox:
	busyboxDir=$$(find $(BUILDROOT)/output/build -maxdepth 2 -type d -regex ".*/busybox-[0-9]+\.[0-9]+\.[0-9]+$$") ;\
	cp $$busyboxDir/busybox $@ ;\

# Generating new Buildroot directories --------------------------------
download: $(WALLYBOARD)
	cp $(WALLYBOARD)/main.config $(BUILDROOT)/.config
	@echo "Buildroot successfully download."

# CONFIG DEPENDENCIES 2023.05.1 ---------------------------------------
$(WALLYBOARD): $(BUILDROOT)
	cp -r $(WALLYBOARDSRC) $(BUILDROOT)/board
	cp $(BR2023)/main.config $(WALLYBOARD)/main.config
	cp $(BR2023)/linux.config $(WALLYBOARD)/linux.config

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
