(qemu-system-riscv64 -M virt -nographic -bios /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/fw_jump.elf -kernel /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/Image -append "root=/dev/vda ro" -initrd /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -s -S 2>/dev/null >/dev/null ) &
riscv64-unknown-elf-gdb -x gdbinit_mem
#sed -i '$d' $file
echo "Done"
