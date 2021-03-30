# Copyright 1991-2007 Mentor Graphics Corporation
# 
# Modification by Oklahoma State University
# Use with Testbench 
# James Stine, 2008
# Go Cowboys!!!!!!
#
# All Rights Reserved.
#
# THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION
# WHICH IS THE PROPERTY OF MENTOR GRAPHICS CORPORATION
# OR ITS LICENSORS AND IS SUBJECT TO LICENSE TERMS.

# Use this run.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do run.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do run.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

# compile source files
vlog mux_div.sv shifters_div.sv divide4x64.sv test_int64div.sv

# start and run simulation
vsim -voptargs=+acc work.tb

view list
view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave -noupdate -divider -height 32 "Control Signals"
add wave -hex -color gold /tb/clk
add wave -hex -color #0080ff /tb/reset
add wave -hex -color #0080ff /tb/start
add wave -hex -color #0080ff /tb/done
add wave -hex -color #0080ff /tb/divdone
add wave -noupdate -divider -height 32 "Key Parts"
add wave -unsigned /tb/dut/NumIter
add wave -unsigned /tb/dut/RemShift
add wave -unsigned /tb/dut/Qd2
add wave -unsigned /tb/dut/Rd2
add wave -unsigned /tb/dut/rem0
add wave -unsigned /tb/dut/Q
add wave -unsigned /tb/dut/P
add wave -unsigned /tb/dut/shiftResult
add wave -noupdate -divider -height 32 "FSM"
add wave -hex /tb/dut/fsm1/CURRENT_STATE
add wave -hex /tb/dut/fsm1/NEXT_STATE
add wave -hex -color #0080ff /tb/dut/fsm1/start
add wave -hex -color #0080ff /tb/dut/fsm1/state0
add wave -hex -color #0080ff /tb/dut/fsm1/done
add wave -hex -color #0080ff /tb/dut/fsm1/en
add wave -hex -color #0080ff /tb/dut/fsm1/divdone
add wave -hex -color #0080ff /tb/dut/fsm1/reset
add wave -hex -color #0080ff /tb/dut/fsm1/otfzero
add wave -hex -color #0080ff /tb/dut/fsm1/LT
add wave -hex -color #0080ff /tb/dut/fsm1/EQ
add wave -hex -color gold /tb/dut/fsm1/clk
add wave -noupdate -divider -height 32 "Datapath"
add wave -hex /tb/dut/N
add wave -hex /tb/dut/D
add wave -hex /tb/dut/reset
add wave -hex /tb/dut/start
add wave -hex /tb/dut/Q
add wave -hex /tb/dut/rem0
add wave -hex /tb/dut/div0
add wave -hex /tb/dut/done
add wave -hex /tb/dut/divdone   
add wave -hex /tb/dut/enable
add wave -hex /tb/dut/state0
add wave -hex /tb/dut/V   
add wave -hex /tb/dut/Num
add wave -hex /tb/dut/P
add wave -hex /tb/dut/NumIter
add wave -hex /tb/dut/RemShift
add wave -hex /tb/dut/op1
add wave -hex /tb/dut/op2
add wave -hex /tb/dut/op1shift
add wave -hex /tb/dut/Rem5
add wave -hex /tb/dut/Qd
add wave -hex /tb/dut/Rd
add wave -hex /tb/dut/Qd2
add wave -hex /tb/dut/Rd2
add wave -hex /tb/dut/quotient
add wave -hex /tb/dut/otfzero   
add wave -noupdate -divider -height 32 "Divider"
add wave -hex -r /tb/dut/p3/*


-- Set Wave Output Items 
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {75 ns}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

-- Run the Simulation
run 338ns


