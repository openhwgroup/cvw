#!/bin/bash
###########################################
## GitHub runner create LVM volume merging /mnt with / for more space
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: 30 Jan 2025
## Based on https://github.com/easimon/maximize-build-space/blob/master/action.yml
##
## Purpose: Combine free space from multiple disks into a single logical volume for GitHub Actions runner
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
## except in compliance with the License, or, at your option, the Apache License version 2.0. You
## may obtain a copy of the License at
##
## https:##solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
## either express or implied. See the License for the specific language governing permissions
## and limitations under the License.
################################################################################################

ROOT_SAVE_SPACE="${1:-20}" # in GB, needed for installing packages, etc.
MOUNT="${2:-$GITHUB_WORKSPACE}"

# First disable and remove swap file on /mnt
sudo swapoff -a
sudo rm -f /mnt/swapfile

# Create / LVM physical volume
ROOT_FREE_SPACE=$(df --block-size=1024 --output=avail / | tail -1)
ROOT_LVM_SIZE=$(((ROOT_FREE_SPACE - (ROOT_SAVE_SPACE * 1024 * 1024)) * 1024))
sudo touch /pv.img && sudo fallocate -z -l $ROOT_LVM_SIZE /pv.img
ROOT_LOOP_DEV=$(sudo losetup --find --show /pv.img)
sudo pvcreate -f "$ROOT_LOOP_DEV"

# Create /mnt LVM physical volume
MNT_FREE_SPACE=$(df --block-size=1024 --output=avail /mnt | tail -1)
MNT_LVM_SIZE=$(((MNT_FREE_SPACE - (1 * 1024)) * 1024)) # Leave 1MB free on /mnt
sudo touch /mnt/pv.img && sudo fallocate -z -l $MNT_LVM_SIZE /mnt/pv.img
MNT_LOOP_DEV=$(sudo losetup --find --show /mnt/pv.img)
sudo pvcreate -f "$MNT_LOOP_DEV"

# Create LVM volume group
sudo vgcreate runnervg "$ROOT_LOOP_DEV" "$MNT_LOOP_DEV"

# Recreate swap
sudo lvcreate -L 4G -n swap runnervg
sudo mkswap /dev/mapper/runnervg-swap
sudo swapon /dev/mapper/runnervg-swap

# Create LVM logical volume
sudo lvcreate -l 100%FREE -n runnerlv runnervg
sudo mkfs.ext4 /dev/mapper/runnervg-runnerlv
sudo mkdir -p "$MOUNT"
sudo mount /dev/mapper/runnervg-runnerlv "$MOUNT"
sudo chown runner:runner "$MOUNT"
sudo rm -rf "$MOUNT/lost+found"
