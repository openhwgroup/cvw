
set partNumber $::env(XILINX_PART)
set boardName $::env(XILINX_BOARD)
set SYSTEMCLOCK $::env(SYSTEMCLOCK)
#set partNumber xcvu9p-flga2104-2L-e
#set boardName  xilinx.com:vcu118:part0:2.4

set ipName ddr4

set SYSTEMCLOCK_MHz [expr $SYSTEMCLOCK/1000000.0]

create_project $ipName . -force -part $partNumber
set_property board_part $boardName [current_project]

# really just these two lines which change
create_ip -name ddr4 -vendor xilinx.com -library ip -module_name $ipName
set_property -dict [list CONFIG.C0.ControllerType {DDR4_SDRAM} \
			CONFIG.No_Controller {1} \
			CONFIG.Phy_Only {Complete_Memory_Controller} \
			CONFIG.C0.DDR4_PhyClockRatio {4:1} \
			CONFIG.C0.DDR4_TimePeriod {833} \
			CONFIG.C0.DDR4_MemoryPart {MT40A256M16GE-083E} \
			CONFIG.C0.DDR4_BurstLength {8} \
			CONFIG.C0.DDR4_BurstType {Sequential} \
			CONFIG.C0.DDR4_CasLatency {16} \
			CONFIG.C0.DDR4_CasWriteLatency {12} \
			CONFIG.C0.DDR4_Slot {Single} \
			CONFIG.C0.DDR4_MemoryVoltage {1.2V} \
			CONFIG.C0.DDR4_DataWidth {64} \
			CONFIG.C0.DDR4_DataMask {DM_NO_DBI} \
			CONFIG.C0.DDR4_Mem_Add_Map {ROW_COLUMN_BANK} \
			CONFIG.C0.DDR4_Ordering {Normal} \
			CONFIG.C0.DDR4_Ecc {false} \
			CONFIG.C0.DDR4_AUTO_AP_COL_A3 {false} \
			CONFIG.C0.DDR4_AutoPrecharge {false} \
			CONFIG.C0.DDR4_UserRefresh_ZQCS {false} \
			CONFIG.C0.DDR4_AxiDataWidth {64} \
			CONFIG.C0.DDR4_AxiArbitrationScheme {RD_PRI_REG} \
			CONFIG.C0.DDR4_AxiIDWidth {4} \
			CONFIG.C0.DDR4_AxiAddressWidth {31} \
			CONFIG.C0.DDR4_AxiNarrowBurst {false} \
			CONFIG.Reference_Clock {Differential} \
			CONFIG.ADDN_UI_CLKOUT1.INSERT_VIP {0} \
			CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ $SYSTEMCLOCK_MHz \
			CONFIG.ADDN_UI_CLKOUT2.INSERT_VIP {0} \
			CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {300} \
			CONFIG.ADDN_UI_CLKOUT3.INSERT_VIP {0} \
			CONFIG.ADDN_UI_CLKOUT3_FREQ_HZ {None} \
			CONFIG.ADDN_UI_CLKOUT4.INSERT_VIP {0} \
			CONFIG.ADDN_UI_CLKOUT4_FREQ_HZ {None} \
			CONFIG.Debug_Signal {Disable} \
			CONFIG.MCS_DBG_EN {false} \
			CONFIG.C0.DDR4_MCS_ECC {false} \
			CONFIG.Simulation_Mode {BFM} \
			CONFIG.Example_TG {SIMPLE_TG} \
			CONFIG.C0.DDR4_SELF_REFRESH {false} \
			CONFIG.RECONFIG_XSDB_SAVE_RESTORE {false} \
			CONFIG.C0.DDR4_SAVE_RESTORE {false} \
			CONFIG.C0.DDR4_RESTORE_CRC {false} \
			CONFIG.C0.MIGRATION {false} \
			CONFIG.AL_SEL {0} \
			CONFIG.C0.ADDR_WIDTH {17} \
			CONFIG.C0.BANK_GROUP_WIDTH {1} \
			CONFIG.C0.CKE_WIDTH {1} \
			CONFIG.C0.CK_WIDTH {1} \
			CONFIG.C0.CS_WIDTH {1} \
			CONFIG.C0.DDR4_ACT_SKEW {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_0 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_1 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_2 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_3 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_4 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_5 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_6 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_7 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_8 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_9 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_10 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_11 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_12 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_13 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_14 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_15 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_16 {0} \
			CONFIG.C0.DDR4_ADDR_SKEW_17 {0} \
			CONFIG.C0.DDR4_AxiSelection {true} \
			CONFIG.C0.DDR4_BA_SKEW_0 {0} \
			CONFIG.C0.DDR4_BA_SKEW_1 {0} \
			CONFIG.C0.DDR4_BG_SKEW_0 {0} \
			CONFIG.C0.DDR4_BG_SKEW_1 {0} \
			CONFIG.C0.DDR4_CKE_SKEW_0 {0} \
			CONFIG.C0.DDR4_CKE_SKEW_1 {0} \
			CONFIG.C0.DDR4_CKE_SKEW_2 {0} \
			CONFIG.C0.DDR4_CKE_SKEW_3 {0} \
			CONFIG.C0.DDR4_CK_SKEW_0 {0} \
			CONFIG.C0.DDR4_CK_SKEW_1 {0} \
			CONFIG.C0.DDR4_CK_SKEW_2 {0} \
			CONFIG.C0.DDR4_CK_SKEW_3 {0} \
			CONFIG.C0.DDR4_CS_SKEW_0 {0} \
			CONFIG.C0.DDR4_CS_SKEW_1 {0} \
			CONFIG.C0.DDR4_CS_SKEW_2 {0} \
			CONFIG.C0.DDR4_CS_SKEW_3 {0} \
			CONFIG.C0.DDR4_Capacity {512} \
			CONFIG.C0.DDR4_ChipSelect {true} \
			CONFIG.C0.DDR4_Clamshell {false} \
			CONFIG.C0.DDR4_CustomParts {no_file_loaded} \
			CONFIG.C0.DDR4_EN_PARITY {false} \
			CONFIG.C0.DDR4_Enable_LVAUX {false} \
			CONFIG.C0.DDR4_InputClockPeriod {4000} \
			CONFIG.C0.DDR4_LR_SKEW_0 {0} \
			CONFIG.C0.DDR4_LR_SKEW_1 {0} \
			CONFIG.C0.DDR4_MemoryName {MainMemory} \
			CONFIG.C0.DDR4_ODT_SKEW_0 {0} \
			CONFIG.C0.DDR4_ODT_SKEW_1 {0} \
			CONFIG.C0.DDR4_ODT_SKEW_2 {0} \
			CONFIG.C0.DDR4_ODT_SKEW_3 {0} \
			CONFIG.C0.DDR4_OnDieTermination {RZQ/6} \
			CONFIG.C0.DDR4_OutputDriverImpedenceControl {RZQ/7} \
			CONFIG.C0.DDR4_PAR_SKEW {0} \
			CONFIG.C0.DDR4_Specify_MandD {false} \
			CONFIG.C0.DDR4_TREFI {0} \
			CONFIG.C0.DDR4_TRFC {0} \
			CONFIG.C0.DDR4_TRFC_DLR {0} \
			CONFIG.C0.DDR4_TXPR {0} \
			CONFIG.C0.DDR4_isCKEShared {false} \
			CONFIG.C0.DDR4_isCustom {false} \
			CONFIG.C0.DDR4_nCK_TREFI {0} \
			CONFIG.C0.DDR4_nCK_TRFC {0} \
			CONFIG.C0.DDR4_nCK_TRFC_DLR {0} \
			CONFIG.C0.DDR4_nCK_TXPR {5} \
			CONFIG.C0.LR_WIDTH {1} \
			CONFIG.C0.ODT_WIDTH {1} \
			CONFIG.C0.StackHeight {1} \
			CONFIG.C0_CLOCK_BOARD_INTERFACE {default_250mhz_clk1} \
			CONFIG.C0_DDR4_ARESETN.INSERT_VIP {0} \
			CONFIG.C0_DDR4_BOARD_INTERFACE {Custom} \
			CONFIG.C0_DDR4_CLOCK.INSERT_VIP {0} \
			CONFIG.C0_DDR4_RESET.INSERT_VIP {0} \
			CONFIG.C0_DDR4_S_AXI.INSERT_VIP {0} \
			CONFIG.C0_SYS_CLK_I.INSERT_VIP {0} \
			CONFIG.CLKOUT6 {0} \
			CONFIG.DCI_Cascade {false} \
			CONFIG.DIFF_TERM_SYSCLK {false} \
			CONFIG.Default_Bank_Selections {false} \
			CONFIG.EN_PP_4R_MIR {false} \
			CONFIG.Enable_SysPorts {true} \
			CONFIG.IOPowerReduction {OFF} \
			CONFIG.IO_Power_Reduction {false} \
			CONFIG.IS_FROM_PHY {1} \
			CONFIG.PARTIAL_RECONFIG_FLOW_MIG {false} \
			CONFIG.PING_PONG_PHY {1} \
			CONFIG.RESET_BOARD_INTERFACE {reset} \
			CONFIG.SET_DW_TO_40 {false} \
			CONFIG.SYSTEM_RESET.INSERT_VIP {0} \
			CONFIG.System_Clock {Differential} \
			CONFIG.TIMING_3DS {false} \
			CONFIG.TIMING_OP1 {false} \
			CONFIG.TIMING_OP2 {false} \
		       ] [get_ips $ipName]

generate_target {instantiation_template} [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
