##################################################
## coremark_sweep.py

## Written: Shreesh Kulkarni, kshreesh5@gmail.com
## Created: 20 March 2024
## Modified: 20 March 2024
## Purpose: Wally 32-bit Coremark sweep Script 
 
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
import subprocess # normal os.system() doesn't seem to work. Tried subprocess and it works.

# list of architectures to run. I have included only 32-bit for now as I'm still testing this script and modifying it to make it more efficient
arch_list = [
    "rv32gc_zba_zbb_zbc",
    "rv32im_zicsr_zba_zbb_zbc",
    "rv32gc",
    "rv32imc_zicsr",
    "rv32im_zicsr",
    "rv32i_zicsr"
]

# make command. If we wish to run the remaining commands like make clean, need to maintain a separate list.
make_cmd = ["make", "run"]

# Iterate over the architectures
for arch in arch_list:
    # Setting the arch variable
    env = os.environ.copy()
    env["ARCH"] = arch

    # used subprocess to run coremark for each architecture
    print(f"Running for architecture: {arch}")
    result = subprocess.run(make_cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)

    # diplay the output on console. If we wish to store the results in a file,need to write some file handling code. Review needed
    print(result.stdout)
    print(result.stderr)
    print("\n" *5)
    
