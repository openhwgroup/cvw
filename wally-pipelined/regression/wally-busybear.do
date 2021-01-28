# wally-pipelined.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with testbench_busybear 
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
vlog +incdir+../config/busybear ../testbench/*.sv ../src/*.sv -suppress 2583

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt +acc work.testbench_busybear -o workopt 
vsim workopt

view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave /testbench_busybear/clk
add wave /testbench_busybear/reset
add wave -divider
add wave -hex /testbench_busybear/PCtext
add wave -hex /testbench_busybear/pcExpected
add wave -hex /testbench_busybear/dut/ifu/PCF
add wave -hex /testbench_busybear/dut/ifu/InstrF
add wave /testbench_busybear/lastInstrF
add wave /testbench_busybear/speculative
add wave /testbench_busybear/lastPC2
add wave -divider
# registers!
add wave -hex /testbench_busybear/rfExpected
add wave -hex /testbench_busybear/MemRWM[0]
add wave -hex /testbench_busybear/MemRWM[1]
add wave -hex /testbench_busybear/ByteMaskM
add wave -hex /testbench_busybear/WriteDataM
add wave -hex /testbench_busybear/DataAdrM
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[1]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[2]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[3]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[4]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[5]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[6]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[7]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[8]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[9]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[10]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[11]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[12]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[13]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[14]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[15]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[16]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[17]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[18]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[19]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[20]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[21]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[22]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[23]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[24]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[25]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[26]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[27]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[28]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[29]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[30]
add wave -hex /testbench_busybear/dut/ieu/dp/regf/rf[31]
add wave /testbench_busybear/InstrFName
add wave -hex /testbench_busybear/dut/ifu/PCD
#add wave -hex /testbench_busybear/dut/ifu/InstrD
add wave /testbench_busybear/InstrDName
#add wave -divider
add wave -hex /testbench_busybear/dut/ifu/PCE
##add wave -hex /testbench_busybear/dut/ifu/InstrE
add wave /testbench_busybear/InstrEName
#add wave -hex /testbench_busybear/dut/ieu/dp/SrcAE
#add wave -hex /testbench_busybear/dut/ieu/dp/SrcBE
add wave -hex /testbench_busybear/dut/ieu/dp/ALUResultE
#add wave /testbench_busybear/dut/ieu/dp/PCSrcE
#add wave -divider
add wave -hex /testbench_busybear/dut/ifu/PCM
##add wave -hex /testbench_busybear/dut/ifu/InstrM
add wave /testbench_busybear/InstrMName
#add wave /testbench_busybear/dut/dmem/dtim/memwrite
#add wave -hex /testbench_busybear/dut/dmem/AdrM
#add wave -hex /testbench_busybear/dut/dmem/WriteDataM
#add wave -divider
add wave -hex /testbench_busybear/dut/ifu/PCW
##add wave -hex /testbench_busybear/dut/ifu/InstrW
add wave /testbench_busybear/InstrWName
#add wave /testbench_busybear/dut/ieu/dp/RegWriteW
#add wave -hex /testbench_busybear/dut/ieu/dp/ResultW
#add wave -hex /testbench_busybear/dut/ieu/dp/RdW
#add wave -divider
##add ww
#add wave -hex -r /testbench_busybear/*
#
#-- Set Wave Output Items 
#TreeUpdate [SetDefaultTree]
#WaveRestoreZoom {0 ps} {100 ps}
#configure wave -namecolwidth 250
#configure wave -valuecolwidth 120
#configure wave -justifyvalue left
#configure wave -signalnamewidth 0
#configure wave -snapdistance 10
#configure wave -datasetprefix 0
#configure wave -rowmargin 4
#configure wave -childrowmargin 2
#set DefaultRadix hexadecimal
#
#-- Run the Simulation 
run 1300
#run -all
##quit
