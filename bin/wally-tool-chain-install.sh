#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Ross Thompson ross1728@gmail.com
## Created: 18 January 2023
## Modified: 22 January 2023
## Modified: 23 March 2023
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

# Use /opt/riscv for installation - may require running script with sudo
export RISCV="${1:-/opt/riscv}"
export PATH=$PATH:$RISCV/bin:/usr/bin

set -e # break on error

# Modify accordingly for your machine
# Increasing NUM_THREADS will speed up parallel compilation of the tools
#NUM_THREADS=2 # for low memory machines > 16GiB
NUM_THREADS=8  # for >= 32GiB
#NUM_THREADS=16  # for >= 64GiB

sudo mkdir -p $RISCV
# *** need to update permissions to local user

# Update and Upgrade tools (see https://itsfoss.com/apt-update-vs-upgrade/)
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git gawk make texinfo bison flex build-essential python3 libz-dev libexpat-dev autoconf device-tree-compiler ninja-build libpixman-1-dev ncurses-base ncurses-bin libncurses5-dev dialog curl wget ftp libgmp-dev libglib2.0-dev python3-pip pkg-config opam z3 zlib1g-dev automake autotools-dev libmpc-dev libmpfr-dev  gperf libtool patchutils bc mutt ssmtp
# Other python libraries used through the book.
sudo pip3 install sphinx sphinx_rtd_theme matplotlib scipy scikit-learn adjustText lief markdown 

# needed for Ubuntu 22.04, gcc cross compiler expects python not python2 or python3.
if ! command -v python &> /dev/null
then
    echo "WARNING: python3 was installed as python3 rather than python. Creating symlink."
    sudo ln -sf /usr/bin/python3 /usr/bin/python
fi

# gcc cross-compiler (https://github.com/riscv-collab/riscv-gnu-toolchain)
# To install GCC from source can take hours to compile. 
# This configuration enables multilib to target many flavors of RISC-V.   
# This book is tested with GCC 13.2.0
# Versions newer than 2023-12-20 fail to compile the RISC-V arch test with an error:
# cvw/addins/riscv-arch-test/riscv-test-suite/rv32i_m/I/src/jalr-01.S:72: Error: illegal operands `la x0,5b'
# PR *** submitted to fix riscv-arch-test to be compatible with latest GCC by modifying test_macros.h for TEST_JALR_OP
cd $RISCV
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=${RISCV} --with-multilib-generator="rv32e-ilp32e--;rv32i-ilp32--;rv32im-ilp32--;rv32iac-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--;rv64i-lp64--;rv64ic-lp64--;rv64iac-lp64--;rv64imac-lp64--;rv64imafdc-lp64d--;rv64im-lp64--;"
make -j 8

# elf2hex (https://github.com/sifive/elf2hex)
#The elf2hex utility to converts executable files into hexadecimal files for Verilog simulation. 
# Note: The exe2hex utility that comes with Spike doesn’t work for our purposes because it doesn’t 
# handle programs that start at 0x80000000. The SiFive version above is touchy to install. 
# For example, if Python version 2.x is in your path, it won’t install correctly. 
# Also, be sure riscv64-unknown-elf-objcopy shows up in your path in $RISCV/riscv-gnu-toolchain/bin 
# at the time of compilation, or elf2hex won’t work properly.
cd $RISCV
export PATH=$RISCV/bin:$PATH
git clone https://github.com/sifive/elf2hex.git
cd elf2hex
autoreconf -i
./configure --target=riscv64-unknown-elf --prefix=$RISCV
make
make install


# QEMU (https://www.qemu.org/docs/master/system/target-riscv.html)
cd $RISCV
git clone --recurse-submodules https://github.com/qemu/qemu
cd qemu
./configure --target-list=riscv64-softmmu --prefix=$RISCV 
make -j 8
make install

# Spike (https://github.com/riscv-software-src/riscv-isa-sim)
# Spike also takes a while to install and compile, but this can be done concurrently 
# with the GCC installation. 
cd $RISCV
git clone https://github.com/riscv-software-src/riscv-isa-sim
mkdir -p riscv-isa-sim/build
cd riscv-isa-sim/build
../configure --prefix=$RISCV 
make -j 8
make install 


# Wally needs Verilator 5.021 or later.
# Verilator needs to be built from scratch to get the latest version
# apt-get install verilator installs version 4.028 as of 6/8/23
sudo apt-get install -y perl g++ ccache help2man libgoogle-perftools-dev numactl perl-doc zlib1g 
sudo apt-get install -y perl g++ ccache help2man libgoogle-perftools-dev numactl perl-doc zlib1g 
cd $RISCV
git clone https://github.com/verilator/verilator   # Only first time
# unsetenv VERILATOR_ROOT  # For csh; ignore error if on bash
unset VERILATOR_ROOT     # For bash
cd verilator
git pull         # Make sure git repository is up-to-date
git checkout master      
autoconf         # Create ./configure script
./configure      # Configure and create Makefile
make -j 8  # Build Verilator itself (if error, try just 'make')
sudo make install

# Sail (https://github.com/riscv/sail-riscv)
# Sail is the new golden reference model for RISC-V.  Sail is written in OCaml, which 
# is an object-oriented extension of ML, which in turn is a functional programming 
# language suited to formal verification.  OCaml is installed with the opam OCcaml 
# package manager. Sail has so many dependencies that it can be difficult to install.
# This script works for Ubuntu.

# Alex Solomatnikov found these commands worked to build Sail for Centos 8 on 1/12/24
#sudo su -
#dnf install ocaml.x86_64
#pip3 install z3-solver
#wget https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh
#sh install.sh
#opam init
#exit
#ocaml -version
#opam switch create 5.1.0
#eval $(opam config env)
#git clone --recurse-submodules git@github.com:riscv/sail-riscv.git
#cd sail-riscv
#make
#ARCH=RV32 make
#ARCH=RV64 make
#git log -1
#cp -p c_emulator/riscv_sim_RV* /tools/sail-riscv/d7a3d8012fd579f40e53a29569141d72dd5e0c32/bin/.


# This was an earlier attemp to prepare to install Sail on RedHat 8
# Do these commands only for RedHat / Rocky 8 to build from source.
#cd $RISCV
#git clone https://github.com/Z3Prover/z3.git
#cd z3
#python scripts/mk_make.py
#cd build
#make  -j 8
#make install
#cd ../..
#pip3 install chardet==3.0.4
#pip3 install urllib3==1.22

cd $RISCV
opam init -y --disable-sandboxing
opam update
opam upgrade
opam switch create 5.1.0
opam install sail -y 

eval $(opam config env)
git clone https://github.com/riscv/sail-riscv.git
cd sail-riscv
# For now, use checkout that is stable for Wally
#git checkout 72b2516d10d472ac77482fd959a9401ce3487f60  # not new enough for Zicboz?
export OPAMCLI=2.0  # Sail is not compatible with opam 2.1 as of 4/16/24
ARCH=RV64 make -j 8 c_emulator/riscv_sim_RV64
ARCH=RV32 make -j 8 c_emulator/riscv_sim_RV32
sudo ln -sf $RISCV/sail-riscv/c_emulator/riscv_sim_RV64 /usr/bin/riscv_sim_RV64
sudo ln -sf $RISCV/sail-riscv/c_emulator/riscv_sim_RV32 /usr/bin/riscv_sim_RV32

# riscof
sudo pip3 install -U testresources riscv_config
sudo pip3 install git+https://github.com/riscv/riscof.git

# Download OSU Skywater 130 cell library
sudo mkdir -p $RISCV/cad/lib
cd $RISCV/cad/lib
sudo git clone https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12
