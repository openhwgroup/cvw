# wally-pipelined-batch.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Usage: do wally-pipelined-batch.do <config> <testcases>
# Example: do wally-pipelined-batch.do rv32ic imperas-32i

# Use this wally-pipelined-batch.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-pipelined-batch.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-pipelined-batch.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if [file exists work_${1}_${2}] {
    vdel -lib work_${1}_${2} -all
}
vlib work_${1}_${2}

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

# default to config/rv64ic, but allow this to be overridden at the command line.  For example:
# do wally-pipelined-batch.do ../config/rv32ic rv32ic
vlog -lint -work work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv -suppress 2583

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt work_${1}_${2}.testbench -work work_${1}_${2} -G TEST=$2 -o testbenchopt
vsim -lib work_${1}_${2} testbenchopt 
# Adding coverage increases runtime from 2:00 to 4:29.  Can't run it all the time
#vopt work_$2.testbench -work work_$2 -o workopt_$2 +cover=sbectf
#vsim -coverage -lib work_$2 workopt_$2

run -all
#coverage report -file wally-pipelined-coverage.txt
# These aren't doing anything helpful
#coverage report -memory 
#profile report -calltree -file wally-pipelined-calltree.rpt -cutoff 2
quit
