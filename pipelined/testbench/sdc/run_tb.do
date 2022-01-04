onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

vlog +incdir+../../../config/rv64ic +incdir+../../../config/shared ../../../testbench/common/*.sv ../../*/*.sv sd_top_tb.sv -suppress 2583

vopt -fsmdebug  +acc -gDEBUG=1 work.sd_top_tb -o workopt 
vsim workopt -fsmdebug

do wave.do
add log -r /*

run 3000 us
