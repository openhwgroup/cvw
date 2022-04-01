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
connect_debug_port u_ila_0/probe0 [get_nets [list {wallypipelinedsoc/core/lsu/LSUBusHWDATA[0]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[1]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[2]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[3]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[4]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[5]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[6]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[7]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[8]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[9]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[10]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[11]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[12]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[13]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[14]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[15]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[16]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[17]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[18]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[19]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[20]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[21]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[22]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[23]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[24]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[25]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[26]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[27]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[28]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[29]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[30]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[31]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[32]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[33]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[34]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[35]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[36]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[37]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[38]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[39]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[40]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[41]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[42]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[43]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[44]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[45]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[46]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[47]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[48]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[49]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[50]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[51]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[52]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[53]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[54]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[55]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[56]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[57]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[58]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[59]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[60]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[61]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[62]} {wallypipelinedsoc/core/lsu/LSUBusHWDATA[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {wallypipelinedsoc/core/lsu/LSUBusHRDATA[0]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[1]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[2]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[3]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[4]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[5]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[6]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[7]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[8]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[9]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[10]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[11]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[12]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[13]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[14]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[15]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[16]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[17]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[18]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[19]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[20]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[21]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[22]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[23]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[24]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[25]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[26]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[27]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[28]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[29]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[30]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[31]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[32]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[33]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[34]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[35]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[36]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[37]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[38]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[39]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[40]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[41]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[42]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[43]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[44]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[45]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[46]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[47]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[48]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[49]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[50]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[51]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[52]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[53]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[54]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[55]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[56]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[57]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[58]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[59]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[60]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[61]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[62]} {wallypipelinedsoc/core/lsu/LSUBusHRDATA[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {wallypipelinedsoc/core/lsu/LSUBusAdr[0]} {wallypipelinedsoc/core/lsu/LSUBusAdr[1]} {wallypipelinedsoc/core/lsu/LSUBusAdr[2]} {wallypipelinedsoc/core/lsu/LSUBusAdr[3]} {wallypipelinedsoc/core/lsu/LSUBusAdr[4]} {wallypipelinedsoc/core/lsu/LSUBusAdr[5]} {wallypipelinedsoc/core/lsu/LSUBusAdr[6]} {wallypipelinedsoc/core/lsu/LSUBusAdr[7]} {wallypipelinedsoc/core/lsu/LSUBusAdr[8]} {wallypipelinedsoc/core/lsu/LSUBusAdr[9]} {wallypipelinedsoc/core/lsu/LSUBusAdr[10]} {wallypipelinedsoc/core/lsu/LSUBusAdr[11]} {wallypipelinedsoc/core/lsu/LSUBusAdr[12]} {wallypipelinedsoc/core/lsu/LSUBusAdr[13]} {wallypipelinedsoc/core/lsu/LSUBusAdr[14]} {wallypipelinedsoc/core/lsu/LSUBusAdr[15]} {wallypipelinedsoc/core/lsu/LSUBusAdr[16]} {wallypipelinedsoc/core/lsu/LSUBusAdr[17]} {wallypipelinedsoc/core/lsu/LSUBusAdr[18]} {wallypipelinedsoc/core/lsu/LSUBusAdr[19]} {wallypipelinedsoc/core/lsu/LSUBusAdr[20]} {wallypipelinedsoc/core/lsu/LSUBusAdr[21]} {wallypipelinedsoc/core/lsu/LSUBusAdr[22]} {wallypipelinedsoc/core/lsu/LSUBusAdr[23]} {wallypipelinedsoc/core/lsu/LSUBusAdr[24]} {wallypipelinedsoc/core/lsu/LSUBusAdr[25]} {wallypipelinedsoc/core/lsu/LSUBusAdr[26]} {wallypipelinedsoc/core/lsu/LSUBusAdr[27]} {wallypipelinedsoc/core/lsu/LSUBusAdr[28]} {wallypipelinedsoc/core/lsu/LSUBusAdr[29]} {wallypipelinedsoc/core/lsu/LSUBusAdr[30]} {wallypipelinedsoc/core/lsu/LSUBusAdr[31]} ]]
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
connect_debug_port u_ila_0/probe5 [get_nets [list {wallypipelinedsoc/core/ReadDataM[0]} {wallypipelinedsoc/core/ReadDataM[1]} {wallypipelinedsoc/core/ReadDataM[2]} {wallypipelinedsoc/core/ReadDataM[3]} {wallypipelinedsoc/core/ReadDataM[4]} {wallypipelinedsoc/core/ReadDataM[5]} {wallypipelinedsoc/core/ReadDataM[6]} {wallypipelinedsoc/core/ReadDataM[7]} {wallypipelinedsoc/core/ReadDataM[8]} {wallypipelinedsoc/core/ReadDataM[9]} {wallypipelinedsoc/core/ReadDataM[10]} {wallypipelinedsoc/core/ReadDataM[11]} {wallypipelinedsoc/core/ReadDataM[12]} {wallypipelinedsoc/core/ReadDataM[13]} {wallypipelinedsoc/core/ReadDataM[14]} {wallypipelinedsoc/core/ReadDataM[15]} {wallypipelinedsoc/core/ReadDataM[16]} {wallypipelinedsoc/core/ReadDataM[17]} {wallypipelinedsoc/core/ReadDataM[18]} {wallypipelinedsoc/core/ReadDataM[19]} {wallypipelinedsoc/core/ReadDataM[20]} {wallypipelinedsoc/core/ReadDataM[21]} {wallypipelinedsoc/core/ReadDataM[22]} {wallypipelinedsoc/core/ReadDataM[23]} {wallypipelinedsoc/core/ReadDataM[24]} {wallypipelinedsoc/core/ReadDataM[25]} {wallypipelinedsoc/core/ReadDataM[26]} {wallypipelinedsoc/core/ReadDataM[27]} {wallypipelinedsoc/core/ReadDataM[28]} {wallypipelinedsoc/core/ReadDataM[29]} {wallypipelinedsoc/core/ReadDataM[30]} {wallypipelinedsoc/core/ReadDataM[31]} {wallypipelinedsoc/core/ReadDataM[32]} {wallypipelinedsoc/core/ReadDataM[33]} {wallypipelinedsoc/core/ReadDataM[34]} {wallypipelinedsoc/core/ReadDataM[35]} {wallypipelinedsoc/core/ReadDataM[36]} {wallypipelinedsoc/core/ReadDataM[37]} {wallypipelinedsoc/core/ReadDataM[38]} {wallypipelinedsoc/core/ReadDataM[39]} {wallypipelinedsoc/core/ReadDataM[40]} {wallypipelinedsoc/core/ReadDataM[41]} {wallypipelinedsoc/core/ReadDataM[42]} {wallypipelinedsoc/core/ReadDataM[43]} {wallypipelinedsoc/core/ReadDataM[44]} {wallypipelinedsoc/core/ReadDataM[45]} {wallypipelinedsoc/core/ReadDataM[46]} {wallypipelinedsoc/core/ReadDataM[47]} {wallypipelinedsoc/core/ReadDataM[48]} {wallypipelinedsoc/core/ReadDataM[49]} {wallypipelinedsoc/core/ReadDataM[50]} {wallypipelinedsoc/core/ReadDataM[51]} {wallypipelinedsoc/core/ReadDataM[52]} {wallypipelinedsoc/core/ReadDataM[53]} {wallypipelinedsoc/core/ReadDataM[54]} {wallypipelinedsoc/core/ReadDataM[55]} {wallypipelinedsoc/core/ReadDataM[56]} {wallypipelinedsoc/core/ReadDataM[57]} {wallypipelinedsoc/core/ReadDataM[58]} {wallypipelinedsoc/core/ReadDataM[59]} {wallypipelinedsoc/core/ReadDataM[60]} {wallypipelinedsoc/core/ReadDataM[61]} {wallypipelinedsoc/core/ReadDataM[62]} {wallypipelinedsoc/core/ReadDataM[63]} ]]
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
set_property port_width 4 [get_debug_ports u_ila_0/probe17]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {wallypipelinedsoc/core/lsu/bus.dcache.dcache/cachefsm/CurrState[0]} {wallypipelinedsoc/core/lsu/bus.dcache.dcache/cachefsm/CurrState[1]} {wallypipelinedsoc/core/lsu/bus.dcache.dcache/cachefsm/CurrState[2]} {wallypipelinedsoc/core/lsu/bus.dcache.dcache/cachefsm/CurrState[3]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe18]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrs/SEPC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe19]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SCAUSE_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe20]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[0]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[1]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[2]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[3]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[4]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[5]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[6]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[7]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[8]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[9]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[10]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[11]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[12]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[13]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[14]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[15]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[16]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[17]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[18]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[19]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[20]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[21]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[22]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[23]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[24]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[25]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[26]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[27]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[28]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[29]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[30]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[31]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[32]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[33]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[34]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[35]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[36]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[37]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[38]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[39]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[40]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[41]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[42]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[43]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[44]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[45]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[46]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[47]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[48]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[49]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[50]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[51]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[52]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[53]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[54]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[55]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[56]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[57]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[58]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[59]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[60]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[61]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[62]} {wallypipelinedsoc/core/priv.priv/trap/SEPC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe21]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/SIP_REGW[1]} {wallypipelinedsoc/core/priv.priv/trap/SIP_REGW[5]} {wallypipelinedsoc/core/priv.priv/trap/SIP_REGW[9]} ]]
create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe22]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/SIE_REGW[1]} {wallypipelinedsoc/core/priv.priv/trap/SIE_REGW[5]} {wallypipelinedsoc/core/priv.priv/trap/SIE_REGW[9]} ]]
create_debug_port u_ila_0 probe
set_property port_width 63 [get_debug_ports u_ila_0/probe23]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[0]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[2]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[3]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[4]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[5]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[6]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[7]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[8]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[9]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[10]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[11]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[12]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[13]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[14]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[15]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[16]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[17]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[18]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[19]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[20]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[21]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[22]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[23]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[24]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[25]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[26]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[27]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[28]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[29]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[30]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[31]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[32]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[33]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[34]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[35]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[36]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[37]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[38]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[39]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[40]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[41]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[42]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[43]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[44]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[45]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[46]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[47]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[48]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[49]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[50]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[51]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[52]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[53]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[54]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[55]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[56]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[57]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[58]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[59]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[60]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[61]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[62]} {wallypipelinedsoc/core/priv.priv/trap/STVEC_REGW[63]} ]]
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
connect_debug_port u_ila_0/probe26 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[0]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[1]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[2]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[3]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[4]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[5]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[6]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[7]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[8]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[9]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[10]} {wallypipelinedsoc/core/priv.priv/trap/MPendingIntsM[11]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe27]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[0]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[1]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[2]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[3]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[4]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[5]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[6]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[7]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[8]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[9]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[10]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[11]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[12]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[13]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[14]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[15]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[16]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[17]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[18]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[19]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[20]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[21]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[22]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[23]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[24]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[25]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[26]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[27]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[28]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[29]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[30]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[31]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[32]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[33]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[34]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[35]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[36]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[37]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[38]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[39]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[40]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[41]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[42]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[43]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[44]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[45]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[46]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[47]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[48]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[49]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[50]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[51]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[52]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[53]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[54]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[55]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[56]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[57]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[58]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[59]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[60]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[61]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[62]} {wallypipelinedsoc/core/priv.priv/trap/MEPC_REGW[63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe28]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[1]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[3]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[5]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[7]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[9]} {wallypipelinedsoc/core/priv.priv/trap/MIE_REGW[11]} ]]
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
connect_debug_port u_ila_0/probe31 [get_nets [list {wallypipelinedsoc/core/lsu/LSUBusSize[0]} {wallypipelinedsoc/core/lsu/LSUBusSize[1]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe32]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe32]
connect_debug_port u_ila_0/probe32 [get_nets [list wallypipelinedsoc/core/lsu/LSUBusAck ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe33]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe33]
connect_debug_port u_ila_0/probe33 [get_nets [list wallypipelinedsoc/core/lsu/LSUBusRead ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe34]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe34]
connect_debug_port u_ila_0/probe34 [get_nets [list wallypipelinedsoc/core/lsu/LSUBusWrite ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe35]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe35]
connect_debug_port u_ila_0/probe35 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/BreakpointFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe36]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe36]
connect_debug_port u_ila_0/probe36 [get_nets [list wallypipelinedsoc/uncore/uart.uart/DTRb ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe37]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe37]
connect_debug_port u_ila_0/probe37 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/EcallFaultM ]]
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
connect_debug_port u_ila_0/probe42 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/IllegalInstrFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe43]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe43]
connect_debug_port u_ila_0/probe43 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/InstrAccessFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe44]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe44]
connect_debug_port u_ila_0/probe44 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/InstrPageFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe45]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe45]
connect_debug_port u_ila_0/probe45 [get_nets [list wallypipelinedsoc/core/InstrValidM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe46]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe46]
connect_debug_port u_ila_0/probe46 [get_nets [list wallypipelinedsoc/uncore/uart.uart/INTR ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe47]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe47]
connect_debug_port u_ila_0/probe47 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/LoadAccessFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe48]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe48]
connect_debug_port u_ila_0/probe48 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/LoadMisalignedFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe49]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe49]
connect_debug_port u_ila_0/probe49 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/LoadPageFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe50]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe50]
connect_debug_port u_ila_0/probe50 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/mretM ]]
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
connect_debug_port u_ila_0/probe63 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/sretM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe64]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe64]
connect_debug_port u_ila_0/probe64 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/StoreAmoAccessFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe65]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe65]
connect_debug_port u_ila_0/probe65 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/StoreAmoMisalignedFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe66]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe66]
connect_debug_port u_ila_0/probe66 [get_nets [list wallypipelinedsoc/core/priv.priv/trap/StoreAmoPageFaultM ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe67]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe67]
connect_debug_port u_ila_0/probe67 [get_nets [list wallypipelinedsoc/core/TrapM ]]
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
connect_debug_port u_ila_0/probe72 [get_nets [list wallypipelinedsoc/core/hzu/BPPredWrongE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe73]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe73]
connect_debug_port u_ila_0/probe73 [get_nets [list wallypipelinedsoc/core/hzu/CSRWritePendingDEM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe74]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe74]
connect_debug_port u_ila_0/probe74 [get_nets [list wallypipelinedsoc/core/hzu/RetM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe75]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe75]
connect_debug_port u_ila_0/probe75 [get_nets [list wallypipelinedsoc/core/hzu/TrapM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe76]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe76]
connect_debug_port u_ila_0/probe76 [get_nets [list wallypipelinedsoc/core/hzu/LoadStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe77]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe77]
connect_debug_port u_ila_0/probe77 [get_nets [list wallypipelinedsoc/core/hzu/StoreStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe78]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe78]
connect_debug_port u_ila_0/probe78 [get_nets [list wallypipelinedsoc/core/hzu/MDUStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe79]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe79]
connect_debug_port u_ila_0/probe79 [get_nets [list wallypipelinedsoc/core/hzu/CSRRdStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe80]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe80]
connect_debug_port u_ila_0/probe80 [get_nets [list wallypipelinedsoc/core/hzu/LSUStallM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe81]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe81]
connect_debug_port u_ila_0/probe81 [get_nets [list wallypipelinedsoc/core/hzu/IFUStallF ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe82]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe82]
connect_debug_port u_ila_0/probe82 [get_nets [list wallypipelinedsoc/core/hzu/FPUStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe83]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe83]
connect_debug_port u_ila_0/probe83 [get_nets [list wallypipelinedsoc/core/hzu/FStallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe84]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe84]
connect_debug_port u_ila_0/probe84 [get_nets [list wallypipelinedsoc/core/hzu/DivBusyE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe85]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe85]
connect_debug_port u_ila_0/probe85 [get_nets [list wallypipelinedsoc/core/hzu/FDivBusyE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe86]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe86]
connect_debug_port u_ila_0/probe86 [get_nets [list wallypipelinedsoc/core/hzu/EcallFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe87]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe87]
connect_debug_port u_ila_0/probe87 [get_nets [list wallypipelinedsoc/core/hzu/BreakpointFaultM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe88]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe88]
connect_debug_port u_ila_0/probe88 [get_nets [list wallypipelinedsoc/core/hzu/InvalidateICacheM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe89]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe89]
connect_debug_port u_ila_0/probe89 [get_nets [list wallypipelinedsoc/core/hzu/StallF ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe90]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe90]
connect_debug_port u_ila_0/probe90 [get_nets [list wallypipelinedsoc/core/hzu/StallD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe91]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe91]
connect_debug_port u_ila_0/probe91 [get_nets [list wallypipelinedsoc/core/hzu/StallE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe92]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe92]
connect_debug_port u_ila_0/probe92 [get_nets [list wallypipelinedsoc/core/hzu/StallM ]]

# StallW is StallM.  trying to connect to StallW causes issues.
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe93]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe93]
connect_debug_port u_ila_0/probe93 [get_nets [list wallypipelinedsoc/core/hzu/StallM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe94]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe94]
connect_debug_port u_ila_0/probe94 [get_nets [list wallypipelinedsoc/core/hzu/FlushF ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe95]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe95]
connect_debug_port u_ila_0/probe95 [get_nets [list wallypipelinedsoc/core/hzu/FlushD ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe96]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe96]
connect_debug_port u_ila_0/probe96 [get_nets [list wallypipelinedsoc/core/hzu/FlushE ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe97]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe97]
connect_debug_port u_ila_0/probe97 [get_nets [list wallypipelinedsoc/core/hzu/FlushM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe98]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe98]
connect_debug_port u_ila_0/probe98 [get_nets [list wallypipelinedsoc/core/hzu/FlushW ]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe99]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe99]
connect_debug_port u_ila_0/probe99 [get_nets [list {wallypipelinedsoc/core/ifu/bus.icache.icache/cachefsm/CurrState[0]} {wallypipelinedsoc/core/ifu/bus.icache.icache/cachefsm/CurrState[1]} {wallypipelinedsoc/core/ifu/bus.icache.icache/cachefsm/CurrState[2]} {wallypipelinedsoc/core/ifu/bus.icache.icache/cachefsm/CurrState[3]}]]


create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe100]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe100]
connect_debug_port u_ila_0/probe100 [get_nets [list {wallypipelinedsoc/core/ifu/IFUBusHRDATA[0]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[1]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[2]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[3]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[4]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[5]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[6]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[7]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[8]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[9]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[10]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[11]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[12]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[13]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[14]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[15]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[16]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[17]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[18]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[19]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[20]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[21]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[22]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[23]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[24]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[25]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[26]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[27]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[28]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[29]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[30]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[31]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[32]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[33]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[34]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[35]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[36]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[37]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[38]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[39]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[40]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[41]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[42]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[43]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[44]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[45]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[46]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[47]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[48]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[49]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[50]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[51]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[52]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[53]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[54]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[55]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[56]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[57]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[58]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[59]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[60]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[61]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[62]} {wallypipelinedsoc/core/ifu/IFUBusHRDATA[63]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe101]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe101]
connect_debug_port u_ila_0/probe101 [get_nets [list wallypipelinedsoc/core/ifu/IFUBusAck ]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe102]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe102]
connect_debug_port u_ila_0/probe102 [get_nets [list {wallypipelinedsoc/core/ifu/IFUBusAdr[0]} {wallypipelinedsoc/core/ifu/IFUBusAdr[1]} {wallypipelinedsoc/core/ifu/IFUBusAdr[2]} {wallypipelinedsoc/core/ifu/IFUBusAdr[3]} {wallypipelinedsoc/core/ifu/IFUBusAdr[4]} {wallypipelinedsoc/core/ifu/IFUBusAdr[5]} {wallypipelinedsoc/core/ifu/IFUBusAdr[6]} {wallypipelinedsoc/core/ifu/IFUBusAdr[7]} {wallypipelinedsoc/core/ifu/IFUBusAdr[8]} {wallypipelinedsoc/core/ifu/IFUBusAdr[9]} {wallypipelinedsoc/core/ifu/IFUBusAdr[10]} {wallypipelinedsoc/core/ifu/IFUBusAdr[11]} {wallypipelinedsoc/core/ifu/IFUBusAdr[12]} {wallypipelinedsoc/core/ifu/IFUBusAdr[13]} {wallypipelinedsoc/core/ifu/IFUBusAdr[14]} {wallypipelinedsoc/core/ifu/IFUBusAdr[15]} {wallypipelinedsoc/core/ifu/IFUBusAdr[16]} {wallypipelinedsoc/core/ifu/IFUBusAdr[17]} {wallypipelinedsoc/core/ifu/IFUBusAdr[18]} {wallypipelinedsoc/core/ifu/IFUBusAdr[19]} {wallypipelinedsoc/core/ifu/IFUBusAdr[20]} {wallypipelinedsoc/core/ifu/IFUBusAdr[21]} {wallypipelinedsoc/core/ifu/IFUBusAdr[22]} {wallypipelinedsoc/core/ifu/IFUBusAdr[23]} {wallypipelinedsoc/core/ifu/IFUBusAdr[24]} {wallypipelinedsoc/core/ifu/IFUBusAdr[25]} {wallypipelinedsoc/core/ifu/IFUBusAdr[26]} {wallypipelinedsoc/core/ifu/IFUBusAdr[27]} {wallypipelinedsoc/core/ifu/IFUBusAdr[28]} {wallypipelinedsoc/core/ifu/IFUBusAdr[29]} {wallypipelinedsoc/core/ifu/IFUBusAdr[30]} {wallypipelinedsoc/core/ifu/IFUBusAdr[31]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe103]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe103]
connect_debug_port u_ila_0/probe103 [get_nets [list wallypipelinedsoc/core/ifu/IFUBusRead ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe104]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe104]
connect_debug_port u_ila_0/probe104 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/counters/counters.INSTRET_REGW[63]}]]


create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe105]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe105]
connect_debug_port u_ila_0/probe105 [get_nets [list {wallypipelinedsoc/core/ebu/HRDATA[0]} {wallypipelinedsoc/core/ebu/HRDATA[1]} {wallypipelinedsoc/core/ebu/HRDATA[2]} {wallypipelinedsoc/core/ebu/HRDATA[3]} {wallypipelinedsoc/core/ebu/HRDATA[4]} {wallypipelinedsoc/core/ebu/HRDATA[5]} {wallypipelinedsoc/core/ebu/HRDATA[6]} {wallypipelinedsoc/core/ebu/HRDATA[7]} {wallypipelinedsoc/core/ebu/HRDATA[8]} {wallypipelinedsoc/core/ebu/HRDATA[9]} {wallypipelinedsoc/core/ebu/HRDATA[10]} {wallypipelinedsoc/core/ebu/HRDATA[11]} {wallypipelinedsoc/core/ebu/HRDATA[12]} {wallypipelinedsoc/core/ebu/HRDATA[13]} {wallypipelinedsoc/core/ebu/HRDATA[14]} {wallypipelinedsoc/core/ebu/HRDATA[15]} {wallypipelinedsoc/core/ebu/HRDATA[16]} {wallypipelinedsoc/core/ebu/HRDATA[17]} {wallypipelinedsoc/core/ebu/HRDATA[18]} {wallypipelinedsoc/core/ebu/HRDATA[19]} {wallypipelinedsoc/core/ebu/HRDATA[20]} {wallypipelinedsoc/core/ebu/HRDATA[21]} {wallypipelinedsoc/core/ebu/HRDATA[22]} {wallypipelinedsoc/core/ebu/HRDATA[23]} {wallypipelinedsoc/core/ebu/HRDATA[24]} {wallypipelinedsoc/core/ebu/HRDATA[25]} {wallypipelinedsoc/core/ebu/HRDATA[26]} {wallypipelinedsoc/core/ebu/HRDATA[27]} {wallypipelinedsoc/core/ebu/HRDATA[28]} {wallypipelinedsoc/core/ebu/HRDATA[29]} {wallypipelinedsoc/core/ebu/HRDATA[30]} {wallypipelinedsoc/core/ebu/HRDATA[31]} {wallypipelinedsoc/core/ebu/HRDATA[32]} {wallypipelinedsoc/core/ebu/HRDATA[33]} {wallypipelinedsoc/core/ebu/HRDATA[34]} {wallypipelinedsoc/core/ebu/HRDATA[35]} {wallypipelinedsoc/core/ebu/HRDATA[36]} {wallypipelinedsoc/core/ebu/HRDATA[37]} {wallypipelinedsoc/core/ebu/HRDATA[38]} {wallypipelinedsoc/core/ebu/HRDATA[39]} {wallypipelinedsoc/core/ebu/HRDATA[40]} {wallypipelinedsoc/core/ebu/HRDATA[41]} {wallypipelinedsoc/core/ebu/HRDATA[42]} {wallypipelinedsoc/core/ebu/HRDATA[43]} {wallypipelinedsoc/core/ebu/HRDATA[44]} {wallypipelinedsoc/core/ebu/HRDATA[45]} {wallypipelinedsoc/core/ebu/HRDATA[46]} {wallypipelinedsoc/core/ebu/HRDATA[47]} {wallypipelinedsoc/core/ebu/HRDATA[48]} {wallypipelinedsoc/core/ebu/HRDATA[49]} {wallypipelinedsoc/core/ebu/HRDATA[50]} {wallypipelinedsoc/core/ebu/HRDATA[51]} {wallypipelinedsoc/core/ebu/HRDATA[52]} {wallypipelinedsoc/core/ebu/HRDATA[53]} {wallypipelinedsoc/core/ebu/HRDATA[54]} {wallypipelinedsoc/core/ebu/HRDATA[55]} {wallypipelinedsoc/core/ebu/HRDATA[56]} {wallypipelinedsoc/core/ebu/HRDATA[57]} {wallypipelinedsoc/core/ebu/HRDATA[58]} {wallypipelinedsoc/core/ebu/HRDATA[59]} {wallypipelinedsoc/core/ebu/HRDATA[60]} {wallypipelinedsoc/core/ebu/HRDATA[61]} {wallypipelinedsoc/core/ebu/HRDATA[62]} {wallypipelinedsoc/core/ebu/HRDATA[63]}]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe106]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe106]
connect_debug_port u_ila_0/probe106 [get_nets [list {wallypipelinedsoc/core/ebu/HWDATA[0]} {wallypipelinedsoc/core/ebu/HWDATA[1]} {wallypipelinedsoc/core/ebu/HWDATA[2]} {wallypipelinedsoc/core/ebu/HWDATA[3]} {wallypipelinedsoc/core/ebu/HWDATA[4]} {wallypipelinedsoc/core/ebu/HWDATA[5]} {wallypipelinedsoc/core/ebu/HWDATA[6]} {wallypipelinedsoc/core/ebu/HWDATA[7]} {wallypipelinedsoc/core/ebu/HWDATA[8]} {wallypipelinedsoc/core/ebu/HWDATA[9]} {wallypipelinedsoc/core/ebu/HWDATA[10]} {wallypipelinedsoc/core/ebu/HWDATA[11]} {wallypipelinedsoc/core/ebu/HWDATA[12]} {wallypipelinedsoc/core/ebu/HWDATA[13]} {wallypipelinedsoc/core/ebu/HWDATA[14]} {wallypipelinedsoc/core/ebu/HWDATA[15]} {wallypipelinedsoc/core/ebu/HWDATA[16]} {wallypipelinedsoc/core/ebu/HWDATA[17]} {wallypipelinedsoc/core/ebu/HWDATA[18]} {wallypipelinedsoc/core/ebu/HWDATA[19]} {wallypipelinedsoc/core/ebu/HWDATA[20]} {wallypipelinedsoc/core/ebu/HWDATA[21]} {wallypipelinedsoc/core/ebu/HWDATA[22]} {wallypipelinedsoc/core/ebu/HWDATA[23]} {wallypipelinedsoc/core/ebu/HWDATA[24]} {wallypipelinedsoc/core/ebu/HWDATA[25]} {wallypipelinedsoc/core/ebu/HWDATA[26]} {wallypipelinedsoc/core/ebu/HWDATA[27]} {wallypipelinedsoc/core/ebu/HWDATA[28]} {wallypipelinedsoc/core/ebu/HWDATA[29]} {wallypipelinedsoc/core/ebu/HWDATA[30]} {wallypipelinedsoc/core/ebu/HWDATA[31]} {wallypipelinedsoc/core/ebu/HWDATA[32]} {wallypipelinedsoc/core/ebu/HWDATA[33]} {wallypipelinedsoc/core/ebu/HWDATA[34]} {wallypipelinedsoc/core/ebu/HWDATA[35]} {wallypipelinedsoc/core/ebu/HWDATA[36]} {wallypipelinedsoc/core/ebu/HWDATA[37]} {wallypipelinedsoc/core/ebu/HWDATA[38]} {wallypipelinedsoc/core/ebu/HWDATA[39]} {wallypipelinedsoc/core/ebu/HWDATA[40]} {wallypipelinedsoc/core/ebu/HWDATA[41]} {wallypipelinedsoc/core/ebu/HWDATA[42]} {wallypipelinedsoc/core/ebu/HWDATA[43]} {wallypipelinedsoc/core/ebu/HWDATA[44]} {wallypipelinedsoc/core/ebu/HWDATA[45]} {wallypipelinedsoc/core/ebu/HWDATA[46]} {wallypipelinedsoc/core/ebu/HWDATA[47]} {wallypipelinedsoc/core/ebu/HWDATA[48]} {wallypipelinedsoc/core/ebu/HWDATA[49]} {wallypipelinedsoc/core/ebu/HWDATA[50]} {wallypipelinedsoc/core/ebu/HWDATA[51]} {wallypipelinedsoc/core/ebu/HWDATA[52]} {wallypipelinedsoc/core/ebu/HWDATA[53]} {wallypipelinedsoc/core/ebu/HWDATA[54]} {wallypipelinedsoc/core/ebu/HWDATA[55]} {wallypipelinedsoc/core/ebu/HWDATA[56]} {wallypipelinedsoc/core/ebu/HWDATA[57]} {wallypipelinedsoc/core/ebu/HWDATA[58]} {wallypipelinedsoc/core/ebu/HWDATA[59]} {wallypipelinedsoc/core/ebu/HWDATA[60]} {wallypipelinedsoc/core/ebu/HWDATA[61]} {wallypipelinedsoc/core/ebu/HWDATA[62]} {wallypipelinedsoc/core/ebu/HWDATA[63]}]]


create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe107]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe107]
connect_debug_port u_ila_0/probe107 [get_nets [list {wallypipelinedsoc/core/ebu/HADDR[0]} {wallypipelinedsoc/core/ebu/HADDR[1]} {wallypipelinedsoc/core/ebu/HADDR[2]} {wallypipelinedsoc/core/ebu/HADDR[3]} {wallypipelinedsoc/core/ebu/HADDR[4]} {wallypipelinedsoc/core/ebu/HADDR[5]} {wallypipelinedsoc/core/ebu/HADDR[6]} {wallypipelinedsoc/core/ebu/HADDR[7]} {wallypipelinedsoc/core/ebu/HADDR[8]} {wallypipelinedsoc/core/ebu/HADDR[9]} {wallypipelinedsoc/core/ebu/HADDR[10]} {wallypipelinedsoc/core/ebu/HADDR[11]} {wallypipelinedsoc/core/ebu/HADDR[12]} {wallypipelinedsoc/core/ebu/HADDR[13]} {wallypipelinedsoc/core/ebu/HADDR[14]} {wallypipelinedsoc/core/ebu/HADDR[15]} {wallypipelinedsoc/core/ebu/HADDR[16]} {wallypipelinedsoc/core/ebu/HADDR[17]} {wallypipelinedsoc/core/ebu/HADDR[18]} {wallypipelinedsoc/core/ebu/HADDR[19]} {wallypipelinedsoc/core/ebu/HADDR[20]} {wallypipelinedsoc/core/ebu/HADDR[21]} {wallypipelinedsoc/core/ebu/HADDR[22]} {wallypipelinedsoc/core/ebu/HADDR[23]} {wallypipelinedsoc/core/ebu/HADDR[24]} {wallypipelinedsoc/core/ebu/HADDR[25]} {wallypipelinedsoc/core/ebu/HADDR[26]} {wallypipelinedsoc/core/ebu/HADDR[27]} {wallypipelinedsoc/core/ebu/HADDR[28]} {wallypipelinedsoc/core/ebu/HADDR[29]} {wallypipelinedsoc/core/ebu/HADDR[30]} {wallypipelinedsoc/core/ebu/HADDR[31]}]]


create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe108]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe108]
connect_debug_port u_ila_0/probe108 [get_nets [list {wallypipelinedsoc/core/ebu/HREADY}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe109]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe109]
connect_debug_port u_ila_0/probe109 [get_nets [list {wallypipelinedsoc/core/ebu/HRESP}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe110]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe110]
connect_debug_port u_ila_0/probe110 [get_nets [list {wallypipelinedsoc/core/ebu/HWRITE}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe111]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe111]
connect_debug_port u_ila_0/probe111 [get_nets [list {wallypipelinedsoc/core/ebu/HSIZE[0]} {wallypipelinedsoc/core/ebu/HSIZE[1]} {wallypipelinedsoc/core/ebu/HSIZE[2]}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe112]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe112]
connect_debug_port u_ila_0/probe112 [get_nets [list {wallypipelinedsoc/core/ebu/HBURST[0]} {wallypipelinedsoc/core/ebu/HBURST[1]} {wallypipelinedsoc/core/ebu/HBURST[2]}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe113]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe113]
connect_debug_port u_ila_0/probe113 [get_nets [list {wallypipelinedsoc/core/ebu/HPROT[0]} {wallypipelinedsoc/core/ebu/HPROT[1]} {wallypipelinedsoc/core/ebu/HPROT[2]} {wallypipelinedsoc/core/ebu/HPROT[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe114]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe114]
connect_debug_port u_ila_0/probe114 [get_nets [list {wallypipelinedsoc/core/ebu/HMASTLOCK}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe115]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe115]
connect_debug_port u_ila_0/probe115 [get_nets [list {wallypipelinedsoc/core/priv.priv/InterruptM}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe116]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe116]
connect_debug_port u_ila_0/probe116 [get_nets [list wallypipelinedsoc/core/lsu/ITLBMissF]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe117]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe117]
connect_debug_port u_ila_0/probe117 [get_nets [list wallypipelinedsoc/core/lsu/DTLBMissM]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe118]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe118]
connect_debug_port u_ila_0/probe118 [get_nets [list wallypipelinedsoc/core/lsu/ITLBWriteF]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe119]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe119]
connect_debug_port u_ila_0/probe119 [get_nets [list wallypipelinedsoc/core/lsu/DTLBWriteM]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe120]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe120]
connect_debug_port u_ila_0/probe120 [get_nets [list {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.lsuvirtmem/hptw/WalkerState[0]} {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.lsuvirtmem/hptw/WalkerState[1]} {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.lsuvirtmem/hptw/WalkerState[2]} {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.lsuvirtmem/hptw/WalkerState[3]}]]


create_debug_port u_ila_0 probe
set_property port_width 56 [get_debug_ports u_ila_0/probe121]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe121]
connect_debug_port u_ila_0/probe121 [get_nets [list {wallypipelinedsoc/core/lsu/IEUAdrM[0]} {wallypipelinedsoc/core/lsu/IEUAdrM[1]} {wallypipelinedsoc/core/lsu/IEUAdrM[2]} {wallypipelinedsoc/core/lsu/IEUAdrM[3]} {wallypipelinedsoc/core/lsu/IEUAdrM[4]} {wallypipelinedsoc/core/lsu/IEUAdrM[5]} {wallypipelinedsoc/core/lsu/IEUAdrM[6]} {wallypipelinedsoc/core/lsu/IEUAdrM[7]} {wallypipelinedsoc/core/lsu/IEUAdrM[8]} {wallypipelinedsoc/core/lsu/IEUAdrM[9]} {wallypipelinedsoc/core/lsu/IEUAdrM[10]} {wallypipelinedsoc/core/lsu/IEUAdrM[11]} {wallypipelinedsoc/core/lsu/IEUAdrM[12]} {wallypipelinedsoc/core/lsu/IEUAdrM[13]} {wallypipelinedsoc/core/lsu/IEUAdrM[14]} {wallypipelinedsoc/core/lsu/IEUAdrM[15]} {wallypipelinedsoc/core/lsu/IEUAdrM[16]} {wallypipelinedsoc/core/lsu/IEUAdrM[17]} {wallypipelinedsoc/core/lsu/IEUAdrM[18]} {wallypipelinedsoc/core/lsu/IEUAdrM[19]} {wallypipelinedsoc/core/lsu/IEUAdrM[20]} {wallypipelinedsoc/core/lsu/IEUAdrM[21]} {wallypipelinedsoc/core/lsu/IEUAdrM[22]} {wallypipelinedsoc/core/lsu/IEUAdrM[23]} {wallypipelinedsoc/core/lsu/IEUAdrM[24]} {wallypipelinedsoc/core/lsu/IEUAdrM[25]} {wallypipelinedsoc/core/lsu/IEUAdrM[26]} {wallypipelinedsoc/core/lsu/IEUAdrM[27]} {wallypipelinedsoc/core/lsu/IEUAdrM[28]} {wallypipelinedsoc/core/lsu/IEUAdrM[29]} {wallypipelinedsoc/core/lsu/IEUAdrM[30]} {wallypipelinedsoc/core/lsu/IEUAdrM[31]} {wallypipelinedsoc/core/lsu/IEUAdrM[32]} {wallypipelinedsoc/core/lsu/IEUAdrM[33]} {wallypipelinedsoc/core/lsu/IEUAdrM[34]} {wallypipelinedsoc/core/lsu/IEUAdrM[35]} {wallypipelinedsoc/core/lsu/IEUAdrM[36]} {wallypipelinedsoc/core/lsu/IEUAdrM[37]} {wallypipelinedsoc/core/lsu/IEUAdrM[38]} {wallypipelinedsoc/core/lsu/IEUAdrM[39]} {wallypipelinedsoc/core/lsu/IEUAdrM[40]} {wallypipelinedsoc/core/lsu/IEUAdrM[41]} {wallypipelinedsoc/core/lsu/IEUAdrM[42]} {wallypipelinedsoc/core/lsu/IEUAdrM[43]} {wallypipelinedsoc/core/lsu/IEUAdrM[44]} {wallypipelinedsoc/core/lsu/IEUAdrM[45]} {wallypipelinedsoc/core/lsu/IEUAdrM[46]} {wallypipelinedsoc/core/lsu/IEUAdrM[47]} {wallypipelinedsoc/core/lsu/IEUAdrM[48]} {wallypipelinedsoc/core/lsu/IEUAdrM[49]} {wallypipelinedsoc/core/lsu/IEUAdrM[50]} {wallypipelinedsoc/core/lsu/IEUAdrM[51]} {wallypipelinedsoc/core/lsu/IEUAdrM[52]} {wallypipelinedsoc/core/lsu/IEUAdrM[53]} {wallypipelinedsoc/core/lsu/IEUAdrM[54]} {wallypipelinedsoc/core/lsu/IEUAdrM[55]} ]]


create_debug_port u_ila_0 probe
set_property port_width 56 [get_debug_ports u_ila_0/probe122]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe122]
connect_debug_port u_ila_0/probe122 [get_nets [list {wallypipelinedsoc/core/ifu/PCPF[0]} {wallypipelinedsoc/core/ifu/PCPF[1]} {wallypipelinedsoc/core/ifu/PCPF[2]} {wallypipelinedsoc/core/ifu/PCPF[3]} {wallypipelinedsoc/core/ifu/PCPF[4]} {wallypipelinedsoc/core/ifu/PCPF[5]} {wallypipelinedsoc/core/ifu/PCPF[6]} {wallypipelinedsoc/core/ifu/PCPF[7]} {wallypipelinedsoc/core/ifu/PCPF[8]} {wallypipelinedsoc/core/ifu/PCPF[9]} {wallypipelinedsoc/core/ifu/PCPF[10]} {wallypipelinedsoc/core/ifu/PCPF[11]} {wallypipelinedsoc/core/ifu/PCPF[12]} {wallypipelinedsoc/core/ifu/PCPF[13]} {wallypipelinedsoc/core/ifu/PCPF[14]} {wallypipelinedsoc/core/ifu/PCPF[15]} {wallypipelinedsoc/core/ifu/PCPF[16]} {wallypipelinedsoc/core/ifu/PCPF[17]} {wallypipelinedsoc/core/ifu/PCPF[18]} {wallypipelinedsoc/core/ifu/PCPF[19]} {wallypipelinedsoc/core/ifu/PCPF[20]} {wallypipelinedsoc/core/ifu/PCPF[21]} {wallypipelinedsoc/core/ifu/PCPF[22]} {wallypipelinedsoc/core/ifu/PCPF[23]} {wallypipelinedsoc/core/ifu/PCPF[24]} {wallypipelinedsoc/core/ifu/PCPF[25]} {wallypipelinedsoc/core/ifu/PCPF[26]} {wallypipelinedsoc/core/ifu/PCPF[27]} {wallypipelinedsoc/core/ifu/PCPF[28]} {wallypipelinedsoc/core/ifu/PCPF[29]} {wallypipelinedsoc/core/ifu/PCPF[30]} {wallypipelinedsoc/core/ifu/PCPF[31]} {wallypipelinedsoc/core/ifu/PCPF[32]} {wallypipelinedsoc/core/ifu/PCPF[33]} {wallypipelinedsoc/core/ifu/PCPF[34]} {wallypipelinedsoc/core/ifu/PCPF[35]} {wallypipelinedsoc/core/ifu/PCPF[36]} {wallypipelinedsoc/core/ifu/PCPF[37]} {wallypipelinedsoc/core/ifu/PCPF[38]} {wallypipelinedsoc/core/ifu/PCPF[39]} {wallypipelinedsoc/core/ifu/PCPF[40]} {wallypipelinedsoc/core/ifu/PCPF[41]} {wallypipelinedsoc/core/ifu/PCPF[42]} {wallypipelinedsoc/core/ifu/PCPF[43]} {wallypipelinedsoc/core/ifu/PCPF[44]} {wallypipelinedsoc/core/ifu/PCPF[45]} {wallypipelinedsoc/core/ifu/PCPF[46]} {wallypipelinedsoc/core/ifu/PCPF[47]} {wallypipelinedsoc/core/ifu/PCPF[48]} {wallypipelinedsoc/core/ifu/PCPF[49]} {wallypipelinedsoc/core/ifu/PCPF[50]} {wallypipelinedsoc/core/ifu/PCPF[51]} {wallypipelinedsoc/core/ifu/PCPF[52]} {wallypipelinedsoc/core/ifu/PCPF[53]} {wallypipelinedsoc/core/ifu/PCPF[54]} {wallypipelinedsoc/core/ifu/PCPF[55]} ]]



create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe123]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe123]
connect_debug_port u_ila_0/probe123 [get_nets [list {wallypipelinedsoc/core/ifu/bus.busdp/busfsm/BusCurrState[0]} {wallypipelinedsoc/core/ifu/bus.busdp/busfsm/BusCurrState[1]} {wallypipelinedsoc/core/ifu/bus.busdp/busfsm/BusCurrState[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe124]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe124]
connect_debug_port u_ila_0/probe124 [get_nets [list wallypipelinedsoc/core/ifu/SpillSupport.spillsupport/CurrState[0] ]]


create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe125]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe125]
connect_debug_port u_ila_0/probe125 [get_nets [list {wallypipelinedsoc/core/lsu/bus.busdp/busfsm/BusCurrState[0]} {wallypipelinedsoc/core/lsu/bus.busdp/busfsm/BusCurrState[1]} {wallypipelinedsoc/core/lsu/bus.busdp/busfsm/BusCurrState[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe126]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe126]
connect_debug_port u_ila_0/probe126 [get_nets [list {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.lsuvirtmem/interlockfsm/InterlockCurrState[0]} {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.lsuvirtmem/interlockfsm/InterlockCurrState[1]} {wallypipelinedsoc/core/lsu/VIRTMEM_SUPPORTED.lsuvirtmem/interlockfsm/InterlockCurrState[2]} ]]


create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe127]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe127]
connect_debug_port u_ila_0/probe127 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrs/csrs.SSCRATCH_REGW[63]} ]]


create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe128]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe128]
connect_debug_port u_ila_0/probe128 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[0]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[1]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[2]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[3]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[4]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[5]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[6]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[7]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[8]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[9]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[10]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[11]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[12]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[13]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[14]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[15]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[16]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[17]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[18]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[19]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[20]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[21]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[22]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[23]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[24]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[25]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[26]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[27]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[28]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[29]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[30]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[31]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[32]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[33]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[34]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[35]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[36]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[37]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[38]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[39]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[40]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[41]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[42]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[43]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[44]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[45]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[46]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[47]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[48]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[49]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[50]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[51]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[52]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[53]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[54]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[55]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[56]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[57]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[58]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[59]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[60]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[61]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[62]} {wallypipelinedsoc/core/priv.priv/csr/csrm/MSCRATCH_REGW[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe129]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe129]
connect_debug_port u_ila_0/probe129 [get_nets [list {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[0]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[1]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[2]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[3]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[4]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[5]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[6]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[7]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[8]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[9]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[10]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[11]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[12]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[13]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[14]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[15]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[16]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[17]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[18]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[19]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[20]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[21]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[22]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[23]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[24]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[25]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[26]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[27]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[28]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[29]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[30]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[31]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[32]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[33]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[34]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[35]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[36]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[37]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[38]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[39]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[40]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[41]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[42]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[43]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[44]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[45]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[46]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[47]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[48]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[49]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[50]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[51]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[52]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[53]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[54]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[55]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[56]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[57]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[58]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[59]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[60]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[61]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[62]} {wallypipelinedsoc/core/ieu/dp/regf/rf[4]__0[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe130]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe130]
connect_debug_port u_ila_0/probe130 [get_nets [list wallypipelinedsoc/core/ieu/dp/RegWriteW]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe131]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe131]
connect_debug_port u_ila_0/probe131 [get_nets [list {wallypipelinedsoc/core/priv.priv/CSRWriteM} ]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe132]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe132]
connect_debug_port u_ila_0/probe132 [get_nets [list {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[0]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[1]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[2]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[3]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[4]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[5]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[6]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[7]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[8]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[9]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[10]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[11]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[12]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[13]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[14]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[15]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[16]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[17]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[18]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[19]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[20]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[21]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[22]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[23]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[24]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[25]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[26]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[27]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[28]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[29]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[30]} {wallypipelinedsoc/core/ifu/PostSpillInstrRawF[31]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe133]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe133]
connect_debug_port u_ila_0/probe133 [get_nets [list {wallypipelinedsoc/core/ifu/PCNextF[0]} {wallypipelinedsoc/core/ifu/PCNextF[1]} {wallypipelinedsoc/core/ifu/PCNextF[2]} {wallypipelinedsoc/core/ifu/PCNextF[3]} {wallypipelinedsoc/core/ifu/PCNextF[4]} {wallypipelinedsoc/core/ifu/PCNextF[5]} {wallypipelinedsoc/core/ifu/PCNextF[6]} {wallypipelinedsoc/core/ifu/PCNextF[7]} {wallypipelinedsoc/core/ifu/PCNextF[8]} {wallypipelinedsoc/core/ifu/PCNextF[9]} {wallypipelinedsoc/core/ifu/PCNextF[10]} {wallypipelinedsoc/core/ifu/PCNextF[11]} {wallypipelinedsoc/core/ifu/PCNextF[12]} {wallypipelinedsoc/core/ifu/PCNextF[13]} {wallypipelinedsoc/core/ifu/PCNextF[14]} {wallypipelinedsoc/core/ifu/PCNextF[15]} {wallypipelinedsoc/core/ifu/PCNextF[16]} {wallypipelinedsoc/core/ifu/PCNextF[17]} {wallypipelinedsoc/core/ifu/PCNextF[18]} {wallypipelinedsoc/core/ifu/PCNextF[19]} {wallypipelinedsoc/core/ifu/PCNextF[20]} {wallypipelinedsoc/core/ifu/PCNextF[21]} {wallypipelinedsoc/core/ifu/PCNextF[22]} {wallypipelinedsoc/core/ifu/PCNextF[23]} {wallypipelinedsoc/core/ifu/PCNextF[24]} {wallypipelinedsoc/core/ifu/PCNextF[25]} {wallypipelinedsoc/core/ifu/PCNextF[26]} {wallypipelinedsoc/core/ifu/PCNextF[27]} {wallypipelinedsoc/core/ifu/PCNextF[28]} {wallypipelinedsoc/core/ifu/PCNextF[29]} {wallypipelinedsoc/core/ifu/PCNextF[30]} {wallypipelinedsoc/core/ifu/PCNextF[31]} {wallypipelinedsoc/core/ifu/PCNextF[32]} {wallypipelinedsoc/core/ifu/PCNextF[33]} {wallypipelinedsoc/core/ifu/PCNextF[34]} {wallypipelinedsoc/core/ifu/PCNextF[35]} {wallypipelinedsoc/core/ifu/PCNextF[36]} {wallypipelinedsoc/core/ifu/PCNextF[37]} {wallypipelinedsoc/core/ifu/PCNextF[38]} {wallypipelinedsoc/core/ifu/PCNextF[39]} {wallypipelinedsoc/core/ifu/PCNextF[40]} {wallypipelinedsoc/core/ifu/PCNextF[41]} {wallypipelinedsoc/core/ifu/PCNextF[42]} {wallypipelinedsoc/core/ifu/PCNextF[43]} {wallypipelinedsoc/core/ifu/PCNextF[44]} {wallypipelinedsoc/core/ifu/PCNextF[45]} {wallypipelinedsoc/core/ifu/PCNextF[46]} {wallypipelinedsoc/core/ifu/PCNextF[47]} {wallypipelinedsoc/core/ifu/PCNextF[48]} {wallypipelinedsoc/core/ifu/PCNextF[49]} {wallypipelinedsoc/core/ifu/PCNextF[50]} {wallypipelinedsoc/core/ifu/PCNextF[51]} {wallypipelinedsoc/core/ifu/PCNextF[52]} {wallypipelinedsoc/core/ifu/PCNextF[53]} {wallypipelinedsoc/core/ifu/PCNextF[54]} {wallypipelinedsoc/core/ifu/PCNextF[55]} {wallypipelinedsoc/core/ifu/PCNextF[56]} {wallypipelinedsoc/core/ifu/PCNextF[57]} {wallypipelinedsoc/core/ifu/PCNextF[58]} {wallypipelinedsoc/core/ifu/PCNextF[59]} {wallypipelinedsoc/core/ifu/PCNextF[60]} {wallypipelinedsoc/core/ifu/PCNextF[61]} {wallypipelinedsoc/core/ifu/PCNextF[62]} {wallypipelinedsoc/core/ifu/PCNextF[63]}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe134]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe134]
connect_debug_port u_ila_0/probe134 [get_nets [list {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[0]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[1]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[2]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[3]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[4]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[5]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[6]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[7]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[8]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[9]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[10]} {wallypipelinedsoc/core/priv.priv/trap/SPendingIntsM[11]} ]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe135]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe135]
connect_debug_port u_ila_0/probe135 [get_nets [list {wallypipelinedsoc/uncore/plic.plic/requests[1]} {wallypipelinedsoc/uncore/plic.plic/requests[2]} {wallypipelinedsoc/uncore/plic.plic/requests[3]} {wallypipelinedsoc/uncore/plic.plic/requests[4]} {wallypipelinedsoc/uncore/plic.plic/requests[5]} {wallypipelinedsoc/uncore/plic.plic/requests[6]} {wallypipelinedsoc/uncore/plic.plic/requests[7]} {wallypipelinedsoc/uncore/plic.plic/requests[8]} {wallypipelinedsoc/uncore/plic.plic/requests[9]} {wallypipelinedsoc/uncore/plic.plic/requests[10]} {wallypipelinedsoc/uncore/plic.plic/requests[11]} {wallypipelinedsoc/uncore/plic.plic/requests[12]}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe136]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe136]
connect_debug_port u_ila_0/probe136 [get_nets [list {wallypipelinedsoc/uncore/plic.plic/intInProgress[1]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[2]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[3]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[4]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[5]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[6]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[7]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[8]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[9]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[10]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[11]} {wallypipelinedsoc/uncore/plic.plic/intInProgress[12]}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe137]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe137]
connect_debug_port u_ila_0/probe137 [get_nets [list {wallypipelinedsoc/uncore/plic.plic/intPending[1]} {wallypipelinedsoc/uncore/plic.plic/intPending[2]} {wallypipelinedsoc/uncore/plic.plic/intPending[3]} {wallypipelinedsoc/uncore/plic.plic/intPending[4]} {wallypipelinedsoc/uncore/plic.plic/intPending[5]} {wallypipelinedsoc/uncore/plic.plic/intPending[6]} {wallypipelinedsoc/uncore/plic.plic/intPending[7]} {wallypipelinedsoc/uncore/plic.plic/intPending[8]} {wallypipelinedsoc/uncore/plic.plic/intPending[9]} {wallypipelinedsoc/uncore/plic.plic/intPending[10]} {wallypipelinedsoc/uncore/plic.plic/intPending[11]} {wallypipelinedsoc/uncore/plic.plic/intPending[12]}]]
