# Wally Debug Support

This repository documents debug support for **Wally**, an open-source RISC-V processor platform. The goal of this effort is to support the RISC-V Debug Specification while enabling reliable debugging in both simulation and hardware environments. Wally integrates debug functionality compatible with OpenOCD, Spike remote bitbang simulation, and physical JTAG debug adapters.

---

## Supported RISC-V Debug Specification

Wally currently targets:

**RISC-V Debug Specification — Version 1.0 (Revised 2025-02-21)**

Development continues toward expanded functionality and improved
tool interoperability.

---

## Note on Spike Debug Compatibility

The current Wally debug implementation does **not** include an initial Debug Module *program buffer* (`progbufsize = 0`). While this is allowed by the RISC-V Debug Specification (which permits implementations to rely on abstract register access instead of a program buffer), some debugger workflows assume program-buffer execution is available.

A recent Spike update (https://github.com/riscv-software-src/riscv-isa-sim/commit/5397899bb9eddba8c2f87d7d62e6303629ebed90) introduced stricter debug checks, including an assertion (around line 122) that may trigger when debugging a target that does not implement a program buffer.

As a result, users may observe assertion failures or unexpected debugger behavior when using newer versions of Spike together with Wally debug.

This limitation is temporary. Future Wally debug revisions will include program buffer support, improving compatibility with Spike, OpenOCD, and standard RISC-V debug workflows.

---

## OpenOCD udev Rules Installation (Linux)

USB debug adapters typically require root privileges. Installing the OpenOCD udev rules allows OpenOCD to access supported debug probes without using `sudo`.

The rules file is provided with OpenOCD:

```
contrib/60-openocd.rules
```

Install it with:

```bash
sudo cp openocd-code/contrib/60-openocd.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

After installation, unplug and reconnect the debug adapter.  You may also need to log out and back in if group permissions change.

OpenOCD should then run normally as a user as an example here:

```bash
openocd -f tests/debug/openocd.cfg
```
