### Cross-Compile Buildroot Linux

Building Linux is only necessary for exploring the boot process in Chapter 17.  Building and generating a trace is a time-consuming operation that could be skipped for now; you can return to this section later if you are interested in the Linux details.

Buildroot depends on configuration files in riscv-wally, so the cad user must install Wally first according to the instructions in Section 2.2.2.  However, don’t source ~/wally-riscv/setup.sh because it will set LD_LIBRARY_PATH in a way to cause make to fail on buildroot.

To configure and build Buildroot:

	$ cd $RISCV
	$ export WALLY=~/riscv-wally  # make sure you haven’t sourced ~/riscv-wally/setup.sh by now
	$ git clone https://github.com/buildroot/buildroot.git
	$ cd buildroot
	$ git checkout 2021.05 # last tested working version
	$ cp -r $WALLY/linux/buildroot-config-src/wally ./board
	$ cp ./board/wally/main.config .config
	$ make --jobs

To generate disassembly files and the device tree, run another make script.  Note that you can expect some warnings about phandle references while running dtc on wally-virt.dtb.
Depending on your system configuration this makefile may need a bit of tweaking.  It places the output buildroot images in $RISCV/linux-testvectors and the buildroot object dumps in $RISCV/buildroot/output/images/disassembly.  If these directories are owned by root then the makefile will likely fail.  You can either change the makefile's target directories or change temporarily change the owner of the two directories.

$ source ~/riscv-wally/setup.sh
$ cd $WALLY/linux/buildroot-scripts
$ make all

Note: When the make tasks complete, you’ll find source code in $RISCV/buildroot/output/build and the executables in $RISCV/buildroot/output/images.

### Generate load images for linux boot

The Questa linux boot uses preloaded bootram and ram memory.  We use QEMU to generate these preloaded memory files.  Files output in $RISCV/linux-testvectors

	cd cvw/linux/testvector-generation
	./genInitMem.sh

This may require changing file permissions to the linux-testvectors directory.

### Generate QEMU linux trace

The linux testbench can instruction by instruction compare Wally's committed instructions against QEMU.  To do this QEMU outputs a log file consisting of all instructions executed.  Interrupts are handled by forcing the testbench to generate an interrupt at the same cycle as in QEMU.  Generating this trace will take more than 24 hours.

	cd cvw/linux/testvector-generation
	./genTrace.sh
