#!/bin/csh

# site-setup.csh
# System Admin should install this into $RISCV/site-setup.csh
# It is automatically placed in the $RISCV directory by wally-toolchain-install.sh
# $RISCV is typically /opt/riscv or ~/riscv
# System Admin must update the licenses and paths for localization.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# License servers and commercial CAD tool paths
# Must edit these based on your local environment.  Ask your sysadmin.
setenv MGLS_LICENSE_FILE 27002@zircon.eng.hmc.edu                         # Change this to your Siemens license server
setenv SNPSLMD_LICENSE_FILE 27020@zircon.eng.hmc.edu                      # Change this to your Synopsys license server
setenv QUESTAPATH /cad/mentor/QUESTA/bin                                  # Change this for your path to Questa
setenv DCPATH /cad/synopsys/SYN/bin                                       # Change this for your path to Design Compiler
setenv VCSPATH /cad/synopsys/VCS/bin                                      # Change this for your path to Synopsys VCS
setenv BREKER_HOME /cad/breker/TREK                                       # Change this for your path to Breker Trek
setenv SPYGLASS_HOME /cad/synopsys/SPYGLASS_HOME                          # Change this for your path to Synopsys Spyglass


# Tools
# Questa and Synopsys
extend PATH $QUESTAPATH
extend PATH $DCPATH
extend PATH $VCSPATH
extend PATH $SPYGLASS_HOME/bin
# Synopsys Spyglass
setenv SNPSLMD_QUEUE 1

# GCC
if ( ! $?LD_LIBRARY_PATH ) then
    setenv LD_LIBRARY_PATH $RISCV/riscv64-unknown-elf/lib
else
    extend LD_LIBRARY_PATH $RISCV/riscv64-unknown-elf/lib
endif

# RISC-V Tools
extend LD_LIBRARY_PATH $RISCV/lib
extend LD_LIBRARY_PATH $RISCV/lib64
extend LD_LIBRARY_PATH $RISCV/lib/x86_64-linux-gnu/
extend PATH $RISCV/bin

# Activate riscv-python Virtual Environment
if ( -e "$RISCV"/riscv-python/bin/activate ) then
    source "$RISCV"/riscv-python/bin/activate.csh
else
    echo "Python virtual environment not found. Rerun wally-toolchain-install.sh to automatically create it."
    exit 1
endif

# environment variables needed for RISCV-DV
setenv RISCV_GCC `which riscv64-unknown-elf-gcc`		            # Copy this as it is
setenv RISCV_OBJCOPY `which riscv64-unknown-elf-objcopy`	        # Copy this as it is
setenv SPIKE_PATH $RISCV/bin										# Change this for your path to riscv-isa-sim (spike)

# Imperas; put this in if you are using it
#set path = ($RISCV/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64 $path)
#setenv LD_LIBRARY_PATH $RISCV/imperas_riscv_tests/riscv-ovpsim-plus/bin/Linux64:$LD_LIBRARY_PATH # remove if no imperas

setenv IDV $RISCV/ImperasDV-OpenHW
if ($?IDV) then
    # echo "Imperas exists"
    setenv IMPERAS_HOME $IDV
    setenv IMPERAS_PERSONALITY CPUMAN_DV_ASYNC
    setenv ROOTDIR ~/
    source ${IMPERAS_HOME}/bin/setup.sh
    setupImperas ${IMPERAS_HOME}
    extend PATH $IDV/scripts/cvw
endif

# Use newer gcc version for older distros
if ( -e $RISCV/gcc-13 ) then
    prepend PATH $RISCV/gcc-13/bin # SUSE Family
elseif ( -e $RISCV/gcc-10 ) then
    prepend PATH $RISCV/gcc-10/bin # Ubuntu 20.04 LTS
endif
