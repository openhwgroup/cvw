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


echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Checking System Requirements and Configuring Installation"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"

# Get distribution information
test -e /etc/os-release && os_release="/etc/os-release" || os_release="/usr/lib/os-release"
source "$os_release"

# Check for compatible distro
if [[ "$ID" = rhel || "$ID_LIKE" = *rhel* ]]; then
    FAMILY=rhel
    if [ "$ID" != rhel ] && [ "$ID" != rocky ] && [ "$ID" != almalinux ]; then
        printf "${WARNING_COLOR}%s\n${ENDC}" "For Red Hat family distros, the Wally install script has only been tested on RHEL, Rocky Linux," \
            " and AlmaLinux. Your distro is $PRETTY_NAME. The regular Red Hat install will be attempted, but there will likely be issues."
    fi
    if [ "${VERSION_ID:0:1}" = 8 ]; then
        RHEL_VERSION=8
    elif [ "${VERSION_ID:0:1}" = 9 ]; then
        RHEL_VERSION=9
    else
        echo "${FAIL_COLOR}The Wally install script is only compatible with versions 8 and 9 of RHEL, Rocky Linux, and AlmaLinux. You have version $VERSION.${ENDC}"
        exit 1
    fi
elif [[ "$ID" = ubuntu || "$ID_LIKE" = *ubuntu* ]]; then
    FAMILY=ubuntu
    if [ "$ID" != ubuntu ]; then
        printf "${WARNING_COLOR}%s\n${ENDC}" "For Ubuntu family distros, the Wally install script has only been tested on standard Ubuntu. Your distro " \
            "is $PRETTY_NAME. The regular Ubuntu install will be attempted, but there may be issues."
    else
        UBUNTU_VERSION="${VERSION_ID:0:2}"
        if (( UBUNTU_VERSION < 20 )); then
            echo "${FAIL_COLOR}The Wally install script is only compatible with versions 20.04, 22.04, and 24.04 of Ubuntu. You have version $VERSION.${ENDC}"
            exit 1
        fi
    fi
else
    printf "${FAIL_COLOR}%s\n${ENDC}" "The Wally install script is currently only compatible with Ubuntu and Red Hat family " \
        "(RHEL, Rocky Linux, or AlmaLinux) distros. Your detected distro is $PRETTY_NAME. You may try manually running the " \
        "commands in this script, but it is likely that some will need to be altered."
    exit 1
fi

echo -e "${OK_COLOR}${UNDERLINE}Detected information${ENDC}"
echo "Distribution: $PRETTY_NAME"
echo "Version: $VERSION"
