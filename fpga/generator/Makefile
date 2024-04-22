dst := IP

# vcu118
#export XILINX_PART := xcvu9p-flga2104-2L-e
#export XILINX_BOARD := xilinx.com:vcu118:part0:2.4
#export board := vcu118

# vcu108
#export XILINX_PART := xcvu095-ffva2104-2-e
#export XILINX_BOARD := xilinx.com:vcu108:part0:1.2
#export board := vcu108

# Arty A7
export XILINX_PART := xc7a100tcsg324-1
export XILINX_BOARD := digilentinc.com:arty-a7-100:part0:1.1
export board := ArtyA7

# for Arty A7 and S7 boards
all: FPGA_Arty

# VCU 108 and VCU 118 boards
#all: FPGA_VCU

FPGA_Arty: PreProcessFiles IP_Arty
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log

FPGA_VCU: PreProcessFiles IP_VCU
	vivado -mode tcl -source wally.tcl 2>&1 | tee wally.log

IP_VCU: $(dst)/xlnx_proc_sys_reset.log \
	$(dst)/xlnx_ddr4-$(board).log \
	$(dst)/xlnx_axi_clock_converter.log \
	$(dst)/xlnx_ahblite_axi_bridge.log \
	$(dst)/xlnx_axi_crossbar.log \
	$(dst)/xlnx_axi_dwidth_conv_32to64.log \
	$(dst)/xlnx_axi_dwidth_conv_64to32.log \
	$(dst)/xlnx_axi_prtcl_conv.log

IP_Arty: $(dst)/xlnx_proc_sys_reset.log \
	$(dst)/xlnx_ddr3-$(board).log \
	$(dst)/xlnx_mmcm.log \
	$(dst)/xlnx_axi_clock_converter.log \
	$(dst)/xlnx_ahblite_axi_bridge.log \
	$(dst)/xlnx_axi_crossbar.log \
	$(dst)/xlnx_axi_dwidth_conv_32to64.log \
	$(dst)/xlnx_axi_dwidth_conv_64to32.log \
	$(dst)/xlnx_axi_prtcl_conv.log


PreProcessFiles:
	$(MAKE) -C ../../sim deriv
	rm -rf ../src/CopiedFiles_do_not_add_to_repo/
	cp -r ../../src/ ../src/CopiedFiles_do_not_add_to_repo/
	mkdir ../src/CopiedFiles_do_not_add_to_repo/config/
	cp ../../config/deriv/fpga/config.vh ../src/CopiedFiles_do_not_add_to_repo/config/
	./insert_debug_comment.sh
	# modify config  *** RT: eventually setup for variably defined sized memory
	#sed -i "s/EXT_MEM_RANGE.*/EXT_MEM_RANGE = 64'h0FFFFFFF;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	# This line allows the Bootloader to be loaded in a Block RAM on the FPGA
	sed -i "s/bit \[DATA_WIDTH-1:0\].*ROM.*/(\* rom_style=\"block\" \*) &/g" ../src/CopiedFiles_do_not_add_to_repo/generic/mem/rom1p1r.sv
	sed -i 's/$$WALLY/\.\.\/\.\.\/\.\.\//g' ../src/CopiedFiles_do_not_add_to_repo/generic/mem/rom1p1r.sv

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
