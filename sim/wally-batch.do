# wally-batch.do 
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Usage: do wally-batch.do <config> <testcases>
# Example: do wally-batch.do rv32imc imperas-32i

# Use this wally-batch.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-batch.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-batch.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if {$2 eq "ahb"} {
    if [file exists wkdir/work_${1}_${2}_${3}_${4}] {
        vdel -lib wkdir/work_${1}_${2}_${3}_${4} -all
    }
    vlib wkdir/work_${1}_${2}_${3}_${4}


} elseif {$2 eq "configOptions"} {
    if [file exists wkdir/work_${1}_${3}_${4}] {
        vdel -lib wkdir/work_${1}_${3}_${4} -all
    }
    vlib wkdir/work_${1}_${3}_${4}

} else {
    if [file exists wkdir/work_${1}_${2}] {
        vdel -lib wkdir/work_${1}_${2} -all
    }
    vlib wkdir/work_${1}_${2}
}
# Create directory for coverage data
mkdir -p cov

# Check if measuring coverage
 set coverage 0
if {$argc >= 3} {
    if {$3 eq "-coverage" || ($argc >= 7 && $7 eq "-coverage")} {
        set coverage 1
    }
}

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

# default to config/rv64ic, but allow this to be overridden at the command line.  For example:
# do wally-pipelined-batch.do ../config/rv32imc rv32imc
if {$2 eq "buildroot" || $2 eq "buildroot-checkpoint"} {
    vlog -lint -work wkdir/work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../src/cvw.sv ../testbench/testbench-linux.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583
    # start and run simulation
    if { $coverage } {
        echo "wally-batch buildroot coverage"
        vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G RISCV_DIR=$3 -G INSTR_LIMIT=$4 -G INSTR_WAVEON=$5 -G CHECKPOINT=$6 -o testbenchopt +cover=sbecf
        vsim -lib wkdir/work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3691,13286  -fatal 7 -cover
     } else {
        vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G RISCV_DIR=$3 -G INSTR_LIMIT=$4 -G INSTR_WAVEON=$5 -G CHECKPOINT=$6 -o testbenchopt 
        vsim -lib wkdir/work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3691,13286  -fatal 7
    }

    run -all
    run -all
    exec ./slack-notifier/slack-notifier.py
} elseif {$2 eq "buildroot-no-trace"} {
    vlog -lint -work work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench-linux.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583
    # start and run simulation
    vopt +acc work_${1}_${2}.testbench -work work_${1}_${2} -G RISCV_DIR=$3 -G INSTR_LIMIT=$4 -G INSTR_WAVEON=$5 -G CHECKPOINT=$6 -G NO_SPOOFING=1 -o testbenchopt 
    vsim -lib work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3829,13286  -fatal 7

    #-- Run the Simulation
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Don't forget to change DEBUG_LEVEL = 0."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    run -all
    run -all
    exec ./slack-notifier/slack-notifier.py

} elseif {$2 eq "ahb"} {
    vlog -lint -work wkdir/work_${1}_${2}_${3}_${4} +incdir+../config/$1 +incdir+../config/shared ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv ../src/*/*/*.sv -suppress 2583 -suppress 7063,2596,13286  +define+RAM_LATENCY=$3 +define+BURST_EN=$4
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

} elseif {$2 eq "configOptions"} {
    # set arguments " "
    # for {set i 5} {$i <= $argc} {incr i} {
    # 	append arguments "\$$i "
    # }
    # puts $arguments
    # set options eval $arguments
    # **** fix this so we can pass any number of +defines.
    # only allows 3 right now

    vlog -lint -work wkdir/work_${1}_${3}_${4} +incdir+../config/$1 +incdir+../config/shared ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv ../src/*/*/*.sv -suppress 2583 -suppress 7063,2596,13286 $5 $6 $7
    # start and run simulation
    # remove +acc flag for faster sim during regressions if there is no need to access internal signals
    vopt wkdir/work_${1}_${3}_${4}.testbench -work wkdir/work_${1}_${3}_${4} -G TEST=$4 -o testbenchopt
    vsim -lib wkdir/work_${1}_${3}_${4} testbenchopt  -fatal 7 -suppress 3829
    # Adding coverage increases runtime from 2:00 to 4:29.  Can't run it all the time
    #vopt work_$2.testbench -work work_$2 -o workopt_$2 +cover=sbectf
    #vsim -coverage -lib work_$2 workopt_$2
    # power add generates the logging necessary for said generation.
    # power add -r /dut/core/*
    run -all
    # power off -r /dut/core/*

} else {
    vlog -lint -work wkdir/work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv ../src/*/*/*.sv -suppress 2583 -suppress 7063,2596,13286
    # start and run simulation
    # remove +acc flag for faster sim during regressions if there is no need to access internal signals
    if {$coverage} {
#        vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G TEST=$2 -o testbenchopt +cover=sbectf
        vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G TEST=$2 -o testbenchopt +cover=sbecf
        vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829 -coverage
    } else {
        vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G TEST=$2 -o testbenchopt
        vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829
    }
#    vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829
    # power add generates the logging necessary for said generation.
    # power add -r /dut/core/*
    run -all
    # power off -r /dut/core/*
} 

if {$coverage} {
    echo "Saving coverage to ${1}_${2}.ucdb"
    do coverage-exclusions-rv64gc.do  # beware: this assumes testing the rv64gc configuration
    coverage save -instance /testbench/dut/core cov/${1}_${2}.ucdb
}

# These aren't doing anything helpful
#profile report -calltree -file wally-calltree.rpt -cutoff 2
#power report -all -bsaif power.saif
quit
