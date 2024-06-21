#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Ross Thompson ross1728@gmail.com
## Created: 18 January 2023
## Modified: 22 January 2023
## Modified: 23 March 2023
## Adapted for Red Hat: June 19 2024, Jordan Carlin jcarlin@hmc.edu
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

# All tools will be installed under the $RISCV directory. Depending on the location selected,
# the script may need to be run as root
export RISCV=/opt/riscv
export PATH=$PATH:$RISCV/bin:/usr/bin
export PKG_CONFIG_PATH=$RISCV/lib64/pkgconfig:$RISCV/lib/pkgconfig:$PKG_CONFIG_PATH

set -e # break on error

# Modify accordingly for your machine
# Increasing NUM_THREADS will speed up parallel compilation of the tools
#NUM_THREADS=2 # for low memory machines > 16GiB
NUM_THREADS=8  # for >= 32GiB
#NUM_THREADS=16  # for >= 64GiB

mkdir -p $RISCV

# Dependencies in package manager
echo -e "\n************************************************************"
echo -e "Installing Dependencies from Package Manager"
echo -e "************************************************************\n"
sudo yum install -y dnf-plugins-core
sudo yum config-manager --set-enabled powertools # FOR ROCKY
# sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms # FOR RHEL
sudo yum update -y
sudo yum group install -y "Development Tools"
sudo yum install -y git gawk make texinfo bison flex python3.12 expat-devel autoconf dtc ninja-build pixman-devel ncurses-base ncurses ncurses-libs ncurses-devel dialog curl wget ftp gmp-devel glib2-devel python3-pip pkgconfig zlib-devel automake libmpc-devel mpfr-devel gperf libtool patchutils bc mutt cmake perl gcc-c++ clang help2man numactl ocaml
sudo yum install -y gcc-toolset-13*

# activate gcc13
source /opt/rh/gcc-toolset-13/enable

# Python virtual environment and package installation
echo -e "\n************************************************************"
echo -e "Setting up Python Environment"
echo -e "************************************************************\n"
cd $RISCV
python3.12 -m venv --system-site-packages riscv-python
source $RISCV/riscv-python/bin/activate
pip install --upgrade pip
pip install sphinx sphinx_rtd_theme matplotlib scipy scikit-learn adjustText lief markdown pyyaml meson z3-solver testresources riscv_config
pip install riscv_isac # to generate new tests, such as quads with fp_dataset.py
source $RISCV/riscv-python/bin/activate

# Other dependencies
# newer versin of glib required for Qemu
# anything newer than this won't build on red hat 8
echo -e "\n************************************************************"
echo -e "Installing glib"
echo -e "************************************************************\n"
cd $RISCV
wget https://download.gnome.org/sources/glib/2.70/glib-2.70.5.tar.xz
tar -xJf glib-2.70.5.tar.xz
rm glib-2.70.5.tar.xz
cd glib-2.70.5
meson setup _build --prefix=$RISCV
meson compile -C _build
meson install -C _build
cd $RISCV
rm -rf glib-2.70.5
# gperftools - not available in yum, needed for Verilator
echo -e "\n************************************************************"
echo -e "Installing gperftools"
echo -e "************************************************************\n"
cd $RISCV
wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.15/gperftools-2.15.tar.gz
tar -xzf gperftools-2.15.tar.gz
rm gperftools-2.15.tar.gz
cd gperftools-2.15
./configure --prefix=$RISCV
make -j ${NUM_THREADS}
make install
cd $RISCV
rm -rf gperftools-2.15
# ccache - not available in yum, needed for Verilator
echo -e "\n************************************************************"
echo -e "Installing ccache"
echo -e "************************************************************\n"
cd $RISCV
wget https://github.com/ccache/ccache/releases/download/v4.10/ccache-4.10-linux-x86_64.tar.xz
tar -xJf ccache-4.10-linux-x86_64.tar.xz
rm ccache-4.10-linux-x86_64.tar.xz
cd ccache-4.10-linux-x86_64
cp ccache $RISCV/bin/ccache
cd $RISCV
rm -rf ccache-4.10-linux-x86_64
# newer version of gmp needed for sail-riscv model
echo -e "\n************************************************************"
echo -e "Installing gmp"
echo -e "************************************************************\n"
cd $RISCV
wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
tar -xJf gmp-6.3.0.tar.xz
rm gmp-6.3.0.tar.xz
cd gmp-6.3.0
./configure --prefix=$RISCV
make -j ${NUM_THREADS}
make install
cd $RISCV
rm -rf gmp-6.3.0

# gcc cross-compiler (https://github.com/riscv-collab/riscv-gnu-toolchain)
# To install GCC from source can take hours to compile.
# This configuration enables multilib to target many flavors of RISC-V.
# This book is tested with GCC 13.2.0
echo -e "\n************************************************************"
echo -e "Installing RISC-V GNU Toolchain"
echo -e "************************************************************\n"
cd $RISCV
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=${RISCV} --with-multilib-generator="rv32e-ilp32e--;rv32i-ilp32--;rv32im-ilp32--;rv32iac-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--;rv64i-lp64--;rv64ic-lp64--;rv64iac-lp64--;rv64imac-lp64--;rv64imafdc-lp64d--;rv64im-lp64--;"
make -j ${NUM_THREADS}

# elf2hex (https://github.com/sifive/elf2hex)
#The elf2hex utility to converts executable files into hexadecimal files for Verilog simulation.
# Note: The exe2hex utility that comes with Spike doesn’t work for our purposes because it doesn’t
# handle programs that start at 0x80000000. The SiFive version above is touchy to install.
# For example, if Python version 2.x is in your path, it won’t install correctly.
# Also, be sure riscv64-unknown-elf-objcopy shows up in your path in $RISCV/riscv-gnu-toolchain/bin
# at the time of compilation, or elf2hex won’t work properly.
echo -e "\n************************************************************"
echo -e "Installing elf2hex"
echo -e "************************************************************\n"
cd $RISCV
export PATH=$RISCV/bin:$PATH
git clone https://github.com/sifive/elf2hex.git
cd elf2hex
autoreconf -i
./configure --target=riscv64-unknown-elf --prefix=$RISCV
make
make install


# QEMU (https://www.qemu.org/docs/master/system/target-riscv.html)
echo -e "\n************************************************************"
echo -e "Installing QEMU"
echo -e "************************************************************\n"
cd $RISCV
git clone --recurse-submodules https://github.com/qemu/qemu
cd qemu
./configure --target-list=riscv64-softmmu --prefix=$RISCV
make -j ${NUM_THREADS}
make install

# Spike (https://github.com/riscv-software-src/riscv-isa-sim)
# Spike also takes a while to install and compile, but this can be done concurrently
# with the GCC installation.
echo -e "\n************************************************************"
echo -e "Installing SPIKE"
echo -e "************************************************************\n"
cd $RISCV
git clone https://github.com/riscv-software-src/riscv-isa-sim
mkdir -p riscv-isa-sim/build
cd riscv-isa-sim/build
../configure --prefix=$RISCV
make -j ${NUM_THREADS}
make install


# Wally needs Verilator 5.021 or later.
# Verilator needs to be built from source to get the latest version
echo -e "\n************************************************************"
echo -e "Installing Verilator"
echo -e "************************************************************\n"
cd $RISCV
git clone https://github.com/verilator/verilator   # Only first time
# unsetenv VERILATOR_ROOT  # For csh; ignore error if on bash
unset VERILATOR_ROOT     # For bash
cd verilator
git pull         # Make sure git repository is up-to-date
git checkout master
autoconf         # Create ./configure script
./configure --prefix=$RISCV     # Configure and create Makefile
make -j ${NUM_THREADS}  # Build Verilator itself (if error, try just 'make')
make install

# Sail (https://github.com/riscv/sail-riscv)
# Sail is the golden reference model for RISC-V.  Sail is written in OCaml, which
# is an object-oriented extension of ML, which in turn is a functional programming
# language suited to formal verification.  OCaml is installed with the opam OCcaml
# package manager. Sail has so many dependencies that it can be difficult to install.
echo -e "\n************************************************************"
echo -e "Installing Opam"
echo -e "************************************************************\n"
cd $RISCV
mkdir -p opam
cd opam
wget https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh
printf '%s\n' $RISCV/bin Y | sh install.sh # the print command provides $RISCV/bin as the installation path when prompted
cd $RISCV
rm -rf opam
echo -e "\n************************************************************"
echo -e "Installing Sail Compiler"
echo -e "************************************************************\n"
opam init -y --disable-sandboxing
opam update
opam upgrade
opam switch create 5.1.0
opam install sail -y

echo -e "\n************************************************************"
echo -e "Installing riscv-sail Model"
echo -e "************************************************************\n"
eval $(opam config env)
git clone https://github.com/riscv/sail-riscv.git
cd sail-riscv
export OPAMCLI=2.0  # Sail is not compatible with opam 2.1 as of 4/16/24
ARCH=RV64 make -j ${NUM_THREADS} c_emulator/riscv_sim_RV64
ARCH=RV32 make -j ${NUM_THREADS} c_emulator/riscv_sim_RV32
cd $RISCV
ln -sf sail-riscv/c_emulator/riscv_sim_RV64 bin/riscv_sim_RV64
ln -sf sail-riscv/c_emulator/riscv_sim_RV32 bin/riscv_sim_RV32

# riscof
echo -e "\n************************************************************"
echo -e "Installing riscof"
echo -e "************************************************************\n"
pip3 install git+https://github.com/riscv/riscof.git

# Download OSU Skywater 130 cell library
echo -e "\n************************************************************"
echo -e "Installing OSU Skywater 130 cell library"
echo -e "************************************************************\n"
mkdir -p $RISCV/cad/lib
cd $RISCV/cad/lib
git clone https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12
