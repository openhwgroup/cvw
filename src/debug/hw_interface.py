#########################################################################################
# jtag.sv
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

debug = True
XLEN = 64

def main():
    global tn
    with Telnet("127.0.0.1", 4444) as tn:
        read() # clear welcome message from read buffer
        activate_dm()
        d = read_data("PCM")
        print(f"PCM register contents: {d}")
        write_data("PCM", "0x000000001337BEEF")

        



def write_data(register, data):
    """Writes data of width XLEN to specified register"""
    # Translate register alias to DM regno
    regno = int(register_translations[register], 16)
    # Write data to 32 bit message registers
    write_dmi("0x4", f"0x{data[-8::]}")
    if XLEN == 64:
        write_dmi("0x5", f"0x{data[-16:-8]}")
    if XLEN == 128:
        write_dmi("0x6", f"0x{data[-24:-16]}")
        write_dmi("0x7", f"0x{data[-32:-24]}")
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
    """3.7.1.1"""
    addr = "0x17"
    data = 2**17 # transfer bit always set
    match addr_size:
        case 32:
            data += 2*2**20
        case 64:
            data += 3*2**20
        case 128:
            data += 4*2**20
        case _:
            raise Exception("must provide valid register access size (32, 64, 128). See: 3.7.1.1 aarsize")
    if write:
        data += 2**16
    data += regno
    data = hex(data)
    write_dmi(addr, data)


def activate_dm():
    write_dmi("0x10", "0x1")


def status():
    pass # TODO: check dmstatus and dtmcs err


def write_dmi(address, data):
    cmd = f"riscv dmi_write {address} {data}"
    write(cmd)


def read_dmi(address):
    cmd = f"riscv dmi_read {address}"
    return execute(cmd)


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
    data = data[:-7]
    if debug:
        print(data)
    return data


# Register alias to regno translation table
register_translations = {
    "PCM"         : "0x0",
    "TRAPM"       : "0x1",
    "INSTRM"      : "0x2",
    "INSTRVALIDM" : "0x3",
    "MEMRWM"      : "0x4",
    "IEUADRM"     : "0x5",
    "READDATAM"   : "0x6",
    "WRITEDATAM"  : "0x7",
    "RS1"         : "0x8",
    "RS2"         : "0x9",
    "RD2"         : "0xA",
    "RD1"         : "0xB",
    "WD"          : "0xC",
    "WE"          : "0xD",
    #"X0"  : "0x1000",
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
