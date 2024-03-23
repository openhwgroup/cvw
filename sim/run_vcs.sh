#!/bin/bash

# Ensure IMPERAS_HOME is set
if [ -z "$IMPERAS_HOME" ]; then
    echo "IMPERAS_HOME is not set"
    exit 1
fi

# Set CONFIG_VARIANT from the first script argument
#CONFIG_VARIANT=${1:-rv64i}
CONFIG_VARIANT=${1}
# Set TESTSUITE from the second script argument
TESTSUITE=$2

SOURCE_PATH="+incdir+../config/${CONFIG_VARIANT} +incdir+../config/deriv/${CONFIG_VARIANT} +incdir+../config/shared +incdir+../testbench +incdir+/${IMPERAS_HOME}/ImpProprietary/include/host +incdir+/${IMPERAS_HOME}/ImpPublic/source/host/rvvi +incdir+${IMPERAS_HOME}/ImpPublic/include/host +define+INCLUDE_TRACE2COV +define+COVER_BASE_RV64I +define+COVER_LEVEL_DV_PR_EXT +define+COVER_RV64I +define+COVER_RV64C +define+COVER_RV64M +incdir+${IMPERAS_HOME}/ImpProprietary/include/host +incdir+${IMPERAS_HOME}/ImpProprietary/source/host/riscvISACOV/source"
SIMFILES="${IMPERAS_HOME}/ImpPublic/source/host/rvvi/rvviApiPkg.sv ${IMPERAS_HOME}/ImpPublic/source/host/rvvi/rvviTrace.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/idvApiPkg.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/idvPkg.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/idvApiPkg.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/trace2api.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/trace2log.sv ${IMPERAS_HOME}/ImpProprietary/source/host/idv/trace2bin.sv ../src/cvw.sv ../testbench/testbench.sv ../src/*/*.sv ../src/*/*/*.sv ../testbench/common/*.sv"
OUTPUT="sim_out"

clean() {
    rm -rf obj_dir work transcript vsim.wlf $OUTPUT *.vcd csrc ucli.key vc_hdrs.h program.out
    rm -rf simv* *.daidir dve *.vpd *.dump DVEfiles/ verdi* novas* *fsdb* *.vg *.rep *.db *.chk *.log *.out profileReport* simprofile_dir*
}

# Clean and run simulation with VCS
clean
vcs +v2k +lint=all,noGCWM -simprofile -sverilog +vc -Mupdate -line -full64 -kdb -lca -debug_access+all+reverse +define+USE_IMPERAS_DV=1 -v2k_generate +define+P.ZICSR_SUPPORTED=1 +define+P.XLEN +define+P.ILEN +define+P.FLEN +define+P.VLEN +define+TEST=$TESTSUITE $SOURCE_PATH $SIMFILES -o $OUTPUT
./$OUTPUT | tee program.out

