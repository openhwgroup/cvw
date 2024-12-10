#!/bin/bash
###########################################
## Get Linux distro information
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: 30 June 2024
## Modified:
##
## Purpose: Check for compatible Linux distibution and set variables accordingly
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
UNDERLINE='\033[4m'
SECTION_COLOR='\033[95m'$BOLD
OK_COLOR='\033[94m'
WARNING_COLOR='\033[93m'
FAIL_COLOR='\033[91m'
ENDC='\033[0m' # Reset to default color

# Print section header
section_header() {
    if tput cols > /dev/null 2>&1; then
        printf "${SECTION_COLOR}%$(tput cols)s\n" | tr ' ' '#'
        printf "%$(tput cols)s\n" | tr ' ' '#'
        printf "%s\n" "$1"
        printf "%$(tput cols)s\n" | tr ' ' '#'
        printf "%$(tput cols)s${ENDC}\n" | tr ' ' '#'
    else
        printf "${SECTION_COLOR}%s\n${ENDC}" "$1"
    fi
}

section_header "Checking System Requirements and Configuring Installation"

# Get distribution information
if [ -f /etc/os-release ]; then
    source /etc/os-release
else
    printf "${FAIL_COLOR}%s\n${ENDC}" "/etc/os-release file not found. Distribution unknown."
    PRETTY_NAME=UNKNOWN
fi

# Check for compatible distro
if [[ "$ID" == rhel || "$ID_LIKE" == *rhel* ]]; then
    export FAMILY=rhel
    if [ "$ID" != rhel ] && [ "$ID" != rocky ] && [ "$ID" != almalinux ]; then
        printf "${WARNING_COLOR}%s%s\n${ENDC}" "For Red Hat family distros, the Wally installation script has only been tested on RHEL, Rocky Linux," \
            " and AlmaLinux. Your distro is $PRETTY_NAME. The regular Red Hat install will be attempted, but there may be issues."
    fi
    export RHEL_VERSION="${VERSION_ID:0:1}"
    if (( RHEL_VERSION < 8 )); then
        printf "${FAIL_COLOR}%s\n${ENDC}" "The Wally installation script is only compatible with versions 8 and 9 of RHEL, Rocky Linux, and AlmaLinux. You have version $VERSION."
        exit 1
    fi
elif [[ "$ID" == ubuntu || "$ID_LIKE" == *ubuntu* ]]; then
    export FAMILY=ubuntu
    if [ "$ID" != ubuntu ]; then
        printf "${WARNING_COLOR}%s%s\n${ENDC}" "For Ubuntu family distros, the Wally installation script is only tested on standard Ubuntu. Your distro " \
            "is $PRETTY_NAME. The regular Ubuntu install will be attempted, but there may be issues."
        # Ubuntu derivates may use different version numbers. Attempt to derive version from Ubuntu codename
        case "$UBUNTU_CODENAME" in
            noble)
                export UBUNTU_VERSION=24
                ;;
            jammy)
                export UBUNTU_VERSION=22
                ;;
            focal)
                export UBUNTU_VERSION=20
                ;;
            *)
                printf "${FAIL_COLOR}%s\n${ENDC}" "Unable to determine which base Ubuntu version you are using."
                exit 1
                ;;
        esac
        echo "Detected Ubuntu derivative baesd on Ubuntu $UBUNTU_VERSION.04."
    else
        export UBUNTU_VERSION="${VERSION_ID:0:2}"
    fi
    if (( UBUNTU_VERSION < 20 )); then
        printf "${FAIL_COLOR}%s\n${ENDC}" "The Wally installation script has only been tested with Ubuntu versions 20.04 LTS, 22.04 LTS, and 24.04 LTS. You have version $VERSION."
        exit 1
    fi
elif [[ "$ID" == debian || "$ID_LIKE" == *debian* ]]; then
    export FAMILY=debian
    if [ "$ID" != debian ]; then
        printf "${WARNING_COLOR}%s%s\n${ENDC}" "For Debian family distros, the Wally installation script has only been tested on standard Debian (and Ubuntu). Your distro " \
            "is $PRETTY_NAME. The regular Debian install will be attempted, but there may be issues."
    fi
    export DEBIAN_VERSION="$VERSION_ID"
    if (( DEBIAN_VERSION < 11 )); then
        printf "${FAIL_COLOR}%s\n${ENDC}" "The Wally installation script has only been tested with Debian versions 11 and 12. You have version $VERSION."
        exit 1
    fi
elif [[ "$ID" == opensuse-leap || "$ID" == sles || "$ID_LIKE" == *suse* ]]; then
    export FAMILY=suse
    if [[ "$ID" != opensuse-leap && "$ID" != sles  ]]; then
        printf "${WARNING_COLOR}%s%s\n${ENDC}" "For SUSE family distros, the Wally installation script has only been tested on OpenSUSE Leap and SLES. Your distro " \
            "is $PRETTY_NAME. The regular SUSE install will be attempted, but there may be issues. If you are using OpenSUSE Tumbleweed, the version check will fail."
    fi
    export SUSE_VERSION="${VERSION_ID//.}"
    if (( SUSE_VERSION < 156 )); then
        printf "${FAIL_COLOR}%s\n${ENDC}" "The Wally installation script has only been tested with SUSE version 15.6. You have version $VERSION."
        exit 1
    fi
else
    printf "${FAIL_COLOR}%s%s%s\n${ENDC}" "The Wally installation script is currently only compatible with Ubuntu, Debian, SUSE, and Red Hat family " \
        "(RHEL, Rocky Linux, or AlmaLinux) distros. Your detected distro is $PRETTY_NAME. You may try manually running the " \
        "commands in this script, but it is likely that some will need to be altered."
    exit 1
fi

printf "${OK_COLOR}${UNDERLINE}%s\n${ENDC}" "Detected information"
echo "Distribution: $PRETTY_NAME"
echo "Version: $VERSION"
