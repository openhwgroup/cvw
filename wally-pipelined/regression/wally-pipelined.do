# wally-pipelined.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# run with vsim -do "do wally-pipelined.do rv64ic riscvarchtest-64m"

# Use this wally-pipelined.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-pipelined.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-pipelined.do -c
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

# default to config/rv64ic, but allow this to be overridden at the command line.  For example:
# do wally-pipelined.do ../config/rv32ic
#switch $argc {
#    0 {vlog +incdir+../config/rv64ic +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv ../src/*/*.sv -suppress 2583}
#    1 {vlog +incdir+$1  +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv ../src/*/*.sv -suppress 2583}
#}
# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vlog -lint +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv -suppress 2583
vopt +acc work.testbench -G TEST=$2 -o workopt 
vsim workopt

view wave
-- display input and output signals as hexidecimal values
do ./wave-dos/peripheral-waves.do

-- Run the Simulation 
#run 3600 
run -all
#quit
#noview ../testbench/testbench-imperas.sv
noview ../testbench/testbench.sv
view wave
