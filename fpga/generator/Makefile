dst := IP
# vcu118
# export XILINX_PART := xcvu9p-flga2104-2L-e
# export XILINX_BOARD := xilinx.com:vcu118:part0:2.4
# export board := vcu118

# vcu108
export XILINX_PART := xcvu095-ffva2104-2-e
export XILINX_BOARD := xilinx.com:vcu108:part0:1.2
export board := vcu108


all: FPGA

FPGA: IP
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log

IP: $(dst)/xlnx_proc_sys_reset.log \
	$(dst)/xlnx_ddr4-$(board).log \
	$(dst)/xlnx_axi_clock_converter.log \
	$(dst)/xlnx_ahblite_axi_bridge.log \
	$(dst)/xlnx_axi_crossbar.log \
	$(dst)/xlnx_axi_dwidth_conv_32to64.log \
	$(dst)/xlnx_axi_dwidth_conv_64to32.log

$(dst)/%.log: %.tcl
	mkdir -p IP
	cd IP;\
	vivado -mode batch -source ../$*.tcl | tee $*.log

cleanIP:
	rm -rf IP

cleanLogs:
	rm -rf  *.jou *.log

cleanFPGA:
	rm -rf WallyFPGA.* reports sim .Xil

cleanAll: cleanIP cleanLogs cleanFPGA
