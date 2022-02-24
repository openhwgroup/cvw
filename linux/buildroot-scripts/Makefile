IMAGES := ${RISCV}/buildroot/output/images
DIS := ${IMAGES}/disassembly

all:
	make disassemble
	make generate

generate:
	# generating device tree binary
	dtc -I dts -O dtb ../devicetree/wally-virt.dts > ${RISCV}/buildroot/output/images/wally-virt.dtb

disassemble:
	mkdir -p ${DIS}
	make -j ${DIS}/fw_jump.objdump ${DIS}/vmlinux.objdump
	# filesystem
	mkdir ${RISCV}/buildroot/output/images/disassembly/rootfs
	-cd ${RISCV}/buildroot/output/images/disassembly/rootfs; cpio -id --nonmatching 'dev/console' < ../../rootfs.cpio
	riscv64-unknown-elf-objdump -D ${RISCV}/buildroot/output/images/disassembly/rootfs/bin/busybox >> ${RISCV}/buildroot/output/images/disassembly/busybox.objdump

${DIS}/fw_jump.objdump: ${IMAGES}/fw_jump.elf
	riscv64-unknown-elf-objdump -D ${RISCV}/buildroot/output/images/fw_jump.elf >> ${RISCV}/buildroot/output/images/disassembly/fw_jump.objdump
${DIS}/vmlinux.objdump: ${IMAGES}/vmlinux
	riscv64-unknown-elf-objdump -D ${RISCV}/buildroot/output/images/vmlinux >> ${RISCV}/buildroot/output/images/disassembly/vmlinux.objdump

clean:
	rm -f ${IMAGES}/wally-virt.dtb
	rm -rf ${DIS}
