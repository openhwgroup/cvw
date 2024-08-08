#!/bin/bash

# Exit on any error (return code != 0)
set -e

# Output colors
GREEN='\033[1;32m'
NC='\033[0m'
NAME="$GREEN"${0:2}"$NC"

# File location variables
IMAGES=$RISCV/buildroot/output/images
FW_JUMP=$IMAGES/fw_jump.bin
LINUX_KERNEL=$IMAGES/Image
DEVICE_TREE=$IMAGES/wally-vcu108.dtb

# Mount Directory
MNT_DIR=wallyimg

if [ ! -z "$2" ] ; then
    MNT_DIR=$2
fi

# If images are not built, exit
if [ ! -e $FW_JUMP ] || [ ! -e $LINUX_KERNEL ] ; then
    echo 'ERROR: Missing images in buildroot output directory.'
    echo '       Build images before running this script.'
    exit 1
fi

if [ ! -e $DEVICE_TREE ] ; then
    echo 'ERROR: Missing device tree file'
    exit 1
fi

# Size of OpenSBI and the Kernel in 512B blocks
DST_SIZE=$(ls -la --block-size=512 $DEVICE_TREE | cut -d' ' -f 5 ) 
FW_JUMP_SIZE=$(ls -la --block-size=512 $FW_JUMP | cut -d' ' -f 5 )
KERNEL_SIZE=$(ls -la --block-size=512 $LINUX_KERNEL | cut -d' ' -f 5 )

# Start sectors of OpenSBI and Kernel Partitions
FW_JUMP_START=$(( 34 + $DST_SIZE ))
KERNEL_START=$(( $FW_JUMP_START + $FW_JUMP_SIZE ))
FS_START=$(( $KERNEL_START + $KERNEL_SIZE ))

# Print out the sizes of the binaries in 512B blocks
echo -e "$NAME: Device tree block size:     $DST_SIZE"
echo -e "$NAME: OpenSBI FW_JUMP block size: $FW_JUMP_SIZE"
echo -e "$NAME: Kernel block size:          $KERNEL_SIZE"

if [ ! -e $1 ] ; then
    # Make empty image
    echo -e "$NAME: Creating blank image"
    sudo dd if=/dev/zero of=$1 bs=1M count=1536

    # GUID Partition Tables (GPT)
    # ===============================================
    # -g Converts any existing mbr record to a gpt record
    # --clear clears any GPT partition table that already exists.
    # --set-alignment=1 that we want to align partition starting sectors
    # to 1 sector boundaries I think? This would normally be set to 2048
    # apparently.

    # sudo sgdisk -g --clear --set-alignment=1 \
    #      --new=1:34:+$FW_JUMP_SIZE: --change-name=1:'opensbi' --typecode=1:2E54B353-1271-4842-806F-E436D6AF6985 \
    #      --new=2:$KERNEL_START:+$KERNEL_SIZE --change-name=2:'kernel' --typecode=2:3000 \
    #      --new=3:$FS_START:-0 --change-name=3:'filesystem' \
    #      $1

    # echo -e "$NAME: Creating GUID Partition Table"
    # sudo sgdisk -g --clear --set-alignment=1 \
    #      --new=1:34:+$DST_SIZE: --change-name=1:'fdt' \
    #      --new=2:$FW_JUMP_START:+$FW_JUMP_SIZE --change-name=2:'opensbi' --typecode=1:2E54B353-1271-4842-806F-E436D6AF6985 \
    #      --new=3:$KERNEL_START:+$KERNEL_SIZE --change-name=3:'kernel' \
    #      --new=4:$FS_START:-0 --change-name=4:'filesystem' \
    #      $1

    echo -e "$NAME: Creating GUID Partition Table"
    sudo sgdisk -g --clear --set-alignment=1 \
         --new=1:34:+$DST_SIZE: --change-name=1:'fdt' \
         --new=2:$FW_JUMP_START:+$FW_JUMP_SIZE --change-name=2:'opensbi' --typecode=1:2E54B353-1271-4842-806F-E436D6AF6985 \
         --new=3:$KERNEL_START:+$KERNEL_SIZE --change-name=3:'kernel' \
         $1

    LOOPDEVICE=$(sudo losetup -f)
    echo -e "$NAME: Loop device: $LOOPDEVICE"

    sudo losetup --partscan $LOOPDEVICE $1

    echo -e "$NAME: Copying binaries into their partitions."
    DD_FLAGS="bs=4k iflag=fullblock oflag=direct conv=fsync status=progress"
    # Store device tree in device tree partition

    echo -e "$NAME: Copying device tree"
    sudo dd if=$DEVICE_TREE of="$LOOPDEVICE"p1 $DD_FLAGS

    echo -e "$NAME: Copying OpenSBI"
    sudo dd if=$FW_JUMP of="$LOOPDEVICE"p2 $DD_FLAGS

    echo -e "$NAME: Copying Kernel"
    sudo dd if=$LINUX_KERNEL of="$LOOPDEVICE"p3 $DD_FLAGS

    # sudo mkfs.ext4 "$LOOPDEVICE"p4
    # sudo mkdir /mnt/$MNT_DIR

    # sudo mount -v "$LOOPDEVICE"p4 /mnt/$MNT_DIR 

    # sudo umount -v /mnt/$MNT_DIR

    # sudo rmdir /mnt/$MNT_DIR
    sudo losetup -d $LOOPDEVICE
fi

echo
echo "GPT Information for $1 ==================================="
sgdisk -p $1
