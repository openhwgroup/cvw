# wally.do 
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Modification by Oklahoma State University & Harvey Mudd College
# Use with Testbench 
# James Stine, 2008; David Harris 2021
# Go Cowboys!!!!!!
#
# Takes 1:10 to run RV64IC tests using gui

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
vlog +incdir+$env(WALLY)/config/$1 \
     +incdir+$env(WALLY)/config/deriv/$1 \
     +incdir+$env(WALLY)/config/shared \
     +define+USE_IMPERAS_DV \
     +define+IDV_INCLUDE_TRACE2COV \
     +incdir+$env(IMPERAS_HOME)/ImpPublic/include/host \
     +incdir+$env(IMPERAS_HOME)/ImpProprietary/include/host \
     $env(IMPERAS_HOME)/ImpPublic/source/host/rvvi/rvviApiPkg.sv    \
     $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/idvApiPkg.sv \
     $env(IMPERAS_HOME)/ImpPublic/source/host/rvvi/rvviTrace.sv      \
     $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/idvPkg.sv   \
     $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2bin.sv \
     $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2api.sv  \
     $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2log.sv  \
     \
     +define+INCLUDE_TRACE2COV +define+COVER_BASE_RV64I +define+COVER_LEVEL_DV_PR_EXT \
       +define+COVER_RV64I \
       +define+COVER_RV64M \
       +define+COVER_RV64A \
       +define+COVER_RV64F \
       +define+COVER_RV64D \
       +define+COVER_RV64ZICSR \
       +define+COVER_RV64C \
     +incdir+$env(IMPERAS_HOME)/ImpProprietary/source/host/riscvISACOV/source \
     $env(IMPERAS_HOME)/ImpProprietary/source/host/idv/trace2cov.sv  \
    \
     $env(WALLY)/src/cvw.sv \
     $env(WALLY)/testbench/testbench-imperas.sv \
     $env(WALLY)/testbench/common/*.sv   \
     $env(WALLY)/src/*/*.sv \
     $env(WALLY)/src/*/*/*.sv \
     -suppress 2583 \
     -suppress 7063  \
     +acc
vopt +acc work.testbench -G DEBUG=1 -o workopt 
eval vsim workopt +nowarn3829  -fatal 7 \
     -sv_lib $env(IMPERAS_HOME)/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model \
     +testDir=$env(TESTDIR) $env(OTHERFLAGS) +TRACE2COV_ENABLE=1

coverage save -onexit $env(WALLY)/sim/questa/riscv.ucdb


view wave
#-- display input and output signals as hexidecimal values
# add log -recursive /*
# do wave.do

run -all

noview $env(WALLY)/testbench/testbench-imperas.sv
view wave

quit -f
