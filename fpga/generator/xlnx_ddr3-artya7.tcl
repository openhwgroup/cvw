set partNumber  xc7a100tcsg324-1 
set boardName  arty-a7

set ipName xlnx_ddr3

create_project $ipName . -force -part $partNumber
#set_property board_part $boardName [current_project]

# really just these two lines which change
create_ip -name mig_7series -vendor xilinx.com -library ip -module_name $ipName

# to recreate one of these.
# 1. use the gui to generate a mig.
# 2. Find the xci file in project_1/project_1.srcs/sources_1/ip/mig_7series_0/
# 3. Run vivado in tcl mode and use command list_property [get_ips $ipName]
#    to find all parameters for this ip.
# 4. Then reconstruct the list with the needed parameters.
# turns out the ddr3 mig cannot be built this way like the ddr 4 mig?!?!?
# instead we need to read the project file, but we have to copy it to the corret location first
exec cp ../xlnx_ddr3-artya7-mig.prj xlnx_ddr3.srcs/sources_1/ip/xlnx_ddr3/

# unlike the vertex ultra scale and ultra scale + fpga's the atrix 7 mig we only get ui clock.

set_property -dict [list CONFIG.XML_INPUT_FILE {xlnx_ddr3-artya7-mig.prj}] [get_ips $ipName]

generate_target {instantiation_template} [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
