#!/bin/bash

config=$1
testsuite=$2
vcs -full64 +lint=all,noGCWM -sverilog  +define+ +incdir+../testbench +incdir+../config/$config +incdir+../config/shared ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/DCacheFlushFSM.sv ../testbench/common/checksignature.sv ../testbench/common/functionName.sv ../testbench/common/instr* ../testbench/common/loggers.sv ../testbench/common/ramxdetector.sv ../testbench/common/riscvassertions.sv ../testbench/common/watchdog.sv ../src/*/*.sv ../src/*/*/*.sv ../testbench/vcs-files/*.sv -pvalue+TEST=$testsuite -o simv_${config}_$testsuite

./simv_${config}_$testsuite -ucli -do vcs.do
