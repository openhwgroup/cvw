# peripheral-waves.do 

restart -f
delete wave /*
view wave

# general stuff
add wave /testbench/clk
add wave /testbench/reset
add wave -divider

add wave /testbench/dut/hart/DataStall
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
add wave -hex /testbench/dut/hart/priv/csr/ProposedEPCM
add wave -hex /testbench/dut/hart/priv/csr/TrapM
add wave -hex /testbench/dut/hart/priv/csr/UnalignedNextEPCM
add wave -hex /testbench/dut/hart/priv/csr/genblk1/csrm/WriteMEPCM
add wave -hex /testbench/dut/hart/priv/csr/genblk1/csrm/MEPC_REGW
add wave -divider

# peripherals
add wave -hex /testbench/dut/uncore/plic/*
add wave -hex /testbench/dut/uncore/plic/intPriority
add wave -hex /testbench/dut/uncore/plic/pendingArray
add wave -divider
add wave -hex /testbench/dut/uncore/uart/u/*
add wave -divider
add wave -hex /testbench/dut/uncore/gpio/*
add wave -divider
add wave -hex /testbench/dut/hart/ebu/*
add wave -divider
add wave -divider

# everything else
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
