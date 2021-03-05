# wally-peripherals-signals.do 
#
# Created by Ben Bracker (bbracker@hmc.edu) on 4 Mar. 2021
#
# I really didn't like having to relaunch and recompile an entire sim
# just because some signal names have changed, so I thought this
# would be good to factor out.

restart -f
delete wave /*
view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave /testbench/clk
add wave /testbench/reset
add wave -divider
add wave /testbench/dut/hart/DataStall
add wave /testbench/dut/hart/InstrStall
add wave /testbench/dut/hart/StallF
add wave /testbench/dut/hart/StallD
add wave /testbench/dut/hart/FlushD
add wave /testbench/dut/hart/FlushE
add wave /testbench/dut/hart/FlushM
add wave /testbench/dut/hart/FlushW

add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCF
add wave -hex /testbench/dut/hart/ifu/InstrF
add wave /testbench/InstrFName
#add wave -hex /testbench/dut/hart/ifu/PCD
add wave -hex /testbench/dut/hart/ifu/InstrD
add wave /testbench/InstrDName
add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCE
add wave -hex /testbench/dut/hart/ifu/InstrE
add wave /testbench/InstrEName
add wave -hex /testbench/dut/hart/ieu/dp/SrcAE
add wave -hex /testbench/dut/hart/ieu/dp/SrcBE
add wave -hex /testbench/dut/hart/ieu/dp/ALUResultE
add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCM
add wave -hex /testbench/dut/hart/ifu/InstrM
add wave /testbench/InstrMName
add wave /testbench/dut/uncore/dtim/memwrite
add wave -hex /testbench/dut/uncore/HADDR
add wave -hex /testbench/dut/uncore/HWDATA
add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCW
add wave /testbench/InstrWName
add wave /testbench/dut/hart/ieu/dp/RegWriteW
add wave -hex /testbench/dut/hart/ieu/dp/ResultW
add wave -hex /testbench/dut/hart/ieu/dp/RdW
add wave -divider
add wave -hex /testbench/dut/hart/ebu/*
add wave -divider
add wave -hex /testbench/dut/uncore/uart/u/*
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
#run 5000 
run -all
#quit
noview ../testbench/testbench-peripherals.sv
view wave
