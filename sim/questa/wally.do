# wally.do
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Usage: do wally.do <config> <testcases> <testbench> [--ccov] [--fcov] [+acc] [--args "any number of +value"] [--params "any number of VAR=VAL parameter overrides"]
# Example: do wally.do rv64gc arch64i testbench

# Use this wally.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally.do -c
# (omit the "-c" to see the GUI while running from the shell)

# lcheck - return 1 if value is in list and remove it from list
proc lcheck {listVariable value} {
    upvar 1 $listVariable list
    set index [lsearch -exact $list $value]
    if {$index >= 0} {
        set list [lreplace $list $index $index]
        return 1
    } else {
        return 0
    }
}

set DEBUG 1
onbreak {resume}
onerror {quit -f}

# Initialize variables
set CFG ${1}
set TESTSUITE ${2}
set TESTBENCH ${3}
set WKDIR wkdir/${CFG}_${TESTSUITE}
set WALLY $::env(WALLY)
set IMPERAS_HOME $::env(IMPERAS_HOME)
set CONFIG ${WALLY}/config
set SRC ${WALLY}/src
set TB ${WALLY}/testbench
set FCRVVI ${WALLY}/addins/cvw-arch-verif/fcov

# create library
if [file exists ${WKDIR}] {
    vdel -lib ${WKDIR} -all
}
vlib ${WKDIR}

set PlusArgs ""
set ParamArgs ""
set ExpandedParamArgs {}

set ccov 0
set CoverageVoptArg ""
set CoverageVsimArg ""

set FunctCoverage 0
set FCvlog ""
set FCvopt ""
set FCdefineCOVER_EXTS {}

set lockstep 0
set lockstepvlog ""
set SVLib ""

set GUI 0
set accFlag ""

# Need to be able to pass arguments to vopt.  Unforunately argv does not work because
# it takes on different values if vsim and the do file are called from the command line or
# if the do file is called from questa sim directly.  This chunk of code uses the $4 through $n
# variables and compacts into a single list for passing to vopt.
set from 4
set step 1
set lst {}

for {set i 0} true {incr i} {
    set x [expr {$i*$step + $from}]
    if {$x > $argc} break
    set arg [expr "$$x"]
    lappend lst $arg
}

echo "number of args = $argc"
echo "lst = $lst"

# if +acc found set flag and remove from list
if {[lcheck lst "+acc"]} {
    set GUI 1
    set accFlag "+acc"
}

# if --ccov found set flag and remove from list
if {[lcheck lst "--ccov"]} {
    set ccov 1
    set CoverageVoptArg "+cover=sbecf"
    set CoverageVsimArg "-coverage"
}

# if --fcovimp found set flag and remove from list
if {[lcheck lst "--fcovimp"]} {
    set FunctCoverage 1
    set FCvlog "+define+INCLUDE_TRACE2COV \
                +define+IDV_INCLUDE_TRACE2COV \
                +define+COVER_BASE_RV64I \
                +define+COVER_LEVEL_DV_PR_EXT \
                +incdir+${IMPERAS_HOME}/ImpProprietary/source/host/riscvISACOV/source"
    set FCvopt "+TRACE2COV_ENABLE=1 +IDV_TRACE2COV=1"
    # Uncomment various cover statements below to control which extensions get functional coverage
    lappend FCdefineCOVER_EXTS "+define+COVER_RV64I"
    #lappend FCdefineCOVER_EXTS "+define+COVER_RV64M"
    #lappend FCdefineCOVER_EXTS "+define+COVER_RV64A"
    #lappend FCdefineCOVER_EXTS "+define+COVER_RV64F"
    #lappend FCdefineCOVER_EXTS "+define+COVER_RV64D"
    #lappend FCdefineCOVER_EXTS "+define+COVER_RV64ZICSR"
    #lappend FCdefineCOVER_EXTS "+define+COVER_RV64C"

}

# if --fcov found set flag and remove from list
if {[lcheck lst "--fcov"]} {
    set FunctCoverage 1
    # COVER_BASE_RV32I is just needed to keep riscvISACOV happy, but no longer affects tests
         set FCvlog "+define+INCLUDE_TRACE2COV \
                +define+IDV_INCLUDE_TRACE2COV \
                +define+COVER_BASE_RV32I \
                +incdir+$env(WALLY)/addins/riscvISACOV/source \
		"
   
    set FCvopt "+TRACE2COV_ENABLE=1 +IDV_TRACE2COV=1"

}

# if --lockstep or --fcov found set flag and remove from list
if {[lcheck lst "--lockstep"] || $FunctCoverage == 1} {
    set lockstep 1
    set lockstepvlog "+define+USE_IMPERAS_DV \
                      +incdir+${IMPERAS_HOME}/ImpPublic/include/host \
                      +incdir+${IMPERAS_HOME}/ImpProprietary/include/host \
                      ${IMPERAS_HOME}/ImpPublic/source/host/rvvi/*.sv \
                      ${IMPERAS_HOME}/ImpProprietary/source/host/idv/*.sv"
    set SVLib "-sv_lib ${IMPERAS_HOME}/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model"
}

# Set PlusArgs passed using the --args flag
set PlusArgsIndex [lsearch -exact $lst "--args"]
if {$PlusArgsIndex >= 0} {
    set PlusArgs [lindex $lst [expr {$PlusArgsIndex + 1}]]
    set lst [lreplace $lst $PlusArgsIndex [expr {$PlusArgsIndex + 1}]]
}

# Set ParamArgs passed using the --params flag and expand into a list of -G<param> arguments
set ParamArgsIndex [lsearch -exact $lst "--params"]
if {$ParamArgsIndex >= 0} {
    set ParamArgs [lindex $lst [expr {$ParamArgsIndex + 1}]]
    set ParamArgs [regexp -all -inline {\S+} $ParamArgs]
    foreach param $ParamArgs {
        lappend ExpandedParamArgs -G$param
    }
    set lst [lreplace $lst $ParamArgsIndex [expr {$ParamArgsIndex + 1}]]
}

# Debug print statements
if {$DEBUG > 0} {
    echo "GUI = $GUI"
    echo "ccov = $ccov"
    echo "lockstep = $lockstep"
    echo "FunctCoverage = $FunctCoverage"
    echo "remaining list = $lst"
    echo "Extra +args = $PlusArgs"
    echo "Extra -args = $ExpandedParamArgs"
}

# compile source files
# suppress spurious warnngs about
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt
set INC_DIRS "+incdir+${CONFIG}/${CFG} +incdir+${CONFIG}/deriv/${CFG} +incdir+${CONFIG}/shared +incdir+${FCRVVI} +incdir+${FCRVVI}/rv32 +incdir+${FCRVVI}/rv64 +incdir+${FCRVVI}/rv64_priv +incdir+${FCRVVI}/common"
set SOURCES "${SRC}/cvw.sv ${TB}/${TESTBENCH}.sv ${TB}/common/*.sv ${SRC}/*/*.sv ${SRC}/*/*/*.sv ${WALLY}/addins/verilog-ethernet/*/*.sv ${WALLY}/addins/verilog-ethernet/*/*/*/*.sv"
vlog -permissive -lint -work ${WKDIR} {*}${INC_DIRS} {*}${FCvlog} {*}${FCdefineCOVER_EXTS} {*}${lockstepvlog} {*}${SOURCES} -suppress 2282,2583,7053,7063,2596,13286

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt $accFlag wkdir/${CFG}_${TESTSUITE}.${TESTBENCH} -work ${WKDIR} {*}${ExpandedParamArgs} -o testbenchopt ${CoverageVoptArg}

vsim -lib ${WKDIR} testbenchopt +TEST=${TESTSUITE} {*}${PlusArgs} -fatal 7 {*}${SVLib} {*}${FCvopt} -suppress 3829 ${CoverageVsimArg}

# power add generates the logging necessary for saif generation.
# power add -r /dut/core/*

# add waveforms if GUI is enabled
if { ${GUI} } {
    add log -recursive /*
    if { ${TESTBENCH} eq "testbench_fp" } {
        do wave-fpu.do
    } else {
        do wave.do
    }
}

if {$FunctCoverage} {
    set UCDB ${WALLY}/sim/questa/fcov_ucdb/${CFG}_${TESTSUITE}.ucdb
    coverage save -onexit ${UCDB}
}

run -all

if {$ccov} {
    set UCDB ${WALLY}/sim/questa/ucdb/${CFG}_${TESTSUITE}.ucdb
    echo "Saving coverage to ${UCDB}"
    do coverage-exclusions-rv64gc.do  # beware: this assumes testing the rv64gc configuration
    coverage save -instance /testbench/dut/core ${UCDB}
}


# power off -r /dut/core/*



# These aren't doing anything helpful
#profile report -calltree -file wally-calltree.rpt -cutoff 2
#power report -all -bsaif power.saif

# terminate simulation unless we need to keep the GUI running
if { ${GUI} == 0} {
    quit
}
