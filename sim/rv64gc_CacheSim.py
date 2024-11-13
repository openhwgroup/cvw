#!/usr/bin/env python3

###########################################
## rv64gc_CacheSim.py
##
## Written: lserafini@hmc.edu
## Created: 11 April 2023
## Modified: 12 April 2023
## Modified: 10 August 2023, jcarlin@hmc.edu
##
## Purpose: Run the cache simulator on each rv64gc test suite in turn.
##
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
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
import os
import argparse
import subprocess

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

tests64gc = ["coverage64gc", "wally64priv", "arch64i", "arch64priv", "arch64c",  "arch64m", "arch64zcb",
             "arch64zifencei", "arch64zicond", "arch64a_amo", "wally64a_lrsc", "wally64periph", 
             "arch64zbkb", "arch64zbkc", "arch64zbkx", "arch64zknd", "arch64zkne", "arch64zknh",
             "arch64zba",  "arch64zbb",  "arch64zbc", "arch64zbs"]
# arch64i is the most interesting case.  Uncomment line below to run just that case
#tests64gc = ["arch64i"]
#tests64gc = ["coverage64gc"]
#tests64gc = ["wally64priv"]

cachetypes = ["ICache", "DCache"]
simdir = os.path.expandvars("$WALLY/sim")

def main():
    parser = argparse.ArgumentParser(description="Runs the cache simulator on all rv64gc test suites")
    parser.add_argument('-p', "--perf", action='store_true', help="Report hit/miss ratio")
    parser.add_argument('-d', "--dist", action='store_true', help="Report distribution of operations")
    parser.add_argument('-s', "--sim", help="Simulator", choices=["questa", "verilator", "vcs"], default="verilator")
    args = parser.parse_args()
    simargs = "I_CACHE_ADDR_LOGGER=1\\\'b1 D_CACHE_ADDR_LOGGER=1\\\'b1"
    testcmd = "wsim --sim " + args.sim + " rv64gc {} --params \"" + simargs + "\" > /dev/null"
    #cachecmd = "CacheSim.py 64 4 56 44 -f {} --verbose"
    cachecmd = "CacheSim.py 64 4 56 44 -f {}"
    mismatches = 0

    if args.perf:
        cachecmd += " -p"
    if args.dist:
        cachecmd += " -d"

    for test in tests64gc:
        print(f"{bcolors.HEADER}Commencing test", test+f":{bcolors.ENDC}")
        # remove wkdir to force recompile with logging enabled
        os.system("rm -rf " + simdir + "/" + args.sim + "/wkdir/rv64gc_" + test)
        os.system("rm -rf " + simdir + "/" + args.sim + "/*Cache.log")
        print(testcmd.format(test))
        os.system(testcmd.format(test))
        for cache in cachetypes:
            print(f"{bcolors.OKCYAN}Running the", cache, f"simulator.{bcolors.ENDC}")
            result = subprocess.run(cachecmd.format(args.sim+"/"+cache+".log"), shell=True)
            mismatches += result.returncode
        print()
    return mismatches

if __name__ == '__main__':
    exit(main())

