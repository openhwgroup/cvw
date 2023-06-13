#!/bin/bash

if [ -d results ]; then
    rm -rf results
fi
mkdir -p results

ALL=$(find ${WALLY}/external/ImperasDV-HMC/tests/riscof/work/riscv-arch-test/rv64i_m -name "ref" -type d)

export IMPERAS_TOOLS=$(pwd)/imperas.ic
export OTHERFLAGS="+TRACE2LOG_ENABLE=1 VERBOSE=1"

for t in $ALL; do
    export TESTDIR=$(dirname ${t})
    OUTLOG=$(echo ${TESTDIR} | sed "s|${WALLY}/external/ImperasDV-HMC/tests/riscof/work|results|").log
    OUTDIR=$(dirname ${OUTLOG})
    echo "Running test ${TESTDIR} -> ${OUTDIR} :: ${OUTLOG}"

    mkdir -p ${OUTDIR}
    vsim -c -do "do wally-imperas.do rv64gc"
    mv transcript ${OUTLOG}
done
