# Linux for core-v-wally

## Setting up Buildroot

In order to generate the Linux and boot stage binaries compatible with Wally, Buildroot is used for cross-compilation. To set up a Buildroot directory, configuration files for Buildroot, Linux, and Busybox must be copied into the correct locations inside the main Buildroot directory. This can be done automatically using the Makefile inside Wally's Linux subdirectory (this one). To install and patch a fresh Buildroot directory, type:

    $ make install BUILDROOT=path/to/buildroot

You can override the `BUILDROOT` variable to place buildroot where you want it. By default it will be placed at `/opt/riscv/buildroot`. In addition to copying the configuration files, it will install the buildroot package needed to build the SD card driver for Linux.

To install a new buildroot directory, build the binaries, and generate the device tree binaries in one command, use:
    
    $ make BUILDROOT=path/to/buildroot
    
Or simply use the default buildroot location in `/opt/riscv`:
    
    $ make
    
Note that the `$RISCV` variable cannot be set prior to building in buildroot or the build will fail. It is best to run `source ./setup.sh` to alter your `$PATH` and set the `$RISCV` variable after buildroot has succesfully built the binaries. If you're new to buildroot, you can find the binaries in `<BUILDROOT>/output/images`.

## Generating Device Tree Binaries

The device tree files for the various FPGA's Wally supports, as well as QEMU's device tree for the virt machine, are located in the `./devicetree` subdirectory. These device tree files are necessary for the boot process. In order to build the device tree binaries (.dtb) from the device tree sources (.dts), we can build all of them at once using:

    $ make generate BUILDROOT=path/to/buildroot
    
    Or for the default buildroot location:
    
    $ make generate 

## Creating a Bootable SD Card


