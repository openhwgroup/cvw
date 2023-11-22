#!/bin/bash
imageDir=$RISCV/buildroot/output/images
tvDir=$RISCV/linux-testvectors
recordFile="$tvDir/all.qemu"
DEVICE_TREE=${imageDir}/wally-virt.dtb

read -p "Warning: running this script will overwrite $recordFile
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

    echo "Launching QEMU in record mode!"
    qemu-system-riscv64 \
    -M virt -m 256M -dtb $DEVICE_TREE \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on,rr=record,rrfile=$recordFile

    echo "genRecording.sh completed!"
    echo "You may want to restrict write access to $tvDir now and give cad ownership of it."
    echo "Run the following:"
    echo "    sudo chown -R cad:cad $tvDir"
    echo "    sudo chmod -R go-w $tvDir"
fi
