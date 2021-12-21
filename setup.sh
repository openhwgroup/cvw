#!/bin/bash

# wally-setup.sh
# David_Harris@hmc.edu and kekim@hmc.edu 1 December 2021
# Set up tools for riscv-wally

echo "Executing wally-setup.sh"

# Path to RISC-V Tools
export RISCV=/opt/riscv   # change this if you installed the tools in a different location

# Tools
# GCCZ
export LD_LIBRARY_PATH=$RISCV/riscv-gnu-toolchain/lib:$RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/lib:$LD_LIBRARY_PATH
export PATH=$RISCV/riscv-gnu-toolchain/bin:$RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/bin:$PATH       # GCC tools
# Spike
export LD_LIBRARY_PATH=$RISCV/lib:$LD_LIBRARY_PATH
export PATH=$RISCV/bin:$PATH
# exe2memfile
export PATH=~/riscv-wally/bin:$PATH    # exe2memfile; change this if riscv-wally isn't at your home directory
# Verilator
export PATH=/usr/local/bin/verilator:$PATH # Change this for your path to Verilator
# ModelSim/Questa (vsim)
export PATH=/cad/mentor/questa_sim-2021.2_1/questasim/bin:$PATH    # Change this for your path to Modelsim
export MGLS_LICENSE_FILE=1717@solidworks.eng.hmc.edu # Change this to your Siemens license server

# Imperas; *** remove if not using
export PATH=/cad/riscv/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64:/cad/riscv/imperas-riscv-tests/riscv-ovpsim/bin/Liux64:$PATH  # *** maybe take this out based on Imperas
export LD_LIBRARY_PATH=/cad/imperas/Imperas.20200630/bin/Linux64:$LD_LIBRARY_PATH # remove if no imperas
export IMPERAS_HOME=/cad/imperas/Imperas.20200630
source $IMPERAS_HOME/bin/setup.sh
setupImperas $IMPERAS_HOME
