# core-v-wally
Configurable RISC-V Processor

Wally is a 5-stage pipelined processor configurable to support all the standard RISC-V options, incluidng RV32/64, A, C, F, D, and M extensions, FENCE.I, and the various privileged modes and CSRs.  It is written in SystemVerilog.  It passes the RISC-V Arch Tests and boots Linux on an FPGA.

![Wally block diagram](wallyriscvTopAll.png)

Wally is described in a textbook, RISC-V System-on-Chip Design, by Harris, Stine, Thompson, and Harris.  Users should follow the setup instructions below.  A system administrator must install CAD tools using the directions further down.

# New User Setup

New users may wish to do the following setup to access the server via a GUI and use a text editor.

	Optional: Download and install x2go - A.1.1
	Optional: Download and install VSCode - A.4.2
	Optional: Make sure you can log into your server via x2go and via a terminal
		Terminal on Mac, cmd on Windows, xterm on Linux
		See A.1 about ssh -Y login from a terminal
	Git started with Git configuration and authentication: B.1
		$ git config --global user.name ″Ben Bitdiddle″
		$ git config --global user.email ″ben_bitdiddle@wally.edu″
		$ git config --global pull.rebase false

Then clone the repo, source setup,  make the tests and run regression

	If you don't already have a Github account, create one
	In a web browser, visit https://github.com/openhwgroup/cvw
	In the upper right part of the screen, click on Fork
	Create a fork, choosing the owner as your github account and the repository as cvw.
	
	On the Linux computer where you will be working, log in

Add the following lines to your .bashrc or .bash_profile to run the setup script each time you log in.

	if [ -f ~/cvw/setup.sh ]; then
		source ~/cvw/setup.sh
	fi

Clone your fork of the repo, run the setup script, and build the tests:

	$ cd
	$ git clone --recurse-submodules https://github.com/<yourgithubid>/cvw
	$ cd cvw
	$ source ./setup.sh
	$ make
	
Edit setup.sh and change the following lines to point to the path and license server for your Siemens Questa and Synopsys Design Compiler installation and license server.  If you only have Questa, you can still simulate but cannot run logic synthesis.

	export MGLS_LICENSE_FILE=1717@solidworks.eng.hmc.edu                # Change this to your Siemens license server
	export SNPSLMD_LICENSE_FILE=27020@zircon.eng.hmc.edu                # Change this to your Synopsys license server
	export QUESTAPATH=/cad/mentor/questa_sim-2021.2_1/questasim/bin     # Change this for your path to Questa
	export SNPSPATH=/cad/synopsys/SYN/bin                               # Change this for your path to Design Compiler

Run a regression simulation with Questa to prove everything is installed.

	$ cd pipelined/regression
	$ ./regression-wally       (depends on having Questa installed)

# Toolchain Installation (Sys Admin)

This section describes the open source toolchain installation.  These steps should only be done once by the system admin.

## TL;DR Open Source Tool-chain Installation

The full instalation details are involved can be be skipped using the following script, wally-tool-chain-install.sh.
The script installs the open source tools to /opt/riscv by default.  This can be changed by supply the path as the first argument.  This script does not install buildroot (see the Detailed Tool-chain Install Guide in the following section) and does not install commercial EDA tools; Siemens Questa, Synopsys Design Compiler, or Cadence Innovus (see section Installing IDA Tools). It must be run as root or with sudo. This script is tested for Ubuntu, 20.04 and 22.04. Fedora and Red Hat can be installed in the Detailed Tool-chain Install Guide.

	$ sudo wally-tool-chain-install.sh <optional, install directory, defaults to /opt/riscv>

## Detailed Toolchain Install Guide

This section describes how to install the tools needed for CORE-V-Wally. Superuser privileges are necessary for many of the tools. Setting up all of the tools can be time-consuming and fussy, so Appendix D also describes an option with a Docker container.  

### Open Source Software Installation

Compiling, assembling, and simulating RISC-V programs requires downloading and installing the following free tools:

1. The GCC cross-compiler
2. A RISC-V simulator such as Spike, Sail, and/or QEMU
3. Spike is easy to use but doesn’t support peripherals to boot Linux
4. QEMU is faster and can boot Linux
5. Sail is presently the official golden reference for RISC-V and is used by the riscof verification suite, but runs slowly and is painful to instal

This setup needs to be done once by the administrator

Note: The following directions assume you have an account called cad to install shared software and files. You can substitute a different user for cad if you prefer.

Note: Installing software in Linux is unreasonably touchy and varies with the flavor and version of your Linux distribution. Don’t be surprised if the installation directions have changed since the book was written or don’t work on your machine; you may need some ingenuity to adjust them. Browse the openhwgroup/core-v-wally repo and look at the README.md for the latest build instructions. 

### Create the $RISCV Directory

First, set up a directory for riscv software in some place such as /opt/riscv.  We will call this shared directory $RISCV.

	$ export RISCV=/opt/riscv
	$ sudo mkdir $RISCV
	$ sudo chown cad $RISCV
	$ sudo su cad  (or root, if you don’t have a cad account)
	$ export RISCV=/opt/riscv
	$ chmod 755 $RISCV
	$ umask 0002
	$ cd $RISCV

### Update Tools

Ubuntu users may need to install and update various tools.  Beware when cutting and pasting that some lines are long!

	$ sudo apt update
	$ sudo apt upgrade
	$ sudo apt install git gawk make texinfo bison flex build-essential python3 zlib1g-dev libexpat-dev autoconf device-tree-compiler ninja-build libglib2.0-dev libpixman-1-dev build-essential ncurses-base ncurses-bin libncurses5-dev dialog 

### Install RISC-V GCC Cross-Compiler

To install GCC from source can take hours to compile. This configuration enables multilib to target many flavors of RISC-V.   This book is tested with GCC 12.2 (tagged 2022.09.21), but will likely work with newer versions as well. 

	$ git clone https://github.com/riscv/riscv-gnu-toolchain 
	$ cd riscv-gnu-toolchain 
	$ git checkout 2022.09.21 
	$ ./configure --prefix=$RISCV --enable-multilib --with-multilib-generator="rv32e-ilp32e--;rv32i-ilp32--;rv32im-ilp32--;rv32iac-ilp32--;rv32imac-ilp32--;rv32imafc-ilp32f--;rv32imafdc-ilp32d--;rv64i-lp64--;rv64ic-lp64--;rv64iac-lp64--;rv64imac-lp64--;rv64imafdc-lp64d--;rv64im-lp64--;"
	$ make --jobs

Note: make --jobs will reduce compile time by compiling in parallel.  However, adding this option could dramatically increase the memory utilization of your local machine.

### Install elf2hex

We also need the elf2hex utility to convert executable files into hexadecimal files for Verilog simulation. Install with:

	$ cd $RISCV
	$ export PATH=$RISCV/riscv-gnu-toolchain/bin:$PATH
	$ git clone https://github.com/sifive/elf2hex.git
	$ cd elf2hex
	$ autoreconf -i
	$ ./configure --target=riscv64-unknown-elf --prefix=$RISCV
	$ make 
	$ make install 

Note: The exe2hex utility that comes with Spike doesn’t work for our purposes because it doesn’t handle programs that start at 0x80000000. The SiFive version above is touchy to install. For example, if Python version 2.x is in your path, it won’t install correctly.  Also, be sure riscv64-unknown-elf-objcopy shows up in your path in $RISCV/riscv-gnu-toolchain/bin at the time of compilation, or elf2hex won’t work properly.

### Install RISC-V Spike Simulator

Spike also takes a while to install and compile, but this can be done concurrently with the GCC installation.  After the build, we need to change two Makefiles to support atomic instructions .

	$ cd $RISCV
	$ git clone https://github.com/riscv-software-src/riscv-isa-sim
	$ mkdir riscv-isa-sim/build
	$ cd riscv-isa-sim/build
	$ ../configure --prefix=$RISCV --enable-commitlog 
	$ make --jobs
	$ make install 
	$ cd ../arch_test_target/spike/device
	$ sed -i 's/--isa=rv32ic/--isa=rv32iac/' rv32i_m/privilege/Makefile.include
	$ sed -i 's/--isa=rv64ic/--isa=rv64iac/' rv64i_m/privilege/Makefile.include 

### Install Sail Simulator

Sail is the new golden reference model for RISC-V.  Sail is written in OCaml, which is an object-oriented extension of ML, which in turn is a functional programming language suited to formal verification.  OCaml is installed with the opam OCcaml package manager. Sail has so many dependencies that it can be difficult to install.

On Ubuntu, apt-get makes opam installation fairly simple.

$ sudo apt-get install opam  build-essential libgmp-dev z3 pkg-config zlib1g-dev

If you are on RedHat/Rocky Linux 8, installation is much more difficult because packages are not available in the default package manager and some need to be built from source.

	$ sudo bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
	When prompted, put it in /usr/bin
	$ sudo yum groupinstall 'Development Tools'
	$ sudo yum -y install gmp-devel
	$ sudo yum -y install zlib-devel
	$ git clone https://github.com/Z3Prover/z3.git 
	$ cd z3
	$ python scripts/mk_make.py
	$ cd build
	$ make
	$ sudo make install
	$ cd ../..
	$ sudo pip3 install chardet==3.0.4
	$ sudo pip3 install urllib3==1.22

Once you have installed the packages on either Ubuntu or RedHat, use opam to install the OCaml compiler and Sail.  Run as the cad user because you will be installing Sail in $RISCV.

	$ sudo su cad
	$ opam init -y --disable-sandboxing
	$ opam switch create ocaml-base-compiler.4.06.1
	$ opam install sail -y

Now you can clone and compile Sail-RISCV.  This will take a while.

	$ eval $(opam config env)
	$ cd $RISCV
	$ git clone https://github.com/riscv/sail-riscv.git
	$ cd sail-riscv
	$ make
	$ ARCH=RV32 make
	$ ARCH=RV64 make
	$ exit
	$ sudo su
	$ export RISCV=/opt/riscv
	$ ln -sf $RISCV/sail-riscv/c_emulator/riscv_sim_RV64 /usr/bin/riscv_sim_RV64
	$ ln -sf $RISCV/sail-riscv/c_emulator/riscv_sim_RV32 /usr/bin/riscv_sim_RV32
	$ exit

### Install riscof

riscof is a Python library used as the RISC-V compatibility framework test an implementation such as Wally or Spike against the Sail golden reference. It will be used to compile the riscv-arch-test suite.  

It is most convenient if the sysadmin installs riscof into the server’s Python libraries:

	$ sudo pip3 install testresources
	$ sudo pip3 install riscof --ignore-installed PyYAML

However, riscof can also be installed and run locally by individual users.

### Install Verilator

Verilator is a free Verilog simulator with a good Lint tool used to catch errors in the SystemVerilog code.  It is needed to run regression.
$ sudo apt install verilator 

### Install QEMU Simulator

QEMU is another simulator used when booting Linux in Chapter 17. You can optionally install it using the following commands. 

<SIDEBAR>
The QEMU patch changes the VirtIO driver to match the Wally peripherals, and also adds print statements to log the state of the CSRs (see Section 2.5XREF).
</END>

	$ cd $RISCV
	$ git clone --recurse-submodules https://github.com/qemu/qemu
	$ cd qemu
	$ git checkout v6.2.0    # last version tested; newer versions might be ok
	$ ./configure --target-list=riscv64-softmmu --prefix=$RISCV
	$ make --jobs
	$ make install

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

$ source ~/riscv-wally/setup.sh
$ cd $WALLY/linux/buildroot-scripts
$ make all

Note: When the make tasks complete, you’ll find source code in $RISCV/buildroot/output/build and the executables in $RISCV/buildroot/output/images.

### Download Synthesis Libraries

For logic synthesis, we need a synthesis tool (see Section 3.XREF) and a cell library.  Clone the OSU 12-track cell library for the Skywater 130 nm process:

	$ cd $RISCV
	$ mkdir cad
	$ mkdir cad/lib
	$ cd cad/lib
	$ git clone https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12

### Install github cli

The github cli allows users to directly issue pull requests from their fork back to openhwgroup/cvw using the command line.

	$ type -p curl >/dev/null || sudo apt install curl -y
	$ curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \ && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y


## Installing EDA Tools

Electronic Design Automation (EDA) tools are vital to implementations of System on Chip architectures as well as validating different designs.   Open-source and commercial tools exist for multiple strategies and although the one can spend a lifetime using combinations of different tools, only a small subset of tools is utilized for this text.  The tools are chosen because of their ease in access as well as their repeatability for accomplishing many of the tasks utilized to design Wally.  It is anticipated that additional tools may be documented later after this is text is published to improve use and access.

Siemens Quest is the primary tool utilized for simulating and validating Wally.    For logic synthesis, you will need Synopsys Design Compiler.  Questa and Design Compiler are commercial tools that require an educational or commercial license.  

Note: Some EDA tools utilize LM_LICENSE_FILE for their environmental variable to point to their license server.  Some operating systems may also utilize MGLS_LICENSE_FILE instead, therefore, it is important to read the user manual on the preferred environmental variable required to point to a user’s license file.  Although there are different mechanisms to allow licenses to work, many companies commonly utilize the FlexLM (i.e., Flex-enabled) license server manager that runs off a node locked license.

Although most EDA tools are Linux-friendly, they tend to have issues when not installed on recommended OS flavors.  Both Red Hat Enterprise Linux and SUSE Linux products typically tend to be recommended for installing commercial-based EDA tools and are recommended for utilizing complex simulation and architecture exploration.  Questa can also be installed on Microsoft Windows as well as Mac OS with a Virtual Machine such as Parallels.  

Siemens Questa

Siemens Questa simulates behavioral, RTL and gate-level HDL.  To install Siemens Questa first go to a web browser and navigate to 
https://eda.sw.siemens.com/en-US/ic/questa/simulation/advanced-simulator/.  Click Sign In and log in with your credentials and the product can easily be downloaded and installed.  Some  Windows-based installations also require gcc libraries that are typically provided as a compressed zip download through Siemens.  

Synopsys Design Compiler (DC)

Many commercial synthesis and place and route tools require a common installer.  These installers are provided by the EDA vendor and Synopsys has one called Synopsys Installer.  To use Synopsys Installer, you will need to acquire a license through Synopsys that is typically Called Synopsys Common Licensing (SCL).  Both the Synopsys Installer, license key file, and Design Compiler can all be downloaded through Synopsys Solvnet.  First open a web browser, log into Synsopsy Solvnet, and download the installer and Design Compiler installation files.  Then, install the Installer

	$ firefox &
Navigate to https://solvnet.synopsys.com
Log in with your institution’s username and password
Click on Downloads, then scroll down to Synopsys Installer
Select the latest version (currently 5.4).  Click Download Here, agree,
Click on SynopsysInstaller_v5.4.run
Return to downloads and also get Design Compiler (synthesis) latest version, and any others you want.
	Click on all parts and the .spf file, then click Download Files near the top
move the SynopsysIntaller into /cad/synopsys/Installer_5.4 with 755 permission for cad, 
move other files into /cad/synopsys/downloads and work as user cad from here on

	$ cd /cad/synopsys/installer_5.4
	$ ./SynopsysInstaller_v5.4.run
	Accept default installation directory
	$ ./installer
	Enter source path as /cad/synopsys/downloads, and installation path as /cad/synopsys
	When prompted, enter your site ID
	Follow prompts

Installer can be utilized in graphical or text-based modes.  It is far easier to use the text-based installation tool.  To install DC, navigate to the location where your downloaded DC files are and type installer.  You should be prompted with questions related to where you wish to have your files installed.  

The Synopsys Installer automatically installs all downloaded product files into a single top-level target directory. You do not need to specify the installation directory for each product. For example, if you specify /import/programs/synopsys as the target directory, your installation directory structure might look like this after installation:

	/import/programs/synopsys/syn/S-2021.06-SP1

Note: Although most parts of Wally, including the software used in this chapter and Questa simulation, will work on most modern Linux platforms, as of 2022, the Synopsys CAD tools for SoC design are only supported on RedHat Enterprise Linux 7.4 or 8 or SUSE Linux Enterprise Server (SLES) 12 or 15. Moreover, the RISC-V formal specification (sail-riscv) does not build gracefully on RHEL7. 

The Verilog simulation has been tested with Siemens Questa/ModelSim. This package is available to universities worldwide as part of the Design Verification Bundle through the Siemens Academic Partner Program members for $990/year. 

If you want to implement your own version of the chip, your tool and license complexity rises significantly. Logic synthesis uses Synopsys Design Compiler. Placement and routing uses Cadence Innovus. Both Synopsys and Cadence offer their tools at a steep discount to their university program members, but the cost is still several thousand dollars per year. Most research universities with integrated circuit design programs have Siemens, Synopsys, and Cadence licenses. You also need a process design kit (PDK) for a specific integrated circuit technology and its libraries. The open-source Google Skywater 130 nm PDK is sufficient to synthesize the core but lacks memories. Google presently funds some fabrication runs for universities. IMEC and Muse Semiconductor offers full access to multiproject wafer fabrication on the TSMC 28 nm process including logic, I/O, and memory libraries; this involves three non-disclosure agreements. Fabrication costs on the order of $10,000 for a batch of 1 mm2 chips. 

Startups can expect to spend more than $1 million on CAD tools to get a chip to market. Commercial CAD tools are not realistically available to individuals without a university or company connection.



