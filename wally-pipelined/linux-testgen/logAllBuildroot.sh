# Oftentimes this script runs so long you'll go to sleep.
# But you don't want the script to die when your computer goes to sleep.
# So consider invoking this with nohup (i.e. "nohup ./logAllBuildroot.sh")
# You can run "tail -f nohup.out" to see what would've
# outputted to the terminal if you didn't use nohup

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

# Uncomment this version in case you just want to have qemu_in_gdb_format.txt around
# It is often helpful for general debugging
(qemu-system-riscv64 -M virt -nographic -bios /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/fw_jump.elf -kernel /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/Image -append "root=/dev/vda ro" -initrd /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -s -S 2>&1 >/dev/null | ./parse_qemu.py >/courses/e190ax/buildroot_boot/qemu_in_gdb_format.txt) & riscv64-unknown-elf-gdb -x gdbinit_qemulog
# Split qemu_in_gdb_format.txt into chunks of 100,000 instructions for easier inspection
#cd /courses/e190ax/buildroot_boot
#split -d -l 5600000 qemu_in_gdb_format.txt --verbose

# Uncomment this version for parse_gdb_output.py debugging
# - Uses qemu_in_gdb_format.txt
# - Logs info needed by buildroot testbench
#cat qemu_in_gdb_format.txt | ./parse_gdb_output.py "/courses/e190ax/buildroot_boot/"

# =========== Just Do the Thing ========== 
# Uncomment this version for the whole thing 
# - Logs info needed by buildroot testbench
#(qemu-system-riscv64 -M virt -nographic -bios /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/fw_jump.elf -kernel /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/Image -append "root=/dev/vda ro" -initrd /courses/e190ax/qemu_sim/rv64_initrd/buildroot_experimental/output/images/rootfs.cpio -d nochain,cpu,in_asm -serial /dev/null -singlestep -s -S 2>&1 >/dev/null | ./parse_qemu.py | ./parse_gdb_output.py "/courses/e190ax/buildroot_boot_new/") & riscv64-unknown-elf-gdb -x gdbinit_qemulog
