#!/bin/bash

# site-setup.sh
# David_Harris@hmc.edu and kekim@hmc.edu 1 December 2021
# System Admin should install this into $RISCV/site-setup.sh
# $RISCV is typically /opt/riscv
# System Admin must update the licenses and paths for localization.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# license servers and commercial CAD tool paths
# Must edit these based on your local environment.
export MGLS_LICENSE_FILE=27002@zircon.eng.hmc.edu                   # Change this to your Siemens license server for Questa
export SNPSLMD_LICENSE_FILE=27020@zircon.eng.hmc.edu                # Change this to your Synopsys license server for Design Compiler
export QUESTA_HOME=/cad/mentor/questa_sim-2023.4                    # Change this for your path to Questa, excluding bin
export DC_HOME=/cad/synopsys/SYN                                    # Change this for your path to Synopsys Design Compiler, excluding bin
export VCS_HOME=/cad/synopsys/vcs/U-2023.03-SP2-4                   # Change this for your path to Synopsys VCS, exccluding bin

# Tools
# Questa and Synopsys
export PATH=$QUESTA_HOME/questasim/bin:$DC_HOME/bin:$VCS_HOME/bin:$PATH

# GCC
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$RISCV/riscv-gnu-toolchain/lib:$RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/lib

# Spike
export LD_LIBRARY_PATH=$RISCV/lib:$LD_LIBRARY_PATH
export PATH=$PATH:$RISCV/bin

# Verilator
export PATH=/usr/local/bin/verilator:$PATH # Change this for your path to Verilator

# environment variables needed for RISCV-DV
export RISCV_GCC=`which riscv64-unknown-elf-gcc`		            # Copy this as it is
export RISCV_OBJCOPY=`which riscv64-unknown-elf-objcopy`	        # Copy this as it is
export SPIKE_PATH=/usr/bin											# Change this for your path to riscv-isa-sim (spike)

# Imperas OVPsim; put this in if you are using it
#export PATH=$RISCV/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64:$PATH  
#export LD_LIBRARY_PATH=$RISCV/imperas_riscv_tests/riscv-ovpsim-plus/bin/Linux64:$LD_LIBRARY_PATH

export IDV=$RISCV/ImperasDV-OpenHW
if [ -e "$IDV" ]; then
#    echo "Imperas exists"
    export IMPERAS_HOME=$IDV/Imperas
    export IMPERAS_PERSONALITY=CPUMAN_DV_ASYNC
    export ROOTDIR=~/
    source ${IMPERAS_HOME}/bin/setup.sh
    setupImperas ${IMPERAS_HOME}
    export PATH=$IDV/scripts/cvw:$PATH
fi


