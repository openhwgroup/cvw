# fma.do 
#
# run with vsim -do "do fma.do"
# add -c before -do for batch simulation

onbreak {resume}

# create library
vlib worklib

vlog -lint -work worklib fma16.sv testbench.sv
vopt +acc worklib.testbench -work worklib -o testbenchopt
vsim -lib worklib testbenchopt

add wave sim:/testbench/clk
add wave sim:/testbench/reset
add wave sim:/testbench/x
add wave sim:/testbench/y
add wave sim:/testbench/z
add wave sim:/testbench/result
add wave sim:/testbench/rexpected

run -all