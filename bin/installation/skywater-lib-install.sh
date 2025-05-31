#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: May 30 2025
## Modified: 
##
## Purpose: QEMU installation script
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

SKYWATER_LIB_VERSION=ac90ef0c622a9377a16b5218d9da3ac4169eeaaf # Last commit as of May 30, 2025

set -e # break on error
# If run standalone, check environment. Otherwise, use info from main install script
if [ -z "$FAMILY" ]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    WALLY="$(dirname $(dirname "$dir"))"
    export WALLY
    source "${dir}"/../wally-environment-check.sh
fi

# OSU Skywater 130 cell library (https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12)
# The OSU Skywater 130 cell library is a standard cell library that is used to synthesize Wally.
section_header "Installing/Updating OSU Skywater 130 cell library"
STATUS="osu_skywater_130_cell_library"
mkdir -p "$RISCV"/cad/lib
cd "$RISCV"/cad/lib
if check_tool_version $SKYWATER_LIB_VERSION; then
    git_checkout "sky130_osu_sc_t12" "https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12" "$SKYWATER_LIB_VERSION"
    echo "$SKYWATER_LIB_VERSION" > "$RISCV"/versions/$STATUS.version
    echo -e "${SUCCESS_COLOR}OSU Skywater library successfully installed!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}OSU Skywater library already up to date.${ENDC}"
fi
