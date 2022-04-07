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
	# disassemblies
	make -j ${DIS}/fw_jump.objdump ${DIS}/vmlinux.objdump ${DIS}/busybox.objdump ${DIS}/vmlinux.objdump.addr
	# filesystem
	make ${DIS}/rootfs/bin/busybox
	# mkdir -p ${DIS}/rootfs
	# -cd ${DIS}/rootfs; cpio -id --nonmatching 'dev/console' < ../../rootfs.cpio

${DIS}/fw_jump.objdump: ${IMAGES}/fw_jump.elf
	riscv64-unknown-elf-objdump -S ${IMAGES}/fw_jump.elf >> ${DIS}/fw_jump.objdump

${DIS}/vmlinux.objdump: ${IMAGES}/vmlinux
	riscv64-unknown-elf-objdump -S ${IMAGES}/vmlinux >> ${DIS}/vmlinux.objdump

${DIS}/vmlinux.objdump.addr: ${DIS}/vmlinux.objdump
	-cd ${DIS}; extractFunctionRadix.sh vmlinux.objdump

${DIS}/busybox.objdump: ${DIS}/rootfs/bin/busybox
	riscv64-unknown-elf-objdump -S ${DIS}/rootfs/bin/busybox >> ${DIS}/busybox.objdump

${DIS}/rootfs/bin/busybox:
	mkdir -p ${DIS}/rootfs
	-cd ${DIS}/rootfs; cpio -id --nonmatching 'dev/console' < ../../rootfs.cpio


clean:
	rm -f ${IMAGES}/wally-virt.dtb
	rm -rf ${DIS}
