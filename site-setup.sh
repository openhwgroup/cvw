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
export SNPSLMD_LICENSE_FILE=27020@zircon.eng.hmc.edu                # Change this to your Synopsys license server
export IMPERASD_LICENSE_FILE=27020@zircon.eng.hmc.edu               # Change this to your Imperas license server
export QUESTA_HOME=/cad/mentor/questa_sim-2023.4/questasim          # Change this for your path to Questa, excluding bin
export DC_HOME=/cad/synopsys/SYN                                    # Change this for your path to Synopsys DC, excluding bin
export VCS_HOME=/cad/synopsys/vcs/U-2023.03-SP2-4                   # Change this for your path to Synopsys VCS, excluding bin
export BREKER_HOME=/cad/breker/trek5-2.1.10b-GCC6_el7               # Change this for your path to Breker Trek

# Tools
# Questa and Synopsys
export PATH=$QUESTA_HOME/bin:$DC_HOME/bin:$VCS_HOME/bin:$PATH

# Environmental variables for SoC
export SYN_pdk=/proj/models/tsmc28/libraries/28nmtsmc/tcbn28hpcplusbwp30p140_190a/
#export osupdk=/import/yukari1/pdk/TSMC/28/CMOS/HPC+/stclib/9-track/tcbn28hpcplusbwp30p140-set/tcbn28hpcplusbwp30p140_190a_FE/
export SYN_TLU=/home/jstine/TLU+
#export OSUTLU=/import/yukari1/pdk/TSMC/TLU+
export SYN_MW=/home/jstine/MW
#export OSUMW=/import/yukari1/pdk/TSMC/MW
export SYN_memory=/home/jstine/WallyMem/rv64gc/
#export osumemory=/import/yukari1/pdk/TSMC/WallyMem/rv64gc/

# Environmental variables for CTG (https://github.com/riscv-software-src/riscv-ctg)
export RISCVCTG=/home/harris/repos/riscv-ctg


# GCC
if [ -z "$LD_LIBRARY_PATH" ]; then
    export LD_LIBRARY_PATH=$RISCV/riscv64-unknown-elf/lib
else
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$RISCV/riscv64-unknown-elf/lib
fi

# RISC-V Tools
export LD_LIBRARY_PATH=$RISCV/lib:$RISCV/lib64:$LD_LIBRARY_PATH:$RISCV/lib/x86_64-linux-gnu/
export PATH=$PATH:$RISCV/bin

# Activate riscv-python Virtual Environment
if [ -e "$RISCV"/riscv-python/bin/activate ]; then
    source "$RISCV"/riscv-python/bin/activate
else
    echo "Python virtual environment not found. Rerun wally-toolchain-install.sh to automatically create it."
    exit 1
fi

# Environment variables needed for RISCV-DV
export RISCV_GCC=$(which riscv64-unknown-elf-gcc)		            # Copy this as it is
export RISCV_OBJCOPY=$(which riscv64-unknown-elf-objcopy)	        # Copy this as it is
export SPIKE_PATH=$RISCV/bin										# Copy this as it is

# Imperas OVPsim; put this in if you are using it
#export PATH=$RISCV/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64:$PATH
#export LD_LIBRARY_PATH=$RISCV/imperas_riscv_tests/riscv-ovpsim-plus/bin/Linux64:$LD_LIBRARY_PATH

# Imperas DV setup
export IDV=$RISCV/ImperasDV-OpenHW
if [ -e "$IDV" ]; then
    # echo "Imperas exists"
    export IMPERAS_HOME=$IDV
    export IMPERAS_PERSONALITY=CPUMAN_DV_ASYNC
    export ROOTDIR=~/
    source "${IMPERAS_HOME}"/bin/setup.sh
    setupImperas "${IMPERAS_HOME}"
    export PATH=$IDV/scripts/cvw:$PATH
fi

# Use newer gcc version for older distros
if [ -e /opt/rh/gcc-toolset-13/enable ]; then
    source /opt/rh/gcc-toolset-13/enable # Red Hat Family
elif [ -e $RISCV/gcc-13 ]; then
    export PATH=$RISCV/gcc-13/bin:$PATH  # SUSE Family
elif [ -e $RISCV/gcc-10 ]; then
    export PATH=$RISCV/gcc-10/bin:$PATH  # Ubuntu 20.04 LTS
fi
