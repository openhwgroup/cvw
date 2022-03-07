#!/bin/bash
imageDir=$RISCV/buildroot/output/images
tvDir=$RISCV/linux-testvectors
tcpPort=1239

# QEMU Simulation
(qemu-system-riscv64 \
-M virt -dtb $imageDir/wally-virt.dtb \
-nographic \
-bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
-singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on \
> ./qemu-serial) # \
#-gdb tcp::$tcpPort -S \
#& riscv64-unknown-elf-gdb -quiet -x debug.gdb -ex "debug $tcpPort \"$imageDir/vmlinux\""
