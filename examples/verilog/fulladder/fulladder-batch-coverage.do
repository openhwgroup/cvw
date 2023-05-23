# fulladder-batch-coverage.do 
# David_Harris@hmc.edu 22 May 2023
vlog fulladder.sv 
vopt +acc work.testbench -o workopt +cover=sbecf
vsim workopt -coverage
run -all
coverage save -instance /testbench/dut fulladder.ucdb
quit