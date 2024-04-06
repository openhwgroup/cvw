add wave /testbench/clk
add wave /testbench/reset
add wave -divider

#add wave /testbench/dut/core/ebu/ebu/IReadF
add wave /testbench/dut/core/DataStall
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

add wave -hex /testbench/dut/core/ebu/ebu/MemReadM
add wave -hex /testbench/dut/core/ebu/ebu/InstrReadF
add wave -hex /testbench/dut/core/ebu/ebu/BusState
add wave -hex /testbench/dut/core/ebu/ebu/NextBusState
add wave -hex /testbench/dut/core/ebu/ebu/HADDR
add wave -hex /testbench/dut/core/ebu/ebu/HREADY
add wave -hex /testbench/dut/core/ebu/ebu/HTRANS
add wave -hex /testbench/dut/core/ebu/ebu/HRDATA
add wave -hex /testbench/dut/core/ebu/ebu/HWRITE
add wave -hex /testbench/dut/core/ebu/ebu/HWDATA
add wave -hex /testbench/dut/core/ebu/ebu/ReadDataM
add wave -divider

add wave /testbench/dut/core/ebu/ebu/CaptureDataM
add wave /testbench/dut/core/ebu/ebu/CapturedDataAvailable
add wave /testbench/dut/core/StallW
add wave -hex /testbench/dut/core/ebu/ebu/CapturedData
add wave -hex /testbench/dut/core/ebu/ebu/ReadDataWnext
add wave -hex /testbench/dut/core/ebu/ebu/ReadDataW
add wave -hex /testbench/dut/core/ifu/PCW
add wave -hex /testbench/dut/core/ifu/InstrW
add wave /testbench/InstrWName
add wave /testbench/dut/core/ieu/dp/RegWriteW
add wave -hex /testbench/dut/core/ebu/ebu/ReadDataW
add wave -hex /testbench/dut/core/ieu/dp/ResultW
add wave -hex /testbench/dut/core/ieu/dp/RdW
add wave -divider

add wave -hex /testbench/dut/core/dmem/*
add wave -hex /testbench/dut/core/dmem/genblk1/*
add wave -divider

add wave -hex -r /testbench/*
