# qrun.do
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# Usage: do wally-pipelined-batch.do <config> <testcases>
# Example: do wally-pipelined-batch.do rv32 imperas-32i

# Use this wally-pipelined-batch.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-pipelined-batch.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-pipelined-batch.do -c
# (omit the "-c" to see the GUI while running from the shell)

qrun -clean
qrun +incdir+../config/rv32ic +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv -suppress 2583 -optimize -snapshot wally +notimingchecks +nospecify
qrun -simulate -snapshot wally
qrun -simulate -snapshot wally

