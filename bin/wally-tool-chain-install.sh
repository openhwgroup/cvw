#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Ross Thompson ross1728@gmail.com
## Created: 18 January 2023
## Modified: 22 January 2023
## Modified: 23 March 2023
## Modified: 21 June 2024, Jordan Carlin jcarlin@hmc.edu
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

# Check if root
ROOT=$( [ "${EUID:=$(id -u)}" = 0 ] && echo true || echo false);

# All tools will be installed under the $RISCV directory. By default, if run as root (with sudo)
# this is set to /opt/riscv. Otherwise, it is set to ~/riscv. This value can be changed if needed.
if [ "$ROOT" = true ]; then
  export RISCV="${1:-/opt/riscv}"
else
  export RISCV="${1:-$HOME/riscv}"
fi

export PATH=$PATH:$RISCV/bin:/usr/bin

set -e # break on error

# Modify accordingly for your machine
# Increasing NUM_THREADS will speed up parallel compilation of the tools
#NUM_THREADS=2 # for low memory machines > 16GiB
NUM_THREADS=8  # for >= 32GiB
#NUM_THREADS=16  # for >= 64GiB

mkdir -p "$RISCV"

echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing Dependencies from Package Manager"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
# Update and Upgrade tools (see https://itsfoss.com/apt-update-vs-upgrade/)
sudo apt update -y
sudo apt upgrade -y

# Packages are grouped by which tool requires them, split by line. 
# If mutltipole tools need a package, it is included in the first tool only
# General/Wally specific, riscv-gnu-toolchain, qemu, spike, verilator, sail
sudo apt install -y git make cmake python3 python3-pip python3-venv curl wget ftp tar pkg-config dialog mutt ssmtp \
                    autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat1-dev ninja-build libglib2.0-dev libslirp-dev \
                    libfdt-dev libpixman-1-dev \
                    device-tree-compiler libboost-regex-dev libboost-system-dev \
                    help2man perl g++ clang ccache libgoogle-perftools-dev numactl mold perl-doc libfl2 libfl-dev zlib1g \
                    opam z3

echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Setting up Python Environment"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
# Other python libraries used through the book.
cd "$RISCV"
if [ ! -e "$RISCV"/riscv-python/bin/activate ]; then
  python3 -m venv riscv-python
fi
source "$RISCV"/riscv-python/bin/activate
pip install -U pip
pip install -U sphinx sphinx_rtd_theme matplotlib scipy scikit-learn adjustText lief markdown pyyaml testresources riscv_config
pip install -U riscv_isac # to generate new tests, such as quads with fp_dataset.py
source "$RISCV"/riscv-python/bin/activate

# gcc cross-compiler (https://github.com/riscv-collab/riscv-gnu-toolchain)
# To install GCC from source can take hours to compile. 
# This configuration enables multilib to target many flavors of RISC-V.   
# This book is tested with GCC 13.2.0
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing RISC-V GNU Toolchain"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd "$RISCV"
if [[ ((! -e riscv-gnu-toolchain) && ($(git clone https://github.com/riscv/riscv-gnu-toolchain) || true)) || ($(cd riscv-gnu-toolchain; git fetch; git rev-parse HEAD) != $(cd riscv-gnu-toolchain; git rev-parse master)) || (! -e $RISCV/riscv-gnu-toolchain/stamps/build-gcc-newlib-stage2) ]]; then
  cd riscv-gnu-toolchain
  git checkout master
  git pull
  ./configure --prefix="${RISCV}" --with-multilib-generator="rv32e-ilp32e--;rv32i-ilp32--;rv32im-ilp32--;rv32iac-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--;rv64i-lp64--;rv64ic-lp64--;rv64iac-lp64--;rv64imac-lp64--;rv64imafdc-lp64d--;rv64im-lp64--;"
  make -j ${NUM_THREADS}
fi

# elf2hex (https://github.com/sifive/elf2hex)
#The elf2hex utility to converts executable files into hexadecimal files for Verilog simulation. 
# Note: The exe2hex utility that comes with Spike doesn’t work for our purposes because it doesn’t 
# handle programs that start at 0x80000000. The SiFive version above is touchy to install. 
# For example, if Python version 2.x is in your path, it won’t install correctly. 
# Also, be sure riscv64-unknown-elf-objcopy shows up in your path in $RISCV/riscv-gnu-toolchain/bin 
# at the time of compilation, or elf2hex won’t work properly.
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing elf2hex"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd "$RISCV"
export PATH=$RISCV/bin:$PATH
if [[ ((! -e elf2hex) && ($(git clone https://github.com/sifive/elf2hex.git) || true)) || ($(cd elf2hex; git fetch; git rev-parse HEAD) != $(cd elf2hex; git rev-parse master)) || (! -e $RISCV/bin/riscv64-unknown-elf-elf2bin) ]]; then
  cd elf2hex
  git reset --hard && git clean -f && git checkout master && git pull
  autoreconf -i
  ./configure --target=riscv64-unknown-elf --prefix="$RISCV"
  make
  make install
fi


# QEMU (https://www.qemu.org/docs/master/system/target-riscv.html)
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing QEMU"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd "$RISCV"
if [[ ((! -e qemu) && ($(git clone --recurse-submodules https://github.com/qemu/qemu) || true)) || ($(cd qemu; git fetch --recurse-submodules=yes; git rev-parse HEAD) != $(cd qemu; git rev-parse master)) || (! -e $RISCV/include/qemu-plugin.h) ]]; then
  cd qemu
  git reset --hard && git clean -f && git checkout master && git pull --recurse-submodules
  ./configure --target-list=riscv64-softmmu --prefix="$RISCV"
  make -j ${NUM_THREADS}
  make install
fi

# Spike (https://github.com/riscv-software-src/riscv-isa-sim)
# Spike also takes a while to install and compile, but this can be done concurrently
# with the GCC installation.
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing SPIKE"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd "$RISCV"
if [[ ((! -e riscv-isa-sim) && ($(git clone https://github.com/riscv-software-src/riscv-isa-sim) || true)) || ($(cd riscv-isa-sim; git fetch; git rev-parse HEAD) != $(cd riscv-isa-sim; git rev-parse master)) || (! -e $RISCV/lib/pkgconfig/riscv-riscv.pc) ]]; then
  cd riscv-isa-sim
  git reset --hard && git clean -f && git checkout master && git pull
  mkdir -p build
  cd build
  ../configure --prefix="$RISCV"
  make -j ${NUM_THREADS}
  make install
fi


# Wally needs Verilator 5.021 or later.
# Verilator needs to be built from scratch to get the latest version
# apt-get install verilator installs version 4.028 as of 6/8/23
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing Verilator"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd "$RISCV"
if [[ ((! -e verilator) && ($(git clone https://github.com/verilator/verilator) || true)) || ($(cd verilator; git fetch; git rev-parse HEAD) != $(cd verilator; git rev-parse master)) || (! -e $RISCV/share/pkgconfig/verilator.pc) ]]; then
  # unsetenv VERILATOR_ROOT  # For csh; ignore error if on bash
  unset VERILATOR_ROOT     # For bash
  cd verilator
  git reset --hard && git clean -f && git checkout master && git pull
  autoconf         # Create ./configure script
  ./configure --prefix="$RISCV"     # Configure and create Makefile
  make -j ${NUM_THREADS}  # Build Verilator itself (if error, try just 'make')
  make install
fi

# RISC-V Sail Model (https://github.com/riscv/sail-riscv)
# The RISC-V Sail Model is the golden reference model for RISC-V. It is written in Sail,
# a language designed for expressing the semantics of an ISA. Sail itself is written in 
# OCaml, which is an object-oriented extension of ML, which in turn is a functional programming
# language suited to formal verification. The Sail compiler is installed with the opam OCcaml
# package manager. The Sail compiler has so many dependencies that it can be difficult to install,
# but a binary release of it should be available soon, removing the need to use opam.
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing Sail Compiler"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd "$RISCV"
opam init -y --disable-sandboxing
opam update -y
opam upgrade -y
opam switch create 5.1.0 || opam switch set 5.1.0
opam install sail -y

echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing RISC-V Sail Model"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
if [[ ((! -e sail-riscv) && ($(git clone https://github.com/riscv/sail-riscv.git) || true)) || ($(cd sail-riscv; git fetch; git rev-parse HEAD) != $(cd sail-riscv; git rev-parse master)) || (! -e $RISCV/bin/riscv_sim_RV32) ]]; then
  eval $(opam config env)
  cd sail-riscv
  git reset --hard && git clean -f && git checkout master && git pull
  export OPAMCLI=2.0  # Sail is not compatible with opam 2.1 as of 4/16/24
  ARCH=RV64 make -j ${NUM_THREADS} c_emulator/riscv_sim_RV64
  ARCH=RV32 make -j ${NUM_THREADS} c_emulator/riscv_sim_RV32
  cd "$RISCV"
  ln -sf ../sail-riscv/c_emulator/riscv_sim_RV64 bin/riscv_sim_RV64
  ln -sf ../sail-riscv/c_emulator/riscv_sim_RV32 bin/riscv_sim_RV32
fi

# riscof
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing riscof"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
pip3 install git+https://github.com/riscv/riscof.git

# Download OSU Skywater 130 cell library
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing OSU Skywater 130 cell library"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
mkdir -p "$RISCV"/cad/lib
cd "$RISCV"/cad/lib
if [[ ((! -e sky130_osu_sc_t12) && ($(git clone https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12) || true)) || ($(cd sky130_osu_sc_t12; git fetch; git rev-parse HEAD) != $(cd sky130_osu_sc_t12; git rev-parse master)) ]]; then
  cd sky130_osu_sc_t12
  git reset --hard && git clean -f && git checkout main && git pull
fi
