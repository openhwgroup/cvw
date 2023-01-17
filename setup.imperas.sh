#!/bin/bash

echo "Imperas Environment to setup Wally"

# Path to Wally repository
WALLY=$(dirname ${BASH_SOURCE[0]:-$0})
export WALLY=$(cd "$WALLY" && pwd)
echo \$WALLY set to ${WALLY}

isetup -dv
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

