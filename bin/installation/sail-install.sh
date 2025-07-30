#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: May 30 2025
## Modified: 
##
## Purpose: Sail installation script
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

SAIL_COMPILER_VERSION=0.19.1 # Last release as of June 26, 2025
CMAKE_VERSION=3.31.5 # Only used for distros with a system CMake that is too old (< 3.20)
RISCV_SAIL_MODEL_VERSION=964277c8fca367e22917421c07ec9c35304782c8 # Last commit as of July 29, 2025

set -e # break on error
# If run standalone, check environment. Otherwise, use info from main install script
if [ -z "$FAMILY" ]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    WALLY="$(dirname $(dirname "$dir"))"
    export WALLY
    source "${dir}"/../wally-environment-check.sh
fi

# Sail Compiler (https://github.com/rems-project/sail)
# Sail is a formal specification language designed for describing the semantics of an ISA.
# It is used to generate the RISC-V Sail Model, which is the golden reference model for RISC-V.
# The Sail Compiler is written in OCaml, which is an object-oriented extension of ML, which in turn
# is a functional programming language suited to formal verification.
section_header "Installing/Updating Sail Compiler"
STATUS="sail_compiler"
cd "$RISCV"
if check_tool_version $SAIL_COMPILER_VERSION; then
    wget -nv --retry-connrefused $retry_on_host_error --output-document=sail.tar.gz "https://github.com/rems-project/sail/releases/download/$SAIL_COMPILER_VERSION-linux-binary/sail.tar.gz"
    tar xz --directory="$RISCV" --strip-components=1 -f sail.tar.gz
    rm -f sail.tar.gz
    echo "$SAIL_COMPILER_VERSION" > "$RISCV"/versions/$STATUS.version # Record installed version
    echo -e "${SUCCESS_COLOR}Sail Compiler successfully installed/updated!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}Sail Compiler already installed.${ENDC}"
fi

# Newer version of CMake needed to build sail-riscv model (at least 3.20)
if (( UBUNTU_VERSION == 20  || DEBIAN_VERSION == 11 )); then
    STATUS="cmake"
    if [ ! -e "$RISCV"/bin/cmake ] || [ "$("$RISCV"/bin/cmake --version | head -n1 | sed 's/cmake version //')" != "$CMAKE_VERSION" ]; then
        section_header "Installing CMake"
        cd "$RISCV"
        wget -nv --retry-connrefused $retry_on_host_error --output-document=cmake.tar.gz "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.tar.gz"
        tar xz --directory="$RISCV" --strip-components=1 -f cmake.tar.gz
        rm -f cmake.tar.gz
        echo -e "${SUCCESS_COLOR}CMake successfully installed/updated!${ENDC}"
    else
        echo -e "${SUCCESS_COLOR}CMake already installed.${ENDC}"
    fi
fi

# Newer version of gmp needed for sail-riscv model on RHEL 8
# sail-riscv will download and build gmp if told to do so, so no need to install it manually.
if (( RHEL_VERSION == 8 )); then
    DOWNLOAD_GMP=TRUE
else
    DOWNLOAD_GMP=FALSE
fi

# RISC-V Sail Model (https://github.com/riscv/sail-riscv)
# The RISC-V Sail Model is the golden reference model for RISC-V. It is written in Sail (described above)
section_header "Installing/Updating RISC-V Sail Model"
STATUS="riscv-sail-model"
cd "$RISCV"
if check_tool_version $RISCV_SAIL_MODEL_VERSION; then
    git_checkout "sail-riscv" "https://github.com/riscv/sail-riscv.git" "$RISCV_SAIL_MODEL_VERSION"
    cd "$RISCV"/sail-riscv
    cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX="$RISCV" -DDOWNLOAD_GMP="$DOWNLOAD_GMP" -GNinja 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    cmake --build build 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    cmake --install build 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    if [ "$clean" = true ]; then
        cd "$RISCV"
        rm -rf sail-riscv
    fi
    echo "$RISCV_SAIL_MODEL_VERSION" > "$RISCV"/versions/$STATUS.version # Record installed version
    echo -e "${SUCCESS_COLOR}RISC-V Sail Model successfully installed/updated!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}RISC-V Sail Model already up to date.${ENDC}"
fi
