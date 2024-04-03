#!/bin/bash


# Set CONFIG_VARIANT from the first script argument
#CONFIG_VARIANT=${1:-rv64i}
CONFIG_VARIANT=${1}
# Set TESTSUITE from the second script argument
TESTSUITE=$2
INCLUDE_DIRS=$(find ../src -type d | xargs -I {} echo -n "{} ")
SOURCE_PATH="+incdir+../config/${CONFIG_VARIANT} +incdir+../config/deriv/${CONFIG_VARIANT} +incdir+../config/shared +define+ +define+P.XLEN=64  +define+FPGA=0 +incdir+../testbench ../src/cvw.sv +incdir+../src" 

SIMFILES="$INCLUDE_DIRS $(find ../src -name "*.sv" ! -path "../src/generic/clockgater.sv" ! -path "../src/generic/mem/rom1p1r_128x64.sv" ! -path "../src/generic/mem/ram2p1r1wbe_128x64.sv" ! -path "../src/generic/mem/rom1p1r_128x32.sv" ! -path "../src/generic/mem/ram2p1r1wbe_512x64.sv")  ../testbench/testbench.sv $(find ../testbench/common -name "*.sv" ! -path "../testbench/common/wallyTracer.sv")" 
OUTPUT="sim_out"

clean() {
    rm -rf obj_dir work transcript vsim.wlf $OUTPUT *.vcd csrc ucli.key vc_hdrs.h program.out
    rm -rf simv* *.daidir dve *.vpd *.dump DVEfiles/ verdi* novas* *fsdb* *.vg *.rep *.db *.chk *.log *.out profileReport* simprofile_dir*
}

# Clean and run simulation with VCS
clean
vcs +lint=all,noGCWM -simprofile -sverilog +vc -Mupdate -line -full64 -kdb -lca -debug_access+all+reverse -v2k_generate  ${SOURCE_PATH} +define+TEST=$TESTSUITE $SIMFILES -o $OUTPUT -error=NOODV
./$OUTPUT | tee program.out

