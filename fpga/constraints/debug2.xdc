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
connect_debug_port u_ila_0/probe0 [get_nets [list {wallypipelinedsoc/core/lsu/LSUHWDATA[0]} {wallypipelinedsoc/core/lsu/LSUHWDATA[1]} {wallypipelinedsoc/core/lsu/LSUHWDATA[2]} {wallypipelinedsoc/core/lsu/LSUHWDATA[3]} {wallypipelinedsoc/core/lsu/LSUHWDATA[4]} {wallypipelinedsoc/core/lsu/LSUHWDATA[5]} {wallypipelinedsoc/core/lsu/LSUHWDATA[6]} {wallypipelinedsoc/core/lsu/LSUHWDATA[7]} {wallypipelinedsoc/core/lsu/LSUHWDATA[8]} {wallypipelinedsoc/core/lsu/LSUHWDATA[9]} {wallypipelinedsoc/core/lsu/LSUHWDATA[10]} {wallypipelinedsoc/core/lsu/LSUHWDATA[11]} {wallypipelinedsoc/core/lsu/LSUHWDATA[12]} {wallypipelinedsoc/core/lsu/LSUHWDATA[13]} {wallypipelinedsoc/core/lsu/LSUHWDATA[14]} {wallypipelinedsoc/core/lsu/LSUHWDATA[15]} {wallypipelinedsoc/core/lsu/LSUHWDATA[16]} {wallypipelinedsoc/core/lsu/LSUHWDATA[17]} {wallypipelinedsoc/core/lsu/LSUHWDATA[18]} {wallypipelinedsoc/core/lsu/LSUHWDATA[19]} {wallypipelinedsoc/core/lsu/LSUHWDATA[20]} {wallypipelinedsoc/core/lsu/LSUHWDATA[21]} {wallypipelinedsoc/core/lsu/LSUHWDATA[22]} {wallypipelinedsoc/core/lsu/LSUHWDATA[23]} {wallypipelinedsoc/core/lsu/LSUHWDATA[24]} {wallypipelinedsoc/core/lsu/LSUHWDATA[25]} {wallypipelinedsoc/core/lsu/LSUHWDATA[26]} {wallypipelinedsoc/core/lsu/LSUHWDATA[27]} {wallypipelinedsoc/core/lsu/LSUHWDATA[28]} {wallypipelinedsoc/core/lsu/LSUHWDATA[29]} {wallypipelinedsoc/core/lsu/LSUHWDATA[30]} {wallypipelinedsoc/core/lsu/LSUHWDATA[31]} {wallypipelinedsoc/core/lsu/LSUHWDATA[32]} {wallypipelinedsoc/core/lsu/LSUHWDATA[33]} {wallypipelinedsoc/core/lsu/LSUHWDATA[34]} {wallypipelinedsoc/core/lsu/LSUHWDATA[35]} {wallypipelinedsoc/core/lsu/LSUHWDATA[36]} {wallypipelinedsoc/core/lsu/LSUHWDATA[37]} {wallypipelinedsoc/core/lsu/LSUHWDATA[38]} {wallypipelinedsoc/core/lsu/LSUHWDATA[39]} {wallypipelinedsoc/core/lsu/LSUHWDATA[40]} {wallypipelinedsoc/core/lsu/LSUHWDATA[41]} {wallypipelinedsoc/core/lsu/LSUHWDATA[42]} {wallypipelinedsoc/core/lsu/LSUHWDATA[43]} {wallypipelinedsoc/core/lsu/LSUHWDATA[44]} {wallypipelinedsoc/core/lsu/LSUHWDATA[45]} {wallypipelinedsoc/core/lsu/LSUHWDATA[46]} {wallypipelinedsoc/core/lsu/LSUHWDATA[47]} {wallypipelinedsoc/core/lsu/LSUHWDATA[48]} {wallypipelinedsoc/core/lsu/LSUHWDATA[49]} {wallypipelinedsoc/core/lsu/LSUHWDATA[50]} {wallypipelinedsoc/core/lsu/LSUHWDATA[51]} {wallypipelinedsoc/core/lsu/LSUHWDATA[52]} {wallypipelinedsoc/core/lsu/LSUHWDATA[53]} {wallypipelinedsoc/core/lsu/LSUHWDATA[54]} {wallypipelinedsoc/core/lsu/LSUHWDATA[55]} {wallypipelinedsoc/core/lsu/LSUHWDATA[56]} {wallypipelinedsoc/core/lsu/LSUHWDATA[57]} {wallypipelinedsoc/core/lsu/LSUHWDATA[58]} {wallypipelinedsoc/core/lsu/LSUHWDATA[59]} {wallypipelinedsoc/core/lsu/LSUHWDATA[60]} {wallypipelinedsoc/core/lsu/LSUHWDATA[61]} {wallypipelinedsoc/core/lsu/LSUHWDATA[62]} {wallypipelinedsoc/core/lsu/LSUHWDATA[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {wallypipelinedsoc/core/HRDATA[0]} {wallypipelinedsoc/core/HRDATA[1]} {wallypipelinedsoc/core/HRDATA[2]} {wallypipelinedsoc/core/HRDATA[3]} {wallypipelinedsoc/core/HRDATA[4]} {wallypipelinedsoc/core/HRDATA[5]} {wallypipelinedsoc/core/HRDATA[6]} {wallypipelinedsoc/core/HRDATA[7]} {wallypipelinedsoc/core/HRDATA[8]} {wallypipelinedsoc/core/HRDATA[9]} {wallypipelinedsoc/core/HRDATA[10]} {wallypipelinedsoc/core/HRDATA[11]} {wallypipelinedsoc/core/HRDATA[12]} {wallypipelinedsoc/core/HRDATA[13]} {wallypipelinedsoc/core/HRDATA[14]} {wallypipelinedsoc/core/HRDATA[15]} {wallypipelinedsoc/core/HRDATA[16]} {wallypipelinedsoc/core/HRDATA[17]} {wallypipelinedsoc/core/HRDATA[18]} {wallypipelinedsoc/core/HRDATA[19]} {wallypipelinedsoc/core/HRDATA[20]} {wallypipelinedsoc/core/HRDATA[21]} {wallypipelinedsoc/core/HRDATA[22]} {wallypipelinedsoc/core/HRDATA[23]} {wallypipelinedsoc/core/HRDATA[24]} {wallypipelinedsoc/core/HRDATA[25]} {wallypipelinedsoc/core/HRDATA[26]} {wallypipelinedsoc/core/HRDATA[27]} {wallypipelinedsoc/core/HRDATA[28]} {wallypipelinedsoc/core/HRDATA[29]} {wallypipelinedsoc/core/HRDATA[30]} {wallypipelinedsoc/core/HRDATA[31]} {wallypipelinedsoc/core/HRDATA[32]} {wallypipelinedsoc/core/HRDATA[33]} {wallypipelinedsoc/core/HRDATA[34]} {wallypipelinedsoc/core/HRDATA[35]} {wallypipelinedsoc/core/HRDATA[36]} {wallypipelinedsoc/core/HRDATA[37]} {wallypipelinedsoc/core/HRDATA[38]} {wallypipelinedsoc/core/HRDATA[39]} {wallypipelinedsoc/core/HRDATA[40]} {wallypipelinedsoc/core/HRDATA[41]} {wallypipelinedsoc/core/HRDATA[42]} {wallypipelinedsoc/core/HRDATA[43]} {wallypipelinedsoc/core/HRDATA[44]} {wallypipelinedsoc/core/HRDATA[45]} {wallypipelinedsoc/core/HRDATA[46]} {wallypipelinedsoc/core/HRDATA[47]} {wallypipelinedsoc/core/HRDATA[48]} {wallypipelinedsoc/core/HRDATA[49]} {wallypipelinedsoc/core/HRDATA[50]} {wallypipelinedsoc/core/HRDATA[51]} {wallypipelinedsoc/core/HRDATA[52]} {wallypipelinedsoc/core/HRDATA[53]} {wallypipelinedsoc/core/HRDATA[54]} {wallypipelinedsoc/core/HRDATA[55]} {wallypipelinedsoc/core/HRDATA[56]} {wallypipelinedsoc/core/HRDATA[57]} {wallypipelinedsoc/core/HRDATA[58]} {wallypipelinedsoc/core/HRDATA[59]} {wallypipelinedsoc/core/HRDATA[60]} {wallypipelinedsoc/core/HRDATA[61]} {wallypipelinedsoc/core/HRDATA[62]} {wallypipelinedsoc/core/HRDATA[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {wallypipelinedsoc/core/lsu/LSUHADDR[0]} {wallypipelinedsoc/core/lsu/LSUHADDR[1]} {wallypipelinedsoc/core/lsu/LSUHADDR[2]} {wallypipelinedsoc/core/lsu/LSUHADDR[3]} {wallypipelinedsoc/core/lsu/LSUHADDR[4]} {wallypipelinedsoc/core/lsu/LSUHADDR[5]} {wallypipelinedsoc/core/lsu/LSUHADDR[6]} {wallypipelinedsoc/core/lsu/LSUHADDR[7]} {wallypipelinedsoc/core/lsu/LSUHADDR[8]} {wallypipelinedsoc/core/lsu/LSUHADDR[9]} {wallypipelinedsoc/core/lsu/LSUHADDR[10]} {wallypipelinedsoc/core/lsu/LSUHADDR[11]} {wallypipelinedsoc/core/lsu/LSUHADDR[12]} {wallypipelinedsoc/core/lsu/LSUHADDR[13]} {wallypipelinedsoc/core/lsu/LSUHADDR[14]} {wallypipelinedsoc/core/lsu/LSUHADDR[15]} {wallypipelinedsoc/core/lsu/LSUHADDR[16]} {wallypipelinedsoc/core/lsu/LSUHADDR[17]} {wallypipelinedsoc/core/lsu/LSUHADDR[18]} {wallypipelinedsoc/core/lsu/LSUHADDR[19]} {wallypipelinedsoc/core/lsu/LSUHADDR[20]} {wallypipelinedsoc/core/lsu/LSUHADDR[21]} {wallypipelinedsoc/core/lsu/LSUHADDR[22]} {wallypipelinedsoc/core/lsu/LSUHADDR[23]} {wallypipelinedsoc/core/lsu/LSUHADDR[24]} {wallypipelinedsoc/core/lsu/LSUHADDR[25]} {wallypipelinedsoc/core/lsu/LSUHADDR[26]} {wallypipelinedsoc/core/lsu/LSUHADDR[27]} {wallypipelinedsoc/core/lsu/LSUHADDR[28]} {wallypipelinedsoc/core/lsu/LSUHADDR[29]} {wallypipelinedsoc/core/lsu/LSUHADDR[30]} {wallypipelinedsoc/core/lsu/LSUHADDR[31]} ]]
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/MIP_REGW[1]} {wallypipelinedsoc/core/priv.priv/trap/MIP_REGW[3]} {wallypipelinedsoc/core/priv.priv/trap/MIP_REGW[5]} {wallypipelinedsoc/core/priv.priv/trap/MIP_REGW[7]} {wallypipelinedsoc/core/priv.priv/trap/MIP_REGW[9]} {wallypipelinedsoc/core/priv.priv/trap/MIP_REGW[11]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MCAUSE_REGW[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {wallypipelinedsoc/core/lsu/ReadDataM[0]} {wallypipelinedsoc/core/lsu/ReadDataM[1]} {wallypipelinedsoc/core/lsu/ReadDataM[2]} {wallypipelinedsoc/core/lsu/ReadDataM[3]} {wallypipelinedsoc/core/lsu/ReadDataM[4]} {wallypipelinedsoc/core/lsu/ReadDataM[5]} {wallypipelinedsoc/core/lsu/ReadDataM[6]} {wallypipelinedsoc/core/lsu/ReadDataM[7]} {wallypipelinedsoc/core/lsu/ReadDataM[8]} {wallypipelinedsoc/core/lsu/ReadDataM[9]} {wallypipelinedsoc/core/lsu/ReadDataM[10]} {wallypipelinedsoc/core/lsu/ReadDataM[11]} {wallypipelinedsoc/core/lsu/ReadDataM[12]} {wallypipelinedsoc/core/lsu/ReadDataM[13]} {wallypipelinedsoc/core/lsu/ReadDataM[14]} {wallypipelinedsoc/core/lsu/ReadDataM[15]} {wallypipelinedsoc/core/lsu/ReadDataM[16]} {wallypipelinedsoc/core/lsu/ReadDataM[17]} {wallypipelinedsoc/core/lsu/ReadDataM[18]} {wallypipelinedsoc/core/lsu/ReadDataM[19]} {wallypipelinedsoc/core/lsu/ReadDataM[20]} {wallypipelinedsoc/core/lsu/ReadDataM[21]} {wallypipelinedsoc/core/lsu/ReadDataM[22]} {wallypipelinedsoc/core/lsu/ReadDataM[23]} {wallypipelinedsoc/core/lsu/ReadDataM[24]} {wallypipelinedsoc/core/lsu/ReadDataM[25]} {wallypipelinedsoc/core/lsu/ReadDataM[26]} {wallypipelinedsoc/core/lsu/ReadDataM[27]} {wallypipelinedsoc/core/lsu/ReadDataM[28]} {wallypipelinedsoc/core/lsu/ReadDataM[29]} {wallypipelinedsoc/core/lsu/ReadDataM[30]} {wallypipelinedsoc/core/lsu/ReadDataM[31]} {wallypipelinedsoc/core/lsu/ReadDataM[32]} {wallypipelinedsoc/core/lsu/ReadDataM[33]} {wallypipelinedsoc/core/lsu/ReadDataM[34]} {wallypipelinedsoc/core/lsu/ReadDataM[35]} {wallypipelinedsoc/core/lsu/ReadDataM[36]} {wallypipelinedsoc/core/lsu/ReadDataM[37]} {wallypipelinedsoc/core/lsu/ReadDataM[38]} {wallypipelinedsoc/core/lsu/ReadDataM[39]} {wallypipelinedsoc/core/lsu/ReadDataM[40]} {wallypipelinedsoc/core/lsu/ReadDataM[41]} {wallypipelinedsoc/core/lsu/ReadDataM[42]} {wallypipelinedsoc/core/lsu/ReadDataM[43]} {wallypipelinedsoc/core/lsu/ReadDataM[44]} {wallypipelinedsoc/core/lsu/ReadDataM[45]} {wallypipelinedsoc/core/lsu/ReadDataM[46]} {wallypipelinedsoc/core/lsu/ReadDataM[47]} {wallypipelinedsoc/core/lsu/ReadDataM[48]} {wallypipelinedsoc/core/lsu/ReadDataM[49]} {wallypipelinedsoc/core/lsu/ReadDataM[50]} {wallypipelinedsoc/core/lsu/ReadDataM[51]} {wallypipelinedsoc/core/lsu/ReadDataM[52]} {wallypipelinedsoc/core/lsu/ReadDataM[53]} {wallypipelinedsoc/core/lsu/ReadDataM[54]} {wallypipelinedsoc/core/lsu/ReadDataM[55]} {wallypipelinedsoc/core/lsu/ReadDataM[56]} {wallypipelinedsoc/core/lsu/ReadDataM[57]} {wallypipelinedsoc/core/lsu/ReadDataM[58]} {wallypipelinedsoc/core/lsu/ReadDataM[59]} {wallypipelinedsoc/core/lsu/ReadDataM[60]} {wallypipelinedsoc/core/lsu/ReadDataM[61]} {wallypipelinedsoc/core/lsu/ReadDataM[62]} {wallypipelinedsoc/core/lsu/ReadDataM[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {wallypipelinedsoc/core/lsu/WriteDataM[0]} {wallypipelinedsoc/core/lsu/WriteDataM[1]} {wallypipelinedsoc/core/lsu/WriteDataM[2]} {wallypipelinedsoc/core/lsu/WriteDataM[3]} {wallypipelinedsoc/core/lsu/WriteDataM[4]} {wallypipelinedsoc/core/lsu/WriteDataM[5]} {wallypipelinedsoc/core/lsu/WriteDataM[6]} {wallypipelinedsoc/core/lsu/WriteDataM[7]} {wallypipelinedsoc/core/lsu/WriteDataM[8]} {wallypipelinedsoc/core/lsu/WriteDataM[9]} {wallypipelinedsoc/core/lsu/WriteDataM[10]} {wallypipelinedsoc/core/lsu/WriteDataM[11]} {wallypipelinedsoc/core/lsu/WriteDataM[12]} {wallypipelinedsoc/core/lsu/WriteDataM[13]} {wallypipelinedsoc/core/lsu/WriteDataM[14]} {wallypipelinedsoc/core/lsu/WriteDataM[15]} {wallypipelinedsoc/core/lsu/WriteDataM[16]} {wallypipelinedsoc/core/lsu/WriteDataM[17]} {wallypipelinedsoc/core/lsu/WriteDataM[18]} {wallypipelinedsoc/core/lsu/WriteDataM[19]} {wallypipelinedsoc/core/lsu/WriteDataM[20]} {wallypipelinedsoc/core/lsu/WriteDataM[21]} {wallypipelinedsoc/core/lsu/WriteDataM[22]} {wallypipelinedsoc/core/lsu/WriteDataM[23]} {wallypipelinedsoc/core/lsu/WriteDataM[24]} {wallypipelinedsoc/core/lsu/WriteDataM[25]} {wallypipelinedsoc/core/lsu/WriteDataM[26]} {wallypipelinedsoc/core/lsu/WriteDataM[27]} {wallypipelinedsoc/core/lsu/WriteDataM[28]} {wallypipelinedsoc/core/lsu/WriteDataM[29]} {wallypipelinedsoc/core/lsu/WriteDataM[30]} {wallypipelinedsoc/core/lsu/WriteDataM[31]} {wallypipelinedsoc/core/lsu/WriteDataM[32]} {wallypipelinedsoc/core/lsu/WriteDataM[33]} {wallypipelinedsoc/core/lsu/WriteDataM[34]} {wallypipelinedsoc/core/lsu/WriteDataM[35]} {wallypipelinedsoc/core/lsu/WriteDataM[36]} {wallypipelinedsoc/core/lsu/WriteDataM[37]} {wallypipelinedsoc/core/lsu/WriteDataM[38]} {wallypipelinedsoc/core/lsu/WriteDataM[39]} {wallypipelinedsoc/core/lsu/WriteDataM[40]} {wallypipelinedsoc/core/lsu/WriteDataM[41]} {wallypipelinedsoc/core/lsu/WriteDataM[42]} {wallypipelinedsoc/core/lsu/WriteDataM[43]} {wallypipelinedsoc/core/lsu/WriteDataM[44]} {wallypipelinedsoc/core/lsu/WriteDataM[45]} {wallypipelinedsoc/core/lsu/WriteDataM[46]} {wallypipelinedsoc/core/lsu/WriteDataM[47]} {wallypipelinedsoc/core/lsu/WriteDataM[48]} {wallypipelinedsoc/core/lsu/WriteDataM[49]} {wallypipelinedsoc/core/lsu/WriteDataM[50]} {wallypipelinedsoc/core/lsu/WriteDataM[51]} {wallypipelinedsoc/core/lsu/WriteDataM[52]} {wallypipelinedsoc/core/lsu/WriteDataM[53]} {wallypipelinedsoc/core/lsu/WriteDataM[54]} {wallypipelinedsoc/core/lsu/WriteDataM[55]} {wallypipelinedsoc/core/lsu/WriteDataM[56]} {wallypipelinedsoc/core/lsu/WriteDataM[57]} {wallypipelinedsoc/core/lsu/WriteDataM[58]} {wallypipelinedsoc/core/lsu/WriteDataM[59]} {wallypipelinedsoc/core/lsu/WriteDataM[60]} {wallypipelinedsoc/core/lsu/WriteDataM[61]} {wallypipelinedsoc/core/lsu/WriteDataM[62]} {wallypipelinedsoc/core/lsu/WriteDataM[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {wallypipelinedsoc/core/PCM[0]} {wallypipelinedsoc/core/PCM[1]} {wallypipelinedsoc/core/PCM[2]} {wallypipelinedsoc/core/PCM[3]} {wallypipelinedsoc/core/PCM[4]} {wallypipelinedsoc/core/PCM[5]} {wallypipelinedsoc/core/PCM[6]} {wallypipelinedsoc/core/PCM[7]} {wallypipelinedsoc/core/PCM[8]} {wallypipelinedsoc/core/PCM[9]} {wallypipelinedsoc/core/PCM[10]} {wallypipelinedsoc/core/PCM[11]} {wallypipelinedsoc/core/PCM[12]} {wallypipelinedsoc/core/PCM[13]} {wallypipelinedsoc/core/PCM[14]} {wallypipelinedsoc/core/PCM[15]} {wallypipelinedsoc/core/PCM[16]} {wallypipelinedsoc/core/PCM[17]} {wallypipelinedsoc/core/PCM[18]} {wallypipelinedsoc/core/PCM[19]} {wallypipelinedsoc/core/PCM[20]} {wallypipelinedsoc/core/PCM[21]} {wallypipelinedsoc/core/PCM[22]} {wallypipelinedsoc/core/PCM[23]} {wallypipelinedsoc/core/PCM[24]} {wallypipelinedsoc/core/PCM[25]} {wallypipelinedsoc/core/PCM[26]} {wallypipelinedsoc/core/PCM[27]} {wallypipelinedsoc/core/PCM[28]} {wallypipelinedsoc/core/PCM[29]} {wallypipelinedsoc/core/PCM[30]} {wallypipelinedsoc/core/PCM[31]} {wallypipelinedsoc/core/PCM[32]} {wallypipelinedsoc/core/PCM[33]} {wallypipelinedsoc/core/PCM[34]} {wallypipelinedsoc/core/PCM[35]} {wallypipelinedsoc/core/PCM[36]} {wallypipelinedsoc/core/PCM[37]} {wallypipelinedsoc/core/PCM[38]} {wallypipelinedsoc/core/PCM[39]} {wallypipelinedsoc/core/PCM[40]} {wallypipelinedsoc/core/PCM[41]} {wallypipelinedsoc/core/PCM[42]} {wallypipelinedsoc/core/PCM[43]} {wallypipelinedsoc/core/PCM[44]} {wallypipelinedsoc/core/PCM[45]} {wallypipelinedsoc/core/PCM[46]} {wallypipelinedsoc/core/PCM[47]} {wallypipelinedsoc/core/PCM[48]} {wallypipelinedsoc/core/PCM[49]} {wallypipelinedsoc/core/PCM[50]} {wallypipelinedsoc/core/PCM[51]} {wallypipelinedsoc/core/PCM[52]} {wallypipelinedsoc/core/PCM[53]} {wallypipelinedsoc/core/PCM[54]} {wallypipelinedsoc/core/PCM[55]} {wallypipelinedsoc/core/PCM[56]} {wallypipelinedsoc/core/PCM[57]} {wallypipelinedsoc/core/PCM[58]} {wallypipelinedsoc/core/PCM[59]} {wallypipelinedsoc/core/PCM[60]} {wallypipelinedsoc/core/PCM[61]} {wallypipelinedsoc/core/PCM[62]} {wallypipelinedsoc/core/PCM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {wallypipelinedsoc/core/IEUAdrM[0]} {wallypipelinedsoc/core/IEUAdrM[1]} {wallypipelinedsoc/core/IEUAdrM[2]} {wallypipelinedsoc/core/IEUAdrM[3]} {wallypipelinedsoc/core/IEUAdrM[4]} {wallypipelinedsoc/core/IEUAdrM[5]} {wallypipelinedsoc/core/IEUAdrM[6]} {wallypipelinedsoc/core/IEUAdrM[7]} {wallypipelinedsoc/core/IEUAdrM[8]} {wallypipelinedsoc/core/IEUAdrM[9]} {wallypipelinedsoc/core/IEUAdrM[10]} {wallypipelinedsoc/core/IEUAdrM[11]} {wallypipelinedsoc/core/IEUAdrM[12]} {wallypipelinedsoc/core/IEUAdrM[13]} {wallypipelinedsoc/core/IEUAdrM[14]} {wallypipelinedsoc/core/IEUAdrM[15]} {wallypipelinedsoc/core/IEUAdrM[16]} {wallypipelinedsoc/core/IEUAdrM[17]} {wallypipelinedsoc/core/IEUAdrM[18]} {wallypipelinedsoc/core/IEUAdrM[19]} {wallypipelinedsoc/core/IEUAdrM[20]} {wallypipelinedsoc/core/IEUAdrM[21]} {wallypipelinedsoc/core/IEUAdrM[22]} {wallypipelinedsoc/core/IEUAdrM[23]} {wallypipelinedsoc/core/IEUAdrM[24]} {wallypipelinedsoc/core/IEUAdrM[25]} {wallypipelinedsoc/core/IEUAdrM[26]} {wallypipelinedsoc/core/IEUAdrM[27]} {wallypipelinedsoc/core/IEUAdrM[28]} {wallypipelinedsoc/core/IEUAdrM[29]} {wallypipelinedsoc/core/IEUAdrM[30]} {wallypipelinedsoc/core/IEUAdrM[31]} {wallypipelinedsoc/core/IEUAdrM[32]} {wallypipelinedsoc/core/IEUAdrM[33]} {wallypipelinedsoc/core/IEUAdrM[34]} {wallypipelinedsoc/core/IEUAdrM[35]} {wallypipelinedsoc/core/IEUAdrM[36]} {wallypipelinedsoc/core/IEUAdrM[37]} {wallypipelinedsoc/core/IEUAdrM[38]} {wallypipelinedsoc/core/IEUAdrM[39]} {wallypipelinedsoc/core/IEUAdrM[40]} {wallypipelinedsoc/core/IEUAdrM[41]} {wallypipelinedsoc/core/IEUAdrM[42]} {wallypipelinedsoc/core/IEUAdrM[43]} {wallypipelinedsoc/core/IEUAdrM[44]} {wallypipelinedsoc/core/IEUAdrM[45]} {wallypipelinedsoc/core/IEUAdrM[46]} {wallypipelinedsoc/core/IEUAdrM[47]} {wallypipelinedsoc/core/IEUAdrM[48]} {wallypipelinedsoc/core/IEUAdrM[49]} {wallypipelinedsoc/core/IEUAdrM[50]} {wallypipelinedsoc/core/IEUAdrM[51]} {wallypipelinedsoc/core/IEUAdrM[52]} {wallypipelinedsoc/core/IEUAdrM[53]} {wallypipelinedsoc/core/IEUAdrM[54]} {wallypipelinedsoc/core/IEUAdrM[55]} {wallypipelinedsoc/core/IEUAdrM[56]} {wallypipelinedsoc/core/IEUAdrM[57]} {wallypipelinedsoc/core/IEUAdrM[58]} {wallypipelinedsoc/core/IEUAdrM[59]} {wallypipelinedsoc/core/IEUAdrM[60]} {wallypipelinedsoc/core/IEUAdrM[61]} {wallypipelinedsoc/core/IEUAdrM[62]} {wallypipelinedsoc/core/IEUAdrM[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {wallypipelinedsoc/core/InstrM[0]} {wallypipelinedsoc/core/InstrM[1]} {wallypipelinedsoc/core/InstrM[2]} {wallypipelinedsoc/core/InstrM[3]} {wallypipelinedsoc/core/InstrM[4]} {wallypipelinedsoc/core/InstrM[5]} {wallypipelinedsoc/core/InstrM[6]} {wallypipelinedsoc/core/InstrM[7]} {wallypipelinedsoc/core/InstrM[8]} {wallypipelinedsoc/core/InstrM[9]} {wallypipelinedsoc/core/InstrM[10]} {wallypipelinedsoc/core/InstrM[11]} {wallypipelinedsoc/core/InstrM[12]} {wallypipelinedsoc/core/InstrM[13]} {wallypipelinedsoc/core/InstrM[14]} {wallypipelinedsoc/core/InstrM[15]} {wallypipelinedsoc/core/InstrM[16]} {wallypipelinedsoc/core/InstrM[17]} {wallypipelinedsoc/core/InstrM[18]} {wallypipelinedsoc/core/InstrM[19]} {wallypipelinedsoc/core/InstrM[20]} {wallypipelinedsoc/core/InstrM[21]} {wallypipelinedsoc/core/InstrM[22]} {wallypipelinedsoc/core/InstrM[23]} {wallypipelinedsoc/core/InstrM[24]} {wallypipelinedsoc/core/InstrM[25]} {wallypipelinedsoc/core/InstrM[26]} {wallypipelinedsoc/core/InstrM[27]} {wallypipelinedsoc/core/InstrM[28]} {wallypipelinedsoc/core/InstrM[29]} {wallypipelinedsoc/core/InstrM[30]} {wallypipelinedsoc/core/InstrM[31]} ]]
create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe10]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {wallypipelinedsoc/core/MemRWM[0]} {wallypipelinedsoc/core/MemRWM[1]} ]]
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe11]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrm/MIE_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIE_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIE_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIE_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIE_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIE_REGW[11]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe12]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEPC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe13]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrm/MIP_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIP_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIP_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIP_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIP_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIP_REGW[11]} ]]


create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe14]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {wallypipelinedsoc/core/lsu/bus.dcache.dcache/cachefsm/CurrState[0]} {wallypipelinedsoc/core/lsu/bus.dcache.dcache/cachefsm/CurrState[1]} {wallypipelinedsoc/core/lsu/bus.dcache.dcache/cachefsm/CurrState[2]} {wallypipelinedsoc/core/lsu/bus.dcache.dcache/cachefsm/CurrState[3]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe15]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SEPC_REGW[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe16]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SCAUSE_REGW[63]} ]]


create_debug_port u_ila_0 probe
set_property port_width 5 [get_debug_ports u_ila_0/probe17]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[4]} ]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe18]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe19]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[0]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[1]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[2]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[3]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[4]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[5]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[6]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[7]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[8]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[9]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[10]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[11]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[12]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[13]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[14]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[15]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[16]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[17]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[18]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[19]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[20]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[21]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[22]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[23]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[24]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[25]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[26]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[27]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[28]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[29]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[30]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[31]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[32]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[33]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[34]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[35]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[36]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[37]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[38]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[39]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[40]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[41]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[42]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[43]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[44]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[45]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[46]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[47]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[48]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[49]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[50]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[51]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[52]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[53]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[54]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[55]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[56]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[57]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[58]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[59]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[60]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[61]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[62]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[63]} ]]


create_debug_port u_ila_0 probe
set_property port_width 63 [get_debug_ports u_ila_0/probe20]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/STVEC_REGW[63]} ]]


create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe21]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/MSR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MSR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MSR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MSR[3]} ]]

create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe22]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[1]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[3]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[5]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[7]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[9]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[11]} ]]


create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe23]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {wallypipelinedsoc/core/lsu/LSUHSIZE[0]} {wallypipelinedsoc/core/lsu/LSUHSIZE[1]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe24]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list wallypipelinedsoc/core/lsu/LSUHREADY ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe25]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list wallypipelinedsoc/core/lsu/LSUHWRITE ]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe26]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {wallypipelinedsoc/core/lsu/LSUHBURST[0]} wallypipelinedsoc/core/lsu/LSUHBURST[1] wallypipelinedsoc/core/lsu/LSUHBURST[2] ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe27]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/BreakpointFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe28]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/DTRb ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe29]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe29]
connect_debug_port u_ila_0/probe29 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/EcallFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe30]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe30]
connect_debug_port u_ila_0/probe30 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/IllegalInstrFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe31]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe31]
connect_debug_port u_ila_0/probe31 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/InstrAccessFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe32]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/InstrPageFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe33]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list wallypipelinedsoc/core/InstrValidM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe34]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/INTR ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe35]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/LoadAccessFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe36]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/LoadMisalignedFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe37]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/LoadPageFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe38]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe38]
connect_debug_port u_ila_0/probe38 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/mretM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe39]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe39]
connect_debug_port u_ila_0/probe39 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/OUT1b ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe40]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe40]
connect_debug_port u_ila_0/probe40 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/OUT2b ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe41]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe41]
connect_debug_port u_ila_0/probe41 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/RTSb ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe42]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe42]
connect_debug_port u_ila_0/probe42 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/RXRDYb ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe43]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe43]
connect_debug_port u_ila_0/probe43 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/SIN ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe44]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe44]
connect_debug_port u_ila_0/probe44 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/SOUT ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe45]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe45]
connect_debug_port u_ila_0/probe45 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/sretM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe46]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe46]
connect_debug_port u_ila_0/probe46 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/StoreAmoAccessFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe47]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe47]
connect_debug_port u_ila_0/probe47 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/StoreAmoMisalignedFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe48]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe48]
connect_debug_port u_ila_0/probe48 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/StoreAmoPageFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe49]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe49]
connect_debug_port u_ila_0/probe49 [get_nets [list wallypipelinedsoc/core/TrapM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe50]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe50]
connect_debug_port u_ila_0/probe50 [get_nets [list wallypipelinedsoc/uncore.uncore/uart.uart/TXRDYb ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe51]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe51]
connect_debug_port u_ila_0/probe51 [get_nets [list wallypipelinedsoc/core/hzu/BPPredWrongE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe52]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe52]
connect_debug_port u_ila_0/probe52 [get_nets [list wallypipelinedsoc/core/hzu/CSRWriteFenceM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe53]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe53]
connect_debug_port u_ila_0/probe53 [get_nets [list wallypipelinedsoc/core/hzu/RetM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe54]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe54]
connect_debug_port u_ila_0/probe54 [get_nets [list wallypipelinedsoc/core/TrapM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe55]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe55]
connect_debug_port u_ila_0/probe55 [get_nets [list wallypipelinedsoc/core/hzu/LoadStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe56]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe56]
connect_debug_port u_ila_0/probe56 [get_nets [list wallypipelinedsoc/core/hzu/StoreStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe57]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe57]
connect_debug_port u_ila_0/probe57 [get_nets [list wallypipelinedsoc/core/hzu/MDUStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe58]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe58]
connect_debug_port u_ila_0/probe58 [get_nets [list wallypipelinedsoc/core/hzu/CSRRdStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe59]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe59]
connect_debug_port u_ila_0/probe59 [get_nets [list wallypipelinedsoc/core/hzu/LSUStallM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe60]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe60]
connect_debug_port u_ila_0/probe60 [get_nets [list wallypipelinedsoc/core/hzu/IFUStallF ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe61]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe61]
connect_debug_port u_ila_0/probe61 [get_nets [list wallypipelinedsoc/core/hzu/FPUStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe62]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe62]
connect_debug_port u_ila_0/probe62 [get_nets [list wallypipelinedsoc/core/hzu/FCvtIntStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 7 [get_debug_ports u_ila_0/probe63]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe63]
connect_debug_port u_ila_0/probe63 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[0][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[0][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[0][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[0][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[0][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[0][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[0][7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe64]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe64]
connect_debug_port u_ila_0/probe64 [get_nets [list wallypipelinedsoc/core/hzu/FDivBusyE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe65]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe65]
connect_debug_port u_ila_0/probe65 [get_nets [list wallypipelinedsoc/core/hzu/EcallFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe66]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe66]
connect_debug_port u_ila_0/probe66 [get_nets [list wallypipelinedsoc/core/hzu/BreakpointFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe67]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe67]
connect_debug_port u_ila_0/probe67 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrIP} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe68]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe68]
connect_debug_port u_ila_0/probe68 [get_nets [list wallypipelinedsoc/core/hzu/StallF ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe69]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe69]
connect_debug_port u_ila_0/probe69 [get_nets [list wallypipelinedsoc/core/hzu/StallDCause]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe70]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe70]
connect_debug_port u_ila_0/probe70 [get_nets [list wallypipelinedsoc/core/hzu/StallE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe71]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe71]
connect_debug_port u_ila_0/probe71 [get_nets [list wallypipelinedsoc/core/hzu/StallM ]]

# StallW is StallM.  trying to connect to StallW causes issues.
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe72]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe72]
connect_debug_port u_ila_0/probe72 [get_nets [list wallypipelinedsoc/core/hzu/StallM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe73]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe73]
connect_debug_port u_ila_0/probe73 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrIP} ]]


create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe74]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe74]
connect_debug_port u_ila_0/probe74 [get_nets [list wallypipelinedsoc/core/hzu/FlushD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe75]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe75]
connect_debug_port u_ila_0/probe75 [get_nets [list wallypipelinedsoc/core/hzu/FlushE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe76]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe76]
connect_debug_port u_ila_0/probe76 [get_nets [list wallypipelinedsoc/core/hzu/FlushM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe77]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe77]
connect_debug_port u_ila_0/probe77 [get_nets [list wallypipelinedsoc/core/hzu/FlushW ]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe78]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe78]
connect_debug_port u_ila_0/probe78 [get_nets [list {wallypipelinedsoc/core/ifu/bus.icache.icache/cachefsm/CurrState[0]} {wallypipelinedsoc/core/ifu/bus.icache.icache/cachefsm/CurrState[1]} {wallypipelinedsoc/core/ifu/bus.icache.icache/cachefsm/CurrState[2]} {wallypipelinedsoc/core/ifu/bus.icache.icache/cachefsm/CurrState[3]}]]


create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe79]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe79]
connect_debug_port u_ila_0/probe79 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HTRANS[0]} {wallypipelinedsoc/core/ebu.ebu/HTRANS[1]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe80]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe80]
connect_debug_port u_ila_0/probe80 [get_nets [list wallypipelinedsoc/core/ifu/IFUHREADY ]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe81]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe81]
connect_debug_port u_ila_0/probe81 [get_nets [list {wallypipelinedsoc/core/ifu/IFUHADDR[0]} {wallypipelinedsoc/core/ifu/IFUHADDR[1]} {wallypipelinedsoc/core/ifu/IFUHADDR[2]} {wallypipelinedsoc/core/ifu/IFUHADDR[3]} {wallypipelinedsoc/core/ifu/IFUHADDR[4]} {wallypipelinedsoc/core/ifu/IFUHADDR[5]} {wallypipelinedsoc/core/ifu/IFUHADDR[6]} {wallypipelinedsoc/core/ifu/IFUHADDR[7]} {wallypipelinedsoc/core/ifu/IFUHADDR[8]} {wallypipelinedsoc/core/ifu/IFUHADDR[9]} {wallypipelinedsoc/core/ifu/IFUHADDR[10]} {wallypipelinedsoc/core/ifu/IFUHADDR[11]} {wallypipelinedsoc/core/ifu/IFUHADDR[12]} {wallypipelinedsoc/core/ifu/IFUHADDR[13]} {wallypipelinedsoc/core/ifu/IFUHADDR[14]} {wallypipelinedsoc/core/ifu/IFUHADDR[15]} {wallypipelinedsoc/core/ifu/IFUHADDR[16]} {wallypipelinedsoc/core/ifu/IFUHADDR[17]} {wallypipelinedsoc/core/ifu/IFUHADDR[18]} {wallypipelinedsoc/core/ifu/IFUHADDR[19]} {wallypipelinedsoc/core/ifu/IFUHADDR[20]} {wallypipelinedsoc/core/ifu/IFUHADDR[21]} {wallypipelinedsoc/core/ifu/IFUHADDR[22]} {wallypipelinedsoc/core/ifu/IFUHADDR[23]} {wallypipelinedsoc/core/ifu/IFUHADDR[24]} {wallypipelinedsoc/core/ifu/IFUHADDR[25]} {wallypipelinedsoc/core/ifu/IFUHADDR[26]} {wallypipelinedsoc/core/ifu/IFUHADDR[27]} {wallypipelinedsoc/core/ifu/IFUHADDR[28]} {wallypipelinedsoc/core/ifu/IFUHADDR[29]} {wallypipelinedsoc/core/ifu/IFUHADDR[30]} {wallypipelinedsoc/core/ifu/IFUHADDR[31]}]]

create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe82]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe82]
connect_debug_port u_ila_0/probe82 [get_nets [list {wallypipelinedsoc/core/ifu/IFUHTRANS[0]} {wallypipelinedsoc/core/ifu/IFUHTRANS[0]}]]



create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe83]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe83]
connect_debug_port u_ila_0/probe83 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HTRANS[0]} {wallypipelinedsoc/core/ebu.ebu/HTRANS[1]}]]

create_debug_port u_ila_0 probe
set_property port_width 53 [get_debug_ports u_ila_0/probe84]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe84]
connect_debug_port u_ila_0/probe84 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][10]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][11]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][12]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][13]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][14]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][15]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][16]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][17]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][18]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][19]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][20]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][21]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][22]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][23]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][24]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][25]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][26]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][27]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][28]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][29]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][30]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][31]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][32]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][33]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][34]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][35]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][36]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][37]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][38]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][39]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][40]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][41]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][42]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][43]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][44]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][45]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][46]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][47]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][48]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][49]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][50]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][51]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][52]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[0][53]} ]]



create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe85]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe85]
connect_debug_port u_ila_0/probe85 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HADDR[0]} {wallypipelinedsoc/core/ebu.ebu/HADDR[1]} {wallypipelinedsoc/core/ebu.ebu/HADDR[2]} {wallypipelinedsoc/core/ebu.ebu/HADDR[3]} {wallypipelinedsoc/core/ebu.ebu/HADDR[4]} {wallypipelinedsoc/core/ebu.ebu/HADDR[5]} {wallypipelinedsoc/core/ebu.ebu/HADDR[6]} {wallypipelinedsoc/core/ebu.ebu/HADDR[7]} {wallypipelinedsoc/core/ebu.ebu/HADDR[8]} {wallypipelinedsoc/core/ebu.ebu/HADDR[9]} {wallypipelinedsoc/core/ebu.ebu/HADDR[10]} {wallypipelinedsoc/core/ebu.ebu/HADDR[11]} {wallypipelinedsoc/core/ebu.ebu/HADDR[12]} {wallypipelinedsoc/core/ebu.ebu/HADDR[13]} {wallypipelinedsoc/core/ebu.ebu/HADDR[14]} {wallypipelinedsoc/core/ebu.ebu/HADDR[15]} {wallypipelinedsoc/core/ebu.ebu/HADDR[16]} {wallypipelinedsoc/core/ebu.ebu/HADDR[17]} {wallypipelinedsoc/core/ebu.ebu/HADDR[18]} {wallypipelinedsoc/core/ebu.ebu/HADDR[19]} {wallypipelinedsoc/core/ebu.ebu/HADDR[20]} {wallypipelinedsoc/core/ebu.ebu/HADDR[21]} {wallypipelinedsoc/core/ebu.ebu/HADDR[22]} {wallypipelinedsoc/core/ebu.ebu/HADDR[23]} {wallypipelinedsoc/core/ebu.ebu/HADDR[24]} {wallypipelinedsoc/core/ebu.ebu/HADDR[25]} {wallypipelinedsoc/core/ebu.ebu/HADDR[26]} {wallypipelinedsoc/core/ebu.ebu/HADDR[27]} {wallypipelinedsoc/core/ebu.ebu/HADDR[28]} {wallypipelinedsoc/core/ebu.ebu/HADDR[29]} {wallypipelinedsoc/core/ebu.ebu/HADDR[30]} {wallypipelinedsoc/core/ebu.ebu/HADDR[31]}]]


create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe86]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe86]
connect_debug_port u_ila_0/probe86 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HREADY}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe87]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe87]
connect_debug_port u_ila_0/probe87 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HRESP}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe88]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe88]
connect_debug_port u_ila_0/probe88 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HWRITE}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe89]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe89]
connect_debug_port u_ila_0/probe89 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HSIZE[0]} {wallypipelinedsoc/core/ebu.ebu/HSIZE[1]} {wallypipelinedsoc/core/ebu.ebu/HSIZE[2]}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe90]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe90]
connect_debug_port u_ila_0/probe90 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HBURST[0]} {wallypipelinedsoc/core/ebu.ebu/HBURST[1]} {wallypipelinedsoc/core/ebu.ebu/HBURST[2]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe91]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe91]
connect_debug_port u_ila_0/probe91 [get_nets [list {wallypipelinedsoc/core/ebu.ebu/HPROT[0]} {wallypipelinedsoc/core/ebu.ebu/HPROT[1]} {wallypipelinedsoc/core/ebu.ebu/HPROT[2]} {wallypipelinedsoc/core/ebu.ebu/HPROT[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe92]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe92]
connect_debug_port u_ila_0/probe92 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/IER[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/IER[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/IER[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/IER[3]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe93]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe93]
connect_debug_port u_ila_0/probe93 [get_nets [list {wallypipelinedsoc/core/priv.priv/InterruptM}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe94]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe94]
connect_debug_port u_ila_0/probe94 [get_nets [list wallypipelinedsoc/core/lsu/ITLBMissF]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe95]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe95]
connect_debug_port u_ila_0/probe95 [get_nets [list wallypipelinedsoc/core/lsu/DTLBMissM]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe96]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe96]
connect_debug_port u_ila_0/probe96 [get_nets [list wallypipelinedsoc/core/lsu/ITLBWriteF]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe97]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe97]
connect_debug_port u_ila_0/probe97 [get_nets [list wallypipelinedsoc/core/lsu/DTLBWriteM]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe98]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe98]
connect_debug_port u_ila_0/probe98 [get_nets [list {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.hptw/WalkerState[0]} {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.hptw/WalkerState[1]} {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.hptw/WalkerState[2]} {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.hptw/WalkerState[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe99]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe99]
connect_debug_port u_ila_0/probe99 [get_nets [list {wallypipelinedsoc/core/SrcAM[0]} {wallypipelinedsoc/core/SrcAM[1]} {wallypipelinedsoc/core/SrcAM[2]} {wallypipelinedsoc/core/SrcAM[3]} {wallypipelinedsoc/core/SrcAM[4]} {wallypipelinedsoc/core/SrcAM[5]} {wallypipelinedsoc/core/SrcAM[6]} {wallypipelinedsoc/core/SrcAM[7]} {wallypipelinedsoc/core/SrcAM[8]} {wallypipelinedsoc/core/SrcAM[9]} {wallypipelinedsoc/core/SrcAM[10]} {wallypipelinedsoc/core/SrcAM[11]} {wallypipelinedsoc/core/SrcAM[12]} {wallypipelinedsoc/core/SrcAM[13]} {wallypipelinedsoc/core/SrcAM[14]} {wallypipelinedsoc/core/SrcAM[15]} {wallypipelinedsoc/core/SrcAM[16]} {wallypipelinedsoc/core/SrcAM[17]} {wallypipelinedsoc/core/SrcAM[18]} {wallypipelinedsoc/core/SrcAM[19]} {wallypipelinedsoc/core/SrcAM[20]} {wallypipelinedsoc/core/SrcAM[21]} {wallypipelinedsoc/core/SrcAM[22]} {wallypipelinedsoc/core/SrcAM[23]} {wallypipelinedsoc/core/SrcAM[24]} {wallypipelinedsoc/core/SrcAM[25]} {wallypipelinedsoc/core/SrcAM[26]} {wallypipelinedsoc/core/SrcAM[27]} {wallypipelinedsoc/core/SrcAM[28]} {wallypipelinedsoc/core/SrcAM[29]} {wallypipelinedsoc/core/SrcAM[30]} {wallypipelinedsoc/core/SrcAM[31]} {wallypipelinedsoc/core/SrcAM[32]} {wallypipelinedsoc/core/SrcAM[33]} {wallypipelinedsoc/core/SrcAM[34]} {wallypipelinedsoc/core/SrcAM[35]} {wallypipelinedsoc/core/SrcAM[36]} {wallypipelinedsoc/core/SrcAM[37]} {wallypipelinedsoc/core/SrcAM[38]} {wallypipelinedsoc/core/SrcAM[39]} {wallypipelinedsoc/core/SrcAM[40]} {wallypipelinedsoc/core/SrcAM[41]} {wallypipelinedsoc/core/SrcAM[42]} {wallypipelinedsoc/core/SrcAM[43]} {wallypipelinedsoc/core/SrcAM[44]} {wallypipelinedsoc/core/SrcAM[45]} {wallypipelinedsoc/core/SrcAM[46]} {wallypipelinedsoc/core/SrcAM[47]} {wallypipelinedsoc/core/SrcAM[48]} {wallypipelinedsoc/core/SrcAM[49]} {wallypipelinedsoc/core/SrcAM[50]} {wallypipelinedsoc/core/SrcAM[51]} {wallypipelinedsoc/core/SrcAM[52]} {wallypipelinedsoc/core/SrcAM[53]} {wallypipelinedsoc/core/SrcAM[54]} {wallypipelinedsoc/core/SrcAM[55]} {wallypipelinedsoc/core/SrcAM[56]} {wallypipelinedsoc/core/SrcAM[57]} {wallypipelinedsoc/core/SrcAM[58]} {wallypipelinedsoc/core/SrcAM[59]} {wallypipelinedsoc/core/SrcAM[60]} {wallypipelinedsoc/core/SrcAM[61]} {wallypipelinedsoc/core/SrcAM[62]} {wallypipelinedsoc/core/SrcAM[63]}]]


create_debug_port u_ila_0 probe
set_property port_width 56 [get_debug_ports u_ila_0/probe100]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe100]
connect_debug_port u_ila_0/probe100 [get_nets [list {wallypipelinedsoc/core/ifu/PCPF[0]} {wallypipelinedsoc/core/ifu/PCPF[1]} {wallypipelinedsoc/core/ifu/PCPF[2]} {wallypipelinedsoc/core/ifu/PCPF[3]} {wallypipelinedsoc/core/ifu/PCPF[4]} {wallypipelinedsoc/core/ifu/PCPF[5]} {wallypipelinedsoc/core/ifu/PCPF[6]} {wallypipelinedsoc/core/ifu/PCPF[7]} {wallypipelinedsoc/core/ifu/PCPF[8]} {wallypipelinedsoc/core/ifu/PCPF[9]} {wallypipelinedsoc/core/ifu/PCPF[10]} {wallypipelinedsoc/core/ifu/PCPF[11]} {wallypipelinedsoc/core/ifu/PCPF[12]} {wallypipelinedsoc/core/ifu/PCPF[13]} {wallypipelinedsoc/core/ifu/PCPF[14]} {wallypipelinedsoc/core/ifu/PCPF[15]} {wallypipelinedsoc/core/ifu/PCPF[16]} {wallypipelinedsoc/core/ifu/PCPF[17]} {wallypipelinedsoc/core/ifu/PCPF[18]} {wallypipelinedsoc/core/ifu/PCPF[19]} {wallypipelinedsoc/core/ifu/PCPF[20]} {wallypipelinedsoc/core/ifu/PCPF[21]} {wallypipelinedsoc/core/ifu/PCPF[22]} {wallypipelinedsoc/core/ifu/PCPF[23]} {wallypipelinedsoc/core/ifu/PCPF[24]} {wallypipelinedsoc/core/ifu/PCPF[25]} {wallypipelinedsoc/core/ifu/PCPF[26]} {wallypipelinedsoc/core/ifu/PCPF[27]} {wallypipelinedsoc/core/ifu/PCPF[28]} {wallypipelinedsoc/core/ifu/PCPF[29]} {wallypipelinedsoc/core/ifu/PCPF[30]} {wallypipelinedsoc/core/ifu/PCPF[31]} {wallypipelinedsoc/core/ifu/PCPF[32]} {wallypipelinedsoc/core/ifu/PCPF[33]} {wallypipelinedsoc/core/ifu/PCPF[34]} {wallypipelinedsoc/core/ifu/PCPF[35]} {wallypipelinedsoc/core/ifu/PCPF[36]} {wallypipelinedsoc/core/ifu/PCPF[37]} {wallypipelinedsoc/core/ifu/PCPF[38]} {wallypipelinedsoc/core/ifu/PCPF[39]} {wallypipelinedsoc/core/ifu/PCPF[40]} {wallypipelinedsoc/core/ifu/PCPF[41]} {wallypipelinedsoc/core/ifu/PCPF[42]} {wallypipelinedsoc/core/ifu/PCPF[43]} {wallypipelinedsoc/core/ifu/PCPF[44]} {wallypipelinedsoc/core/ifu/PCPF[45]} {wallypipelinedsoc/core/ifu/PCPF[46]} {wallypipelinedsoc/core/ifu/PCPF[47]} {wallypipelinedsoc/core/ifu/PCPF[48]} {wallypipelinedsoc/core/ifu/PCPF[49]} {wallypipelinedsoc/core/ifu/PCPF[50]} {wallypipelinedsoc/core/ifu/PCPF[51]} {wallypipelinedsoc/core/ifu/PCPF[52]} {wallypipelinedsoc/core/ifu/PCPF[53]} {wallypipelinedsoc/core/ifu/PCPF[54]} {wallypipelinedsoc/core/ifu/PCPF[55]} ]]



create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe101]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe101]
connect_debug_port u_ila_0/probe101 [get_nets [list {wallypipelinedsoc/core/ifu/bus.icache.ahbcacheinterface/AHBBuscachefsm/CurrState[0]} {wallypipelinedsoc/core/ifu/bus.icache.ahbcacheinterface/AHBBuscachefsm/CurrState[1]} {wallypipelinedsoc/core/ifu/bus.icache.ahbcacheinterface/AHBBuscachefsm/CurrState[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe102]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe102]
connect_debug_port u_ila_0/probe102 [get_nets [list wallypipelinedsoc/core/ifu/Spill.spill/CurrState[0] ]]


create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe103]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe103]
connect_debug_port u_ila_0/probe103 [get_nets [list {wallypipelinedsoc/core/lsu/bus.dcache.ahbcacheinterface/AHBBuscachefsm/CurrState[0]} {wallypipelinedsoc/core/lsu/bus.dcache.ahbcacheinterface/AHBBuscachefsm/CurrState[1]} {wallypipelinedsoc/core/lsu/bus.dcache.ahbcacheinterface/AHBBuscachefsm/CurrState[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 7 [get_debug_ports u_ila_0/probe104]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe104]
connect_debug_port u_ila_0/probe104 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[1][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[1][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[1][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[1][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[1][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[1][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/threshMask[1][7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe105]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe105]
connect_debug_port u_ila_0/probe105 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[0]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[1]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[2]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[3]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[4]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[5]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[6]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[7]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[8]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[9]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[10]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[11]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[12]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[13]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[14]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[15]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[16]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[17]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[18]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[19]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[20]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[21]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[22]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[23]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[24]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[25]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[26]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[27]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[28]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[29]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[30]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[31]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[32]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[33]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[34]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[35]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[36]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[37]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[38]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[39]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[40]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[41]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[42]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[43]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[44]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[45]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[46]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[47]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[48]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[49]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[50]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[51]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[52]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[53]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[54]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[55]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[56]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[57]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[58]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[59]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[60]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[61]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[62]} {wallypipelinedsoc/core/priv.priv/csr/CSRReadValM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe106]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe106]
connect_debug_port u_ila_0/probe106 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[0]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[1]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[2]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[3]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[4]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[5]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[6]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[7]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[8]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[9]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[10]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[11]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[12]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[13]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[14]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[15]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[16]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[17]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[18]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[19]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[20]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[21]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[22]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[23]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[24]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[25]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[26]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[27]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[28]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[29]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[30]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[31]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[32]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[33]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[34]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[35]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[36]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[37]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[38]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[39]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[40]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[41]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[42]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[43]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[44]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[45]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[46]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[47]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[48]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[49]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[50]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[51]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[52]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[53]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[54]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[55]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[56]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[57]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[58]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[59]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[60]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[61]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[62]} {wallypipelinedsoc/core/priv.priv/csr/CSRSrcM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe107]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe107]
connect_debug_port u_ila_0/probe107 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[0]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[1]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[2]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[3]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[4]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[5]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[6]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[7]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[8]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[9]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[10]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[11]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[12]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[13]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[14]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[15]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[16]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[17]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[18]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[19]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[20]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[21]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[22]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[23]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[24]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[25]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[26]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[27]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[28]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[29]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[30]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[31]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[32]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[33]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[34]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[35]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[36]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[37]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[38]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[39]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[40]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[41]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[42]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[43]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[44]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[45]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[46]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[47]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[48]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[49]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[50]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[51]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[52]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[53]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[54]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[55]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[56]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[57]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[58]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[59]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[60]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[61]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[62]} {wallypipelinedsoc/core/priv.priv/csr/CSRWriteValM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe108]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe108]
connect_debug_port u_ila_0/probe108 [get_nets [list wallypipelinedsoc/core/ieu/dp/RegWriteW]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe109]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe109]
connect_debug_port u_ila_0/probe109 [get_nets [list {wallypipelinedsoc/core/priv.priv/CSRWriteM} ]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe110]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe110]
connect_debug_port u_ila_0/probe110 [get_nets [list {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[0]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[1]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[2]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[3]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[4]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[5]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[6]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[7]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[8]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[9]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[10]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[11]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[12]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[13]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[14]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[15]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[16]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[17]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[18]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[19]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[20]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[21]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[22]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[23]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[24]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[25]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[26]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[27]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[28]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[29]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[30]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[31]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe111]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe111]
connect_debug_port u_ila_0/probe111 [get_nets [list {wallypipelinedsoc/core/ifu/PCNextF[0]} {wallypipelinedsoc/core/ifu/PCNextF[1]} {wallypipelinedsoc/core/ifu/PCNextF[2]} {wallypipelinedsoc/core/ifu/PCNextF[3]} {wallypipelinedsoc/core/ifu/PCNextF[4]} {wallypipelinedsoc/core/ifu/PCNextF[5]} {wallypipelinedsoc/core/ifu/PCNextF[6]} {wallypipelinedsoc/core/ifu/PCNextF[7]} {wallypipelinedsoc/core/ifu/PCNextF[8]} {wallypipelinedsoc/core/ifu/PCNextF[9]} {wallypipelinedsoc/core/ifu/PCNextF[10]} {wallypipelinedsoc/core/ifu/PCNextF[11]} {wallypipelinedsoc/core/ifu/PCNextF[12]} {wallypipelinedsoc/core/ifu/PCNextF[13]} {wallypipelinedsoc/core/ifu/PCNextF[14]} {wallypipelinedsoc/core/ifu/PCNextF[15]} {wallypipelinedsoc/core/ifu/PCNextF[16]} {wallypipelinedsoc/core/ifu/PCNextF[17]} {wallypipelinedsoc/core/ifu/PCNextF[18]} {wallypipelinedsoc/core/ifu/PCNextF[19]} {wallypipelinedsoc/core/ifu/PCNextF[20]} {wallypipelinedsoc/core/ifu/PCNextF[21]} {wallypipelinedsoc/core/ifu/PCNextF[22]} {wallypipelinedsoc/core/ifu/PCNextF[23]} {wallypipelinedsoc/core/ifu/PCNextF[24]} {wallypipelinedsoc/core/ifu/PCNextF[25]} {wallypipelinedsoc/core/ifu/PCNextF[26]} {wallypipelinedsoc/core/ifu/PCNextF[27]} {wallypipelinedsoc/core/ifu/PCNextF[28]} {wallypipelinedsoc/core/ifu/PCNextF[29]} {wallypipelinedsoc/core/ifu/PCNextF[30]} {wallypipelinedsoc/core/ifu/PCNextF[31]} {wallypipelinedsoc/core/ifu/PCNextF[32]} {wallypipelinedsoc/core/ifu/PCNextF[33]} {wallypipelinedsoc/core/ifu/PCNextF[34]} {wallypipelinedsoc/core/ifu/PCNextF[35]} {wallypipelinedsoc/core/ifu/PCNextF[36]} {wallypipelinedsoc/core/ifu/PCNextF[37]} {wallypipelinedsoc/core/ifu/PCNextF[38]} {wallypipelinedsoc/core/ifu/PCNextF[39]} {wallypipelinedsoc/core/ifu/PCNextF[40]} {wallypipelinedsoc/core/ifu/PCNextF[41]} {wallypipelinedsoc/core/ifu/PCNextF[42]} {wallypipelinedsoc/core/ifu/PCNextF[43]} {wallypipelinedsoc/core/ifu/PCNextF[44]} {wallypipelinedsoc/core/ifu/PCNextF[45]} {wallypipelinedsoc/core/ifu/PCNextF[46]} {wallypipelinedsoc/core/ifu/PCNextF[47]} {wallypipelinedsoc/core/ifu/PCNextF[48]} {wallypipelinedsoc/core/ifu/PCNextF[49]} {wallypipelinedsoc/core/ifu/PCNextF[50]} {wallypipelinedsoc/core/ifu/PCNextF[51]} {wallypipelinedsoc/core/ifu/PCNextF[52]} {wallypipelinedsoc/core/ifu/PCNextF[53]} {wallypipelinedsoc/core/ifu/PCNextF[54]} {wallypipelinedsoc/core/ifu/PCNextF[55]} {wallypipelinedsoc/core/ifu/PCNextF[56]} {wallypipelinedsoc/core/ifu/PCNextF[57]} {wallypipelinedsoc/core/ifu/PCNextF[58]} {wallypipelinedsoc/core/ifu/PCNextF[59]} {wallypipelinedsoc/core/ifu/PCNextF[60]} {wallypipelinedsoc/core/ifu/PCNextF[61]} {wallypipelinedsoc/core/ifu/PCNextF[62]} {wallypipelinedsoc/core/ifu/PCNextF[63]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe112]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe112]
connect_debug_port u_ila_0/probe112 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[7]} ]]


create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe113]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe113]
connect_debug_port u_ila_0/probe113 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe114]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe114]
connect_debug_port u_ila_0/probe114 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe115]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe115]
connect_debug_port u_ila_0/probe115 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe116]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe116]
connect_debug_port u_ila_0/probe116 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txstate[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txstate[1]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe117]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe117]
connect_debug_port u_ila_0/probe117 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csri/MExtInt}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe118]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe118]
connect_debug_port u_ila_0/probe118 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csri/SExtInt} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe119]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe119]
connect_debug_port u_ila_0/probe119 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csri/MTimerInt} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe120]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe120]
connect_debug_port u_ila_0/probe120 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csri/MSwInt} ]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe121]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe121]
connect_debug_port u_ila_0/probe121 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[10]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe122]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe122]
connect_debug_port u_ila_0/probe122 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxparityerr} ]]

create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe123]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe123]
connect_debug_port u_ila_0/probe123 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxstate[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxstate[1]} ]]


create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe124]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe124]
connect_debug_port u_ila_0/probe124 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MIDELEG_REGW[11]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe125]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe125]
connect_debug_port u_ila_0/probe125 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MEDELEG_REGW[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe126]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe126]
connect_debug_port u_ila_0/probe126 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSTATUS_REGW[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe127]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe127]
connect_debug_port u_ila_0/probe127 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/SSTATUS_REGW[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe128]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe128]
connect_debug_port u_ila_0/probe128 [get_nets [list {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[0]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[1]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[2]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[3]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[4]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[5]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[6]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[7]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[8]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[9]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[10]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[11]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[12]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[13]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[14]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[15]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[16]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[17]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[18]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[19]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[20]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[21]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[22]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[23]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[24]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[25]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[26]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[27]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[28]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[29]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[30]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[31]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[32]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[33]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[34]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[35]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[36]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[37]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[38]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[39]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[40]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[41]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[42]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[43]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[44]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[45]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[46]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[47]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[48]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[49]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[50]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[51]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[52]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[53]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[54]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[55]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[56]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[57]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[58]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[59]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[60]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[61]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[62]} {wallypipelinedsoc/core/ieu/dp/regf/rf[2]__0[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe129]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe129]
connect_debug_port u_ila_0/probe129 [get_nets [list {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[0]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[1]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[2]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[3]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[4]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[5]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[6]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[7]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[8]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[9]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[10]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[11]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[12]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[13]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[14]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[15]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[16]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[17]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[18]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[19]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[20]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[21]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[22]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[23]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[24]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[25]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[26]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[27]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[28]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[29]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[30]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[31]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[32]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[33]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[34]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[35]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[36]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[37]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[38]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[39]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[40]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[41]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[42]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[43]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[44]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[45]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[46]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[47]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[48]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[49]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[50]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[51]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[52]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[53]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[54]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[55]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[56]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[57]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[58]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[59]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[60]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[61]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[62]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe130]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe130]
connect_debug_port u_ila_0/probe130 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrs.csrs/SSCRATCH_REGW[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe131]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe131]
connect_debug_port u_ila_0/probe131 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe132]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe132]
connect_debug_port u_ila_0/probe132 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/intrID[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/intrID[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/intrID[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe133]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe133]
connect_debug_port u_ila_0/probe133 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdataavailintr} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe134]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe134]
connect_debug_port u_ila_0/probe134 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/fifoenabled} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe135]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe135]
connect_debug_port u_ila_0/probe135 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifotriggered} ]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe136]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe136]
connect_debug_port u_ila_0/probe136 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoentries[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoentries[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoentries[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoentries[3]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe137]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe137]
connect_debug_port u_ila_0/probe137 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdataready} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe138]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe138]
connect_debug_port u_ila_0/probe138 [get_nets [list {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[0]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[1]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[2]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[3]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[4]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[5]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[6]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[7]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[8]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[9]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[10]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[11]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[12]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[13]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[14]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[15]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[16]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[17]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[18]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[19]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[20]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[21]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[22]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[23]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[24]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[25]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[26]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[27]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[28]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[29]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[30]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[31]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[32]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[33]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[34]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[35]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[36]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[37]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[38]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[39]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[40]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[41]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[42]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[43]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[44]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[45]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[46]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[47]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[48]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[49]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[50]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[51]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[52]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[53]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[54]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[55]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[56]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[57]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[58]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[59]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[60]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[61]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[62]} {wallypipelinedsoc/core/ieu/dp/regf/rf[10]__0[63]} ]]

# UART Signals -------------------------------------------------------

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe139]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe139]
connect_debug_port u_ila_0/probe139 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/Din[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Din[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Din[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Din[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Din[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Din[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Din[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Din[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe140]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe140]
connect_debug_port u_ila_0/probe140 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/Dout[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Dout[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Dout[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Dout[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Dout[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Dout[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Dout[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/Dout[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe141]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe141]
connect_debug_port u_ila_0/probe141 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/A[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/A[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/A[2]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe142]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe142]
connect_debug_port u_ila_0/probe142 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/MEMWb}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe143]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe143]
connect_debug_port u_ila_0/probe143 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/SIN}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe144]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe144]
connect_debug_port u_ila_0/probe144 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/SOUT}]]

create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe145]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe145]
connect_debug_port u_ila_0/probe145 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxstate[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxstate[1]}]]

create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe146]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe146]
connect_debug_port u_ila_0/probe146 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txstate[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txstate[1]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe147]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe147]
connect_debug_port u_ila_0/probe147 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/FCR[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe148]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe148]
connect_debug_port u_ila_0/probe148 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LCR[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe149]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe149]
connect_debug_port u_ila_0/probe149 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/LSR[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe150]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe150]
connect_debug_port u_ila_0/probe150 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/SCR[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe151]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe151]
connect_debug_port u_ila_0/probe151 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLL[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe152]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe152]
connect_debug_port u_ila_0/probe152 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/DLM[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe153]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe153]
connect_debug_port u_ila_0/probe153 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RBR[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe154]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe154]
connect_debug_port u_ila_0/probe154 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/IER[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/IER[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/IER[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/IER[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe155]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe155]
connect_debug_port u_ila_0/probe155 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/MSR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MSR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MSR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MSR[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 5 [get_debug_ports u_ila_0/probe156]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe156]
connect_debug_port u_ila_0/probe156 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/MCR[4]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe157]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe157]
connect_debug_port u_ila_0/probe157 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[0][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[0][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[0][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[0][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[0][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[0][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[0][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[0][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe158]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe158]
connect_debug_port u_ila_0/probe158 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[1][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[1][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[1][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[1][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[1][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[1][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[1][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[1][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe159]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe159]
connect_debug_port u_ila_0/probe159 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[2][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[2][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[2][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[2][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[2][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[2][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[2][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[2][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe160]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe160]
connect_debug_port u_ila_0/probe160 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[3][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[3][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[3][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[3][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[3][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[3][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[3][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[3][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe161]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe161]
connect_debug_port u_ila_0/probe161 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[4][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[4][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[4][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[4][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[4][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[4][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[4][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[4][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe162]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe162]
connect_debug_port u_ila_0/probe162 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[5][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[5][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[5][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[5][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[5][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[5][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[5][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[5][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe163]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe163]
connect_debug_port u_ila_0/probe163 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[6][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[6][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[6][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[6][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[6][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[6][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[6][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[6][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe164]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe164]
connect_debug_port u_ila_0/probe164 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[7][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[7][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[7][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[7][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[7][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[7][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[7][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[7][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe165]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe165]
connect_debug_port u_ila_0/probe165 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[8][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[8][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[8][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[8][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[8][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[8][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[8][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[8][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe166]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe166]
connect_debug_port u_ila_0/probe166 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[9][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[9][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[9][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[9][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[9][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[9][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[9][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[9][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe167]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe167]
connect_debug_port u_ila_0/probe167 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[10][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[10][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[10][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[10][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[10][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[10][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[10][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[10][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe168]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe168]
connect_debug_port u_ila_0/probe168 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[11][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[11][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[11][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[11][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[11][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[11][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[11][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[11][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe169]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe169]
connect_debug_port u_ila_0/probe169 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[12][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[12][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[12][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[12][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[12][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[12][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[12][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[12][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe170]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe170]
connect_debug_port u_ila_0/probe170 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[13][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[13][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[13][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[13][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[13][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[13][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[13][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[13][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe171]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe171]
connect_debug_port u_ila_0/probe171 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[14][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[14][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[14][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[14][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[14][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[14][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[14][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[14][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe172]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe172]
connect_debug_port u_ila_0/probe172 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[15][0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[15][1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[15][2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[15][3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[15][4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[15][5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[15][6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifo_reg[15][7]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe173]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe173]
connect_debug_port u_ila_0/probe173 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsrfull}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe174]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe174]
connect_debug_port u_ila_0/probe174 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txhrfull}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe175]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe175]
connect_debug_port u_ila_0/probe175 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifofull}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe176]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe176]
connect_debug_port u_ila_0/probe176 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifoempty}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe177]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe177]
connect_debug_port u_ila_0/probe177 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifotail[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifotail[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifotail[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifotail[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe178]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe178]
connect_debug_port u_ila_0/probe178 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifohead[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifohead[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifohead[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txfifohead[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe179]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe179]
connect_debug_port u_ila_0/probe179 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[10]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/txsr[11]}]]

create_debug_port u_ila_0 probe
set_property port_width 7 [get_debug_ports u_ila_0/probe180]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe180]
connect_debug_port u_ila_0/probe180 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxtimeoutcnt[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxtimeoutcnt[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxtimeoutcnt[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxtimeoutcnt[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxtimeoutcnt[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxtimeoutcnt[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxtimeoutcnt[6]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe181]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe181]
connect_debug_port u_ila_0/probe181 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifotimeout}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe182]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe182]
connect_debug_port u_ila_0/probe182 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoempty}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe183]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe183]
connect_debug_port u_ila_0/probe183 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifotriggered}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe184]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe184]
connect_debug_port u_ila_0/probe184 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxbaudpulse}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe185]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe185]
connect_debug_port u_ila_0/probe185 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifohead[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifohead[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifohead[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifohead[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe186]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe186]
connect_debug_port u_ila_0/probe186 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifotail[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifotail[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifotail[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifotail[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe187]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe187]
connect_debug_port u_ila_0/probe187 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoentries[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoentries[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoentries[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifoentries[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe188]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe188]
connect_debug_port u_ila_0/probe188 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/intrID[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/intrID[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/intrID[2]}]]

create_debug_port u_ila_0 probe
set_property port_width 31 [get_debug_ports u_ila_0/probe189]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe189]
connect_debug_port u_ila_0/probe189 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[10]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[11]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[12]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[13]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[14]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[15]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[16]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[17]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[18]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[19]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[20]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[21]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[22]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[23]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[24]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[25]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[26]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[27]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[28]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[29]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbitunwrapped[30]}]]

create_debug_port u_ila_0 probe
set_property port_width 16 [get_debug_ports u_ila_0/probe190]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe190]
connect_debug_port u_ila_0/probe190 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[10]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[11]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[12]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[13]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[14]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfullbit[15]}]]

create_debug_port u_ila_0 probe
set_property port_width 16 [get_debug_ports u_ila_0/probe191]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe191]
connect_debug_port u_ila_0/probe191 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[10]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[11]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[12]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[13]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[14]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXerrbit[15]}]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe192]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe192]
connect_debug_port u_ila_0/probe192 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdata[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdata[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdata[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdata[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdata[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdata[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdata[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxdata[7]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe193]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe193]
connect_debug_port u_ila_0/probe193 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifohaserr}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe194]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe194]
connect_debug_port u_ila_0/probe194 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifohaserr}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe195]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe195]
connect_debug_port u_ila_0/probe195 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxoverrunerr}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe196]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe196]
connect_debug_port u_ila_0/probe196 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxframingerr}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe197]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe197]
connect_debug_port u_ila_0/probe197 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxparityerr}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe198]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe198]
connect_debug_port u_ila_0/probe198 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[0]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe199]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe199]
connect_debug_port u_ila_0/probe199 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[1]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe200]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe200]
connect_debug_port u_ila_0/probe200 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[2]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe201]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe201]
connect_debug_port u_ila_0/probe201 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[3]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe202]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe202]
connect_debug_port u_ila_0/probe202 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[4]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe203]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe203]
connect_debug_port u_ila_0/probe203 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[5]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe204]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe204]
connect_debug_port u_ila_0/probe204 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[6]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe205]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe205]
connect_debug_port u_ila_0/probe205 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[7]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe206]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe206]
connect_debug_port u_ila_0/probe206 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[8]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe207]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe207]
connect_debug_port u_ila_0/probe207 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[9]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 11 [get_debug_ports u_ila_0/probe208]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe208]
connect_debug_port u_ila_0/probe208 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[0]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[1]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[2]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[3]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[4]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[5]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[6]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[7]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[8]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[9]} {wallypipelinedsoc/uncore.uncore/uart.uart/u/rxfifo[10]__0[10]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe209]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe209]
connect_debug_port u_ila_0/probe209 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/MEMRb}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe210]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe210]
connect_debug_port u_ila_0/probe210 [get_nets [list {wallypipelinedsoc/uncore.uncore/uart.uart/u/RXRDYb}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe211]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe211]
connect_debug_port u_ila_0/probe211 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/requests[1]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[2]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[3]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[4]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[5]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[6]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[7]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[8]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[9]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[10]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[11]} {wallypipelinedsoc/uncore.uncore/plic.plic/requests[12]}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe212]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe212]
connect_debug_port u_ila_0/probe212 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[1]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[2]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[3]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[4]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[5]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[6]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[7]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[8]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[9]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[10]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[11]} {wallypipelinedsoc/uncore.uncore/plic.plic/intInProgress[12]}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe213]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe213]
connect_debug_port u_ila_0/probe213 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[1]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[2]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[3]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[4]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[5]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[6]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[7]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[8]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[9]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[10]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[11]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPending[12]}]]

create_debug_port u_ila_0 probe
set_property port_width 70 [get_debug_ports u_ila_0/probe214]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe214]
connect_debug_port u_ila_0/probe214 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][1][10]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][2][10]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][3][10]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][4][10]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][5][10]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][6][10]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqMatrix[1][7][10]} ]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe215]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe215]
connect_debug_port u_ila_0/probe215 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/intPriority[10][0]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPriority[10][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/intPriority[10][2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 10 [get_debug_ports u_ila_0/probe216]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe216]
connect_debug_port u_ila_0/probe216 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[1]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[2]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[3]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[4]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[5]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[6]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[7]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[8]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[9]} {wallypipelinedsoc/uncore.uncore/plic.plic/intEn[1]__0[10]} ]]

create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe217]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe217]
connect_debug_port u_ila_0/probe217 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[0][0]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[0][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[0][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[0][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[0][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[0][5]} ]]

create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe218]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe218]
connect_debug_port u_ila_0/probe218 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[1][0]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[1][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[1][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[1][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[1][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/intClaim[1][5]} ]]

create_debug_port u_ila_0 probe
set_property port_width 7 [get_debug_ports u_ila_0/probe219]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe219]
connect_debug_port u_ila_0/probe219 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[0][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[0][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[0][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[0][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[0][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[0][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[0][7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 7 [get_debug_ports u_ila_0/probe220]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe220]
connect_debug_port u_ila_0/probe220 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[1][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[1][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[1][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[1][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[1][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[1][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/priorities_with_irqs[1][7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe221]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe221]
connect_debug_port u_ila_0/probe221 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/intThreshold[0]__0[0]} {wallypipelinedsoc/uncore.uncore/plic.plic/intThreshold[0]__0[1]} {wallypipelinedsoc/uncore.uncore/plic.plic/intThreshold[0]__0[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe222]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe222]
connect_debug_port u_ila_0/probe222 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/intThreshold[1]__0[0]} {wallypipelinedsoc/uncore.uncore/plic.plic/intThreshold[1]__0[1]} {wallypipelinedsoc/uncore.uncore/plic.plic/intThreshold[1]__0[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 53 [get_debug_ports u_ila_0/probe223]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe223]
connect_debug_port u_ila_0/probe223 [get_nets [list {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][1]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][2]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][3]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][4]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][5]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][6]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][7]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][8]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][9]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][10]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][11]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][12]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][13]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][14]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][15]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][16]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][17]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][18]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][19]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][20]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][21]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][22]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][23]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][24]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][25]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][26]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][27]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][28]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][29]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][30]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][31]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][32]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][33]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][34]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][35]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][36]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][37]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][38]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][39]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][40]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][41]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][42]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][43]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][44]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][45]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][46]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][47]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][48]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][49]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][50]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][51]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][52]} {wallypipelinedsoc/uncore.uncore/plic.plic/irqs_at_max_priority[1][53]} ]]

