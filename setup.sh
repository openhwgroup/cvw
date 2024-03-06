#!/bin/bash

# setup.sh
# David_Harris@hmc.edu and kekim@hmc.edu 1 December 2021
# Set up tools for rvw
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

echo "Executing Wally setup.sh"

# Path to Wally repository
WALLY=$(dirname ${BASH_SOURCE[0]:-$0})
export WALLY=$(cd "$WALLY" && pwd)
echo \$WALLY set to ${WALLY}

# License servers and commercial CAD tool paths
# Must edit these based on your local environment.  Ask your sysadmin.
export MGLS_LICENSE_FILE=27002@zircon.eng.hmc.edu                   # Change this to your Siemens license server
export SNPSLMD_LICENSE_FILE=27020@zircon.eng.hmc.edu                # Change this to your Synopsys license server
export QUESTA_HOME=/cad/mentor/questa_sim-2023.4/questasim        # Change this for your path to Questa, excluding bin
export SNPS_HOME=/cad/synopsys/SYN                                  # Change this for your path to Design Compiler, excluding bin

# Path to RISC-V Tools
export RISCV=/opt/riscv   # change this if you installed the tools in a different location

# Tools
# Questa and Synopsys
export PATH=$QUESTA_HOME/bin:$SNPS_HOME/bin:$PATH
# GCC
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$RISCV/riscv-gnu-toolchain/lib:$RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/lib
export PATH=$PATH:$RISCV/riscv-gnu-toolchain/bin:$RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/bin      # GCC tools
# Spike
export LD_LIBRARY_PATH=$RISCV/lib:$LD_LIBRARY_PATH
export PATH=$PATH:$RISCV/bin
# utility functions in Wally repository
export PATH=$WALLY/bin:$PATH    
# Verilator
export PATH=/usr/local/bin/verilator:$PATH # Change this for your path to Verilator
# ModelSim/Questa (vsim)
# Note: 2022.1 complains on cache/sram1p1r1w about StoredData cannot be driven by multiple always_ff blocks.  Ues 2021.2 for now

# Imperas; put this in if you are using it
#export PATH=$RISCV/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64:$PATH  
#export LD_LIBRARY_PATH=$RISCV/imperas_riscv_tests/riscv-ovpsim-plus/bin/Linux64:$LD_LIBRARY_PATH # remove if no imperas

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

# Verilator needs a larger stack to simulate CORE-V Wally
ulimit -s 100000

echo "setup done"