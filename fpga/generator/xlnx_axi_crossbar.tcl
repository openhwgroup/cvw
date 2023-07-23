set partNumber $::env(XILINX_PART)
set boardName $::env(XILINX_BOARD)

# vcu118 board
#set partNumber xcvu9p-flga2104-2L-e
#set boardName  xilinx.com:vcu118:part0:2.4

# kcu105 board
#set partNumber  xcku040-ffva1156-2-e
#set boardName  xilinx.com:kcu105:part0:1.7

set ipName xlnx_axi_crossbar

create_project $ipName . -force -part $partNumber
set_property board_part $boardName [current_project]

create_ip -name axi_crossbar -vendor xilinx.com -library ip -version 2.1 -module_name $ipName

set_property -dict [list CONFIG.NUM_SI {2} \
						CONFIG.DATA_WIDTH {64} \
						CONFIG.ID_WIDTH {4} \
						CONFIG.M01_S01_READ_CONNECTIVITY {0} \
						CONFIG.M01_S01_WRITE_CONNECTIVITY {0} \
						CONFIG.M00_A00_BASE_ADDR {0x0000000080000000} \
						CONFIG.M01_A00_BASE_ADDR {0x0000000000013000} \
                        CONFIG.M00_A00_ADDR_WIDTH {31}] [get_ips $ipName]

generate_target {instantiation_template} [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
