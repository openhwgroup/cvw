#!/bin/sh

# setup.csh
# james.stine@okstate.edu 18 February 2023

echo "Executing Wally setup.csh"

# Path to Wally repository
setenv WALLY $PWD
echo '$WALLY set to ' ${WALLY}

# Extend alias which makes extending PATH much easier.
alias extend 'if (-d \!:2) if ("$\!:1" \!~ *"\!:2"*) setenv \!:1 ${\!:1}:\!:2;echo Added \!:2 to \!:1'
alias prepend 'if (-d \!:2) if ("$\!:1" \!~ *"\!:2"*) setenv \!:1 "\!:2":${\!:1};echo Added \!:2 to \!:1'

# License servers and commercial CAD tool paths
# Must edit these based on your local environment.  Ask your sysadmin.
setenv MGLS_LICENSE_FILE 27002@zircon.eng.hmc.edu                 # Change this to your Siemens license server
setenv SNPSLMD_LICENSE_FILE 27020@zircon.eng.hmc.edu              # Change this to your Synopsys license server
setenv QUESTAPATH /cad/mentor/questa_sim-2022.4_2/questasim/bin   # Change this for your path to Questa
setenv SNPSPATH /cad/synopsys/SYN/bin                             # Change this for your path to Design Compiler

# Path to RISC-V Tools
setenv RISCV /opt/riscv   # change this if you installed the tools in a different location

# Tools
# Questa and Synopsys
extend PATH $QUESTAPATH
extend PATH $SNPSPATH 
# GCC
prepend LD_LIBRARY_PATH $RISCV/riscv-gnu-toolchain/lib
prepend LD_LIBRARY_PATH $RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/lib
extend PATH $RISCV/riscv-gnu-toolchain/bin # GCC tools
extend PATH $RISCV/riscv-gnu-toolchain/riscv64-unknown-elf/bin # GCC tools
# Spike
extend LD_LIBRARY_PATH $RISCV/lib
extend PATH $RISCV/bin
# utility functions in Wally repository
extend PATH $WALLY/bin
# Verilator
extend PATH /usr/local/bin/verilator # Change this for your path to Verilator
# ModelSim/Questa (vsim)
# Note: 2022.1 complains on cache/sram1p1r1w about StoredData cannot be driven by multiple always_ff blocks.  Ues 2021.2 for now

# Imperas; put this in if you are using it
#set path = ($RISCV/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64 $path)
#setenv LD_LIBRARY_PATH $RISCV/imperas_riscv_tests/riscv-ovpsim-plus/bin/Linux64:$LD_LIBRARY_PATH # remove if no imperas

echo "setup done"
