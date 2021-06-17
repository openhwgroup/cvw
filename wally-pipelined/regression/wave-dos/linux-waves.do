# linux-waves.do 
restart -f
delete wave /*
view wave

add wave -divider
add wave /testbench/clk
add wave /testbench/reset

add wave -divider Stalls_and_Flushes
add wave /testbench/dut/hart/StallF
add wave /testbench/dut/hart/StallD
add wave /testbench/dut/hart/StallE
add wave /testbench/dut/hart/StallM
add wave /testbench/dut/hart/StallW
add wave -group stall_srcs /testbench/dut/hart/DataStall
add wave -group stall_srcs /testbench/dut/hart/ICacheStallF
add wave /testbench/dut/hart/FlushD
add wave /testbench/dut/hart/FlushE
add wave /testbench/dut/hart/FlushM
add wave /testbench/dut/hart/FlushW

add wave -divider F
add wave -hex /testbench/dut/hart/ifu/PCF
add wave -divider D
add wave -hex /testbench/pcExpected
add wave -hex /testbench/dut/hart/ifu/PCD
add wave -hex /testbench/PCtextD
add wave /testbench/InstrDName
add wave -hex /testbench/dut/hart/ifu/InstrD
add wave -hex /testbench/dut/hart/ieu/c/InstrValidD
add wave -divider E
add wave -hex /testbench/dut/hart/ifu/PCE
add wave -hex /testbench/PCtextE
add wave /testbench/InstrEName
add wave -hex /testbench/dut/hart/ifu/InstrE
add wave -hex /testbench/dut/hart/ieu/c/InstrValidE
add wave -hex /testbench/dut/hart/ieu/dp/SrcAE
add wave -hex /testbench/dut/hart/ieu/dp/SrcBE
add wave -hex /testbench/dut/hart/ieu/dp/ALUResultE
add wave -divider M
add wave -hex /testbench/dut/hart/ifu/PCM
add wave -hex /testbench/PCtextM
add wave /testbench/InstrMName
add wave -hex /testbench/dut/hart/ifu/InstrM
add wave -hex /testbench/dut/hart/ieu/c/InstrValidM
add wave /testbench/dut/uncore/dtim/memwrite
add wave -hex /testbench/dut/uncore/HADDR
add wave -hex /testbench/HWRITE
add wave -hex /testbench/dut/uncore/HWDATA
add wave -hex /testbench/HRDATA
add wave -hex /testbench/readAdrExpected
add wave -divider W
add wave -hex /testbench/PCW
add wave -hex /testbench/PCtextW
add wave -hex /testbench/dut/hart/ieu/c/InstrValidW
add wave /testbench/dut/hart/ieu/dp/RegWriteW
add wave -hex /testbench/dut/hart/ieu/dp/ResultW
add wave -hex /testbench/dut/hart/ieu/dp/RdW

add wave -divider RegFile
add wave -hex /testbench/regExpected
add wave -hex /testbench/regNumExpected
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[1]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[2]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[3]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[4]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[5]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[6]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[7]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[8]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[9]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[10]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[11]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[12]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[13]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[14]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[15]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[16]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[17]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[18]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[19]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[20]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[21]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[22]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[23]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[24]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[25]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[26]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[27]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[28]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[29]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[30]
add wave -hex /testbench/dut/hart/ieu/dp/regf/rf[31]

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
