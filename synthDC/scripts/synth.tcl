#
# OKSTATE Main Synopsys Flow
# Updated Sep 27, 2015 jes
#

# Config
set hdl_src "../../../pipelined/src"
set cfg "${hdl_src}/../config/rv32e/wally-config.vh"

eval file copy -force ${cfg} {hdl/}
eval file copy -force ${cfg} {reports/}
eval file copy -force [glob ${hdl_src}/../config/shared/*.vh] {hdl/}
eval file copy -force [glob ${hdl_src}/*/*.sv] {hdl/}
eval file copy -force [glob ${hdl_src}/*/flop/*.sv] {hdl/}

# Verilog files
set my_verilog_files [glob hdl/*]

# Set toplevel
set my_toplevel $::env(DESIGN)

# Set number of significant digits
set report_default_significant_digits 6

# V(HDL) Unconnectoed Pins Output
set verilogout_show_unconnected_pins "true"
set vhdlout_show_unconnected_pins "true"

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

# Set reset false path
set_false_path -from [get_ports reset_ext]

# Set Frequency in [MHz] or [ps]
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

# Partitioning - flatten or hierarchically synthesize
#ungroup -all -flatten -simple_names

# Set input pins except clock
set all_in_ex_clk [remove_from_collection [all_inputs] [get_ports $my_clk]]

# Specifies delays be propagated through the clock network
#set_propagated_clock [get_clocks $my_clk]

# Setting constraints on input ports 
set_driving_cell  -lib_cell scc9gena_dfxbp_1 -pin Q $all_in_ex_clk
#set_driving_cell  -lib_cell sky130_osu_sc_12T_ms__dff_1 -pin Q $all_in_ex_clk

# Set input/output delay
set_input_delay 0.0 -max -clock $my_clk $all_in_ex_clk
set_output_delay 0.0 -max -clock $my_clk [all_outputs]

# Setting load constraint on output ports 
set_load [expr [load_of scc9gena_tt_1.2v_25C/scc9gena_dfxbp_1/D] * 1] [all_outputs]
#set_load [expr [load_of sky130_osu_sc_12T_ms_TT_1P8_25C.ccs/sky130_osu_sc_12T_ms__dff_1/D] * 1] [all_outputs]

# Set the wire load model 
set_wire_load_mode "top"

# Attempt Area Recovery - if looking for minimal area
# set_max_area 2000

# Set fanout
set_max_fanout 6 $all_in_ex_clk

# Fix hold time violations
#set_fix_hold [all_clocks]

# Deal with constants and buffers to isolate ports
set_fix_multiple_port_nets -all -buffer_constants

# setting up the group paths to find out the required timings
#group_path -name OUTPUTS -to [all_outputs]
#group_path -name INPUTS -from [all_inputs] 
#group_path -name COMBO -from [all_inputs] -to [all_outputs]

# Save Unmapped Design
set filename [format "%s%s%s"  "unmapped/" $my_toplevel ".ddc"]
write_file -format ddc -hierarchy -o $filename

# Compile statements
compile_ultra -no_seq_output_inversion -no_boundary_optimization

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

set filename [format "%s%s%s" "reports/" $my_toplevel "_per_module_timing.rep"]
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through ifu ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ifu/*} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through ieu ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/*} -nworst 1 } 
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through lsu ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {lsu/*} -nworst 1 } 
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through ebu (ahblite) ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ebu/*} -nworst 1 } 
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through mdu ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/*} -nworst 1 } 
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through hzu ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {hzu/*} -nworst 1 } 
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through priv ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {priv/*} -nworst 1 } 
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through fpu ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/*} -nworst 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_mdu_timing.rep"]
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through entire mdu ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/*} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through multiply unit ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.mul/*} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through redundant multiplier ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.mul/bigmul/*} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through ProdM (mul output) ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.ProdM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through PP0E (mul partial product) ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.mul/PP0E} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through divide unit ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.div/*} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through QuotM (div output) ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.QuotM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through RemM (div output) ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.RemM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through div/WNextE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.div/WNextE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through div/XQNextE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.div/XQNextE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through div/DAbsBE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {mdu/genblk1.div/DAbsBE} -nworst 1 }

# set filename [format "%s%s%s" "reports/" $my_toplevel "_fpu_timing.rep"]
# redirect $filename { echo "\n\n\n//////////////// Critical paths through fma ////////////////\n\n\n" }
# redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.fma/*} -nworst 1 }
# redirect -append $filename { echo "\n\n\n//////////////// Critical paths through fpdiv ////////////////\n\n\n" }
# redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.fdivsqrt/*} -nworst 1 }
# redirect -append $filename { echo "\n\n\n//////////////// Critical paths through faddcvt ////////////////\n\n\n" }
# redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.faddcvt/*} -nworst 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_ifu_timing.rep"]
redirect -append $filename { echo "\n\n\n//////////////// Critical path through PCF ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ifu/PCF} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through PCNextF ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ifu/PCNextF} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through FinalInstrRawF ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ifu/FinalInstrRawF} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through InstrD ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ifu/decomp/InstrD} -nworst 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_stall_flush_timing.rep"]
redirect -append $filename { echo "\n\n\n//////////////// Critical path through StallD ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/StallD} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through StallE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/StallE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through StallM ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/StallM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through StallW ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/StallW} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through FlushD ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/FlushD} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through FlushE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/FlushE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through FlushM ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/FlushM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through FlushW ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/FlushW} -nworst 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_ieu_timing.rep"]
redirect -append $filename { echo "\n\n\n//////////////// Critical path through datapath/RD1D ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/RD1D} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through datapath/RD2D ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/RD2D} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through datapath/PreSrcAE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/PreSrcAE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through datapath/SrcAE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/SrcAE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through datapath/ALUResultE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/ALUResultE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through datapath/WriteDataE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/WriteDataE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through dataphath/ResultM ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/ResultM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through datapath/WriteDataW ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/WriteDataW} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical path through datapath/ReadDataM ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ieu/dp/ReadDataM} -nworst 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_fpu_timing.rep"]
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through fma ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.fma/*} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through fpdiv ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.fdivsqrt/*} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through faddcvt ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.faddcvt/*} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through FMAResM ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.FMAResM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through FDivResM ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.FDivResM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through FResE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.FResE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through fma/SumE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.fma/SumE} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through fma/ProdExpE ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {fpu/fpu.fma/ProdExpE} -nworst 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_mmu_timing.rep"]
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through immu/physicaladdress ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {ifu/immu/PhysicalAddress} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through dmmu/physicaladdress ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {lsu/dmmu/PhysicalAddress} -nworst 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_priv_timing.rep"]
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through priv/TrapM ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {priv/TrapM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through priv/CSRReadValM ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {priv/csr/CSRReadValM} -nworst 1 }
redirect -append $filename { echo "\n\n\n//////////////// Critical paths through priv/CSRReadValW ////////////////\n\n\n" }
redirect -append $filename { report_timing -capacitance -transition_time -nets -through {priv/CSRReadValW} -nworst 1 }


set filename [format "%s%s%s" "reports/" $my_toplevel "_min_timing.rep"]
redirect $filename { report_timing -delay min }

set filename [format "%s%s%s" "reports/" $my_toplevel "_area.rep"]
redirect $filename { report_area -hierarchy -nosplit -physical -designware}

set filename [format "%s%s%s" "reports/" $my_toplevel "_cell.rep"]
redirect $filename { report_cell [get_cells -hier *] }

set filename [format "%s%s%s" "reports/" $my_toplevel "_power.rep"]
redirect $filename { report_power -hierarchy -levels 1 }

set filename [format "%s%s%s" "reports/" $my_toplevel "_constraint.rep"]
redirect $filename { report_constraint }

set filename [format "%s%s%s" "reports/" $my_toplevel "_hier.rep"]
redirect $filename { report_hierarchy }

#Quit
#quit # *** commented out so we can stay in the synopsis terminal after synthesis is done.
