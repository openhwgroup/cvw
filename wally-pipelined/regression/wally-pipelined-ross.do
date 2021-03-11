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

# load the branch predictors with known data. The value of the data is not important for function, but
# is important for perventing pessimistic x propagation.
mem load -infile twoBitPredictor.txt -format bin testbench/dut/hart/ifu/bpred/DirPredictor/memory/memory
switch $argc {
    0 {mem load -infile ../config/rv64ic/BTBPredictor.txt -format bin testbench/dut/hart/ifu/bpred/TargetPredictor/memory/memory}
    1 {mem load -infile ../config/$1/BTBPredictor.txt -format bin testbench/dut/hart/ifu/bpred/TargetPredictor/memory/memory}
}

do wave.do
add log -r /*

-- Run the Simulation 
#run 1000
run -all
#quit
