#!/bin/bash
# Oftentimes this script runs so long you'll go to sleep.
# But you don't want the script to die when your computer goes to sleep.
# So consider invoking this with nohup (i.e. "nohup ./logAllBuildroot.sh")
# You can run "tail -f nohup.out" to see what would've
# outputted to the terminal if you didn't use nohup

#customQemu="/courses/e190ax/qemu_sim/rv64_initrd/qemu_experimental/qemu/build/qemu-system-riscv64"
customQemu="qemu-system-riscv64"
imageDir="../buildroot-image-output"
intermedDir="../linux-testvectors/intermediate-outputs"
outDir="../linux-testvectors"

# - Logs info needed by buildroot testbench
#($customQemu -M virt -nographic -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -gdb tcp::1236 -S 2>&1 >/dev/null | ./parseNew.py "$outDir") & riscv64-unknown-elf-gdb -x gdbinit_qemulog
#./fix_csrs.py "$outDir"

($customQemu -M virt -nographic -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -gdb tcp::1236 -S 2>&1 >/dev/null | ./parse_qemu.py | ./parseNew.py | ./remove_dup.awk > all.txt) & riscv64-unknown-elf-gdb -x gdbinit_qemulog
