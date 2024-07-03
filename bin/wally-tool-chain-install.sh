#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Ross Thompson ross1728@gmail.com
## Created: 18 January 2023
## Modified: 22 January 2023
## Modified: 23 March 2023
## Modified: 30 June 2024, Jordan Carlin jcarlin@hmc.edu
##
## Purpose: Open source tool chain installation script
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

# MODIFY FOR YOUR MACHINE
# Increasing NUM_THREADS will speed up parallel compilation of the tools
#NUM_THREADS=2 # for low memory machines > 16GiB
NUM_THREADS=8  # for >= 32GiB
#NUM_THREADS=16  # for >= 64GiB

set -e # break on error
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
BOLD='\033[1m'
UNDERLINE='\033[4m'
SECTION_COLOR='\033[95m'$BOLD
OK_COLOR='\033[94m'
SUCCESS_COLOR='\033[92m'
WARNING_COLOR='\033[93m'
FAIL_COLOR='\033[91m'
ENDC='\033[0m'

# Get Linux distro and version
source "${dir}"/wally-distro-check.sh

# Check if root
ROOT=$( [ "${EUID:=$(id -u)}" = 0 ] && echo true || echo false);

# All tools will be installed under the $RISCV directory. By default, if run as root (with sudo) this is set to
# /opt/riscv. Otherwise, it is set to ~/riscv. This value can be overridden with an argument passed to the script.
if [ "$ROOT" = true ]; then
    export RISCV="${1:-/opt/riscv}"
else
    export RISCV="${1:-$HOME/riscv}"
fi

export PATH=$PATH:$RISCV/bin:/usr/bin
export PKG_CONFIG_PATH=$RISCV/lib64/pkgconfig:$RISCV/lib/pkgconfig:$RISCV/share/pkgconfig:$RISCV/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH
mkdir -p "$RISCV"

echo "Running as root: $ROOT"
echo "Installation path: $RISCV"

# Install/update packages if root. Otherwise, check that packages are already installed.
if [ "$ROOT" = true ]; then
    source "${dir}"/wally-package-install.sh
else
    source "${dir}"/wally-package-install.sh --check
fi

if [ "$FAMILY" = rhel ]; then
    # A newer version of gcc is required for qemu
    source /opt/rh/gcc-toolset-13/enable  # activate gcc13
    # Newer version of gcc needed for Ubuntu 20.04 for Verilator
elif [ "$UBUNTU_VERSION" = 20 ]; then
    mkdir -p "$RISCV"/gcc-10/bin
    for f in gcc cpp g++ gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool lto-dump; do
        ln -vsf /usr/bin/$f-10 "$RISCV"/gcc-10/bin/$f
    done
    export PATH="$RISCV"/gcc-10/bin:$PATH
fi

echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Setting up Python Environment"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
# Create python virtual environment so the python command targets our desired version of python
# and installed packages are isolated from the rest of the system.
cd "$RISCV"
if [ ! -e "$RISCV"/riscv-python/bin/activate ]; then
    # If python3.12 is avaiable, use it. Otherise, use whatever version of python3 is installed.
    if [ "$(which python3.12)" ]; then
        python3.12 -m venv riscv-python
    else
        python3 -m venv riscv-python
    fi
    echo -e "${OK_COLOR}Python virtual environment created.\nInstalling pip packages.${ENDC}"
else
    echo -e "${OK_COLOR}Python virtual environment already exists.\Updating pip packages.${ENDC}"
fi
source "$RISCV"/riscv-python/bin/activate # activate python virtual environment

# Install python packages
pip install -U pip
pip install -U sphinx sphinx_rtd_theme matplotlib scipy scikit-learn adjustText lief markdown pyyaml testresources riscv_config
pip install -U riscv_isac # to generate new tests, such as quads with fp_dataset.py

# z3 is eeded for sail and not availabe from dnf for rhel 8
if [ "$RHEL_VERSION" = 8 ]; then
    pip install -U z3-solver
fi
source "$RISCV"/riscv-python/bin/activate # reload python virtual environment
echo -e "${SUCCESS_COLOR}Python environment successfully configured.${ENDC}"

# Extra dependecies needed for older distros that don't have new enough versions available from package manager
if [ "$RHEL_VERSION" = 8 ] || [ "$UBUNTU_VERSION" = 20 ]; then
    # Newer versin of glib required for Qemu.
    # Anything newer than this won't build on red hat 8
    if [ ! -e "$RISCV"/include/glib-2.0 ]; then
        echo -e "${SECTION_COLOR}\n*************************************************************************"
        echo -e "*************************************************************************"
        echo -e "Installing glib"
        echo -e "*************************************************************************"
        echo -e "*************************************************************************\n${ENDC}"
        # Meson is needed to build glib
        pip install -U meson
        cd "$RISCV"
        wget https://download.gnome.org/sources/glib/2.70/glib-2.70.5.tar.xz
        tar -xJf glib-2.70.5.tar.xz
        rm glib-2.70.5.tar.xz
        cd glib-2.70.5
        meson setup _build --prefix="$RISCV"
        meson compile -C _build
        meson install -C _build
        cd "$RISCV"
        rm -rf glib-2.70.5
        echo -e "${SUCCESS_COLOR}glib successfully installed${ENDC}"
    fi
fi

# Newer version of gmp needed for sail-riscv model
if [ "$RHEL_VERSION" = 8 ]; then
    if [ ! -e "$RISCV"/include/gmp.h ]; then
        echo -e "${SECTION_COLOR}\n*************************************************************************"
        echo -e "*************************************************************************"
        echo -e "Installing gmp"
        echo -e "*************************************************************************"
        echo -e "*************************************************************************\n${ENDC}"
        cd "$RISCV"
        wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
        tar -xJf gmp-6.3.0.tar.xz
        rm gmp-6.3.0.tar.xz
        cd gmp-6.3.0
        ./configure --prefix="$RISCV"
        make -j ${NUM_THREADS}
        make install
        cd "$RISCV"
        rm -rf gmp-6.3.0
        echo -e "${SUCCESS_COLOR}gmp successfully installed${ENDC}"
    fi
fi

# gcc cross-compiler (https://github.com/riscv-collab/riscv-gnu-toolchain)
# To install GCC from source can take hours to compile.
# This configuration enables multilib to target many flavors of RISC-V.
# This book is tested with GCC 13.2.0
echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating RISC-V GNU Toolchain"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
cd "$RISCV"
if [[ ((! -e riscv-gnu-toolchain) && ($(git clone https://github.com/riscv/riscv-gnu-toolchain) || true)) || ($(cd riscv-gnu-toolchain; git fetch; git rev-parse HEAD) != $(cd riscv-gnu-toolchain; git rev-parse origin/master)) || (! -e $RISCV/riscv-gnu-toolchain/stamps/build-gcc-newlib-stage2) ]]; then
    cd riscv-gnu-toolchain
    git reset --hard && git clean -f && git checkout master && git pull
    git pull
    ./configure --prefix="${RISCV}" --with-multilib-generator="rv32e-ilp32e--;rv32i-ilp32--;rv32im-ilp32--;rv32iac-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--;rv64i-lp64--;rv64ic-lp64--;rv64iac-lp64--;rv64imac-lp64--;rv64imafdc-lp64d--;rv64im-lp64--;"
    make -j ${NUM_THREADS}
    echo -e "${SUCCESS_COLOR}RISC-V GNU Toolchain successfully installed${ENDC}"
else
    echo -e "${SUCCESS_COLOR}RISC-V GNU Toolchain already up to date${ENDC}"
fi

# elf2hex (https://github.com/sifive/elf2hex)
#The elf2hex utility to converts executable files into hexadecimal files for Verilog simulation.
# Note: The exe2hex utility that comes with Spike doesn’t work for our purposes because it doesn’t
# handle programs that start at 0x80000000. The SiFive version above is touchy to install.
# For example, if Python version 2.x is in your path, it won’t install correctly.
# Also, be sure riscv64-unknown-elf-objcopy shows up in your path in $RISCV/riscv-gnu-toolchain/bin
# at the time of compilation, or elf2hex won’t work properly.
echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating elf2hex"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
cd "$RISCV"
export PATH=$RISCV/bin:$PATH
if [[ ((! -e elf2hex) && ($(git clone https://github.com/sifive/elf2hex.git) || true)) || ($(cd elf2hex; git fetch; git rev-parse HEAD) != $(cd elf2hex; git rev-parse origin/master)) || (! -e $RISCV/bin/riscv64-unknown-elf-elf2bin) ]]; then
    cd elf2hex
    git reset --hard && git clean -f && git checkout master && git pull
    autoreconf -i
    ./configure --target=riscv64-unknown-elf --prefix="$RISCV"
    make
    make install
    echo -e "${SUCCESS_COLOR}elf2hex successfully installed${ENDC}"
else
    echo -e "${SUCCESS_COLOR}elf2hex already up to date${ENDC}"
fi

# QEMU (https://www.qemu.org/docs/master/system/target-riscv.html)
echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating QEMU"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
cd "$RISCV"
if [[ ((! -e qemu) && ($(git clone --recurse-submodules https://github.com/qemu/qemu) || true)) || ($(cd qemu; git fetch; git rev-parse HEAD) != $(cd qemu; git rev-parse origin/master)) || (! -e $RISCV/include/qemu-plugin.h) ]]; then
    cd qemu
    git reset --hard && git clean -f && git checkout master && git pull --recurse-submodules
    ./configure --target-list=riscv64-softmmu --prefix="$RISCV"
    make -j ${NUM_THREADS}
    make install
    echo -e "${SUCCESS_COLOR}QEMU successfully installed${ENDC}"
else
    echo -e "${SUCCESS_COLOR}QEMU already up to date${ENDC}"
fi

# Spike (https://github.com/riscv-software-src/riscv-isa-sim)
# Spike also takes a while to install and compile, but this can be done concurrently
# with the GCC installation.
echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating SPIKE"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
cd "$RISCV"
if [[ ((! -e riscv-isa-sim) && ($(git clone https://github.com/riscv-software-src/riscv-isa-sim) || true)) || ($(cd riscv-isa-sim; git fetch; git rev-parse HEAD) != $(cd riscv-isa-sim; git rev-parse origin/master)) || (! -e $RISCV/lib/pkgconfig/riscv-riscv.pc) ]]; then
    cd riscv-isa-sim
    git reset --hard && git clean -f && git checkout master && git pull
    mkdir -p build
    cd build
    ../configure --prefix="$RISCV"
    make -j ${NUM_THREADS}
    make install
    echo -e "${SUCCESS_COLOR}Spike successfully installed${ENDC}"
else
    echo -e "${SUCCESS_COLOR}Spike already up to date${ENDC}"
fi

# Wally needs Verilator 5.021 or later.
# Verilator needs to be built from source to get the latest version
echo -e "\n${SECTION_COLOR}*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating Verilator"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
cd "$RISCV"
if [[ ((! -e verilator) && ($(git clone https://github.com/verilator/verilator) || true)) || ($(cd verilator; git fetch; git rev-parse HEAD) != $(cd verilator; git rev-parse origin/master)) || (! -e $RISCV/share/pkgconfig/verilator.pc) ]]; then
    # unsetenv VERILATOR_ROOT  # For csh; ignore error if on bash
    unset VERILATOR_ROOT     # For bash
    cd verilator
    git reset --hard && git clean -f && git checkout master && git pull
    autoconf         # Create ./configure script
    ./configure --prefix="$RISCV"     # Configure and create Makefile
    make -j ${NUM_THREADS}  # Build Verilator itself (if error, try just 'make')
    make install
    echo -e "${SUCCESS_COLOR}Verilator successfully installed${ENDC}"
else
    echo -e "${SUCCESS_COLOR}Verilator already up to date${ENDC}"
fi

# RISC-V Sail Model (https://github.com/riscv/sail-riscv)
# The RISC-V Sail Model is the golden reference model for RISC-V. It is written in Sail,
# a language designed for expressing the semantics of an ISA. Sail itself is written in 
# OCaml, which is an object-oriented extension of ML, which in turn is a functional programming
# language suited to formal verification. The Sail compiler is installed with the opam OCcaml
# package manager. The Sail compiler has so many dependencies that it can be difficult to install,
# but a binary release of it should be available soon, removing the need to use opam.
cd "$RISCV"
if [ "$FAMILY" = rhel ]; then
    echo -e "${SECTION_COLOR}\n*************************************************************************"
    echo -e "*************************************************************************"
    echo -e "Installing/Updating Opam"
    echo -e "*************************************************************************"
    echo -e "*************************************************************************\n${ENDC}"
    mkdir -p opam
    cd opam
    wget https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh
    printf '%s\n' "$RISCV"/bin Y | sh install.sh # the print command provides $RISCV/bin as the installation path when prompted
    cd "$RISCV"
    rm -rf opam
    echo -e "${SUCCESS_COLOR}Opam successfully installed/updated${ENDC}"
fi

echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating Sail Compiler"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
cd "$RISCV"
opam init -y --disable-sandboxing
opam update -y
opam upgrade -y
opam switch create 5.1.0 || opam switch set 5.1.0
opam install sail -y
echo -e "${SUCCESS_COLOR}Sail Compiler successfully installed/updated${ENDC}"

echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating RISC-V Sail Model"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
if [[ ((! -e sail-riscv) && ($(git clone https://github.com/riscv/sail-riscv.git) || true)) || ($(cd sail-riscv; git fetch; git rev-parse HEAD) != $(cd sail-riscv; git rev-parse origin/master)) || (! -e $RISCV/bin/riscv_sim_RV32) ]]; then
    eval $(opam config env)
    cd sail-riscv
    git reset --hard && git clean -f && git checkout master && git pull
    export OPAMCLI=2.0  # Sail is not compatible with opam 2.1 as of 4/16/24
    ARCH=RV64 make -j ${NUM_THREADS} c_emulator/riscv_sim_RV64
    ARCH=RV32 make -j ${NUM_THREADS} c_emulator/riscv_sim_RV32
    cd "$RISCV"
    ln -sf ../sail-riscv/c_emulator/riscv_sim_RV64 bin/riscv_sim_RV64
    ln -sf ../sail-riscv/c_emulator/riscv_sim_RV32 bin/riscv_sim_RV32
    echo -e "${SUCCESS_COLOR}RISC-V Sail Model successfully installed${ENDC}"
else
    echo -e "${SUCCESS_COLOR}RISC-V Sail Model already up to date${ENDC}"
fi

# riscof
echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating RISCOF"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
pip3 install git+https://github.com/riscv/riscof.git

# Download OSU Skywater 130 cell library
echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing/Updating OSU Skywater 130 cell library"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
mkdir -p "$RISCV"/cad/lib
cd "$RISCV"/cad/lib
if [[ ((! -e sky130_osu_sc_t12) && ($(git clone https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12) || true)) || ($(cd sky130_osu_sc_t12; git fetch; git rev-parse HEAD) != $(cd sky130_osu_sc_t12; git rev-parse origin/main)) ]]; then
    cd sky130_osu_sc_t12
    git reset --hard && git clean -f && git checkout main && git pull
    echo -e "${SUCCESS_COLOR}OSU Skywater library successfully installed${ENDC}"
else
    echo -e "${SUCCESS_COLOR}OSU Skywater library already up to date${ENDC}"
fi

# site-setup script
echo -e "${SECTION_COLOR}\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Downloading Site Setup Script"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n${ENDC}"
cd "$RISCV"
if [ ! -e "${RISCV}"/site-setup.sh ]; then
    wget https://raw.githubusercontent.com/openhwgroup/cvw/main/site-setup.sh
    wget https://raw.githubusercontent.com/openhwgroup/cvw/main/site-setup.csh
    if [ "$FAMILY" = rhel ]; then
        echo "source /opt/rh/gcc-toolset-13/enable" >> site-setup.sh
    elif [ "$UBUNTU_VERSION" = 20 ]; then
        echo "export PATH=\$RISCV/gcc-10/bin:\$PATH" >> site-setup.sh
        echo "prepend PATH \$RISCV/gcc-10/bin" >> site-setup.csh
    fi
    echo -e "${SUCCESS_COLOR}Site setup script successfully downloaded${ENDC}"
else
    echo -e "${OK_COLOR}Site setup script already exists. Not checking for updates to avoid overwritng modifications${ENDC}"
fi

echo -e "${SUCCESS_COLOR}${BOLD}\n\nINSTALLATION SUCCESSFUL\n\n${ENDC}"
