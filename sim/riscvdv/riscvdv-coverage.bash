#!/bin/bash

# Usage
# run-elf-cov.bash <elf-file> <coverage-db>

declare -i rc=0
declare -i errcnt=0

cmdline="$0 $*"

function usage() {
    echo "Usage $0 --elf <elf-file> [--seed <seed-file>] --coverdb <coverage-file> [--verbose]"
    exit 1
}

VERBOSE=0

# --test X --seed y --coverdb z
while [[ $# -gt 0 ]]; do
  case $1 in
    --elf)
      ELF_FILE=$(realpath $2)
      shift # past argument
      shift # past value
      ;;
    --seed)
      SEED_VALUE=$2
      shift # past argument
      shift # past value
      ;;
    --test_name)
      TEST_NAME=$2
      shift # past argument
      shift # past value
      ;;
    --coverdb)
      COV_DB=$(realpath $2)
      shift # past argument
      shift # past value
      ;;
    --verbose)
      VERBOSE=1
      shift # past argument
      ;;
    *)
      usage
      ;;
  esac
done

# Ensure these variables are set
# WALLY ROOTDIR 
if [ ! $ROOTDIR ]; then
    echo "ROOTDIR is unset"
    exit 1
fi

CVW=${ROOTDIR}/cvw
export WALLY=${CVW}
if [ ! $WALLY ]; then
    echo "WALLY is unset"
    exit 1
fi

if [ ! $ELF_FILE ] || [ ! $COV_DB ]; then
    usage
fi

export ROOTDIR=$(pwd)

export OUTDIR=$(mktemp -d --suffix=.riscv)
mkdir -p ${OUTDIR}/ref

export ERRDIR=${ROOTDIR}/results-error

# Convert
${RISCV}/bin/riscv64-unknown-elf-elf2hex --bit-width 64 --input ${ELF_FILE} --output ${OUTDIR}/ref/ref.elf.memfile
cp ${ELF_FILE} ${OUTDIR}/ref/ref.elf
${RISCV}/bin/riscv64-unknown-elf-objdump -D ${OUTDIR}/ref/ref.elf > ${OUTDIR}/ref/ref.elf.objdump
${WALLY}/bin/extractFunctionRadix.sh ${OUTDIR}/ref/ref.elf.objdump

baseTEST=$(basename ${ELF_FILE} .elf)

SIM_CMD="vsim -c -do \"do ${WALLY}/sim/riscvdv/riscvdv-coverage.do rv64gc ${SEED_VALUE} ${TEST_NAME}\""
if [ $VERBOSE -eq 0 ]; then
    SIM_CMD="${SIM_CMD} > vsim.log"
else
    SIM_CMD="${SIM_CMD} | tee vsim.log"
fi

echo -e -n "running ${ELF_FILE} "
pushd ${CVW}/sim/questa >/dev/null
    IMPERAS_TOOLS=${CVW}/sim/imperas.ic \
        OTHERFLAGS="+IDV_TRACE2LOG=0 +IDV_TRACE2COV=1" \
        TESTDIR=${OUTDIR} \
        eval ${SIM_CMD}

    # Detect Pass/Fail
    grep Mismatches vsim.log 2>&1 > /dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
      rc=$(grep Mismatches vsim.log  | awk '{print $NF}')
    fi

    if [ $rc -eq 0 ]; then
        echo "Test Passed"
    else
        echo "Test Failed"
        while [ -d "${ERRDIR}/${errcnt}" ] && [ ${errcnt} -lt 100000 ]; do
            errcnt=$((errcnt + 1))
        done
        mkdir -p ${ERRDIR}/${errcnt}

        echo "  Saving to ${ERRDIR}/${errcnt}"
        mkdir -p ${ERRDIR}/${errcnt}
        echo $cmdline > ${ERRDIR}/${errcnt}/README.txt
        cp -r ${OUTDIR}/ref ${ERRDIR}/${errcnt}
        cp vsim.log ${ERRDIR}/${errcnt}
#        if [ -f "${SEED_FILE}" ]; then
            echo ${SEED_VALUE} > ${ERRDIR}/${errcnt}/SEED_VALUE.txt
#        fi
        pushd ${OUTDIR} >/dev/null
            tar cvfz ref.tar.gz ref/ref.elf ref/ref.elf.memfile ref/ref.elf.objdump.addr ref/ref.elf.objdump.lab
        popd >/dev/null
    fi
popd >/dev/null


if [ -e ${CVW}/sim/multiple_regressions/merged.ucdb ]; then
    echo "merged.ucdb existed for Quswar"
    if [ -e ${CVW}/sim/questa/${SEED_VALUE}/${TEST_NAME}/riscv.ucdb ]; then
        if [ -e ${COV_DB} ]; then
            vcover merge -suppress 6854 -64 ${COV_DB}.tmp ${COV_DB} ${CVW}/sim/questa/${SEED_VALUE}/${TEST_NAME}/riscv.ucdb > /dev/null
        else
            vcover merge -suppress 6854 -64 ${COV_DB}.tmp           ${CVW}/sim/questa/${SEED_VALUE}/${TEST_NAME}/riscv.ucdb > /dev/null
        fi
        mv ${COV_DB}.tmp ${COV_DB}
        vcover report ${COV_DB} -details -cvg > ${COV_DB}.log
        vcover report ${COV_DB} -testdetails -cvg > ${COV_DB}.testdetails.log
        vcover report ${COV_DB} -details -cvg -below 100 | egrep "Coverpoint|Covergroup|Cross" | grep -v Metric > ${COV_DB}.summary.log
        grep "Total Coverage By Instance" ${COV_DB}.log
    else
        echo "Error no coverage"
        rc=1
    fi
else
    echo "merged.ucdb DID NOT exist for Quswar"
    if [ -e ${COV_DB} ]; then
        vcover merge -suppress 6854 -64 ${COV_DB}.tmp ${COV_DB} ${CVW}/sim/questa/${SEED_VALUE}/${TEST_NAME}/riscv.ucdb > /dev/null
    else
        vcover merge -suppress 6854 -64 ${COV_DB}.tmp           ${CVW}/sim/questa/${SEED_VALUE}/${TEST_NAME}/riscv.ucdb > /dev/null
    fi
    mv ${COV_DB}.tmp ${COV_DB}
    cp ${COV_DB} ${CVW}/sim/multiple_regressions/merged.ucdb
    vcover report ${COV_DB} -details -cvg > ${COV_DB}.log
    vcover report ${COV_DB} -testdetails -cvg > ${COV_DB}.testdetails.log
    vcover report ${COV_DB} -details -cvg -below 100 | egrep "Coverpoint|Covergroup|Cross" | grep -v Metric > ${COV_DB}.summary.log
    grep "Total Coverage By Instance" ${COV_DB}.log
fi


#rm -rf ${OUTDIR}

exit $rc

