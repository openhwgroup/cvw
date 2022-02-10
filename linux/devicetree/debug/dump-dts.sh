#!/bin/bash
machine=virt

qemu-system-riscv64 -M $machine,dumpdtb=$machine.dtb -bios $RISCV/buildroot/output/images/fw_jump.elf

dtc -I dtb -O dts $machine.dtb > $machine.dts
