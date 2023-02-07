#!/bin/bash

IMP_HASH=56b1479

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
        git clone git@github.com:Imperas/ImperasDV-HMC.git
    fi
    pushd ImperasDV-HMC
        git checkout $IMP_HASH
    popd
popd

# Setup Imperas
source ${WALLY}/external/ImperasDV-HMC/Imperas/bin/setup.sh
setupImperas ${WALLY}/external/ImperasDV-HMC/Imperas
export IMPERAS_PERSONALITY=CPUMAN_DV_ASYNC

# setup QUESTA (Imperas only command, YMMV)
svsetup -questa

pushd sim
    # With IDV
    IMPERAS_TOOLS=$(pwd)/imperas.ic \
        OTHERFLAGS="+TRACE2LOG_ENABLE=1 VERBOSE=1" \
        TESTDIR=${WALLY}/external/ImperasDV-HMC/tests/riscof/work/riscv-arch-test/rv64i_m/F/src/fadd_b1-01.S  \
        vsim -c -do "do wally-imperas.do rv64gc"
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
vsim -c -do "do wally-imperas.do rv64gc"


# getting library issue.
# try switching to modelsim 2022.01
