# wally-coremark.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Use this wally-coremark.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-coremark.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-coremark.do -c
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

# default to config/coremark, but allow this to be overridden at the command line.  For example:
vlog +incdir+../config/coremark_bare +incdir+../config/shared ../testbench/testbench-coremark_bare.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt +acc work.testbench -o workopt 
vsim workopt

mem load -startaddress 268435456 -endaddress 268566527 -filltype value -fillradix hex -filldata 0 /testbench/dut/uncore/ram/ram/RAM


do wave.do
run -all
#run 21400
#quit
