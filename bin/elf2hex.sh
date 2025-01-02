#!/bin/bash

###########################################
## Written: james.stine@okstate.edu
## Created: 4 Jan 2022
## Modified: 
##
## Purpose: Script to run elf2hex for memfile for
##          Imperas and riscv-arch-test benchmarks
##
## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-25 Harvey Mudd College & Oklahoma State University
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

for file in work/rv64i_m/*/*.elf ; do
    memfile=${file%.elf}.elf.memfile
    echo riscv64-unknown-elf-elf2hex --bit-width 64 --input "$file" 
    riscv64-unknown-elf-elf2hex --bit-width 64 --input "$file" --output "$memfile"
done

for file in work/rv32i_m/*/*.elf ; do
    memfile=${file%.elf}.elf.memfile
    echo riscv64-unknown-elf-elf2hex --bit-width 32 --input "$file"
    riscv64-unknown-elf-elf2hex --bit-width 32 --input "$file" --output "$memfile"
done
