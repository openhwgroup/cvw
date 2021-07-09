customQemu="/courses/e190ax/qemu_sim/rv64_initrd/qemu_experimental/qemu/build/qemu-system-riscv64"
imageDir="../buildroot-image-output"
($customQemu -M virt -nographic -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -s -S 2>/dev/null >/dev/null) &
riscv64-unknown-elf-gdb -x gdbinit_mem
echo "Translating Mem from GDB to Questa format"
./fix_mem.py
echo "Done"
