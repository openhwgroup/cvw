#
# Main Synopsys Flow
# james.stine@okstate.edu 26 Jan 2022
#

# Config
set hdl_src "../pipelined/src"

eval file copy ${hdl_src}/../config/rv32e/wally-config.vh {hdl/}
eval file copy ${hdl_src}/../config/rv32e/wally-config.vh {reports/}
eval file copy [glob ${hdl_src}/../config/shared/*.vh] {hdl/}
eval file copy [glob ${hdl_src}/*/*.sv] {hdl/}
eval file copy [glob ${hdl_src}/*/flop/*.sv] {hdl/}

# Verilog files
set my_verilog_files [glob hdl/*]

# Set toplevel
set my_toplevel wallypipelinedcore

# Set number of significant digits
set report_default_significant_digits 6

# V(HDL) Unconnectoed Pins Output
set verilogout_show_unconnected_pins "true"
set vhdlout_show_unconnected_pins "true"

#
# Due to parameterized Verilog must use analyze/elaborate and not 
# read_verilog/vhdl (change to pull in Verilog and/or VHDL)
#
define_design_lib WORK -path ./WORK
analyze -f sverilog -lib WORK $my_verilog_files

#
# Added if you had any VHDL
# analyze -f vhdl -lib WORK $my_vhdl_files
#
elaborate $my_toplevel -lib WORK 

# Set the current_design 
current_design $my_toplevel
link

# Reset all constraints 
reset_design

# Set Frequency in [MHz] or [ps]
set my_clock_pin clk
set my_clk_freq_MHz 10
set my_period [expr 1000 / $my_clk_freq_MHz]
set my_uncertainty [expr .1 * $my_period]

# Create clock object 
set find_clock [ find port [list $my_clock_pin] ]
if {  $find_clock != [list] } {
    echo "Found clock!"
    set my_clk $my_clock_pin
    create_clock -period $my_period $my_clk
    set_clock_uncertainty $my_uncertainty [get_clocks $my_clk]
} else {
    echo "Did not find clock! Design is probably combinational!"
    set my_clk vclk
    create_clock -period $my_period -name $my_clk
}

# Partitioning - flatten or hierarchically synthesize
#ungroup -flatten -simple_names { dp* }
#ungroup -flatten -simple_names { c* }
#ungroup -all -flatten -simple_names

# Set input pins except clock
set all_in_ex_clk [remove_from_collection [all_inputs] [get_ports $my_clk]]

# Specifies delays be propagated through the clock network
set_propagated_clock [get_clocks $my_clk]

# Setting constraints on input ports 
set_driving_cell  -lib_cell sky130_osu_sc_18T_ms__dff_1 -pin Q $all_in_ex_clk

# Set input/output delay
set_input_delay 0.0 -max -clock $my_clk $all_in_ex_clk
set_output_delay 0.0 -max -clock $my_clk [all_outputs]

# Setting load constraint on output ports 
set_load [expr [load_of sky130_osu_sc_18T_ms_TT_1P8_25C.ccs/sky130_osu_sc_18T_ms__dff_1/D] * 1] [all_outputs]

# Set the wire load model 
set_wire_load_mode "top"

# Attempt Area Recovery - if looking for minimal area
# set_max_area 2000

# Set fanout
set_max_fanout 6 $all_in_ex_clk

# Fix hold time violations
set_fix_hold [all_clocks]

# Deal with constants and buffers to isolate ports
set_fix_multiple_port_nets -all -buffer_constants

# setting up the group paths to find out the required timings
#group_path -name OUTPUTS -to [all_outputs]
#group_path -name INPUTS -from [all_inputs] 
#group_path -name COMBO -from [all_inputs] -to [all_outputs]

# Save Unmapped Design
set filename [format "%s%s%s"  "unmapped/" $my_toplevel ".ddc"]
write_file -format ddc -hierarchy -o $filename

# Compile statements - either compile or compile_ultra
# compile -scan -incr -map_effort low
# compile_ultra -no_seq_output_inversion -no_boundary_optimization

# Eliminate need for assign statements (yuck!)
set verilogout_no_tri true
set verilogout_equation false

# setting to generate output files
set write_v    1        ;# generates structual netlist
set write_sdc  1	;# generates synopsys design constraint file for p&r
set write_ddc  1	;# compiler file in ddc format
set write_sdf  1	;# sdf file for backannotated timing sim
set write_pow  1 	;# genrates estimated power report
set write_rep  1	;# generates estimated area and timing report
set write_cst  1        ;# generate report of constraints
set write_hier 1        ;# generate hierarchy report

# Report Constraint Violators
set filename [format "%s%s%s"  "reports/" $my_toplevel "_constraint_all_violators.rpt"]
redirect $filename {report_constraint -all_violators}

# Check design
redirect reports/check_design.rpt { check_design }

# Report Final Netlist (Hierarchical)
set filename [format "%s%s%s"  "mapped/" $my_toplevel ".vh"]
write_file -f verilog -hierarchy -output $filename

set filename [format "%s%s%s"  "mapped/" $my_toplevel ".sdc"]
write_sdc $filename

set filename [format "%s%s%s"  "mapped/" $my_toplevel ".ddc"]
write_file -format ddc -hierarchy -o $filename

set filename [format "%s%s%s"  "mapped/" $my_toplevel ".sdf"]
write_sdf $filename

# QoR
set filename [format "%s%s%s"  "reports/" $my_toplevel "_qor.rep"]
redirect $filename { report_qor }

# Report Timing
set filename [format "%s%s%s"  "reports/" $my_toplevel "_reportpath.rep"]
redirect $filename { report_path_group }

set filename [format "%s%s%s"  "reports/" $my_toplevel "_report_clock.rep"]
redirect $filename { report_clock }

set filename [format "%s%s%s" "reports/" $my_toplevel "_timing.rep"]
redirect $filename { report_timing -capacitance -transition_time -nets -nworst 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_min_timing.rep"]
redirect $filename { report_timing -delay min }

set filename [format "%s%s%s" "reports/" $my_toplevel "_area.rep"]
redirect $filename { report_area -hierarchy -nosplit -physical -designware}

set filename [format "%s%s%s" "reports/" $my_toplevel "_cell.rep"]
redirect $filename { report_cell [get_cells -hier *] }

set filename [format "%s%s%s" "reports/" $my_toplevel "_power.rep"]
redirect $filename { report_power }

set filename [format "%s%s%s" "reports/" $my_toplevel "_constraint.rep"]
redirect $filename { report_constraint }

set filename [format "%s%s%s" "reports/" $my_toplevel "_hier.rep"]
redirect $filename { report_hierarchy }

# Quit
quit

