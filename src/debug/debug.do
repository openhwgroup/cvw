# Use this run.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do run.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do run.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

set WALLY $::env(WALLY)
set CONFIG ${WALLY}/config
set SRC ${WALLY}/src
set TB ${WALLY}/testbench
set CFG rv64gc


# create library
if [file exists work] {
    vdel -lib work -all
}
vlib work

vlog -lint -work work +incdir+${CONFIG}/${CFG} +incdir+${CONFIG}/shared ${SRC}/cvw.sv  ${SRC}/*/*.sv ${SRC}/*/*/*.sv 
#-suppress 2583 -suppress 7063,2596,13286

# compile source files
#vlog tb_debug.sv dm.sv dtm.sv tap.sv ir.sv idreg.sv jtag.sv
#vlog dummy_reg.sv scan_reg.sv 
#vlog ../generic/flop/synchronizer.sv

# start and run simulation
vsim +nowarn3829 -error 3015 -voptargs=+acc -l transcript work.testbench

view list
view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
#add wave -hex -r /testbench/*
add wave -hex -color gold /testbench/clk
add wave -hex -color gold /testbench/tck
add wave -hex -color gold /testbench/dtm/tcks
add wave -hex -color blue /testbench/r1q
add wave -hex -color blue /testbench/r2q
add wave -color purple /testbench/wave_marker
add wave -hex /testbench/data
#add wave -hex /testbench/trstn
#add wave -hex /testbench/tdi
#add wave -hex /testbench/tdo
#add wave -hex /testbench/tms
add wave -hex /testbench/ReqReady
add wave -hex /testbench/ReqValid
add wave -hex /testbench/ReqAddress
add wave -hex /testbench/ReqData
add wave -hex /testbench/ReqOP
add wave -hex /testbench/RspReady
add wave -hex /testbench/RspValid
add wave -hex /testbench/RspData
add wave -hex /testbench/RspOP
add wave -noupdate -divider -height 32 "Abstract Commands"
add wave -hex /testbench/dm/AcState
add wave -hex /testbench/dm/Busy
add wave -hex /testbench/dm/Cycle
add wave -hex /testbench/dm/ScanReg
add wave -hex /testbench/dm/AcWrite
add wave -hex /testbench/dm/AcTransfer
add wave -hex /testbench/dm/Data0
add wave -hex /testbench/dm/Data1
add wave -hex /testbench/dm/Data2
add wave -hex /testbench/dm/Data3
add wave -noupdate -divider -height 32 "DM"
add wave -hex /testbench/dm/State
add wave -hex /testbench/dm/*
add wave -noupdate -divider -height 32 "DTM"
add wave -hex /testbench/dtm/*
add wave -noupdate -divider -height 32 "JTAG"
add wave -hex /testbench/dtm/jtag/tap/State
add wave -hex /testbench/dtm/jtag/*
#add wave -noupdate -divider -height 32 "TAP"
#add wave -hex /testbench/dtm/jtag/tap/*
#add wave -noupdate -divider -height 32 "ID Reg"
#add wave -hex /testbench/dtm/jtag/id/*


-- Set Wave Output Items 
#TreeUpdate [SetDefaultTree]
#WaveRestoreZoom {0 ps} {200 ns}
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

-- Run the Simulation
run 1000000 ns
