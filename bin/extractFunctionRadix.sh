#!/bin/bash

######################
## extractFunctionRadix.sh
##
## Written: Rose Thompson
## email: rose@rosethompson.net
## Created: March 1, 2021
## Modified: March 10, 2021
##
## Purpose: Lists the symbols of an ELF in 2 files, which the testbench uses to name the current function and to
##          find where a test reports its result.
##          File 1: <prefix>.addr: A sorted list of symbol addresses.
##                  When the PC is greater than or equal to a symbol's address, the label will be associated with this address.
##          File 2: <prefix>.lab: The symbol names, in the same order.  The simulator displays these names rather than the address.
##          <prefix> defaults to <elf>.objdump.
##
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
## except in compliance with the License, or, at your option, the Apache License version 2.0. You
## may obtain a copy of the License at
##
## https://solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
## either express or implied. See the License for the specific language governing permissions
## and limitations under the License.
################################################################################################


if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <elf> [<prefix>]" >&2
    exit 1
fi
elf=$1
prefix=${2:-$elf.objdump}

set -o pipefail
# nm -n lists the symbol table sorted by address, so the testbench can binary search it.  Leave out
# symbols without an address in the program: absolute constants and undefined references.
symbols=$(riscv64-unknown-elf-nm -n "$elf" | awk 'NF == 3 && $2 !~ /^[aAUvw]$/') || exit 1
echo "$symbols" | awk '{print $1}' > "$prefix.addr"
echo "$symbols" | awk '{print $3}' > "$prefix.lab"
