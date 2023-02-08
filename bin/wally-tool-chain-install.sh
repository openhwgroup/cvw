#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Ross Thompson ross1728@gmail.com
## Created: 18 January 2023
## Modified: 22 January 2023
##
## Purpose: Open source tool chain installation script
##
## A component of the CORE-V-WALLY configurable RISC-V project.
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

export RISCV="${1:-/opt/riscv}"
export PATH=$PATH:$RISCV/bin

set -e # break on error

NUM_THREADS=1 # for low memory machines > 16GiB
#NUM_THREADS=8  # for >= 32GiB
#NUM_THREADS=16  # for >= 64GiB

sudo mkdir -p $RISCV

# UPDATE / UPGRADE
apt update

# INSTALL 
apt install -y git gawk make texinfo bison flex build-essential python3 libz-dev libexpat-dev autoconf device-tree-compiler ninja-build libpixman-1-dev build-essential ncurses-base ncurses-bin libncurses5-dev dialog curl wget ftp libgmp-dev

# needed for Ubuntu 22.04, gcc cross compiler expects python not python2 or python3.
if ! command -v python &> /dev/null
then
    echo "WARNING: python3 was installed as python3 rather than python. Creating symlink."
    ln -sf /usr/bin/python3 /usr/bin/python
fi

# gcc cross-compiler
cd $RISCV
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
git checkout 2023.01.31 
./configure --prefix=${RISCV} --with-multilib-generator="rv32e-ilp32e--;rv32i-ilp32--;rv32im-ilp32--;rv32iac-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--;rv64i-lp64--;rv64ic-lp64--;rv64iac-lp64--;rv64imac-lp64--;rv64imafdc-lp64d--;rv64im-lp64--;"
make -j ${NUM_THREADS}
make install

# elf2hex
cd $RISCV
#export PATH=$RISCV/riscv-gnu-toolchain/bin:$PATH
gexport PATH=$RISCV/bin:$PATH
git clone https://github.com/sifive/elf2hex.git
cd elf2hex
autoreconf -i
./configure --target=riscv64-unknown-elf --prefix=$RISCV
make
make install

# Update Python3.6 for QEMU
apt-get -y update
apt-get -y install python3-pip
apt-get -y install pkg-config
apt-get -y install libglib2.0-dev

# QEMU
cd $RISCV
git clone --recurse-submodules https://github.com/qemu/qemu
cd qemu
./configure --target-list=riscv64-softmmu --prefix=$RISCV 
make -j ${NUM_THREADS}
make install

# Spike
cd $RISCV
git clone https://github.com/riscv-software-src/riscv-isa-sim
mkdir -p riscv-isa-sim/build
cd riscv-isa-sim/build
../configure --prefix=$RISCV 
make -j ${NUM_THREADS}
make install 
cd ../arch_test_target/spike/device
sed -i 's/--isa=rv32ic/--isa=rv32iac/' rv32i_m/privilege/Makefile.include
sed -i 's/--isa=rv64ic/--isa=rv64iac/' rv64i_m/privilege/Makefile.include

# SAIL
cd $RISCV
apt-get install -y opam  build-essential libgmp-dev z3 pkg-config zlib1g-dev
git clone https://github.com/Z3Prover/z3.git
cd z3
python scripts/mk_make.py
cd build
make  -j ${NUM_THREADS}
make install
cd ../..
pip3 install chardet==3.0.4
pip3 install urllib3==1.22
opam init -y --disable-sandboxing
opam switch create ocaml-base-compiler.4.06.1
opam install sail -y 

eval $(opam config env)
git clone https://github.com/riscv/sail-riscv.git
cd sail-riscv
make -j ${NUM_THREADS}
ARCH=RV32 make
ARCH=RV64 make
ln -sf $RISCV/sail-riscv/c_emulator/riscv_sim_RV64 /usr/bin/riscv_sim_RV64
ln -sf $RISCV/sail-riscv/c_emulator/riscv_sim_RV32 /usr/bin/riscv_sim_RV32

pip3 install testresources
pip3 install riscof --ignore-installed PyYAML

# Verilator
apt install -y verilator

# install github cli (gh)
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
