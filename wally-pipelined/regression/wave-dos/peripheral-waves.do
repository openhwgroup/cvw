# peripheral-waves.do 

restart -f
delete wave /*
view wave

# general stuff
add wave /testbench/clk
add wave /testbench/reset
add wave -divider

#add wave /testbench/dut/hart/DataStall
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
add wave -hex /testbench/dut/hart/ieu/c/InstrValidD
add wave /testbench/InstrDName
add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCE
add wave -hex /testbench/dut/hart/ifu/InstrE
add wave -hex /testbench/dut/hart/ieu/c/InstrValidE
add wave /testbench/InstrEName
add wave -hex /testbench/dut/hart/ieu/dp/SrcAE
add wave -hex /testbench/dut/hart/ieu/dp/SrcBE
add wave -hex /testbench/dut/hart/ieu/dp/ALUResultE
#add wave /testbench/dut/hart/ieu/dp/PCSrcE
add wave /testbench/dut/hart/mdu/genblk1/div/StartDivideE
add wave /testbench/dut/hart/mdu/DivBusyE
add wave -hex /testbench/dut/hart/mdu/genblk1/div/DE
add wave -hex /testbench/dut/hart/mdu/genblk1/div/Din
add wave -hex /testbench/dut/hart/mdu/genblk1/div/XE
add wave -hex /testbench/dut/hart/mdu/genblk1/div/Win
add wave -hex /testbench/dut/hart/mdu/genblk1/div/XQin
add wave -hex /testbench/dut/hart/mdu/genblk1/div/Wshift
add wave -hex /testbench/dut/hart/mdu/genblk1/div/XQshift
add wave -hex /testbench/dut/hart/mdu/genblk1/div/Wnext
add wave -hex /testbench/dut/hart/mdu/genblk1/div/qi
add wave -hex /testbench/dut/hart/mdu/genblk1/div/Wprime
add wave -hex /testbench/dut/hart/mdu/genblk1/div/W
add wave -hex /testbench/dut/hart/mdu/genblk1/div/XQ
add wave -hex /testbench/dut/hart/mdu/genblk1/div/RemM
add wave -hex /testbench/dut/hart/mdu/genblk1/div/QuotM

add wave -divider
add wave -hex /testbench/dut/hart/ifu/PCM
add wave -hex /testbench/dut/hart/ifu/InstrM
add wave -hex /testbench/dut/hart/ieu/c/InstrValidM
add wave /testbench/InstrMName
add wave /testbench/dut/uncore/dtim/memwrite
add wave -hex /testbench/dut/hart/WriteDataM
add wave -hex /testbench/dut/hart/lsu/dcache/MemPAdrM
add wave -hex /testbench/dut/hart/lsu/dcache/WriteDataM
add wave -hex /testbench/dut/hart/lsu/dcache/ReadDataM
add wave -hex /testbench/dut/hart/ebu/ReadDataM
add wave -divider
add wave -hex /testbench/PCW
#add wave -hex /testbench/InstrW
add wave -hex /testbench/dut/hart/ieu/c/InstrValidW
#add wave /testbench/InstrWName
add wave -hex /testbench/dut/hart/ReadDataW
add wave -hex /testbench/dut/hart/ieu/dp/ResultW
add wave -hex /testbench/dut/hart/ieu/dp/RegWriteW
add wave -hex /testbench/dut/hart/ieu/dp/WriteDataW
add wave -hex /testbench/dut/hart/ieu/dp/RdW
add wave -divider
add wave -hex /testbench/dut/hart/priv/csr/TrapM
add wave -hex /testbench/dut/hart/priv/csr/UnalignedNextEPCM
add wave -hex /testbench/dut/hart/priv/csr/genblk1/csrm/WriteMEPCM
add wave -hex /testbench/dut/hart/priv/csr/genblk1/csrm/MEPC_REGW

add wave -divider RegFile
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

# peripherals
add wave -divider PLIC
add wave -hex /testbench/dut/hart/priv/csr/TrapM
add wave -hex /testbench/dut/uncore/plic/plic/*
add wave -hex /testbench/dut/uncore/plic/plic/intPriority
add wave -hex /testbench/dut/uncore/plic/plic/pendingArray
add wave -divider UART
add wave -hex /testbench/dut/uncore/uart/uart/u/*
add wave -divider GPIO
add wave -hex /testbench/dut/uncore/gpio/gpio/*
#add wave -divider
#add wave -hex /testbench/dut/hart/ebu/*
#add wave -divider
#add wave -divider

# everything else
add wave -hex -r /testbench/*
