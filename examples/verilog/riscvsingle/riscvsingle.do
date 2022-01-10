# riscvsingle.do 
# David_Harris@hmc.edu 10 January 2021

# compile, optimize, and start the simulation
vlog riscvsingle.sv 
vopt +acc work.testbench -o workopt 
vsim workopt

# Add waveforms and run the simulation
add wave /testbench/clk
add wave /testbench/reset
add wave -divider "Main Datapath"
add wave /testbench/dut/PC
add wave /testbench/dut/Instr
add wave /testbench/dut/rvsingle/dp/SrcA
add wave /testbench/dut/rvsingle/dp/SrcB
add wave /testbench/dut/rvsingle/dp/Result
add wave -divider "Memory Bus"
add wave /testbench/MemWrite
add wave /testbench/DataAdr
add wave /testbench/WriteData
run -all
view wave
