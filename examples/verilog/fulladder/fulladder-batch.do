# fulladder-batch.do 
# David_Harris@hmc.edu 10 January 2021
vlog fulladder.sv 
vopt +acc work.testbench -o workopt 
vsim workopt
run -all
quit