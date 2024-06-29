#!/bin/csh

# site-setup.csh

# License servers and commercial CAD tool paths
# Must edit these based on your local environment.  Ask your sysadmin.
setenv MGLS_LICENSE_FILE 27002@zircon.eng.hmc.edu                 # Change this to your Siemens license server
setenv SNPSLMD_LICENSE_FILE 27020@zircon.eng.hmc.edu              # Change this to your Synopsys license server
setenv QUESTAPATH /cad/mentor/questa_sim-2022.4_2/questasim/bin   # Change this for your path to Questa
setenv SNPSPATH /cad/synopsys/SYN/bin                             # Change this for your path to Design Compiler
setenv VCSPATH /cad/synopsys/vcs/U-2023.03-SP2-4/bin              # Change this for your path to Synopsys VCS

# Tools
# Questa and Synopsys
extend PATH $QUESTAPATH
extend PATH $SNPSPATH 
extend PATH $VCSPATH 

# GCC
extend LD_LIBRARY_PATH $RISCV/riscv64-unknown-elf/lib

# RISC-V Tools
extend LD_LIBRARY_PATH $RISCV/lib
extend LD_LIBRARY_PATH $RISCV/lib64
extend PATH $RISCV/bin

# Activate riscv-python Virtual Environment
source "$RISCV"/riscv-python/bin/activate.csh

# environment variables needed for RISCV-DV
setenv RISCV_GCC `which riscv64-unknown-elf-gcc`		            # Copy this as it is
setenv RISCV_OBJCOPY `which riscv64-unknown-elf-objcopy`	        # Copy this as it is
setenv SPIKE_PATH $RISCV/bin										# Change this for your path to riscv-isa-sim (spike)

# Verilator needs a larger stack to simulate CORE-V Wally
limit stacksize unlimited

# Imperas; put this in if you are using it
#set path = ($RISCV/imperas-riscv-tests/riscv-ovpsim-plus/bin/Linux64 $path)
#setenv LD_LIBRARY_PATH $RISCV/imperas_riscv_tests/riscv-ovpsim-plus/bin/Linux64:$LD_LIBRARY_PATH # remove if no imperas

setenv IDV $RISCV/ImperasDV-OpenHW
if ($?IDV) then
    # echo "Imperas exists"
    setenv IMPERAS_HOME $IDV/Imperas
    setenv IMPERAS_PERSONALITY CPUMAN_DV_ASYNC
    setenv ROOTDIR ~/
    source ${IMPERAS_HOME}/bin/setup.sh
    setupImperas ${IMPERAS_HOME}
    extend PATH $IDV/scripts/cvw
endif

