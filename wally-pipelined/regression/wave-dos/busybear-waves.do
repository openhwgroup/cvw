# busybear-waves.do 

restart -f
delete wave /*
view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave /testbench/clk
add wave /testbench/reset
add wave -divider
add wave -hex /testbench/PCtext
add wave -hex /testbench/pcExpected
add wave -hex /testbench/dut/hart/ifu/PCD
add wave -hex /testbench/dut/hart/ifu/InstrD
add wave -hex /testbench/dut/hart/ifu/StallD
add wave -hex /testbench/dut/hart/ifu/FlushD
add wave -hex /testbench/dut/hart/ifu/StallE
add wave -hex /testbench/dut/hart/ifu/FlushE
add wave -hex /testbench/dut/hart/ifu/InstrRawD
add wave /testbench/CheckInstrD
add wave /testbench/lastCheckInstrD
add wave /testbench/speculative
add wave /testbench/dut/hart/ifu/bpred/BPPredWrongE
add wave /testbench/lastPC2
add wave -divider
add wave -divider
add wave /testbench/dut/uncore/HSELBootTim
add wave /testbench/dut/uncore/HSELTim
add wave /testbench/dut/uncore/HREADTim
add wave /testbench/dut/uncore/dtim/HREADTim0
add wave /testbench/dut/uncore/HREADYTim
add wave -divider
add wave /testbench/dut/uncore/HREADBootTim
add wave /testbench/dut/uncore/bootdtim/HREADTim0
add wave /testbench/dut/uncore/HREADYBootTim
add wave /testbench/dut/uncore/HADDR
add wave /testbench/dut/uncore/HRESP
add wave /testbench/dut/uncore/HREADY
add wave /testbench/dut/uncore/HRDATA
#add wave -hex /testbench/dut/hart/priv/csr/MTVEC_REG
#add wave -hex /testbench/dut/hart/priv/csr/MSTATUS_REG
#add wave -hex /testbench/dut/hart/priv/csr/SCOUNTEREN_REG
#add wave -hex /testbench/dut/hart/priv/csr/MIE_REG
#add wave -hex /testbench/dut/hart/priv/csr/MIDELEG_REG
#add wave -hex /testbench/dut/hart/priv/csr/MEDELEG_REG
add wave -divider
# registers!
add wave -hex /testbench/regExpected
add wave -hex /testbench/regNumExpected
add wave -hex /testbench/HWRITE
add wave -hex /testbench/dut/hart/MemRWM[1]
add wave -hex /testbench/HWDATA
add wave -hex /testbench/HRDATA
add wave -hex /testbench/HADDR
add wave -hex /testbench/readAdrExpected
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
add wave /testbench/InstrFName
add wave -hex /testbench/dut/hart/ifu/PCD
#add wave -hex /testbench/dut/hart/ifu/InstrD
add wave /testbench/InstrDName
#add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCE
##add wave -hex /testbench/dut/hart/ifu/InstrE
add wave /testbench/InstrEName
#add wave -hex /testbench/dut/hart/ieu/dp/SrcAE
#add wave -hex /testbench/dut/hart/ieu/dp/SrcBE
add wave -hex /testbench/dut/hart/ieu/dp/ALUResultE
#add wave /testbench/dut/hart/ieu/dp/PCSrcE
#add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCM
##add wave -hex /testbench/dut/hart/ifu/InstrM
add wave /testbench/InstrMName
#add wave /testbench/dut/hart/dmem/dtim/memwrite
#add wave -hex /testbench/dut/hart/dmem/AdrM
#add wave -hex /testbench/dut/hart/dmem/WriteDataM
#add wave -divider
add wave -hex /testbench/PCW
##add wave -hex /testbench/dut/hart/ifu/InstrW
add wave /testbench/InstrWName
#add wave /testbench/dut/hart/ieu/dp/RegWriteW
#add wave -hex /testbench/dut/hart/ieu/dp/ResultW
#add wave -hex /testbench/dut/hart/ieu/dp/RdW
#add wave -divider
##add ww
add wave -hex -r /testbench/*
#
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
