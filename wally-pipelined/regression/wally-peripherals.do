# wally-peripherals.do 
#
# Created by Ben Bracker (bbracker@hmc.edu) on 11 Feb. 2021
#
# Based on wally-pipelined.do by 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!

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
# That said, I don't think there are any peripherals that use anything but rv64i just yet.
switch $argc {
    0 {vlog +incdir+../config/rv64ic ../testbench/testbench-peripherals.sv ../src/*/*.sv -suppress 2583}
    1 {vlog +incdir+$1 ../testbench/testbench-peripherals.sv ../src/*/*.sv -suppress 2583}
}
# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt +acc work.testbench -o workopt 
vsim workopt


view wave
do wally-peripherals-signals.do
