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

set CFG ${1}
set TESTSUITE ${2}
set WKDIR wkdir/${CFG}_${TESTSUITE}
set WALLY $::env(WALLY)

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
        set CoverageVoptArg "+cover=sbecf"
        set CoverageVsimArg "-coverage"
    } elseif {$3 eq "configOptions"} {
        set configOptions $lst
        puts $configOptions
    }
}

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

set CONFIG ${WALLY}/config
set SRC ${WALLY}/src
set TB ${WALLY}/testbench

vlog -lint -work ${WKDIR} +incdir+${CONFIG}/$1 +incdir+${CONFIG}/deriv/$1 +incdir+${CONFIG}/shared ${SRC}/cvw.sv ${TB}/testbench.sv ${TB}/common/*.sv  ${SRC}/*/*.sv ${SRC}/*/*/*.sv -suppress 2583 -suppress 7063,2596,13286

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt wkdir/${CFG}_${TESTSUITE}.testbench -work ${WKDIR} -G TEST=$2 ${configOptions} -o testbenchopt ${CoverageVoptArg}
vsim -lib ${WKDIR} testbenchopt  -fatal 7 -suppress 3829 ${CoverageVsimArg}

#    vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829
# power add generates the logging necessary for said generation.
# power add -r /dut/core/*
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
quit
