# fulladder.do 
# David_Harris@hmc.edu 10 January 2021

# compile, optimize, and start the simulation
vlog fulladder.sv 
vopt +acc work.testbench -o workopt 
vsim workopt

# Add waveforms and run the simulation
add wave *
run -all
view wave
