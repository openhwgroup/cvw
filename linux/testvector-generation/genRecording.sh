#!/bin/bash
imageDir=$RISCV/buildroot/output/images
tvDir=$RISCV/linux-testvectors
recordFile="$tvDir/all.qemu"

read -p "Warning: running this script will overwrite $recordFile
Would you like to proceed? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Create Output Directory
    echo "Elevating permissions to create $recordFile"
    sudo mkdir -p $tvDir
    sudo chown cad $tvDir
    sudo touch $recordFile 
    sudo chmod a+rw $recordFile

    # Compile Devicetree from Source
    dtc -I dts -O dtb ../devicetree/wally-virt.dts > ../devicetree/wally-virt.dtb

    # QEMU Simulation
    echo "Launching QEMU!"
    qemu-system-riscv64 \
    -M virt -dtb ../devicetree/wally-virt.dtb \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on,rr=record,rrfile=$recordFile

    # Cleanup
    echo "Elevating permissions to restrict write access to $recordFile"
    sudo chown cad $recordFile
    sudo chmod o-w $recordFile
fi

