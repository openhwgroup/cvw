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

# MODIFY FOR YOUR MACHINE
# Increasing NUM_THREADS will speed up parallel compilation of the tools
#NUM_THREADS=2 # for low memory machines > 16GiB
NUM_THREADS=8  # for >= 32GiB
#NUM_THREADS=16  # for >= 64GiB

echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Checking Distro and Permissions and Setting Installation Directory"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"

set -e # break on error

# Get distribution information
test -e /etc/os-release && os_release="/etc/os-release" || os_release="/usr/lib/os-release"
source $os_release

# Check for compatible distro
if [[ $ID = rhel || $ID = rocky ]]; then
  FAMILY=rhel
  if [ "${VERSION_ID:0:1}" = 8 ]; then
    RHEL_VERSION=8
  elif [ "${VERSION_ID:0:1}" = 9 ]; then
    RHEL_VERSION=9
  else
    echo "The Wally install script is only compatible with versions 8 and 9 of RHEL and Rocky Linux. You have version $VERSION."
    exit 1
  fi
elif [[ $ID = ubuntu || $ID_LIKE = *ubuntu* ]]; then
  FAMILY=ubuntu
else
  echo "The Wally install script is currently only compatible with Ubuntu and Red Hat family \
(RHEL or Rocky Linux) distros. Your detected distro is $ID. You may try manually running the \
commands in this script, but it is likely that some will need to be altered."
  exit 1
fi

# Check if root
ROOT=$( [ "${EUID:=$(id -u)}" = 0 ] && echo 1 || echo 0);

# All tools will be installed under the $RISCV directory. By default, if run as root (with sudo)
# this is set to /opt/riscv. Otherwise, it is set to ~/riscv. This value can be changed if needed.
if [ $ROOT = 1 ]; then
  export RISCV=/opt/riscv
else
  export RISCV=~/riscv
fi

export PATH=$PATH:$RISCV/bin:/usr/bin
export PKG_CONFIG_PATH=$RISCV/lib64/pkgconfig:$RISCV/lib/pkgconfig:$PKG_CONFIG_PATH
mkdir -p $RISCV

echo "Detected information:"
echo "Distribution: $NAME"
echo "Version: $VERSION"
echo "Running as root: $ROOT"
echo "Installation path: $RISCV"

echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing Dependencies from Package Manager"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
if [ $FAMILY = rhel ]; then
  sudo dnf install -y dnf-plugins-core
  if [ $ID = rocky ]; then
    if [ $RHEL_VERSION = 8 ]; then
      sudo dnf config-manager -y --set-enabled powertools
    else # Version 9
      sudo dnf config-manager -y --set-enabled crb
    fi
    sudo dnf install -y epel-release
  else # RHEL
    if [ $RHEL_VERSION = 8 ]; then
      sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
      sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    else # Version 9
      sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms
      sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    fi
  fi
  sudo dnf update -y
  sudo dnf group install -y "Development Tools"
  sudo dnf install -y git gawk make texinfo bison flex python3.12 expat-devel autoconf dtc ninja-build pixman-devel ncurses-base ncurses ncurses-libs ncurses-devel dialog curl wget ftp gmp-devel glib2-devel python3-pip pkgconfig zlib-devel automake libmpc-devel mpfr-devel gperf libtool patchutils bc mutt cmake perl gcc-c++ clang help2man numactl ocaml mold gperftools ccache
  if [ $RHEL_VERSION = 9 ]; then
    sudo dnf install -y z3
  fi
  sudo dnf install -y gcc-toolset-13*

  # activate gcc13
  source /opt/rh/gcc-toolset-13/enable
fi

echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Setting up Python Environment"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd $RISCV
if [ ! -e $RISCV/riscv-python/bin/activate ]; then
  python3.12 -m venv riscv-python
fi
source $RISCV/riscv-python/bin/activate
pip install -U pip
pip install -U sphinx sphinx_rtd_theme matplotlib scipy scikit-learn adjustText lief markdown pyyaml meson testresources riscv_config
pip install -U riscv_isac # to generate new tests, such as quads with fp_dataset.py
if [ $RHEL_VERSION = 8 ]; then
  pip install -U z3-solver
fi

source $RISCV/riscv-python/bin/activate

if [ $RHEL_VERSION = 8 ]; then
  # Other dependencies
  # newer versin of glib required for Qemu
  # anything newer than this won't build on red hat 8
  if [ ! -e $RISCV/include/glib-2.0 ]; then
    echo -e "\n*************************************************************************"
    echo -e "*************************************************************************"
    echo -e "Installing glib"
    echo -e "*************************************************************************"
    echo -e "*************************************************************************\n"
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
  fi
  # newer version of gmp needed for sail-riscv model
  if [ ! -e $RISCV/include/gmp.h ]; then
    echo -e "\n*************************************************************************"
    echo -e "*************************************************************************"
    echo -e "Installing gmp"
    echo -e "*************************************************************************"
    echo -e "*************************************************************************\n"
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
  fi
fi

# gcc cross-compiler (https://github.com/riscv-collab/riscv-gnu-toolchain)
# To install GCC from source can take hours to compile.
# This configuration enables multilib to target many flavors of RISC-V.   
# This book is tested with GCC 13.2.0
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing RISC-V GNU Toolchain"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd $RISCV
if [[ ((! -e riscv-gnu-toolchain) && ($(git clone https://github.com/riscv/riscv-gnu-toolchain) || 1)) || ($(cd riscv-gnu-toolchain; git fetch; git rev-parse HEAD) != $(cd riscv-gnu-toolchain; git rev-parse master)) ]]; then
  cd riscv-gnu-toolchain
  git checkout master
  git pull
  ./configure --prefix=${RISCV} --with-multilib-generator="rv32e-ilp32e--;rv32i-ilp32--;rv32im-ilp32--;rv32iac-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--;rv64i-lp64--;rv64ic-lp64--;rv64iac-lp64--;rv64imac-lp64--;rv64imafdc-lp64d--;rv64im-lp64--;"
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
cd $RISCV
export PATH=$RISCV/bin:$PATH
if [[ ((! -e elf2hex) && ($(git clone https://github.com/sifive/elf2hex.git) || 1)) || ($(cd elf2hex; git fetch; git rev-parse HEAD) != $(cd elf2hex; git rev-parse master)) ]]; then
  cd elf2hex
  git checkout master
  git pull
  autoreconf -i
  ./configure --target=riscv64-unknown-elf --prefix=$RISCV
  make
  make install
fi


# QEMU (https://www.qemu.org/docs/master/system/target-riscv.html)
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing QEMU"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd $RISCV
if [[ ((! -e qemu) && ($(git clone --recurse-submodules https://github.com/qemu/qemu) || 1)) || ($(cd qemu; git fetch --recurse-submodules=yes; git rev-parse HEAD) != $(cd qemu; git rev-parse master)) ]]; then
  cd qemu
  git checkout master
  git pull --recurse-submodules
  ./configure --target-list=riscv64-softmmu --prefix=$RISCV
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
cd $RISCV
if [[ ((! -e riscv-isa-sim) && ($(git clone https://github.com/riscv-software-src/riscv-isa-sim) || 1)) || ($(cd riscv-isa-sim; git fetch; git rev-parse HEAD) != $(cd riscv-isa-sim; git rev-parse master)) ]]; then
  cd riscv-isa-sim
  git checkout master
  git pull
  mkdir -p build
  cd build
  ../configure --prefix=$RISCV
  make -j ${NUM_THREADS}
  make install
fi


# Wally needs Verilator 5.021 or later.
# Verilator needs to be built from source to get the latest version
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing Verilator"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd $RISCV
if [[ ((! -e verilator) && ($(git clone https://github.com/verilator/verilator) || 1)) || ($(cd verilator; git fetch; git rev-parse HEAD) != $(cd verilator; git rev-parse master)) ]]; then
  # unsetenv VERILATOR_ROOT  # For csh; ignore error if on bash
  unset VERILATOR_ROOT     # For bash
  cd verilator
  git checkout master
git pull         # Make sure git repository is up-to-date
git pull         # Make sure git repository is up-to-date
git checkout master
  git pull         # Make sure git repository is up-to-date
git checkout master
  autoconf         # Create ./configure script
  ./configure --prefix=$RISCV     # Configure and create Makefile
  make -j ${NUM_THREADS}  # Build Verilator itself (if error, try just 'make')
  make install
fi

# Sail (https://github.com/riscv/sail-riscv)
# Sail is the golden reference model for RISC-V.  Sail is written in OCaml, which
# is an object-oriented extension of ML, which in turn is a functional programming
# language suited to formal verification.  OCaml is installed with the opam OCcaml
# package manager. Sail has so many dependencies that it can be difficult to install.
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing Opam"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
cd $RISCV
mkdir -p opam
cd opam
wget https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh
printf '%s\n' $RISCV/bin Y | sh install.sh # the print command provides $RISCV/bin as the installation path when prompted
cd $RISCV
rm -rf opam
echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing Sail Compiler"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
opam init -y --disable-sandboxing
opam update -y
opam upgrade -y
opam switch create 5.1.0 || opam switch set 5.1.0
opam install sail -y

echo -e "\n*************************************************************************"
echo -e "*************************************************************************"
echo -e "Installing riscv-sail Model"
echo -e "*************************************************************************"
echo -e "*************************************************************************\n"
eval $(opam config env)
if [[ ((! -e sail-riscv) && ($(git clone https://github.com/riscv/sail-riscv.git) || 1)) || ($(cd sail-riscv; git fetch; git rev-parse HEAD) != $(cd sail-riscv; git rev-parse master)) ]]; then
  cd sail-riscv
  git checkout master
  git pull
  export OPAMCLI=2.0  # Sail is not compatible with opam 2.1 as of 4/16/24
  ARCH=RV64 make -j ${NUM_THREADS} c_emulator/riscv_sim_RV64
  ARCH=RV32 make -j ${NUM_THREADS} c_emulator/riscv_sim_RV32
  cd $RISCV
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
mkdir -p $RISCV/cad/lib
cd $RISCV/cad/lib
if [[ ((! -e sky130_osu_sc_t12) && ($(git clone https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12) || 1)) || ($(cd sky130_osu_sc_t12; git fetch; git rev-parse HEAD) != $(cd sky130_osu_sc_t12; git rev-parse master)) ]]; then
  cd sky130_osu_sc_t12
  git checkout main
  git pull
fi