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
vlog +incdir+../config/rv64ic ../testbench/testbench-imperas.sv ../src/*.sv -suppress 2583

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt +acc work.testbench -o workopt 
vsim workopt

view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave /testbench/clk
add wave /testbench/reset
add wave -divider
add wave -hex /testbench/dut/hart/dp/PCF
add wave -hex /testbench/dut/hart/dp/InstrF
add wave /testbench/InstrFName
#add wave -hex /testbench/dut/hart/dp/PCD
add wave -hex /testbench/dut/hart/dp/InstrD
add wave /testbench/InstrDName
add wave -divider
#add wave -hex /testbench/dut/hart/dp/PCE
#add wave -hex /testbench/dut/hart/dp/InstrE
add wave /testbench/InstrEName
add wave -hex /testbench/dut/hart/dp/SrcAE
add wave -hex /testbench/dut/hart/dp/SrcBE
add wave -hex /testbench/dut/hart/dp/ALUResultE
add wave /testbench/dut/hart/dp/PCSrcE
add wave -divider
#add wave -hex /testbench/dut/hart/dp/PCM
#add wave -hex /testbench/dut/hart/dp/InstrM
add wave /testbench/InstrMName
add wave /testbench/dut/dmem/dtim/memwrite
add wave -hex /testbench/dut/dmem/AdrM
add wave -hex /testbench/dut/dmem/WriteDataM
add wave -divider
add wave -hex /testbench/dut/hart/dp/PCW
#add wave -hex /testbench/dut/hart/dp/InstrW
add wave /testbench/InstrWName
add wave /testbench/dut/hart/dp/RegWriteW
add wave -hex /testbench/dut/hart/dp/ResultW
add wave -hex /testbench/dut/hart/dp/RdW
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
#run 1000
run -all
#quit
