dst := IP


all: $(dst)/xlnx_proc_sys_reset.log \
	$(dst)/xlnx_ddr4.log \
	$(dst)/xlnx_axi_clock_converter.log \
	 $(dst)/xlnx_ahblite_axi_bridge.log

$(dst)/%.log: %.tcl
	mkdir -p IP
	cd IP;\
	vivado -mode batch -source ../$*.tcl | tee $*.log
