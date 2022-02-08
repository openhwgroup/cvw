#!/bin/bash
tcpPort=1234
imageDir=$RISCV/buildroot/output/images
outDir=$RISCV/linux-testvectors
recordFile="$outDir/all.qemu"
traceFile="$outDir/all.txt"

read -p "Warning: running this script will overwrite the contents of:
  * $recordFile
  * $traceFile
Would you like to proceed? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Create Output Directory
    sudo mkdir -p $outDir
    sudo chown cad $outDir
    sudo touch $recordFile 
    sudo touch $traceFile 
    sudo chmod a+rw $recordFile
    sudo chmod a+rw $traceFile

    # Compile Devicetree from Source
    dtc -I dts -O dtb ../devicetree/virt-trimmed.dts > ../devicetree/virt-trimmed.dtb

    # QEMU Simulation
    (qemu-system-riscv64 \
    -M virt -dtb ../devicetree/virt-trimmed.dtb \
    -nographic -serial /dev/null \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on,rr=record,rrfile=$recordFile \
    -d nochain,cpu,in_asm \
    -gdb tcp::$tcpPort -S \
    2>&1 >/dev/null | ./parseQemuToGDB.py | ./parseGDBtoTrace.py | ./remove_dup.awk > $traceFile) \
    & riscv64-unknown-elf-gdb -quiet -x genTrace.gdb -ex "genTrace $tcpPort \"$imageDir/vmlinux\""

    # Cleanup
    sudo chown cad $recordFile
    sudo chown cad $traceFile
    sudo chmod o-w $recordFile
    sudo chmod o-w $traceFile
fi

