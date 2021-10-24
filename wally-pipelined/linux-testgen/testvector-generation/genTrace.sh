#!/bin/bash
source genSettings.sh
tcpPort=1234

read -p "Warning: running this script will overwrite the contents of:
  $outDir/$traceFile
  $outDir/$recordFile
Would you like to proceed? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mkdir -p $outDir
    mkdir -p $intermedDir
    ($customQemu \
    -M virt \
    -nographic -serial /dev/null \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=1,align=off,sleep=on,rr=record,rrfile="$intermedDir/$recordFile" \
    -d nochain,cpu,in_asm \
    -gdb tcp::$tcpPort -S \
    2>&1 >/dev/null | ./parseQemuToGDB.py | ./parseGDBtoTrace.py | ./remove_dup.awk > "$outDir/$traceFile") \
    & riscv64-unknown-elf-gdb -quiet -x genTrace.gdb -ex "genTrace $tcpPort"
fi

