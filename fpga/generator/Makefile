dst := IP

# vcu118
#export XILINX_PART := xcvu9p-flga2104-2L-e
#export XILINX_BOARD := xilinx.com:vcu118:part0:2.4
#export board := vcu118

# vcu108
export XILINX_PART := xcvu095-ffva2104-2-e
export XILINX_BOARD := xilinx.com:vcu108:part0:1.2
export board := vcu108

# Arty A7
# export XILINX_PART := xc7a100tcsg324-1
# export XILINX_BOARD := digilentinc.com:arty-a7-100:part0:1.1
# export board := ArtyA7

# for Arty A7 and S7 boards
all: FPGA_VCU

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
	rm -rf ../src/CopiedFiles_do_not_add_to_repo/
	cp -r ../../src/ ../src/CopiedFiles_do_not_add_to_repo/
	mkdir ../src/CopiedFiles_do_not_add_to_repo/config/
	cp ../../config/rv64gc/config.vh ../src/CopiedFiles_do_not_add_to_repo/config/
	./insert_debug_comment.sh
	# modify config  *** RT: eventually setup for variably defined sized memory
	sed -i "s/ZICCLSM_SUPPORTED.*/ZICCLSM_SUPPORTED = 0;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/RESET_VECTOR.*/RESET_VECTOR = 64'h0000000000001000;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/BOOTROM_PRELOAD.*/BOOTROM_PRELOAD = 1'b1;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/UNCORE_RAM_BASE.*/UNCORE_RAM_BASE = 64'h00002000;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/UNCORE_RAM_RANGE.*/UNCORE_RAM_RANGE = 64'h00000FFF;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/UNCORE_RAM_PRELOAD.*/UNCORE_RAM_PRELOAD = 1'b1;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/EXT_MEM_SUPPORTED.*/EXT_MEM_SUPPORTED = 1'b1;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/EXT_MEM_RANGE.*/EXT_MEM_RANGE = 64'h0FFFFFFF;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/SDC_SUPPORTED.*/SDC_SUPPORTED = 1'b1;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/SPI_SUPPORTED.*/SPI_SUPPORTED = 1'b0;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh   # *** RT: Add SPI when ready
	sed -i "s/GPIO_LOOPBACK_TEST.*/GPIO_LOOPBACK_TEST = 0;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/SPI_LOOPBACK_TEST.*/SPI_LOOPBACK_TEST = 0;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/UART_PRESCALE.*/UART_PRESCALE = 32'd0;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/PLIC_NUM_SRC = .*/PLIC_NUM_SRC = 32'd53;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/PLIC_SDC_ID.*/PLIC_SDC_ID = 32'd20;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/BPRED_SIZE.*/BPRED_SIZE = 32'd12;/g" ../src/CopiedFiles_do_not_add_to_repo/config/config.vh
	sed -i "s/$\$readmemh.*/$\$readmemh(\"..\/..\/..\/fpga\/src\/boot.mem\", ROM, 0);/g" ../src/CopiedFiles_do_not_add_to_repo/generic/mem/rom1p1r.sv
	# This line allows the Bootloader to be loaded in a Block RAM on the FPGA
	sed -i "s/logic \[DATA_WIDTH-1:0\].*ROM.*/(\* rom_style=\"block\" \*) &/g" ../src/CopiedFiles_do_not_add_to_repo/generic/mem/rom1p1r.sv

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
