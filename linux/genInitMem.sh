#!/bin/bash
set -e
tcpPort=1235
imageDir=$RISCV/buildroot/output/images
tvDir=$RISCV/linux-testvectors
rawRamFile="$tvDir/ramGDB.bin"
ramFile="$tvDir/ram.bin"
rawBootmemFile="$tvDir/bootmemGDB.bin"
bootmemFile="$tvDir/bootmem.bin"
rawUntrimmedBootmemFile="$tvDir/untrimmedBootmemFileGDB.bin"
DEVICE_TREE=${imageDir}/wally-virt.dtb

if ! mkdir -p "$tvDir"; then
    echo "Error: unable to create linux testvector directory $tvDir!">&2
    echo "Please try running as sudo.">&2
    exit 1
fi
if ! test -w "$tvDir"; then
    echo "Using sudo to gain access to $tvDir"
    if ! sudo chmod -R a+rw "$tvDir"; then
        echo "Error: insuffcient write privileges for linux testvector directory $tvDir !">&2
        echo "Please chmod it. For example:">&2
        echo "    sudo chmod -R a+rw $tvDir">&2
        exit 1
    fi
fi

echo "Launching QEMU in replay mode!"
(qemu-system-riscv64 \
-M virt -m 256M -dtb "$DEVICE_TREE" \
-nographic \
-bios "$imageDir"/fw_jump.elf -kernel "$imageDir"/Image -append "root=/dev/vda ro" -initrd "$imageDir"/rootfs.cpio \
-gdb tcp::$tcpPort -S) \
& riscv64-unknown-elf-gdb --quiet \
-ex "set pagination off" \
-ex "set logging overwrite on" \
-ex "set logging redirect on" \
-ex "set confirm off" \
-ex "target extended-remote :$tcpPort" \
-ex "maintenance packet Qqemu.PhyMemMode:1" \
-ex "printf \"Creating $rawBootmemFile\n\"" \
-ex "dump binary memory $rawBootmemFile 0x1000 0x1fff" \
-ex "printf \"Creating $rawRamFile\n\"" \
-ex "dump binary memory $rawRamFile 0x80000000 0x8fffffff" \
-ex "kill" \
-ex "q"

echo "Changing Endianness"
# Extend files to 8 byte multiple
truncate -s %8 "$rawRamFile"
truncate -s %8 "$rawBootmemFile"
# Reverse bytes
objcopy --reverse-bytes=8 -F binary "$rawRamFile" "$ramFile"
objcopy --reverse-bytes=8 -F binary "$rawBootmemFile" "$bootmemFile"
rm -f "$rawRamFile" "$rawBootmemFile" "$rawUntrimmedBootmemFile"

echo "genInitMem.sh completed!"
echo "You may want to restrict write access to $tvDir now and give cad ownership of it."
echo "Run the following:"
echo "    sudo chown -R cad:cad $tvDir"
echo "    sudo chmod -R go-w $tvDir"
