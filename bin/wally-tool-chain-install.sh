#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Rose Thompson rose@rosethompson.net
## Modified: 30 June 2024, Jordan Carlin jcarlin@hmc.edu
## Modified: 30 May 2025
##
## Purpose: Open source tool chain installation script
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

# NOTE: All scripts are sourced instead of executed so that environment variables and functions are shared properly.

set -e # break on error

# Determine script directory to locate related scripts
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLY=$(dirname "$dir")
export WALLY

# Get Linux distro and version
source "${dir}"/wally-environment-check.sh

# Install/update system packages if root. Otherwise, check that packages are already installed.
if [ "$ROOT" == true ]; then
    source "${dir}"/wally-package-install.sh
else
    source "${dir}"/wally-package-install.sh --check
fi


# Create python virtual environment so the python command targets desired version of python
# and installed packages are isolated from the rest of the system. Also installs python packages,
# including RISCOF (https://github.com/riscv-software-src/riscof.git)
# RISCOF is a RISC-V compliance test framework that is used to run the RISC-V Arch Tests.
source "$WALLY"/bin/installation/python-setup.sh


# Activate tools (python virtual environment and possibly newer version of gcc)
source "${WALLY}"/bin/installation/activate-tools.sh


# Newer version of glib required for QEMU.
# Anything newer than this won't build on red hat 8
# Used for all installed tools becuase mixing glib versions can cause issues.
if (( RHEL_VERSION == 8 )) || (( UBUNTU_VERSION == 20 )); then
    source "$WALLY"/bin/installation/glib-installation.sh
fi


# RISC-V GNU Toolchain (https://github.com/riscv-collab/riscv-gnu-toolchain)
# The RISC-V GNU Toolchain includes the GNU Compiler Collection (gcc), GNU Binutils, Newlib,
# and the GNU Debugger Project (gdb). It is a collection of tools used to compile RISC-V programs.
# To install GCC from source can take hours to compile.
source "$WALLY"/bin/installation/riscv-gnu-toolchain-install.sh


# elf2hex (https://github.com/sifive/elf2hex)
# The elf2hex utility to converts executable files into hexadecimal files for Verilog simulation.
# Note: The exe2hex utility that comes with Spike doesn’t work for our purposes because it doesn’t
# handle programs that start at 0x80000000.
source "$WALLY"/bin/installation/elf2hex-install.sh


# QEMU (https://www.qemu.org/docs/master/system/target-riscv.html)
# QEMU is an open source machine emulator and virtualizer capable of emulating RISC-V
source "$WALLY"/bin/installation/qemu-install.sh


# Spike (https://github.com/riscv-software-src/riscv-isa-sim)
# Spike is a reference model for RISC-V. It is a functional simulator that can be used to run RISC-V programs.
source "$WALLY"/bin/installation/spike-install.sh


# RISC-V Sail Model (https://github.com/riscv/sail-riscv)
# The RISC-V Sail Model is the golden reference model for RISC-V. It is written in Sail.
# Sail is a formal specification language designed for describing the semantics of an ISA.
# It is used to generate the RISC-V Sail Model, which is the golden reference model for RISC-V.
# The Sail Compiler is written in OCaml, which is an object-oriented extension of ML, which in turn
# is a functional programming language suited to formal verification.
source "$WALLY"/bin/installation/sail-install.sh


# Verilator (https://github.com/verilator/verilator)
# Verilator is a fast open-source Verilog simulator that compiles synthesizable Verilog code into C++ code.
# It is used for linting and simulation of Wally.
source "$WALLY"/bin/installation/verilator-install.sh


# OSU Skywater 130 cell library (https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12)
# The OSU Skywater 130 cell library is a standard cell library that is used to synthesize Wally.
source "$WALLY"/bin/installation/skywater-lib-install.sh


# Buildroot and Linux testvectors
# Buildroot is used to boot a minimal version of Linux on Wally.
# Testvectors are generated using QEMU.
if [ "$no_buildroot" = true ]; then
    echo -e "${OK_COLOR}Skipping Buildroot and Linux testvectors.${ENDC}"
else
    source "$WALLY"/bin/installation/buildroot-install.sh
fi


# Download site-setup scripts
# The site-setup script is used to set up the environment for the RISC-V tools and EDA tools by setting
# the PATH and other environment variables. It also sources the Python virtual environment.
section_header "Downloading Site Setup Script"
STATUS="site-setup_scripts"
cd "$RISCV"
if [ ! -e "${RISCV}"/site-setup.sh ]; then
    wget -nv --retry-connrefused $retry_on_host_error https://raw.githubusercontent.com/openhwgroup/cvw/main/site-setup.sh
    wget -nv --retry-connrefused $retry_on_host_error https://raw.githubusercontent.com/openhwgroup/cvw/main/site-setup.csh
    echo -e "${SUCCESS_COLOR}Site setup script successfully downloaded!${ENDC}"
    echo -e "${WARNING_COLOR}Make sure to edit the environment variables in $RISCV/site-setup.sh (or .csh) to point to your installation of EDA tools and license files.${ENDC}"
else
    echo -e "${OK_COLOR}Site setup script already exists. Not checking for updates to avoid overwritng modifications."
    echo -e "You may need to manually update it if there were changes upstream.${ENDC}"
fi

echo -e "${SUCCESS_COLOR}${BOLD}\n\nWALLY INSTALLATION SUCCESSFUL!!!\n\n${ENDC}"
