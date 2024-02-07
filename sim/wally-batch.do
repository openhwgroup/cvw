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
if {$2 eq "configOptions"} {
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

# Need to be able to pass arguments to vopt.  Unforunately argv does not work because
# it takes on different values if vsim and the do file are called from the command line or
# if the do file isd called from questa sim directly.  This chunk of code uses the $4 through $n
# variables and compacts into a single list for passing to vopt.
set coverage 0
set configOptions ""
set from 4
set step 1
set lst {}
for {set i 0} true {incr i} {
    set x [expr {$i*$step + $from}]
    if {$x > $argc} break
    set arg [expr "$$x"]
    lappend lst $arg
}
if {$argc >= 3} {
    if {$3 eq "-coverage" || ($argc >= 7 && $7 eq "-coverage")} {
        set coverage 1
    } elseif {$3 eq "configOptions"} {
        set configOptions $lst
        puts $configOptions
    }
    
}

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

# default to config/rv64ic, but allow this to be overridden at the command line.  For example:
# do wally-pipelined-batch.do ../config/rv32imc rv32imc

vlog -lint -work wkdir/work_${1}_${2} +incdir+../config/$1 +incdir+../config/deriv/$1 +incdir+../config/shared ../src/cvw.sv ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv ../src/*/*/*.sv -suppress 2583 -suppress 7063,2596,13286
# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
if {$coverage} {
    #        vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G TEST=$2 -o testbenchopt +cover=sbectf
    vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G TEST=$2 -o testbenchopt +cover=sbecf
    vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829 -coverage
} else {
    vopt wkdir/work_${1}_${2}.testbench -work wkdir/work_${1}_${2} -G TEST=$2 ${configOptions} -o testbenchopt
    vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829
}
#    vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829
# power add generates the logging necessary for said generation.
# power add -r /dut/core/*
run -all
# power off -r /dut/core/*


if {$coverage} {
    echo "Saving coverage to ${1}_${2}.ucdb"
    do coverage-exclusions-rv64gc.do  # beware: this assumes testing the rv64gc configuration
    coverage save -instance /testbench/dut/core cov/${1}_${2}.ucdb
}

# These aren't doing anything helpful
#profile report -calltree -file wally-calltree.rpt -cutoff 2
#power report -all -bsaif power.saif
quit
