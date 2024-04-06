# testfloat-batch.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021; Kevin Kim 2024
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# run with vsim -do "do wally.do rv64ic riscvarchtest-64m"

onbreak {resume}

# create library

if [file exists wkdir/work_${1}_${2}] {
    vdel -lib wkdir/work_${1}_${2} -all
}
vlib wkdir/work_${1}_${2}



# c# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
# $num = the added words after the call

vlog -lint -work wkdir/work_${1}_${2} +incdir+../config/$1 +incdir+../config/deriv/$1 +incdir+../config/shared ../src/cvw.sv ../testbench/testbench-fp.sv ../src/fpu/*.sv ../src/fpu/*/*.sv ../src/generic/*.sv  ../src/generic/flop/*.sv -suppress 2583,7063,8607,2697,7033 


# Set WAV variable to avoid having any output to wave (to limit disk space)
quietly set WAV 0;

# Determine if nowave argument is provided this removes any output to
# a wlf or wave window to reduce disk space.
if {$WAV eq 0} {
    puts "No wave output is selected"
} else {
    puts "wave output is selected"
    view wave
    add log -recursive /*
    do wave-fpu.do    
}  

# Change TEST_SIZE to only test certain FP width
# values are QP, DP, SP, HP or all for all tests

vopt +acc wkdir/work_${1}_${2}.testbench-fp -work wkdir/work_${1}_${2} -G TEST=$2 -G TEST_SIZE="all" -o testbenchopt
vsim -lib wkdir/work_${1}_${2} testbenchopt  -fatal 7 -suppress 3829
#-- Run the Simulation 
run -all
