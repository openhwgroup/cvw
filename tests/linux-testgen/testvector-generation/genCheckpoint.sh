#!/bin/bash

source  genSettings.sh
tcpPort=1236

instrs=450000000
checkOutDir="$outDir/checkpoint$instrs"
checkIntermedDir="$checkOutDir/intermediate-outputs"


read -p "This scripts is going to create a checkpoint at $instrs instrs.
Is that what you wanted? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mkdir -p $checkOutDir
    mkdir -p $checkIntermedDir
    instr=$(sed "${instrs}q;d" "../linux-testvectors/all.txt")
    echo "Found ${instrs}th instr: ${instr}."
    pc=$(echo $instr | cut -d " " -f1)
    asm=$(echo $instr | cut -d " " -f2)
    occurences=$(($(head -$instrs "../linux-testvectors/all.txt" | grep -c "${pc} ${asm}")-1))
    echo "It occurs ${occurences} times before the ${instrs}th instr." 
    # Simulate QEMU, parse QEMU trace, run GDB script which logs a bunch of data at the checkpoint
    ($customQemu \
    -M virt \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=1,align=off,sleep=on,rr=replay,rrfile="$intermedDir/$recordFile" \
    -gdb tcp::$tcpPort -S) \
    & riscv64-unknown-elf-gdb -x genCheckpoint.gdb -ex "genCheckpoint $tcpPort $instrs \"$checkIntermedDir\" \"$pc\" $occurences"
    # Post-Process GDB outputs
    ./parseState.py "$checkOutDir"
    ./fix_mem.py "$checkIntermedDir/ramGDB.txt" "$checkOutDir/ram.txt"
    tail -n+$($instrs+1) "$outDir/$traceFile" > "$checkOutDir/$traceFile"
else
    echo "You can change the number of instructions by editing the \"instrs\" variable in this script."
    echo "Have a nice day!"
fi
