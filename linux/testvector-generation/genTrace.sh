#!/bin/bash
tcpPort=1234
imageDir=$RISCV/buildroot/output/images
tvDir=$RISCV/linux-testvectors
recordFile="$tvDir/all.qemu"
traceFile="$tvDir/all.txt"
interruptsFile="$tvDir/interrupts.txt"

read -p "Warning: running this script will overwrite the contents of:
  * $traceFile
  * $interruptsFile
Would you like to proceed? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Create Output Directory
    echo "Elevating permissions to create $traceFile, $interruptsFile"
    sudo mkdir -p $tvDir
    sudo chown cad $tvDir
    sudo touch $traceFile 
    sudo touch $interruptsFile 
    sudo chmod a+rw $traceFile
    sudo chmod a+rw $interruptsFile

    # Compile Devicetree from Source
    dtc -I dts -O dtb ../devicetree/wally-virt.dts > ../devicetree/wally-virt.dtb

    # QEMU Simulation
    echo "Launching QEMU in replay mode!"
    (qemu-system-riscv64 \
    -M virt -dtb ../devicetree/wally-virt.dtb \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on,rr=replay,rrfile=$recordFile \
    -d nochain,cpu,in_asm,int \
    2>&1 >/dev/null | ./parseQEMUtoGDB.py | ./parseGDBtoTrace.py $interruptsFile | ./remove_dup.awk > $traceFile)

    # Cleanup
    echo "Elevating permissions to restrict write access to $traceFile, $interruptsFile"
    sudo chown cad $traceFile
    sudo chown cad $interruptsFile
    sudo chmod o-w $traceFile
    sudo chmod o-w $interruptsFile
fi
