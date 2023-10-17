#!/usr/bin/env python3

###########################################
## rv64gc_CacheSim.py
##
## Written: lserafini@hmc.edu
## Created: 11 April 2023
## Modified: 12 April 2023
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
import argparse

# NOTE: make sure testbench.sv has the ICache and DCache loggers enabled!
# This does not check the test output for correctness, run regression for that.
# Add -p or --perf to report the hit/miss ratio. 
# Add -d or --dist to report the distribution of loads, stores, and atomic ops.
# These distributions may not add up to 100; this is because of flushes or invalidations.

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# tests64gc = ["coverage64gc", "arch64f", "arch64d", "arch64i", "arch64priv", "arch64c",  "arch64m", 
tests64gc = ["coverage64gc", "arch64i", "arch64priv", "arch64c",  "arch64m",             
             "arch64zi", "wally64a", "wally64periph", "wally64priv", 
             "arch64zba",  "arch64zbb",  "arch64zbc",  "arch64zbs", 
             "imperas64f", "imperas64d", "imperas64c", "imperas64i"]
# arch64i is the most interesting case.  Uncomment line below to run just that case
tests64gc = ["arch64i"]

cachetypes = ["ICache", "DCache"]
simdir = os.path.expanduser("~/cvw/sim")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Runs the cache simulator on all rv64gc test suites")
    parser.add_argument('-p', "--perf", action='store_true', help="Report hit/miss ratio")
    parser.add_argument('-d', "--dist", action='store_true', help="Report distribution of operations")

    args = parser.parse_args()

    testcmd = "vsim -do \"do wally-batch.do rv64gc {}\" -c > /dev/null"
    cachecmd = "CacheSim.py 64 4 56 44 -f {}"
    
    if args.perf:
        cachecmd += " -p"
    if args.dist:
        cachecmd += " -d"
    
    for test in tests64gc:
        print(f"{bcolors.HEADER}Commencing test", test+f":{bcolors.ENDC}")
        os.system(testcmd.format(test))
        for cache in cachetypes:
            print(f"{bcolors.OKCYAN}Running the", cache, f"simulator.{bcolors.ENDC}")
            os.system(cachecmd.format(cache+".log"))
        print()
