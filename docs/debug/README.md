# Wally Debug List

It is our hope that we will get to many of these items for Wally with
the RISC-V Debug specification.  We have posted a MarkDown file that lists
the capabilities we have implemented including the items we hope to
implement soon.

### Supported RISC-V Debug Specification
We are currently using the Debug specification with
Version 1.0, Revised 2025-02-21


### OpenOCD udev Rules Installation (Linux)

This part explains how to install and activate the OpenOCD udev rules on a Linux system so that USB debug adapters can be used without running OpenOCD as root. These steps apply to FTDI-based JTAG adapters, CMSIS-DAP/DAPLink devices, ST-Link, J-Link in OpenOCD mode, and many RISC-V debug probes.  These updates are done separately, because its not an OpenOCD dependency and a system policy configuration.  We did this as a precaution in case it interferes with shared hardware access.

Open a terminal and ensure the system package list and required utilities are installed. On Ubuntu or Debian systems run:

```bash
sudo apt-get update
sudo apt-get install -y udev usbutils
```

On RHEL, Rocky, or Alma Linux systems run:

```bash
sudo dnf install -y systemd-udev usbutils
```

Verify that the OpenOCD udev rules file exists in the OpenOCD source tree. The file is provided by OpenOCD and is located at contrib/60-openocd.rules. If your OpenOCD source directory is named openocd-code, verify the file with:

```bash
ls openocd-code/contrib/60-openocd.rules
```

If the file does not exist, obtain or update the OpenOCD source tree before continuing.

Copy the OpenOCD udev rules file into the system udev rules directory:

```bash
sudo cp openocd-code/contrib/60-openocd.rules /etc/udev/rules.d/
```

Verify that the file was copied successfully:

```bash
ls -l /etc/udev/rules.d/60-openocd.rules
```
