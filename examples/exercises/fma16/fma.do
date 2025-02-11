# fma.do 
#
# run with vsim -do "do fma.do"
# add -c before -do for batch simulation

onbreak {resume}

# create library
vlib worklib

vlog -lint -sv -work worklib fma16.sv testbench.sv
vopt +acc worklib.testbench_fma16 -work worklib -o testbenchopt
vsim -lib worklib testbenchopt

add wave sim:/testbench_fma16/clk
add wave sim:/testbench_fma16/reset
add wave sim:/testbench_fma16/x
add wave sim:/testbench_fma16/y
add wave sim:/testbench_fma16/z
add wave sim:/testbench_fma16/result
add wave sim:/testbench_fma16/rexpected

run -all
