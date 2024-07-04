#!/bin/bash
###########################################
## Package installation
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: 30 June 2024
## Modified:
##
## Purpose: Package manager installation for open source tool chain installation script
##
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
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

set -e # break on error

# Colors
BOLD='\033[1m'
SECTION_COLOR='\033[95m'$BOLD
SUCCESS_COLOR='\033[92m'
FAIL_COLOR='\033[91m'
ENDC='\033[0m' # Reset to default color

# If run standalone, determine distro information. Otherwise, use info from main install script
if [ -z "$FAMILY" ]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${dir}"/wally-distro-check.sh
fi


# Generate list of packages to install and package manager commands based on distro
# Packages are grouped by which tool requires them. If multiple tools need a package, it is included in the first tool only
if [ "$FAMILY" = rhel ]; then
    PACKAGE_MANAGER="dnf"
    UPDATE_COMMAND="sudo dnf update -y"
    GENERAL_PACKAGES="git make cmake python3.12 python3-pip curl wget ftp tar pkgconf-pkg-config dialog mutt ssmtp"
    GNU_PACKAGES="autoconf automake  libmpc-devel mpfr-devel gmp-devel gawk bison flex texinfo gperf libtool patchutils bc gcc gcc-c++ zlib-devel expat-devel libslirp-devel"
    QEMU_PACKAGES="glib2-devel libfdt-devel pixman-devel bzip2 ninja-build"
    SPIKE_PACKAGES="dtc boost-regex boost-system"
    VERILATOR_PACKAGES="help2man perl clang ccache gperftools numactl mold"
    BUILDROOT_PACKAGES="ncurses-base ncurses ncurses-libs ncurses-devel gcc-gfortran"
    # Extra packages not availale in rhel8, nice for Verilator and needed for sail respectively
    if [ "$RHEL_VERSION" = 9 ]; then
        VERILATOR_PACKAGES="$VERILATOR_PACKAGES perl-doc"
        SAIL_PACKAGES="z3"
    fi
    # A newer version of gcc is required for qemu
    OTHER_PACKAGES="gcc-toolset-13"
elif [ "$FAMILY" = ubuntu ]; then
    PACKAGE_MANAGER=apt
    UPDATE_COMMAND="sudo apt update -y && sudo apt upgrade -y"
    GENERAL_PACKAGES="git make cmake python3 python3-pip python3-venv curl wget ftp tar pkg-config dialog mutt ssmtp"
    GNU_PACKAGES="autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat1-dev ninja-build libglib2.0-dev libslirp-dev"
    QEMU_PACKAGES="libfdt-dev libpixman-1-dev"
    SPIKE_PACKAGES="device-tree-compiler libboost-regex-dev libboost-system-dev"
    VERILATOR_PACKAGES="help2man perl g++ clang ccache libgoogle-perftools-dev numactl perl-doc libfl2 libfl-dev zlib1g"
    SAIL_PACKAGES="opam z3"
    BUILDROOT_PACKAGES="ncurses-base ncurses-bin libncurses-dev gfortran"
    # Extra packages not availale in Ubuntu 20.04, nice for Verilator
    if (( UBUNTU_VERSION >= 22 )); then
        VERILATOR_PACKAGES="$VERILATOR_PACKAGES mold"
    fi
    # Newer version of gcc needed for Ubuntu 20.04 for Verilator
    if [ "$UBUNTU_VERSION" = 20 ]; then
        OTHER_PACKAGES="gcc-10 g++-10 cpp-10"
    fi
fi


# Check if required packages are installed or install/update them depending on passed flag.
if [ "${1}" = "--check" ]; then
    echo -e "${SECTION_COLOR}\n*************************************************************************"
    echo -e "*************************************************************************"
    echo -e "Checking Dependencies from Package Manager"
    echo -e "*************************************************************************"
    echo -e "*************************************************************************\n${ENDC}"
    if [ "$FAMILY" = rhel ]; then
        for pack in $GENERAL_PACKAGES $GNU_PACKAGES $QEMU_PACKAGES $SPIKE_PACKAGES $VERILATOR_PACKAGES $SAIL_PACKAGES $BUILDROOT_PACKAGES $OTHER_PACKAGES; do
            rpm -q "$pack" > /dev/null || (echo -e "${FAIL_COLOR}Missing packages detected (${WARNING_COLOR}$pack${FAIL_COLOR}). Run as root to auto-install or run wally-package-install.sh first.${ENDC}" && exit 1)
        done
    elif [ "$FAMILY" = ubuntu ]; then
        for pack in $GENERAL_PACKAGES $GNU_PACKAGES $QEMU_PACKAGES $SPIKE_PACKAGES $VERILATOR_PACKAGES $SAIL_PACKAGES $BUILDROOT_PACKAGES $OTHER_PACKAGES; do
            dpkg -l "$pack" | grep "ii" > /dev/null || (echo -e "${FAIL_COLOR}Missing packages detected (${WARNING_COLOR}$pack${FAIL_COLOR}). Run as root to auto-install or run wally-package-install.sh first." && exit 1)
        done
    fi
    echo -e "${OK_COLOR}All required packages detected.${ENDC}"
else
    # Check if root, otherwise exit with error message
    [ "${EUID:=$(id -u)}" -ne 0 ] && echo -e "\n${FAIL_COLOR}Must be run as root${ENDC}" && exit 1

    echo -e "${SECTION_COLOR}\n*************************************************************************"
    echo -e "*************************************************************************"
    echo -e "Installing/Updating Dependencies from Package Manager"
    echo -e "*************************************************************************"
    echo -e "*************************************************************************\n${ENDC}"
    # Enable extra repos necessary for rhel
    if [ "$FAMILY" = rhel ]; then
        sudo dnf install -y dnf-plugins-core
        sudo dnf group install -y "Development Tools"
        if [ "$ID" = rhel ]; then
            sudo subscription-manager repos --enable "codeready-builder-for-rhel-$RHEL_VERSION-$(arch)-rpms"
            sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$RHEL_VERSION.noarch.rpm"
        else # RHEL clone
            if [ "$RHEL_VERSION" = 8 ]; then
                sudo dnf config-manager -y --set-enabled powertools
            else # Version 9
                sudo dnf config-manager -y --set-enabled crb
            fi
            sudo dnf install -y epel-release
        fi
    fi

    # Update and Upgrade tools
    eval "$UPDATE_COMMAND"
    # Install packages listed above using appropriate package manager
    sudo "$PACKAGE_MANAGER" install -y $GENERAL_PACKAGES $GNU_PACKAGES $QEMU_PACKAGES $SPIKE_PACKAGES $VERILATOR_PACKAGES $SAIL_PACKAGES $BUILDROOT_PACKAGES $OTHER_PACKAGES
    echo -e "${SUCCESS_COLOR}Packages successfully installed.${ENDC}"
fi
