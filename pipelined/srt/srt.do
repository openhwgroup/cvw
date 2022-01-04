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

vlog srt.sv
vopt +acc work.testbench -o workopt 
vsim workopt

-- display input and output signals as hexidecimal values
do ./srt-waves.do

-- Run the Simulation 
run -all
