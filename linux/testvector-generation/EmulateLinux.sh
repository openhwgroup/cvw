#!/bin/bash

usage() { echo "Usage: $0 [-h] [-b <path/to/buildroot>] [-d <path/to/device tree>]" 1>&2; exit 1; }

help() {
    echo "Usage: $0 [OPTIONS] <device>"
    echo "  -b <path/to/buildroot>      get images from given buildroot"
    echo "  -d <device tree name>       specify device tree to use"
    exit 0;
}

# defaults
imageDir=$RISCV/buildroot/output/images
DEVICE_TREE=${imageDir}/wally-virt.dtb

# Process options and arguments. The following code grabs the single
# sdcard device argument no matter where it is in the positional
# parameters list.
ARGS=()
while [ $OPTIND -le "$#" ] ; do
    if getopts "hb:d:" arg ; then
        case "${arg}" in
            h) help
               ;;
            b) BUILDROOT=${OPTARG}
               ;;
            d) DEVICE_TREE=${OPTARG}
               ;;
        esac
    else
        ARGS+=("${!OPTIND}")
        ((OPTIND++))
    fi
done

# File location variables
imageDir=$BUILDROOT/output/images

tvDir=$RISCV/linux-testvectors
tcpPort=1239

# QEMU Simulation
qemu-system-riscv64 \
-M virt -m 256M -dtb $DEVICE_TREE \
-nographic \
-bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro"
-singlestep -rtc clock=vm -icount shift=0,align=off,sleep=on 
