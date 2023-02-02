#!/bin/bash

# setup.sh
# David_Harris@hmc.edu and kekim@hmc.edu 1 December 2021
# Set up tools for rvw

echo "Executing Wally setup.sh"

# Path to Wally repository
WALLY=$(dirname ${BASH_SOURCE[0]:-$0})
export WALLY=$(cd "$WALLY" && pwd)
echo \$WALLY set to ${WALLY}

# License servers and commercial CAD tool paths
# Must edit these based on your local environment.  Ask your sysadmin.
export MGLS_LICENSE_FILE=27002@zircon.eng.hmc.edu                   # Change this to your Siemens license server
export SNPSLMD_LICENSE_FILE=27020@zircon.eng.hmc.edu                # Change this to your Synopsys license server
export QUESTAPATH=/cad/mentor/questa_sim-2022.4_2/questasim/bin     # Change this for your path to Questa
export SNPSPATH=/cad/synopsys/SYN/bin                               # Change this for your path to Design Compiler

# Path to RISC-V Tools
export RISCV=/opt/riscv   # change this if you installed the tools in a different location

# Tools
# Questa and Synopsys
export PATH=$QUESTAPATH:$SNPSPATH:$PATH
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

echo "setup done"