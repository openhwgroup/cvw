#!/bin/bash

#export RISCV=/scratch/moore/RISCV

export IMPERAS_TOOLS=$(pwd)/imperas.ic
#export OTHERFLAGS="+IDV_TRACE2LOG=1"
#export OTHERFLAGS="+IDV_TRACE2LOG=1  +IDV_TRACE2LOG_AFTER=10500000"
export OTHERFLAGS=""

vsim -c -do "do wally-linux-imperas.do buildroot buildroot-no-trace $::env(RISCV) 0 0 0"
