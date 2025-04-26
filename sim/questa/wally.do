# wally.do
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench
# James Stine, 2008; David Harris 2021; Jordan Carlin 2024
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Usage: do wally.do <config> <testcases> <testbench> [--ccov] [--fcov] [--gui] [--args "any number of +value"] [--params "any number of VAR=VAL parameter overrides"] [--define "any number of +define+VAR=VAL"]
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
set DefineArgs ""

set ccov 0
set CoverageVoptArg ""
set CoverageVsimArg ""

set FunctCoverage 0
set FCvlog ""

set breker 0
set brekervlog ""
set brekervopt ""

set lockstep 0
set lockstepvlog ""

set SVLib ""

set GUI 0
set accFlag ""

# Need to be able to pass arguments to vopt.  Unforunately argv does not work because
# it takes on different values if vsim and the do file are called from the command line or
# if the do file is called from questa sim directly.  This chunk of code uses the $n variables
# and compacts them into a single list for passing to vopt. Shift is used to move the arguments
# through the list.
set lst {}
echo "number of args = $argc"

# Shift off the first three arguments (config, testcases, testbench)
shift
shift
shift

# Copy the remaining arguments into a list
while {$argc > 0} {
    lappend lst [expr "\$1"]
    shift
}

echo "lst = $lst"

# if --gui found set flag and remove from list
if {[lcheck lst "--gui"]} {
    set GUI 1
    set accFlag "+acc"
}

# if --vcd found set flag and remove from list
if {[lcheck lst "--vcd"]} {
    set VCD 1
    set accFlag "+acc"
}

# if --ccov found set flag and remove from list
if {[lcheck lst "--ccov"]} {
    set ccov 1
    set CoverageVoptArg "+cover=sbecf"
    set CoverageVsimArg "-coverage"
}

# if --fcov found set flag and remove from list
if {[lcheck lst "--fcov"]} {
    set FunctCoverage 1
    set FCvlog "-f ${FCRVVI}/cvw-arch-verif.f"
}

# if --lockstep found set flag and remove from list
if {[lcheck lst "--lockstep"]} {
    set IMPERAS_HOME $::env(IMPERAS_HOME)
    set lockstep 1
    set SVLib " -sv_lib ${IMPERAS_HOME}/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model "
    set lockstepvlog "+incdir+${IMPERAS_HOME}/ImpPublic/include/host \
                      +incdir+${IMPERAS_HOME}/ImpProprietary/include/host \
                      ${IMPERAS_HOME}/ImpPublic/source/host/rvvi/rvviApiPkg.sv \
                      ${IMPERAS_HOME}/ImpProprietary/source/host/idv/*.sv"
    # only add standard rvviTrace interface if not using the custom one from cvw-arch-verif
    if {!$FunctCoverage} {append lockstepvlog " ${IMPERAS_HOME}/ImpPublic/source/host/rvvi/rvviTrace.sv"}
}

# if --breker found set flag and remove from list
# Requires a license for the breker tool. See tests/breker/README.md for details
if {[lcheck lst "--breker"]} {
    set breker 1
    set BREKER_HOME $::env(BREKER_HOME)
    set brekervlog "+incdir+${WALLY}/testbench/trek_files \
                    ${WALLY}/testbench/trek_files/uvm_output/trek_uvm_pkg.sv"
    set brekervopt "${WKDIR}.trek_uvm"
    append SVLib " -sv_lib ${BREKER_HOME}/linux64/lib/libtrek "
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

# Set +define macros passed using the --define flag
set DefineArgsIndex [lsearch -exact $lst "--define"]
if {$DefineArgsIndex >= 0} {
    set DefineArgs [lindex $lst [expr {$DefineArgsIndex + 1}]]
    set lst [lreplace $lst $DefineArgsIndex [expr {$DefineArgsIndex + 1}]]
}

# Debug print statements
if {$DEBUG > 0} {
    echo "GUI = $GUI"
    echo "ccov = $ccov"
    echo "lockstep = $lockstep"
    echo "FunctCoverage = $FunctCoverage"
    echo "Breker = $breker"
    echo "remaining list = $lst"
    echo "Extra +args = $PlusArgs"
    echo "Extra params = $ExpandedParamArgs"
    echo "Extra defines = $DefineArgs"
}

# compile source files
# suppress spurious warnngs about
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt
set INC_DIRS "+incdir+${CONFIG}/${CFG} +incdir+${CONFIG}/deriv/${CFG} +incdir+${CONFIG}/shared"
set SOURCES "${SRC}/cvw.sv ${TB}/${TESTBENCH}.sv ${TB}/common/*.sv ${SRC}/*/*.sv ${SRC}/*/*/*.sv ${WALLY}/addins/verilog-ethernet/*/*.sv ${WALLY}/addins/verilog-ethernet/*/*/*/*.sv"
vlog -permissive -lint -work ${WKDIR} {*}${INC_DIRS} {*}${DefineArgs} {*}${lockstepvlog} {*}${FCvlog} {*}${brekervlog} {*}${SOURCES} -suppress 2282,2583,7053,7063,2596,13286,2605,2250

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt $accFlag ${WKDIR}.${TESTBENCH} ${brekervopt} -work ${WKDIR} {*}${ExpandedParamArgs} -o testbenchopt ${CoverageVoptArg}

vsim -lib ${WKDIR} testbenchopt +TEST=${TESTSUITE} {*}${PlusArgs} -fatal 7 {*}${SVLib} -suppress 3829 ${CoverageVsimArg} 
# +IDV_TRACE2LOG=1  (add this to vsim command to enable ImperasDV RVVI trace logging)

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
