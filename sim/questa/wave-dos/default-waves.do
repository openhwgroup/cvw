# default-waves.do
restart -f
delete wave /*
view wave

# Diplays All Signals recursively
add wave /testbench/clk
add wave /testbench/reset
add wave -divider
#add wave /testbench/dut/core/ebu/ebu/IReadF
#add wave /testbench/dut/core/DataStall
add wave /testbench/dut/core/ICacheStallF
add wave /testbench/dut/core/StallF
add wave /testbench/dut/core/StallD
add wave /testbench/dut/core/StallE
add wave /testbench/dut/core/StallM
add wave /testbench/dut/core/StallW
add wave /testbench/dut/core/FlushD
add wave /testbench/dut/core/FlushE
add wave /testbench/dut/core/FlushM
add wave /testbench/dut/core/FlushW

add wave -divider
add wave -hex /testbench/dut/core/ifu/PCF
add wave -hex /testbench/dut/core/ifu/PCD
add wave -hex /testbench/dut/core/ifu/InstrD
add wave /testbench/InstrDName
add wave -divider
add wave -hex /testbench/dut/core/ifu/PCE
add wave -hex /testbench/dut/core/ifu/InstrE
add wave /testbench/InstrEName
add wave -hex /testbench/dut/core/ieu/dp/SrcAE
add wave -hex /testbench/dut/core/ieu/dp/SrcBE
add wave -hex /testbench/dut/core/ieu/dp/ALUResultE
#add wave /testbench/dut/core/ieu/dp/PCSrcE
add wave -divider
add wave -hex /testbench/dut/core/ifu/PCM
add wave -hex /testbench/dut/core/ifu/InstrM
add wave /testbench/InstrMName
add wave /testbench/dut/uncore/uncore/ram/memwrite
add wave -hex /testbench/dut/uncore/uncore/HADDR
add wave -hex /testbench/dut/uncore/uncore/HWDATA
add wave -divider
add wave -hex /testbench/PCW
add wave -hex /testbench/InstrW
add wave /testbench/InstrWName
add wave /testbench/dut/core/ieu/dp/RegWriteW
add wave -hex /testbench/dut/core/ieu/dp/ResultW
add wave -hex /testbench/dut/core/ieu/dp/RdW
add wave -divider

add wave -hex -r /testbench/*

# appearance
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {100 ps}
configure wave -namecolwidth 250
configure wave -valuecolwidth 150
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
set DefaultRadix hexadecimal
