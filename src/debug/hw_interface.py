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

from telnetlib import Telnet

debug = False
XLEN = 64 # TODO: infer this value from the MISA

tapname = "cvw.cpu" # this is set via the openocd config. It can be found by running `scan_chain`

def main():
    global tn
    with Telnet("127.0.0.1", 4444) as tn:
        read() # clear welcome message from read buffer
        activate_dm() # necessary if openocd init is disabled
        status()
        #halt()
        #status()
        #resume()
        #status()
        #clear_abstrcmd_err()
        #write_data("READDATAM", "0xAA0987210000FFFF")
        #print(f"READDATAM'{read_data("READDATAM")}'")
        print(f"WRITEDATAM: '{read_data("WRITEDATAM")}'")
        print(f"IEUADRM: '{read_data("IEUADRM")}'")
        write_data("TRAPM", "0x0")
        print(f"INSTRVALIDM: '{read_data("INSTRVALIDM")}'")
        print(f"MEMRWM: '{read_data("MEMRWM")}'")
        write_data("MEMRWM", "0x3")
        write_data("PCM", "0x100000")
        print(f"PCM'{read_data("PCM")}'")
        check_errors()
        #dmi_reset()
        #clear_abstrcmd_err()




def write_data(register, data):
    """Writes data of width XLEN to specified register"""
    # Translate register alias to DM regno
    regno = int(register_translations[register], 16)
    # Write data to 32 bit message registers
    data = int(data, 16)
    write_dmi("0x4", hex(data & 0xffffffff))
    if XLEN == 64:
        write_dmi("0x5", hex((data>>32) & 0xffffffff))
    if XLEN == 128:
        write_dmi("0x6", hex((data>>64) & 0xffffffff))
        write_dmi("0x7", hex((data>>96) & 0xffffffff))
    # Transfer data from msg registers to target register
    access_register(write=True, regno=regno, addr_size=XLEN)


def read_data(register):
    """Read data of width XLEN from specified register"""
    # Translate register alias to DM regno
    regno = int(register_translations[register], 16)
    # Transfer data from target register to msg registers
    access_register(write=False, regno=regno, addr_size=XLEN)
    # Read data from 32 bit message registers
    data = ""
    data = read_dmi("0x4").replace("0x", "").zfill(4)
    if XLEN == 64:
        data = read_dmi("0x5").replace("0x", "").zfill(4) + data
    if XLEN == 128:
        data = read_dmi("0x6").replace("0x", "").zfill(4) + data
        data = read_dmi("0x7").replace("0x", "").zfill(4) + data
    return f"0x{data}"


def access_register(write, regno, addr_size):
    """3.7.1.1
    Before starting an abstract command, a debugger must ensure that haltreq, resumereq, and
    ackhavereset are all 0."""
    addr = "0x17"
    data = 1<<17 # transfer bit always set
    if addr_size == 32:
        data += 2<<20
    elif addr_size == 64:
        data += 3<<20
    elif addr_size == 128:
        data += 4<<20
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


def step():
    write_dmi("0x10", "0xC0000001")
    check_errors()


def resume():
    write_dmi("0x10", "0x40000001")
    check_errors()


def status():
    dmstatus = int(read_dmi("0x11"), 16)
    print(f"Core status:::")
    print(f"Running: {bool((dmstatus>>11)&0x1)}")
    print(f"Halted:  {bool((dmstatus>>9)&0x1)}")
    print(f"Reset:   {bool((dmstatus>>19)&0x1)}")


def check_errors():
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
        print(f"DMControl Error: Debug module is not active")
        #return True
    # check abstract command error
    abstractcs = int(read_dmi("0x16"), 16)
    busy = (abstractcs & 0x1000) >> 12
    cmderr = (abstractcs & 0x700) >> 8
    if not busy and cmderr:
        print(f"Abstract Command Error: {cmderr_translations[cmderr]}")
        return True
    

def reset_dm():
    deactivate_dm()
    activate_dm()


def clear_abstrcmd_err():
    write_dmi("0x16", "0x700")
    check_errors()


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
        data += 0x1<<17
    if dmireset:
        data += 0x1<<16
    execute(f"irscan {tapname} 0x10") # dtmcs instruction
    execute(f"drscan {tapname} 32 {hex(data)}")


def read_dtmcs():
    execute(f"irscan {tapname} 0x10") # dtmcs instruction
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
    data = data.replace("\r","").replace("\n","").replace("> ","")
    if debug:
        print(data)
    return data


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
    0 : "none",
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
    "X0"  : "0x1000",
    "X1"  : "0x1001",
    "X2"  : "0x1002",
    "X3"  : "0x1003",
    "X4"  : "0x1004",
    "X5"  : "0x1005",
    "X6"  : "0x1006",
    "X7"  : "0x1007",
    "X8"  : "0x1008",
    "X9"  : "0x1009",
    "X10" : "0x100A",
    "X11" : "0x100B",
    "X12" : "0x100C",
    "X13" : "0x100D",
    "X14" : "0x100E",
    "X15" : "0x100F",
    "X16" : "0x1010",
    "X17" : "0x1011",
    "X18" : "0x1012",
    "X19" : "0x1013",
    "X20" : "0x1014",
    "X21" : "0x1015",
    "X22" : "0x1016",
    "X23" : "0x1017",
    "X24" : "0x1018",
    "X25" : "0x1019",
    "X26" : "0x101A",
    "X27" : "0x101B",
    "X28" : "0x101C",
    "X29" : "0x101D",
    "X30" : "0x101E",
    "X31" : "0x101F",
}

if __name__ == "__main__":
    main()
