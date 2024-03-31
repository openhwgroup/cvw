#!/usr/bin/python 
##################################################
## coremark_sweep.py

## Written: Shreesh Kulkarni, kshreesh5@gmail.com
## Created: 20 March 2024
## Modified: 22 March 2024
## Purpose: Wally  Coremark sweep Script for both 32 and 64 bit configs. 
 
## Documentation: 

# A component of the CORE-V-WALLY configurable RISC-V project.
# https://github.com/openhwgroup/cvw
 
# Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
# except in compliance with the License, or, at your option, the Apache License version 2.0. You 
# may obtain a copy of the License at

# https://solderpad.org/licenses/SHL-2.1/

# Unless required by applicable law or agreed to in writing, any work distributed under the 
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific language governing permissions 
# and limitations under the License.
###########################################################################################


import os
# list of architectures to run. 
arch32_list = [
    "rv32gc_zba_zbb_zbc",
    "rv32im_zicsr_zba_zbb_zbc",
    "rv32gc",
    "rv32imc_zicsr",
    "rv32im_zicsr",
    "rv32i_zicsr"
]
arch64_list = [
    "rv64gc_zba_zbb_zbc",
    "rv64im_zicsr_zba_zbb_zbc",
    "rv64gc",
    "rv64imc_zicsr",
    "rv64im_zicsr",
    "rv64i_zicsr"
]
xlen_values = ['32','64']
for xlen_value in xlen_values:
    if(xlen_value=='32'):
        for arch in arch32_list:
            os.system("make clean")
            make_all = f"make all XLEN={xlen_value} ARCH={arch}"
            os.system(make_all)
            make_run = f"make run XLEN={xlen_value} ARCH={arch}"
            os.system(make_run)
    else:
        for arch in arch64_list:
            os.system("make clean")
            make_all = f"make all XLEN={xlen_value} ARCH={arch}"
            os.system(make_all)
            make_run = f"make run XLEN={xlen_value} ARCH={arch}"
            os.system(make_run)





