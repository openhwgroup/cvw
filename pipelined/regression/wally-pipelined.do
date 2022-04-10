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
if {$2 eq "buildroot" || $2 eq "buildroot-checkpoint"} {
    vlog -lint -work work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench-linux.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583
    # start and run simulation
    vopt +acc work_${1}_${2}.testbench -work work_${1}_${2} -G RISCV_DIR=$3 -G INSTR_LIMIT=$4 -G INSTR_WAVEON=$5 -G CHECKPOINT=$6 -o testbenchopt 
    vsim -lib work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3829

    #-- Run the Simulation
    run -all
    add log -recursive /*
    do linux-wave.do
    run -all

    exec ./slack-notifier/slack-notifier.py
    
} elseif {$2 eq "buildroot-no-trace"} {
    vlog -lint -work work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench-linux.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583
    # start and run simulation
    vopt +acc work_${1}_${2}.testbench -work work_${1}_${2} -G RISCV_DIR=$3 -G INSTR_LIMIT=470350800 -G INSTR_WAVEON=470350800 -G CHECKPOINT=470350800 -G NO_IE_MTIME_CHECKPOINT=1 -o testbenchopt 
    vsim -lib work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3829

    #-- Run the Simulation
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Don't forget to change DEBUG_LEVEL = 0."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"    
    run 100 ns
    force -deposit testbench/dut/core/priv/priv/csr/csri/IE_REGW 16'h2aa
    force -deposit testbench/dut/uncore/clint/clint/MTIMECMP 64'h1000
    run 1200 ms
    #add log -recursive /*
    #do linux-wave.do
    #run -all

    exec ./slack-notifier/slack-notifier.py
    
} else {
    vlog +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench.sv ../testbench/common/*.sv   ../src/*/*.sv ../src/*/*/*.sv -suppress 2583 -suppress 7063
    vopt +acc work.testbench -G TEST=$2 -G DEBUG=1 -o workopt 

    vsim workopt +nowarn3829

    view wave
    #-- display input and output signals as hexidecimal values
    #do ./wave-dos/peripheral-waves.do
    add log -recursive /*
    do wave.do

    # power add generates the logging necessary for saif generation.
    power add -r /dut/core/*
    #-- Run the Simulation 

    run -all
    power off -r /dut/core/*
    power report -all -bsaif power.saif
    noview ../testbench/testbench.sv
    view wave
}



#elseif {$2 eq "buildroot-no-trace""} {
#    vlog -lint -work work_${1}_${2} +incdir+../config/$1 +incdir+../config/shared ../testbench/testbench-linux.sv ../testbench/common/*.sv ../src/*/*.sv ../src/*/*/*.sv -suppress 2583
    # start and run simulation
#    vopt +acc work_${1}_${2}.testbench -work work_${1}_${2} -G RISCV_DIR=$3 -G INSTR_LIMIT=470350800 -G INSTR_WAVEON=470350800 -G CHECKPOINT=470350800 -G DEBUG_TRACE=0 -o testbenchopt 
#    vsim -lib work_${1}_${2} testbenchopt -suppress 8852,12070,3084,3829

    #-- Run the Simulation
#    run 100 ns
#    force -deposit testbench/dut/core/priv/priv/csr/csri/IE_REGW 16'h2aa
#    force -deposit testbench/dut/uncore/clint/clint/MTIMECMP 64'h1000
#    add log -recursive /*
#    do linux-wave.do
#    run -all

#    exec ./slack-notifier/slack-notifier.py
#} 
