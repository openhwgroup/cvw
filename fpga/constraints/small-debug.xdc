create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN true [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0 ]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0 ]
create_debug_port u_ila_0  trig_in
create_debug_port u_ila_0  trig_in_ack
#set_property port_width 1 [get_debug_ports u_ila_0/trig_in]
#set_property port_width 1 [get_debug_ports u_ila_0/trig_in_ack]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/trig_in]
connect_debug_port u_ila_0/trig_in [get_nets IlaTrigger]
#connect_debug_port u_ila_0/trig_in_ack [get_nets IlaTriggerAck]
connect_debug_port u_ila_0/clk [get_nets CPUCLK]

set_property port_width 32 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][0]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][1]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][2]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][3]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][4]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][5]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][6]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][7]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][8]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][9]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][10]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][11]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][12]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][13]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][14]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][15]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][16]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][17]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][18]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][19]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][20]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][21]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][22]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][23]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][24]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][25]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][26]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][27]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][28]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][29]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][30]} {wallypipelinedsoc/core/priv.priv/csr/HPMCOUNTER_REGW[0][31]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list RvviAxiWlast ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list wallypipelinedsoc/core/InstrValidM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {RvviAxiRlast}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {RvviAxiRvalid}]]

create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {packetizer/CurrState[0]} {packetizer/CurrState[1]} {packetizer/CurrState[2]} {packetizer/CurrState[3]}]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {wallypipelinedsoc/core/PCM[0]} {wallypipelinedsoc/core/PCM[1]} {wallypipelinedsoc/core/PCM[2]} {wallypipelinedsoc/core/PCM[3]} {wallypipelinedsoc/core/PCM[4]} {wallypipelinedsoc/core/PCM[5]} {wallypipelinedsoc/core/PCM[6]} {wallypipelinedsoc/core/PCM[7]} {wallypipelinedsoc/core/PCM[8]} {wallypipelinedsoc/core/PCM[9]} {wallypipelinedsoc/core/PCM[10]} {wallypipelinedsoc/core/PCM[11]} {wallypipelinedsoc/core/PCM[12]} {wallypipelinedsoc/core/PCM[13]} {wallypipelinedsoc/core/PCM[14]} {wallypipelinedsoc/core/PCM[15]} {wallypipelinedsoc/core/PCM[16]} {wallypipelinedsoc/core/PCM[17]} {wallypipelinedsoc/core/PCM[18]} {wallypipelinedsoc/core/PCM[19]} {wallypipelinedsoc/core/PCM[20]} {wallypipelinedsoc/core/PCM[21]} {wallypipelinedsoc/core/PCM[22]} {wallypipelinedsoc/core/PCM[23]} {wallypipelinedsoc/core/PCM[24]} {wallypipelinedsoc/core/PCM[25]} {wallypipelinedsoc/core/PCM[26]} {wallypipelinedsoc/core/PCM[27]} {wallypipelinedsoc/core/PCM[28]} {wallypipelinedsoc/core/PCM[29]} {wallypipelinedsoc/core/PCM[30]} {wallypipelinedsoc/core/PCM[31]} {wallypipelinedsoc/core/PCM[32]} {wallypipelinedsoc/core/PCM[33]} {wallypipelinedsoc/core/PCM[34]} {wallypipelinedsoc/core/PCM[35]} {wallypipelinedsoc/core/PCM[36]} {wallypipelinedsoc/core/PCM[37]} {wallypipelinedsoc/core/PCM[38]} {wallypipelinedsoc/core/PCM[39]} {wallypipelinedsoc/core/PCM[40]} {wallypipelinedsoc/core/PCM[41]} {wallypipelinedsoc/core/PCM[42]} {wallypipelinedsoc/core/PCM[43]} {wallypipelinedsoc/core/PCM[44]} {wallypipelinedsoc/core/PCM[45]} {wallypipelinedsoc/core/PCM[46]} {wallypipelinedsoc/core/PCM[47]} {wallypipelinedsoc/core/PCM[48]} {wallypipelinedsoc/core/PCM[49]} {wallypipelinedsoc/core/PCM[50]} {wallypipelinedsoc/core/PCM[51]} {wallypipelinedsoc/core/PCM[52]} {wallypipelinedsoc/core/PCM[53]} {wallypipelinedsoc/core/PCM[54]} {wallypipelinedsoc/core/PCM[55]} {wallypipelinedsoc/core/PCM[56]} {wallypipelinedsoc/core/PCM[57]} {wallypipelinedsoc/core/PCM[58]} {wallypipelinedsoc/core/PCM[59]} {wallypipelinedsoc/core/PCM[60]} {wallypipelinedsoc/core/PCM[61]} {wallypipelinedsoc/core/PCM[62]} {wallypipelinedsoc/core/PCM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {RvviAxiWvalid}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {RVVIStall}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {valid}]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {RvviAxiWready}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe11]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {triggergen/CurrState[0]} {triggergen/CurrState[1]} {triggergen/CurrState[2]}]]


# the debug hub has issues with the clocks from the mmcm so lets give up an connect to the 100Mhz input clock.
#connect_debug_port dbg_hub/clk [get_nets default_100mhz_clk]
connect_debug_port dbg_hub/clk [get_nets CPUCLK]

