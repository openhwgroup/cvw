# peripheral-waves.do 

restart -f
delete wave /*
view wave

# general stuff
add wave /testbench/clk
add wave /testbench/reset
add wave -divider

#add wave /testbench/dut/core/DataStall
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
add wave -hex /testbench/dut/core/ieu/c/InstrValidD
add wave /testbench/InstrDName
add wave -divider
add wave -hex /testbench/dut/core/ifu/PCE
add wave -hex /testbench/dut/core/ifu/InstrE
add wave -hex /testbench/dut/core/ieu/c/InstrValidE
add wave /testbench/InstrEName
add wave -hex /testbench/dut/core/ieu/dp/SrcAE
add wave -hex /testbench/dut/core/ieu/dp/SrcBE
add wave -hex /testbench/dut/core/ieu/dp/ALUResultE
#add wave /testbench/dut/core/ieu/dp/PCSrcE
add wave /testbench/dut/core/mdu/genblk1/div/DivStartE
add wave /testbench/dut/core/mdu/DivBusyE
add wave -hex /testbench/dut/core/mdu/genblk1/div/RemM
add wave -hex /testbench/dut/core/mdu/genblk1/div/QuotM

add wave -divider
add wave -hex /testbench/dut/core/ifu/PCM
add wave -hex /testbench/dut/core/ifu/InstrM
add wave -hex /testbench/dut/core/ieu/c/InstrValidM
add wave /testbench/InstrMName
add wave /testbench/dut/uncore/uncore/ram/memwrite
add wave -hex /testbench/dut/core/WriteDataM
add wave -hex /testbench/dut/core/lsu.bus.dcache/MemPAdrM
add wave -hex /testbench/dut/core/lsu.bus.dcache/WriteDataM
add wave -hex /testbench/dut/core/lsu.bus.dcache/ReadDataM
add wave -divider
add wave -hex /testbench/PCW
#add wave -hex /testbench/InstrW
#add wave -hex /testbench/dut/core/ieu/c/InstrValidW
#add wave /testbench/InstrWName
add wave -hex /testbench/dut/core/ReadDataW
add wave -hex /testbench/dut/core/ieu/dp/ResultW
add wave -hex /testbench/dut/core/ieu/dp/RegWriteW
add wave -hex /testbench/dut/core/ieu/dp/WriteDataW
add wave -hex /testbench/dut/core/ieu/dp/RdW
add wave -divider
add wave -hex /testbench/dut/core/priv/csr/TrapM
add wave -hex /testbench/dut/core/priv/csr/UnalignedNextEPCM
add wave -hex /testbench/dut/core/priv/csr/genblk1/csrm/WriteMEPCM
add wave -hex /testbench/dut/core/priv/csr/genblk1/csrm/MEPC_REGW

add wave -divider RegFile
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[1]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[2]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[3]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[4]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[5]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[6]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[7]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[8]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[9]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[10]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[11]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[12]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[13]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[14]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[15]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[16]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[17]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[18]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[19]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[20]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[21]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[22]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[23]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[24]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[25]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[26]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[27]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[28]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[29]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[30]
add wave -hex /testbench/dut/core/ieu/dp/regf/rf[31]

# peripherals
add wave -divider PLIC
add wave -hex /testbench/dut/core/priv/csr/TrapM
add wave -hex /testbench/dut/uncore/uncore/plic/plic/*
add wave -hex /testbench/dut/uncore/uncore/plic/plic/intPriority
add wave -hex /testbench/dut/uncore/uncore/plic/plic/pendingArray
add wave -divider UART
add wave -hex /testbench/dut/uncore/uncore/uart/uart/u/*
add wave -divider GPIO
add wave -hex /testbench/dut/uncore/uncore/gpio/gpio/*
#add wave -divider
#add wave -hex /testbench/dut/core/ebu/ebu/*
#add wave -divider
#add wave -divider

# everything else
add wave -hex -r /testbench/*
