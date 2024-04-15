# wally.do 
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# run with vsim -do "do wally-pipelined.do rv64ic riscvarchtest-64m"

# Use this wally-pipelined.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
if {$2 eq "buildroot"} {
    vlog -lint -work work_${1}_${2} \
      +define+USE_IMPERAS_DV \
      +incdir+../config/deriv/$1 \
      +incdir+../config/shared \
      +incdir+$env(IMPERAS_HOME)/ImpPublic/include/host \
      +incdir+$env(IMPERAS_HOME)/ImpProprietary/include/host \
      $env(IMPERAS_HOME)/ImpPublic/source/host/rvvi/rvviApiPkg.sv    \
      $env(IMPERAS_HOME)/ImpPublic/source/host/rvvi/rvviTrace.sv      \
      $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/idvApiPkg.sv  \
      $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/idvPkg.sv   \
      $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/idvApiPkg.sv \
      $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2api.sv  \
      $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2log.sv  \
      $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2cov.sv  \
      $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2bin.sv  \
      ../src/cvw.sv \
       ../testbench/testbench.sv \
       ../testbench/common/*.sv ../src/*/*.sv \
       ../src/*/*/*.sv -suppress 2583

    #
    # start and run simulation
    # for profiling add
    # vopt -fprofile
    # vsim -fprofile+perf
    # visualizer -fprofile+perf+dir=fprofile
    #
    eval vopt +acc work_${1}_${2}.testbench -work work_${1}_${2} -G RISCV_DIR=$3 \
         -G TEST=$2 -o testbenchopt 
    eval vsim -lib work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3829,13286  -fatal 7 \
        -sv_lib $env(IMPERAS_HOME)/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model \
        $env(OTHERFLAGS)

    #-- Run the Simulation
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Don't forget to change DEBUG_LEVEL = 0."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    #run 100 ns
    #force -deposit testbench/dut/core/priv/priv/csr/csri/IE_REGW 16'h2aa
    #force -deposit testbench/dut/uncore/uncore/clint/clint/MTIMECMP 64'h1000
    run 9800 ms
    add log -recursive /testbench/dut/*
    do wave.do
    run 200 ms
    #run -all

    exec ./slack-notifier/slack-notifier.py

}
