# Linux for core-v-wally

## Table of Contents

1. [Setting up Buildroot](#buildroot)
2. [Generating Device Tree Binaries](#devicetree)
3. [Disassembling the Binaries for Debugging](#disassembly)
4. [Creating a Bootable SD Card](#sdcard)

## Setting up Buildroot <a name="buildroot"></a>

In order to generate the Linux and boot stage binaries compatible with Wally, Buildroot is used for cross-compilation. To set up a Buildroot directory, configuration files for Buildroot, Linux, and Busybox must be copied into the correct locations inside the main Buildroot directory. This can be done automatically using the Makefile inside Wally's Linux subdirectory (this one). To install and patch a fresh Buildroot directory, type:

    $ make install BUILDROOT=path/to/buildroot

You can override the `BUILDROOT` variable to place buildroot where you want it. By default it will be placed at `/opt/riscv/buildroot`. In addition to copying the configuration files, it will install the buildroot package needed to build the SD card driver for Linux.

To install a new buildroot directory, build the binaries, and generate the device tree binaries in one command, use:
    
    $ make BUILDROOT=path/to/buildroot
    
Or simply use the default buildroot location in `/opt/riscv`:
    
    $ make
    
Note that the `$RISCV` variable cannot be set prior to building in buildroot or the build will fail. It is best to run `source ./setup.sh` to alter your `$PATH` and set the `$RISCV` variable after buildroot has succesfully built the binaries. If you're new to buildroot, you can find the binaries in `<BUILDROOT>/output/images`.

## Generating Device Tree Binaries <a name="devicetree"></a>

The device tree files for the various FPGA's Wally supports, as well as QEMU's device tree for the virt machine, are located in the `./devicetree` subdirectory. These device tree files are necessary for the boot process. In order to build the device tree binaries (.dtb) from the device tree sources (.dts), we can build all of them at once using:

    $ make generate BUILDROOT=path/to/buildroot
    
    Or for the default buildroot location:
    
    $ make generate 
    
The .dts files will end up in the `<BUILDROOT>/output/images` folder of your chosen buildroot directory.

## Disassembling the Binaries for Debugging <a name="disassembly"></a>

By using the `riscv64-unknown-elf-objdump` utility, we can disassemble the binaries in `<BUILDROOT>/output/images` so that we can explore the resulting machine code instructions and see what assembly or C code the instructions came from, along with the corresponding addresses. This is useful during debugging in order to trace how code is being executed.

To create the disassembled binaries, run:

    $ make disassemble BUILDROOT=path/to/buildroot
    
You'll find the resulting disassembled files in `<BUILDROOT>/output/images/disassembly`.

## Creating a Bootable SD Card <a name="sdcard"></a>

To flash a bootable sd card for Wally's bootloader, use the `flash-sd.sh` script located in `<WALLY>/linux/sdcard`. The script allows you to specify which buildroot directory you would like to use and to specify the device tree. By default it is set up for the default location of buildroot in `/opt/riscv` and uses the vcu108 device tree. To use the script with your own buildroot directory and device tree, type:

    $ cd sdcard
    $ ./flash-sd.sh -b <path/to/buildroot> -d <device tree name> <DEVICE>
    
    for example
    
    $ ./flash-sd.sh -b ~/repos/buildroot -d wally-vcu118.dtb /dev/sdb
    

