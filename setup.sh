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
if [ -e /opt/riscv ]; then
    export RISCV=/opt/riscv
elif [ -e ~/riscv ]; then
    export RISCV=~/riscv
else
    # set the $RISCV directory here and remove the subsequent two lines
    # export RISCV=
    echo "\$RISCV directory not found. Checked /opt/riscv and ~/riscv. Edit setup.sh to point to your custom \$RISCV directory."
    exit 1;
fi
echo \$RISCV set to "${RISCV}"

# Path to Wally repository
WALLY=$(dirname "${BASH_SOURCE[0]:-$0}")
export WALLY=$(cd "$WALLY" && pwd)
echo \$WALLY set to "${WALLY}"
# utility functions in Wally repository
export PATH=$WALLY/bin:$PATH

# load site licenses and tool locations
source "${RISCV}"/site-setup.sh

echo "setup done"
