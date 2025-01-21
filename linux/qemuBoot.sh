#!/bin/bash
BUILDROOT="${BUILDROOT:-$RISCV/buildroot}"
IMAGES="$BUILDROOT"/output/images

if [[ "$1" == "--gdb" && -n "$2" ]]; then
    GDB_FLAG="-gdb tcp::$2 -S"
fi

qemu-system-riscv64 \
	-M virt -m 256M -nographic \
	-bios "$IMAGES"/fw_jump.bin \
	-kernel "$IMAGES"/Image \
	-initrd "$IMAGES"/rootfs.cpio \
	-dtb "$IMAGES"/wally-virt.dtb \
	-cpu rva22s64,zicond=true,zfa=true,zfh=true,zcb=true,zbc=true,zkn=true,sstc=true,svadu=true,svnapot=true \
	$GDB_FLAG
