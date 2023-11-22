#!/bin/bash
tcpPort=1235
imageDir=$RISCV/buildroot/output/images
tvDir=$RISCV/linux-testvectors
rawRamFile="$tvDir/ramGDB.bin"
ramFile="$tvDir/ram.bin"
rawBootmemFile="$tvDir/bootmemGDB.bin"
bootmemFile="$tvDir/bootmem.bin"
rawUntrimmedBootmemFile="$tvDir/untrimmedBootmemFileGDB.bin"
untrimmedBootmemFile="$tvDir/untrimmedBootmemFile.bin"
DEVICE_TREE=${imageDir}/wally-virt.dtb

read -p "Warning: running this script will overwrite the contents of:
  * $rawRamFile
  * $ramFile
  * $rawBootmemFile
  * $bootmemFile
  * $rawUntrimmedBootmemFile
  * $untrimmedBootmemFile
Would you like to proceed? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    if [ ! -d "$tvDir" ]; then
        echo "Error: linux testvector directory $tvDir not found!">&2
        echo "Please create it. For example:">&2
        echo "    sudo mkdir -p $tvDir">&2
        exit 1
    fi
    test -w $tvDir
    if [ ! $? -eq 0 ]; then
        echo "Error: insuffcient write privileges for linux testvector directory $tvDir !">&2
        echo "Please chmod it. For example:">&2
        echo "    sudo chmod -R a+rw $tvDir">&2
        exit 1
    fi

    echo "Launching QEMU in replay mode!"
    (qemu-system-riscv64 \
    -M virt -m 256M -dtb $DEVICE_TREE \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
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
    -ex "printf \"Creating $rawUntrimmedBootmemFile\n\"" \
    -ex "printf \"Warning - please verify that the second half of $rawUntrimmedBootmemFile is all 0s\n\"" \
    -ex "dump binary memory $rawUntrimmedBootmemFile 0x1000 0x2fff" \
    -ex "printf \"Creating $rawRamFile\n\"" \
    -ex "dump binary memory $rawRamFile 0x80000000 0x8fffffff" \
    -ex "kill" \
    -ex "q"

    echo "Changing Endianness"
    make fixBinMem
    ./fixBinMem "$rawRamFile" "$ramFile"
    ./fixBinMem "$rawBootmemFile" "$bootmemFile"
    ./fixBinMem "$rawUntrimmedBootmemFile" "$untrimmedBootmemFile"

    echo "genInitMem.sh completed!"
    echo "You may want to restrict write access to $tvDir now and give cad ownership of it."
    echo "Run the following:"
    echo "    sudo chown -R cad:cad $tvDir"
    echo "    sudo chmod -R go-w $tvDir"
fi
