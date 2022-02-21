all:
	make disassemble
	make generate

generate:
	# generating device tree binary
	dtc -I dts -O dtb ../devicetree/wally-virt.dts > ${RISCV}/buildroot/output/images/wally-virt.dtb

disassemble:
	mkdir ${RISCV}/buildroot/output/images/disassembly
	# fw_jump
	riscv64-unknown-elf-objdump -D ${RISCV}/buildroot/output/images/fw_jump.elf >> ${RISCV}/buildroot/output/images/disassembly/fw_jump.objdump
	# vmlinux
	riscv64-unknown-elf-objdump -D ${RISCV}/buildroot/output/images/vmlinux >> ${RISCV}/buildroot/output/images/disassembly/vmlinux.objdump
	# filesystem
	mkdir ${RISCV}/buildroot/output/images/disassembly/rootfs
	-cd ${RISCV}/buildroot/output/images/disassembly/rootfs; cpio -idv < ../../rootfs.cpio

clean:
	rm ${RISCV}/buildroot/output/images/wally-virt.dtb
	rm -rf ${RISCV}/buildroot/output/images/disassembly
