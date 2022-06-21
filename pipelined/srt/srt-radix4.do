# srt.do   
#
# David_Harris@hmc.edu 19 October 2021

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

vlog +incdir+../config/rv64gc +incdir+../config/shared srt-radix4.sv testbench-radix4.sv ../src/generic/flop/flop*.sv ../src/generic/mux.sv ../src/generic/lzc.sv
vopt +acc work.testbenchradix4 -o workopt 
vsim workopt

-- display input and output signals as hexidecimal values
add wave /testbenchradix4/*
add wave /testbenchradix4/srtradix4/*
add wave /testbenchradix4/srtradix4/qsel4/*
add wave /testbenchradix4/srtradix4/otfc4/*

-- Run the Simulation 
run -all
