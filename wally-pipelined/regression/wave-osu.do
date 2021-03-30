# wally-pipelined.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
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
switch $argc {
    0 {vlog +incdir+../config/rv64ic ../testbench/testbench-imperas.sv ../src/*/*.sv -suppress 2583}
    1 {vlog +incdir+$1 ../testbench/testbench-imperas.sv ../src/*/*.sv -suppress 2583}
}
# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt +acc work.testbench -o workopt 
vsim workopt

view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave /testbench/clk
add wave /testbench/reset
add wave -noupdate -divider -height 32 "Datapath"
add wave -hex /testbench/dut/hart/ieu/dp/*
add wave -noupdate -divider -height 32 "RF"
add wave -hex /testbench/dut/hart/ieu/dp/regf/*
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf
add wave -noupdate -divider -height 32 "Control"
add wave -hex /testbench/dut/hart/ieu/c/*
add wave -noupdate -divider -height 32 "Multiply/Divide"
add wave -hex /testbench/dut/hart/mdu/*

-- Set Wave Output Items 
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {100 ps}
configure wave -namecolwidth 250
configure wave -valuecolwidth 120
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
set DefaultRadix hexadecimal

-- Run the Simulation 
#run 1000
run -all
#quit
