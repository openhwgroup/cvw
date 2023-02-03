# wally-pipelined.do 
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

# run with vsim -do "do wally-pipelined.do rv64ic riscvarchtest-64m"

# Use this wally-pipelined.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do wally-pipelined.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do wally-pipelined.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

# compile source files
# suppress spurious warnngs about 
# "Extra checking for conflicts with always_comb done at vopt time"
# because vsim will run vopt

# start and run simulation
# remove +acc flag for faster sim during regressions if there is no need to access internal signals
        # *** modelsim won't take `PA_BITS, but will take other defines for the lengths of DTIM_RANGE and IROM_LEN.  For now just live with the warnings.
vlog +incdir+../config/$1 \
     +incdir+../config/shared \
     ../../external/ImperasDV-HMC/Imperas/ImpPublic/source/host/rvvi/rvvi-trace.sv \
     ../testbench/testbench_imperas.sv \
     ../testbench/common/*.sv   \
     ../src/*/*.sv \
     ../src/*/*/*.sv \
     -suppress 2583 \
     -suppress 7063 
vopt +acc work.testbench -G DEBUG=1 -o workopt 
vsim workopt +nowarn3829  -fatal 7 \
     +testDir=$env(TESTDIR) $env(OTHERFLAGS)
view wave
#-- display input and output signals as hexidecimal values
add log -recursive /*
do wave.do

run -all

noview ../testbench/testbench_imperas.sv
view wave
