#!/usr/bin/env python3

###########################################
## CacheSimTest.py
##
## Written: lserafini@hmc.edu
## Created: 4 April 2023
## Modified: 5 April 2023
##
## Purpose: Run the cache simulator on each rv64gc test suite in turn. 
##
## A component of the CORE-V-WALLY configurable RISC-V project.
##
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
## except in compliance with the License, or, at your option, the Apache License version 2.0. You 
## may obtain a copy of the License at
##
## https:##solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the 
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
## either express or implied. See the License for the specific language governing permissions 
## and limitations under the License.
################################################################################################
import sys
import os

# NOTE: make sure testbench.sv has the ICache and DCache loggers enabled!
# This does not check the test output for correctness, run regression for that.


tests64gc = ["coverage64gc", "arch64f", "arch64d", "arch64i", "arch64priv", "arch64c",  "arch64m", 
             "arch64zi", "wally64a", "wally64periph", "wally64priv", 
             "arch64zba",  "arch64zbb",  "arch64zbc",  "arch64zbs", 
             "imperas64f", "imperas64d", "imperas64c", "imperas64i"]

cachetypes = ["ICache", "DCache"]
simdir = os.path.expanduser("~/cvw/sim")

if __name__ == '__main__':
    testcmd = "vsim -do \"do wally-batch.do rv64gc {}\" -c > /dev/null"
    cachecmd = "CacheSim.py 64 4 56 44 -f {}"
    for test in tests64gc:
        # print(testcmd.format(test))
        print("Commencing test", test)
        os.system(testcmd.format(test))
        for cache in cachetypes:
            print("Running the", cache, "simulator.")
            os.system(cachecmd.format(cache+".log"))
