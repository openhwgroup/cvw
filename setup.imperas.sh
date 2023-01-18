#!/bin/bash

echo "Imperas Environment to setup Wally"

# Path to Wally repository
WALLY=$(dirname ${BASH_SOURCE[0]:-$0})
export WALLY=$(cd "$WALLY" && pwd)
echo \$WALLY set to ${WALLY}

# clone the Imperas repo
if [ ! -d external ]; then
    mkdir -p external
fi
pushd external
    if [ ! -f ImperasDV-HMC ]; then
        git clone git@github.com:Imperas/ImperasDV-HMC.git
    fi
    pushd ImperasDV-HMC
        git checkout 0c2f365
    popd
popd

isetup -dv ${WALLY}/external/ImperasDV-HMC/Imperas
svsetup -questa

pushd pipelined/regression
    # With IDV
    IMPERAS_TOOLS=$(pwd)/imperas.ic \
        OTHERFLAGS="+TRACE2LOG_ENABLE=1 VERBOSE=1" \
        TESTDIR=../../tests/riscof_lee/work/riscv-arch-test/rv64i_m/F/src/fadd_b1-01.S  \
        vsim -c -do "do wally-pipelined-imperas.do rv64gc"

    # Without IDV
    IMPERAS_TOOLS=$(pwd)/imperas.ic \
        OTHERFLAGS="+TRACE2LOG_ENABLE=1 VERBOSE=1" \
        TESTDIR=../../tests/riscof_lee/work/riscv-arch-test/rv64i_m/F/src/fadd_b1-01.S  \
        vsim -c -do "do wally-pipelined-imperas-no-idv.do rv64gc"
popd

# notes
# run the pushd external  code

#source external/ImperasDV-HMC/Imperas/bin/setup.sh 
#  setupImperas /home/ross/repos/active-wally/riscv-wally/external/ImperasDV-HMC/Imperas
#  env | grep IMPERAS
#  export IMPERAS_PERSONALITY=CPUMAN_DV_ASYNC

IMPERAS_TOOLS=$(pwd)/imperas.ic \
OTHERFLAGS="+TRACE2LOG_ENABLE=1 VERBOSE=1" \
TESTDIR=../../tests/riscof_lee/work/riscv-arch-test/rv64i_m/F/src/fadd_b1-01.S  \
vsim -c -do "do wally-pipelined-imperas.do rv64gc"


# getting library issue.
# try switching to modelsim 2022.01
