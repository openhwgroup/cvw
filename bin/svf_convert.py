#!/usr/bin/env python3

################################################
# svf_convert.py
#
# Written: matthew.n.otto@okstate.edu
# Created: 28 June 2024
#
# Purpose: Converts JTAG SVF files to hexfile format for driving simulation stimulus
#
# A component of the CORE-V-WALLY configurable RISC-V project.
# https://github.com/openhwgroup/cvw
# 
# Copyright (C) 2021-24 Harvey Mudd College & Oklahoma State University
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
# except in compliance with the License, or, at your option, the Apache License Version 2.0. You 
# may obtain a copy of the License at
#
# https://solderpad.org/licenses/SHL-2.1/
#
# Unless required by applicable law or agreed to in writing, any work distributed under the 
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific language governing permissions 
# and limitations under the License.
################################################

import argparse
from enum import Enum
from math import log2
import os
import sys

# Assembled SVF command format
CMD_BITS = 3
LENGTH_BITS = 10
DATA_BITS = 48

# Derived constants
MAXLEN = 2**LENGTH_BITS

usage = f"""
Converts SVF file to proprietary memfile for use with jtag_driver.sv\n

Usage: svf_convert.py <source_directory> <output_directory>
"""

def main():
    parser = argparse.ArgumentParser(description=usage, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(dest="source_directory", help="The absolute path of the directory contianing SVF test files")
    parser.add_argument(dest="output_directory", help="The absolute path of the directory where memfiles will be generated")
    args = parser.parse_args()
    srcdir = args.source_directory
    workdir = args.output_directory

    if not os.path.exists(srcdir):
        print(f"Error: source directory '{srcdir}' does not exist")
        sys.exit(1)
    if not os.path.exists(workdir):
        print(f"Error: output directory '{workdir}' does not exist")
        sys.exit(1)

    for file in os.scandir(srcdir):
        if file.is_file() and file.name.endswith(".svf"):
            memfilename = file.name.replace(".svf", ".memfile")
            memfilepath = os.path.join(workdir, memfilename)
            convert(file.path, memfilepath)
            print(f"Successfully converted {file.name} -> {memfilename}")


def convert(input_path, output_path):
    with open(input_path, "r") as file:
        data = file.read()
    data = data.lower()

    tokens = svf_tokenizer(data)
    tokens = remove_comments(tokens)
    cmds = parse_tokens(tokens)
    with open(output_path, "w") as file:
        for cmd in cmds:
            asm = assemble_svf(cmd)
            file.write(asm + '\n')


def svf_tokenizer(data):
    """Reads raw SVF ascii and converts to a list of tokens"""
    keywords = ["sir", "sdr", "runtest", "tdi", "tdo", "mask", "smask", "(", ")", ";"]
    comment_keywords = ["//", "!"]
    keywords += comment_keywords

    tokens = []
    eof = len(data)
    token = ""
    for idx, char in enumerate(data):
        if char != " " and char != "\n":
            token += char
        if (idx+1 < eof):
            if data[idx+1] == " ":
                if token:
                    tokens.append(token)
                    token = ""
            elif data[idx+1] == "\n":
                if token:
                    tokens.append(token)
                    token = ""
                tokens.append("\n")
            elif token in keywords or data[idx+1] in keywords:
                if token:
                    tokens.append(token)
                    token = ""
    return tokens


def remove_comments(tokens):
    """Removes comments and newlines from list of tokens"""
    pruned = []
    comment = False
    for t in tokens:
        if t == "\n":
            comment = False
            continue
        if comment:
            continue
        if t in ["//", "!"]:
            comment = True
            continue
        pruned.append(t)
    return pruned

def parse_tokens(tokens):
    """groups tokens belonging to the same SVF command and checks if valid"""
    cmds = []

    cmd = Command()
    start_idx = 0
    i = -1
    while i+1 < len(tokens):
        i += 1
        t = tokens[i]
        if t == ";":
            if cmd.complete():
                cmds.append(cmd)
                cmd = Command()
                start_idx = i+1
                continue
            else:
                raise Exception(f"Error: incomplete SVF command terminated : '{' '.join(tokens[start_idx:i+1])}'")

        if cmd.op is None:
            try:
                cmd.op = SVF[t]
            except KeyError:
                raise Exception(f"Error: expected an SVF command, got '{t}' : '{' '.join(tokens[start_idx:i+1])}'")
            continue

        if cmd.length is None:
            try:
                cmd.length = int(t)
            except Exception:
                raise Exception(f"Error: expected a length value, got '{t}' : '{' '.join(tokens[start_idx:i+1])}'")
            if cmd.length == 0:
                raise Exception(f"Error: length parameter must not be 0 : '{' '.join(tokens[start_idx:i+1])}'")
            if cmd.length >= MAXLEN:
                raise Exception(f"Error: not enough bits to represent command length : {cmd.length} > {MAXLEN-1} : '{' '.join(tokens[start_idx:i+2])}'")
            if cmd.op != SVF.runtest and cmd.length > DATA_BITS:
                raise Exception(f"Error: length exceeds number of bits in data field : {cmd.length} > {DATA_BITS} : '{' '.join(tokens[start_idx:i+2])}'")
            continue

        match cmd.op:
            case SVF.runtest:
                continue
            case SVF.sdr | SVF.sir:
                if t not in ("tdi", "tdo", "mask"):
                    raise Exception(f"Error: unknown keyword '{t}' : '{' '.join(tokens[start_idx:i+1])}'")
                if not (tokens[i+1] == "(" and tokens[i+3] == ")"):
                    raise Exception(f"Error: could not interpret value following token '{t}' (missing parentheses) : '{' '.join(tokens[start_idx:i+2])}'")
                try:
                    val = int(tokens[i+2], 16)
                    i += 3
                    if t == "tdi":
                        cmd.tdi = val
                    elif t == "tdo":
                        cmd.tdo = val
                    elif t == "mask":
                        cmd.mask = val
                except Exception:
                    raise Exception(f"Error: could not interpret {t} value: '{tokens[i+2]}' : '{' '.join(tokens[start_idx:i+1])}'")
                if val > 0 and int(log2(val)) > cmd.length:
                    raise Exception(f"Error: shift data cannot be a value larger than the maximum implied by the length parameter : log2({val}) > {cmd.length}" +
                                    f" : '{' '.join(tokens[start_idx:i+2])}'")
                continue
            case _:
                raise Exception(f"Error: did not match on valid SVF command : '{' '.join(tokens[start_idx:i+1])}'")
    if t != ";":
        raise Exception(f"Error: file ended with incomplete command")
    return cmds



def assemble_svf(cmd):
    """Converts svf command object to proprietary format for Wally simulation"""
    cmdcode = (cmd.op.value << (LENGTH_BITS + DATA_BITS*3))
    match cmd.op:
        case SVF.runtest:
            cmdcode += (cmd.length << DATA_BITS*3)
        case SVF.sdr | SVF.sir:
            if cmd.length:
                cmdcode += (cmd.length << DATA_BITS*3)
            if cmd.tdi:
                cmdcode += (cmd.tdi << DATA_BITS*2)
            if cmd.tdo:
                cmdcode += (cmd.tdo << DATA_BITS)
            if cmd.mask:
                cmdcode += (cmd.mask)
            elif not cmd.mask: # If mask isnt specified, set all bits to 1
                cmdcode += 2**DATA_BITS-1
    hexcmd = hex(cmdcode)[2:]
    # TODO: pad left with 0 if needed (if CMD_BITS increases)
    return hexcmd


class Command:
    def __init__(self):
        self.op = None
        self.length = None
        self.tdi = None
        self.tdo = None
        self.mask = None

    def complete(self):
        """Returns true if object contains enough information to form a complete command"""
        if self.op == SVF.runtest:
            return self.length
        elif self.op in (SVF.sdr, SVF.sir):
            z = self.length and (self.tdi is not None or self.tdo is not None)
            return z
        else:
            return False


#  Supported SVF commands
class SVF(Enum):
    runtest = 0
    sir = 1
    sdr = 2


if __name__ == "__main__":
    main()
