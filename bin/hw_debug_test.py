#!/usr/bin/env python3

#########################################################################################
# hw_test.py
#
# Written: matthew.n.otto@okstate.edu
# Created: 19 April 2024
#
# Purpose: script to automate testing of hardware debug interface
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

import random
import time

from openocd_tcl_wrapper import OpenOCD

random_stimulus = True
random_order = False


def flow_control_test():
    with OpenOCD() as cvw:
        cvw.reset_dm()
        cvw.reset_hart()

        cvw.halt()
        cvw.read_data("DCSR")
        for _ in range(50):
            cvw.step()
            cvw.read_data("PCM")
        cvw.resume()


def register_rw_test():
    with OpenOCD() as cvw:
        registers = dict.fromkeys(cvw.register_translations.keys(),[])
        reg_addrs = list(registers.keys())

        global XLEN
        XLEN = cvw.LLEN
        global nonstandard_register_lengths
        nonstandard_register_lengths = cvw.nonstandard_register_lengths

        cvw.reset_dm()
        cvw.reset_hart()

        #time.sleep(70)  # wait for OpenSBI

        cvw.halt()

        # dump data in all registers
        for r in reg_addrs:
            try:
                data = cvw.read_data(r)
                registers[r] = data
                print(f"{r}: {data}")
            except Exception as e:
                if e.args[0] == "exception":  # Invalid register (not implemented)
                    del registers[r]
                    cvw.clear_abstrcmd_err()
                else:
                    raise e
        input("Compare values to ILA, press any key to continue")

        # Write random data to all registers
        reg_addrs = list(registers.keys())
        if random_order:
            random.shuffle(reg_addrs)
        test_reg_data = {}
        for r in reg_addrs:
            test_data = random_hex(r)
            try:
                cvw.write_data(r, test_data)
                test_reg_data[r] = test_data
                print(f"Writing {test_data} to {r}")
            except Exception as e:
                if e.args[0] == "not supported":  # Register is read only
                    del registers[r]
                    cvw.clear_abstrcmd_err()
                else:
                    raise e

        # GPR X0 is always 0
        test_reg_data["x0"] = "0x" + "0"*(cvw.LLEN//4)

        # Confirm data was written correctly
        reg_addrs = list(registers.keys())
        if random_order:
            random.shuffle(reg_addrs)
        for r in reg_addrs:
            try:
                rdata = cvw.read_data(r)
            except Exception as e:
                raise e
            if rdata != test_reg_data[r]:
                print(f"Error: register {r} read did not return correct data: {rdata} != {test_reg_data[r]}")
            else:
                print(f"Reading {rdata} from {r}")

        # Return all registers to original state
        reg_addrs = list(registers.keys())
        for r in reg_addrs:
            print(f"Writing {registers[r]} to {r}")
            try:
                cvw.write_data(r, registers[r])
            except Exception as e:
                raise e

        # Confirm data was written correctly
        for r in reg_addrs:
            try:
                rdata = cvw.read_data(r)
            except Exception as e:
                raise e
            if rdata != registers[r]:
                raise Exception(f"Register {r} read did not return correct data: {rdata} != {registers[r]}")
        print("All writes successful")

        cvw.resume()


def random_hex(reg_name):
    pad = XLEN // 4
    if reg_name in nonstandard_register_lengths:
        size = nonstandard_register_lengths[reg_name]
    else:
        size = XLEN

    # Reset ReadDataM to a value
    nonstandard_register_lengths["READDATAM"] = XLEN
    if random_stimulus:
        return "0x" + f"{random.getrandbits(size):x}".rjust(pad, "0")
    else:
        data = 0xa5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5
        return "0x" + f"{(data & (2**size-1)):x}".rjust(pad, "0")


#register_rw_test()
flow_control_test()
