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

Reload the udev rules so the system recognizes the new file and retrigger device evaluation:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Unplug the USB debug adapter from the system, wait a few seconds, and plug it back in so the new rules are applied.

Add your user account to the system groups commonly required for USB and serial device access. On most distributions these include plugdev and dialout:

```bash
sudo usermod -aG plugdev,dialout $USER
```

On some distributions, access may also require membership in the uucp group:

```bash
sudo usermod -aG uucp $USER
```

Log out of your current session and log back in, or reboot the system, so the new group memberships take effect:

```bash
sudo reboot
```

After logging back in, verify that your user is a member of the required groups:

```bash
groups
```

Confirm that the USB debug adapter is detected by the system:

```bash
lsusb
```

Run OpenOCD as a normal user without sudo and log output to a file:

```bash
openocd -l /tmp/openocd.log
```

If OpenOCD starts without permission errors, the udev rules are installed and working correctly. Stop OpenOCD by pressing Ctrl+C.

If OpenOCD still reports permission errors, monitor udev activity while unplugging and replugging the adapter to confirm that rules are being applied:

```bash
udevadm monitor --environment --udev
```

Stop monitoring by pressing Ctrl+C. Inspect the installed rules file if necessary to confirm that your adapter’s vendor and product IDs are included:

```bash
grep -E 'idVendor|idProduct' /etc/udev/rules.d/60-openocd.rules
```

Once the rules are installed, udev has been reloaded, the device has been replugged, and the user is in the appropriate groups, OpenOCD can be used without root privileges.
