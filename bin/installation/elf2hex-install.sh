#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: May 30 2025
## Modified: 
##
## Purpose: elf2hex installation script
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

# If run standalone, check environment. Otherwise, use info from main install script
if [ -z "$FAMILY" ]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    WALLY="$(dirname $(dirname "$dir"))"
    export WALLY
    source "${dir}"/../wally-environment-check.sh
fi

# elf2hex (https://github.com/sifive/elf2hex)
# The elf2hex utility to converts executable files into hexadecimal files for Verilog simulation.
# Note: The exe2hex utility that comes with Spike doesn’t work for our purposes because it doesn’t
# handle programs that start at 0x80000000. The SiFive version above is touchy to install.
# For example, if Python version 2.x is in your path, it won’t install correctly.
# Also, be sure riscv64-unknown-elf-objcopy shows up in your path in $RISCV/riscv-gnu-toolchain/bin
# at the time of compilation, or elf2hex won’t work properly.
section_header "Installing/Updating elf2hex"
STATUS="elf2hex"
cd "$RISCV"
if git_check "elf2hex" "https://github.com/sifive/elf2hex.git" "$RISCV/bin/riscv64-unknown-elf-elf2bin"; then
    cd "$RISCV"/elf2hex
    git reset --hard && git clean -f && git checkout master && git pull
    autoreconf -i
    ./configure --target=riscv64-unknown-elf --prefix="$RISCV"
    make 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    make install 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    if [ "$clean" ]; then
        cd "$RISCV"
        rm -rf elf2hex
    fi
    echo -e "${SUCCESS_COLOR}elf2hex successfully installed/updated!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}elf2hex already up to date.${ENDC}"
fi
