# =========== Debug the Process ========== 
# Uncomment this version for GDB/QEMU debugging
# - Opens up GDB interactively
# - Logs raw QEMU output to qemu_output.txt
#(qemu-system-riscv64 -M virt -nographic -bios /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/fw_jump.elf -kernel /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/Image -append "root=/dev/vda ro" -initrd /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -s -S 2> qemu_output.txt) & riscv64-unknown-elf-gdb

# Uncomment this version to generate qemu_output.txt
# - Uses GDB script
# - Logs raw QEMU output to qemu_output.txt
#(qemu-system-riscv64 -M virt -nographic -bios /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/fw_jump.elf -kernel /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/Image -append "root=/dev/vda ro" -initrd /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -s -S 2>qemu_output.txt) & riscv64-unknown-elf-gdb -x gdbinit_qemulog_debug

# Uncomment this version for parse_qemu.py debugging
# - Uses qemu_output.txt
# - Makes qemu_in_gdb_format.txt
# - Logs parse_qemu.py's simulated gdb output to qemu_in_gdb_format.txt
#cat qemu_output.txt | ./parse_qemu.py >qemu_in_gdb_format.txt
#cat qemu_output.txt | ./parse_qemu.py | ./parse_gdb_output.py "/courses/e190ax/buildroot_boot/"

# Uncomment this version for parse_gdb_output.py debugging
# - Uses qemu_in_gdb_format.txt
# - Logs info needed by buildroot testbench
#cat qemu_in_gdb_format.txt | ./parse_gdb_output.py "/courses/e190ax/buildroot_boot/"

# =========== Just Do the Thing ========== 
# Uncomment this version for the whole thing 
# - Logs info needed by buildroot testbench
(qemu-system-riscv64 -M virt -nographic -bios /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/fw_jump.elf -kernel /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/Image -append "root=/dev/vda ro" -initrd /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -s -S 2>&1 >/dev/null | pv -l | ./parse_qemu.py | ./parse_gdb_output.py "/courses/e190ax/buildroot_boot/") & riscv64-unknown-elf-gdb -x gdbinit_qemulog
