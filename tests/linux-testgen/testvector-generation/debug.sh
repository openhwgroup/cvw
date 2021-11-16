#!/bin/bash
source genSettings.sh
tcpPort=1237

# Run without GDB
($customQemu \
-M virt \
-m 128M \
-nographic \
-bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
-singlestep -rtc clock=vm -icount shift=1,align=off,sleep=on)

# Run with GDB
#($customQemu \
#-M virt \
#-nographic -serial /dev/null \
#-bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
#-singlestep -rtc clock=vm -icount shift=1,align=off,sleep=on \
#-gdb tcp::$tcpPort -S) \
#& riscv64-unknown-elf-gdb -x debug.gdb -ex "debug $tcpPort"

