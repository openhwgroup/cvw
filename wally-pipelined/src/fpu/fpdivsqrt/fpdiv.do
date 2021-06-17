# Copyright 1991-2016 Mentor Graphics Corporation
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
vlog adder_ip.sv bk15.v mult_R4_64_64_cs.v ldf128.v ldf64.v sbtm_a1.sv sbtm_a0.sv sbtm.sv sbtm_a4.sv sbtm_a5.sv sbtm3.sv fsm.v divconvDP.sv convert_inputs.sv exception.sv rounder.sv fpdiv.sv test_fpdiv.sv

# start and run simulation
vsim -voptargs=+acc work.tb

view wave

-- display input and output signals as hexidecimal values
# Diplays All Signals recursively
add wave -hex -color gold /tb/dut/clk
add wave -hex -color gold /tb/dut/mantissaA
add wave -hex -color gold /tb/dut/mantissaB
add wave -hex -color gold /tb/dut/op1
add wave -hex -color gold /tb/dut/op2
add wave -hex -color gold /tb/dut/AS_Result
add wave -hex -color gold /tb/dut/Flags
add wave -hex -color gold /tb/dut/Denorm
#add wave -noupdate -divider -height 32 "exponent"
#add wave -hex /tb/dut/exp1
#add wave -hex /tb/dut/exp2
#add wave -hex /tb/dut/expF
#add wave -hex /tb/dut/bias
#add wave -hex /tb/dut/exp_diff
#add wave -hex /tb/dut/exp_odd
#add wave -hex -r /tb/dut/explogic2/*
#add wave -hex -r /tb/dut/explogic1/*
add wave -noupdate -divider -height 32 "FSM"
add wave -hex /tb/dut/control/CURRENT_STATE
add wave -hex /tb/dut/control/NEXT_STATE
add wave -hex -color #0080ff /tb/dut/control/start
add wave -hex -color #0080ff /tb/dut/control/reset
add wave -hex -color #0080ff /tb/dut/control/op_type
add wave -hex -color #0080ff /tb/dut/control/load_rega
add wave -hex -color #0080ff /tb/dut/control/load_regb
add wave -hex -color #0080ff /tb/dut/control/load_regc
add wave -hex -color #0080ff /tb/dut/control/load_regr
add wave -hex -color #0080ff /tb/dut/control/load_regs
add wave -hex -color #0080ff /tb/dut/control/sel_muxa
add wave -hex -color #0080ff /tb/dut/control/sel_muxb
add wave -hex -color #0080ff /tb/dut/control/sel_muxr
add wave -hex -color #0080ff /tb/dut/control/done
add wave -noupdate -divider -height 32 "Convert"
add wave -hex -r /tb/dut/conv1/*
add wave -noupdate -divider -height 32 "Exceptions"
add wave -hex -r /tb/dut/exc1/*
add wave -noupdate -divider -height 32 "Rounder"
add wave -hex -r /tb/dut/round1/*
add wave -noupdate -divider -height 32 "Pipe State"
add wave -hex -r /tb/dut/goldy/Sum_pipe;
add wave -hex -r /tb/dut/goldy/Carry_pipe;
add wave -hex -r /tb/dut/goldy/muxr_pipe;   
add wave -hex -r /tb/dut/goldy/rega_pipe;
add wave -hex -r /tb/dut/goldy/regb_pipe;
add wave -hex -r /tb/dut/goldy/regc_pipe;
add wave -hex -r /tb/dut/goldy/regd_pipe;
add wave -hex -r /tb/dut/goldy/regs_pipe;
add wave -hex -r /tb/dut/goldy/regr_pipe;
add wave -hex -r /tb/dut/goldy/P_pipe;
add wave -hex -r /tb/dut/goldy/op_type_pipe;
add wave -hex -r /tb/dut/goldy/q_const_pipe;
add wave -hex -r /tb/dut/goldy/qm_const_pipe;
add wave -hex -r /tb/dut/goldy/qp_const_pipe;   
add wave -noupdate -divider -height 32 "Goldschmidt"
add wave -hex -r /tb/dut/goldy/*

-- Set Wave Output Items 
TreeUpdate [SetDefaultTree]
WaveRestoreZoom {0 ps} {75 ns}
configure wave -namecolwidth 350
configure wave -valuecolwidth 250
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

-- Run the Simulation 
run 20ns
quit
