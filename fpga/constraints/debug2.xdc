create_debug_core u_ila_0 ila

set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
startgroup 
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0 ]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0 ]
endgroup
connect_debug_port u_ila_0/clk [get_nets [list xlnx_ddr4_c0/inst/u_ddr4_infrastructure/addn_ui_clkout1 ]]
set_property port_width 64 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {wallypipelinedsoc/hart/lsu/dcache/HWDATA[0]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[1]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[2]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[3]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[4]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[5]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[6]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[7]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[8]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[9]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[10]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[11]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[12]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[13]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[14]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[15]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[16]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[17]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[18]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[19]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[20]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[21]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[22]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[23]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[24]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[25]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[26]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[27]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[28]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[29]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[30]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[31]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[32]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[33]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[34]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[35]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[36]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[37]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[38]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[39]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[40]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[41]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[42]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[43]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[44]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[45]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[46]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[47]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[48]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[49]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[50]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[51]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[52]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[53]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[54]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[55]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[56]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[57]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[58]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[59]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[60]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[61]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[62]} {wallypipelinedsoc/hart/lsu/dcache/HWDATA[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {wallypipelinedsoc/hart/lsu/dcache/HRDATA[0]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[1]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[2]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[3]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[4]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[5]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[6]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[7]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[8]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[9]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[10]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[11]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[12]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[13]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[14]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[15]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[16]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[17]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[18]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[19]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[20]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[21]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[22]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[23]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[24]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[25]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[26]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[27]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[28]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[29]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[30]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[31]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[32]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[33]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[34]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[35]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[36]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[37]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[38]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[39]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[40]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[41]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[42]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[43]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[44]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[45]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[46]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[47]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[48]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[49]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[50]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[51]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[52]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[53]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[54]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[55]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[56]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[57]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[58]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[59]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[60]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[61]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[62]} {wallypipelinedsoc/hart/lsu/dcache/HRDATA[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[0]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[1]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[2]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[3]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[4]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[5]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[6]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[7]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[8]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[9]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[10]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[11]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[12]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[13]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[14]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[15]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[16]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[17]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[18]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[19]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[20]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[21]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[22]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[23]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[24]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[25]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[26]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[27]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[28]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[29]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[30]} {wallypipelinedsoc/hart/lsu/dcache/AHBPAdr[31]} ]]
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {wallypipelinedsoc/hart/priv/trap/MIP_REGW[1]} {wallypipelinedsoc/hart/priv/trap/MIP_REGW[3]} {wallypipelinedsoc/hart/priv/trap/MIP_REGW[5]} {wallypipelinedsoc/hart/priv/trap/MIP_REGW[7]} {wallypipelinedsoc/hart/priv/trap/MIP_REGW[9]} {wallypipelinedsoc/hart/priv/trap/MIP_REGW[11]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[0]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[1]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[2]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[3]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[4]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[5]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[6]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[7]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[8]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[9]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[10]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[11]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[12]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[13]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[14]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[15]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[16]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[17]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[18]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[19]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[20]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[21]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[22]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[23]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[24]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[25]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[26]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[27]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[28]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[29]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[30]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[31]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[32]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[33]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[34]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[35]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[36]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[37]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[38]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[39]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[40]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[41]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[42]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[43]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[44]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[45]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[46]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[47]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[48]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[49]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[50]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[51]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[52]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[53]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[54]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[55]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[56]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[57]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[58]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[59]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[60]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[61]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[62]} {wallypipelinedsoc/hart/priv/csr/csrm/MCAUSE_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {wallypipelinedsoc/hart/ReadDataM[0]} {wallypipelinedsoc/hart/ReadDataM[1]} {wallypipelinedsoc/hart/ReadDataM[2]} {wallypipelinedsoc/hart/ReadDataM[3]} {wallypipelinedsoc/hart/ReadDataM[4]} {wallypipelinedsoc/hart/ReadDataM[5]} {wallypipelinedsoc/hart/ReadDataM[6]} {wallypipelinedsoc/hart/ReadDataM[7]} {wallypipelinedsoc/hart/ReadDataM[8]} {wallypipelinedsoc/hart/ReadDataM[9]} {wallypipelinedsoc/hart/ReadDataM[10]} {wallypipelinedsoc/hart/ReadDataM[11]} {wallypipelinedsoc/hart/ReadDataM[12]} {wallypipelinedsoc/hart/ReadDataM[13]} {wallypipelinedsoc/hart/ReadDataM[14]} {wallypipelinedsoc/hart/ReadDataM[15]} {wallypipelinedsoc/hart/ReadDataM[16]} {wallypipelinedsoc/hart/ReadDataM[17]} {wallypipelinedsoc/hart/ReadDataM[18]} {wallypipelinedsoc/hart/ReadDataM[19]} {wallypipelinedsoc/hart/ReadDataM[20]} {wallypipelinedsoc/hart/ReadDataM[21]} {wallypipelinedsoc/hart/ReadDataM[22]} {wallypipelinedsoc/hart/ReadDataM[23]} {wallypipelinedsoc/hart/ReadDataM[24]} {wallypipelinedsoc/hart/ReadDataM[25]} {wallypipelinedsoc/hart/ReadDataM[26]} {wallypipelinedsoc/hart/ReadDataM[27]} {wallypipelinedsoc/hart/ReadDataM[28]} {wallypipelinedsoc/hart/ReadDataM[29]} {wallypipelinedsoc/hart/ReadDataM[30]} {wallypipelinedsoc/hart/ReadDataM[31]} {wallypipelinedsoc/hart/ReadDataM[32]} {wallypipelinedsoc/hart/ReadDataM[33]} {wallypipelinedsoc/hart/ReadDataM[34]} {wallypipelinedsoc/hart/ReadDataM[35]} {wallypipelinedsoc/hart/ReadDataM[36]} {wallypipelinedsoc/hart/ReadDataM[37]} {wallypipelinedsoc/hart/ReadDataM[38]} {wallypipelinedsoc/hart/ReadDataM[39]} {wallypipelinedsoc/hart/ReadDataM[40]} {wallypipelinedsoc/hart/ReadDataM[41]} {wallypipelinedsoc/hart/ReadDataM[42]} {wallypipelinedsoc/hart/ReadDataM[43]} {wallypipelinedsoc/hart/ReadDataM[44]} {wallypipelinedsoc/hart/ReadDataM[45]} {wallypipelinedsoc/hart/ReadDataM[46]} {wallypipelinedsoc/hart/ReadDataM[47]} {wallypipelinedsoc/hart/ReadDataM[48]} {wallypipelinedsoc/hart/ReadDataM[49]} {wallypipelinedsoc/hart/ReadDataM[50]} {wallypipelinedsoc/hart/ReadDataM[51]} {wallypipelinedsoc/hart/ReadDataM[52]} {wallypipelinedsoc/hart/ReadDataM[53]} {wallypipelinedsoc/hart/ReadDataM[54]} {wallypipelinedsoc/hart/ReadDataM[55]} {wallypipelinedsoc/hart/ReadDataM[56]} {wallypipelinedsoc/hart/ReadDataM[57]} {wallypipelinedsoc/hart/ReadDataM[58]} {wallypipelinedsoc/hart/ReadDataM[59]} {wallypipelinedsoc/hart/ReadDataM[60]} {wallypipelinedsoc/hart/ReadDataM[61]} {wallypipelinedsoc/hart/ReadDataM[62]} {wallypipelinedsoc/hart/ReadDataM[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {wallypipelinedsoc/hart/WriteDataM[0]} {wallypipelinedsoc/hart/WriteDataM[1]} {wallypipelinedsoc/hart/WriteDataM[2]} {wallypipelinedsoc/hart/WriteDataM[3]} {wallypipelinedsoc/hart/WriteDataM[4]} {wallypipelinedsoc/hart/WriteDataM[5]} {wallypipelinedsoc/hart/WriteDataM[6]} {wallypipelinedsoc/hart/WriteDataM[7]} {wallypipelinedsoc/hart/WriteDataM[8]} {wallypipelinedsoc/hart/WriteDataM[9]} {wallypipelinedsoc/hart/WriteDataM[10]} {wallypipelinedsoc/hart/WriteDataM[11]} {wallypipelinedsoc/hart/WriteDataM[12]} {wallypipelinedsoc/hart/WriteDataM[13]} {wallypipelinedsoc/hart/WriteDataM[14]} {wallypipelinedsoc/hart/WriteDataM[15]} {wallypipelinedsoc/hart/WriteDataM[16]} {wallypipelinedsoc/hart/WriteDataM[17]} {wallypipelinedsoc/hart/WriteDataM[18]} {wallypipelinedsoc/hart/WriteDataM[19]} {wallypipelinedsoc/hart/WriteDataM[20]} {wallypipelinedsoc/hart/WriteDataM[21]} {wallypipelinedsoc/hart/WriteDataM[22]} {wallypipelinedsoc/hart/WriteDataM[23]} {wallypipelinedsoc/hart/WriteDataM[24]} {wallypipelinedsoc/hart/WriteDataM[25]} {wallypipelinedsoc/hart/WriteDataM[26]} {wallypipelinedsoc/hart/WriteDataM[27]} {wallypipelinedsoc/hart/WriteDataM[28]} {wallypipelinedsoc/hart/WriteDataM[29]} {wallypipelinedsoc/hart/WriteDataM[30]} {wallypipelinedsoc/hart/WriteDataM[31]} {wallypipelinedsoc/hart/WriteDataM[32]} {wallypipelinedsoc/hart/WriteDataM[33]} {wallypipelinedsoc/hart/WriteDataM[34]} {wallypipelinedsoc/hart/WriteDataM[35]} {wallypipelinedsoc/hart/WriteDataM[36]} {wallypipelinedsoc/hart/WriteDataM[37]} {wallypipelinedsoc/hart/WriteDataM[38]} {wallypipelinedsoc/hart/WriteDataM[39]} {wallypipelinedsoc/hart/WriteDataM[40]} {wallypipelinedsoc/hart/WriteDataM[41]} {wallypipelinedsoc/hart/WriteDataM[42]} {wallypipelinedsoc/hart/WriteDataM[43]} {wallypipelinedsoc/hart/WriteDataM[44]} {wallypipelinedsoc/hart/WriteDataM[45]} {wallypipelinedsoc/hart/WriteDataM[46]} {wallypipelinedsoc/hart/WriteDataM[47]} {wallypipelinedsoc/hart/WriteDataM[48]} {wallypipelinedsoc/hart/WriteDataM[49]} {wallypipelinedsoc/hart/WriteDataM[50]} {wallypipelinedsoc/hart/WriteDataM[51]} {wallypipelinedsoc/hart/WriteDataM[52]} {wallypipelinedsoc/hart/WriteDataM[53]} {wallypipelinedsoc/hart/WriteDataM[54]} {wallypipelinedsoc/hart/WriteDataM[55]} {wallypipelinedsoc/hart/WriteDataM[56]} {wallypipelinedsoc/hart/WriteDataM[57]} {wallypipelinedsoc/hart/WriteDataM[58]} {wallypipelinedsoc/hart/WriteDataM[59]} {wallypipelinedsoc/hart/WriteDataM[60]} {wallypipelinedsoc/hart/WriteDataM[61]} {wallypipelinedsoc/hart/WriteDataM[62]} {wallypipelinedsoc/hart/WriteDataM[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {wallypipelinedsoc/hart/PCM[0]} {wallypipelinedsoc/hart/PCM[1]} {wallypipelinedsoc/hart/PCM[2]} {wallypipelinedsoc/hart/PCM[3]} {wallypipelinedsoc/hart/PCM[4]} {wallypipelinedsoc/hart/PCM[5]} {wallypipelinedsoc/hart/PCM[6]} {wallypipelinedsoc/hart/PCM[7]} {wallypipelinedsoc/hart/PCM[8]} {wallypipelinedsoc/hart/PCM[9]} {wallypipelinedsoc/hart/PCM[10]} {wallypipelinedsoc/hart/PCM[11]} {wallypipelinedsoc/hart/PCM[12]} {wallypipelinedsoc/hart/PCM[13]} {wallypipelinedsoc/hart/PCM[14]} {wallypipelinedsoc/hart/PCM[15]} {wallypipelinedsoc/hart/PCM[16]} {wallypipelinedsoc/hart/PCM[17]} {wallypipelinedsoc/hart/PCM[18]} {wallypipelinedsoc/hart/PCM[19]} {wallypipelinedsoc/hart/PCM[20]} {wallypipelinedsoc/hart/PCM[21]} {wallypipelinedsoc/hart/PCM[22]} {wallypipelinedsoc/hart/PCM[23]} {wallypipelinedsoc/hart/PCM[24]} {wallypipelinedsoc/hart/PCM[25]} {wallypipelinedsoc/hart/PCM[26]} {wallypipelinedsoc/hart/PCM[27]} {wallypipelinedsoc/hart/PCM[28]} {wallypipelinedsoc/hart/PCM[29]} {wallypipelinedsoc/hart/PCM[30]} {wallypipelinedsoc/hart/PCM[31]} {wallypipelinedsoc/hart/PCM[32]} {wallypipelinedsoc/hart/PCM[33]} {wallypipelinedsoc/hart/PCM[34]} {wallypipelinedsoc/hart/PCM[35]} {wallypipelinedsoc/hart/PCM[36]} {wallypipelinedsoc/hart/PCM[37]} {wallypipelinedsoc/hart/PCM[38]} {wallypipelinedsoc/hart/PCM[39]} {wallypipelinedsoc/hart/PCM[40]} {wallypipelinedsoc/hart/PCM[41]} {wallypipelinedsoc/hart/PCM[42]} {wallypipelinedsoc/hart/PCM[43]} {wallypipelinedsoc/hart/PCM[44]} {wallypipelinedsoc/hart/PCM[45]} {wallypipelinedsoc/hart/PCM[46]} {wallypipelinedsoc/hart/PCM[47]} {wallypipelinedsoc/hart/PCM[48]} {wallypipelinedsoc/hart/PCM[49]} {wallypipelinedsoc/hart/PCM[50]} {wallypipelinedsoc/hart/PCM[51]} {wallypipelinedsoc/hart/PCM[52]} {wallypipelinedsoc/hart/PCM[53]} {wallypipelinedsoc/hart/PCM[54]} {wallypipelinedsoc/hart/PCM[55]} {wallypipelinedsoc/hart/PCM[56]} {wallypipelinedsoc/hart/PCM[57]} {wallypipelinedsoc/hart/PCM[58]} {wallypipelinedsoc/hart/PCM[59]} {wallypipelinedsoc/hart/PCM[60]} {wallypipelinedsoc/hart/PCM[61]} {wallypipelinedsoc/hart/PCM[62]} {wallypipelinedsoc/hart/PCM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {wallypipelinedsoc/hart/MemAdrM[0]} {wallypipelinedsoc/hart/MemAdrM[1]} {wallypipelinedsoc/hart/MemAdrM[2]} {wallypipelinedsoc/hart/MemAdrM[3]} {wallypipelinedsoc/hart/MemAdrM[4]} {wallypipelinedsoc/hart/MemAdrM[5]} {wallypipelinedsoc/hart/MemAdrM[6]} {wallypipelinedsoc/hart/MemAdrM[7]} {wallypipelinedsoc/hart/MemAdrM[8]} {wallypipelinedsoc/hart/MemAdrM[9]} {wallypipelinedsoc/hart/MemAdrM[10]} {wallypipelinedsoc/hart/MemAdrM[11]} {wallypipelinedsoc/hart/MemAdrM[12]} {wallypipelinedsoc/hart/MemAdrM[13]} {wallypipelinedsoc/hart/MemAdrM[14]} {wallypipelinedsoc/hart/MemAdrM[15]} {wallypipelinedsoc/hart/MemAdrM[16]} {wallypipelinedsoc/hart/MemAdrM[17]} {wallypipelinedsoc/hart/MemAdrM[18]} {wallypipelinedsoc/hart/MemAdrM[19]} {wallypipelinedsoc/hart/MemAdrM[20]} {wallypipelinedsoc/hart/MemAdrM[21]} {wallypipelinedsoc/hart/MemAdrM[22]} {wallypipelinedsoc/hart/MemAdrM[23]} {wallypipelinedsoc/hart/MemAdrM[24]} {wallypipelinedsoc/hart/MemAdrM[25]} {wallypipelinedsoc/hart/MemAdrM[26]} {wallypipelinedsoc/hart/MemAdrM[27]} {wallypipelinedsoc/hart/MemAdrM[28]} {wallypipelinedsoc/hart/MemAdrM[29]} {wallypipelinedsoc/hart/MemAdrM[30]} {wallypipelinedsoc/hart/MemAdrM[31]} {wallypipelinedsoc/hart/MemAdrM[32]} {wallypipelinedsoc/hart/MemAdrM[33]} {wallypipelinedsoc/hart/MemAdrM[34]} {wallypipelinedsoc/hart/MemAdrM[35]} {wallypipelinedsoc/hart/MemAdrM[36]} {wallypipelinedsoc/hart/MemAdrM[37]} {wallypipelinedsoc/hart/MemAdrM[38]} {wallypipelinedsoc/hart/MemAdrM[39]} {wallypipelinedsoc/hart/MemAdrM[40]} {wallypipelinedsoc/hart/MemAdrM[41]} {wallypipelinedsoc/hart/MemAdrM[42]} {wallypipelinedsoc/hart/MemAdrM[43]} {wallypipelinedsoc/hart/MemAdrM[44]} {wallypipelinedsoc/hart/MemAdrM[45]} {wallypipelinedsoc/hart/MemAdrM[46]} {wallypipelinedsoc/hart/MemAdrM[47]} {wallypipelinedsoc/hart/MemAdrM[48]} {wallypipelinedsoc/hart/MemAdrM[49]} {wallypipelinedsoc/hart/MemAdrM[50]} {wallypipelinedsoc/hart/MemAdrM[51]} {wallypipelinedsoc/hart/MemAdrM[52]} {wallypipelinedsoc/hart/MemAdrM[53]} {wallypipelinedsoc/hart/MemAdrM[54]} {wallypipelinedsoc/hart/MemAdrM[55]} {wallypipelinedsoc/hart/MemAdrM[56]} {wallypipelinedsoc/hart/MemAdrM[57]} {wallypipelinedsoc/hart/MemAdrM[58]} {wallypipelinedsoc/hart/MemAdrM[59]} {wallypipelinedsoc/hart/MemAdrM[60]} {wallypipelinedsoc/hart/MemAdrM[61]} {wallypipelinedsoc/hart/MemAdrM[62]} {wallypipelinedsoc/hart/MemAdrM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {wallypipelinedsoc/hart/InstrM[0]} {wallypipelinedsoc/hart/InstrM[1]} {wallypipelinedsoc/hart/InstrM[2]} {wallypipelinedsoc/hart/InstrM[3]} {wallypipelinedsoc/hart/InstrM[4]} {wallypipelinedsoc/hart/InstrM[5]} {wallypipelinedsoc/hart/InstrM[6]} {wallypipelinedsoc/hart/InstrM[7]} {wallypipelinedsoc/hart/InstrM[8]} {wallypipelinedsoc/hart/InstrM[9]} {wallypipelinedsoc/hart/InstrM[10]} {wallypipelinedsoc/hart/InstrM[11]} {wallypipelinedsoc/hart/InstrM[12]} {wallypipelinedsoc/hart/InstrM[13]} {wallypipelinedsoc/hart/InstrM[14]} {wallypipelinedsoc/hart/InstrM[15]} {wallypipelinedsoc/hart/InstrM[16]} {wallypipelinedsoc/hart/InstrM[17]} {wallypipelinedsoc/hart/InstrM[18]} {wallypipelinedsoc/hart/InstrM[19]} {wallypipelinedsoc/hart/InstrM[20]} {wallypipelinedsoc/hart/InstrM[21]} {wallypipelinedsoc/hart/InstrM[22]} {wallypipelinedsoc/hart/InstrM[23]} {wallypipelinedsoc/hart/InstrM[24]} {wallypipelinedsoc/hart/InstrM[25]} {wallypipelinedsoc/hart/InstrM[26]} {wallypipelinedsoc/hart/InstrM[27]} {wallypipelinedsoc/hart/InstrM[28]} {wallypipelinedsoc/hart/InstrM[29]} {wallypipelinedsoc/hart/InstrM[30]} {wallypipelinedsoc/hart/InstrM[31]} ]]
create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe10]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {wallypipelinedsoc/hart/MemRWM[0]} {wallypipelinedsoc/hart/MemRWM[1]} ]]
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe11]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {wallypipelinedsoc/hart/priv/csr/csrm/MIE_REGW[1]} {wallypipelinedsoc/hart/priv/csr/csrm/MIE_REGW[3]} {wallypipelinedsoc/hart/priv/csr/csrm/MIE_REGW[5]} {wallypipelinedsoc/hart/priv/csr/csrm/MIE_REGW[7]} {wallypipelinedsoc/hart/priv/csr/csrm/MIE_REGW[9]} {wallypipelinedsoc/hart/priv/csr/csrm/MIE_REGW[11]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe12]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[0]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[1]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[2]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[3]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[4]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[5]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[6]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[7]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[8]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[9]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[10]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[11]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[12]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[13]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[14]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[15]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[16]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[17]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[18]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[19]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[20]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[21]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[22]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[23]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[24]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[25]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[26]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[27]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[28]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[29]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[30]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[31]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[32]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[33]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[34]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[35]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[36]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[37]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[38]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[39]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[40]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[41]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[42]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[43]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[44]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[45]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[46]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[47]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[48]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[49]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[50]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[51]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[52]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[53]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[54]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[55]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[56]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[57]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[58]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[59]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[60]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[61]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[62]} {wallypipelinedsoc/hart/priv/csr/csrm/MEPC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe13]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {wallypipelinedsoc/hart/priv/csr/csrm/MIP_REGW[1]} {wallypipelinedsoc/hart/priv/csr/csrm/MIP_REGW[3]} {wallypipelinedsoc/hart/priv/csr/csrm/MIP_REGW[5]} {wallypipelinedsoc/hart/priv/csr/csrm/MIP_REGW[7]} {wallypipelinedsoc/hart/priv/csr/csrm/MIP_REGW[9]} {wallypipelinedsoc/hart/priv/csr/csrm/MIP_REGW[11]} ]]
create_debug_port u_ila_0 probe
set_property port_width 5 [get_debug_ports u_ila_0/probe14]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/r_curr_state[0]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/r_curr_state[1]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/r_curr_state[2]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/r_curr_state[3]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/r_curr_state[4]} ]]
create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe15]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/o_ERROR_CODE_Q[0]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/o_ERROR_CODE_Q[1]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/o_ERROR_CODE_Q[2]} ]]
create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe16]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_DAT_Q[0]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_DAT_Q[1]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_DAT_Q[2]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_DAT_Q[3]} ]]
create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe17]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[0]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[1]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[2]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[3]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[4]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[5]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[6]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[7]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[8]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[9]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[10]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[11]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[12]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[13]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[14]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[15]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[16]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[17]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[18]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[19]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[20]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[21]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[22]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[23]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[24]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[25]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[26]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[27]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[28]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[29]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[30]} {wallypipelinedsoc/hart/lsu/dcache/dcachefsm/CurrState[31]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe18]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[0]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[1]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[2]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[3]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[4]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[5]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[6]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[7]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[8]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[9]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[10]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[11]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[12]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[13]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[14]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[15]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[16]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[17]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[18]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[19]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[20]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[21]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[22]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[23]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[24]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[25]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[26]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[27]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[28]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[29]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[30]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[31]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[32]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[33]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[34]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[35]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[36]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[37]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[38]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[39]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[40]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[41]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[42]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[43]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[44]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[45]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[46]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[47]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[48]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[49]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[50]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[51]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[52]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[53]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[54]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[55]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[56]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[57]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[58]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[59]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[60]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[61]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[62]} {wallypipelinedsoc/hart/priv/csr/csrs/SEPC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe19]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[0]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[1]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[2]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[3]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[4]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[5]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[6]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[7]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[8]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[9]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[10]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[11]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[12]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[13]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[14]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[15]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[16]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[17]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[18]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[19]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[20]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[21]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[22]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[23]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[24]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[25]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[26]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[27]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[28]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[29]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[30]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[31]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[32]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[33]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[34]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[35]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[36]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[37]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[38]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[39]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[40]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[41]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[42]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[43]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[44]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[45]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[46]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[47]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[48]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[49]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[50]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[51]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[52]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[53]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[54]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[55]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[56]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[57]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[58]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[59]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[60]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[61]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[62]} {wallypipelinedsoc/hart/priv/csr/csrs/SCAUSE_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe20]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[0]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[1]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[2]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[3]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[4]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[5]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[6]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[7]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[8]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[9]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[10]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[11]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[12]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[13]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[14]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[15]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[16]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[17]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[18]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[19]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[20]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[21]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[22]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[23]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[24]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[25]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[26]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[27]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[28]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[29]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[30]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[31]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[32]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[33]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[34]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[35]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[36]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[37]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[38]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[39]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[40]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[41]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[42]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[43]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[44]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[45]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[46]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[47]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[48]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[49]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[50]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[51]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[52]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[53]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[54]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[55]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[56]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[57]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[58]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[59]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[60]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[61]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[62]} {wallypipelinedsoc/hart/priv/trap/SEPC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe21]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {wallypipelinedsoc/hart/priv/trap/SIP_REGW[1]} {wallypipelinedsoc/hart/priv/trap/SIP_REGW[5]} {wallypipelinedsoc/hart/priv/trap/SIP_REGW[9]} ]]
create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe22]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {wallypipelinedsoc/hart/priv/trap/SIE_REGW[1]} {wallypipelinedsoc/hart/priv/trap/SIE_REGW[5]} {wallypipelinedsoc/hart/priv/trap/SIE_REGW[9]} ]]
create_debug_port u_ila_0 probe
set_property port_width 63 [get_debug_ports u_ila_0/probe23]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[0]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[2]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[3]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[4]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[5]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[6]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[7]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[8]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[9]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[10]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[11]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[12]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[13]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[14]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[15]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[16]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[17]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[18]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[19]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[20]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[21]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[22]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[23]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[24]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[25]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[26]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[27]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[28]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[29]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[30]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[31]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[32]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[33]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[34]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[35]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[36]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[37]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[38]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[39]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[40]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[41]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[42]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[43]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[44]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[45]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[46]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[47]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[48]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[49]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[50]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[51]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[52]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[53]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[54]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[55]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[56]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[57]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[58]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[59]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[60]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[61]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[62]} {wallypipelinedsoc/hart/priv/trap/STVEC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe24]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_clk_fsm/r_curr_state[0]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_clk_fsm/r_curr_state[1]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_clk_fsm/r_curr_state[2]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_clk_fsm/r_curr_state[3]} ]]
create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe25]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list {wallypipelinedsoc/uncore/sdc.SDC/sd_top/i_SD_DAT[0]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/i_SD_DAT[1]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/i_SD_DAT[2]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/i_SD_DAT[3]} ]]
create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe26]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {wallypipelinedsoc/hart/priv/trap/PendingIntsM[0]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[1]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[2]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[3]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[4]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[5]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[6]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[7]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[8]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[9]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[10]} {wallypipelinedsoc/hart/priv/trap/PendingIntsM[11]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe27]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[0]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[1]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[2]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[3]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[4]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[5]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[6]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[7]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[8]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[9]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[10]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[11]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[12]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[13]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[14]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[15]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[16]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[17]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[18]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[19]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[20]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[21]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[22]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[23]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[24]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[25]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[26]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[27]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[28]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[29]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[30]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[31]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[32]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[33]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[34]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[35]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[36]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[37]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[38]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[39]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[40]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[41]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[42]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[43]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[44]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[45]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[46]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[47]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[48]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[49]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[50]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[51]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[52]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[53]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[54]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[55]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[56]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[57]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[58]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[59]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[60]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[61]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[62]} {wallypipelinedsoc/hart/priv/trap/MEPC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe28]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list {wallypipelinedsoc/hart/priv/trap/MIE_REGW[1]} {wallypipelinedsoc/hart/priv/trap/MIE_REGW[3]} {wallypipelinedsoc/hart/priv/trap/MIE_REGW[5]} {wallypipelinedsoc/hart/priv/trap/MIE_REGW[7]} {wallypipelinedsoc/hart/priv/trap/MIE_REGW[9]} {wallypipelinedsoc/hart/priv/trap/MIE_REGW[11]} ]]
create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe29]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list {wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_IC_OUT[0]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_IC_OUT[1]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_IC_OUT[2]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_IC_OUT[3]} ]]
create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe30]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_dat_fsm/r_curr_state[0]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_dat_fsm/r_curr_state[1]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_dat_fsm/r_curr_state[2]} {wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_dat_fsm/r_curr_state[3]} ]]
create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe31]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list {wallypipelinedsoc/hart/lsu/dcache/DCtoAHBSizeM[0]} {wallypipelinedsoc/hart/lsu/dcache/DCtoAHBSizeM[1]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe32]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list wallypipelinedsoc/hart/lsu/dcache/AHBAck ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe33]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list wallypipelinedsoc/hart/lsu/dcache/AHBRead ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe34]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list wallypipelinedsoc/hart/lsu/dcache/AHBWrite ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe35]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list wallypipelinedsoc/hart/priv/trap/BreakpointFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe36]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list wallypipelinedsoc/uncore/uart.uart/DTRb ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe37]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list wallypipelinedsoc/hart/priv/trap/EcallFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe38]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe38]
connect_debug_port u_ila_0/probe38 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_dat_fsm/i_DAT0_Q ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe39]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe39]
connect_debug_port u_ila_0/probe39 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_dat_fsm/i_DATA_CRC16_GOOD ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe40]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe40]
connect_debug_port u_ila_0/probe40 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/i_ERROR_CRC16 ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe41]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe41]
connect_debug_port u_ila_0/probe41 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/i_ERROR_DAT_TIMES_OUT ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe42]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe42]
connect_debug_port u_ila_0/probe42 [get_nets [list wallypipelinedsoc/hart/priv/trap/IllegalInstrFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe43]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe43]
connect_debug_port u_ila_0/probe43 [get_nets [list wallypipelinedsoc/hart/priv/trap/InstrAccessFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe44]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe44]
connect_debug_port u_ila_0/probe44 [get_nets [list wallypipelinedsoc/hart/priv/trap/InstrPageFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe45]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe45]
connect_debug_port u_ila_0/probe45 [get_nets [list wallypipelinedsoc/hart/InstrValidM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe46]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe46]
connect_debug_port u_ila_0/probe46 [get_nets [list wallypipelinedsoc/uncore/uart.uart/INTR ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe47]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe47]
connect_debug_port u_ila_0/probe47 [get_nets [list wallypipelinedsoc/hart/priv/trap/LoadAccessFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe48]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe48]
connect_debug_port u_ila_0/probe48 [get_nets [list wallypipelinedsoc/hart/priv/trap/LoadMisalignedFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe49]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe49]
connect_debug_port u_ila_0/probe49 [get_nets [list wallypipelinedsoc/hart/priv/trap/LoadPageFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe50]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe50]
connect_debug_port u_ila_0/probe50 [get_nets [list wallypipelinedsoc/hart/priv/trap/mretM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe51]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe51]
connect_debug_port u_ila_0/probe51 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_clk_fsm/o_G_CLK_SD_EN ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe52]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe52]
connect_debug_port u_ila_0/probe52 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/o_SD_CLK ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe53]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe53]
connect_debug_port u_ila_0/probe53 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/o_SD_CMD ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe54]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe54]
connect_debug_port u_ila_0/probe54 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/o_SD_CMD_OE ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe55]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe55]
connect_debug_port u_ila_0/probe55 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/my_sd_cmd_fsm/o_SD_CMD_OE ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe56]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe56]
connect_debug_port u_ila_0/probe56 [get_nets [list wallypipelinedsoc/uncore/uart.uart/OUT1b ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe57]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe57]
connect_debug_port u_ila_0/probe57 [get_nets [list wallypipelinedsoc/uncore/uart.uart/OUT2b ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe58]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe58]
connect_debug_port u_ila_0/probe58 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/r_DAT_ERROR_Q ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe59]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe59]
connect_debug_port u_ila_0/probe59 [get_nets [list wallypipelinedsoc/uncore/uart.uart/RTSb ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe60]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe60]
connect_debug_port u_ila_0/probe60 [get_nets [list wallypipelinedsoc/uncore/uart.uart/RXRDYb ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe61]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe61]
connect_debug_port u_ila_0/probe61 [get_nets [list wallypipelinedsoc/uncore/uart.uart/SIN ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe62]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe62]
connect_debug_port u_ila_0/probe62 [get_nets [list wallypipelinedsoc/uncore/uart.uart/SOUT ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe63]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe63]
connect_debug_port u_ila_0/probe63 [get_nets [list wallypipelinedsoc/hart/priv/trap/sretM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe64]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe64]
connect_debug_port u_ila_0/probe64 [get_nets [list wallypipelinedsoc/hart/priv/trap/StoreAccessFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe65]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe65]
connect_debug_port u_ila_0/probe65 [get_nets [list wallypipelinedsoc/hart/priv/trap/StoreMisalignedFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe66]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe66]
connect_debug_port u_ila_0/probe66 [get_nets [list wallypipelinedsoc/hart/priv/trap/StorePageFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe67]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe67]
connect_debug_port u_ila_0/probe67 [get_nets [list wallypipelinedsoc/hart/TrapM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe68]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe68]
connect_debug_port u_ila_0/probe68 [get_nets [list wallypipelinedsoc/uncore/uart.uart/TXRDYb ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe69]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe69]
connect_debug_port u_ila_0/probe69 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/w_IC_EN ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe70]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe70]
connect_debug_port u_ila_0/probe70 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/w_IC_RST ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe71]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe71]
connect_debug_port u_ila_0/probe71 [get_nets [list wallypipelinedsoc/uncore/sdc.SDC/sd_top/w_IC_UP_DOWN ]]


create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe72]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe72]
connect_debug_port u_ila_0/probe72 [get_nets [list wallypipelinedsoc/hart/hzu/BPPredWrongE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe73]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe73]
connect_debug_port u_ila_0/probe73 [get_nets [list wallypipelinedsoc/hart/hzu/CSRWritePendingDEM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe74]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe74]
connect_debug_port u_ila_0/probe74 [get_nets [list wallypipelinedsoc/hart/hzu/RetM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe75]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe75]
connect_debug_port u_ila_0/probe75 [get_nets [list wallypipelinedsoc/hart/hzu/TrapM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe76]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe76]
connect_debug_port u_ila_0/probe76 [get_nets [list wallypipelinedsoc/hart/hzu/LoadStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe77]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe77]
connect_debug_port u_ila_0/probe77 [get_nets [list wallypipelinedsoc/hart/hzu/StoreStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe78]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe78]
connect_debug_port u_ila_0/probe78 [get_nets [list wallypipelinedsoc/hart/hzu/MulDivStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe79]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe79]
connect_debug_port u_ila_0/probe79 [get_nets [list wallypipelinedsoc/hart/hzu/CSRRdStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe80]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe80]
connect_debug_port u_ila_0/probe80 [get_nets [list wallypipelinedsoc/hart/hzu/LSUStall ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe81]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe81]
connect_debug_port u_ila_0/probe81 [get_nets [list wallypipelinedsoc/hart/hzu/ICacheStallF ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe82]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe82]
connect_debug_port u_ila_0/probe82 [get_nets [list wallypipelinedsoc/hart/hzu/FPUStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe83]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe83]
connect_debug_port u_ila_0/probe83 [get_nets [list wallypipelinedsoc/hart/hzu/FStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe84]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe84]
connect_debug_port u_ila_0/probe84 [get_nets [list wallypipelinedsoc/hart/hzu/DivBusyE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe85]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe85]
connect_debug_port u_ila_0/probe85 [get_nets [list wallypipelinedsoc/hart/hzu/FDivBusyE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe86]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe86]
connect_debug_port u_ila_0/probe86 [get_nets [list wallypipelinedsoc/hart/hzu/EcallFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe87]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe87]
connect_debug_port u_ila_0/probe87 [get_nets [list wallypipelinedsoc/hart/hzu/BreakpointFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe88]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe88]
connect_debug_port u_ila_0/probe88 [get_nets [list wallypipelinedsoc/hart/hzu/InvalidateICacheM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe89]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe89]
connect_debug_port u_ila_0/probe89 [get_nets [list wallypipelinedsoc/hart/hzu/StallF ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe90]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe90]
connect_debug_port u_ila_0/probe90 [get_nets [list wallypipelinedsoc/hart/hzu/StallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe91]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe91]
connect_debug_port u_ila_0/probe91 [get_nets [list wallypipelinedsoc/hart/hzu/StallE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe92]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe92]
connect_debug_port u_ila_0/probe92 [get_nets [list wallypipelinedsoc/hart/hzu/StallM ]]

# StallW is StallM.  trying to connect to StallW causes issues.
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe93]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe93]
connect_debug_port u_ila_0/probe93 [get_nets [list wallypipelinedsoc/hart/hzu/StallM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe94]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe94]
connect_debug_port u_ila_0/probe94 [get_nets [list wallypipelinedsoc/hart/hzu/FlushF ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe95]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe95]
connect_debug_port u_ila_0/probe95 [get_nets [list wallypipelinedsoc/hart/hzu/FlushD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe96]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe96]
connect_debug_port u_ila_0/probe96 [get_nets [list wallypipelinedsoc/hart/hzu/FlushE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe97]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe97]
connect_debug_port u_ila_0/probe97 [get_nets [list wallypipelinedsoc/hart/hzu/FlushM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe98]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe98]
connect_debug_port u_ila_0/probe98 [get_nets [list wallypipelinedsoc/hart/hzu/FlushW ]]

create_debug_port u_ila_0 probe
set_property port_width 24 [get_debug_ports u_ila_0/probe99]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe99]
connect_debug_port u_ila_0/probe99 [get_nets [list {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[0]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[1]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[2]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[3]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[4]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[5]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[6]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[7]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[8]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[9]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[10]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[11]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[12]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[13]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[14]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[15]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[16]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[17]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[18]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[19]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[20]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[21]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[22]} {wallypipelinedsoc/hart/ifu/icache/controller/CurrState[23]}]]


create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe100]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe100]
connect_debug_port u_ila_0/probe100 [get_nets [list {wallypipelinedsoc/hart/ifu/icache/InstrInF[0]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[1]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[2]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[3]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[4]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[5]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[6]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[7]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[8]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[9]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[10]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[11]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[12]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[13]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[14]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[15]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[16]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[17]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[18]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[19]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[20]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[21]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[22]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[23]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[24]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[25]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[26]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[27]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[28]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[29]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[30]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[31]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[32]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[33]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[34]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[35]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[36]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[37]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[38]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[39]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[40]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[41]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[42]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[43]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[44]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[45]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[46]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[47]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[48]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[49]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[50]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[51]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[52]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[53]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[54]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[55]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[56]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[57]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[58]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[59]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[60]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[61]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[62]} {wallypipelinedsoc/hart/ifu/icache/InstrInF[63]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe101]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe101]
connect_debug_port u_ila_0/probe101 [get_nets [list wallypipelinedsoc/hart/ifu/icache/InstrAckF ]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe102]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe102]
connect_debug_port u_ila_0/probe102 [get_nets [list {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[0]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[1]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[2]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[3]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[4]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[5]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[6]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[7]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[8]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[9]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[10]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[11]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[12]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[13]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[14]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[15]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[16]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[17]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[18]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[19]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[20]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[21]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[22]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[23]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[24]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[25]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[26]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[27]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[28]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[29]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[30]} {wallypipelinedsoc/hart/ifu/icache/InstrPAdrF[31]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe103]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe103]
connect_debug_port u_ila_0/probe103 [get_nets [list wallypipelinedsoc/hart/ifu/icache/InstrReadF ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe104]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe104]
connect_debug_port u_ila_0/probe104 [get_nets [list {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[0]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[1]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[2]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[3]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[4]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[5]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[6]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[7]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[8]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[9]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[10]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[11]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[12]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[13]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[14]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[15]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[16]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[17]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[18]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[19]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[20]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[21]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[22]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[23]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[24]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[25]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[26]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[27]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[28]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[29]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[30]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[31]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[32]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[33]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[34]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[35]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[36]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[37]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[38]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[39]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[40]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[41]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[42]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[43]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[44]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[45]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[46]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[47]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[48]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[49]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[50]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[51]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[52]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[53]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[54]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[55]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[56]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[57]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[58]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[59]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[60]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[61]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[62]} {wallypipelinedsoc/hart/priv/csr/counters/INSTRET_REGW[63]}]]


create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe105]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe105]
connect_debug_port u_ila_0/probe105 [get_nets [list {wallypipelinedsoc/hart/ebu/HRDATA[0]} {wallypipelinedsoc/hart/ebu/HRDATA[1]} {wallypipelinedsoc/hart/ebu/HRDATA[2]} {wallypipelinedsoc/hart/ebu/HRDATA[3]} {wallypipelinedsoc/hart/ebu/HRDATA[4]} {wallypipelinedsoc/hart/ebu/HRDATA[5]} {wallypipelinedsoc/hart/ebu/HRDATA[6]} {wallypipelinedsoc/hart/ebu/HRDATA[7]} {wallypipelinedsoc/hart/ebu/HRDATA[8]} {wallypipelinedsoc/hart/ebu/HRDATA[9]} {wallypipelinedsoc/hart/ebu/HRDATA[10]} {wallypipelinedsoc/hart/ebu/HRDATA[11]} {wallypipelinedsoc/hart/ebu/HRDATA[12]} {wallypipelinedsoc/hart/ebu/HRDATA[13]} {wallypipelinedsoc/hart/ebu/HRDATA[14]} {wallypipelinedsoc/hart/ebu/HRDATA[15]} {wallypipelinedsoc/hart/ebu/HRDATA[16]} {wallypipelinedsoc/hart/ebu/HRDATA[17]} {wallypipelinedsoc/hart/ebu/HRDATA[18]} {wallypipelinedsoc/hart/ebu/HRDATA[19]} {wallypipelinedsoc/hart/ebu/HRDATA[20]} {wallypipelinedsoc/hart/ebu/HRDATA[21]} {wallypipelinedsoc/hart/ebu/HRDATA[22]} {wallypipelinedsoc/hart/ebu/HRDATA[23]} {wallypipelinedsoc/hart/ebu/HRDATA[24]} {wallypipelinedsoc/hart/ebu/HRDATA[25]} {wallypipelinedsoc/hart/ebu/HRDATA[26]} {wallypipelinedsoc/hart/ebu/HRDATA[27]} {wallypipelinedsoc/hart/ebu/HRDATA[28]} {wallypipelinedsoc/hart/ebu/HRDATA[29]} {wallypipelinedsoc/hart/ebu/HRDATA[30]} {wallypipelinedsoc/hart/ebu/HRDATA[31]}]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe106]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe106]
connect_debug_port u_ila_0/probe106 [get_nets [list {wallypipelinedsoc/hart/ebu/HWDATA[0]} {wallypipelinedsoc/hart/ebu/HWDATA[1]} {wallypipelinedsoc/hart/ebu/HWDATA[2]} {wallypipelinedsoc/hart/ebu/HWDATA[3]} {wallypipelinedsoc/hart/ebu/HWDATA[4]} {wallypipelinedsoc/hart/ebu/HWDATA[5]} {wallypipelinedsoc/hart/ebu/HWDATA[6]} {wallypipelinedsoc/hart/ebu/HWDATA[7]} {wallypipelinedsoc/hart/ebu/HWDATA[8]} {wallypipelinedsoc/hart/ebu/HWDATA[9]} {wallypipelinedsoc/hart/ebu/HWDATA[10]} {wallypipelinedsoc/hart/ebu/HWDATA[11]} {wallypipelinedsoc/hart/ebu/HWDATA[12]} {wallypipelinedsoc/hart/ebu/HWDATA[13]} {wallypipelinedsoc/hart/ebu/HWDATA[14]} {wallypipelinedsoc/hart/ebu/HWDATA[15]} {wallypipelinedsoc/hart/ebu/HWDATA[16]} {wallypipelinedsoc/hart/ebu/HWDATA[17]} {wallypipelinedsoc/hart/ebu/HWDATA[18]} {wallypipelinedsoc/hart/ebu/HWDATA[19]} {wallypipelinedsoc/hart/ebu/HWDATA[20]} {wallypipelinedsoc/hart/ebu/HWDATA[21]} {wallypipelinedsoc/hart/ebu/HWDATA[22]} {wallypipelinedsoc/hart/ebu/HWDATA[23]} {wallypipelinedsoc/hart/ebu/HWDATA[24]} {wallypipelinedsoc/hart/ebu/HWDATA[25]} {wallypipelinedsoc/hart/ebu/HWDATA[26]} {wallypipelinedsoc/hart/ebu/HWDATA[27]} {wallypipelinedsoc/hart/ebu/HWDATA[28]} {wallypipelinedsoc/hart/ebu/HWDATA[29]} {wallypipelinedsoc/hart/ebu/HWDATA[30]} {wallypipelinedsoc/hart/ebu/HWDATA[31]}]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe107]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe107]
connect_debug_port u_ila_0/probe107 [get_nets [list {wallypipelinedsoc/hart/ebu/HADDR[0]} {wallypipelinedsoc/hart/ebu/HADDR[1]} {wallypipelinedsoc/hart/ebu/HADDR[2]} {wallypipelinedsoc/hart/ebu/HADDR[3]} {wallypipelinedsoc/hart/ebu/HADDR[4]} {wallypipelinedsoc/hart/ebu/HADDR[5]} {wallypipelinedsoc/hart/ebu/HADDR[6]} {wallypipelinedsoc/hart/ebu/HADDR[7]} {wallypipelinedsoc/hart/ebu/HADDR[8]} {wallypipelinedsoc/hart/ebu/HADDR[9]} {wallypipelinedsoc/hart/ebu/HADDR[10]} {wallypipelinedsoc/hart/ebu/HADDR[11]} {wallypipelinedsoc/hart/ebu/HADDR[12]} {wallypipelinedsoc/hart/ebu/HADDR[13]} {wallypipelinedsoc/hart/ebu/HADDR[14]} {wallypipelinedsoc/hart/ebu/HADDR[15]} {wallypipelinedsoc/hart/ebu/HADDR[16]} {wallypipelinedsoc/hart/ebu/HADDR[17]} {wallypipelinedsoc/hart/ebu/HADDR[18]} {wallypipelinedsoc/hart/ebu/HADDR[19]} {wallypipelinedsoc/hart/ebu/HADDR[20]} {wallypipelinedsoc/hart/ebu/HADDR[21]} {wallypipelinedsoc/hart/ebu/HADDR[22]} {wallypipelinedsoc/hart/ebu/HADDR[23]} {wallypipelinedsoc/hart/ebu/HADDR[24]} {wallypipelinedsoc/hart/ebu/HADDR[25]} {wallypipelinedsoc/hart/ebu/HADDR[26]} {wallypipelinedsoc/hart/ebu/HADDR[27]} {wallypipelinedsoc/hart/ebu/HADDR[28]} {wallypipelinedsoc/hart/ebu/HADDR[29]} {wallypipelinedsoc/hart/ebu/HADDR[30]} {wallypipelinedsoc/hart/ebu/HADDR[31]}]]


create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe108]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe108]
connect_debug_port u_ila_0/probe108 [get_nets [list {wallypipelinedsoc/hart/ebu/HREADY}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe109]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe109]
connect_debug_port u_ila_0/probe109 [get_nets [list {wallypipelinedsoc/hart/ebu/HRESP}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe110]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe110]
connect_debug_port u_ila_0/probe110 [get_nets [list {wallypipelinedsoc/hart/ebu/HWRITE}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe111]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe111]
connect_debug_port u_ila_0/probe111 [get_nets [list {wallypipelinedsoc/hart/ebu/HSIZE[0]} {wallypipelinedsoc/hart/ebu/HSIZE[1]} {wallypipelinedsoc/hart/ebu/HSIZE[2]}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe112]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe112]
connect_debug_port u_ila_0/probe112 [get_nets [list {wallypipelinedsoc/hart/ebu/HBURST[0]} {wallypipelinedsoc/hart/ebu/HBURST[1]} {wallypipelinedsoc/hart/ebu/HBURST[2]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe113]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe113]
connect_debug_port u_ila_0/probe113 [get_nets [list {wallypipelinedsoc/hart/ebu/HPROT[0]} {wallypipelinedsoc/hart/ebu/HPROT[1]} {wallypipelinedsoc/hart/ebu/HPROT[2]} {wallypipelinedsoc/hart/ebu/HPROT[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe114]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe114]
connect_debug_port u_ila_0/probe114 [get_nets [list {wallypipelinedsoc/hart/ebu/HMASTLOCK}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe115]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe115]
connect_debug_port u_ila_0/probe115 [get_nets [list {wallypipelinedsoc/hart/priv/InterruptM}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe116]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe116]
connect_debug_port u_ila_0/probe116 [get_nets [list wallypipelinedsoc/hart/lsu/hptw/ITLBMissF]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe117]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe117]
connect_debug_port u_ila_0/probe117 [get_nets [list wallypipelinedsoc/hart/lsu/hptw/DTLBMissM]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe118]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe118]
connect_debug_port u_ila_0/probe118 [get_nets [list wallypipelinedsoc/hart/lsu/hptw/ITLBWriteF]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe119]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe119]
connect_debug_port u_ila_0/probe119 [get_nets [list wallypipelinedsoc/hart/lsu/hptw/DTLBWriteM]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe120]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe120]
connect_debug_port u_ila_0/probe120 [get_nets [list {wallypipelinedsoc/hart/lsu/hptw/WalkerState[0]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[1]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[2]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[3]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[4]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[5]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[6]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[7]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[8]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[9]} {wallypipelinedsoc/hart/lsu/hptw/WalkerState[10]}]]


create_debug_port u_ila_0 probe
set_property port_width 56 [get_debug_ports u_ila_0/probe121]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe121]
connect_debug_port u_ila_0/probe121 [get_nets [list {wallypipelinedsoc/hart/lsu/MemPAdrM[0]} {wallypipelinedsoc/hart/lsu/MemPAdrM[1]} {wallypipelinedsoc/hart/lsu/MemPAdrM[2]} {wallypipelinedsoc/hart/lsu/MemPAdrM[3]} {wallypipelinedsoc/hart/lsu/MemPAdrM[4]} {wallypipelinedsoc/hart/lsu/MemPAdrM[5]} {wallypipelinedsoc/hart/lsu/MemPAdrM[6]} {wallypipelinedsoc/hart/lsu/MemPAdrM[7]} {wallypipelinedsoc/hart/lsu/MemPAdrM[8]} {wallypipelinedsoc/hart/lsu/MemPAdrM[9]} {wallypipelinedsoc/hart/lsu/MemPAdrM[10]} {wallypipelinedsoc/hart/lsu/MemPAdrM[11]} {wallypipelinedsoc/hart/lsu/MemPAdrM[12]} {wallypipelinedsoc/hart/lsu/MemPAdrM[13]} {wallypipelinedsoc/hart/lsu/MemPAdrM[14]} {wallypipelinedsoc/hart/lsu/MemPAdrM[15]} {wallypipelinedsoc/hart/lsu/MemPAdrM[16]} {wallypipelinedsoc/hart/lsu/MemPAdrM[17]} {wallypipelinedsoc/hart/lsu/MemPAdrM[18]} {wallypipelinedsoc/hart/lsu/MemPAdrM[19]} {wallypipelinedsoc/hart/lsu/MemPAdrM[20]} {wallypipelinedsoc/hart/lsu/MemPAdrM[21]} {wallypipelinedsoc/hart/lsu/MemPAdrM[22]} {wallypipelinedsoc/hart/lsu/MemPAdrM[23]} {wallypipelinedsoc/hart/lsu/MemPAdrM[24]} {wallypipelinedsoc/hart/lsu/MemPAdrM[25]} {wallypipelinedsoc/hart/lsu/MemPAdrM[26]} {wallypipelinedsoc/hart/lsu/MemPAdrM[27]} {wallypipelinedsoc/hart/lsu/MemPAdrM[28]} {wallypipelinedsoc/hart/lsu/MemPAdrM[29]} {wallypipelinedsoc/hart/lsu/MemPAdrM[30]} {wallypipelinedsoc/hart/lsu/MemPAdrM[31]} {wallypipelinedsoc/hart/lsu/MemPAdrM[32]} {wallypipelinedsoc/hart/lsu/MemPAdrM[33]} {wallypipelinedsoc/hart/lsu/MemPAdrM[34]} {wallypipelinedsoc/hart/lsu/MemPAdrM[35]} {wallypipelinedsoc/hart/lsu/MemPAdrM[36]} {wallypipelinedsoc/hart/lsu/MemPAdrM[37]} {wallypipelinedsoc/hart/lsu/MemPAdrM[38]} {wallypipelinedsoc/hart/lsu/MemPAdrM[39]} {wallypipelinedsoc/hart/lsu/MemPAdrM[40]} {wallypipelinedsoc/hart/lsu/MemPAdrM[41]} {wallypipelinedsoc/hart/lsu/MemPAdrM[42]} {wallypipelinedsoc/hart/lsu/MemPAdrM[43]} {wallypipelinedsoc/hart/lsu/MemPAdrM[44]} {wallypipelinedsoc/hart/lsu/MemPAdrM[45]} {wallypipelinedsoc/hart/lsu/MemPAdrM[46]} {wallypipelinedsoc/hart/lsu/MemPAdrM[47]} {wallypipelinedsoc/hart/lsu/MemPAdrM[48]} {wallypipelinedsoc/hart/lsu/MemPAdrM[49]} {wallypipelinedsoc/hart/lsu/MemPAdrM[50]} {wallypipelinedsoc/hart/lsu/MemPAdrM[51]} {wallypipelinedsoc/hart/lsu/MemPAdrM[52]} {wallypipelinedsoc/hart/lsu/MemPAdrM[53]} {wallypipelinedsoc/hart/lsu/MemPAdrM[54]} {wallypipelinedsoc/hart/lsu/MemPAdrM[55]} ]]


create_debug_port u_ila_0 probe
set_property port_width 56 [get_debug_ports u_ila_0/probe122]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe122]
connect_debug_port u_ila_0/probe122 [get_nets [list {wallypipelinedsoc/hart/ifu/PCPFmmu[0]} {wallypipelinedsoc/hart/ifu/PCPFmmu[1]} {wallypipelinedsoc/hart/ifu/PCPFmmu[2]} {wallypipelinedsoc/hart/ifu/PCPFmmu[3]} {wallypipelinedsoc/hart/ifu/PCPFmmu[4]} {wallypipelinedsoc/hart/ifu/PCPFmmu[5]} {wallypipelinedsoc/hart/ifu/PCPFmmu[6]} {wallypipelinedsoc/hart/ifu/PCPFmmu[7]} {wallypipelinedsoc/hart/ifu/PCPFmmu[8]} {wallypipelinedsoc/hart/ifu/PCPFmmu[9]} {wallypipelinedsoc/hart/ifu/PCPFmmu[10]} {wallypipelinedsoc/hart/ifu/PCPFmmu[11]} {wallypipelinedsoc/hart/ifu/PCPFmmu[12]} {wallypipelinedsoc/hart/ifu/PCPFmmu[13]} {wallypipelinedsoc/hart/ifu/PCPFmmu[14]} {wallypipelinedsoc/hart/ifu/PCPFmmu[15]} {wallypipelinedsoc/hart/ifu/PCPFmmu[16]} {wallypipelinedsoc/hart/ifu/PCPFmmu[17]} {wallypipelinedsoc/hart/ifu/PCPFmmu[18]} {wallypipelinedsoc/hart/ifu/PCPFmmu[19]} {wallypipelinedsoc/hart/ifu/PCPFmmu[20]} {wallypipelinedsoc/hart/ifu/PCPFmmu[21]} {wallypipelinedsoc/hart/ifu/PCPFmmu[22]} {wallypipelinedsoc/hart/ifu/PCPFmmu[23]} {wallypipelinedsoc/hart/ifu/PCPFmmu[24]} {wallypipelinedsoc/hart/ifu/PCPFmmu[25]} {wallypipelinedsoc/hart/ifu/PCPFmmu[26]} {wallypipelinedsoc/hart/ifu/PCPFmmu[27]} {wallypipelinedsoc/hart/ifu/PCPFmmu[28]} {wallypipelinedsoc/hart/ifu/PCPFmmu[29]} {wallypipelinedsoc/hart/ifu/PCPFmmu[30]} {wallypipelinedsoc/hart/ifu/PCPFmmu[31]} {wallypipelinedsoc/hart/ifu/PCPFmmu[32]} {wallypipelinedsoc/hart/ifu/PCPFmmu[33]} {wallypipelinedsoc/hart/ifu/PCPFmmu[34]} {wallypipelinedsoc/hart/ifu/PCPFmmu[35]} {wallypipelinedsoc/hart/ifu/PCPFmmu[36]} {wallypipelinedsoc/hart/ifu/PCPFmmu[37]} {wallypipelinedsoc/hart/ifu/PCPFmmu[38]} {wallypipelinedsoc/hart/ifu/PCPFmmu[39]} {wallypipelinedsoc/hart/ifu/PCPFmmu[40]} {wallypipelinedsoc/hart/ifu/PCPFmmu[41]} {wallypipelinedsoc/hart/ifu/PCPFmmu[42]} {wallypipelinedsoc/hart/ifu/PCPFmmu[43]} {wallypipelinedsoc/hart/ifu/PCPFmmu[44]} {wallypipelinedsoc/hart/ifu/PCPFmmu[45]} {wallypipelinedsoc/hart/ifu/PCPFmmu[46]} {wallypipelinedsoc/hart/ifu/PCPFmmu[47]} {wallypipelinedsoc/hart/ifu/PCPFmmu[48]} {wallypipelinedsoc/hart/ifu/PCPFmmu[49]} {wallypipelinedsoc/hart/ifu/PCPFmmu[50]} {wallypipelinedsoc/hart/ifu/PCPFmmu[51]} {wallypipelinedsoc/hart/ifu/PCPFmmu[52]} {wallypipelinedsoc/hart/ifu/PCPFmmu[53]} {wallypipelinedsoc/hart/ifu/PCPFmmu[54]} {wallypipelinedsoc/hart/ifu/PCPFmmu[55]} ]]


