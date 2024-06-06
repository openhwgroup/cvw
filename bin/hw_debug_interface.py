#!/usr/bin/env python3

#########################################################################################
# hw_interface.py
#
# Written: matthew.n.otto@okstate.edu
# Created: 19 April 2024
#
# Purpose: Send debugging commands to OpenOCD via local telnet connection
#
# A component of the CORE-V-WALLY configurable RISC-V project.
# https:#github.com/openhwgroup/cvw
#
# Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
# except in compliance with the License, or, at your option, the Apache License version 2.0. You 
# may obtain a copy of the License at
#
# https:#solderpad.org/licenses/SHL-2.1/
#
# Unless required by applicable law or agreed to in writing, any work distributed under the 
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific language governing permissions 
# and limitations under the License.
#########################################################################################

# This script uses python to send text commands to OpenOCD via telnet
# OpenOCD also supports tcl commands directly

import atexit
import re
import time
from telnetlib import Telnet

debug = False

# TODO: if JTAG clk is fast enough, need to check for busy between absract commands

def dump_GPR():
    gpr = {}
    for i in range(1,32):
        addr = f"X{i}"
        gpr[addr] = read_data(addr)
        # DM will assert Abstract Command Err if GPR X16-X31 isn't implemented (CMDERR_EXCEPTION)
        # This will clear that error and return early. 
        if i == 16:
            abstractcs = int(read_dmi("0x16"), 16)
            cmderr = (abstractcs & 0x700) >> 8
            if cmderr == 3:
                clear_abstrcmd_err()
                break
    return gpr
    


def write_data(register, data):
    """Writes data of width XLEN to specified register"""
    # Translate register alias to DM regno
    regno = int(register_translations[register], 16)
    # Write data to 32 bit message registers
    data = int(data, 16)
    write_dmi("0x4", hex(data & 0xffffffff))
    if XLEN == 64:
        write_dmi("0x5", hex((data >> 32) & 0xffffffff))
    if XLEN == 128:
        write_dmi("0x6", hex((data >> 64) & 0xffffffff))
        write_dmi("0x7", hex((data >> 96) & 0xffffffff))
    # Transfer data from msg registers to target register
    access_register(write=True, regno=regno, addr_size=XLEN)
    # Check that operations completed without error
    if acerr := check_absrtcmderr():
        raise Exception(acerr)


def read_data(register):
    """Read data of width XLEN from specified register"""
    # Translate register alias to DM regno
    regno = int(register_translations[register], 16)
    # Transfer data from target register to msg registers
    access_register(write=False, regno=regno, addr_size=XLEN)
    # Read data from 32 bit message registers
    data = ""
    data = read_dmi("0x4").replace("0x", "").zfill(8)
    if XLEN >= 64:
        data = read_dmi("0x5").replace("0x", "").zfill(8) + data
    if XLEN == 128:
        data = read_dmi("0x6").replace("0x", "").zfill(8) + data
        data = read_dmi("0x7").replace("0x", "").zfill(8) + data
    # Check that operations completed without error
    if acerr := check_absrtcmderr():
        raise Exception(acerr)
    return f"0x{data}"


def access_register(write, regno, addr_size):
    """3.7.1.1
    Before starting an abstract command, a debugger must ensure that haltreq, resumereq, and
    ackhavereset are all 0."""
    addr = "0x17"
    data = 1 << 17  # transfer bit always set
    if addr_size == 32:
        data += 2 << 20
    elif addr_size == 64:
        data += 3 << 20
    elif addr_size == 128:
        data += 4 << 20
    else:
        raise Exception("must provide valid register access size (32, 64, 128). See: 3.7.1.1 aarsize")
    if write:
        data += 1<<16
    data += regno
    data = hex(data)
    write_dmi(addr, data)


def halt():
    write_dmi("0x10", "0x80000001")
    check_errors()


def resume():
    write_dmi("0x10", "0x40000001")
    check_errors()


def step():
    write_dmi("0x10", "0xC0000001")
    check_errors()


def set_haltonreset():
    write_dmi("0x10", "0x9")


def clear_haltonreset():
    write_dmi("0x10", "0x5")


def reset_hart():
    write_dmi("0x10", "0x3")
    write_dmi("0x10", "0x1")


def status():
    dmstatus = int(read_dmi("0x11"), 16)
    print("Core status:::")
    print(f"Running: {bool((dmstatus >> 11) & 0x1)}")
    print(f"Halted:  {bool((dmstatus >> 9) & 0x1)}")


def check_errors():
    # TODO: update this
    """Checks various status bits and reports any potential errors
    Returns true if any errors are found"""
    # check dtmcs
    dtmcs = int(read_dtmcs(), 16)
    errinfo = (dtmcs & 0x1C0000) >> 18
    dmistat = (dtmcs & 0xC00) >> 10
    if errinfo > 0 and errinfo < 4:
        print(f"DTM Error: {errinfo_translations[errinfo]}")
        return True
    if dmistat:
        print(f"DMI status error: {op_translations[dmistat]}")
        return True
    # check if DM is inactive
    dm_active = int(read_dmi("0x10"), 16) & 0x1
    if not dm_active:
        print("DMControl Error: Debug module is not active")
        return True
    # check abstract command error
    abstractcs = int(read_dmi("0x16"), 16)
    busy = (abstractcs & 0x1000) >> 12
    cmderr = (abstractcs & 0x700) >> 8
    if not busy and cmderr:
        print(f"Abstract Command Error: {cmderr_translations[cmderr]}")
        return True


def check_busy():
    """If an Abstract Command OP is attempted while busy, an abstrcmderr will be asserted"""
    abstractcs = int(read_dmi("0x16"), 16)
    return bool((abstractcs & 0x1000) >> 12)


def check_absrtcmderr():
    """These errors must be cleared using clear_abstrcmd_err() before another OP can be executed"""
    abstractcs = int(read_dmi("0x16"), 16)
    # CmdErr is only valid if Busy is 0
    busy = bool((abstractcs & 0x1000) >> 12)
    while busy:
        time.sleep(0.05)
        abstractcs = int(read_dmi("0x16"), 16)
        busy = bool((abstractcs & 0x1000) >> 12)
    return cmderr_translations[(abstractcs & 0x700) >> 8]


def clear_abstrcmd_err():
    write_dmi("0x16", "0x700")


def reset_dm():
    deactivate_dm()
    activate_dm()


def activate_dm():
    write_dmi("0x10", "0x1")
    return int(read_dmi("0x10"), 16) & 0x1


def deactivate_dm():
    write_dmi("0x10", "0x0")
    return not int(read_dmi("0x10"), 16) & 0x1


def dmi_reset():
    """Reset sticky dmi error status in DTM"""
    write_dtmcs(dmireset=True)
    check_errors()


def write_dmi(address, data):
    cmd = f"riscv dmi_write {address} {data}"
    rsp = execute(cmd)
    if "Failed" in rsp:
        print(rsp)


def read_dmi(address):
    cmd = f"riscv dmi_read {address}"
    return execute(cmd)


def write_dtmcs(dtmhardreset=False, dmireset=False):
    data = 0
    if dtmhardreset:
        data += 0x1 << 17
    if dmireset:
        data += 0x1 << 16
    execute(f"irscan {tapname} 0x10")  # dtmcs instruction
    execute(f"drscan {tapname} 32 {hex(data)}")


def read_dtmcs():
    execute(f"irscan {tapname} 0x10")  # dtmcs instruction
    dtmcs = execute(f"drscan {tapname} 32 0x0")
    return dtmcs


def trst():
    execute("pathmove RESET IDLE")


def execute(cmd):
    write(cmd)
    return read()


def write(cmd):
    if debug:
        print(f"Executing command: '{cmd}'")
    tn.write(cmd.encode('ascii') + b"\n")
    tn.read_until(b"\n")


def read():
    data = b""
    data = tn.read_until(b"> ").decode('ascii')
    data = data.replace("\r", "").replace("\n", "").replace("> ", "")
    if debug:
        print(data)
    return data


def interrogate():
    global XLEN
    global tapname
    write("scan_chain")
    raw = tn.read_until(b"> ").decode('ascii')
    scan_chain = raw.replace("\r", "").replace("> ", "")
    scan_chain = [tap for tap in scan_chain.split("\n")[2:] if tap]
    if len(scan_chain) > 1:
        print(f"Found multiple taps. Selecting tap #0\n{raw}")
    scan_chain = scan_chain[0]
    tapname = re.search("\d\s+(.+?)\s+", scan_chain).group(1)
    print(f"DM tapname: {tapname}")

    write("riscv info")
    info = tn.read_until(b"> ").decode('ascii').replace("\r", "").replace("> ", "").split("\n")
    for line in info:
        if XLEN := re.search("hart.xlen\s+(\d+)", line).group(1):
            XLEN = int(XLEN)
            break
    print(f"XLEN: {XLEN}")


def init():
    global tn
    tn = Telnet("127.0.0.1", 4444)
    atexit.register(cleanup)
    read()  # clear welcome message from read buffer
    interrogate()
    activate_dm()
    # TODO: query gpr count


def cleanup():
    tn.close()


# 6.1.4 dtmcs errinfo translation table
errinfo_translations = {
    0 : "not implemented",
    1 : "dmi error",
    2 : "communication error",
    3 : "device error",
    4 : "unknown",
}


# 6.1.5 DMI op translation table
op_translations = {
    0 : "success",
    1 : "reserved",
    2 : "failed",
    3 : "busy",
}


# 3.14.6 Abstract command CmdErr value translation table
cmderr_translations = {
    0 : None,
    1 : "busy",
    2 : "not supported",
    3 : "exception",
    4 : "halt/resume",
    5 : "bus",
    6 : "reserved",
    7 : "other",
}


# Register alias to regno translation table
register_translations = {
    "MISA"        : "0x0301",
    "TRAPM"       : "0xC000",
    "PCM"         : "0xC001",
    "INSTRM"      : "0xC002",
    "MEMRWM"      : "0xC003",
    "INSTRVALIDM" : "0xC004",
    "WRITEDATAM"  : "0xC005",
    "IEUADRM"     : "0xC006",
    "READDATAM"   : "0xC007",
    "X0"          : "0x1000",
    "X1"          : "0x1001",
    "X2"          : "0x1002",
    "X3"          : "0x1003",
    "X4"          : "0x1004",
    "X5"          : "0x1005",
    "X6"          : "0x1006",
    "X7"          : "0x1007",
    "X8"          : "0x1008",
    "X9"          : "0x1009",
    "X10"         : "0x100A",
    "X11"         : "0x100B",
    "X12"         : "0x100C",
    "X13"         : "0x100D",
    "X14"         : "0x100E",
    "X15"         : "0x100F",
    "X16"         : "0x1010",
    "X17"         : "0x1011",
    "X18"         : "0x1012",
    "X19"         : "0x1013",
    "X20"         : "0x1014",
    "X21"         : "0x1015",
    "X22"         : "0x1016",
    "X23"         : "0x1017",
    "X24"         : "0x1018",
    "X25"         : "0x1019",
    "X26"         : "0x101A",
    "X27"         : "0x101B",
    "X28"         : "0x101C",
    "X29"         : "0x101D",
    "X30"         : "0x101E",
    "X31"         : "0x101F",
}

nonstandard_register_lengths = {
    "TRAPM"       : 1,
    "INSTRM"      : 32,
    "MEMRWM"      : 2,
    "INSTRVALIDM" : 1,
    "READDATAM"   : 64
}
