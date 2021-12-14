# ahb-waves.do
restart -f
delete wave /*
view wave

add wave /testbench/clk
add wave /testbench/reset
add wave -divider

#add wave /testbench/dut/hart/ebu/IReadF
add wave /testbench/dut/hart/DataStall
add wave /testbench/dut/hart/ICacheStallF
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
add wave -hex /testbench/dut/hart/ifu/ic/InstrRawD
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
add wave /testbench/dut/uncore/ram/memwrite
add wave -hex /testbench/dut/uncore/HADDR
add wave -hex /testbench/dut/uncore/HWDATA
add wave -divider

add wave -hex /testbench/dut/hart/ebu/MemReadM
add wave -hex /testbench/dut/hart/ebu/InstrReadF
add wave -hex /testbench/dut/hart/ebu/BusState
add wave -hex /testbench/dut/hart/ebu/NextBusState
add wave -hex /testbench/dut/hart/ebu/HADDR
add wave -hex /testbench/dut/hart/ebu/HREADY
add wave -hex /testbench/dut/hart/ebu/HTRANS
add wave -hex /testbench/dut/hart/ebu/HRDATA
add wave -hex /testbench/dut/hart/ebu/HWRITE
add wave -hex /testbench/dut/hart/ebu/HWDATA
add wave -hex /testbench/dut/hart/ebu/CaptureDataM
add wave -divider

add wave -hex /testbench/dut/uncore/ram/*
add wave -divider

add wave -hex /testbench/dut/hart/ifu/PCW
add wave -hex /testbench/dut/hart/ifu/InstrW
add wave /testbench/InstrWName
add wave /testbench/dut/hart/ieu/dp/RegWriteW
add wave -hex /testbench/dut/hart/ebu/ReadDataW
add wave -hex /testbench/dut/hart/ieu/dp/ResultW
add wave -hex /testbench/dut/hart/ieu/dp/RdW
add wave -divider

add wave -hex /testbench/dut/uncore/ram/*
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
