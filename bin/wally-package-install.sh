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


# Packages are grouped by which tool requires them. If multiple tools need a package, it is included in the first tool only
# Packages that are constant across distros
GENERAL_PACKAGES+=(rsync git make cmake curl wget tar unzip bzip2 dialog mutt)
GNU_PACKAGES+=(autoconf automake gawk bison flex texinfo gperf libtool patchutils bc gcc)
VERILATOR_PACKAGES+=(help2man perl clang ccache numactl)
BUILDROOT_PACKAGES+=(cpio)

# Distro specific packages and package manager
case "$FAMILY" in
    rhel)
        PYTHON_VERSION=python3.12
        PACKAGE_MANAGER="dnf -y"
        UPDATE_COMMAND="$PACKAGE_MANAGER update"
        GENERAL_PACKAGES+=(which "$PYTHON_VERSION" "$PYTHON_VERSION"-pip pkgconf-pkg-config gcc-c++ ssmtp)
        GNU_PACKAGES+=(libmpc-devel mpfr-devel gmp-devel zlib-devel expat-devel libslirp-devel ninja-build)
        QEMU_PACKAGES+=(glib2-devel libfdt-devel pixman-devel)
        SPIKE_PACKAGES+=(dtc boost-regex boost-system)
        VERILATOR_PACKAGES+=(gperftools mold)
        BUILDROOT_PACKAGES+=(ncurses ncurses-base ncurses-libs ncurses-devel gcc-gfortran) # gcc-gfortran is only needed for compiling spec benchmarks on buildroot linux
        # Extra packages not availale in rhel8, nice for Verilator
        if (( RHEL_VERSION >= 9 )); then
            VERILATOR_PACKAGES+=(perl-doc)
        fi
        # A newer version of gcc is required for qemu
        OTHER_PACKAGES+=(gcc-toolset-13)
        ;;
    ubuntu | debian)
        if (( UBUNTU_VERSION >= 24 )); then
            PYTHON_VERSION=python3.12
        elif (( UBUNTU_VERSION >= 22 )); then
            PYTHON_VERSION=python3.11
        elif (( UBUNTU_VERSION >= 20 )); then
            PYTHON_VERSION=python3.9
            OTHER_PACKAGES+=(gcc-10 g++-10 cpp-10) # Newer version of gcc needed for Verilator
        elif (( DEBIAN_VERSION >= 12 )); then
            PYTHON_VERSION=python3.11
        elif (( DEBIAN_VERSION >= 11 )); then
            PYTHON_VERSION=python3.9
        fi
        # Mold not available in older distros for Verilator, will download binary instead
        if (( UBUNTU_VERSION != 20 && DEBIAN_VERSION != 11 )); then
            VERILATOR_PACKAGES+=(mold)
        fi
        PACKAGE_MANAGER="DEBIAN_FRONTEND=noninteractive apt-get -y"
        UPDATE_COMMAND="$PACKAGE_MANAGER update && $PACKAGE_MANAGER upgrade --with-new-pkgs"
        GENERAL_PACKAGES+=("$PYTHON_VERSION" python3-pip "$PYTHON_VERSION"-venv pkg-config g++ ssmtp)
        GNU_PACKAGES+=(autotools-dev libmpc-dev libmpfr-dev libgmp-dev build-essential ninja-build zlib1g-dev libexpat1-dev libglib2.0-dev libslirp-dev)
        QEMU_PACKAGES+=(libfdt-dev libpixman-1-dev)
        SPIKE_PACKAGES+=(device-tree-compiler libboost-regex-dev libboost-system-dev)
        VERILATOR_PACKAGES+=(libunwind-dev libgoogle-perftools-dev perl-doc libfl2 libfl-dev zlib1g)
        BUILDROOT_PACKAGES+=(ncurses-base ncurses-bin libncurses-dev gfortran) # gfortran is only needed for compiling spec benchmarks on buildroot linux
        VIVADO_PACKAGES+=(libncurses*) # Vivado hangs on the third stage of installation without this
        ;;
    suse)
        PYTHON_VERSION=python3.12
        PYTHON_VERSION_PACKAGE=python312
        PACKAGE_MANAGER="zypper -n"
        UPDATE_COMMAND="$PACKAGE_MANAGER update"
        GENERAL_PACKAGES+=("$PYTHON_VERSION_PACKAGE" "$PYTHON_VERSION_PACKAGE"-pip pkg-config)
        GNU_PACKAGES+=(mpc-devel mpfr-devel gmp-devel zlib-devel libexpat-devel libslirp-devel ninja)
        QEMU_PACKAGES+=(glib2-devel libpixman-1-0-devel) # maybe also need qemu itself?
        SPIKE_PACKAGES+=(dtc libboost_regex1_75_0-devel libboost_system1_75_0-devel)
        VERILATOR_PACKAGES+=(gperftools perl-doc)
        BUILDROOT_PACKAGES+=(ncurses-utils ncurses-devel ncurses5-devel gcc-fortran) # gcc-fortran is only needed for compiling spec benchmarks on buildroot linux
        OTHER_PACKAGES+=(gcc13 gcc13-c++ cpp13) # Newer version of gcc needed for many tools. Default is gcc7
        ;;
esac


# Check if required packages are installed or install/update them depending on passed flag.
if [ "${1}" == "--check" ]; then
    section_header "Checking Dependencies from Package Manager"
    if [[ "$FAMILY" == rhel || "$FAMILY" == suse ]]; then
        for pack in "${GENERAL_PACKAGES[@]}" "${GNU_PACKAGES[@]}" "${QEMU_PACKAGES[@]}" "${SPIKE_PACKAGES[@]}" "${VERILATOR_PACKAGES[@]}" "${BUILDROOT_PACKAGES[@]}" "${OTHER_PACKAGES[@]}"; do
            rpm -q "$pack" > /dev/null || (echo -e "${FAIL_COLOR}Missing packages detected (${WARNING_COLOR}$pack${FAIL_COLOR}). Run as root to auto-install or run wally-package-install.sh first.${ENDC}" && exit 1)
        done
    elif [[ "$FAMILY" == ubuntu || "$FAMILY" == debian ]]; then
        for pack in "${GENERAL_PACKAGES[@]}" "${GNU_PACKAGES[@]}" "${QEMU_PACKAGES[@]}" "${SPIKE_PACKAGES[@]}" "${VERILATOR_PACKAGES[@]}" "${BUILDROOT_PACKAGES[@]}" "${OTHER_PACKAGES[@]}"; do
            dpkg -l "$pack" | grep "ii" > /dev/null || (echo -e "${FAIL_COLOR}Missing packages detected (${WARNING_COLOR}$pack${FAIL_COLOR}). Run as root to auto-install or run wally-package-install.sh first." && exit 1)
        done
    fi
    echo -e "${OK_COLOR}All required packages detected.${ENDC}"
else
    # Check if root, otherwise exit with error message
    [ "${EUID:=$(id -u)}" -ne 0 ] && echo -e "\n${FAIL_COLOR}Must be run as root${ENDC}" && exit 1

    section_header "Installing/Updating Dependencies from Package Manager"
    # Enable extra repos necessary for rhel
    if [ "$FAMILY" == rhel ]; then
        dnf install -y dnf-plugins-core
        dnf group install -y "Development Tools"
        if [ "$ID" == rhel ]; then
            subscription-manager repos --enable "codeready-builder-for-rhel-$RHEL_VERSION-$(arch)-rpms"
            dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$RHEL_VERSION.noarch.rpm"
        else # RHEL clone
            if (( RHEL_VERSION == 8 )); then
                dnf config-manager -y --set-enabled powertools
            else # Version 9
                dnf config-manager -y --set-enabled crb
            fi
            dnf install -y epel-release
        fi
    fi

    # Update and Upgrade tools
    eval "$UPDATE_COMMAND"
    # Install packages listed above using appropriate package manager
    eval $PACKAGE_MANAGER install "${GENERAL_PACKAGES[@]}" "${GNU_PACKAGES[@]}" "${QEMU_PACKAGES[@]}" "${SPIKE_PACKAGES[@]}" "${VERILATOR_PACKAGES[@]}" "${BUILDROOT_PACKAGES[@]}" "${OTHER_PACKAGES[@]}" "${VIVADO_PACKAGES[@]}"

    # Post install steps
    # Vivado looks for ncurses5 libraries, but Ubuntu 24.04 only has ncurses6
    # Create symbolic links to the ncurses6 libraries to fool Vivado
    if (( UBUNTU_VERSION >= 24 )); then
        ln -vsf /lib/x86_64-linux-gnu/libncurses.so.6 /lib/x86_64-linux-gnu/libncurses.so.5
        ln -vsf /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libntinfo.so.5
    fi

    echo -e "${SUCCESS_COLOR}Packages successfully installed.${ENDC}"
fi
