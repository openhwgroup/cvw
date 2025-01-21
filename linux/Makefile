# .SECONDEXPANSION:

BUILDROOT := buildroot
IMAGES := ${BUILDROOT}/output/images
WALLYLINUX := $(WALLY)/linux
DIS := ${IMAGES}/disassembly
BR2_EXTERNAL_TREE := $(WALLYLINUX)/br2-external-tree
LINUX_TEST_VECTORS := $(RISCV)/linux-testvectors

# set sudo if needed depending on $RISCV
SUDO := $(shell mkdir -p $(RISCV)/.test > /dev/null 2>&1 || echo sudo)

# Device tree files
DTS ?= $(wildcard devicetree/*.dts)
DTB := $(foreach name, $(DTS:%.dts=%.dtb), $(IMAGES)/$(notdir $(name)))

# Disassembly stuff
BINARIES := fw_jump.elf vmlinux busybox
OBJDUMPS := $(foreach name, $(basename $(BINARIES) .elf), $(DIS)/$(name).objdump)

.PHONY: all check_environment check_write_permissions config Image disassemble generate install dumptvs clean cleanDTB

all: check_write_permissions clean config Image disassemble install dumptvs

check_environment: $(RISCV)
ifeq ($(findstring :$(RISCV)/lib:,:$(LD_LIBRARY_PATH):),)
	@(echo "ERROR: Your environment variables are not set correctly." >&2 \
	&& echo "Make sure to source setup.sh or install buildroot using the wally-tool-chain-install.sh script." >&2 \
	&& exit 1)
endif

check_write_permissions: check_environment
ifeq ($(SUDO), sudo)
	@echo "Cannot write to '$(RISCV)'." \
		"Using sudo (you may be prompted for your password several times throughout the install)"
endif
	@$(SUDO) mkdir -p $(RISCV)/.test || \
		(echo "ERROR: Still unable to write to '$(RISCV)'." >&2 \
		&& exit 1)
	@$(SUDO) rm -r $(RISCV)/.test

Image: check_environment $(BUILDROOT)
	bash -c "unset LD_LIBRARY_PATH; $(MAKE) -C $(BUILDROOT)"
# $(MAKE) generate
	@echo "Buildroot Image successfully generated."

install: check_write_permissions
	$(SUDO) rm -rf $(RISCV)/$(BUILDROOT)
	$(SUDO) mv $(BUILDROOT) $(RISCV)/$(BUILDROOT)
	@echo "Buildroot successfully installed."

TCP_PORT=1235
RAW_RAM_FILE=${LINUX_TEST_VECTORS}/ramGDB.bin
RAM_FILE=${LINUX_TEST_VECTORS}/ram.bin
RAW_BOOTMEM_FILE=${LINUX_TEST_VECTORS}/bootmemGDB.bin
BOOTMEM_FILE=${LINUX_TEST_VECTORS}/bootmem.bin

MEM_FILES=${RAM_FILE} ${BOOTMEM_FILE}

dumptvs: check_write_permissions ${MEM_FILES}

${LINUX_TEST_VECTORS}/%.bin: ${LINUX_TEST_VECTORS}/%GDB.bin
	truncate -s %8 $^ # Extend file to 8 byte multiple
	objcopy --reverse-bytes=8 -F binary $^ $@ # Reverse bytes

${LINUX_TEST_VECTORS}/%GDB.bin: | $(LINUX_TEST_VECTORS)
	${WALLYLINUX}/qemuBoot.sh --gdb ${TCP_PORT} &
	riscv64-unknown-elf-gdb -batch \
		-ex "target remote :${TCP_PORT}" \
		-ex "maintenance packet Qqemu.PhyMemMode:1" \
		-ex "printf \"Creating ${RAW_BOOTMEM_FILE}\n\"" \
		-ex "dump binary memory ${RAW_BOOTMEM_FILE} 0x1000 0x1fff" \
		-ex "printf \"Creating ${RAW_RAM_FILE}\n\"" \
		-ex "dump binary memory ${RAW_RAM_FILE} 0x80000000 0x8fffffff" \
		-ex "kill" \

generate: $(DTB) $(IMAGES)

$(IMAGES)/%.dtb: ${WALLYLINUX}/devicetree/%.dts
	dtc -I dts -O dtb $< > $@

$(IMAGES):
	@ echo "No output/images directory in buildroot."
	@ echo "Run make --jobs in buildroot directory before generating device tree binaries."; exit 1

$(RISCV):
	@ echo "ERROR: No $(RISCV) directory. Make sure you have installed the Wally Toolchain."
	@ echo "and sourced setup.sh"

# Disassembly rules ---------------------------------------------------
disassemble: check_environment
	cp $(BUILDROOT)/output/build/linux-*/vmlinux $(IMAGES)
	$(MAKE) $(OBJDUMPS) $(DIS)/rootfs

$(DIS)/rootfs: $(IMAGES)/rootfs.cpio
	@echo "Ignore error about dev/console when extracting rootfs from rootfs.cpio"
	mkdir -p $(DIS)/rootfs
	-cpio -i -D $(DIS)/rootfs < $(IMAGES)rootfs.cpio

$(DIS)/%.objdump: $(IMAGES)/%.elf | $(DIS)
	riscv64-unknown-elf-objdump -DS $< >> $@
	$(WALLY)/bin/extractFunctionRadix.sh $@

$(DIS)/%.objdump: $(IMAGES)/% | $(DIS)
	riscv64-unknown-elf-objdump -S $< >> $@
	$(WALLY)/bin/extractFunctionRadix.sh $@

$(IMAGES)/vmlinux:
	cp $(BUILDROOT)/output/build/linux-*/vmlinux $@

$(IMAGES)/busybox:
	cp $(BUILDROOT)/output/build/busybox-*/busybox $@

config: $(BUILDROOT) $(BR2_EXTERNAL_TREE)/configs/wally_defconfig
	$(MAKE) -C $(BUILDROOT) wally_defconfig BR2_EXTERNAL=$(BR2_EXTERNAL_TREE)

$(BUILDROOT):
	git clone https://github.com/buildroot/buildroot.git $@
	cd $@; git checkout 2024.11.x

$(LINUX_TEST_VECTORS):
	$(SUDO) mkdir -p $@

$(DIS):
	mkdir -p $@

cleanDTB:
	rm -f $(IMAGES)/*.dtb

clean:
	rm -rf $(BUILDROOT)
