#!/bin/bash
###########################################
## Tool chain install script.
##
## Written: Rose Thompson rose@rosethompson.net
## Created: 18 January 2023
## Modified: 22 January 2023
## Modified: 23 March 2023
## Modified: 30 June 2024, Jordan Carlin jcarlin@hmc.edu
## Modified: 1 September 2024
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

# Increasing NUM_THREADS will speed up parallel compilation of the tools
NUM_THREADS=$(nproc --ignore 1) # One less than the total number of threads

# Colors
BOLD='\033[1m'
UNDERLINE='\033[4m'
SECTION_COLOR='\033[95m'$BOLD
OK_COLOR='\033[94m'
SUCCESS_COLOR='\033[92m'
WARNING_COLOR='\033[93m'
FAIL_COLOR='\033[91m'
ENDC='\033[0m' # Reset to default color

## Helper functions
# Error handler
error() {
    echo -e "${FAIL_COLOR}Error: $STATUS installation failed"
    echo -e "Error on line ${BASH_LINENO[0]} with command $BASH_COMMAND${ENDC}"
    if [ -e "$RISCV/logs/$STATUS.log" ]; then
        echo -e "Please check the log in $RISCV/logs/$STATUS.log for more information."
    fi
    exit 1
}

# Check if a git repository exists, is up to date, and has been installed
# clones the repository if it doesn't exist
# $1: repo name
# $2: repo url to clone from
# $3: file to check if already installed
# $4: upstream branch, optional, default is master
git_check() {
    local repo=$1
    local url=$2
    local check=$3
    local branch="${4:-master}"

    # Clone repo if it doesn't exist
    if [[ ! -e $repo ]]; then
        for ((i=1; i<=5; i++)); do
            git clone "$url" && break
            echo -e "${WARNING_COLOR}Failed to clone $repo. Retrying.${ENDC}"
            rm -rf "$repo"
            sleep $i
        done
        if [[ ! -e $repo ]]; then
            echo -e "${ERROR_COLOR}Failed to clone $repo after 5 attempts. Exiting.${ENDC}"
            exit 1
        fi
    fi

    # Get the current HEAD commit hash and the remote branch commit hash
    cd "$repo"
    git fetch
    local local_head=$(git rev-parse HEAD)
    local remote_head=$(git rev-parse origin/"$branch")

    # Check if the git repository is not up to date or the specified file does not exist
    if [[ "$local_head" != "$remote_head" ]]; then
        echo "$repo is not up to date. Updating now."
        true
    elif [[ ! -e $check ]]; then
        true
    else
        false
    fi
}

# Log output to a file and only print lines with keywords
logger() {
    local log_file="$RISCV/logs/$STATUS.log"
    local keyword_pattern="(\bwarning|\berror|\bfail|\bsuccess|\bstamp|\bdoesn't work)"
    local exclude_pattern="(_warning|warning_|_error|error_|-warning|warning-|-error|error-|Werror|error\.o|warning flags)"

    cat < /dev/stdin | tee -a "$log_file" | \
    (grep -iE --color=never "$keyword_pattern" || true) | \
    (grep -viE --color=never "$exclude_pattern" || true)
}

set -e # break on error
trap error ERR # run error handler on error
STATUS="setup" # keep track of what part of the installation is running for error messages

# Check for clean flag
if [ "$1" == "--clean" ] || [ "$2" == "--clean" ]; then
    clean=true
    shift
fi

# Check for no-buildroot flag
if [ "$1" == "--no-buildroot" ] || [ "$2" == "--no-buildroot" ]; then
    no_buidroot=true
    shift
fi

# Determine script directory to locate related scripts
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLY=$(dirname "$dir")
export WALLY

# Get Linux distro and version
source "${dir}"/wally-distro-check.sh

# Check if root
ROOT=$( [ "${EUID:=$(id -u)}" == 0 ] && echo true || echo false);

# Set installation directory based on execution privileges
# If the script is run as root, the default installation path is /opt/riscv
# If the script is run as a user, the default installation path is ~/riscv
# The installation path can be overridden with an argument passed to the script.
if [ "$ROOT" == true ]; then
    export RISCV="${1:-/opt/riscv}"
else
    export RISCV="${1:-$HOME/riscv}"
fi

# Set environment variables
export PATH=$PATH:$RISCV/bin:/usr/bin
export PKG_CONFIG_PATH=$RISCV/lib64/pkgconfig:$RISCV/lib/pkgconfig:$RISCV/share/pkgconfig:$RISCV/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH

# wget retry on host error flag not available with older wget on RHEL 8
if (( RHEL_VERSION != 8 )); then
    retry_on_host_error="--retry-on-host-error"
fi

# Check for incompatible PATH environment variable before proceeding with installation
if [[ ":$PATH:" == *::* || ":$PATH:" == *:.:* ]]; then
    echo -e "${FAIL_COLOR}Error: You seem to have the current working directory in your \$PATH environment variable."
    echo -e "This won't work. Please update your \$PATH and try again.${ENDC}"
    exit 1
fi

# Check available memory
total_mem=$(grep MemTotal < /proc/meminfo | awk '{print $2}')
total_mem_gb=$((total_mem / 1024 / 1024))

# Print system information
echo "Running as root: $ROOT"
echo "Installation path: $RISCV"
echo "Number of cores: $(nproc)"
echo "Total memory: $total_mem_gb GB"

# Reduce number of threads for systems with less than 8 GB of memory
if ((total_mem < 8400000 )) ; then
    NUM_THREADS=1
    echo -e "${WARNING_COLOR}Detected less than or equal to 8 GB of memory. Using a single thread for compiling tools. This may take a while.${ENDC}"
fi

# Print number of threads
echo "Using $NUM_THREADS thread(s) for compilation"

# Create installation directory
mkdir -p "$RISCV"/logs

# Install/update system packages if root. Otherwise, check that packages are already installed.
STATUS="system_packages"
if [ "$ROOT" == true ]; then
    source "${dir}"/wally-package-install.sh
else
    source "${dir}"/wally-package-install.sh --check
fi

# Older version of git defaults to protocol version incompatible with riscv-gnu-toolchain
if (( UBUNTU_VERSION == 20 )); then
    git config --global protocol.version 2
fi

# Enable newer version of gcc for older distros (required for QEMU/Verilator)
if [ "$FAMILY" == rhel ]; then
    source /opt/rh/gcc-toolset-13/enable
elif [ "$FAMILY" == suse ]; then
    mkdir -p "$RISCV"/gcc-13/bin
    for f in gcc cpp g++ gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool lto-dump; do
        ln -vsf /usr/bin/$f-13 "$RISCV"/gcc-13/bin/$f
    done
    export PATH="$RISCV"/gcc-13/bin:$PATH
elif (( UBUNTU_VERSION == 20 )); then
    mkdir -p "$RISCV"/gcc-10/bin
    for f in gcc cpp g++ gcc-ar gcc-nm gcc-ranlib gcov gcov-dump gcov-tool lto-dump; do
        ln -vsf /usr/bin/$f-10 "$RISCV"/gcc-10/bin/$f
    done
    export PATH="$RISCV"/gcc-10/bin:$PATH
fi


# Create python virtual environment so the python command targets desired version of python
# and installed packages are isolated from the rest of the system.
section_header "Setting up Python Environment"
STATUS="python_virtual_environment"
cd "$RISCV"
if [ ! -e "$RISCV"/riscv-python/bin/activate ]; then
    "$PYTHON_VERSION" -m venv riscv-python --prompt cvw
    echo -e "${OK_COLOR}Python virtual environment created!\nInstalling pip packages.${ENDC}"
else
    echo -e "${OK_COLOR}Python virtual environment already exists.\nUpdating pip packages.${ENDC}"
fi

source "$RISCV"/riscv-python/bin/activate # activate python virtual environment

# Install python packages, including RISCOF (https://github.com/riscv-software-src/riscof.git)
# RISCOF is a RISC-V compliance test framework that is used to run the RISC-V Arch Tests.
STATUS="python packages"
pip install --upgrade pip && pip install --upgrade -r "$dir"/requirements.txt

source "$RISCV"/riscv-python/bin/activate # reload python virtual environment
echo -e "${SUCCESS_COLOR}Python environment successfully configured!${ENDC}"

# Extra dependecies needed for older distros that don't have new enough versions available from package manager
if (( RHEL_VERSION == 8 )) || (( UBUNTU_VERSION == 20 )); then
    # Newer versin of glib required for QEMU.
    # Anything newer than this won't build on red hat 8
    STATUS="glib"
    if [ ! -e "$RISCV"/include/glib-2.0 ]; then
        section_header "Installing glib"
        pip install -U meson # Meson is needed to build glib
        cd "$RISCV"
        wget -nv --retry-connrefused $retry_on_host_error https://download.gnome.org/sources/glib/2.70/glib-2.70.5.tar.xz
        tar -xJf glib-2.70.5.tar.xz
        rm -f glib-2.70.5.tar.xz
        cd glib-2.70.5
        meson setup _build --prefix="$RISCV"
        meson compile -C _build -j "${NUM_THREADS}" 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
        meson install -C _build 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
        cd "$RISCV"
        rm -rf glib-2.70.5
        echo -e "${SUCCESS_COLOR}glib successfully installed!${ENDC}"
    fi
fi

# Newer version of gmp needed for sail-riscv model
if (( RHEL_VERSION == 8 )); then
    STATUS="gmp"
    if [ ! -e "$RISCV"/include/gmp.h ]; then
        section_header "Installing gmp"
        cd "$RISCV"
        wget -nv --retry-connrefused $retry_on_host_error https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
        tar -xJf gmp-6.3.0.tar.xz
        rm -f gmp-6.3.0.tar.xz
        cd gmp-6.3.0
        ./configure --prefix="$RISCV"
        make -j "${NUM_THREADS}" 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
        make install 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
        cd "$RISCV"
        rm -rf gmp-6.3.0
        echo -e "${SUCCESS_COLOR}gmp successfully installed!${ENDC}"
    fi
fi

# Mold needed for Verilator
if (( UBUNTU_VERSION == 20  || DEBIAN_VERSION == 11 )) || [ "$FAMILY" == suse ]; then
    STATUS="mold"
    if [ ! -e "$RISCV"/bin/mold ]; then
        section_header "Installing mold"
        cd "$RISCV"
        wget -nv --retry-connrefused $retry_on_host_error --output-document=mold.tar.gz https://github.com/rui314/mold/releases/download/v2.34.1/mold-2.34.1-x86_64-linux.tar.gz
        tar xz --directory="$RISCV" --strip-components=1 -f mold.tar.gz
        rm -f mold.tar.gz
        echo -e "${SUCCESS_COLOR}Mold successfully installed/updated!${ENDC}"
    else
        echo -e "${SUCCESS_COLOR}Mold already installed.${ENDC}"
    fi
fi

# Newer version of CMake needed to build sail-riscv model (at least 3.20)
if (( UBUNTU_VERSION == 20  || DEBIAN_VERSION == 11 )); then
    STATUS="cmake"
    if [ ! -e "$RISCV"/bin/cmake ]; then
        section_header "Installing cmake"
        cd "$RISCV"
        wget -nv --retry-connrefused $retry_on_host_error --output-document=cmake.tar.gz https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5-linux-x86_64.tar.gz
        tar xz --directory="$RISCV" --strip-components=1 -f cmake.tar.gz
        rm -f cmake.tar.gz
        echo -e "${SUCCESS_COLOR}CMake successfully installed/updated!${ENDC}"
    else
        echo -e "${SUCCESS_COLOR}CMake already installed.${ENDC}"
    fi
fi

# RISC-V GNU Toolchain (https://github.com/riscv-collab/riscv-gnu-toolchain)
# The RISC-V GNU Toolchain includes the GNU Compiler Collection (gcc), GNU Binutils, Newlib,
# and the GNU Debugger Project (gdb). It is a collection of tools used to compile RISC-V programs.
# To install GCC from source can take hours to compile.
# This configuration enables multilib to target many flavors of RISC-V.
# This book is tested with GCC 13.2.0 and 14.2.0.
section_header "Installing/Updating RISC-V GNU Toolchain"
STATUS="riscv-gnu-toolchain"
cd "$RISCV"
if git_check "riscv-gnu-toolchain" "https://github.com/riscv/riscv-gnu-toolchain" "$RISCV/riscv-gnu-toolchain/stamps/build-gcc-newlib-stage2"; then
    cd "$RISCV"/riscv-gnu-toolchain
    git reset --hard && git clean -f && git checkout master && git pull && git submodule update
    # sed commands needed to fix broken shallow cloning of submodules
    sed -i '/shallow = true/d' .gitmodules
    sed -i 's/--depth 1//g' Makefile.in
    ./configure --prefix="${RISCV}" --with-multilib-generator="rv32e-ilp32e--;rv32i-ilp32--;rv32im-ilp32--;rv32iac-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--;rv64i-lp64--;rv64ic-lp64--;rv64iac-lp64--;rv64imac-lp64--;rv64imafdc-lp64d--;rv64im-lp64--;"
    make -j "${NUM_THREADS}" 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    if [ "$clean" ]; then
        cd "$RISCV"
        rm -rf riscv-gnu-toolchain
    fi
    echo -e "${SUCCESS_COLOR}RISC-V GNU Toolchain successfully installed/updated!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}RISC-V GNU Toolchain already up to date.${ENDC}"
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
export PATH=$RISCV/bin:$PATH
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


# QEMU (https://www.qemu.org/docs/master/system/target-riscv.html)
# QEMU is an open source machine emulator and virtualizer capable of emulating RISC-V
section_header "Installing/Updating QEMU"
STATUS="qemu"
cd "$RISCV"
if git_check "qemu" "https://github.com/qemu/qemu" "$RISCV/include/qemu-plugin.h"; then
    cd "$RISCV"/qemu
    git reset --hard && git clean -f && git checkout master && git pull
    ./configure --target-list=riscv64-softmmu --prefix="$RISCV"
    make -j "${NUM_THREADS}" 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    make install 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    if [ "$clean" ]; then
        cd "$RISCV"
        rm -rf qemu
    fi
    echo -e "${SUCCESS_COLOR}QEMU successfully installed/updated!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}QEMU already up to date.${ENDC}"
fi


# Spike (https://github.com/riscv-software-src/riscv-isa-sim)
# Spike is a reference model for RISC-V. It is a functional simulator that can be used to run RISC-V programs.
section_header "Installing/Updating SPIKE"
STATUS="spike"
cd "$RISCV"
if git_check "riscv-isa-sim" "https://github.com/riscv-software-src/riscv-isa-sim" "$RISCV/lib/pkgconfig/riscv-riscv.pc"; then
    cd "$RISCV"/riscv-isa-sim
    git reset --hard && git clean -f && git checkout master && git pull
    mkdir -p build
    cd build
    ../configure --prefix="$RISCV"
    make -j "${NUM_THREADS}" 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    make install 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    if [ "$clean" ]; then
        cd "$RISCV"
        rm -rf riscv-isa-sim
    fi
    echo -e "${SUCCESS_COLOR}Spike successfully installed/updated!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}Spike already up to date.${ENDC}"
fi


# Verilator (https://github.com/verilator/verilator)
# Verilator is a fast open-source Verilog simulator that compiles synthesizable Verilog code into C++ code.
# It is used for linting and simulation of Wally.
# Verilator needs to be built from source to get the latest version (Wally needs 5.021 or later).
section_header "Installing/Updating Verilator"
STATUS="verilator"
cd "$RISCV"
if git_check "verilator" "https://github.com/verilator/verilator" "$RISCV/share/pkgconfig/verilator.pc"; then
    unset VERILATOR_ROOT
    cd "$RISCV"/verilator
    git reset --hard && git clean -f && git checkout master && git pull
    autoconf
    ./configure --prefix="$RISCV"
    make -j "${NUM_THREADS}" 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    make install 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    if [ "$clean" ]; then
        cd "$RISCV"
        rm -rf verilator
    fi
    echo -e "${SUCCESS_COLOR}Verilator successfully installed/updated!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}Verilator already up to date.${ENDC}"
fi


# Sail Compiler (https://github.com/rems-project/sail)
# Sail is a formal specification language designed for describing the semantics of an ISA.
# It is used to generate the RISC-V Sail Model, which is the golden reference model for RISC-V.
# The Sail Compiler is written in OCaml, which is an object-oriented extension of ML, which in turn
# is a functional programming language suited to formal verification.
section_header "Installing/Updating Sail Compiler"
STATUS="sail_compiler"
cd "$RISCV"
wget -nv --retry-connrefused $retry_on_host_error --output-document=sail.tar.gz https://github.com/rems-project/sail/releases/latest/download/sail.tar.gz
tar xz --directory="$RISCV" --strip-components=1 -f sail.tar.gz
rm -f sail.tar.gz
echo -e "${SUCCESS_COLOR}Sail Compiler successfully installed/updated!${ENDC}"

# RISC-V Sail Model (https://github.com/riscv/sail-riscv)
# The RISC-V Sail Model is the golden reference model for RISC-V. It is written in Sail (described above)
section_header "Installing/Updating RISC-V Sail Model"
STATUS="riscv-sail-model"
if git_check "sail-riscv" "https://github.com/riscv/sail-riscv.git" "$RISCV/bin/riscv_sim_rv32d"; then
    cd "$RISCV"/sail-riscv
    git reset --hard && git clean -f && git checkout master && git pull
    cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX="$RISCV" -GNinja 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    cmake --build build 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    cmake --install build 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
    if [ "$clean" ]; then
        cd "$RISCV"
        rm -rf sail-riscv
    fi
    echo -e "${SUCCESS_COLOR}RISC-V Sail Model successfully installed/updated!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}RISC-V Sail Model already up to date.${ENDC}"
fi


# OSU Skywater 130 cell library (https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12)
# The OSU Skywater 130 cell library is a standard cell library that is used to synthesize Wally.
section_header "Installing/Updating OSU Skywater 130 cell library"
STATUS="osu_skywater_130_cell_library"
mkdir -p "$RISCV"/cad/lib
cd "$RISCV"/cad/lib
if git_check "sky130_osu_sc_t12" "https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12" "$RISCV/cad/lib/sky130_osu_sc_t12" "main"; then
    cd "$RISCV"/sky130_osu_sc_t12
    git reset --hard && git clean -f && git checkout main && git pull
    echo -e "${SUCCESS_COLOR}OSU Skywater library successfully installed!${ENDC}"
else
    echo -e "${SUCCESS_COLOR}OSU Skywater library already up to date.${ENDC}"
fi


# Buildroot and Linux testvectors
# Buildroot is used to boot a minimal versio of Linux on Wally.
# Testvectors are generated using QEMU.
if [ ! "$no_buidroot" ]; then
    section_header "Installing Buildroot and Creating Linux testvectors"
    STATUS="buildroot"
    if [ -z "$LD_LIBRARY_PATH" ]; then
        export LD_LIBRARY_PATH=$RISCV/lib:$RISCV/lib64:$RISCV/riscv64-unknown-elf/lib:$RISCV/lib/x86_64-linux-gnu/
    else
        export LD_LIBRARY_PATH=$RISCV/lib:$RISCV/lib64:$LD_LIBRARY_PATH:$RISCV/riscv64-unknown-elf/lib:$RISCV/lib/x86_64-linux-gnu/
    fi
    cd "$dir"/../linux
    if [ ! -e "$RISCV"/buildroot ]; then
        FORCE_UNSAFE_CONFIGURE=1 make 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ] # FORCE_UNSAFE_CONFIGURE is needed to allow buildroot to compile when run as root
        echo -e "${SUCCESS_COLOR}Buildroot successfully installed and Linux testvectors created!${ENDC}"
    elif [ ! -e "$RISCV"/linux-testvectors ]; then
        echo -e "${OK_COLOR}Buildroot already exists, but Linux testvectors are missing. Generating them now.${ENDC}"
        make dumptvs 2>&1 | logger; [ "${PIPESTATUS[0]}" == 0 ]
        echo -e "${SUCCESS_COLOR}Linux testvectors successfully generated!${ENDC}"
    else
        echo -e "${OK_COLOR}Buildroot and Linux testvectors already exist.${ENDC}"
    fi
else
    echo -e "${OK_COLOR}Skipping Buildroot and Linux testvectors.${ENDC}"
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
    echo -e "${WARNING_COLOR}Make sure to edit the environment variables in $RISCV/site-setup.sh (or .csh) to point to your installation of EDA tools and licensce files.${ENDC}"
else
    echo -e "${OK_COLOR}Site setup script already exists. Not checking for updates to avoid overwritng modifications."
    echo -e "You may need to manually update it if there were changes upstream.${ENDC}"
fi

echo -e "${SUCCESS_COLOR}${BOLD}\n\nWALLY INSTALLATION SUCCESSFUL!!!\n\n${ENDC}"
