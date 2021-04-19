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

# general stuff
add wave /testbench/clk
add wave /testbench/reset
add wave -divider

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
add wave -hex /testbench/PCW
add wave -hex /testbench/InstrW
add wave /testbench/InstrWName
add wave /testbench/dut/hart/ieu/dp/RegWriteW
add wave -hex /testbench/dut/hart/ieu/dp/ResultW
add wave -hex /testbench/dut/hart/ieu/dp/RdW
add wave -divider
add wave -divider

# peripherals
add wave -hex /testbench/dut/uncore/gpio/*
add wave -divider
add wave -hex /testbench/dut/uncore/plic/*
add wave -hex /testbench/dut/uncore/plic/intPriority
add wave -hex /testbench/dut/uncore/plic/pendingArray
add wave -divider
add wave -hex /testbench/dut/uncore/uart/u/*
add wave -divider
add wave -hex /testbench/dut/hart/ebu/*
add wave -divider
add wave -divider

# everything else
add wave -hex -r /testbench/*

