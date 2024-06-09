#########################################################################################
# openocd_tcl_wrapper.py
#
# Written: matthew.n.otto@okstate.edu
# Created: 8 June 2024
#
# Purpose: Python wrapper library used to send debug commands to OpenOCD
#
# A component of the CORE-V-WALLY configurable RISC-V project.
# https://github.com/openhwgroup/cvw
#
# Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
# except in compliance with the License, or, at your option, the Apache License version 2.0. You 
# may obtain a copy of the License at
#
# https://solderpad.org/licenses/SHL-2.1/
#
# Unless required by applicable law or agreed to in writing, any work distributed under the 
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific language governing permissions 
# and limitations under the License.
#########################################################################################

import math
import socket
import time

ENDMSG = b'\x1a'

class OpenOCD:
    def __init__(self):
        self.tcl = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def __enter__(self):
        self.tcl.connect(("127.0.0.1", 6666))
        self.LLEN = 64 #TODO: find this
        return self

    def __exit__(self, type, value, traceback):
        try:
            self.send("exit")
        finally:
            self.tcl.close()

    def capture(self, cmd):
        return self.send(f"capture \"{cmd}\"")

    def send(self, cmd):
        data = cmd.encode("ascii") + ENDMSG
        self.tcl.send(data)
        return self.receive()

    def receive(self):
        data = bytes()
        while True:
            byte = self.tcl.recv(1)
            if byte == ENDMSG:
                break
            else:
                data += byte
        data = data.decode("ascii").rstrip()
        return data

    def trst(self):
        self.send("pathmove RESET IDLE")

    def write_dtmcs(self, dtmhardreset=False, dmireset=False):
        """Send reset commands to DTMCS. Used to clear sticky DMI OP error status"""
        data = 0
        data |= dtmhardreset << 17
        data |= dmireset << 16
        if not data:
            print("Warning: not writing DTMCS (dtmhardreset and dmireset are both false)")
            return
        tapname = "cvw.cpu"
        self.send(f"irscan {tapname} 0x10")  # dtmcs instruction
        self.send(f"drscan {tapname} 32 {hex(data)}")
        op = self.capture(f"drscan {tapname} 32 0x0")
        if (int(op) >> 10) & 0x3:
            raise Exception("Error: failed to reset DTMCS (nonzero dmistat)")

    def write_dmi(self, address, data):
        cmd = f"riscv dmi_write {address} {data}"
        rsp = self.capture(cmd)
        if "Failed" in rsp:
            raise Exception(rsp)

    def read_dmi(self, address):
        cmd = f"riscv dmi_read {address}"
        return self.capture(cmd)

    def activate_dm(self):
        self.write_dmi("0x10", "0x1")
        dmstat = int(self.read_dmi("0x10"), 16)
        if not dmstat & 0x1:
            raise Exception("Error: failed to activate debug module")
  
    def reset_dm(self):
        self.write_dmi("0x10", "0x0")
        dmstat = int(self.read_dmi("0x10"), 16)
        if dmstat & 0x1:
            raise Exception("Error: failed to deactivate debug module")
        self.activate_dm()

    def reset_hart(self):
        self.write_dmi("0x10", "0x3")
        self.write_dmi("0x10", "0x1")
        dmstat = int(self.read_dmi("0x11"), 16)  # check HaveReset
        if not ((dmstat >> 18) & 0x3):
            raise Exception("Error: Hart failed to reset")
        self.write_dmi("0x10", "0x10000001")  # ack HaveReset

    def set_haltonreset(self):
        self.write_dmi("0x10", "0x9")

    def clear_haltonreset(self):
        self.write_dmi("0x10", "0x5")

    def halt(self):
        self.write_dmi("0x10", "0x80000001")
        dmstat = int(self.read_dmi("0x11"), 16)  # Check halted bit
        if not ((dmstat >> 8) & 0x3):
            raise Exception("Error: Hart failed to halt")

    def resume(self):
        self.write_dmi("0x10", "0x40000001")  # Send resume command
        dmstat = int(self.read_dmi("0x11"), 16)  # Check resumeack bit
        if not ((dmstat >> 16) & 0x3):
            raise Exception("Error: Hart failed to resume")
        self.write_dmi("0x10", "0x40000001")  # Clear resumeack bit

    def step(self):
        self.write_dmi("0x10", "0xC0000001")
        # BOZO: checking resumeack after halt is pointless until sdext halt method is added
        dmstat = int(self.read_dmi("0x11"), 16)
        if not ((dmstat >> 16) & 0x3):
            raise Exception("Error: Hart failed to resume")

    def access_register(self, write, regno, addr_size=None):
        data = 1 << 17  # transfer bit always set
        if not addr_size:
            addr_size = self.LLEN
        elif addr_size not in (32, 64, 128):
            raise Exception("must provide valid register access size (32, 64, 128). See: 3.7.1.1 aarsize")
        data += int(math.log2(addr_size // 8)) << 20
        data += write << 16
        data += regno
        self.write_dmi("0x17", hex(data))

    def write_data(self, register, data):
        """Write data to specified register"""
        # Write data to 32 bit message registers
        data = int(data, 16)
        self.write_dmi("0x4", hex(data & 0xffffffff))
        if self.LLEN >= 64:
            self.write_dmi("0x5", hex((data >> 32) & 0xffffffff))
        if self.LLEN == 128:
            self.write_dmi("0x6", hex((data >> 64) & 0xffffffff))
            self.write_dmi("0x7", hex((data >> 96) & 0xffffffff))
        # Translate register alias to DM regno
        regno = self.translate_regno(register)
        # Transfer data from msg registers to target register
        self.access_register(write=True, regno=regno)
        # Check that operations completed without error
        if acerr := self.check_abstrcmderr():
            raise Exception(acerr)

    def read_data(self, register):
        """Read data from specified register"""
        # Translate register alias to DM regno
        regno = self.translate_regno(register)
        # Transfer data from target register to msg registers
        self.access_register(write=False, regno=regno)
        # Read data from 32 bit message registers
        data = ""
        data = self.read_dmi("0x4").replace("0x", "").zfill(8)
        if self.LLEN >= 64:
            data = self.read_dmi("0x5").replace("0x", "").zfill(8) + data
        if self.LLEN == 128:
            data = self.read_dmi("0x6").replace("0x", "").zfill(8) + data
            data = self.read_dmi("0x7").replace("0x", "").zfill(8) + data
        # Check that operations completed without error
        if acerr := self.check_abstrcmderr():
            raise Exception(acerr)
        return f"0x{data}"

    def translate_regno(self, register):
        if register not in self.register_translations:
            register = self.abi_translations[register]
        return int(self.register_translations[register], 16)

    def check_abstrcmderr(self):
        """These errors must be cleared using clear_abstrcmd_err() before another OP can be executed"""
        abstractcs = int(self.read_dmi("0x16"), 16)
        # CmdErr is only valid if Busy is 0
        while True:
            if not bool((abstractcs & 0x1000) >> 12):  # if not Busy
                break
            time.sleep(0.05)
            abstractcs = int(self.read_dmi("0x16"), 16)
        return self.cmderr_translations[(abstractcs & 0x700) >> 8]

    def clear_abstrcmd_err(self):
        self.write_dmi("0x16", "0x700")
        if self.check_abstrcmderr():
            raise Exception("Error: failed to clear AbstrCmdErr")

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
        "x0"          : "0x1000",
        "x1"          : "0x1001",
        "x2"          : "0x1002",
        "x3"          : "0x1003",
        "x4"          : "0x1004",
        "x5"          : "0x1005",
        "x6"          : "0x1006",
        "x7"          : "0x1007",
        "x8"          : "0x1008",
        "x9"          : "0x1009",
        "x10"         : "0x100A",
        "x11"         : "0x100B",
        "x12"         : "0x100C",
        "x13"         : "0x100D",
        "x14"         : "0x100E",
        "x15"         : "0x100F",
        "x16"         : "0x1010",
        "x17"         : "0x1011",
        "x18"         : "0x1012",
        "x19"         : "0x1013",
        "x20"         : "0x1014",
        "x21"         : "0x1015",
        "x22"         : "0x1016",
        "x23"         : "0x1017",
        "x24"         : "0x1018",
        "x25"         : "0x1019",
        "x26"         : "0x101A",
        "x27"         : "0x101B",
        "x28"         : "0x101C",
        "x29"         : "0x101D",
        "x30"         : "0x101E",
        "x31"         : "0x101F",
        "f0"          : "0x1020",
        "f1"          : "0x1021",
        "f2"          : "0x1022",
        "f3"          : "0x1023",
        "f4"          : "0x1024",
        "f5"          : "0x1025",
        "f6"          : "0x1026",
        "f7"          : "0x1027",
        "f8"          : "0x1028",
        "f9"          : "0x1029",
        "f10"         : "0x102A",
        "f11"         : "0x102B",
        "f12"         : "0x102C",
        "f13"         : "0x102D",
        "f14"         : "0x102E",
        "f15"         : "0x102F",
        "f16"         : "0x1030",
        "f17"         : "0x1031",
        "f18"         : "0x1032",
        "f19"         : "0x1033",
        "f20"         : "0x1034",
        "f21"         : "0x1035",
        "f22"         : "0x1036",
        "f23"         : "0x1037",
        "f24"         : "0x1038",
        "f25"         : "0x1039",
        "f26"         : "0x103A",
        "f27"         : "0x103B",
        "f28"         : "0x103C",
        "f29"         : "0x103D",
        "f30"         : "0x103E",
        "f31"         : "0x103F",
    }

    abi_translations = {
        "x0"  : "zero",
        "x1"  : "ra",
        "x2"  : "sp",
        "x3"  : "gp",
        "x4"  : "tp",
        "x5"  : "t0",
        "x6"  : "t1",
        "x7"  : "t2",
        "x8"  : "s0/fp",
        "x9"  : "s1",
        "x10" : "a0",
        "x11" : "a1",
        "x12" : "a2",
        "x13" : "a3",
        "x14" : "a4",
        "x15" : "a5",
        "x16" : "a6",
        "x17" : "a7",
        "x18" : "s2",
        "x19" : "s3",
        "x20" : "s4",
        "x21" : "s5",
        "x22" : "s6",
        "x23" : "s7",
        "x24" : "s8",
        "x25" : "s9",
        "x26" : "s10",
        "x27" : "s11",
        "x28" : "t3",
        "x29" : "t4",
        "x30" : "t5",
        "x31" : "t6",
        "f0"  : "ft0",
        "f1"  : "ft1",
        "f2"  : "ft2",
        "f3"  : "ft3",
        "f4"  : "ft4",
        "f5"  : "ft5",
        "f6"  : "ft6",
        "f7"  : "ft7",
        "f8"  : "fs0",
        "f9"  : "fs1",
        "f10" : "fa0",
        "f11" : "fa1",
        "f12" : "fa2",
        "f13" : "fa3",
        "f14" : "fa4",
        "f15" : "fa5",
        "f16" : "fa6",
        "f17" : "fa7",
        "f18" : "fs2",
        "f19" : "fs3",
        "f20" : "fs4",
        "f21" : "fs5",
        "f22" : "fs6",
        "f23" : "fs7",
        "f24" : "fs8",
        "f25" : "fs9",
        "f26" : "fs10",
        "f27" : "fs11",
        "f28" : "ft8",
        "f29" : "ft9",
        "f30" : "ft10",
        "f31" : "ft11",
    }
    abi_translations |= dict(map(reversed, abi_translations.items())) # two way translations

    nonstandard_register_lengths = {
        "TRAPM"       : 1,
        "INSTRM"      : 32,
        "MEMRWM"      : 2,
        "INSTRVALIDM" : 1,
        "READDATAM"   : 64
    }
