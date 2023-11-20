#!/bin/bash

#export RISCV=/scratch/moore/RISCV

export IMPERAS_TOOLS=$(pwd)/imperas.ic
export OTHERFLAGS="+TRACE2LOG_ENABLE=1"
#export OTHERFLAGS="+TRACE2LOG_ENABLE=1  +TRACE2LOG_AFTER=10500000"
export OTHERFLAGS=""

vsim -c  -do "do wally-linux-imperas.do buildroot buildroot-no-trace $::env(RISCV) 0 0 0"
