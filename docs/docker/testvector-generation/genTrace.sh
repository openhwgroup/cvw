#!/bin/bash
tcpPort=1234
imageDir=$RISCV/buildroot/output/images
tvDir=$RISCV/linux-testvectors
recordFile="$tvDir/all.qemu"
traceFile="$tvDir/all.txt"
trapsFile="$tvDir/traps.txt"
interruptsFile="$tvDir/interrupts.txt"
DEVICE_TREE=${imageDir}/wally-virt.dtb

read -p "Warning: running this script will overwrite the contents of:
  * $traceFile
  * $trapsFile
  * $interruptsFile
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

    touch $traceFile 
    touch $trapsFile 
    touch $interruptsFile 

    # QEMU Simulation
    echo "Launching QEMU in replay mode!"
    (qemu-system-riscv64 \
    -M virt -m 256M -dtb $DEVICE_TREE \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on,rr=replay,rrfile=$recordFile \
    -d nochain,cpu,in_asm,int \
    2>&1 >./qemu-serial | ./parseQEMUtoGDB.py | ./parseGDBtoTrace.py $trapsFile > $traceFile)

    ./filterTrapsToInterrupts.py $tvDir

    echo "genTrace.sh completed!"
    echo "You may want to restrict write access to $tvDir now and give cad ownership of it."
    echo "Run the following:"
    echo "    sudo chown -R cad:cad $tvDir"
    echo "    sudo chmod -R go-w $tvDir"
fi
