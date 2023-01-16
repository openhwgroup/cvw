# core-v-wally
Configurable RISC-V Processor

Wally is a 5-stage pipelined processor configurable to support all the standard RISC-V options, incluidng RV32/64, A, C, F, D, and M extensions, FENCE.I, and the various privileged modes and CSRs.  It is written in SystemVerilog.  It passes the RISC-V Arch Tests and boots Linux on an FPGA.

Wally is described in a textbook, RISC-V System-on-Chip Design, by Harris, Stine, Thompson, and Harris.  See Appendix D for directions installing the RISC-V tool chain needed to use Wally.

New users may wish to do the following setup to access the server via a GUI and use a text editor.

	Download and install x2go - A.1.1
	Download and install VSCode - A.4.2
	Make sure you can log into Tera acceptly via x2go and via a terminal
		Terminal on Mac, cmd on Windows, xterm on Linux
		See A.1 about ssh -Y login from a terminal
	Git started with Git configuration and authentication: B.1

Then follow Section 2.2 to clone the repo, source setup,  make the tests and run regression

	$ cd
	$ git clone --recurse-submodules https://github.com/davidharrishmc/riscv-wally
	$ cd riscv-wally
	$ source ./setup.sh
	$ make
	$ cd pipelined/regression
	$ ./regression-wally       (depends on having Questa installed)

Add the following lines to your .bashrc or .bash_profile

	if [ -f ~/riscv-wally/setup.sh ]; then
		source ~/riscv-wally/setup.sh
	fi
