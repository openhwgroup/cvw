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

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
if {$2 eq "buildroot"} {
    vlog +incdir+../config/buildroot +incdir+../config/shared ../testbench/testbench-linux.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583


    # start and run simulation
    # remove +acc flag for faster sim during regressions if there is no need to access internal signals
    vopt +acc work.testbench -G INSTR_LIMIT=$3 -G INSTR_WAVEON=$4 -G CHECKPOINT=$5 -o workopt 

    vsim workopt -suppress 8852,12070

    #-- Run the Simulation 
    run -all
    do linux-wave.do
    add log -recursive /*
    run -all

    exec ./slack-notifier/slack-notifier.py
  } else {
    vlog +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv ../src/*/*/*.sv -suppress 2583 -suppress 7063
    vopt +acc work.testbench -G TEST=$2 -G DEBUG=1 -o workopt 

    vsim workopt +nowarn3829

    view wave
    #-- display input and output signals as hexidecimal values
    #do ./wave-dos/peripheral-waves.do
    add log -recursive /*
    do wave.do

    # power add generates the logging necessary for saif generation.
    #power add -r /dut/core/*
    #-- Run the Simulation 

    run -all
    #power off -r /dut/core/*
    #power report -all -bsaif power.saif
    noview ../testbench/testbench.sv
    view wave
}

