#!/bin/bash

# setup.sh
# David_Harris@hmc.edu and kekim@hmc.edu 1 December 2021
# Set up tools for cvw

# optionally have .bashrc or .bash_profile source this file with
#if [ -f ~/cvw/setup.sh ]; then
#	source ~/cvw/setup.sh
#fi

# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

echo "Executing Wally setup.sh"

# Path to RISC-V Tools
export RISCV=/opt/riscv   # change this if you installed the tools in a different location

# Path to Wally repository
WALLY=$(dirname ${BASH_SOURCE[0]:-$0})
export WALLY=$(cd "$WALLY" && pwd)
echo \$WALLY set to ${WALLY}
# utility functions in Wally repository
export PATH=$WALLY/bin:$PATH    

# Verilator needs a larger stack to simulate CORE-V Wally
ulimit -c 234613

# load site licenses and tool locations
if [ -f ${RISCV}/site-setup.sh ]; then
    source ${RISCV}/site-setup.sh
else
    source ${WALLY}/site-setup.sh
fi

echo "setup done"
