#!/bin/sh

# setup.csh
# james.stine@okstate.edu 18 February 2023

echo "Executing Wally setup.csh"


# Extend alias which makes extending PATH much easier.
alias extend 'if (-d \!:2) if ("$\!:1" \!~ *"\!:2"*) setenv \!:1 ${\!:1}:\!:2;echo Added \!:2 to \!:1'
alias prepend 'if (-d \!:2) if ("$\!:1" \!~ *"\!:2"*) setenv \!:1 "\!:2":${\!:1};echo Added \!:2 to \!:1'

# Path to RISC-V Tools
setenv RISCV /opt/riscv   # change this if you installed the tools in a different location

# Path to Wally repository
setenv WALLY $PWD
echo '$WALLY set to ' ${WALLY}
# utility functions in Wally repository
extend PATH $WALLY/bin

source $RISCV/site-setup.csh

echo "setup done"
