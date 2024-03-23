#!/bin/bash

# Ensure IMPERAS_HOME is set
if [ -z "$IMPERAS_HOME" ]; then
    echo "IMPERAS_HOME is not set"
    exit 1
fi

# Set CONFIG_VARIANT from the first script argument
CONFIG_VARIANT="$1"
# Set TESTSUITE from the second script argument
TESTSUITE="$2"

# Define source and simulation files paths
SOURCE_PATH="+incdir+../config/${CONFIG_VARIANT} +incdir+../config/deriv/${CONFIG_VARIANT} +incdir+../config/shared +incdir+../testbench +incdir+/${IMPERAS_HOME}/ImpProprietary/include/host +incdir+/${IMPERAS_HOME}/ImpPublic/source/host/rvvi +incdir+${IMPERAS_HOME}/ImpPublic/include/host +define+INCLUDE_TRACE2COV +define+COVER_BASE_RV64I +define+COVER_LEVEL_DV_PR_EXT +define+COVER_RV64I +define+COVER_RV64C +define+COVER_RV64M +incdir+${IMPERAS_HOME}/ImpProprietary/include/host +incdir+${IMPERAS_HOME}/ImpProprietary/source/host/riscvISACOV/source"
SIMFILES="${IMPERAS_HOME}/ImpPublic/source/host/rvvi/rvviApiPkg.sv ${IMPERAS_HOME}/ImpPublic/source/host/rvvi/rvviTrace.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/idvApiPkg.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/idvPkg.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/idvApiPkg.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/trace2api.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/trace2log.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/trace2bin.sv ../src/cvw.sv ../testbench/testbench.sv ../src/*/*.sv ../src/*/*/*.sv ../testbench/common/*.sv"

# Function to clean up generated files
clean() {
    rm -rf obj_dir work transcript vsim.wlf *.vcd csrc ucli.key vc_hdrs.h program.out
    rm -rf simv* *.daidir dve *.vpd *.dump DVEfiles/ verdi* novas* *fsdb* *.vg *.rep *.db *.chk *.log *.out profileReport* simprofile_dir*
}

# Clean up before running
clean

# Command to run Xcelium (xrun) simulation
xrun -sv -uvm -access +rwc -timescale 1ns/1ns +define+TEST=$TESTSUITE $SOURCE_PATH $SIMFILES -R | tee program.out

# Check for errors in command execution
if [ $? -ne 0 ]; then
    echo "Error: Xcelium (xrun) simulation failed."
    exit 1
else
    echo "Xcelium (xrun) simulation completed successfully."
fi

