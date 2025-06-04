#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: May 30 2025
## Modified: 
##
## Purpose: glib installation script
##
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
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
# If run standalone, check environment. Otherwise, use info from main install script
if [ -z "$FAMILY" ]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    WALLY="$(dirname $(dirname "$dir"))"
    export WALLY
    source "${dir}"/../wally-environment-check.sh
fi

# Newer version of glib required for QEMU.
# Anything newer than this won't build on red hat 8
STATUS="glib"
if [ ! -e "$RISCV"/include/glib-2.0 ]; then
    section_header "Installing glib"
    pip --require-virtualenv install -U meson # Meson is needed to build glib
    cd "$RISCV"
    wget -nv --retry-connrefused $retry_on_host_error https://download.gnome.org/sources/glib/2.70/glib-2.70.5.tar.xz
    tar -xJf glib-2.70.5.tar.xz
    rm -f glib-2.70.5.tar.xz
    cd glib-2.70.5
    meson setup _build --prefix="$RISCV"
    meson compile -C _build -j "${NUM_THREADS}" 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    meson install -C _build 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    cd "$RISCV"
    rm -rf glib-2.70.5
    echo -e "${SUCCESS_COLOR}glib successfully installed!${ENDC}"
else
    echo -e "${OK_COLOR}glib already installed.${ENDC}"
fi