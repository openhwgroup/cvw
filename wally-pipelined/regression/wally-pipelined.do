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
mem load -infile BTBPredictor.txt -format bin testbench/dut/hart/ifu/bpred/TargetPredictor/memory/memory

view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave /testbench/clk
add wave /testbench/reset
add wave -divider
#add wave /testbench/dut/hart/ebu/IReadF
add wave /testbench/dut/hart/DataStall
add wave /testbench/dut/hart/InstrStall
add wave /testbench/dut/hart/StallF
add wave /testbench/dut/hart/StallD
add wave /testbench/dut/hart/StallE
add wave /testbench/dut/hart/StallM
add wave /testbench/dut/hart/StallW
add wave /testbench/dut/hart/FlushD
add wave /testbench/dut/hart/FlushE
add wave /testbench/dut/hart/FlushM
add wave /testbench/dut/hart/FlushW

add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCF
add wave -hex /testbench/dut/hart/ifu/InstrF
add wave /testbench/InstrFName
add wave -hex /testbench/dut/hart/ifu/PCD
add wave -hex /testbench/dut/hart/ifu/InstrD
add wave /testbench/InstrDName
add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCE
add wave -hex /testbench/dut/hart/ifu/InstrE
add wave /testbench/InstrEName
add wave -hex /testbench/dut/hart/ieu/dp/SrcAE
add wave -hex /testbench/dut/hart/ieu/dp/SrcBE
add wave -hex /testbench/dut/hart/ieu/dp/ALUResultE
#add wave /testbench/dut/hart/ieu/dp/PCSrcE
add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCM
add wave -hex /testbench/dut/hart/ifu/InstrM
add wave /testbench/InstrMName
add wave /testbench/dut/uncore/dtim/memwrite
add wave -hex /testbench/dut/uncore/HADDR
add wave -hex /testbench/dut/uncore/HWDATA
add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCW
add wave -hex /testbench/dut/hart/ifu/InstrW
add wave /testbench/InstrWName
add wave /testbench/dut/hart/ieu/dp/RegWriteW
add wave -hex /testbench/dut/hart/ieu/dp/ResultW
add wave -hex /testbench/dut/hart/ieu/dp/RdW
add wave -divider
#add ww
add wave -hex -r /testbench/*

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
#run 2000
run -all
#quit
