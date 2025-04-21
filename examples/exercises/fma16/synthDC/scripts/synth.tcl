#
# Synthesis Synopsys Flow
# james.stine@okstate.edu 27 Sep 2015
#

# start run clock
set t1 [clock seconds]

# Ignore unnecessary warnings:
# intraassignment delays for nonblocking assignments are ignored
suppress_message {VER-130} 
# statements in initial blocks are ignored
suppress_message {VER-281} 
suppress_message {VER-173} 
 # Unsupported system task '$warn'
suppress_message {VER-274}
# Disable Warning:  Little argument or return value checking implemented for system task or function '$readmemh'. (VER-209)
suppress_message {VER-209}

# Enable Multicore
set_host_options -max_cores $::env(MAXCORES)

# get outputDir and configDir from environment (Makefile)
set outputDir $::env(OUTPUTDIR)
set hdl_src ".."
set saifpower $::env(SAIFPOWER)
set maxopt $::env(MAXOPT)
set drive $::env(DRIVE)

eval file copy -force [glob ${hdl_src}/fma16.sv] {$outputDir/hdl/}
eval file copy -force [glob ${hdl_src}/fma16wrapper.sv] {$outputDir/hdl/}

# Check if a wrapper is needed and create it (to pass parameters when cvw_t parameters are used)
set wrapper 0

# Enables name mapping
if { $saifpower == 1 } {
    saif_map -start
}

# Verilog files
set my_verilog_files [glob $outputDir/hdl/cvw.sv $outputDir/hdl/*.sv]

# Set toplevel
set my_toplevel fma16wrapper
set my_design $::env(DESIGN)

# Set number of significant digits
set report_default_significant_digits 6

# V(HDL) Unconnectoed Pins Output
set verilogout_show_unconnected_pins "true"
set vhdlout_show_unconnected_pins "true"

#  Set up MW List
set MY_LIB_NAME $my_toplevel
# Create MW
if { [shell_is_in_topographical_mode] } {
    echo "In Topographical Mode...processing\n"
    create_mw_lib  -technology $MW_REFERENCE_LIBRARY/$MW_TECH_FILE.tf \
        -mw_reference_library $mw_reference_library $outputDir/$MY_LIB_NAME
    # Open MW
    open_mw_lib $outputDir/$MY_LIB_NAME
    
    # TLU+
    set_tlu_plus_files -max_tluplus $MAX_TLU_FILE -min_tluplus $MIN_TLU_FILE \
	-tech2itf_map $PRS_MAP_FILE

} else {
    echo "In normal DC mode...processing\n"
}

# Due to parameterized Verilog must use analyze/elaborate and not 
# read_verilog/vhdl (change to pull in Verilog and/or VHDL)
#
#set alib_library_analysis_path ./$outputDir
define_design_lib WORK -path ./$outputDir/WORK
analyze -f sverilog -lib WORK $my_verilog_files
elaborate $my_toplevel -lib WORK 

# Set the current_design 
current_design $my_toplevel
link

# Reset all constraints 
reset_design

# Power Dissipation Analysis
######### OPTIONAL !!!!!!!!!!!!!!!!
if { $saifpower == 1 } {
    read_saif -input power.saif -instance_name testbench/dut/core -auto_map_names -verbose
}

# Set reset false path
if {$drive != "INV"} {
    set_false_path -from [get_ports reset]
}
# for PPA multiplexer synthesis
if {(($::env(DESIGN) == "ppa_mux2d_1") || ($::env(DESIGN) == "ppa_mux4d_1") || ($::env(DESIGN) == "ppa_mux8d_1"))} {
    set_false_path -from {s}
}

# Set Frequency in [MHz] or period in [ns]
set my_clock_pin clk
set my_uncertainty 0.0
set my_clk_freq_MHz $::env(FREQ)
set my_period [expr 1000.0 / $my_clk_freq_MHz]

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


# Optimize paths that are close to critical
set_critical_range 0.05 $current_design

# Partitioning - flatten or hierarchically synthesize
if { $maxopt == 1 } {
    ungroup -all -simple_names -flatten 
}

# Set input pins except clock
set all_in_ex_clk [remove_from_collection [all_inputs] [get_ports $my_clk]]

# Specifies delays be propagated through the clock network
# This is getting optimized poorly in the current flow, causing a lot of clock skew 
# and unrealistic bad timing results.
# set_propagated_clock [get_clocks $my_clk]

# Setting constraints on input ports 
if {$tech == "sky130"} {
    if {$drive == "INV"} {
	    set_driving_cell -lib_cell inv -pin Y $all_in_ex_clk
    } elseif {$drive == "FLOP"} {
	    set_driving_cell  -lib_cell sky130_osu_sc_12T_ms__dff_1 -pin Q $all_in_ex_clk
    }
} elseif {$tech == "sky90"} {
    if {$drive == "INV"} {
	    set_driving_cell -lib_cell scc9gena_inv_1 -pin Y $all_in_ex_clk
    } elseif {$drive == "FLOP"} {
	    set_driving_cell  -lib_cell scc9gena_dfxbp_1 -pin Q $all_in_ex_clk
    }
} elseif {$tech == "tsmc28" || $tech=="tsmc28psyn"} {
    if {$drive == "INV"} {
	    set_driving_cell -lib_cell INVD1BWP30P140 -pin ZN $all_in_ex_clk
    } elseif {$drive == "FLOP"} {
        set_driving_cell -lib_cell DFQD1BWP30P140 -pin Q $all_in_ex_clk
    }
}

# Set input/output delay
if {$drive == "FLOP"} {
    set_input_delay 0.0 -max -clock $my_clk $all_in_ex_clk
    set_output_delay 0.0 -max -clock $my_clk [all_outputs]
} else {
    set_input_delay 0.0 -max -clock $my_clk $all_in_ex_clk
    set_output_delay 0.0 -max -clock $my_clk [all_outputs]
}

# Setting load constraint on output ports 
if {$tech == "sky130"} {
    if {$drive == "INV"} {
	    set_load [expr [load_of sky130_osu_sc_12T_ms_TT_1P8_25C.ccs/sky130_osu_sc_12T_ms__inv_4/A] * 1] [all_outputs]
    } elseif {$drive == "FLOP"} {
        set_load [expr [load_of sky130_osu_sc_12T_ms_TT_1P8_25C.ccs/sky130_osu_sc_12T_ms__dff_1/D] * 1] [all_outputs]
    }
 } elseif {$tech == "sky90"} {
    if {$drive == "INV"} {
	    set_load [expr [load_of scc9gena_tt_1.2v_25C/scc9gena_inv_4/A] * 1] [all_outputs]
    } elseif {$drive == "FLOP"} {
        set_load [expr [load_of scc9gena_tt_1.2v_25C/scc9gena_dfxbp_1/D] * 1] [all_outputs]
    }
} elseif {$tech == "tsmc28" || $tech == "tsmc28psyn"} {
    if {$drive == "INV"} {
	    set_load [expr [load_of tcbn28hpcplusbwp30p140tt0p9v25c/INVD4BWP30P140/I] * 1] [all_outputs]
    } elseif {$drive == "FLOP"} {
        set_load [expr [load_of tcbn28hpcplusbwp30p140tt0p9v25c/DFQD1BWP30P140/D] * 1] [all_outputs]
    }
}

if {$tech != "tsmc28psyn"} {
    # Set the wire load model 
    set_wire_load_mode "top"
}

# Set switching activities
# default activity factors are 1 for clocks, 0.1 for others
# static probability of 0.5 is used for leakage

# Attempt Area Recovery - if looking for minimal area
# set_max_area 2000

# Set fanout
set_max_fanout 6 $all_in_ex_clk

# Fix hold time violations (DH: this doesn't seem to be working right now)
#set_fix_hold [all_clocks]

# Deal with constants and buffers to isolate ports
set_fix_multiple_port_nets -all -buffer_constants

# setting up the group paths to find out the required timings
# group_path -name OUTPUTS -to [all_outputs]
# group_path -name INPUTS -from [all_inputs] 
# group_path -name COMBO -from [all_inputs] -to [all_outputs]

# Save Unmapped Design
# set filename [format "%s%s%s%s" $outputDir "/unmapped/" $my_toplevel ".ddc"]
# write_file -format ddc -hierarchy -o $filename

# Compile statements
if { $maxopt == 1 } {
    compile_ultra -retime
    optimize_registers
} else {
    compile_ultra -no_seq_output_inversion -no_boundary_optimization
}

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

# Report on DESIGN, not wrapper.  However, design has a suffix for the parameters.
if { $wrapper == 1 } {
    set designname [format "%s%s" $my_design "__*"]
    current_design $designname

    # recreate clock below wrapper level or reporting doesn't work properly
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
} 

# Report Constraint Violators
set filename [format "%s%s" $outputDir "/reports/constraint_all_violators.rpt"]
redirect $filename {report_constraint -all_violators}

# Check design
redirect $outputDir/reports/check_design.rpt { check_design }

# Report Final Netlist (Hierarchical)
set filename [format "%s%s%s%s" $outputDir "/mapped/" $my_design ".sv"]
write_file -f verilog -hierarchy -output $filename

set filename [format "%s%s%s%s" $outputDir "/mapped/" $my_design ".sdc"]
write_sdc $filename

set filename [format "%s%s%s%s" $outputDir  "/mapped/" $my_design ".ddc"]
write_file -format ddc -hierarchy -o $filename

set filename [format "%s%s%s%s" $outputDir "/mapped/" $my_design ".sdf"]
write_sdf $filename

# Write SPEF file in case need more precision power exploration for TSMC28psyn
if {$tech == "tsmc28psyn"} {
    set filename [format "%s%s%s%s" $outputDir "/mapped/" $my_toplevel ".spef"]
    redirect $filename { write_parasitics }
}

# QoR
set filename [format "%s%s"  $outputDir "/reports/qor.rep"]
redirect $filename { report_qor }

# Report Timing
set filename [format "%s%s" $outputDir "/reports/reportpath.rep"]
#redirect $filename { report_path_group }

set filename [format "%s%s" $outputDir  "/reports/timing.rep"]
redirect $filename { report_timing -capacitance -transition_time -nets -nworst 1 }

set filename [format "%s%s" $outputDir  "/reports/mindelay.rep"]
redirect $filename { report_timing -capacitance -transition_time -nets -delay_type min -nworst 1 }

#set filename [format "%s%s" $outputDir  "/reports/per_module_timing.rep"]
#redirect -append $filename { echo "\n\n\n//// Critical paths through Stall ////\n\n\n" }
#redirect -append $filename { report_timing -capacitance -transition_time -nets -through {Stall*} -nworst 1 }

set filename [format "%s%s" $outputDir  "/reports/area.rep"]
redirect $filename { report_area -hierarchy -nosplit -physical -designware}

set filename [format "%s%s" $outputDir  "/reports/power.rep"]
redirect $filename { report_power -hierarchy -levels 1 }

set filename [format "%s%s" $outputDir  "/reports/constraint.rep"]
redirect $filename { report_constraint }

set filename [format "%s%s" $outputDir  "/reports/hier.rep"]
# redirect $filename { report_hierarchy }

# end run clock and echo run time in minutes
set t2 [clock seconds]
set t [expr $t2 - $t1]
echo [expr $t/60]

quit 
