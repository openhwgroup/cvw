# riscv-single.do 
#
# Simulate with vsim -do riscvsingle.do

# run with vsim -do "do wally-pipelined.do rv64ic riscvarchtest-64m"

#onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

vlog -lint riscvsingle.sv
vopt +acc work.testbench -o workopt 
vsim workopt

view wave
-- display input and output signals as hexadecimal values
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -divider "Main Datapath"
add wave -noupdate /testbench/dut/PC
add wave -noupdate /testbench/dut/Instr
add wave -noupdate /testbench/dut/rvsingle/dp/SrcA
add wave -noupdate /testbench/dut/rvsingle/dp/SrcB
add wave -noupdate /testbench/dut/rvsingle/dp/Result
add wave -divider "Memory Bus"
add wave -noupdate /testbench/MemWrite
add wave -noupdate /testbench/DataAdr
add wave -noupdate /testbench/WriteData
add wave -noupdate /testbench/dut/ReadData

-- Run the Simulation 
run -all
view wave
