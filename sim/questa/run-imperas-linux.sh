#!/bin/bash

#export RISCV=/scratch/moore/RISCV

export IMPERAS_TOOLS=$(pwd)/imperas.ic
export OTHERFLAGS="+TRACE2LOG_ENABLE=1 +TRACE2LOG_AFTER=100"
#export OTHERFLAGS="+TRACE2LOG_ENABLE=1  +TRACE2LOG_AFTER=10500000"
#export OTHERFLAGS=""

vsim -do "do wally.do buildroot buildroot testbench --lockstep +acc -GDEBUG=1"
