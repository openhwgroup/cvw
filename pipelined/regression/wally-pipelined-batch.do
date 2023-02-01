# wally-pipelined-batch.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Usage: do wally-pipelined-batch.do <config> <testcases>
# Example: do wally-pipelined-batch.do rv32imc imperas-32i

# Use this wally-pipelined-batch.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-pipelined-batch.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-pipelined-batch.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if {$2 eq "ahb"} {
    if [file exists wkdir/work_${1}_${2}_${3}_${4}] {
        vdel -lib wkdir/work_${1}_${2}_${3}_${4} -all
    }
    vlib wkdir/work_${1}_${2}_${3}_${4}
} else {
    if [file exists wkdir/work_${1}_${2}] {
        vdel -lib wkdir/work_${1}_${2} -all
    }
    vlib wkdir/work_${1}_${2}
}
# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

# default to config/rv64ic, but allow this to be overridden at the command line.  For example:
# do wally-pipelined-batch.do ../config/rv32imc rv32imc
if {$2 eq "buildroot" || $2 eq "buildroot-checkpoint"} {
    vlog -lint -work wkdir/work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench-linux.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583
    # start and run simulation
    vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G RISCV_DIR=$3 -G INSTR_LIMIT=$4 -G INSTR_WAVEON=$5 -G CHECKPOINT=$6 -o testbenchopt 
    vsim -lib wkdir/work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3691  -fatal 7

    run -all
    run -all
    exec ./slack-notifier/slack-notifier.py
} elseif {$2 eq "buildroot-no-trace"} {
    vlog -lint -work work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench-linux.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583
    # start and run simulation
    vopt +acc work_${1}_${2}.testbench -work work_${1}_${2} -G RISCV_DIR=$3 -G INSTR_LIMIT=$4 -G INSTR_WAVEON=$5 -G CHECKPOINT=$6 -G NO_SPOOFING=1 -o testbenchopt 
    vsim -lib work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3829  -fatal 7

    #-- Run the Simulation
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Don't forget to change DEBUG_LEVEL = 0."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    run -all
    run -all
    exec ./slack-notifier/slack-notifier.py

} elseif {$2 eq "ahb"} {
    vlog -lint -work wkdir/work_${1}_${2}_${3}_${4} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv ../src/*/*/*.sv -suppress 2583 -suppress 7063,2596  +define+RAM_LATENCY=$3 +define+BURST_EN=$4
    # start and run simulation
    # remove +acc flag for faster sim during regressions if there is no need to access internal signals
    vopt wkdir/work_${1}_${2}_${3}_${4}.testbench -work wkdir/work_${1}_${2}_${3}_${4} -G TEST=$2 -o testbenchopt
    vsim -lib wkdir/work_${1}_${2}_${3}_${4} testbenchopt  -fatal 7
    # Adding coverage increases runtime from 2:00 to 4:29.  Can't run it all the time
    #vopt work_$2.testbench -work work_$2 -o workopt_$2 +cover=sbectf
    #vsim -coverage -lib work_$2 workopt_$2

    # power add generates the logging necessary for said generation.
    # power add -r /dut/core/*
    run -all
    # power off -r /dut/core/*
} else {
    vlog -lint -work wkdir/work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv ../src/*/*/*.sv -suppress 2583 -suppress 7063,2596
    # start and run simulation
    # remove +acc flag for faster sim during regressions if there is no need to access internal signals
    vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G TEST=$2 -o testbenchopt
    vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7
    # Adding coverage increases runtime from 2:00 to 4:29.  Can't run it all the time
    #vopt work_$2.testbench -work work_$2 -o workopt_$2 +cover=sbectf
    #vsim -coverage -lib work_$2 workopt_$2

    # power add generates the logging necessary for said generation.
    # power add -r /dut/core/*
    run -all
    # power off -r /dut/core/*
} 

#coverage report -file wally-pipelined-coverage.txt
# These aren't doing anything helpful
#coverage report -memory 
#profile report -calltree -file wally-pipelined-calltree.rpt -cutoff 2
#power report -all -bsaif power.saif
quit
