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
#add wave -hex -r /testbench_debug/*
add wave -hex -color gold /testbench_debug/clk
add wave -hex -color gold /testbench_debug/tck
add wave -hex -color gold /testbench_debug/dtm/tcks
add wave -hex -color blue /testbench_debug/r1q
add wave -hex -color blue /testbench_debug/r2q
add wave -color purple /testbench_debug/wave_marker
add wave -hex /testbench_debug/data
#add wave -hex /testbench_debug/trstn
#add wave -hex /testbench_debug/tdi
#add wave -hex /testbench_debug/tdo
#add wave -hex /testbench_debug/tms
add wave -hex /testbench_debug/ReqReady
add wave -hex /testbench_debug/ReqValid
add wave -hex /testbench_debug/ReqAddress
add wave -hex /testbench_debug/ReqData
add wave -hex /testbench_debug/ReqOP
add wave -hex /testbench_debug/RspReady
add wave -hex /testbench_debug/RspValid
add wave -hex /testbench_debug/RspData
add wave -hex /testbench_debug/RspOP
add wave -noupdate -divider -height 32 "Abstract Commands"
add wave -hex /testbench_debug/dm/AcState
add wave -hex /testbench_debug/dm/Busy
add wave -hex /testbench_debug/dm/Cycle
add wave -hex /testbench_debug/dm/ScanReg
add wave -hex /testbench_debug/dm/AcWrite
add wave -hex /testbench_debug/dm/AcTransfer
add wave -hex /testbench_debug/dm/Data0
add wave -hex /testbench_debug/dm/Data1
add wave -hex /testbench_debug/dm/Data2
add wave -hex /testbench_debug/dm/Data3
add wave -noupdate -divider -height 32 "DM"
add wave -hex /testbench_debug/dm/State
add wave -hex /testbench_debug/dm/*
add wave -noupdate -divider -height 32 "DTM"
add wave -hex /testbench_debug/dtm/*
add wave -noupdate -divider -height 32 "JTAG"
add wave -hex /testbench_debug/dtm/jtag/tap/State
add wave -hex /testbench_debug/dtm/jtag/*
#add wave -noupdate -divider -height 32 "TAP"
#add wave -hex /testbench_debug/dtm/jtag/tap/*
#add wave -noupdate -divider -height 32 "ID Reg"
#add wave -hex /testbench_debug/dtm/jtag/id/*


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
