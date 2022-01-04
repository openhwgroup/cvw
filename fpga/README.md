The FPGA currently only targets the VCU118 board.

* Build Process

cd generator
make 

* Description

The generator makefile creates 4 IP blocks; proc_sys_reset, ddr4,
axi_clock_converter, and ahblite_axi_bridge.  Then it reads in the 4 IP blocks
and builds wally.  fpga/src/fpgaTop.v is the top level which instanciates
wallypipelinedsoc.sv and the 4 IP blocks.  The FPGA include and ILA (In logic
analyzer) which provides the current instruction PCM, instrM, etc along with
a large number of debuging signals.

* Programming the flash card
You'll need to write the linux image to the flash card.  Use the convert2bin.py 
script in pipelined/linux-testgen/linux-testvectors/ to convert the ram.txt
file from QEMU's preload to generate the binary.  Then to copy
 sudo dd if=ram.bin of=<path to flash card>.

* Loading the FPGA

After the build process is complete about 2 hrs on an i9-7900x. Launch vivado's
gui and open the WallyFPGA.xpr project file.  Open the hardware manager under
program and debug. Open target and then program with the bit file.

* Test Run

Once the FPGA is programed the 3 MSB LEDs in the upper right corner provide
status of the reset and ddr4 calibration.  LED 7 should always be lit.
LED 6 will light if the DDR4 is not calibrated.  LED 6 will be lit once
wally begins running.

Next the bootloader program will copy the flash card into the DDR4 memory.
When this done the lower 5 LEDs will blink 5 times and then try to boot
the program loaded in the DDR4 memory at physical address 0x8000_0000.

* Connecting uart
You'll need to connect both usb cables.  The first connects the FPGA programer
while the connect connects UART.  UART is configured to use 57600 baud with 
no parity, 8 data bits, and 1 stop bit.  sudo screen /dev/ttyUSB1 57600 should
let you view the com port.


