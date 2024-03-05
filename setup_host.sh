#!/bin/bash

# setup.sh
# David_Harris@hmc.edu and kekim@hmc.edu 1 December 2021
# Set up tools for riscv-wally

echo "Executing Wally setup.sh"

# Path to Wally repository
WALLY=$(dirname ${BASH_SOURCE[0]:-$0})
export WALLY=$(cd "$WALLY" && pwd)
echo \$WALLY set to ${WALLY}

# Path to RISC-V Tools
export RISCV=/opt/riscv   # change this if you installed the tools in a different location

# Tools
# GCC
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$RISCV/riscv-gnu-toolchain/lib:$RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/lib
#export PATH=$PATH:$RISCV/riscv-gnu-toolchain/bin:$RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/bin      # GCC tools
# Spike
#export LD_LIBRARY_PATH=$RISCV/lib:$LD_LIBRARY_PATH
export PATH=$PATH:$RISCV/bin
# utility functions in Wally repository
export PATH=$WALLY/bin:$PATH    
# Verilator
export PATH=$RICKV/verilator:$PATH # Change this for your path to Verilator
# ModelSim/Questa (vsim)
# Note: 2022.1 complains on cache/sram1p1r1w about StoredData cannot be driven by multiple always_ff blocks.  Ues 2021.2 for now
#export PATH=/cad/mentor/questa_sim-2022.1_1/questasim/bin:$PATH    # Change this for your path to Modelsim 
#export PATH=/cad/mentor/questa_sim-2021.2_1/questasim/bin:$PATH    # Change this for your path to Modelsim, or delete
#export MGLS_LICENSE_FILE=1717@solidworks.eng.hmc.edu # Change this to your Siemens license server
#export PATH=/cad/synopsys/SYN/bin:$PATH  # Change this for your path to Design Compiler
#export SNPSLMD_LICENSE_FILE=27020@134.173.38.184 # Change this to your license manager file

# Imperas; put this in if you are using it
#export PATH=$RISCV/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64:$PATH  
#export LD_LIBRARY_PATH=$RISCV/imperas_riscv_tests/riscv-ovpsim-plus/bin/Linux64:$LD_LIBRARY_PATH # remove if no imperas

export MODSIM=/opt/ModelSim/questasim
export PATH=$PATH:$MODSIM/bin
export LD_LIBRARY_PATH=/usr/lib:/lib
export MGC_DOC_PATH=$MODSIM/docs
export MGC_PDF_READER=evince
export MGC_HTML_BROWSER=firefox
export MGLS_LICENSE_FILE=1717@trelaina.ecen.okstate.edu
export IMPERASD_LICENSE_FILE=2700@trelaina.ecen.okstate.edu

export IDV=$RISCV/ImperasDV-OpenHW
if [ -e "$IDV" ]; then
#    echo "Imperas exists"
    export IMPERAS_HOME=$IDV/Imperas
    export IMPERAS_PERSONALITY=CPUMAN_DV_ASYNC
    export ROOTDIR=${WALLY}/..
    source ${IMPERAS_HOME}/bin/setup.sh
    setupImperas ${IMPERAS_HOME}
    export PATH=$IDV/scripts/cvw:$PATH
fi
