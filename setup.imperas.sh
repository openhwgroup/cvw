#!/bin/bash

REPO=davidharrishmc
REPO=eroom1966
git clone https://github.com/${REPO}/riscv-wally -b imperas

cd riscv-wally
WALLY=$(dirname ${BASH_SOURCE[0]:-$0})
export WALLY=$(cd "$WALLY" && pwd)

# clone the Imperas repo
if [ ! -d external ]; then
    mkdir -p external
fi
pushd external
    if [ ! -f ImperasDV-HMC ]; then
        git clone https://github.com/Imperas/ImperasDV-HMC
    fi
    pushd ImperasDV-HMC
        git checkout fac563d
    popd
popd

# Setup Imperas
source ${WALLY}/external/ImperasDV-HMC/Imperas/bin/setup.sh
setupImperas ${WALLY}/external/ImperasDV-HMC/Imperas
export IMPERAS_PERSONALITY=CPUMAN_DV_ASYNC

# setup QUESTA (Imperas only command, YMMV)
svsetup -questa

pushd pipelined/regression
    # With IDV
    IMPERAS_TOOLS=$(pwd)/imperas.ic \
        OTHERFLAGS="+TRACE2LOG_ENABLE=1 VERBOSE=1" \
        TESTDIR=${WALLY}/external/ImperasDV-HMC/tests/riscof/work/riscv-arch-test/rv64i_m/F/src/fadd_b1-01.S  \
        vsim -c -do "do wally-pipelined-imperas.do rv64gc"
popd

