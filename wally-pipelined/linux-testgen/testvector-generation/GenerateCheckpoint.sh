#!/bin/bash
# Oftentimes this script runs so long you'll go to sleep.
# But you don't want the script to die when your computer goes to sleep.
# So consider invoking this with nohup (i.e. "nohup ./logAllBuildroot.sh")
# You can run "tail -f nohup.out" to see what would've
# outputted to the terminal if you didn't use nohup

# use on tera.
customQemu="/courses/e190ax/qemu_sim/rv64_initrd/qemu_experimental/qemu/build/qemu-system-riscv64"
# use on other systems
#customQemu="qemu-system-riscv64"

instrs=8500000

imageDir="../buildroot-image-output"
outDir="../linux-testvectors/checkpoint$instrs"
intermedDir="$outDir/intermediate-outputs"


read -p "This scripts is going to create a checkpoint at $instrs instrs.
Is that what you wanted? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mkdir -p $outDir
    mkdir -p $intermedDir
    ($customQemu -M virt -nographic -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio -rtc clock=vm -icount shift=1 -d nochain,cpu,in_asm -serial /dev/null -singlestep -gdb tcp::1240 -S 2>&1 1>&2 | ./parse_qemu.py | ./parseNew.py | ./remove_dup.awk > $intermedDir/rawTrace.txt) & riscv64-unknown-elf-gdb -x ./checkpoint.gdb -ex "createCheckpoint $instrs \"$intermedDir\""
    ./fix_mem.py "$intermedDir/ramGDB.txt" "$outDir/ram.txt"
    ./parseState.py "$outDir"
else
    echo "You can change the number of instructions by editing the \"instrs\" variable in this script."
    echo "Have a nice day!"
fi
