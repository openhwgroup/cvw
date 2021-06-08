# wally-pipelined.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with testbench_busybear 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Use this wally-pipelined.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-pipelined.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-pipelined.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if [file exists work-buildroot] {
    vdel -all -lib work-buildroot
}
vlib work-buildroot

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt
vlog +incdir+../config/buildroot +incdir+../config/shared ../testbench/testbench-linux.sv ../src/*/*.sv -suppress 2583


# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt work.testbench -o workopt 

vsim workopt -suppress 8852,12070

run -all
quit
