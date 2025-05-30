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
connect_debug_port u_ila_0/clk [get_nets CPUCLK]

set_property port_width 64 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {wallypipelinedsoc/core/PCM[0]} {wallypipelinedsoc/core/PCM[1]} {wallypipelinedsoc/core/PCM[2]} {wallypipelinedsoc/core/PCM[3]} {wallypipelinedsoc/core/PCM[4]} {wallypipelinedsoc/core/PCM[5]} {wallypipelinedsoc/core/PCM[6]} {wallypipelinedsoc/core/PCM[7]} {wallypipelinedsoc/core/PCM[8]} {wallypipelinedsoc/core/PCM[9]} {wallypipelinedsoc/core/PCM[10]} {wallypipelinedsoc/core/PCM[11]} {wallypipelinedsoc/core/PCM[12]} {wallypipelinedsoc/core/PCM[13]} {wallypipelinedsoc/core/PCM[14]} {wallypipelinedsoc/core/PCM[15]} {wallypipelinedsoc/core/PCM[16]} {wallypipelinedsoc/core/PCM[17]} {wallypipelinedsoc/core/PCM[18]} {wallypipelinedsoc/core/PCM[19]} {wallypipelinedsoc/core/PCM[20]} {wallypipelinedsoc/core/PCM[21]} {wallypipelinedsoc/core/PCM[22]} {wallypipelinedsoc/core/PCM[23]} {wallypipelinedsoc/core/PCM[24]} {wallypipelinedsoc/core/PCM[25]} {wallypipelinedsoc/core/PCM[26]} {wallypipelinedsoc/core/PCM[27]} {wallypipelinedsoc/core/PCM[28]} {wallypipelinedsoc/core/PCM[29]} {wallypipelinedsoc/core/PCM[30]} {wallypipelinedsoc/core/PCM[31]} {wallypipelinedsoc/core/PCM[32]} {wallypipelinedsoc/core/PCM[33]} {wallypipelinedsoc/core/PCM[34]} {wallypipelinedsoc/core/PCM[35]} {wallypipelinedsoc/core/PCM[36]} {wallypipelinedsoc/core/PCM[37]} {wallypipelinedsoc/core/PCM[38]} {wallypipelinedsoc/core/PCM[39]} {wallypipelinedsoc/core/PCM[40]} {wallypipelinedsoc/core/PCM[41]} {wallypipelinedsoc/core/PCM[42]} {wallypipelinedsoc/core/PCM[43]} {wallypipelinedsoc/core/PCM[44]} {wallypipelinedsoc/core/PCM[45]} {wallypipelinedsoc/core/PCM[46]} {wallypipelinedsoc/core/PCM[47]} {wallypipelinedsoc/core/PCM[48]} {wallypipelinedsoc/core/PCM[49]} {wallypipelinedsoc/core/PCM[50]} {wallypipelinedsoc/core/PCM[51]} {wallypipelinedsoc/core/PCM[52]} {wallypipelinedsoc/core/PCM[53]} {wallypipelinedsoc/core/PCM[54]} {wallypipelinedsoc/core/PCM[55]} {wallypipelinedsoc/core/PCM[56]} {wallypipelinedsoc/core/PCM[57]} {wallypipelinedsoc/core/PCM[58]} {wallypipelinedsoc/core/PCM[59]} {wallypipelinedsoc/core/PCM[60]} {wallypipelinedsoc/core/PCM[61]} {wallypipelinedsoc/core/PCM[62]} {wallypipelinedsoc/core/PCM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list wallypipelinedsoc/core/TrapM ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list wallypipelinedsoc/core/InstrValidM ]]

create_debug_port u_ila_0 probe
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {wallypipelinedsoc/core/InstrM[0]} {wallypipelinedsoc/core/InstrM[1]} {wallypipelinedsoc/core/InstrM[2]} {wallypipelinedsoc/core/InstrM[3]} {wallypipelinedsoc/core/InstrM[4]} {wallypipelinedsoc/core/InstrM[5]} {wallypipelinedsoc/core/InstrM[6]} {wallypipelinedsoc/core/InstrM[7]} {wallypipelinedsoc/core/InstrM[8]} {wallypipelinedsoc/core/InstrM[9]} {wallypipelinedsoc/core/InstrM[10]} {wallypipelinedsoc/core/InstrM[11]} {wallypipelinedsoc/core/InstrM[12]} {wallypipelinedsoc/core/InstrM[13]} {wallypipelinedsoc/core/InstrM[14]} {wallypipelinedsoc/core/InstrM[15]} {wallypipelinedsoc/core/InstrM[16]} {wallypipelinedsoc/core/InstrM[17]} {wallypipelinedsoc/core/InstrM[18]} {wallypipelinedsoc/core/InstrM[19]} {wallypipelinedsoc/core/InstrM[20]} {wallypipelinedsoc/core/InstrM[21]} {wallypipelinedsoc/core/InstrM[22]} {wallypipelinedsoc/core/InstrM[23]} {wallypipelinedsoc/core/InstrM[24]} {wallypipelinedsoc/core/InstrM[25]} {wallypipelinedsoc/core/InstrM[26]} {wallypipelinedsoc/core/InstrM[27]} {wallypipelinedsoc/core/InstrM[28]} {wallypipelinedsoc/core/InstrM[29]} {wallypipelinedsoc/core/InstrM[30]} {wallypipelinedsoc/core/InstrM[31]} ]]

create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {wallypipelinedsoc/core/lsu/MemRWM[0]} {wallypipelinedsoc/core/lsu/MemRWM[1]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {wallypipelinedsoc/core/lsu/IEUAdrM[0]} {wallypipelinedsoc/core/lsu/IEUAdrM[1]} {wallypipelinedsoc/core/lsu/IEUAdrM[2]} {wallypipelinedsoc/core/lsu/IEUAdrM[3]} {wallypipelinedsoc/core/lsu/IEUAdrM[4]} {wallypipelinedsoc/core/lsu/IEUAdrM[5]} {wallypipelinedsoc/core/lsu/IEUAdrM[6]} {wallypipelinedsoc/core/lsu/IEUAdrM[7]} {wallypipelinedsoc/core/lsu/IEUAdrM[8]} {wallypipelinedsoc/core/lsu/IEUAdrM[9]} {wallypipelinedsoc/core/lsu/IEUAdrM[10]} {wallypipelinedsoc/core/lsu/IEUAdrM[11]} {wallypipelinedsoc/core/lsu/IEUAdrM[12]} {wallypipelinedsoc/core/lsu/IEUAdrM[13]} {wallypipelinedsoc/core/lsu/IEUAdrM[14]} {wallypipelinedsoc/core/lsu/IEUAdrM[15]} {wallypipelinedsoc/core/lsu/IEUAdrM[16]} {wallypipelinedsoc/core/lsu/IEUAdrM[17]} {wallypipelinedsoc/core/lsu/IEUAdrM[18]} {wallypipelinedsoc/core/lsu/IEUAdrM[19]} {wallypipelinedsoc/core/lsu/IEUAdrM[20]} {wallypipelinedsoc/core/lsu/IEUAdrM[21]} {wallypipelinedsoc/core/lsu/IEUAdrM[22]} {wallypipelinedsoc/core/lsu/IEUAdrM[23]} {wallypipelinedsoc/core/lsu/IEUAdrM[24]} {wallypipelinedsoc/core/lsu/IEUAdrM[25]} {wallypipelinedsoc/core/lsu/IEUAdrM[26]} {wallypipelinedsoc/core/lsu/IEUAdrM[27]} {wallypipelinedsoc/core/lsu/IEUAdrM[28]} {wallypipelinedsoc/core/lsu/IEUAdrM[29]} {wallypipelinedsoc/core/lsu/IEUAdrM[30]} {wallypipelinedsoc/core/lsu/IEUAdrM[31]} {wallypipelinedsoc/core/lsu/IEUAdrM[32]} {wallypipelinedsoc/core/lsu/IEUAdrM[33]} {wallypipelinedsoc/core/lsu/IEUAdrM[34]} {wallypipelinedsoc/core/lsu/IEUAdrM[35]} {wallypipelinedsoc/core/lsu/IEUAdrM[36]} {wallypipelinedsoc/core/lsu/IEUAdrM[37]} {wallypipelinedsoc/core/lsu/IEUAdrM[38]} {wallypipelinedsoc/core/lsu/IEUAdrM[39]} {wallypipelinedsoc/core/lsu/IEUAdrM[40]} {wallypipelinedsoc/core/lsu/IEUAdrM[41]} {wallypipelinedsoc/core/lsu/IEUAdrM[42]} {wallypipelinedsoc/core/lsu/IEUAdrM[43]} {wallypipelinedsoc/core/lsu/IEUAdrM[44]} {wallypipelinedsoc/core/lsu/IEUAdrM[45]} {wallypipelinedsoc/core/lsu/IEUAdrM[46]} {wallypipelinedsoc/core/lsu/IEUAdrM[47]} {wallypipelinedsoc/core/lsu/IEUAdrM[48]} {wallypipelinedsoc/core/lsu/IEUAdrM[49]} {wallypipelinedsoc/core/lsu/IEUAdrM[50]} {wallypipelinedsoc/core/lsu/IEUAdrM[51]} {wallypipelinedsoc/core/lsu/IEUAdrM[52]} {wallypipelinedsoc/core/lsu/IEUAdrM[53]} {wallypipelinedsoc/core/lsu/IEUAdrM[54]} {wallypipelinedsoc/core/lsu/IEUAdrM[55]} {wallypipelinedsoc/core/lsu/IEUAdrM[56]} {wallypipelinedsoc/core/lsu/IEUAdrM[57]} {wallypipelinedsoc/core/lsu/IEUAdrM[58]} {wallypipelinedsoc/core/lsu/IEUAdrM[59]} {wallypipelinedsoc/core/lsu/IEUAdrM[60]} {wallypipelinedsoc/core/lsu/IEUAdrM[61]} {wallypipelinedsoc/core/lsu/IEUAdrM[62]} {wallypipelinedsoc/core/lsu/IEUAdrM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {wallypipelinedsoc/core/lsu/ReadDataM[0]} {wallypipelinedsoc/core/lsu/ReadDataM[1]} {wallypipelinedsoc/core/lsu/ReadDataM[2]} {wallypipelinedsoc/core/lsu/ReadDataM[3]} {wallypipelinedsoc/core/lsu/ReadDataM[4]} {wallypipelinedsoc/core/lsu/ReadDataM[5]} {wallypipelinedsoc/core/lsu/ReadDataM[6]} {wallypipelinedsoc/core/lsu/ReadDataM[7]} {wallypipelinedsoc/core/lsu/ReadDataM[8]} {wallypipelinedsoc/core/lsu/ReadDataM[9]} {wallypipelinedsoc/core/lsu/ReadDataM[10]} {wallypipelinedsoc/core/lsu/ReadDataM[11]} {wallypipelinedsoc/core/lsu/ReadDataM[12]} {wallypipelinedsoc/core/lsu/ReadDataM[13]} {wallypipelinedsoc/core/lsu/ReadDataM[14]} {wallypipelinedsoc/core/lsu/ReadDataM[15]} {wallypipelinedsoc/core/lsu/ReadDataM[16]} {wallypipelinedsoc/core/lsu/ReadDataM[17]} {wallypipelinedsoc/core/lsu/ReadDataM[18]} {wallypipelinedsoc/core/lsu/ReadDataM[19]} {wallypipelinedsoc/core/lsu/ReadDataM[20]} {wallypipelinedsoc/core/lsu/ReadDataM[21]} {wallypipelinedsoc/core/lsu/ReadDataM[22]} {wallypipelinedsoc/core/lsu/ReadDataM[23]} {wallypipelinedsoc/core/lsu/ReadDataM[24]} {wallypipelinedsoc/core/lsu/ReadDataM[25]} {wallypipelinedsoc/core/lsu/ReadDataM[26]} {wallypipelinedsoc/core/lsu/ReadDataM[27]} {wallypipelinedsoc/core/lsu/ReadDataM[28]} {wallypipelinedsoc/core/lsu/ReadDataM[29]} {wallypipelinedsoc/core/lsu/ReadDataM[30]} {wallypipelinedsoc/core/lsu/ReadDataM[31]} {wallypipelinedsoc/core/lsu/ReadDataM[32]} {wallypipelinedsoc/core/lsu/ReadDataM[33]} {wallypipelinedsoc/core/lsu/ReadDataM[34]} {wallypipelinedsoc/core/lsu/ReadDataM[35]} {wallypipelinedsoc/core/lsu/ReadDataM[36]} {wallypipelinedsoc/core/lsu/ReadDataM[37]} {wallypipelinedsoc/core/lsu/ReadDataM[38]} {wallypipelinedsoc/core/lsu/ReadDataM[39]} {wallypipelinedsoc/core/lsu/ReadDataM[40]} {wallypipelinedsoc/core/lsu/ReadDataM[41]} {wallypipelinedsoc/core/lsu/ReadDataM[42]} {wallypipelinedsoc/core/lsu/ReadDataM[43]} {wallypipelinedsoc/core/lsu/ReadDataM[44]} {wallypipelinedsoc/core/lsu/ReadDataM[45]} {wallypipelinedsoc/core/lsu/ReadDataM[46]} {wallypipelinedsoc/core/lsu/ReadDataM[47]} {wallypipelinedsoc/core/lsu/ReadDataM[48]} {wallypipelinedsoc/core/lsu/ReadDataM[49]} {wallypipelinedsoc/core/lsu/ReadDataM[50]} {wallypipelinedsoc/core/lsu/ReadDataM[51]} {wallypipelinedsoc/core/lsu/ReadDataM[52]} {wallypipelinedsoc/core/lsu/ReadDataM[53]} {wallypipelinedsoc/core/lsu/ReadDataM[54]} {wallypipelinedsoc/core/lsu/ReadDataM[55]} {wallypipelinedsoc/core/lsu/ReadDataM[56]} {wallypipelinedsoc/core/lsu/ReadDataM[57]} {wallypipelinedsoc/core/lsu/ReadDataM[58]} {wallypipelinedsoc/core/lsu/ReadDataM[59]} {wallypipelinedsoc/core/lsu/ReadDataM[60]} {wallypipelinedsoc/core/lsu/ReadDataM[61]} {wallypipelinedsoc/core/lsu/ReadDataM[62]} {wallypipelinedsoc/core/lsu/ReadDataM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {wallypipelinedsoc/core/lsu/WriteDataM[0]} {wallypipelinedsoc/core/lsu/WriteDataM[1]} {wallypipelinedsoc/core/lsu/WriteDataM[2]} {wallypipelinedsoc/core/lsu/WriteDataM[3]} {wallypipelinedsoc/core/lsu/WriteDataM[4]} {wallypipelinedsoc/core/lsu/WriteDataM[5]} {wallypipelinedsoc/core/lsu/WriteDataM[6]} {wallypipelinedsoc/core/lsu/WriteDataM[7]} {wallypipelinedsoc/core/lsu/WriteDataM[8]} {wallypipelinedsoc/core/lsu/WriteDataM[9]} {wallypipelinedsoc/core/lsu/WriteDataM[10]} {wallypipelinedsoc/core/lsu/WriteDataM[11]} {wallypipelinedsoc/core/lsu/WriteDataM[12]} {wallypipelinedsoc/core/lsu/WriteDataM[13]} {wallypipelinedsoc/core/lsu/WriteDataM[14]} {wallypipelinedsoc/core/lsu/WriteDataM[15]} {wallypipelinedsoc/core/lsu/WriteDataM[16]} {wallypipelinedsoc/core/lsu/WriteDataM[17]} {wallypipelinedsoc/core/lsu/WriteDataM[18]} {wallypipelinedsoc/core/lsu/WriteDataM[19]} {wallypipelinedsoc/core/lsu/WriteDataM[20]} {wallypipelinedsoc/core/lsu/WriteDataM[21]} {wallypipelinedsoc/core/lsu/WriteDataM[22]} {wallypipelinedsoc/core/lsu/WriteDataM[23]} {wallypipelinedsoc/core/lsu/WriteDataM[24]} {wallypipelinedsoc/core/lsu/WriteDataM[25]} {wallypipelinedsoc/core/lsu/WriteDataM[26]} {wallypipelinedsoc/core/lsu/WriteDataM[27]} {wallypipelinedsoc/core/lsu/WriteDataM[28]} {wallypipelinedsoc/core/lsu/WriteDataM[29]} {wallypipelinedsoc/core/lsu/WriteDataM[30]} {wallypipelinedsoc/core/lsu/WriteDataM[31]} {wallypipelinedsoc/core/lsu/WriteDataM[32]} {wallypipelinedsoc/core/lsu/WriteDataM[33]} {wallypipelinedsoc/core/lsu/WriteDataM[34]} {wallypipelinedsoc/core/lsu/WriteDataM[35]} {wallypipelinedsoc/core/lsu/WriteDataM[36]} {wallypipelinedsoc/core/lsu/WriteDataM[37]} {wallypipelinedsoc/core/lsu/WriteDataM[38]} {wallypipelinedsoc/core/lsu/WriteDataM[39]} {wallypipelinedsoc/core/lsu/WriteDataM[40]} {wallypipelinedsoc/core/lsu/WriteDataM[41]} {wallypipelinedsoc/core/lsu/WriteDataM[42]} {wallypipelinedsoc/core/lsu/WriteDataM[43]} {wallypipelinedsoc/core/lsu/WriteDataM[44]} {wallypipelinedsoc/core/lsu/WriteDataM[45]} {wallypipelinedsoc/core/lsu/WriteDataM[46]} {wallypipelinedsoc/core/lsu/WriteDataM[47]} {wallypipelinedsoc/core/lsu/WriteDataM[48]} {wallypipelinedsoc/core/lsu/WriteDataM[49]} {wallypipelinedsoc/core/lsu/WriteDataM[50]} {wallypipelinedsoc/core/lsu/WriteDataM[51]} {wallypipelinedsoc/core/lsu/WriteDataM[52]} {wallypipelinedsoc/core/lsu/WriteDataM[53]} {wallypipelinedsoc/core/lsu/WriteDataM[54]} {wallypipelinedsoc/core/lsu/WriteDataM[55]} {wallypipelinedsoc/core/lsu/WriteDataM[56]} {wallypipelinedsoc/core/lsu/WriteDataM[57]} {wallypipelinedsoc/core/lsu/WriteDataM[58]} {wallypipelinedsoc/core/lsu/WriteDataM[59]} {wallypipelinedsoc/core/lsu/WriteDataM[60]} {wallypipelinedsoc/core/lsu/WriteDataM[61]} {wallypipelinedsoc/core/lsu/WriteDataM[62]} {wallypipelinedsoc/core/lsu/WriteDataM[63]} ]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list wallypipelinedsoc/uncoregen.uncore/uartgen.uart/INTR ]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe9]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[2]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[3]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[4]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[5]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[6]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[7]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[8]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[9]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[10]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[11]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/requests[12]}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe10]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[2]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[3]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[4]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[5]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[6]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[7]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[8]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[9]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[10]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[11]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intInProgress[12]}]]

create_debug_port u_ila_0 probe
set_property port_width 12 [get_debug_ports u_ila_0/probe11]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[2]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[3]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[4]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[5]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[6]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[7]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[8]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[9]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[10]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[11]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPending[12]}]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe12]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPriority_reg[10][2]_1[0]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPriority_reg[10][2]_1[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intPriority_reg[10][2]_1[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 10 [get_debug_ports u_ila_0/probe13]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[2]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[3]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[4]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[5]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[6]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[7]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[8]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[9]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intEn[1]__0[10]} ]]
  
create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe14]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[0]_52[0]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[0]_52[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[0]_52[2]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[0]_52[3]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[0]_52[4]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[0]_52[5]} ]]

create_debug_port u_ila_0 probe
set_property port_width 6 [get_debug_ports u_ila_0/probe15]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[1]_53[0]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[1]_53[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[1]_53[2]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[1]_53[3]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[1]_53[4]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intClaim[1]_53[5]} ]]

create_debug_port u_ila_0 probe
set_property port_width 7 [get_debug_ports u_ila_0/probe16]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[0]_54[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[0]_54[2]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[0]_54[3]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[0]_54[4]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[0]_54[5]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[0]_54[6]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[0]_54[7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 8 [get_debug_ports u_ila_0/probe17]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[1]_55[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[1]_55[2]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[1]_55[3]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[1]_55[4]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[1]_55[5]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[1]_55[6]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/priorities_with_irqs[1]_55[7]} ]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe18]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/intThreshold[0]__0[0]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intThreshold[0]__0[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intThreshold[0]__0[2]} ]]

create_debug_port u_ila_0 probe
set_property port_width 3 [get_debug_ports u_ila_0/probe19]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {wallypipelinedsoc/uncoregen.uncore/plic.plic/intThreshold[1]__0[0]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intThreshold[1]__0[1]} {wallypipelinedsoc/uncoregen.uncore/plic.plic/intThreshold[1]__0[2]} ]]

# the debug hub has issues with the clocks from the mmcm so lets give up an connect to the 100Mhz input clock.
#connect_debug_port dbg_hub/clk [get_nets default_100mhz_clk]
connect_debug_port dbg_hub/clk [get_nets CPUCLK]
