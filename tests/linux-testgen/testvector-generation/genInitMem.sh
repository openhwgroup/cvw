#!/bin/bash

source genSettings.sh
tcpPort=1235

read -p "Warning: running this script will overwrite the contents of memory dumps needed for simulation.
Would you like to proceed? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ($customQemu \
    -M virt \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -gdb tcp::$tcpPort -S 2>/dev/null >/dev/null) \
    & riscv64-unknown-elf-gdb -quiet -x genInitMem.gdb -ex "genInitMem $tcpPort \"$intermedDir\""

    echo "Translating Mem from GDB to Questa format"
    ./fix_mem.py "$intermedDir/bootmemGDB.txt" "$outDir/bootmem.txt"
    ./fix_mem.py "$intermedDir/ramGDB.txt"     "$outDir/ram.txt"
    echo "Done"

    echo "Creating debugging objdump of linux image"
    riscv64-unknown-elf-objdump -D $imageDir/vmlinux > $outDir/vmlinux.objdump
    extractFunctionRadix.sh $outDir/vmlinux.objdump
    echo "Done"
fi
