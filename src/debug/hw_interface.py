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


def main():
    global tn
    #with Telnet("127.0.0.1", 4444) as tn:
    #activate_dm()
    access_register(32,1,0)
    print(f"DATA0: {read_data(0)}")
    print(f"DATA1: {read_data(1)}")
    print("Writing 00000000_BAADFEED to R1")
    write_data(1, "0x0")
    write_data(0, "0xbaadfeed")
    access_register(0,1,0)
        




def write_data(regno, data):
    """Writes to a message register DATA0-"""
    if regno == 1:
        write_dmi("0x5", data)
    elif regno == 0:
        write_dmi("0x4", data)


def read_data(regno):
    if regno == 1:
        return read_dmi("0x5")
    elif regno == 0:
        return read_dmi("0x4")


def access_register(write, register, addr_size):
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

    # TODO: convert register alias to regno

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


def read():
    data = b""
    while True:
        rd = tn.read_until(b"\n", timeout=0.05)
        if not rd:
            break
        else:
            data += rd
    if debug:
        print(data.decode('ascii'))
    return data.decode('ascii')


if __name__ == "__main__":
    main()
