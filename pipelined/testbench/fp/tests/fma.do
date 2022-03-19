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
# $num = the added words after the call
vlog +incdir+../../../config/$1 +incdir+../../../config/shared fma-testbench.sv ../../../src/fpu/fma.sv ../../../src/fpu/unpack.sv -suppress 2583 -suppress 7063

vsim -voptargs=+acc work.fmatestbench

view wave
#-- display input and output signals as hexidecimal values
#do ./wave-dos/peripheral-waves.do
#add log -recursive /*
#do wave.do deal with when ready

#-- Run the Simulation 
#run 3600 
run -all
noview fma-testbench.sv
view wave

