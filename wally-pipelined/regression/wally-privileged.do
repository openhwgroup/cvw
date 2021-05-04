# wally-pipelined.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Use this wally-pipelined.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-pipelined.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-pipelined.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

# default to config/rv64ic, but allow this to be overridden at the command line.  For example:
# do wally-pipelined.do ../config/rv32ic
switch $argc {
    0 {vlog +incdir+../config/rv64ic ../testbench/testbench-imperas.sv ../src/*/*.sv -suppress 2583}
    1 {vlog +incdir+$1 ../testbench/testbench-imperas.sv ../testbench/function_radix.sv ../src/*/*.sv -suppress 2583}
}
# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
vopt +acc work.testbench -o workopt 
vsim workopt

view wave
-- display input and output signals as hexidecimal values
onerror {resume}
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate -expand -group {Execution Stage} /testbench/dut/hart/ifu/PCE
quietly WaveActivateNextPane {} 0
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {12215488 ns} 0} {{Cursor 4} {22127 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 250
configure wave -valuecolwidth 513
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {21993 ns} {22181 ns}

-- Run the Simulation 
#run 5000 
run -all
#quit
noview ../testbench/testbench-imperas.sv
view wave
