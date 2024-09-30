# core-v-wally

Wally is a 5-stage pipelined processor configurable to support all the standard RISC-V options, including RV32/64, A, B, C, D, F, M, Q, and Zk* extensions, virtual memory, PMP, and the various privileged modes and CSRs. It provides optional caches, branch prediction, and standard RISC-V peripherals (CLINT, PLIC, UART, GPIO).   Wally is written in SystemVerilog.  It passes the [RISC-V Arch Tests](https://github.com/riscv-non-isa/riscv-arch-test) and boots Linux on an FPGA.  Configurations range from a minimal RV32E core to a fully featured RV64GC application processor with all of the RVA22S64 profile extensions. Wally is part of the OpenHWGroup family of robust open RISC-V cores.

![Wally block diagram](wallyriscvTopAll.png)

Wally is described in an upcoming textbook, *RISC-V System-on-Chip Design*, by Harris, Stine, Thompson, and Harris.  Users should follow the setup instructions below.  A system administrator must install CAD tools using the directions further down.

# Verification

Wally is presently at Technology Readiness Level 4, passing the RISC-V compatibility test suite and custom tests, and booting Linux in simulation and on an FPGA.  See the [Test Plan](docs/testplans/testplan.md) for details.

# New User Setup

New users may wish to do the following setup to access the server via a GUI and use a text editor.

	Git started with Git configuration and authentication: B.1 (replace with your name and email)
		$ git config --global user.name "Ben Bitdiddle"
		$ git config --global user.email "ben_bitdiddle@wally.edu"
		$ git config --global pull.rebase false
	Optional: Download and install x2go - A.1.1
	Optional: Download and install VSCode - A.4.2
	Optional: Make sure you can log into your server via x2go and via a terminal
		Terminal on Mac, cmd on Windows, xterm on Linux
		See A.1 about ssh -Y login from a terminal

Then fork and clone the repo, source setup, make the tests and run regression

	If you don't already have a Github account, create one
	In a web browser, visit https://github.com/openhwgroup/cvw
	In the upper right part of the screen, click on Fork
	Create a fork, choosing the owner as your github account
	and the repository as cvw.

	On the Linux computer where you will be working, log in

Clone your fork of the repo. Change `<yourgithubid>` to your github id.

	$ git clone --recurse-submodules https://github.com/<yourgithubid>/cvw
	$ cd cvw
	$ git remote add upstream https://github.com/openhwgroup/cvw

If you are installing on a new system without any tools installed, please jump to the next section, Toolchain Installation then come back here.

Run the setup script to update your `PATH` and activate the python virtual environment.

	$ source ./setup.sh

Add the following lines to your `.bashrc` or `.bash_profile` to run the setup script each time you log in.

	if [ -f ~/cvw/setup.sh ]; then
		source ~/cvw/setup.sh
	fi


Build the tests and run a regression simulation to prove everything is installed.  Building tests will take a while.

	$ make --jobs
	$ regression-wally

# Toolchain Installation and Configuration (Sys Admin)

This section describes the open source toolchain installation.

### Compatibility
The current version of the toolchain has been tested on Ubuntu (versions 20.04 LTS, 22.04 LTS, and 24.04 LTS) and on Red Hat/Rocky/AlmaLinux (versions 8 and 9).

NOTE: Ubuntu 22.04LTS is incompatible with Synopsys Design Compiler.

### Overview
The toolchain installation script installs the following tools:
- [RISC-V GNU Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain): GCC and accompanying compiler tools
- [elf2hex](https://github.com/sifive/elf2hex): executable file to hexadecimal converter
- [QEMU](https://www.qemu.org/docs/master/system/target-riscv.html): emulator
- [Spike](https://github.com/riscv-software-src/riscv-isa-sim): functional RISC-V model
- [Verilator](https://github.com/verilator/verilator): open-source Verilog simulator
	- NOTE: Verilator does not currently work reliably for simulating Wally on Ubuntu 20.04 LTS and Red Hat 8
- [RISC-V Sail Model](https://github.com/riscv/sail-riscv): golden reference model for RISC-V
- [OSU Skywater 130 cell library](https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_osu_sc_t12): standard cell library
- [RISCOF](https://github.com/riscv-software-src/riscof.git): RISC-V compliance test framework

Additionally, Buildroot Linux is built for Wally and linux test-vectors are generated for simulation. See the [Linux README](linux/README.md) for more details.

### Installation

The tools can be installed by running

	$ $WALLY/bin/wally-tool-chain-install.sh

If this script is run as root or using `sudo`, it will also install all of the prerequisite packages using the system package manager. The default installation directory when run in this manner is `/opt/riscv`.

If a user-level installation is desired, the script can instead be run by any user without `sudo` and the installation directory will be `~/riscv`. In this case, the prerequisite packages must first be installed by running

	$ sudo $WALLY/bin/wally-package-install.sh

In either case, the installation directory can be overridden by passing the desired directory as the last argument to the installation script. For example,

	$ sudo $WALLY/bin/wally-tool-chain-install.sh /home/riscv

See `wally-tool-chain-install.sh` for a detailed description of each component, or to issue the commands one at a time to install on the command line.

**NOTE:** The complete installation process requires ~55 GB of free space. If the `--clean` flag is passed as the first argument to the installation script then the final consumed space is only ~26 GB, but upgrading the tools requires reinstalling from scratch.

### Configuration
`$WALLY/setup.sh` sources `$RISCV/site-setup.sh`. If the toolchain was installed in either of the default locations (`/opt/riscv` or `~/riscv`), `$RISCV` will automatically be set to the correct path when `setup.sh` is run. If a custom installation directory was used, then `$WALLY/setup.sh` must be modified to set the correct path.

`$RISCV/site-setup.sh` allows for customization of the site specific information such as commercial licenses and PATH variables. It is automatically copied into your `$RISCV` folder when the installation script is run.

Change the following lines to point to the path and license server for your Siemens Questa and Synopsys Design Compiler and VCS installations and license servers.  If you only have Questa or VCS, you can still simulate but cannot run logic synthesis.  If Questa, VSC, or Design Compiler are already setup on this system then don't set these variables.

	export MGLS_LICENSE_FILE=..         # Change this to your Siemens license server
	export SNPSLMD_LICENSE_FILE=..      # Change this to your Synopsys license server
	export QUESTA_HOME=..               # Change this for your path to Questa
	export DC_HOME=..                   # Change this for your path to Synopsys Design Compiler
	export VCS_HOME=..                  # Change this for your path to Synopsys VCS


# Installing EDA Tools

Electronic Design Automation (EDA) tools are vital to implementations of System on Chip architectures as well as validating different designs.   Open-source and commercial tools exist for multiple strategies and although the one can spend a lifetime using combinations of different tools, only a small subset of tools is utilized for this text.  The tools are chosen because of their ease in access as well as their repeatability for accomplishing many of the tasks utilized to design Wally.  It is anticipated that additional tools may be documented later after this is text is published to improve use and access.

Siemens Questa is the primary tool utilized for simulating and validating Wally.    For logic synthesis, you will need Synopsys Design Compiler.  Questa and Design Compiler are commercial tools that require an educational or commercial license.

Note: Some EDA tools utilize `LM_LICENSE_FILE` for their environmental variable to point to their license server.  Some operating systems may also utilize `MGLS_LICENSE_FILE` instead, therefore, it is important to read the user manual on the preferred environmental variable required to point to a user’s license file.  Although there are different mechanisms to allow licenses to work, many companies commonly utilize the FlexLM (i.e., Flex-enabled) license server manager that runs off a node locked license.

Although most EDA tools are Linux-friendly, they tend to have issues when not installed on recommended OS flavors.  Both Red Hat Enterprise Linux and SUSE Linux products typically tend to be recommended for installing commercial-based EDA tools and are recommended for utilizing complex simulation and architecture exploration.  Questa can also be installed on Microsoft Windows as well as Mac OS with a Virtual Machine such as Parallels.

### Siemens Questa

Siemens Questa simulates behavioral, RTL and gate-level HDL.  To install Siemens Questa first go to a web browser and navigate to
https://eda.sw.siemens.com/en-US/ic/questa/simulation/advanced-simulator/.  Click Sign In and log in with your credentials and the product can easily be downloaded and installed.  Some  Windows-based installations also require gcc libraries that are typically provided as a compressed zip download through Siemens.

### Synopsys Design Compiler (DC)

Many commercial synthesis and place and route tools require a common installer.  These installers are provided by the EDA vendor and Synopsys has one called Synopsys Installer.  To use Synopsys Installer, you will need to acquire a license through Synopsys that is typically Called Synopsys Common Licensing (SCL).  Both the Synopsys Installer, license key file, and Design Compiler can all be downloaded through Synopsys Solvnet.  First open a web browser, log into Synsopsy Solvnet, and download the installer and Design Compiler installation files.  Then, install the Installer

	$ firefox &
Navigate to https://solvnet.synopsys.com
Log in with your institution’s username and password
Click on Downloads, then scroll down to Synopsys Installer
Select the latest version (currently 5.4).  Click Download Here, agree,
Click on SynopsysInstaller_v5.4.run
Return to downloads and also get Design Compiler (synthesis) latest version, and any others you want.
	Click on all parts and the .spf file, then click Download Files near the top
move the SynopsysInstaller into /cad/synopsys/Installer_5.4 with 755 permission for cad,
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

Note: Although most parts of Wally, including the Questa simulator, will work on most modern Linux platforms, as of 2022, the Synopsys CAD tools for SoC design are only supported on RedHat Enterprise Linux 7.4 or 8 or SUSE Linux Enterprise Server (SLES) 12 or 15. Moreover, the RISC-V formal specification (sail-riscv) does not build gracefully on RHEL7.

The Verilog simulation has been tested with Siemens Questa/ModelSim. This package is available to universities worldwide as part of the Design Verification Bundle through the Siemens Academic Partner Program members for $990/year.

If you want to implement your own version of the chip, your tool and license complexity rises significantly. Logic synthesis uses Synopsys Design Compiler. Placement and routing uses Cadence Innovus. Both Synopsys and Cadence offer their tools at a steep discount to their university program members, but the cost is still several thousand dollars per year. Most research universities with integrated circuit design programs have Siemens, Synopsys, and Cadence licenses. You also need a process design kit (PDK) for a specific integrated circuit technology and its libraries. The open-source Google Skywater 130 nm PDK is sufficient to synthesize the core but lacks memories. Google presently funds some fabrication runs for universities. IMEC and Muse Semiconductor offers full access to multiproject wafer fabrication on the TSMC 28 nm process including logic, I/O, and memory libraries; this involves three non-disclosure agreements. Fabrication costs on the order of $10,000 for a batch of 1 mm2 chips.

Startups can expect to spend more than $1 million on CAD tools to get a chip to market. Commercial CAD tools are not realistically available to individuals without a university or company connection.


# Adding Cron Job for nightly builds

If you want to add a cronjob you can do the following:
1) Set up the email client `mutt` for your distribution
2) Enter `crontab -e` into a terminal
3) add this code to test building CVW and then running `regression-wally --nightly` at 9:30 PM each day
```
30 21 * * * bash -l -c "source ~/PATH/TO/CVW/setup.sh; PATH_TO_CVW/cvw/bin/wrapper_nightly_runs.sh --path {PATH_TO_TEST_LOCATION} --target all --tests nightly --send_email harris@hmc.edu,kaitlin.verilog@gmail.com"
```

# Example wsim commands

wsim runs one of multiple simulators, Questa, VCS, or Verilator using a specific configuration and either a suite of tests or a specific elf file.
The general syntax is
wsim <config> <suite or elf file or directory> [--options]

Parameters and options:

	-h, --help                                                   show this help message and exit
	--sim {questa,verilator,vcs}, -s {questa,verilator,vcs}      Simulator
	--tb {testbench,testbench_fp}, -t {testbench,testbench_fp}   Testbench
	--gui, -g                                                    Simulate with GUI
	--coverage, -c                                               Code & Functional Coverage
	--fcov, -f                                                   Code & Functional Coverage
	--args ARGS, -a ARGS                                         Optional arguments passed to simulator via $value$plusargs
	--vcd, -v                                                    Generate testbench.vcd
	--lockstep, -l                                               Run ImperasDV lock, step, and compare.
	--locksteplog LOCKSTEPLOG, -b LOCKSTEPLOG                    Retired instruction number to be begin logging.
	--covlog COVLOG, -d COVLOG                                   Log coverage after n instructions.
	--elfext ELFEXT, -e ELFEXT                                   When searching for elf files only includes ones which end in this extension

Run basic test with questa

	wsim rv64gc arch64i

Run Questa with gui

	wsim rv64gc wally64priv --gui

Run lockstep against ImperasDV with a single elf file in the --gui.  Lockstep requires single elf.

	wsim rv64gc ../../tests/riscof/work/riscv-arch-test/rv64i_m/I/src/add-01.S/ref/ref.elf --lockstep --gui

Run lockstep against ImperasDV with a single elf file.  Compute coverage.

	wsim rv64gc ../../tests/riscof/work/riscv-arch-test/rv64i_m/I/src/add-01.S/ref/ref.elf --lockstep --coverage

Run lockstep against ImperasDV with directory file.

	wsim rv64gc ../../tests/riscof/work/riscv-arch-test/rv64i_m/I/src/ --lockstep

Run lockstep against ImperasDV with directory file and specify specific extension.

	wsim rv64gc ../../tests/riscof/work/riscv-arch-test/rv64i_m/I/src/ --lockstep --elfext ref.elf

