dst := IP

all: FPGA

FPGA: IP
	vivado -mode batch -source wally.tcl 2>&1 | tee wally.log

IP: $(dst)/xlnx_proc_sys_reset.log \
	$(dst)/xlnx_ddr4.log \
	$(dst)/xlnx_axi_clock_converter.log \
	 $(dst)/xlnx_ahblite_axi_bridge.log

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
