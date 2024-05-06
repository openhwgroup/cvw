# wally-batch.do 
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Usage: do wally-batch.do <config> <testcases> <testbench> [-coverage] [+acc] [any number of +value] [any number of -G VAR=VAL]
# Example: do wally-batch.do rv64gc arch64i testbench

# Use this wally-batch.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-batch.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-batch.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}
onerror {quit -f}

set CFG ${1}
set TESTSUITE ${2}
set TESTBENCH ${3}
set WKDIR wkdir/${CFG}_${TESTSUITE}
set WALLY $::env(WALLY)
set CONFIG ${WALLY}/config
set SRC ${WALLY}/src
set TB ${WALLY}/testbench

# create library
if [file exists ${WKDIR}] {
    vdel -lib ${WKDIR} -all
}
vlib ${WKDIR}
# Create directory for coverage data
mkdir -p cov

set coverage 0
set CoverageVoptArg ""
set CoverageVsimArg ""

# Need to be able to pass arguments to vopt.  Unforunately argv does not work because
# it takes on different values if vsim and the do file are called from the command line or
# if the do file isd called from questa sim directly.  This chunk of code uses the $4 through $n
# variables and compacts into a single list for passing to vopt.
set tbArgs ""
set from 4
set step 1
set lst {}
set GUI 0
set PlusArgs {}
set ParamArgs {}
set accFlag ""
for {set i 0} true {incr i} {
    set x [expr {$i*$step + $from}]
    if {$x > $argc} break
    set arg [expr "$$x"]
    lappend lst $arg
}

if {$argc >= 3} {
    if {[lindex $lst [expr { [llength $lst] -1 } ]] eq "+acc"} {
        set GUI 1
        set accFlag "+acc"
        set tbArgs [lrange $lst 0 end-1]
    } else {
        set tbArgs $lst
    }
    set tbArgsLst [split $lst " "]

    set index [lsearch -exact $tbArgsLst "-coverage"]
    if {$index >= 0} {
        set coverage 1
        set CoverageVoptArg "+cover=sbecf"
        set CoverageVsimArg "-coverage"
        echo $tbArgsLst
        set tbArgsLst [lreplace $tbArgsLst $index $index ]
        echo "help help help !!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo $tbArgsLst
        echo "help help help !!!!!!!!!!!!!!!!!!!!!!!!!!!"
    }
    
    # separate the +args from the -G parameters
    foreach otherArg $tbArgsLst {
        if {[string index $otherArg 0] eq "+"} {
            lappend PlusArgs $otherArg
        } else {
            lappend ParamArgs $otherArg
        }
    }
}

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

vlog -lint -work ${WKDIR} +incdir+${CONFIG}/${CFG} +incdir+${CONFIG}/deriv/${CFG} +incdir+${CONFIG}/shared ${SRC}/cvw.sv ${TB}/${TESTBENCH}.sv ${TB}/common/*.sv  ${SRC}/*/*.sv ${SRC}/*/*/*.sv -suppress 2583 -suppress 7063,2596,13286

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt $accFlag wkdir/${CFG}_${TESTSUITE}.${TESTBENCH} -work ${WKDIR} ${tbArgsLst} -o testbenchopt ${CoverageVoptArg}

#  *** tbArgs producees a warning that TEST not found in design when running sim-testfloat-batch.  Need to separate -G and + arguments to pass separately to vopt and vsim
vsim -lib ${WKDIR} testbenchopt +TEST=${TESTSUITE} ${PlusArgs} -fatal 7 -suppress 3829 ${CoverageVsimArg} 

#    vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829
# power add generates the logging necessary for said generation.
# power add -r /dut/core/*
if { ${GUI} } {
    add log -recursive /*
    if { ${TESTBENCH} eq "testbench_fp" } {
        do wave-fpu.do
    } else {
        do wave.do
    }
}

run -all
# power off -r /dut/core/*


if {$coverage} {
    set UCDB cov/${CFG}_${TESTSUITE}.ucdb
    echo "Saving coverage to ${UCDB}"
    do coverage-exclusions-rv64gc.do  # beware: this assumes testing the rv64gc configuration
    coverage save -instance /testbench/dut/core ${UCDB}
}

# These aren't doing anything helpful
#profile report -calltree -file wally-calltree.rpt -cutoff 2
#power report -all -bsaif power.saif

# terminate simulation unless we need to keep the GUI running
if { ${GUI} == 0} {
    quit
}

